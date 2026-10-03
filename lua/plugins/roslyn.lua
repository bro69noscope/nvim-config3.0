return {
  "seblyng/roslyn.nvim",
  enabled = true,

  -- TODO: update after a while or try after/lsp again as suggested in
  -- https://github.com/seblyng/roslyn.nvim/issues/385#issuecomment-5717213750
  commit = "de9a98d61ed3fd01b5016eea5fe9e32f1a4c7cfb",

  ft = "cs",
  opts = {
    settings = {
      ["csharp|inlay_hints"] = {
        csharp_enable_inlay_hints_for_implicit_object_creation = true,
        csharp_enable_inlay_hints_for_implicit_variable_types = true,
      },
      ["csharp|code_lens"] = {
        dotnet_enable_references_code_lens = true,
      },
    },
  },
}
