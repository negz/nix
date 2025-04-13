require('avante_lib').load()
require('avante').setup {
  claude = {
    model = 'claude-3-7-sonnet-20250219'
  },
  behaviour = {
    enable_cursor_planning_mode = true,
    enable_claude_text_editor_tool_mode = true,
  },
  hints = { enabled = false },
}
