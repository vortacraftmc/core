# guikit — in-game GUI editor

Menus are built **in the world**, not by writing `.mcfunction` files.
A chest minecart is the screen. Left-click is the click. Definitions live in
`storage guikit:lib` (saved with the world) and survive `/reload`.

Target: Minecraft Java **26.3** (`min_format` / `max_format` **121**).

The cart / click / redraw engine underneath is the old guikit runtime. Authoring
moved off the `#guikit:fill` / `#guikit:probe` framework and into an editor.

## Install

Drop this pack in the world's `datapacks` folder and `/reload`.
On first load it seeds a published **Welcome** menu so there is something to open.

## Play

Anyone (no operator permission):

```
/trigger guikit.open
```

That opens the list of **published** menus. A one-time chat line suggests the same command.
Joining players are told once.

## Edit (operators)

`/function` is permission level 2, so the editor is operator-only:

```
/function guikit:editor/open
/function guikit:help
```

1. **Menu list** — emerald creates a menu, a book opens it.
2. **Editor chest** — slots 0–25 are the menu. The bottom-right book is **Tools**
   (not part of the menu). Slot 26 of a real 27-slot menu is edited from Tools → Edit slot 26.
3. Hold the item you want as the icon, left-click a slot, pick an action in the dialog.
4. Tools: pages, rename, container, timeout, publish / hide, preview, delete.

Preview is the real menu. Chat suggests `/function guikit:editor/resume` to come back.

### What a click can do

| Action | Effect |
| --- | --- |
| Decoration | Icon only, not clickable |
| Give held item | Gives that item, optional fixed cost (diamond / emerald / gold / iron) |
| Message | Plain tellraw (`interpret:false`) |
| Close | Closes the menu |
| Go to page | Pages `0`–`8` |
| Open another menu | Picker, no typed ids |
| Toggle | Per-player on/off, gray dye when off |
| Counter +1 | Per-player score, clamped, value printed in chat |
| Sound | One of six built-in sounds, only the clicking player hears it |
| Web link | Clickable `https` link in chat; the menu closes so chat is visible |
| Command | Stored command, see trust model below |

Container presets: chest, hopper (5 slots), barrel, ender chest, trapped chest, shulker box, copper chest.
Themed chests are still a `chest_minecart` with a different pane and title — Minecraft has no barrel entity to summon.
A hopper menu only has slots 0–4; the editor marks the rest red.

Timeout is how long the menu stays open (15–180 seconds). The editor itself uses a long timeout so a dialog does not eat it.

## Trust model

- Building menus requires `/function` (operator).
- **Give / message / sound / page / toggle / counter** do not run arbitrary commands.
- A **command** widget runs at datapack function permission (default 2), **as the clicking player, for any player who can open the menu**. Same trust as a command block behind a button. Do not put player-typed text in it. The command dialog rejects nothing by itself: do not put an apostrophe (`'`) in the command, or the save line will not parse.
- Names, messages and lore must not contain `"` or `\`. Dialog text is escaped into the function call; the function stores it as a string and later shows messages with `interpret:false`.
- Menu ids are generated (`m1`, `m2`, …). Players never type them.

Backup / inspect:

```
/data get storage guikit:lib
```

## How it is stored

```
storage guikit:lib
  order: ["m1", "m2"]
  menus.m1: {n, name, container, timer, published, pages:[{widgets:[...]}]}
```

`guikit:reg` is still rebuilt every `/reload` (that is the engine). Saved menus are
registered again from `guikit:lib` by `guikit:runtime/register`. Do not `data remove storage guikit:lib`.

Per-player editor state is `storage guikit:ed p<pid>` and is not wiped on close, so a dialog can resume the editor.

## Opening a menu from a command block

```
function guikit:play/open_id {menu:"m1"}
```

`m1` is the generated id (`/data get storage guikit:lib order`).

## Engine notes (advanced)

`#guikit:register`, `#guikit:fill`, `#guikit:probe`, `#guikit:clear_tags` and `#guikit:on_close`
still exist and are **not** `replace: true`, so another pack can still add a listener.
`#guikit:on_open` is new: it runs after the cart is bound and before the first redraw.
The editor's fill/probe no-op unless this open set `guikit:ed pending`.

Widget helpers (`guikit:widget/*`) are unchanged and are what the editor draws with.
Prefer the editor for new menus. A hand-written `#guikit:fill` pack still works beside it;
do not clear `guikit:lib` from that pack.

Click detection is still “the widget item landed in the inventory”.
`clear` is filtered by `custom_data~{guikit:{w:1b}}` and only runs after a count.
See `guikit:internal/selftest` if a world wipes inventories — that bug was never proven.

## Limits

- Not verified in a live 26.3 client. Load the pack and read `latest.log`.
  `mecha` is not a substitute; it does not validate macro lines.
- Editor slot 26 is the Tools button. The stored widget for slot 26 still shows in play / preview.
- Icons are item ids, not full stacks (no enchantments copied off the held item).
- Hopper menus: slots 5+ are not shown.
- Command widgets and links are macro-expanded. Quotes in a name, or an apostrophe in a command, fail that save instead of injecting a second command (vanilla has no command separator, but a broken macro line is still a failed save).
- Dialog buttons run as the player, so they need operator permission. That is why editing is `/function` and playing is a chest click / trigger.
- Two operators editing the same menu: last write wins.
- Donkey / mule containers are still registered by the engine and still refused (unchanged).
