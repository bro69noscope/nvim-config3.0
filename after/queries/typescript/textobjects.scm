; extends

(call_expression
  function: (identifier) @call.function_name)

(call_expression
  function: (member_expression
    property: (property_identifier) @call.method_name))

(call_expression
  function: [
    (identifier) @call.name
    (member_expression property: (property_identifier) @call.name)
  ])

(function_declaration
  return_type: (_) @definition.return_type)
(function_expression
  return_type: (_) @definition.return_type)
(arrow_function
  return_type: (_) @definition.return_type)
(method_definition
  return_type: (_) @definition.return_type)
(generator_function_declaration
  return_type: (_) @definition.return_type)

(function_declaration
  parameters: (formal_parameters) @definition.params
  !return_type)
(function_expression
  parameters: (formal_parameters) @definition.params
  !return_type)
(arrow_function
  parameters: (formal_parameters) @definition.params
  !return_type)
(method_definition
  parameters: (formal_parameters) @definition.params
  !return_type)

(member_expression
  property: (property_identifier) @variable.member.inner) @variable.member.outer

(function_declaration
  name: (identifier) @definition.name)
(generator_function_declaration
  name: (identifier) @definition.name)
(function_expression
  name: (identifier) @definition.name)
(method_definition
  name: (property_identifier) @definition.name)
(variable_declarator
  name: (identifier) @definition.name
  value: [(arrow_function) (function_expression)])
