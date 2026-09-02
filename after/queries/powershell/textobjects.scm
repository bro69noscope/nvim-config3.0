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

