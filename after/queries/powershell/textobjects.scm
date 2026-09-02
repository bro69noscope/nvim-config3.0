; extends

(function_statement
  (function_name) @definition.name) @function.outer

(command
  command_name: (_) @call.name) @call.outer

(function_statement
  (script_block
    (param_block
      (parameter_list) @definition.params)))

(script_parameter) @parameter.inner

(member_access
  (member_name) @variable.member.inner) @variable.member.outer

(for_statement) @loop.outer
(foreach_statement) @loop.outer
(while_statement) @loop.outer
(do_statement) @loop.outer

(if_statement) @conditional.outer
(switch_statement) @conditional.outer

(comment) @comment.inner

(attribute) @attribute.inner

(integer_literal) @number.inner
(real_literal) @number.inner

(invokation_expression
  (member_access
    (member_name) @call.method_name))
