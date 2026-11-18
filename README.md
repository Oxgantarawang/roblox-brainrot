# Brainrot Breakout

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun)
[![rank](https://make.fun/badge/roblox-brainrot-01/Oxgantarawang/roblox-brainrot/rank.svg)](https://make.fun)
[![reward](https://make.fun/badge/roblox-brainrot-01/Oxgantarawang/roblox-brainrot/reward.svg)](https://make.fun)

A 3D Roblox brainrot game for make.fun's
["Make the best AI Roblox brainrot game"](https://make.fun) bounty (roblox-brainrot-01).
Brainrots walk the central conveyor, you buy them with cash, park them on your own base
plot, and they earn money every second while you climb the rarity ladder — and run
home when the tsunami comes.

## The game

- **Conveyor:** brainrots spawn at the north end and walk south past the players.
  Walk up, read the floating label (name, rarity, mutation, $/s, price) and buy with
  the prompt. Unbought brainrots walk off the far end.
- **The cast (18 original characters):** Noodle Goblin, Toilet Trumpet, Sock Puppet
  Shark, Banana Knight, Cereal Box Wizard, Fridge Magnet Frog, Disco Pickle,
  Lawnmower Llama, Spaghetti Tornado, Grandma's WiFi Router, Quantum Burrito,
  Invisible Chair King, Moon Cheese Dragon, Time-Traveling Toaster,
  Sir Reginald III (a Pigeon), The Almighty Spud, CEO of Nonsense and Galactic
  Grandpa — across Common, Rare, Epic, Legendary, Mythic and Brainrot God.
- **Mutations:** Gold (x2), Diamond (x5) and Rainbow (x10) rolls make a find
  worth sprinting for.
- **Bases:** eight plots around the conveyor. Bought brainrots sit on your plot
  in slots and earn $/s, paid every second. Sell any of them back from the HUD.
- **Stealing:** click a brainrot on another player's base to steal it. Bases can
  be locked for 60 seconds (press L, or the LOCK BASE button); a steal costs the
  thief a 15-second cooldown and pays the victim a consolation cut.
- **Rebirth:** at the shrine (or the REBIRTH button), trade all your cash and
  brainrots for a permanent +25% income multiplier, compounding every rebirth.
- **Tsunami:** every 3 minutes a warning banner goes up and a giant wave sweeps
  the map north to south. Caught out in the open, you are flung back to spawn
  and lose 10% of your cash. Press B to dash home to your base — safe ground.

## How it is built

- `default.project.json` — the Rojo project: the 3D world (baseplate, conveyor
  with neon rails, eight base plots, spawn area, shop kiosk, rebirth shrine,
  trees, lamps, tsunami wall), the script services and the RemoteEvents.
- `src/shared/` — `BrainrotData.luau` (the roster, rarities, mutations, prices
  and rates) and `Config.luau` (every tunable number in one place).
- `src/server/` — `GameState.luau` (the single source of truth for player
  state), `Economy.luau` (income ticks, buying, selling, rebirth),
  `Spawner.luau` (the conveyor), `BasePlacer.luau` (brainrot models on bases),
  `Stealing.luau` (steals and base locks), `Events.luau` (the tsunami) and
  `init.server.luau` (wires it all together).
- `src/client/` — `Hud.client.luau` (cash, income, owned list, shop, lock and
  rebirth buttons, feedback line, tsunami banner) and `Interact.client.luau`
  (click-to-steal, B to dash home, L to lock).
- `main.ts` (Node 22, standard library only) hands the game in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out
  every name that starts with a dot, and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.

## Build and check

    ~/workspace/makefun/roblox-brainrot-01/tools/rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
    node <kit>/cli/makefun.mjs check --kit <kit> --repo <repo>

## Status

- `PLAY.json` still names no published place (zeros): the game has to be
  published from Roblox Studio on a Windows or Mac computer, which this Linux
  build machine cannot do. Publishing, the play link, real Studio screenshots,
  and the icon/thumbnail uploads are the remaining owner-side steps — see the
  repo's commit history and the bounty rules.
- `screenshots/` still holds the kit starter's placeholder captures until real
  Studio screenshots are taken.
