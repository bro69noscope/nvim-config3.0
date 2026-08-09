local NEXT_MODE = {
  smart = "ignore",
  ignore = "sensitive",
  sensitive = "smart",
}

local MODE_LABEL = {
  smart = "smart",
  ignore = "ignore",
  sensitive = "sensitive",
}

return function(picker)
  local current = picker.opts.case_mode or "smart"
  local new_mode = NEXT_MODE[current] or "smart"
  picker.opts.case_mode = new_mode

  picker._base_title = picker._base_title or picker.title
  picker.title = string.format("%s [%s]", picker._base_title, MODE_LABEL[new_mode])

  picker:find()
end
