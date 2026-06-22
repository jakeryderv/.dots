// .opencode/plugins/tmux-panes.ts
//
// The "viewer": auto-spawns a tmux pane per subagent session and closes it on
// idle. Subagent-only (gated on a parentID), so the main session is untouched.
//
// Requirements:
//   - running inside tmux (TMUX env set)
//   - opencode started as a server with a known port:  opencode --port 4096
//     (override the port with the OPENCODE_PORT env var)
//
// Event shape verified against opencode 1.17.7: session.created carries
// properties.info.{id,parentID}; idle/deleted/error carry properties.sessionID.
// Flip DEBUG = true to re-dump raw session.* payloads if a future version moves them.

import { type Plugin } from "@opencode-ai/plugin"

const DEBUG = false
const PORT = Number(process.env.OPENCODE_PORT ?? 4096)
const SERVER_URL = `http://127.0.0.1:${PORT}`
const LAYOUT = process.env.OPENCODE_TMUX_LAYOUT ?? "main-vertical"        // main-horizontal | tiled | ...
const requestedMainPaneSize = Number(process.env.OPENCODE_TMUX_MAIN_PANE_SIZE ?? 60)
const MAIN_PANE_SIZE = Number.isFinite(requestedMainPaneSize)
  ? Math.min(80, Math.max(20, requestedMainPaneSize))
  : 60
const AUTO_CLOSE = process.env.OPENCODE_TMUX_AUTO_CLOSE !== "0"

export const TmuxPanesPlugin: Plugin = async ({ $, client, directory }) => {
  const inTmux = !!process.env.TMUX
  // The pane opencode itself runs in — our stable anchor for splits/resizes so
  // we never act on whichever pane happens to be active at event time.
  const MAIN_PANE = process.env.TMUX_PANE
  const panes = new Map<string, string>()   // sessionId -> pane id

  const log = (message: string, extra: Record<string, unknown> = {}) =>
    client.app.log({ body: { service: "tmux-panes", level: "info", message, extra } })

  if (!inTmux) await log("Not inside tmux; pane spawning disabled")

  async function spawnPaneFor(sessionId: string) {
    if (!inTmux) return
    if (panes.has(sessionId)) return   // already tracking a pane; don't orphan a duplicate
    try {
      // -d: keep focus on the main opencode pane (don't jump into the agent pane).
      // -t MAIN_PANE: always split off the opencode pane, not the active one.
      const paneId = (
        await $`tmux split-window -d -h -t ${MAIN_PANE} -P -F ${"#{pane_id}"} opencode attach ${SERVER_URL} --session ${sessionId} --dir ${directory}`.text()
      ).trim()
      await $`tmux select-layout -t ${MAIN_PANE} ${LAYOUT}`.nothrow()
      await $`tmux resize-pane -t ${MAIN_PANE} -x ${MAIN_PANE_SIZE + "%"}`.nothrow()
      panes.set(sessionId, paneId)
      await log("spawned pane", { sessionId, paneId })
    } catch (err) {
      await log("spawn failed", { sessionId, err: String(err) })
    }
  }

  async function closePaneFor(sessionId: string) {
    const paneId = panes.get(sessionId)
    if (!paneId || !AUTO_CLOSE) return
    await $`tmux kill-pane -t ${paneId}`.nothrow()
    panes.delete(sessionId)
    await log("closed pane", { sessionId, paneId })
  }

  function readSession(event: any): { id?: string; parentID?: string } {
    const p = event?.properties ?? {}
    const info = p.info ?? p.session ?? p
    return { id: info?.id ?? p.sessionID, parentID: info?.parentID ?? info?.parentId }
  }

  return {
    event: async ({ event }) => {
      if (DEBUG && String(event.type).startsWith("session.")) {
        await log(`event ${event.type}`, { raw: event })
      }
      if (event.type === "session.created") {
        const { id, parentID } = readSession(event)
        if (id && parentID) await spawnPaneFor(id)   // child = subagent only
      }
      // idle = finished normally; deleted = cleaned up; error = terminal failure
      // (e.g. MessageAborted when you stop a hung subagent). Reap the pane in all
      // three so a hard-errored agent never leaves an orphaned pane behind.
      if (
        event.type === "session.idle" ||
        event.type === "session.deleted" ||
        event.type === "session.error"
      ) {
        const { id } = readSession(event)
        if (id) await closePaneFor(id)
      }
    },
  }
}
