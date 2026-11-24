; Textobjects for holy-tao/tree-sitter-autohotkey (AHK v2), used by mini.ai.
; Inner captures are quantified: mini.ai spans the first to the last node.

; functions
[
  (function_declaration)
  (method_declaration)
  (function_expression)
  (fat_arrow_function)
] @function.outer

(function_body
  (block
    "{"
    (_)+ @function.inner
    "}"))

; classes
(class_declaration) @class.outer

(class_body
  "{"
  (_)+ @class.inner
  "}")

; blocks
(block) @block.outer

(block
  "{"
  (_)+ @block.inner
  "}")

; conditionals
[
  (if_statement)
  (switch_statement)
] @conditional.outer

(if_statement
  body: (block
    "{"
    (_)+ @conditional.inner
    "}"))

(switch_body
  "{"
  (_)+ @conditional.inner
  "}")

; loops
[
  (loop_statement)
  (while_statement)
  (for_statement)
] @loop.outer

(loop_statement
  body: (block
    "{"
    (_)+ @loop.inner
    "}"))

(while_statement
  body: (block
    "{"
    (_)+ @loop.inner
    "}"))

(for_statement
  body: (block
    "{"
    (_)+ @loop.inner
    "}"))

; definitions (used by the ]f / [f moves)
(function_declaration
  name: (identifier) @definition.name)

(method_declaration
  name: (identifier) @definition.name)

(class_declaration
  name: (identifier) @definition.name)

(function_head
  (param_sequence) @definition.params)

(param_sequence
  (_) @parameter.inner)

; calls
[
  (function_call)
  (call_statement)
] @call.outer

(function_call
  function: (identifier) @call.function_name)

(call_statement
  function: (identifier) @call.function_name)

(function_call
  function: (member_access
    member: (identifier) @call.method_name))

(function_call
  function: [
    (identifier) @call.name
    (member_access
      member: (identifier) @call.name)
  ])

(call_statement
  function: (identifier) @call.name)

(member_access
  member: (identifier) @variable.member.inner) @variable.member.outer

; misc
(return_statement) @return.inner

[
  (line_comment)
  (block_comment)
] @comment.inner

[
  (integer_literal)
  (float_literal)
  (hex_literal)
] @number.inner
