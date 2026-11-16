---@meta

---@class snacks.picker.Config
---@field and_search? boolean grep: match all space-separated terms (see finders/egrepify.lua)
---@field _scope? string scope label from actions/rescope-picker.lua ("cwd", "git root", "all")
---@field _base_title? string picker title without the scope suffix
---@field _root_title? string picker title without the glob suffix (actions/input-grep-globs.lua)
