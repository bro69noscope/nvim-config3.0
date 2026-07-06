local build
if OnWindows then
  build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
else
  build = "make"
end
return {
  "yetone/avante.nvim",
  enabled = true,
  event = { "BufReadPost", "BufNewFile" },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- ⚠️ must add this setting! ! !
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false", -- for windows
  build = build,
  version = false, -- Never set this value to "*"! Never!
  init = function()
    -- HACK: Fix bizarre avante default behavior with weird operator pending mode issue
    vim.api.nvim_create_autocmd("WinEnter", {
      pattern = "*",
      callback = function()
        if vim.bo.filetype == "AvanteInput" then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n", false)
          vim.cmd("startinsert")
        end
      end,
    })
  end,
  ---@module 'avante'
  ---@type avante.Config
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    -- add any opts here
    -- for example
    provider = "claude",
    providers = {
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-sonnet-4-20250514",
        timeout = 30000, -- Timeout in milliseconds
        extra_request_body = {
          temperature = 0.75,
          max_tokens = 20480,
        },
      },
    },
    hints = { enabled = false }, -- Disable virutal text in vmode
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "echasnovski/mini.pick", -- for file_selector provider mini.pick
    "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
    "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
    "ibhagwan/fzf-lua", -- for file_selector provider fzf
    "stevearc/dressing.nvim", -- for input provider dressing
    "folke/snacks.nvim", -- for input provider snacks
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
  -- NOTE: Seems to not work well with lazy keys, so we're lazyloading on event right now

  -- cmd = {
  --   "AvanteAsk",
  --   "AvanteChat",
  --   "AvanteEdit",
  --   "AvanteStop",
  --   "AvanteBuild",
  --   "AvanteClear",
  --   "AvanteFocus",
  --   "AvanteModels",
  --   "AvanteToggle",
  --   "AvanteChatNew",
  --   "AvanteHistory",
  --   "AvanteRefresh",
  --   "AvanteShowRepoMap",
  --   "AvanteSwitchProvider",
  --   "AvanteSwitchInputProvider",
  --   "AvanteSwitchSelectorProvider",
  -- },
  -- keys = {
  --   {
  --     "<leader>aa",
  --     "<cmd>AvanteAsk<cr>",
  --     desc = "Avante: Ask",
  --     mode = { "n", "v" },
  --   },
  --   {
  --     "<leader>ae",
  --     "<cmd>AvanteEdit<cr>",
  --     desc = "Avante: Edit",
  --     mode = { "n", "v" },
  --   },
  --   {
  --     "<leader>an",
  --     "<cmd>AvanteChatNew<cr>",
  --     desc = "Avante: New Task",
  --     mode = { "n", "v" },
  --   },
  --   {
  --     "<leader>at",
  --     "<cmd>AvanteToggle<cr>",
  --     desc = "Avante: Toggle",
  --   },
  --   {
  --     "<leader>ah",
  --     "<cmd>AvanteHistory<cr>",
  --     desc = "Avante: Select History",
  --   },
  -- },
}
