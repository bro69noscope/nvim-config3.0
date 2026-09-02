; extends

(function_definition
  name: (identifier) @definition.name)

(call
  function: (identifier) @call.function_name)

(call
  function: (attribute
    attribute: (identifier) @call.method_name))

(call
  function: [
    (identifier) @call.name
    (attribute attribute: (identifier) @call.name)
  ])

(function_definition
  return_type: (_) @definition.return_type)

(function_definition
  parameters: (parameters) @definition.params
  !return_type)

(attribute
  attribute: (identifier) @variable.member.inner) @variable.member.outer
