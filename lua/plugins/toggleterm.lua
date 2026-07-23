return {
  "akinsho/toggleterm.nvim",
  enabled = true,
  version = "*",
  config = function()
    local original_height = 10
    local Terminal = require("toggleterm.terminal").Terminal
    local next_terminal_id = 1

    local function set_terminal_keymaps(term)
      local opts = { buffer = term.bufnr }
      vim.keymap.set("t", HideTerminalBind, [[<Cmd>ToggleTermToggleAll<CR>]], opts)
    end

    -- Create a new terminal
    local function create_terminal(dir)
      local new_terminal = Terminal:new({
        dir = dir,
        id = next_terminal_id,
        direction = "horizontal",
        on_open = function(term)
          vim.cmd("startinsert!")
          set_terminal_keymaps(term)
        end,
        on_close = function()
          vim.cmd("startinsert!")
        end,
      })
      next_terminal_id = next_terminal_id + 1
      return new_terminal
    end

    -- Create a new floating terminal
    local backdrop = require("scripts.ui.create-backdrop-window")
    local term_backdrop
    local float_term

    local function create_terminal_float(dir)
      float_term = Terminal:new({
        dir = dir,
        hidden = true,
        id = 100,
        direction = "float",
        float_opts = {
          border = "rounded",
          width = math.floor(vim.o.columns * 0.8),
          height = math.floor(vim.o.lines * 0.8),
        },
        on_open = function(t)
          term_backdrop = backdrop.open({ blend = 70, zindex = 40 })
          vim.cmd("startinsert!")
          set_terminal_keymaps(t)
        end,
        on_close = function(t)
          backdrop.close(term_backdrop)
        end,
      })
      return float_term
    end

    local function toggle_or_create_terminal_float(dir)
      if not float_term then
        create_terminal_float(dir)
      elseif dir then
        float_term:change_dir(dir)
      end

      float_term:toggle()
    end

    local function toggle_or_create_terminal(dir)
      local terms = require("toggleterm.terminal").get_all()
      if #terms == 0 then
        local new_term = create_terminal(dir)
        new_term:open()
      else
        vim.cmd("ToggleTermToggleAll")
      end
    end

    -- Set up keybindings for multi-terminal management
    local wk = require("which-key")

    wk.add({
      "<leader>tt",
      function()
        toggle_or_create_terminal()
      end,
      desc = "Toggleterm",
      icon = { icon = "", color = "cyan" },
    })

    wk.add({
      "<leader>tn",
      function()
        local new_term = create_terminal()
        new_term:open()
      end,
      desc = "New toggleterm",
      icon = { icon = "", color = "blue" },
    })

    wk.add({
      "<leader>tN",
      function()
        toggle_or_create_terminal(vim.fn.expand("%:p:h"))
      end,
      desc = "New toggleterm at current file",
      icon = { icon = "", color = "blue" },
    })

    wk.add({
      "<leader>tf",
      function()
        toggle_or_create_terminal_float()
      end,
      desc = "Toggleterm float",
      icon = { icon = "", color = "red" },
    })

    wk.add({
      "<leader>tF",
      function()
        toggle_or_create_terminal_float(vim.fn.expand("%:p:h"))
      end,
      desc = "Toggleterm float at current file",
      icon = { icon = "", color = "red" },
    })

    local shell
    if OnWindows then
      shell = "pwsh.exe"
    end

    require("toggleterm").setup({
      shell = shell or vim.o.shell,
      size = function(term)
        if term.direction == "horizontal" then
          return original_height -- Use the original_height variable
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
    })
  end,
}
