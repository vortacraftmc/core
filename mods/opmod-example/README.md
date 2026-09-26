# LevelOp

Fabric mod for Minecraft 26.3 that extends the vanilla `/op` command with an
explicit permission-level argument.

## What it adds

- `/op <targets>` — unchanged vanilla behaviour (grants op at the level from
  `op-permission-level` in `server.properties`).
- `/op <targets> <level>` — **new**. Grants op at the given `level` (1-4),
  regardless of the server's default `op-permission-level`.

Both require permission level 3 to run, same as vanilla `/op`.

## Before building

1. Confirm the exact Yarn mappings build for 26.3 and put it in
   `gradle.properties` (`yarn_mappings`):
   ```
   curl https://meta.fabricmc.net/v2/versions/yarn/26.3
   ```
   Pick the top (newest) entry's `version` field.
2. Confirm Fabric Loader / Fabric API versions are still current on
   https://fabricmc.net/develop and https://modrinth.com/mod/fabric-api —
   this project was written against Loader 0.19.5 and Fabric API
   0.161.0+26.3.
3. You'll need JDK 25 installed (Minecraft 26.3 requires it).

## Build

```
./gradlew build
```

The mod jar will be in `build/libs/`.

## Notes on implementation

- No mixins are used. The mod registers an *additional* branch under the
  existing `op` command literal via `CommandRegistrationCallback`, so vanilla
  `/op <targets>` keeps working exactly as before.
- `PlayerManager#addToOperators` always writes the server-wide default
  level, so after calling it the mod re-writes the ops list entry
  (`OperatorEntry`) with the level actually requested and re-saves
  `ops.json`.
- `OperatorEntry`'s field names are Yarn-mapped and can rename between
  Minecraft drops. If the project fails to compile after a Minecraft/Yarn
  update, check `OpLevelHelper.java` first — the fix is almost always
  just updating a field/constructor name there.
