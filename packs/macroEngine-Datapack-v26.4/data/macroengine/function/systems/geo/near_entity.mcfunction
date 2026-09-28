$execute as @a[name=$(player),limit=1] at @s if entity @e[type=$(type),tag=$(tag),distance=..$(distance),limit=1] run $(invoke)
