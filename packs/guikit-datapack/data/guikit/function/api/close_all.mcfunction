# guikit :: api/close_all
# Closes every open guikit menu on the server at once (map resets, minigame rounds, adventure
# transitions...). Runs api/close once per owner; players without an open menu are skipped.
#
#   function guikit:api/close_all
execute as @a[scores={guikit.uid=1..}] run function guikit:api/close
