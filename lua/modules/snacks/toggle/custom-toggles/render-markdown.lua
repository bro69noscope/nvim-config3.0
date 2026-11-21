local M = {}

M.render_markdown_toggle = Snacks.toggle.new({
  name = "Render Markdown",
  get = function()
    -- Do not load the plugin only to read its state
    local plugin = require("lazy.core.config").plugins["render-markdown.nvim"]
    if not (plugin and plugin._.loaded) then
      return false
    end

    return require("render-markdown").get()
  end,
  set = function(enabled)
    require("render-markdown").set(enabled)
  end,
})

return M
