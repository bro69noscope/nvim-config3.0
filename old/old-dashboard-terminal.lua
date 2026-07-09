local height_limit = 40
local terms_width = 60
local top_padding = vim.o.lines > height_limit and 7 or -1
return {
  { pane = 4, padding = top_padding },
  {
    pane = 4,
    section = "terminal",
    enabled = false,
    cmd = not OnWindows and "colorscript -e square" or nil,
    height = 5,
    width = terms_width,
    padding = 1,
  },
  function()
    local in_git = Snacks.git.get_root() ~= nil

    -- Function to get command output, count lines, and add ellipsis if needed
    local function process_cmd(cmd, max_height, check_empty)
      local handle = io.popen(cmd)
      if not handle then
        return cmd, math.max(1, max_height)
      end
      local result = handle:read("*a")
      handle:close()

      -- Check if result is empty (just whitespace) when check_empty is true
      if check_empty and (result == "" or result:match("^%s*$")) then
        return "echo ' None 💃'", 1
      end

      local lines = {}
      for line in string.gmatch(result, "[^\r\n]+") do
        table.insert(lines, line)
      end
      local line_count = #lines
      local display_height = math.max(1, math.min(line_count, max_height))

      if line_count > max_height then
        local modified_cmd
        if cmd:find("|") then
          modified_cmd = cmd .. " | head -n " .. (max_height - 1) .. ' && echo "..."'
        else
          modified_cmd = cmd .. " | head -n " .. (max_height - 1) .. ' && echo "..."'
        end
        return modified_cmd, display_height
      else
        return cmd, display_height
      end
    end

    local function get_platform_specific_untracked_cmd()
      if OnWindows then
        -- Windows approach using PowerShell
        return [[
              git status --porcelain | findstr "^??" |
                pwsh -NoProfile -Command "& {
                  $input |
                    ForEach-Object { $_ -replace '^??', '$([char]0x1b)[35m??$([char]0x1b)[0m' }
              }"
    ]]
      else
        -- Unix approach using tput
        return 'git status --porcelain | grep "^??" | sed "s/^??/$(tput setaf 5)??$(tput sgr0)/"'
      end
    end

    local untracked_cmd, untracked_height =
      process_cmd(get_platform_specific_untracked_cmd(), 10, true)
    local diff_cmd, diff_height = process_cmd("git --no-pager diff --stat=60,40 -B -M -C", 20, true)

    -- local untracked_cmd, untracked_height = process_cmd('git status --porcelain | grep "^??"', 10)

    local cmds = {
      {
        icon = " ",
        title = "Git Changed Files",
        cmd = diff_cmd,
        height = diff_height,
        hl_pattern = {},
      },
      {
        icon = " ",
        title = "Git Untracked Files",
        cmd = untracked_cmd,
        height = untracked_height,
      },
    }

    return vim.tbl_map(function(cmd)
      return vim.tbl_extend("force", {
        pane = 4,
        section = "terminal",
        enabled = false,
        -- enabled = in_git,
        padding = 1,
        width = terms_width,
        ttl = 5 * 60,
        indent = 3,
      }, cmd)
    end, cmds)
  end,
}
