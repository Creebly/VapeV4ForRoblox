# VapeV4ForRoblox
Vape V4 for Roblox

Personal fork maintained by Creebly, based on 7GrandDadPGN/VapeV4ForRoblox.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Creebly/VapeV4ForRoblox/main/NewMainScript.lua", true))()
```

The BedWars retirement kick is removed. AutoBank registers before the legacy BedWars initialization in standard, Micro, and Mega matches. Enable it in Inventory near a personal chest. Its resource transfers still rely on BedWars' inventory remotes, so current-game compatibility requires an in-game test.

Source lives in `src/`; generated scripts and assets live in `runtime/`. Build with `node scripts/build.cjs`. GitHub Actions rebuilds the runtime after source changes using this repository's built-in token. The runtime uses a separate `creeblyvape` cache and downloads from this repository.

Original author: [7GrandDad](https://github.com/7GrandDadPGN). Original credits are in CONTRIBUTING.md and the source. Original source license: CC0-1.0. The build helpers are from 7GrandDad's VapeBundler (ISC).
