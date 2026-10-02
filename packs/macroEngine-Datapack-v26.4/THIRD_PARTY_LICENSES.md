# Third-Party Licenses

macroEngine's own code is released under the Unlicense (see `LICENSE`).
The components below are third-party work and stay under their own licenses.
Keep this file in every distributed copy of the pack (MIT requires the
copyright and permission notice to ship with copies or substantial portions).

## StringLib — CMDred

- Upstream: https://github.com/CMDred/StringLib
- License: MIT (verified against upstream `LICENSE`, copyright 2024 CMDred)
- Use here: macroEngine does not bundle StringLib's files. The string module
  is a macroEngine-native re-implementation that follows StringLib's
  algorithms (CharMap, reverse lookup, split) and keeps its interface.
  Treat it as a derivative work and keep the notice below.
- Affected paths (all under `data/macroengine/function/`):
  - `core/lib/string/*`
  - `core/internal/string/**` (including `util/*` and `zprivate/*`)

### License text

MIT License

Copyright (c) 2024 CMDred

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Not third-party (listed for clarity)

- Minecraft vanilla registries, tags and command syntax are referenced, not
  redistributed. No Mojang assets are included in this datapack.
- Companion resource pack (`macroEngine-Resourcepack-v26.4`) is a separate
  artifact and must carry its own license file.
