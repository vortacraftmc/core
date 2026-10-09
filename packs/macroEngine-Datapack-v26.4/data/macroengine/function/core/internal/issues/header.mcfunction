# Header line. Runs as a macro over the whole storage object so `count` and
# `fetched_at` come straight from what packd wrote.
$tellraw @a [{"text":"[macroEngine] ","color":"gold","bold":true},{"text":"open issues","color":"white","bold":true},{"text":" ($(count))","color":"gray"},{"text":"  fetched $(fetched_at)","color":"dark_gray"}]
