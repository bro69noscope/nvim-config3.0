; extends

(function_declaration
  name: [
    (identifier) @definition.name
    (dot_index_expression field: (identifier) @definition.name)
    (method_index_expression method: (identifier) @definition.name)
  ])

(function_call
  name: (identifier) @call.function_name)

(function_call
  name: (dot_index_expression
    field: (identifier) @call.method_name))

(function_call
  name: (method_index_expression
    method: (identifier) @call.method_name))

(function_call
  name: [
    (identifier) @call.name
    (dot_index_expression field: (identifier) @call.name)
    (method_index_expression method: (identifier) @call.name)
  ])

(dot_index_expression
  field: (identifier) @variable.member.inner) @variable.member.outer
