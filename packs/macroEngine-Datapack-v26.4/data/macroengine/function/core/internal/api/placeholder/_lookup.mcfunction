# macroengine:core/internal/api/placeholder/_lookup [MACRO]
# Copies reg.<name> into cur when it exists (cur stays unset otherwise).
$data modify storage macroengine:placeholder cur set from storage macroengine:placeholder reg.$(name)
