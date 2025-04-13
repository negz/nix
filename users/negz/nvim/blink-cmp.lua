require('blink.cmp').setup {
  keymap = { preset = 'super-tab' },
  completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 100,
      },
      list = {
        selection = {
          preselect = false,
        },
      },
  };
  sources = {
    default = { 'lsp', 'path', 'buffer', 'avante', 'git' },
    providers = {
      avante = {
        module = 'blink-cmp-avante',
        name = 'Avante',
      },
      git = {
        module = 'blink-cmp-git',
        name = 'Git',
      },
    },
  },
  fuzzy = { implementation = "rust" },
  signature = { 
    enabled = true,
    window = {
      show_documentation = true
    }
  }
}
