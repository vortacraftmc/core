# macroengine:api/cmd/other/multi_cmd_adv [MACRO]
# Advanced multi-command execution with options.
# INPUT (macro args): $(list) — command list; $(options) — options compound
#

$data merge storage macroengine:input {list:$(list),options:$(options)}

function macroengine:api/cmd/other/multi_cmd/advanced/run_with_options
