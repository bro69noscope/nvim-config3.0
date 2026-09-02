; extends

(method_declaration
  name: (identifier) @definition.name)
(local_function_statement
  name: (identifier) @definition.name)
(constructor_declaration
  name: (identifier) @definition.name)

(invocation_expression
  function: (identifier) @call.function_name)

(invocation_expression
  function: (member_access_expression
    name: (identifier) @call.method_name))

(invocation_expression
  function: [
    (identifier) @call.name
    (member_access_expression name: (identifier) @call.name)
  ])

(member_access_expression
  name: (identifier) @variable.member.inner) @variable.member.outer
