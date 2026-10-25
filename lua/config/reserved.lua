-- Reserved registers and marks used in the configuration, there is no guard against their manual
-- usage as of yet, but it might result in unexpected, sudden, automated overwrites.

-- reserved scratch registers for temporary use
_G.Scratch_registers = { "z", "y", "x" }

-- reserved marks set programmatically
_G.Automated_marks = {
  qf_jumps = { key = "Q", desc = "return to location pre qf jumps" },
  search_jumps = { key = "o", desc = "return to location pre word search jumps" },
}
