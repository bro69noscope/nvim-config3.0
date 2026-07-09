return {
  grep_vertical = {
    layout = {
      box = "vertical",
      width = 0.65,
      min_width = 100,
      height = 0.9,
      border = "none",
      { win = "preview", title = "{preview}", height = 0.5, border = "rounded" }, -- Preview at top
      {
        box = "vertical",
        border = "rounded",
        title = "{title} {live} {flags}",
        title_pos = "center",
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
    },
  },
  midscreen_dropdown = {
    preview = false,
    layout = {
      backdrop = false,
      row = 0.4,
      width = 0.4,
      min_width = 80,
      height = 0.4,
      border = "none",
      box = "vertical",
      {
        win = "input",
        height = 1,
        border = "rounded",
        title = "{title} {live} {flags}",
        title_pos = "center",
      },
      { win = "list", border = "hpad" },
      { win = "preview", title = "{preview}", border = "rounded" },
    },
  },
  midscreen_dropdown_preview = {
    -- preview = true,
    layout = {
      backdrop = false,
      row = 0.1,
      width = 0.55,
      min_width = 80,
      height = 0.75,
      border = "none",
      box = "vertical",
      { win = "preview", title = "{preview}", height = 0.6, border = "rounded" },
      {
        win = "input",
        height = 1,
        border = "rounded",
        title = "{title} {live} {flags}",
        title_pos = "center",
      },
      { win = "list", border = "hpad" },
    },
  },
}
