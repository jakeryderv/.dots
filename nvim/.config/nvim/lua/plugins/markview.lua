return {
  'OXY2DEV/markview.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
  ft = { 'markdown', 'norg', 'typst', 'rmd' },
  config = function()
    local c = require('colors')

    -- highlight groups
    local function hl(name, opts) vim.api.nvim_set_hl(0, name, opts) end

    -- headings (fg = accent, bg = dim tint of accent mixed with carbonfox bg)
    hl('MarkviewH1', { fg = c.blue,    bg = '#252c39', bold = true })
    hl('MarkviewH2', { fg = c.cyan,    bg = '#1a2d39', bold = true })
    hl('MarkviewH3', { fg = c.green,   bg = '#182f23', bold = true })
    hl('MarkviewH4', { fg = c.teal,    bg = '#142f2f', bold = true })
    hl('MarkviewH5', { fg = c.magenta, bg = '#2f2939', bold = true })
    hl('MarkviewH6', { fg = c.pink,    bg = '#361f29', bold = true })

    -- code blocks
    hl('MarkviewCode', { bg = c.bg2 })
    hl('MarkviewCodeInfo', { fg = c.fg_mute, bg = c.bg2, italic = true })
    hl('MarkviewInlineCode', { fg = c.teal, bg = c.bg3 })

    -- lists
    hl('MarkviewListItemMinus', { fg = c.fg_mute })
    hl('MarkviewListItemPlus', { fg = c.fg_mute })
    hl('MarkviewListItemStar', { fg = c.fg_mute })

    -- checkboxes
    hl('MarkviewCheckboxUnchecked', { fg = c.fg_dim })
    hl('MarkviewCheckboxChecked',   { fg = c.green })
    hl('MarkviewCheckboxProgress',  { fg = c.cyan })
    hl('MarkviewCheckboxCancelled', { fg = c.bg4, strikethrough = true })
    hl('MarkviewCheckboxForwarded', { fg = c.blue })
    hl('MarkviewCheckboxImportant', { fg = c.pink })
    hl('MarkviewCheckboxQuestion',  { fg = c.magenta })

    -- callouts
    hl('MarkviewBlockQuoteDefault', { fg = c.fg_dim })
    hl('MarkviewBlockQuoteNote',    { fg = c.blue })
    hl('MarkviewBlockQuoteTip',     { fg = c.green })
    hl('MarkviewBlockQuoteImportant', { fg = c.magenta })
    hl('MarkviewBlockQuoteWarn',    { fg = c.orange })
    hl('MarkviewBlockQuoteCaution', { fg = c.red })
    hl('MarkviewBlockQuoteSpecial', { fg = c.teal })

    -- tables
    hl('MarkviewTableBorder', { fg = c.bg4 })
    hl('MarkviewTableHeader', { fg = c.fg, bold = true })
    hl('MarkviewTableAlignLeft', { fg = c.cyan })
    hl('MarkviewTableAlignCenter', { fg = c.cyan })
    hl('MarkviewTableAlignRight', { fg = c.cyan })

    -- links
    hl('MarkviewHyperlink',    { fg = c.blue, underline = true })
    hl('MarkviewInternalLink', { fg = c.cyan, underline = true })
    hl('MarkviewImageLink',    { fg = c.magenta, underline = true })
    hl('MarkviewEmbedFile',    { fg = c.magenta, underline = true })
    hl('MarkviewEmail',        { fg = c.orange, underline = true })

    -- latex
    hl('MarkviewLatexCode',  { bg = c.bg2 })
    hl('MarkviewLatexBlock', { fg = c.magenta, bg = c.bg2 })
    hl('MarkviewLatexInline',{ fg = c.magenta })

    -- footnotes
    hl('MarkviewFootnoteRef', { fg = c.blue })
    hl('MarkviewFootnoteDef', { fg = c.blue, bold = true })

    -- frontmatter
    hl('MarkviewYamlProperty', { fg = c.cyan })
    hl('MarkviewYamlBorder',   { fg = c.bg4 })

    -- horizontal rule
    hl('MarkviewHr', { fg = c.bg4 })

    require('markview').setup({
      preview = {
        icon_provider = 'mini',
        modes = { 'n' },
        hybrid_modes = {},
        filetypes = { 'markdown', 'quarto', 'rmd', 'typst' },
      },

      markdown = {
        headings = {
          enable = true,
          shift_width = 2,
          heading_1 = { style = 'label', icon = 'Ⅰ ', sign = '', hl = 'MarkviewH1' },
          heading_2 = { style = 'label', icon = 'Ⅱ ', sign = '', hl = 'MarkviewH2' },
          heading_3 = { style = 'label', icon = 'Ⅲ ', sign = '', hl = 'MarkviewH3' },
          heading_4 = { style = 'label', icon = 'Ⅳ ', sign = '', hl = 'MarkviewH4' },
          heading_5 = { style = 'label', icon = 'Ⅴ ', sign = '', hl = 'MarkviewH5' },
          heading_6 = { style = 'label', icon = 'Ⅵ ', sign = '', hl = 'MarkviewH6' },
        },

        code_blocks = {
          enable = true,
          style = 'block',
          icons = 'mini',
          min_width = 60,
          pad_amount = 2,
          pad_char = ' ',
          sign = false,
          language_direction = 'right',
          language_name = true,
          hl = 'MarkviewCode',
          info_hl = 'MarkviewCodeInfo',
        },

        list_items = {
          enable = true,
          marker_minus      = { text = '●', hl = 'MarkviewListItemMinus' },
          marker_plus       = { text = '●', hl = 'MarkviewListItemPlus' },
          marker_star       = { text = '●', hl = 'MarkviewListItemStar' },
          marker_dot        = { add_padding = true },
          marker_parenthesis= { add_padding = true },
        },

        block_quotes = {
          enable = true,
          default   = { border = '▌', hl = 'MarkviewBlockQuoteDefault' },
          ['NOTE']        = { preview = '󰋽 NOTE',      icon = '󰋽 ', border = '▌', hl = 'MarkviewBlockQuoteNote' },
          ['INFO']        = { preview = '󰋽 INFO',      icon = '󰋽 ', border = '▌', hl = 'MarkviewBlockQuoteNote' },
          ['TIP']         = { preview = '󰌶 TIP',       icon = '󰌶 ', border = '▌', hl = 'MarkviewBlockQuoteTip' },
          ['SUCCESS']     = { preview = '󰄬 SUCCESS',   icon = '󰄬 ', border = '▌', hl = 'MarkviewBlockQuoteTip' },
          ['IMPORTANT']   = { preview = '󰅾 IMPORTANT', icon = '󰅾 ', border = '▌', hl = 'MarkviewBlockQuoteImportant' },
          ['QUESTION']    = { preview = '󰞋 QUESTION',  icon = '󰞋 ', border = '▌', hl = 'MarkviewBlockQuoteImportant' },
          ['WARNING']     = { preview = '󰀦 WARNING',   icon = '󰀦 ', border = '▌', hl = 'MarkviewBlockQuoteWarn' },
          ['TODO']        = { preview = '󰀦 TODO',      icon = '󰀦 ', border = '▌', hl = 'MarkviewBlockQuoteWarn' },
          ['CAUTION']     = { preview = '󰳦 CAUTION',   icon = '󰳦 ', border = '▌', hl = 'MarkviewBlockQuoteCaution' },
          ['FAILURE']     = { preview = '󰳦 FAILURE',   icon = '󰳦 ', border = '▌', hl = 'MarkviewBlockQuoteCaution' },
          ['DANGER']      = { preview = '󰳦 DANGER',    icon = '󰳦 ', border = '▌', hl = 'MarkviewBlockQuoteCaution' },
          ['ABSTRACT']    = { preview = '󰋼 ABSTRACT',  icon = '󰋼 ', border = '▌', hl = 'MarkviewBlockQuoteSpecial' },
          ['EXAMPLE']     = { preview = '󰉹 EXAMPLE',   icon = '󰉹 ', border = '▌', hl = 'MarkviewBlockQuoteSpecial' },
          ['BUG']         = { preview = '󰨰 BUG',       icon = '󰨰 ', border = '▌', hl = 'MarkviewBlockQuoteCaution' },
          ['QUOTE']       = { preview = '󱆨 QUOTE',     icon = '󱆨 ', border = '▌', hl = 'MarkviewBlockQuoteDefault' },
        },

        tables = {
          enable = true,
          style = 'rounded',
          use_virt_lines = true,
          parts = {
            top       = { '╭', '─', '╮', '┬' },
            header    = { '│', '│', '│' },
            separator = { '├', '─', '┤', '┼' },
            row       = { '│', '│', '│' },
            bottom    = { '╰', '─', '╯', '┴' },
            align_left   = '←',
            align_center = '↔',
            align_right  = '→',
          },
          hl = {
            top       = { 'MarkviewTableBorder', 'MarkviewTableBorder', 'MarkviewTableBorder', 'MarkviewTableBorder' },
            header    = { 'MarkviewTableBorder', 'MarkviewTableBorder', 'MarkviewTableBorder' },
            separator = { 'MarkviewTableBorder', 'MarkviewTableBorder', 'MarkviewTableBorder', 'MarkviewTableBorder' },
            row       = { 'MarkviewTableBorder', 'MarkviewTableBorder', 'MarkviewTableBorder' },
            bottom    = { 'MarkviewTableBorder', 'MarkviewTableBorder', 'MarkviewTableBorder', 'MarkviewTableBorder' },
            align_left   = 'MarkviewTableAlignLeft',
            align_center = 'MarkviewTableAlignCenter',
            align_right  = 'MarkviewTableAlignRight',
          },
        },

        horizontal_rules = {
          enable = true,
          parts = {
            {
              type = 'repeating',
              text = '━',
              repeat_amount = function() return vim.o.columns end,
              hl = 'MarkviewHr',
            },
          },
        },
      },

      markdown_inline = {
        checkboxes = {
          enable = true,
          checked   = { text = '󰱒', hl = 'MarkviewCheckboxChecked' },
          unchecked = { text = '󰄱', hl = 'MarkviewCheckboxUnchecked' },
          ['/'] = { text = '󱎬', hl = 'MarkviewCheckboxProgress' },
          ['-'] = { text = '󰍶', hl = 'MarkviewCheckboxCancelled' },
          ['>'] = { text = '󰒊', hl = 'MarkviewCheckboxForwarded' },
          ['!'] = { text = '󰀦', hl = 'MarkviewCheckboxImportant' },
          ['?'] = { text = '󰞋', hl = 'MarkviewCheckboxQuestion' },
        },

        inline_codes = {
          enable = true,
          hl = 'MarkviewInlineCode',
          padding_left = ' ',
          padding_right = ' ',
        },

        hyperlinks = {
          enable = true,
          default = { icon = '󰌹 ', hl = 'MarkviewHyperlink' },
        },

        images = {
          enable = true,
          default = { icon = '󰋩 ', hl = 'MarkviewImageLink' },
        },

        internal_links = {
          enable = true,
          default = { icon = '󰏪 ', hl = 'MarkviewInternalLink' },
        },

        embed_files = {
          enable = true,
          default = { icon = '󰈔 ', hl = 'MarkviewEmbedFile' },
        },

        emails = {
          enable = true,
          default = { icon = '󰇮 ', hl = 'MarkviewEmail' },
        },

        uri_autolinks = {
          enable = true,
          default = { icon = '󰖟 ', hl = 'MarkviewHyperlink' },
        },

        entities  = { enable = true },
        escapes   = { enable = true },
        footnotes = {
          enable = true,
          reference = { icon = '', hl = 'MarkviewFootnoteRef' },
          definition = { icon = '', hl = 'MarkviewFootnoteDef' },
        },
      },

      latex = {
        enable = true,
        blocks = {
          enable = true,
          hl = 'MarkviewLatexBlock',
          border_left = '▌',
          border_left_hl = 'MarkviewLatexBlock',
        },
        inlines = {
          enable = true,
          hl = 'MarkviewLatexInline',
        },
        symbols  = { enable = true },
        fonts    = { enable = true },
        operators= { enable = true },
        parenthesis = { enable = true },
        subscripts  = { enable = true },
        superscripts= { enable = true },
        texts    = { enable = true },
      },

      yaml = {
        properties = {
          enable = true,
          hl = 'MarkviewYamlProperty',
          border_top    = '─',
          border_bottom = '─',
          border_hl     = 'MarkviewYamlBorder',
        },
      },

      html = {
        container_elements = { enable = true },
        void_elements      = { enable = true },
      },
    })

    -- link-follower keymap on markdown buffers
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'markdown', 'quarto', 'rmd' },
      callback = function(args)
        vim.bo[args.buf].suffixesadd = '.md'

        vim.keymap.set('n', '<CR>', function()
          local line = vim.api.nvim_get_current_line()
          local col = vim.api.nvim_win_get_cursor(0)[2] + 1

          for s, target, e in line:gmatch('()%[%[([^%]|]+)[^%]]*%]%]()') do
            if col >= s and col < e then
              local file = target:match('^([^#]+)') or target
              vim.cmd.edit(vim.fn.fnameescape(file .. '.md'))
              return
            end
          end

          for s, url, e in line:gmatch('()%[[^%]]+%]%(([^%)]+)%)()') do
            if col >= s and col < e then
              if url:match('^https?://') or url:match('^mailto:') then
                vim.ui.open(url)
              else
                local file = url:match('^([^#]+)') or url
                vim.cmd.edit(vim.fn.fnameescape(file))
              end
              return
            end
          end

          vim.cmd('normal! +')
        end, { buffer = args.buf, desc = 'Follow markdown link' })
      end,
    })
  end,
}
