-- Reserved registers and marks used in the configuration, there is no guard against their manual
-- usage as of yet, but it might result in unexpected, sudden, automated overwrites.

-- reserved scratch registers for temporary use
_G.Scratch_registers = { "z", "y", "x" }

-- reserved marks set programmatically
_G.Automated_marks = { "Q" }
