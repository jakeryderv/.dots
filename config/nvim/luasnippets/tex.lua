-- LaTeX snippets, loaded by LuaSnip's lua loader (blink-cmp.lua).
-- Autosnippets expand as soon as the trigger is typed. The math ones only fire
-- inside a math zone as VimTeX's syntax sees it ($...$, \[...\], align, ...),
-- so prose is never rewritten. Regular snippets come from the completion menu.
local ls = require('luasnip')
local s, i, t, f = ls.snippet, ls.insert_node, ls.text_node, ls.function_node
local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep

-- LuaSnip passes the line up to the cursor and the matched trigger. A
-- backslash before the trigger means a command is being typed by hand
-- (\bf, \cal, \int, ...), which must not expand.
local function in_math(line_to_cursor, trigger)
  return line_to_cursor:sub(-#trigger - 1, -#trigger - 1) ~= '\\' and vim.fn['vimtex#syntax#in_mathzone']() == 1
end

local function in_text()
  return vim.fn['vimtex#syntax#in_mathzone']() == 0
end

-- A math-only autosnippet. `nodes` may be a string for plain replacements.
-- `attach` = true lets the trigger follow a word character (x^2 via `xsr`).
local function m(trig, nodes, attach)
  if type(nodes) == 'string' then
    nodes = t(nodes)
  end
  return s({ trig = trig, snippetType = 'autosnippet', wordTrig = not attach }, nodes, { condition = in_math })
end

local snippets = {
  -- Prose: open math
  s({ trig = 'mk', snippetType = 'autosnippet' }, fmta('$<>$', { i(1) }), { condition = in_text }),
  s({ trig = 'dm', snippetType = 'autosnippet' }, fmta('\\[\n\t<>\n\\]', { i(1) }), { condition = in_text }),

  -- Environments (from the menu): the \end name mirrors the \begin one.
  s('beg', fmta('\\begin{<>}\n\t<>\n\\end{<>}', { i(1), i(0), rep(1) })),

  -- Math: structures
  m('ff', fmta('\\frac{<>}{<>}', { i(1), i(2) })),
  m('sq', fmta('\\sqrt{<>}', { i(1) })),
  m('td', fmta('^{<>}', { i(1) }), true),
  m('__', fmta('_{<>}', { i(1) }), true),
  m('sr', '^2', true),
  m('invs', '^{-1}', true),
  m('tt', fmta('\\text{<>}', { i(1) })),
  m('bf', fmta('\\mathbf{<>}', { i(1) })),
  m('bb', fmta('\\mathbb{<>}', { i(1) })),
  m('cal', fmta('\\mathcal{<>}', { i(1) })),
  m('lr(', fmta('\\left( <> \\right)', { i(1) })),
  m('lr[', fmta('\\left[ <> \\right]', { i(1) })),
  m('lr{', fmta('\\left\\{ <> \\right\\}', { i(1) })),
  m('sum', fmta('\\sum_{<>}^{<>}', { i(1), i(2) })),
  m('int', fmta('\\int_{<>}^{<>}', { i(1), i(2) })),
  m('lim', fmta('\\lim_{<> \\to <>}', { i(1), i(2) })),

  -- Math: symbols
  m('->', '\\to', true),
  m('=>', '\\implies', true),
  m('!=', '\\neq', true),
  m('<=', '\\leq', true),
  m('>=', '\\geq', true),
  m('**', '\\cdot', true),
  m('xx', '\\times'),
  m('...', '\\dots', true),
  m('ooo', '\\infty'),

  -- Math: x1 -> x_1, then a second digit -> x_{12}
  s(
    { trig = '(%a)(%d)', trigEngine = 'pattern', snippetType = 'autosnippet', wordTrig = false },
    f(function(_, snip)
      return snip.captures[1] .. '_' .. snip.captures[2]
    end),
    { condition = in_math }
  ),
  s(
    { trig = '(%a)_(%d%d)', trigEngine = 'pattern', snippetType = 'autosnippet', wordTrig = false },
    f(function(_, snip)
      return snip.captures[1] .. '_{' .. snip.captures[2] .. '}'
    end),
    { condition = in_math }
  ),
}

-- Math: Greek letters as ;<key>. Uppercase keys give the capital form.
-- stylua: ignore
local greek = {
  a = 'alpha', b = 'beta', g = 'gamma', d = 'delta', e = 'epsilon', z = 'zeta',
  h = 'eta', q = 'theta', i = 'iota', k = 'kappa', l = 'lambda', m = 'mu',
  n = 'nu', x = 'xi', p = 'pi', r = 'rho', s = 'sigma', t = 'tau',
  u = 'upsilon', f = 'phi', c = 'chi', y = 'psi', w = 'omega',
  G = 'Gamma', D = 'Delta', Q = 'Theta', L = 'Lambda', X = 'Xi', P = 'Pi',
  S = 'Sigma', U = 'Upsilon', F = 'Phi', Y = 'Psi', W = 'Omega',
}
for key, name in pairs(greek) do
  table.insert(snippets, m(';' .. key, '\\' .. name, true))
end

return snippets
