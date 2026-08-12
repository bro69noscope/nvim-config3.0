; extends

; Capture function names in function calls
(call_expression
  function: (identifier) @function_name)

; Capture method names in method calls
(call_expression
  function: (member_expression
    property: (property_identifier) @method_name))

; Capture both function name or method name
(call_expression
  function: [
    (identifier) @call_name
    (member_expression property: (property_identifier) @call_name)
  ])

; Capture return type annotations
(function_declaration
  return_type: (_) @return_type)
(function_expression
  return_type: (_) @return_type)
(arrow_function
  return_type: (_) @return_type)
(method_definition
  return_type: (_) @return_type)
(generator_function_declaration
  return_type: (_) @return_type)

; Capture function parameters (no return type)
(function_declaration
  parameters: (formal_parameters) @function_parameters
  !return_type)
(function_expression
  parameters: (formal_parameters) @function_parameters
  !return_type)
(arrow_function
  parameters: (formal_parameters) @function_parameters
  !return_type)
(method_definition
  parameters: (formal_parameters) @function_parameters
  !return_type)

(member_expression
  property: (property_identifier) @variable.member.inner) @variable.member.outer
