; extends

(method_declaration
  name: (identifier) @function.name)
(local_function_statement
  name: (identifier) @function.name)
(constructor_declaration
  name: (identifier) @function.name)

; Capture function names in function calls
(invocation_expression
  function: (identifier) @function_name)

; Capture method names in method calls
(invocation_expression
  function: (member_access_expression
    name: (identifier) @method_name))

; Capture both function name or method name
(invocation_expression
  function: [
    (identifier) @call_name
    (member_access_expression name: (identifier) @call_name)
  ])

(member_access_expression
  name: (identifier) @variable.member.inner) @variable.member.outer
