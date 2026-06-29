/**
 * compact-bash — minimal bash tool rendering.
 *
 * Overrides the built-in `bash` tool but REUSES its exact execution
 * (createBashToolDefinition), so streaming, truncation, timeout, abort, and
 * the LLM-facing result are all unchanged. Only the TUI rendering is replaced.
 *
 * Default view: full command in the header + a single compact metadata line
 *   ✓ exit 0 · 42 lines · 3.1KB · 0.4s · 10:15:03
 * Press Ctrl+O (app.tools.expand) to expand and see the full raw output.
 */

import {
	createBashToolDefinition,
	formatSize,
	keyHint,
	type ExtensionAPI,
	type ToolRenderResultOptions,
} from "@earendil-works/pi-coding-agent";
import { Container, Text, truncateToWidth } from "@earendil-works/pi-tui";

interface BashToolDetails {
	truncation?: {
		truncated?: boolean;
		truncatedBy?: "lines" | "bytes";
		outputLines?: number;
		totalLines?: number;
		maxBytes?: number;
	};
	fullOutputPath?: string;
}

// Shared render state across renderCall/renderResult for one tool row.
type BashRenderState = {
	startedAt: number | undefined;
	endedAt: number | undefined;
	interval: NodeJS.Timeout | undefined;
};

function formatDuration(ms: number): string {
	if (ms < 1000) return `${ms}ms`;
	return `${(ms / 1000).toFixed(1)}s`;
}

function formatClock(ts: number): string {
	const d = new Date(ts);
	const p = (n: number) => String(n).padStart(2, "0");
	return `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

function getOutputText(result: {
	content: Array<{ type: string; text?: string }>;
}): string {
	return result.content
		.filter((c) => c.type === "text" && typeof c.text === "string")
		.map((c) => c.text as string)
		.join("");
}

// On non-zero exit / timeout / abort the tool throws and the harness embeds the
// reason at the tail of the output text. Parse it back out for the summary.
function parseExitCode(
	text: string,
	isError: boolean,
): number | "abort" | "timeout" | null {
	const code = text.match(/Command exited with code (\d+)\s*$/);
	if (code) return Number(code[1]);
	if (/Command aborted\s*$/.test(text)) return "abort";
	if (/Command timed out after [\d.]+ seconds\s*$/.test(text)) return "timeout";
	return isError ? 1 : 0;
}

export default function compactBashExtension(pi: ExtensionAPI) {
	const def = createBashToolDefinition(pi.cwd ?? process.cwd());

	pi.registerTool({
		...def,
		// Reuse built-in execute + renderCall (the command header). Replace only
		// the result rendering with a compact, expandable summary.
		renderResult(result, options: ToolRenderResultOptions, theme, context) {
			const state = context.state as unknown as BashRenderState;

			// Live elapsed timer while the command is still running.
			if (
				state.startedAt !== undefined &&
				options.isPartial &&
				!state.interval
			) {
				state.interval = setInterval(() => context.invalidate(), 1000);
			}
			if (!options.isPartial || context.isError) {
				state.endedAt ??= Date.now();
				if (state.interval) {
					clearInterval(state.interval);
					state.interval = undefined;
				}
			}

			const details = result.details as BashToolDetails | undefined;
			const rawText = getOutputText(result as any).trim();
			const container = new Container();

			// ---- Still running -------------------------------------------------
			if (options.isPartial) {
				const elapsed =
					state.startedAt !== undefined
						? formatDuration(Date.now() - state.startedAt)
						: "";
				const line =
					theme.fg("warning", "● running") +
					(elapsed ? theme.fg("muted", ` · ${elapsed}`) : "");
				container.addChild(new Text(line, 0, 0));
				return container;
			}

			// ---- Finished: build the compact metadata line ---------------------
			const exit = parseExitCode(rawText, context.isError);
			const ok = exit === 0;

			const lineCount = rawText ? rawText.split("\n").length : 0;
			const bytes = Buffer.byteLength(rawText, "utf8");

			const parts: string[] = [];
			if (ok) {
				parts.push(theme.fg("success", "✓ exit 0"));
			} else if (exit === "abort") {
				parts.push(theme.fg("error", "✗ aborted"));
			} else if (exit === "timeout") {
				parts.push(theme.fg("error", "✗ timed out"));
			} else {
				parts.push(theme.fg("error", `✗ exit ${exit}`));
			}

			if (lineCount > 0) {
				parts.push(
					theme.fg("muted", `${lineCount} line${lineCount === 1 ? "" : "s"}`),
				);
				parts.push(theme.fg("muted", formatSize(bytes)));
			} else {
				parts.push(theme.fg("dim", "no output"));
			}

			if (state.startedAt !== undefined) {
				const end = state.endedAt ?? Date.now();
				parts.push(theme.fg("muted", formatDuration(end - state.startedAt)));
				parts.push(theme.fg("dim", formatClock(state.startedAt)));
			}

			if (details?.truncation?.truncated) {
				parts.push(theme.fg("warning", "truncated"));
			}

			let summary = parts.join(theme.fg("dim", " · "));
			if (!options.expanded && rawText) {
				summary += "  " + keyHint("app.tools.expand", "expand");
			}
			container.addChild(new Text(summary, 0, 0));

			// ---- Expanded: append the full raw output --------------------------
			if (options.expanded && rawText) {
				container.addChild({
					render: (width: number) =>
						rawText
							.split("\n")
							.map((l) => truncateToWidth(theme.fg("toolOutput", l), width)),
					invalidate: () => {},
				});
				if (details?.fullOutputPath) {
					container.addChild(
						new Text(
							theme.fg("warning", `\n[Full output: ${details.fullOutputPath}]`),
							0,
							0,
						),
					);
				}
			}

			return container;
		},
	});
}
