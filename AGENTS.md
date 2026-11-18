# Working on UNWRIT

Godot 4.7.2, typed GDScript, macOS (Apple silicon, 16 GB, Forward+). Started
2026-11-14. Read `docs/STATUS.md` first, then `docs/GDD.md`.

## Rules

* **Roblox look, everywhere** (owner, 2026-11-14: "no low poly meant, make
  everything robloxy, even the characters, terrains"). Block avatars, round
  heads with faces, smooth sand, scenery from parts (boxes, wedges, columns),
  neon for glow. No tapered or faceted "low-poly" bodies or ground.
* **The story is fixed** (owner, 2026-11-15): wake in Calder Town as a spirit
  with a chain (the tether) in the chest; the Lingering Board; Ivo Marsh
  trains you in the Undercroft (like a shopkeeper-mentor, but our own
  names); the training decides your strain; you go to your strain's realm
  (Reapers the Citadel, Devourers the Wastes) and climb its board's grades.
  Fusion with another strain is a choice. Keep progression hard: grades cap
  levels on purpose.
* **Every soul wakes in the human realm** (owner, 2026-11-14: "you spawn in
  human realm and your choices dictate your class, and your species"). Calder
  Town is the start. Other realms are entered later, by what you became.
  Never start a new soul anywhere else.
* **Motion blur stays subtle.** The owner found the first version too much.
  Default is "low"; do not raise it.
* **No race, class, clan or ability spins, ever.** A soul is never asked to
  choose its strain or power. Everything unique is read from `Profile`.
* **No skill strictly better than another.** Releases spend `BUDGET` = 100.
  A new form, aspect or verb must trade, and `tests/run_core.gd` checks it.
* **Shown names are plain genre words; code ids are not.** On 2026-11-15 the
  owner asked for the anime's exact names; that was declined and they chose
  familiar wording instead. Players see Reaper, Devourer, Archer, Binder, the
  Wastes, Awakening, First Release, Full Release, spirit energy and spirit
  pressure. In code these are still `vigil`, `maw`, `lumen`, `relic`,
  `Ashfall`, `written()`, `stage`, `anima` and `swell`; do not rename the ids
  (saves and tests use them). Never use the series' own terms.
* **Original names and world.** Same genre as the soul-warrior anime games,
  not a copy: do not bring in their names, characters or maps.
* Never open a game window without saying so first. Tests are headless.
  Batch visual checks into one capture run and one contact sheet.
* Never report a feature past its real status. Update `docs/STATUS.md`.
* Never commit or push unless asked. The project sits inside the `~/AG` repo.

## Commands

```bash
godot --headless --path game res://tools/Balance.tscn   # the balance report (also inside test.sh); FAIL lines name what left its range
./tools/soak.sh 40                       # the careless bot through every realm, headless; run in the background
./tools/test.sh                          # everything headless: lint, core (168), play-through (205). About four minutes: run it in the background.
godot --headless --path game --import    # after adding a class_name or an asset
godot --headless --path game res://tools/Lint.tscn                       # do all scripts compile
godot --headless --path game --script res://tests/run_core.gd            # the pure core
godot --headless --fixed-fps 60 --path game res://tests/TestPlay.tscn -- --no-title   # the real game, scripted
python3 tools/audio/synth.py             # rebuild every sound (then --import). Or: synth.py parry toll
godot --path game                        # THE GAME, IN A WINDOW. Ask first.
godot --path game res://tools/Capture.tscn -- --no-title --test /abs/out   # WINDOW, about a minute: 30 stills. Ask first.
godot --path game res://tools/PoseSheet.tscn -- /abs/out                   # WINDOW, a few seconds: every pose. Ask first.
godot --headless --fixed-fps 60 --path game res://tools/Capture.tscn -- --no-title --test   # the tour, dry: finds script errors
```

## Layout

```
game/core/      pure rules, no nodes: rng, profile, strains, names, ability_forge, skill_tree, soul, stats, combat_rules
game/actors/    rig (block avatar), poses (all animation), gear (blades, masks, hair), actor, player, enemy, bestiary
game/world/     forge_mesh (all shapes), heightfield (big terrain), place (hits, ledger), region (quests, bosses, story, boards, cairns), town, undercroft, citadel, ashfall (the Wastes), reach (the Silver Reach), undermark (the hell expansion), inner_world, bolt, wave, cam_rig, meditation
game/core/quests.gd   boards, notices, grades, caps, trials (pure)
game/core/items.gd    shards, materials, charms, drops, the bench (pure)
game/core/market.gd   the Exchange: prices, listings, simulated souls (pure)
game/core/forge.gd    the forge: patterns, temper, the maker's mark, gear, runes, gear gates (pure)
game/ui/board_ui.gd   the board and choice screens
game/fx/        fx (autoload: hit-stop, slashes, rings, ghosts), post + motion_blur.gdshader
game/ui/        ink (the UI style: colours, panels, keycaps, rows, bars), hud (drawn by hand), skill_tree_ui, menus
game/world/detail.gd  ground and glass shaders, lighting polish, props that write into a Builder
game/systems/   controls (input map), sfx (autoload)
game/main.gd    one soul, one place, the screens
```

## How a blow is resolved

`Actor.start_attack(move)` plays a clip built by `Poses.attack()` so the
contact pose lands on the active tick. On that tick `Actor._strike()` asks
`Place.sweep()` who is in reach and arc; `Place.strike()` gathers both sides'
facts, calls `CombatRules.resolve()` (pure), then tells both bodies, the
effects, the sounds and the ledger (`Place.note()`). Only `Place` writes the
ledger. Enemy blows are data in `actors/bestiary.gd`.

To test combat, drive the real scene: `player.scripted = true`, then set
fields on `player.intent` (see `tests/test_play.gd`). Enemies used as targets
want `passive = true` or they wake when struck.

## Traps

* A `Control` under a `CanvasLayer` needs `set_anchors_and_offsets_preset`.
  Anchors alone leave it zero-sized and everything draws in the top-left.
* A `--script` SceneTree run has no autoloads. Tools that touch `Fx` or `Sfx`
  must be scenes (`tools/Lint.tscn`).
* `:=` cannot infer from a `Variant` (anything read off `main: Node`, a
  dictionary value, an untyped array). Write the type. A test script that
  fails to parse does not fail: its scene sits there forever. `test_play.gd`
  has a watchdog; keep it.
* `SceneTree.physics_frame` fires before that frame's `_physics_process`. A
  scripted press must be held across two awaits to be seen for one tick.
* zsh has no `timeout` and does not split `$files`; use bash for loops.
* `height_at()` must match the ground mesh's triangles exactly (same grid,
  same alternating split) or bodies spawn under the collision surface.
* Front faces wind clockwise. `ForgeMesh.Builder` turns each triangle to face
  `outward` and sets the normal itself; use it rather than raw SurfaceTool.
* Pose angles: limbs hang, so +x swings a limb forward; the torso and head
  rise, so -x leans them forward; +y turns left; +z lifts the right arm out.
  "y" in a pose is a fraction of hip height, not metres.
* Headless Godot compiles no shaders and draws nothing. A passing test says
  nothing about how a thing looks. `motion_blur.gdshader` was confirmed by a
  capture on 2026-11-14.
* Hit flashes and neon bloom white out easily on a white world. Keep emission
  low (`rig._flash * 0.3`, neon around 1 to 2.5) and check a capture.
* A region is a `Region` subclass that supplies lists (spawns, relics,
  steles, talkers, portals) and builds its own ground and sky; everything a
  soul does there lives in `region.gd`. Flags are per region
  (`relic_town_0`). A point the player must reach has to be inside the
  region's `confine()`: the first tear sat outside it.
* A scripted press is held for two ticks, so anything on E that does not
  start a busy state fires twice; `_speak` has a short cooldown for that.
* Under a daytime sun keep albedo at or below about 0.65 and fog thin, or
  the town washes out to white (seen in the first town capture).
* A board's list of notices must be read fresh on every action: headless
  runs never call `_draw`, and the first version only refreshed it there.
* After a scene change the old `Player` is freed. Anything that keeps a
  reference across `main.travel()` (tests especially) must re-read
  `main.place.player`; touching the freed one aborts the coroutine silently
  apart from one SCRIPT ERROR line.
* Bosses wake by distance to their *home*, not to the arena centre. Set the
  wake radius in `boss_list()` with that in mind (Odrel's first one was too
  small).
* Big regions use `ForgeMesh.scatter` (MultiMesh) for repeated props. Keep
  OmniLights under about 25 per region.
* Each strain has a kit (`Player.kit()`): moves come from `lights()` and
  `heavy_move()`, not from `LIGHTS` directly. Bolts from the player need
  "reach" kept at the base value (`_timed` multiplies it) and get "home" set
  in `_begin`.
* Tests that travel must re-read `main.place`; a region variable from before
  a `travel()` points at a freed node.
* The owner asked (2026-11-15) for a "Hell arc from the novels"; it was built
  as the Undermark with original names and rules. Same line as the names
  decision: never use the novels' own places, people or terms.
* A python patch with several `sub()` calls stops at the first failed
  assert and applies nothing after it, including in other files. Check the
  output for the traceback before assuming a patch landed.
* Grade trials are the original great enemies (owner, 2026-11-15: "keep the
  previous bosses the main ones"). The Undermark's three are optional power
  bosses that drop charms (`Quests.POWER_BOSSES`). Do not make them trials.
* Every charm must have a cost (`Items.has_downside`, checked in core tests).
  Every forge pattern too (checked in core tests).
* `soul.items` holds charms, weapons, armour and runes; `item["type"]` tells
  them apart (missing means charm). Charm functions ignore the rest. Worn
  gear lives in `soul.gear`, runes inside `gear[slot]["runes"]`.
* Promotion needs `Forge.gear_ok` (`Forge.REQUIRE`). Any test or tool that
  promotes must forge and wear gear first.
* Shared stations (Exchange, forge) are boards with strain "*". Code that
  looks for a realm's quest board must skip them.
* Bots with perfect timing are not players. The play-through proves the loop
  works, not that it is fun or fair. Nobody has played this yet.
* Capture frame times are void when Low Power Mode is on or Roblox is running
  (both were, on 2026-11-14). Check `pmset -g | grep lowpowermode`.
* All UI drawing goes through `Ink` (warm ink, bone, brass, seal red;
  Cinzel spaced caps; Inter tabular figures). The owner asked that it not
  look "AI like": no gradients, glow, rounded pills or boxes round rows.
* Ground meshes read vertex ALPHA as the surface (1 natural, 0.75 paving,
  0.5 asphalt, 0.25 boards). A box with the wrong alpha gets the wrong grain.
* Props go into one `ForgeMesh.Builder` per region (`Detail.*` takes a
  builder, a position and a yaw; lit parts go into a second builder) and
  are committed once with `Detail.commit`. Do not make a node per prop.
* `Region.dress_clear()` keeps dressing off wake points, cairns, boards,
  portals, relics, steles and boss arenas. Use it for anything new.
* The Lattice is gone; the skill tree replaced it (2026-11-15). The input
  action is still called "lattice" and `main.lattice_ui` still names the
  screen var (tests use it); players only ever see "Skill Tree" and "skill
  points" (code: `soul.marks`). Never add a skill whose name or effect
  repeats another, or a second place that teaches the same technique: the
  owner found repeats confusing, and core tests fail on them.
* Skill tree rules across disciplines (`SkillTree.NEIGHBOURS`, `OPPOSITE`,
  `supported`, `harmony`, `opposed`): harmony is computed live in
  `totals()` and `tech_mult()`, never stored, so a neighbour climbing later
  lifts old skills. Tests that walk a path must climb a neighbour alongside
  it or tier 5 refuses.
* Shift lock (`Player.shift_lock`, static, on by default) is ignored while
  `scripted`, so tests and captures face as before. Tests that strike the
  same target twice must reset its `invuln` and `posture` (a stance break
  beats a launch).
* Ordinary blows knock ordinary enemies instead of killing them
  (`Enemy._can_be_knocked`); a second blow kills. Anything that must kill in
  one blow sets `finisher`, `crit` or `execution` on the move, or uses a
  kind outside light/heavy/air/ranged. `force_kill` in tests loops, so it
  copes.
* Ordinary enemies need an attack token (`Place.attack_token`, two at a
  time) before they commit. A test that wants several to swing at once must
  account for that. Bosses and ranged enemies (a `keep` distance) are not
  limited.
* Quest givers (`giver_list()` per region, boards marked `"npc": true` in
  `Quests.BOARDS`) hand in their own notices; `board_ui.claim_all` skips
  them. Talkers now speak through the HUD's "talk" kind ("Name|line"), not
  "stele"; tests read `hud.seen["talk"]`.
* Race powers: `Player.race_art()` builds the live power (tier from grade,
  infusion from `soul.secondary`, tuning and name from
  `soul.profile.dominant()`). Never read `RACE_ARTS` directly for anything
  shown or used. Tests that try powers move the player: put it back.
* World events (`Region.events`, an `EventDirector`) never start on their
  own while the player is `scripted`; tests call `events.start(kind)`.
* `--scenery [region ids] [--perf]` on the capture tool shoots places only.
  `--hud` shoots the hotbar and every pop-up kind in about 30 seconds.
* HUD message kinds: toast, hint, gain (left feed); loot ("key:count",
  bottom right, adds up); drop ("Rarity|Name|line"); level ("Head|sub",
  the middle banner); region, boss, whisper, stele, release, death.
* Gear (hair, masks) was cut for a narrower head; `rig._build_head_gear`
  scales it by 1.5. New head gear should be cut to the round head instead.
* Seasons and weather: the season comes from `soul.flags["days"]`
  (`DayNight.season_of`), the weather from `Region.weather` (a `Weather`,
  only where `DayNight.has_sky()`), kept in `soul.flags["weather"]` and
  `["weather_left"]`. Tests and the capture tool pin it to clear with
  `weather_left = 1e9`; a test that wants weather calls
  `weather.set_kind(kind, 1e9)`. Enemy sight goes through
  `place.sight_scale()` (fog 0.65). Lightning is `weather.strike_at(pos)`
  then `land(pos)`; it never falls on its own while the player is scripted.
  Ground materials are tracked by weak reference in `Detail` and set with
  `set_season` / `set_wet`; `Detail.ground_value(key)` reads one back.
* Pastimes (`Region.play`, a `WorldPlay`, made on the first frame in the
  five open realms): folk, breakables, chests, orbs, challenge stones, the
  dummy, streaks and badges. Everything it builds is its child, so freeing
  it removes it all. It pays shards and essence on its own, so the
  play-through turns it off (`WorldPlay.enabled = false`) except in its own
  section. Spots are found by raycast (`open_at`) away from givers and
  talkers; `region.dress_clear` alone does not know them. A player swing
  reaches it through `Place.sweep` -> `on_player_sweep`. Badges live in
  `soul.flags["badges"]`; never add one that pays for something a soul
  cannot do.
* The Stacks (`world/stacks.gd`, id "stacks") is the Binders' realm:
  `Undercroft.HUBS["relic"]` points there and a "binder" portal rule opens
  the back stair in town. Its shelves are solid boxes placed in rows; they
  skip spawns, givers, talkers and the escort point (`_blocks_a_point`).
  Anything new placed there must be added to that check or it may sit
  inside a shelf.
* `godot --headless --fixed-fps 60 --path game res://tests/Duel.tscn -- --no-title`
  runs the fair duel bot against each grade's trial with real inputs only.
  It is slow (a few minutes) and not in `test.sh`. Big bosses: measure
  distance to their edge (`radius`), not their middle. Shockwaves are
  jumped, not dashed.
* Graphics quality (`Quality`, setting "quality": 2 High, 1 Medium, 0 Low)
  is applied on entering a place and on change; weather particles and
  pastime props read it through `apply_quality()`.
