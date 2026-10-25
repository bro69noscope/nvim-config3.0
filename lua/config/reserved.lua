-- Reserved registers and marks used in the configuration, there is no guard against their manual
-- usage as of yet, but it might result in unexpected, sudden, automated overwrites.

-- reserved scratch registers for temporary use
_G.Scratch_registers = { "z", "y", "x" }

-- reserved marks set programmatically
_G.Automated_marks = {
  -- global
  qf_jumps = { key = "Q", desc = "return to location pre qf jumps" },
  buffer_browser_jumps = { key = "B", desc = "return to location pre buffer browser jump" },
  -- local
  search_jumps = { key = "o", desc = "return to location pre word search jumps" },
  snacks_words_jumps = { key = "r", desc = "return to location pre snacks words jumps" },
}
