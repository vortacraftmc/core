# macroengine:api/placeholder/load
# Registers the built-in placeholders. Idempotent; called from macroengine:setup.
#
# Built-ins (all resolve for the executor, i.e. @s):
#   %player%   executor name          %name%    alias of %player%
#   %nl%       line break             %percent% a literal percent sign
#   %%         a literal percent sign (handled by the parser, not the registry)
data modify storage macroengine:placeholder reg.player set value {selector:"@s"}
data modify storage macroengine:placeholder reg.name set value {selector:"@s"}
data modify storage macroengine:placeholder reg.nl set value {text:"\n"}
data modify storage macroengine:placeholder reg.percent set value {text:"%"}

# Live entity values of the executor, resolved by the text engine at display time.
#   %health%  current health   %food%  food level   %xp_level%  XP level   %dimension%  e.g. minecraft:overworld
data modify storage macroengine:placeholder reg.health set value {nbt:"Health",entity:"@s",plain:true}
data modify storage macroengine:placeholder reg.food set value {nbt:"foodLevel",entity:"@s",plain:true}
data modify storage macroengine:placeholder reg.xp_level set value {nbt:"XpLevel",entity:"@s",plain:true}
data modify storage macroengine:placeholder reg.dimension set value {nbt:"Dimension",entity:"@s",plain:true}
