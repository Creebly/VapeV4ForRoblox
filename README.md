# VapeV4ForRoblox
Vape V4 for Roblox

Personal fork maintained by Creebly, based on 7GrandDadPGN/VapeV4ForRoblox.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Creebly/VapeV4ForRoblox/main/NewMainScript.lua", true))()
```

The BedWars retirement kick is removed. AutoBank appears under Inventory throughout the BedWars experience, including the lobby, and registers before universal or legacy game initialization. Join a match and enable it near a personal chest to transfer resources. Enabling it in the lobby explains that a match is required. Its resource transfers still rely on BedWars' inventory remotes, so current-game compatibility requires an in-game test. The loader refreshes the main script and AutoBank on each normal run to avoid stale copies.

Source lives in `src/`; generated scripts and assets live in `runtime/`. Build with `node scripts/build.cjs`. GitHub Actions rebuilds the runtime after source changes using this repository's built-in token. The runtime uses a separate `creeblyvape` cache and downloads from this repository.

Original author: [7GrandDad](https://github.com/7GrandDadPGN). Original credits are in CONTRIBUTING.md and the source. Original source license: CC0-1.0. The build helpers are from 7GrandDad's VapeBundler (ISC).
