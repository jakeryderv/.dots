return {
  '3rd/image.nvim',
  build = false,
  ft = { 'markdown', 'norg', 'vimwiki', 'typst' },
  opts = {
    backend = 'kitty',
    processor = 'magick_rock',
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = false,
        only_render_image_at_cursor = true,
        filetypes = { 'markdown', 'vimwiki' },
      },
      neorg = { enabled = true, filetypes = { 'norg' } },
      typst = { enabled = true, filetypes = { 'typst' } },
      html = { enabled = false },
      css = { enabled = false },
    },
    max_width_window_percentage = 80,
    max_height_window_percentage = 50,
    window_overlap_clear_enabled = true,
    window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', 'snacks_notif' },
    editor_only_render_when_focused = false,
    tmux_show_only_in_active_window = true,
    hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp', '*.avif' },
  },
}
