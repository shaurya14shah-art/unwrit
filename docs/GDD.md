# UNWRIT: design

A fast, parry-based action RPG about the dead. Block avatars, a pale afterlife,
and one rule above the rest: **nothing about your soul is picked from a menu.**
You arrive with no strain, no power and no name. What you do decides what you
become, and no two souls end up the same.

This is its own game. It sits in the genre of soul-warrior RPGs and shares
that genre's structure (a spirit weapon released in stages, devourers that
evolve, a trial inside your own blade), but the world, names, characters and
systems below are original.

Status words used here: **Built** (in the game and tested), **Designed**
(written, not built). `docs/STATUS.md` is the truth about what exists.

## 1. Pillars

1. **Unwritten.** No race screen, no class, no ability spin, no clan roll.
   A soul starts blank and identical in power to every other.
2. **Read, not chosen.** The game keeps a ledger of how you actually fight
   and breathes it back to you as your instinct, your spirit, your scars.
3. **Equal budgets.** Every released blade spends the same 100 points. Yours
   is different from mine, never better.
4. **The parry is the game.** Fights are decided by timing and stance, not
   by who has the bigger number.
5. **You live there.** Sitting, breathing, devouring or sending on the dead
   are acts in the world, not menu entries.

## 2. The world and the story (Built)

You die in **Calder Town**, in the living world, and wake beside your own
roadside memorial with a **tether** hanging from your chest: a short chain,
what is left of your tie to the living. The living cannot see you. The
**Ledger** names every soul that dies; you are missing from it, which is why
you are *Unwrit* and why you can still become anything.

1. **The prologue (Calder Town).** A Reaper up the street tells you what you
   are. The **Lingering Board** by your memorial has three notices: put down
   five strays, remember two keepsakes, and kill **the Gutter King** in the
   flats courtyard. Your tether rusts a link every four minutes and every
   time you devour one of the fallen. Levels stop at 6 until you are trained.
2. **The training (the Undercroft).** **Ivo Marsh**, the shopkeeper, takes
   you down into the cavern under his shop.
   - *The Drill*: three parries, two slips, three training frames broken.
   - *The Cut*: Marsh severs what is left of your tether (each link left
     counts toward the Reaper). In the pit three waves come while a hunger
     bar fills; if it fills you start the Cut again.
   - *The Stillness*: sit at the cellar cairn, breathe, and beat the one in
     your blade. This is the **Awakening**: your strongest strain is fixed
     and your blade is named.
3. **Your realm.** Marsh opens a gate to where your strain belongs:
   Reapers to **the Citadel**, Devourers to **the Wastes**, Archers to
   **the Silver Reach**, Binders to **the shop** in Calder Town.
   Each has a board, its own notices and its own climb.

- **Spirit energy**: spent on techniques, returns over time.
- **Spirit pressure**: what gathers when you fight well. Full pressure releases a named blade.
- **Stance**: every body has one. Fill an enemy's and it breaks open.
- **Essence**: what the fallen leave. Levels a soul.

## 2b. Grades, boards and promotion (Built)

Every awakened soul starts at **Grade 5** and climbs to Grade 0. Each grade
**caps your level** (10, 18, 28, 40, 55, none), so levelling alone stops
quickly. To rise you need two things: **standing**, earned by handing in
notices at your board (60, 140, 260, 420, 650), and your grade's **trial**: a
great enemy chosen by your strain. Promotion grants three marks, raises the
cap, and changes your body.

| Strain | Titles | Trials (Grade 5 → 1) |
| --- | --- | --- |
| Reaper | Unseated, Seated, Officer, Lieutenant, Captain, Commander | Thane, Many-Mouthed, Vael, Odrel, Sereth |
| Devourer | Husk, Colossus, Stalker, Sovereign, Crowned Sovereign, the Hunger Itself | Many-Mouthed, Odrel, Sereth, Thane, Vael |
| Archer | Initiate, Archer, Lantern Archer, Starbearer, Constellation, Polestar | Drowned Hound, Odrel, Ysolde, Vael, Sereth |
| Binder | Touched, Binder, Keeper, Twin-Bound, Reliquary, the Remembered | Drowned Hound, Many-Mouthed, Odrel, Sereth, Vael |

- Boards hold **story notices** (once) and **bounties** (repeatable). Three
  can be carried at once. A board serves its own strain, or a grafted one.
- Every stage **trades**: a Colossus has more vitality and stance but moves
  slower; a Stalker is faster and thinner; Reapers' parry window widens;
  Archers' techniques hit harder but they are frailer; Binders' spirit
  energy returns faster.
- Devourers change shape the most: a masked Husk, a hulking Colossus, a lean
  long-legged Stalker, then a Sovereign who looks almost human again.
- Enemies scale with **their own** level, never yours, and pay less essence
  once you outgrow them. Dying costs half your carried essence and a little
  standing.
- **Full Release** (the blade's second stage) comes with promotion to
  Grade 2, scarred by how you won your Grade 3 trial.

## 3. The four Strains (Built)

Nobody picks one. Each grows from acts:

| Strain | What it is | Fed by |
| --- | --- | --- |
| **Reaper** | The answer to what is done to you. Bladework, guard. | parries, blocks, cuts, sending souls on |
| **Devourer** | Hunger. | devouring the fallen, trading blows, killing near death |
| **Archer** | Gathering the light that is left. | thrown and returned bolts, perfect dodges, breath |
| **Binder** | Remembering what things were. | techniques, relics, reading steles |

- **The Awakening** (Built): when your blade is named, your strongest strain is
  fixed. You become a Reaper, a Devourer, an Archer or a Binder. Your body changes to show it.
- **The Graft: a choice** (Built). Once you reach Grade 3 and a second
  strain has grown past 60, resting at a cairn asks: let it in, or refuse.
  Letting it in makes you a hybrid, changes your body, opens the second
  strain's board to you and gives you that hybrid's own art: Grave Answer
  (Revenant: a counter that feeds you), Falling Star (Seraph: leap, land as
  light, hunting shards), Exhibit (Curator: hold everything near, stance half
  broken), Black Sun (Eclipse: drag in and burn), Worship (Idol: everything
  turns to you, you mend and harm barely lands), Star Map (Constellate: eight
  shards out in a ring, then hunting). Refusing keeps
  you pure for good: sharper cuts and faster spirit pressure. Six hybrids: **Revenant** (Reaper+Devourer), **Seraph**
  (Reaper+Archer), **Curator** (Reaper+Binder), **Eclipse** (Devourer+Archer), **Idol**
  (Devourer+Binder), **Constellate** (Archer+Binder).
- Designed, not built: each hybrid's own moves; a third stage of forms; the
  Devourer's body-evolution ladder (Husk, Colossus, Stalker, Sovereign) with the
  choice to break the mask.

## 4. The ledger (Built)

`Profile` counts swings, hits by kind, parries, blocks, dodges, hits taken,
kills, devours, technique uses, time near death and how you breathe. From it
come ten habits, each 0 to 1: aggression, patience, mobility, range, risk,
hunger, precision, weight, craft, stillness. Everything unique reads these.

## 5. What makes a soul unique (Built)

- **Look**: hair, skin, face, coat and build come from the seed.
- **Sealed blade**: its length, curve and width come from the seed.
- **First instinct**: after three kills a technique surfaces, picked from how
  you fought them (a patient soul gets Still Guard; a mobile one Sever Step).
- **Techniques set to you**: a technique takes its numbers from your stats at
  the moment it sets and a **quirk** from your strongest habit (Restless,
  Measured, Desperate, Starved...). Same technique, different soul, different
  technique.
- **The Stillness**: sit at a cairn and breathe. Hold to draw in, let go to
  release. There is no right way; steady, sharp or held breaths lean your
  aspect. Then you fight **the one in your blade**, which has your shape and
  reads your habits (a patient soul's spirit parries more).
- **How you beat it decides the verb**: parrying gives *Answer* (a counter
  stance), heavy offence *Sunder* (a long cut), thrown splinters *Thread* (a
  homing volley), winning near death *Ember* (a ring that feeds you), dodging
  *Mirage* (a blink behind), blocking *Bastion* (a ward).
- **The released blade**: aspect (14, each with one of seven effects) x form
  (7 weapon shapes) x verb (6), with a 100-point budget split over power,
  reach, speed and craft, plus a generated name ("Shilosai, the Ninth Toll").
- **Scars**: how you beat a great enemy scars the blade (Full Release,
  stage 2): Tollbreaker, Long-Hunger, Unbroken, Far-Sight, Afterstep.

## 6. The Skill Tree (Built, 2026-11-15)

It replaced the Lattice. The owner found the Lattice confusing: the same
skills came up again on different paths, which made a custom build hard
to plan. They asked for "more generic" names and something "easier to
progress, not so complicated, yet unique".

`core/skill_tree.gd`, screen `ui/skill_tree_ui.gd` (K).

**Four disciplines.** Each has one stat, renamed to plain words: Blade,
Body, Speed, Spirit (code ids edge, frame, tempo, focus).
- Swordsmanship (Blade)
- Hand-to-Hand (Body)
- Footwork (Speed)
- Spirit Arts (Spirit)

The owner's examples were the anime's own discipline names. Plain generic
names were used instead, per the naming decision.

**How a path works:**
- Each discipline is one straight path of eight tiers, read top to bottom,
  and a tier opens when the one above it is taken.
- Tiers 3 and 6 are forks: two skills side by side, and taking one closes
  the other for good. Forks are where builds part.
- Tier 8 is a capstone, and every capstone is a trade (for example One Cut:
  +25% heavy cuts, +10% light cuts, -10% vitality).
- Past it, Mastery ranks (+2 to the stat each) go on forever, so the tree
  has no top.

**Every skill exists once.** No name or effect repeats, and each of the six
techniques is taught in exactly one place (tier 4 of each path, plus one
side of the tier-6 fork in Hand-to-Hand and Spirit Arts). Core tests check
both. A technique you already know (your instinct technique, say) is honed
instead of given twice: +12% damage and an 8% shorter cooldown.

**Still unique.** A skill's percentage sets from the habit behind it when
you take it (0.8x to 1.2x: a heavy hitter's Heavy Hand is stronger than a
dancer's). The two forks per path also split builds, and rites make one
stat feed another (Momentum: light cuts per 10 Speed).

**Cost:** 1, 1, 2, 2, 3, 3, 4, 5 points by tier, 2 per Mastery rank. Two
skill points come per level and three per promotion. A path costs 21 to
walk, so by mid-game you finish two disciplines and dip into a third.

Each card shows its effect on its face, and hovering gives the whole text
plus what blocks it. Old saves get every point the Lattice took back.

**The disciplines lean on one another** (2026-11-15). The owner asked for
"a system that affects one another ... forcing balanced and non
overpowering builds". The four sit on a square:

    Swordsmanship -- Footwork
         |               |
    Hand-to-Hand  -- Spirit Arts

- **Support.** Tiers 5 to 8 need a neighbour no more than three tiers
  behind: tier 5 needs a neighbour at 2, up to tier 8 needing one at 5.
  No discipline can be rushed alone.
- **Harmony.** A discipline's skills, and the techniques it taught, grow
  stronger live as both neighbours climb: +6% per tier of the shallower
  neighbour, up to +30%. Advancing one discipline strengthens what you
  already took in another. A two-path build gets nothing from it; a
  rounded build does.
- **Opposition.** Swordsmanship and Spirit Arts are opposites, and so are
  Footwork and Hand-to-Hand. Holding both capstones of an opposed pair
  doubles both their costs. You can have everything, but not for free.

**The screen** (redrawn 2026-11-15; the owner called the card grid "slop
like and like ai"). The tree is drawn as a chart:
- Your unspent points sit in a seal at the centre.
- The four disciplines grow out of it toward the four corners, so
  neighbours sit side by side and opposites face each other across the
  seal. The shape states the rules, and no caption has to.
- Faint arcs join neighbouring roots, thickening with the harmony between
  them. A dashed thread crosses the seal between opposites and turns red
  when both of their capstones are held.
- Skills are small engraved marks: three dots for a stat, a chevron for a
  gain (a red underline if it trades), linked rings for a rite, the
  technique's own mark, a hexagon for the capstone, a dashed ring for
  Mastery. Held marks fill with the discipline's colour, reachable ones
  breathe in brass, and closed forks are struck through.
- Names appear only on the mark you point at or select.
- The right-hand panel inspects the selected mark: its effects as large
  figures (live, with habit and harmony), a ticked or crossed list of
  what it needs, and a Learn button (E). Under that are your numbers and
  techniques (click one to move its key). Selecting first and learning
  second ends accidental spending.

## 7. Combat (Built)

**Feel like the Roblox soul-reaper fighters** (2026-11-15). The owner asked
for it to "feel more like the Type Soul games or any other Roblox Bleach
game". The first batch, built on that genre's conventions:
- **Keys:** Q dashes, Shift (held) runs, Ctrl toggles shift lock. Dash and
  run used to share Shift.
- **Shift lock, on by default:** the body faces where the camera looks and
  strafes, the camera sits further over the right shoulder, and a small
  reticle marks the centre of the screen. Off, the body turns to face
  where it walks, as before.
- **Five-cut strings:** the blade and the claws now chain five light cuts.
  The last one is a finisher, and it goes three ways:
  - Plain, on the ground: it knocks them flying.
  - Holding jump: it launches them upward, and you rise after them to keep
    cutting in the air.
  - In the air, the third cut slams them down with a ring.
  Knocked bodies keep flying in the air instead of stopping dead.
- **Feints:** guard during a heavy's wind-up to call it off and bait a
  parry, with a 1.4 s cooldown.
- **Evasive** (Q while being hit, every 12 s), batch 2. It bursts out of a
  combo:
  - A ring throws near enemies back and chips their stance.
  - Your own stance recovers by a third.
  - You get a moment of safety and a dash away.
  It does not work from a broken stance, which stays punishable. It
  replaces the old free dash out of any hit after 0.2 s.
- **Critical** (T, every 9 s), batch 2:
  - A slow strike with hyper-armour that no guard stops. A parry still can.
  - It gives the same tell enemies give for their unguardable blows: a red
    glint, a "!" and the warning sound.
  - Each kit swings its own: the blade a lunging thrust, the claws a wide
    rending sweep, the chain a pulling lash, the bow a three-arrow
    piercing volley.
  - R stays the Release.
- The critical and the evasive have two small slots left of the hotbar
  tray, with a cooldown sweep and a flash when ready.
- **Movement and air** (batch 3):
  - **Double jump:** one extra jump in the air, given back on landing. It
    carries your run in the direction you hold.
  - **Juggles:** a hit landed in the air gives back an air dash and the
    second jump, so juggles keep going.
  - **Wall bounces:** a body knocked hard into a wall rebounds off it. It
    takes 3% of its vitality, has its stance chipped, and stays helpless a
    little longer, open to a follow-up (once per knock). Big knocks keep a
    body stunned for their whole flight.
  - **Ragdoll fling:** flung bodies tip over backwards while they fly and
    right themselves with a puff of dust when they land.
- **Knocked, grip, carry** (batch 4):
  - **Knocked:** an ordinary enemy beaten by an ordinary blow (light,
    heavy, air or ranged) does not die. It drops to its knees, knocked,
    for 7 s. Any further blow finishes it, and left alone it gets back up
    with a quarter of its vitality. Finishers, criticals, executions,
    techniques and releases kill outright. Bosses and training echoes are
    never knocked.
  - **Grip (B):** kneel over a knocked enemy for 1.3 s to finish it. It
    gives +20 spirit pressure, a little vitality, extra essence and style.
    Being hit breaks the grip, and the enemy's knock timer starts again.
  - **Carry (V):** lift a knocked enemy or a remnant over your shoulder. You
    move at 70% and drop it if hit. LMB throws it at the nearest enemy (or
    where you face). It hits the first enemy it reaches (heavy damage, a
    knock and a launch), and a knocked body does not survive the landing.
    V puts it down.
  - **Ragdoll death:** a dying body keeps its momentum. It flies and
    slides, tumbles in the air, bounces once when it lands and comes to
    rest at its own angle.
  - Prompts name the keys: "B Grip it · V carry it", and on a remnant
    "E Devour · G send on · V carry".
- **Enemy AI and bosses** (batch 5):
  - **Pack turns:** at most two ordinary enemies press you at once (attack
    tokens in `Place`). The rest hold a ring a few metres further out and
    strafe, and the pressure rotates round the pack as tokens lapse.
    Ranged enemies and bosses do not wait.
  - **Openings:** any enemy that can reach you attacks at once if your
    swing misses.
  - **Guards:** humanoid ordinary enemies sometimes guard the back half of
    a string (from the third cut).
  - **Criticals:** enemies that react dodge criticals rather than block
    them.
  - **Gap dash:** quick ordinary enemies close a long gap (6 to 15 m) in a
    dash, every few seconds.
  - **Grab:** past half vitality, every great enemy learns a grab. It is
    red, unguardable and unparryable, so it can only be dodged. It holds
    you, then throws you. The evasive breaks it.
  - **Enrage:** at a quarter vitality a great enemy is enraged: it moves
    faster and rests only 60% as long between attacks.
  - **Winded:** after every four swings a great enemy stops, winded, for
    1.4 s (1.0 s enraged). It is a clear window to punish.
- **Questing and NPCs** (batch 6):
  - **Quest givers:** people who ask stand in every hub:
    - Mira Okafor and Old Pell in Calder Town
    - Officer Hana Ves at the Citadel outpost
    - Kesh, a husk who stopped eating, at the Wastes' arrival
    - Odile the lamp-keeper in the Silver Reach
  - **Marks and plates:** a gold "!" floats over a giver with something to
    ask, and a pale "?" when something is ready to hand in. Every talker
    and giver wears a name plate (name and what they do) seen from close
    by. The compass shows givers ("!") and lost souls.
  - **Talking:** E opens their offer as a choice, Accept or Not now. Their
    notices are handed in to them, not at boards, and they pay shards as
    well as essence and standing.
  - **Three kinds of ask:**
    - **Deliveries** (eight ash bone, six oath steel, ten mask shards,
      eight lantern glass) are ready the moment the materials are in hand,
      and talking hands them over. They tie the quests to the economy.
    - **Escorts:** a lost soul waits somewhere in the region, kneeling. E
      takes their hand, and they follow you, drifting through walls (they
      are dead), until they reach the one who asked.
    - Hunts, as on the boards.
  - **Dialogue box:** all talk now shows in a box above the bars: a name
    tab and the line typed out. It replaces the stele card that talkers
    used to borrow.
- **World events** (batch 7, `world/events.gd`): every 3 to 8 minutes of a
  realm's quiet, once a soul has awakened, one event starts. It is never
  in the Undercroft and never mid-fight. A title card, a red compass mark
  and a card under the compass (objective and time left) announce it.
  - **Rift raid** (4 min): a black-and-red rift opens 35 to 70 m away.
    Three waves of the realm's own enemies (3, 4, 5) come through, then a
    Warden of the Rift: a Stone elite with triple vitality. Seal it for
    essence, shards, three material piles and a 40% chance of a charm. If
    the time runs out, the rift closes and takes its brood.
  - **The Tall's march** (3.5 min, not in town): a Tall with twice the
    vitality crosses the realm from edge to edge. It fights anything that
    picks a fight. Bring it down for the same spoils, or it walks out.
  - **Spirit storm** (2 min): fog and light turn red. Two restless dead
    rise near you every 20 s, elites are 30% likelier, and every kill pays
    half again.
- **Sound and impact** (batch 8): eleven new synthesised sounds:
  - Moves: critical, evasive, grab, finisher, air jump.
  - Bodies: a body thud for throws, wall bounces and landings, and the
    knocked sound.
  - Events: the rift's tear and the event horn.
  - Quests: a chime for taking a quest and one for handing it in.
  Impact now scales with the blow: a hit that takes a big share of an
  enemy's vitality stops time longer (40 to 120 ms), shakes harder and
  throws more sparks. A critical landing adds red sparks and a pale flash.
- **Settings and controls** (batch 8, `systems/settings.gd`): from the
  title or the pause menu.
  - Settings: mouse sensitivity (0.5x to 2x), field of view (60 to 90),
    master, music and effects volumes (their own buses), shift lock at
    start, and motion blur.
  - Each is one button that steps to its next value, saved at once to
    user://settings.cfg.
  - A Controls page lists every key, grouped: moving, fighting, bodies,
    everything else.
- **Spirit sense** (Z, held; batch 9): spends 6 spirit energy a second to
  feel every enemy within 70 m, with a pulse ring every 1.2 s. Each shows
  on the compass with its level and a colour for how it stands against
  you: grey weaker (4 or more levels below), bone even, red stronger (4 or
  more above, or any great enemy).
- **The record** (pause sheet): kills, great enemies beaten, events won,
  notices done, deaths.
- **Race powers** (X; batch 10). Each race has its own power and passive.
  Before awakening, X does nothing.

  | Race | Power (X) | Passive |
  | --- | --- | --- |
  | Reaper | Binding Art (cast; rods pin the nearest enemy 2 s, a great enemy 0.8 s) | Discipline (+15% parry window) |
  | Devourer | Iron Hide (6 s: 40% less harm, no flinch) | Regrowth (out of the fight 5 s, knit back 1.5%/s) |
  | Archer | Rail Step (a long glide with i-frames; arrows fly three at a time for 2.5 s) | Gather (+40% spirit energy return) |
  | Binder | Grapple (chain to an enemy within 20 m, zip in, strike) | Memory (+3% damage per keepsake, up to 15%) |

  A grafted second strain gives half of its own passive.

  **The power grows with its soul** (the owner asked for powers that change
  "as the player progresses, their race combines or a new stage is
  reached"):
  - **Stage:** a second form at Grade 3, a third at Grade 1.
    - Reaper: II binds two; III binds all near the first, and the rods
      burn.
    - Devourer: II throws 30% of each blow back at its striker; III ends in
      a roar that throws the near ones back.
    - Archer: II holds two charges; III cuts what the rail crosses.
    - Binder: II's strike stuns; III jumps the chain on to a second enemy.
  - **Fusion:** a grafted strain infuses every use:
    - Devouring heals 6%.
    - Radiant fires three homing shards.
    - Sworn: the next 3 s of hits break stance 25% harder.
    - Chained drags enemies within 7 m in.
  - **The hand:** the strongest habit tunes it. Aggression returns sooner,
    patience lasts longer, mobility and range reach further, risk and
    weight hit harder, hunger feeds you, precision breaks stance, craft
    and stillness cost less.
  - **Its name** is built from all three, for example "Measured Devouring
    Binding Art II". A banner announces each change ("Your power
    deepens").
  - **HUD:** the slot right of the tray shows the power's short name and
    numeral, a stripe in the infusing strain's colour, charges as
    diamonds, and a bar while Iron Hide or a volley runs.
- **Day and night** (batch 11, `world/daynight.gd`):
  - **The clock:** one for the whole soul (`soul.flags["clock"]`: 0 dawn,
    0.25 noon, 0.5 dusk, 0.75 midnight). A day lasts 24 real minutes, and
    a new soul wakes in the morning.
  - **Where:** Calder Town and the Citadel turn. The Wastes stay in their
    night, the Silver Reach in its violet twilight, and the Undermark and
    the Undercroft have no sky.
  - **The look:** the sun climbs and sets, and by night the same light is
    a low pale moon. The sky warms to orange at dawn and dusk and goes
    deep blue at night. Lamps, signs, paper screens and lit windows burn
    up to twice as bright. A spirit storm's red sky wins over the clock
    while it lasts.
  - **Night play:**
    - In town, two in three of the living go home.
    - Once awakened, a wanderer comes up near you every 30 s (up to ten
      about).
    - Elites are 10% likelier, and every kill pays a quarter more.
  - **HUD:** a sun or moon mark beside the compass names the time: Dawn,
    Day, Dusk or Night.
- **Seasons and weather** (batch 13, 2026-11-16; `world/weather.gd`,
  seasons in `world/daynight.gd`):
  - **Seasons:** spring, summer, autumn, winter, three in-game days each
    (`soul.flags["days"]`, counted when the clock passes midnight; a new
    soul wakes in spring). Natural ground takes a season tint (autumn
    browns, spring greens) and winter lays snow on open, level ground
    (ground shader `season_tint` and `snow`). Paving, asphalt and boards
    keep their colour.
  - **Weather** turns every 3 to 6 minutes in Calder Town and the
    Citadel, drawn from the season's odds, and is kept in
    `soul.flags["weather"]` so it is still raining when you come back:

    | Season | Clear | Rain | Fog | Thunderstorm | Snow |
    | --- | --- | --- | --- | --- | --- |
    | Spring | 4 | 3 | 2 | 1 | - |
    | Summer | 6 | 1 | 0.5 | 2 | - |
    | Autumn | 3 | 3 | 3 | 1 | - |
    | Winter | 3 | - | 2 | - | 4 |

  - **Rain:** streaks fall round you, the ground darkens and turns glossy
    (wets in about 20 s, dries over 90 s), its own sound, cloud dims the
    sun. Enemies see you from 85% as far.
  - **Fog:** thick grey air. Enemies notice you from only 65% as far, so
    you can slip past or open on them.
  - **Thunderstorm:** heavier rain, and every 4 to 8 s lightning. A pale
    ring warns where it will fall (1.1 s), then it hurts everything
    inside 3 m: an eighth of your vitality, a quarter of an ordinary
    enemy's, 8% of a great enemy's. Four bolts in ten seek an enemy near
    you, so you can lure them into it. Bolts never fall on their own
    while the player is scripted.
  - **Snow:** winter only. Flakes drift round you and snow lies deeper
    while it falls. Enemies see you from 85% as far.
  - A spirit storm (world event) keeps its red sky and fog; the weather's
    rain, wet ground and lightning carry on under it.
  - **HUD:** the time mark beside the compass reads, for example,
    "DUSK · AUTUMN · RAIN".
- **The Stacks** (batch 15, 2026-11-17; `world/stacks.gd`): the Binders'
  realm, down the back stair of the shop in Calder Town (open to
  Binders, and to anyone of Grade 3). An archive about 440 m across with
  board floors, rows of shelves 7 to 15 m tall and aisles between them,
  no sky, and paper lanterns hanging on chains in the dark. In the middle
  the Binding Wheel turns: a pillar of light inside a ring of chain. The
  hub holds the Shop Ledger (the same notices as the shop upstairs), an
  Exchange and a forge; Wren Halloway keeps the Stacks, and Quill mends
  the bindings and gives three notices (four mask shards for the Wheel; a
  lost reader by the Wheel; five chainbound). The shop board adds "Dust
  the Shelves" (ten kills in the Stacks). 18 enemies, levels 8 to 14,
  chainbound in the deep shelves. Binders are sent here after training.
  Its own music loop. Pastimes too: 6 folk, crates and urns, chests,
  orbs, an orb rush and a parry drill.
- **Graphics setting** (`systems/quality.gd`): High, Medium or Low. Low
  turns off ambient occlusion and sun shadows, renders at 75%, thins rain
  and snow to a third and shortens how far small props show.
- **First-time tips:** the first time a soul meets folk, a crate, a chest,
  an orb, a challenge stone, the dummy, night, or each kind of weather,
  one line says what it is for. Never again after.
- **Pastimes** (batch 14, 2026-11-16; `world/world_play.gd`, badges in
  `core/badges.gd`). In Calder Town, the Citadel, the Wastes, the Silver
  Reach and the Undermark (not the Undercroft):
  - **Folk:** 5 to 10 souls per realm, each with a name, a line about
    what they do, and their own lines. Every third word is about the
    moment (night, rain, fog, storm, snow, or a soul not yet awakened).
    Some wander a few steps; all of them crouch when an enemy is fighting
    near. Kinds:
    - givers: a few shards once a day (a "!" floats over them while it
      waits)
    - seers: mark the nearest closed chest on the compass for 2 minutes
    - trackers: say how many orbs are left and mark the nearest one
    - trainers: stand by the dummy
  - **Breakables:** 28 crates, barrels, urns or bone heaps per realm, in
    heaps of two to four. A swing breaks them, or E. 55% pay 1 to 3
    shards (more with level), 20% drop a realm material, 5% heal 10%.
    They are back when you return to the realm.
  - **Chests:** 5 per realm (wood, silver, gold; the last and furthest is
    gold). E opens one; it fills again the next in-game day. They pay
    shards (6, 12 or 25 kills' worth) and 1, 2 or 3 rolls of realm
    materials; gold can hold a charm. 12% of silver and gold chests are
    mimics: an elite with 1.6x vitality that pays the chest twice when
    it falls.
  - **Spirit orbs:** 30 in town, 24 elsewhere; one in four floats high
    (jump or double jump). Each pays 2 shards and a little essence, and
    a quick run of them rings higher. All of a realm's: 150 shards.
  - **Challenge stones:** two per realm, each with one challenge:
    - Slay: 6 kills in 60 s, three at a time
    - Orb Rush: 10 gold orbs in 45 s, some up high
    - Parry Drill: 4 parries in 60 s against a sparring foe with 5x
      vitality

    Gold with 45% of the time left, silver with 20%, else bronze. Pay 40,
    80 or 160 shards (more at higher grades), a third of that unless you
    beat your best; first gold adds a silver chest's worth. A stone will
    not start during a world event, and world events wait for it.
  - **Training dummy:** one per realm, by the trainer. Each blow shows
    its damage; over its head, damage a second over the last 5 s and the
    best.
  - **Kill streaks:** kills within 3 s of each other: DOUBLE, TRIPLE,
    QUAD, RAMPAGE, paying 2 shards per kill in the streak.
  - **Badges:** 30 (core/badges.gd), each paying 0 to 600 shards when
    earned, shown as a card in the pickup feed. They count kills,
    parries, crates, chests, mimics, orbs, folk met, medals, dummy blows
    and damage, lightning, night kills, streaks, awakening, promotion,
    shards held, forged gear, realms visited and the lost brother.
  - **Pause sheet:** the record shows badges, chests opened and orbs.
- **Balance pass** (batch 12, 2026-11-16; `tools/balance.gd`, in
  `./tools/test.sh`). Nobody has played past the start, so this is
  balance by numbers. For a representative soul at each grade's cap (skill
  points spent down two neighbouring disciplines, gear at the grade's bar)
  the report measures:
  - time to kill the realm's enemies, and the trial
  - ordinary hits to die, and the trial's biggest hit as a share of
    vitality
  - each kit's light-string damage a second
  - minutes of nonstop fighting to climb the grade
  - kills to afford the next gear bar

  It fails the tests when a number leaves its range:

  | Measure | Range |
  | --- | --- |
  | Ordinary enemy down in | 3 to 8 s |
  | Ordinary hits to die | 8 to 16 |
  | Trial down in | 40 to 130 s |
  | Trial's biggest hit | 15 to 38% of vitality |
  | A grade's climb | 5 to 90 minutes of fighting |
  | Every kit | within 20% of the best |

  What it found and what changed:
  - **Grades 3 to 1 took 5 to 14 hours of grinding:** every hub enemy was
    far below the soul, so essence collapsed. Ordinary enemies now stand
    no more than three levels below an awakened soul (`Region
    .scaled_level`; the Undercroft keeps its own), and the soul's current
    trial stands at its grade's level cap (`Region.trial_level`).
  - **Souls died in 5 to 7 hits, and trials took 41 to 50% a blow:** a
    soul now gains 3% vitality and 2.5% damage per level. Enemies grow
    slower: 8% vitality (was 12), 5% harm (was 8) and 14% essence (was 18)
    per level. The Many-Mouthed's beam went from 38 to 34.
  - **The climb then swung too fast,** so the essence curve is steeper:
    60 + 22 x level^1.55 (was 26 x level^1.4).
  - **Now:**
    - The climb takes 7, 13, 23, 35 and 59 minutes of fighting for
      Grades 5 to 1.
    - Ordinary enemies fall in 4.6 to 6.2 s and kill you in 8 to 11 hits.
    - Trials take 44 to 110 s, and their biggest hit takes 27 to 35%.
    - Kits: blade = claws, chain 90%, bow 86% (it pays for range).

**Each race fights its own way** once awakened (released, everyone fights
with the form their spirit took):

| Race | Light | Heavy | Dash |
| --- | --- | --- | --- |
| Reaper | three-cut blade chain | a heavy cut with armour | **Flash Step**: a 9 m teleport, safe for a moment |
| Devourer | a four-hit claw flurry | **Maw Beam**: a charged beam that pierces through a line | **Rend**: the dash tears what it passes |
| Archer | arrows of light that home on the nearest enemy, at range | a charged piercing shot | **Sky Step**: two dashes in the air, with lift |
| Binder | a bound chain with long reach | **Pull**: the chain yanks an enemy to you | a quicker dash |

**Executions.** Heavy near an enemy whose stance is broken is one great
cut that nothing guards: three times a heavy (at least 7% of a great
enemy's vitality).

**Style rank.** Hits, parries, slips, kills and executions raise a rank from
D to SS, more for variety; getting hit drops it by more than half, and it
fades when you stop fighting. Each rank adds 6% to the essence from kills.


- **Light** chain of three, **heavy** with armour, **air cut**.
- **Guard**: held, it takes chip and stance damage. Raised within the parry
  window as a blow lands, it is a **parry**: no damage, the attacker's stance
  suffers, and your next cut is a riposte. Mashing the guard shrinks the window.
- **Dash** with a short safe moment. Through a blow at the last instant is a
  **slip** and feeds spirit pressure.
- **Red blows** cannot be guarded. Ground rings can be jumped.
- **Stance break**: a full bar opens the enemy for a long moment.
- **Lock-on**, input buffering, cancel windows, hit-stop, shake, afterimages,
  motion blur on turns and speed.
- **Techniques** (six kinds: Sever Step, Rising Arc, Pale Lance, Low Toll,
  Still Guard, Gnash) on keys 1 to 4.
- **Release** on R when the diamond is full. R again spends spirit pressure on the verb.
- The rules live in `core/combat_rules.gd`: pure, so a server can own them.

## 8. The dead (Built)

A fallen enemy leaves a remnant. **Devour** it (heal, more essence, Devourer) or
**send it on** (spirit energy, spirit pressure, Reaper and Archer). This is the game's quiet
choice and it is made hundreds of times.

## 9. The realms (Built)

| Realm | Size | Levels | What is there |
| --- | --- | --- | --- |
| **Calder Town** (living world) | ~420 m | 1 to 6 | river with a weir and five bridges, downtown towers, the flats, school, park with cairn and tear, the shop, Lantern House, warehouses, the Ledger Gate; 5 cairns, 7 keepsakes, 4 people to speak to |
| **The Undercroft** (under the shop) | ~260 m cavern | 1 to 4 | the yard, the pit, the cellar cairn, the gate to your realm |
| **The Citadel** (Reapers) | ~600 m | 6 to 17 | the Lower Rings and outpost, the great wall and gate, white-walled lanes and blue-roofed halls, the Spire; 4 cairns |
| **The Wastes** (Devourers) | ~790 m | 6 to 24 | dunes, the Crystal Undergrowth, the bone fields, the Bell Court, the Sunken Throne, the Breach; 5 cairns |
| **The Silver Reach** (Archers) | ~500 m | 9 to 15 | snow under endless twilight, a frozen lake ringed by lantern towers, pine woods, the Lantern Spire; aurora; 4 cairns |

Travel: the Lantern Door at Lantern House (Archers, or anyone of Grade 3)
to the Silver Reach; the tear in the park (named souls) to the Wastes; the Ledger Gate
(Reapers, or anyone of Grade 3) to the Citadel; the Breach links the
Citadel and the Wastes; the shop's cellar stairs (after the prologue) to the
Undercroft.

**Great enemies (8).** Ysolde, the Last Lantern (the Lantern Spire) fights
from range with volleys and an unparryable piercing shot. The Gutter King (flats courtyard), the Drowned Hound
(the weir), Thane the living gate (the Citadel's wall), Vael Morrow the
Oathbreaker (the Spire), the Many-Mouthed (the Undergrowth), Odrel the
Bell-Eater (the Bell Court), Sereth Queen of Dunes (the Sunken Throne).
Each sleeps until you walk into its ground and has a second phase at half
vitality. Once beaten it leaves its mask where it fell: touch the mask to
call it back for a **rematch**, three levels stronger each time, for less
essence than the first.

**The living.** Calder Town has people walking its pavements and cars on
its roads. They cannot see you, and you pass straight through them.

**Music.** Each realm has its own loop: a soft major melody for the town,
slow plucked strings over a drone for the Citadel, glass bells for the
Reach, a far bell over a drone for the Wastes, war drums for great enemies.

**Enemies (9 kinds).** Husks, stray hounds (fast lunges and pounces),
gleaners and wraiths (bolts you can parry back; wraiths throw fans), rogue
reapers (they guard and dodge your swings), stone sentinels (armoured, a red
stomp), stalkers (fast chains and pounces), gravebrutes, and the Tall
(towering, red beams that cannot be parried, only blocked or dodged).

Death returns you to the last cairn you sat at, in whichever realm it is.

## 9b. The Undermark expansion (Built)

The hell beneath every realm, where souls struck from the Ledger are
chained. Original to this game: its own places, people and rules.

- **Getting there.** A seal in the far south-west of the Wastes breaks for
  any soul of Grade 2. Every board gains a repeatable notice for it.
- **The place (~570 m).** Black rock and lava rivers under a red dark;
  three chain bridges; great chains hanging out of the sky; cages; the
  Branded King's court of braziers in the west; Gaoler Prime's iron yard in
  the east; a white throne on an island in a lake of fire in the north.
- **Its rules.** Every death there **brands** you: -6% vitality each, up
  to five, until you leave. Lava burns and slows. **Gaolers re-form** twelve
  seconds after they fall unless someone devours them or sends them on.
  One enemy in four is an elite.
- **Enemies.** The **Damned** (they mend when you stop hitting them), the
  **Chainbound** (they hook and drag you in), **Gaolers** (huge, armoured,
  they drag and re-form), **Cinders** (fire that keeps burning).
- **Elites, everywhere from level 6 up.** One in eight ordinary enemies is
  born with an affix: Swift (faster, quicker blows), Stone (more vitality
  and stance, armoured), Leeching (heals from what it lands), Volatile
  (explodes when it dies: get away). Elites glow and pay more essence.
- **Power bosses, not trials** (owner, 2026-11-15). The **Branded King**
  (chains, burning waves, a falling judgement), **Gaoler Prime** (a giant
  who wears the Undermark's chains) and **the First Unwrit** (the first soul
  ever struck from the Ledger; sealed until Grade 1) are optional. Each
  drops its own charm every time it is beaten, rematches included, which is
  what feeds the economy.
- **Last Release.** Beating the First Unwrit gives your blade its last
  name, a third stage after First and Full Release. Released, it hits 25%
  harder, lasts 40 seconds instead of 26, and six blades turn about you.

## 9c. Loot and the economy (Built)

- **Shards** are the currency. Every kill pays them at once (more for
  elites, twenty times more for great enemies).
- **Materials** drop by enemy kind and lie on the ground until you walk
  over them: ash bone, mask shards, lantern glass, oath steel, eyes of the
  Tall, bell bronze, dune glass, brand iron, gaoler links, unwritten ink.
  Great enemies always drop their own.
- **Charms**, worn three at a time (I). Every charm rolls a gift and a cost
  inside its ranges, graded Common, Fine, Rare or Mythic by how well it
  rolled, so no two are quite alike and none is simply better than going
  without. The power bosses drop the strongest (Crown of Brands, Prime
  Link, Blank Page); the bench (I, A to G) makes seven more from materials
  and shards.
- **The Exchange**, a board in every hub (Calder Town, the Citadel outpost,
  the Wastes' arrival, the Reach). Sell materials at a price that falls as
  the market floods and recovers over time; buy what other souls list; list
  your charms at your price and they sell while you play if the price is
  fair. A tenth of every sale goes to the Exchange. The other souls are
  simulated for now, but listings, prices and the sale log are plain data a
  server can own when the market goes online. Forged pieces are listed and
  sold there too.

## 9d. The forge and gear gates (Built)

Materials are what you build with. Every hub has a forge (an anvil, a
furnace and a quench trough, next to the Exchange). Its four shelves:

- **Weapons**, tiers 1 to 5: Bone-Edge, Oath Blade, Glassfang, Bellforged,
  Brandsteel, the Unwritten Edge. They hit harder as the tier rises and are
  slower, or trade stance damage for speed (Glassfang). One to three rune
  sockets. A forged blade takes its metal's colour and length on your body;
  tier 3 and up holds a glow in the edge.
- **Armour**, tiers 1 to 5, in three looks built from blocks: hide (straps
  and furred shoulders), robe (long coat, mantle, trim in the cloth's
  colour) and plate (pauldrons, breastplate, fauld). More life and stance,
  less speed; the robes trade stance for spirit energy.
- **Runes**, set into sockets: Ember (chance to burn), Frost (chance to
  slow), Leech (heals a share of each hit), Storm (chance to arc a third of
  the hit to another enemy), Ward (less harm taken), Haste (faster, softer),
  Echo (shorter technique cooldowns, dearer techniques). Each costs
  something. Pull them out and move them freely.
- **Charms**: the old bench, now a shelf of the forge.

**Your own way of building.** Each piece rolls inside its pattern's ranges.
Up to two **temper** materials (three of each) push it toward what that
material is: bone for life, mask shards for stance, glass for technique
damage, oath steel for a wider parry, an eye of the Tall for heavy blows,
bell bronze for faster release, dune glass for speed, brand iron for damage,
gaoler links for stance damage, ink for cheaper techniques. The temper
scales with the piece's tier. The maker's strongest habit marks the piece
too: a parrier forges *Patient* steel (a wider parry), a dodger *Fleet*, a
reckless fighter *Reckless* (more damage, less life). So the name says how
it was made: "Patient Oath Blade of Brand Iron and Eye of the Tall".

**Gear gates the grind.** A grade will not let you go until you wear the
gear its trial expects, on top of standing and the trial:

| Leaving grade | Weapon tier | Armour tier | Runes set |
| --- | --- | --- | --- |
| 5 | 1 | - | - |
| 4 | 2 | 1 | - |
| 3 | 3 | 2 | 1 |
| 2 | 3 | 3 | 2 |
| 1 | 4 | 4 | 3 |

The higher tiers need materials from the realms and the Undermark (bell
bronze, brand iron, gaoler links, dune glass, unwritten ink), so climbing
means farming, trading at the Exchange, or both.

## 10. Designed, not built

- A realm of their own for Binders (they live in Calder Town for now), and
  deeper layers under the Wastes.
- The living in the town: people who cannot see you, and what the strays do
  to them if you let them.
- Factions that court each strain and treat hybrids differently.
- Weapon bonding beyond stage 2 (a true name, earned by a second trial that
  the spirit fights with your own released form).
- Duels against other souls' saved builds, then live play. Combat is already
  split so the rules can run on a server.
- Raids, world events, trading: only after the solo game is good.
- No pay-to-win, no spins, ever. Cosmetics only.

## 11. Look and sound

Roblox-style throughout: block avatars (2x2x1 torso, 1x2x1 limbs, round head
with a face), smooth sand, scenery built from parts, neon for the one colour.
Every shape is built in code (`world/forge_mesh.gd`, `actors/rig.gd`), every
animation is a pose table (`actors/poses.gd`), and every sound is synthesised
(`tools/audio/synth.py`). Nothing is imported except two open fonts.

**Detail** (`world/detail.gd`, 2026-11-15). The owner asked for "more
intricate details in scenery and the UI to a next level but don't make it
AI like". Scenery:
- One ground shader for every realm reads vertex alpha as a surface:
  natural ground gets large patches and speckle, paving gets slabs with
  seams, asphalt gets grit, boards get planks. Per realm: sand ripples and
  sparkle in the Wastes, sparkle in the Reach's snow, faint ember veins in
  the Undermark (kept dim so real lava still reads), loam in the Undercroft.
- Ambient occlusion and a light grade on every realm (`Detail.polish`).
- Calder Town: towers with plinths, corner piers, floor bands, framed
  windows (some lit, some curtained), a shopfront and canopy, roofs with a
  parapet, hatch, AC units, vents, water tanks and antennas. Houses with
  siding, corner boards, shutters, window boxes, a door with frame, step
  and lamp, fascia, ridge and chimney. Shops with striped awnings, lit sign
  letters, mullioned windows and an A-frame board. Streets with kerbs,
  garden edging, lamps, bins, hydrants, mailboxes, street signs, traffic
  lights and bollards at the big crossings, manholes, poles and sagging
  wires behind the houses, a bus stop, a bike rack and planters.
- The Citadel: timber-framed halls with lit paper screens, double doors
  and hanging lanterns, ribbed tile roofs with a ridge, turned-up ends and
  eave brackets; the wall with a stone base, a beam band, arrow slits and
  roofed towers; stone lanterns and banners down the avenue; a rutted road.
- The Wastes: ribcage arches, rock falls, masks half sunk in the sand. The
  Undermark: black glass spires with burning seams, gibbets, broken stone.
  The Reach: ice shards and snow drifts. The Undercroft: rock falls and
  timber props.

**The UI** (`ui/ink.gd`) is drawn in one deliberate style, the Ledger's ink
and paper, so it reads as this game's and not a template:
- Warm black panels with one hairline rule and corner ticks. Bone text,
  muted brass for what you can act on, seal red for danger.
- Spaced small capitals for headings, each running into a hairline rule.
  Keycaps for every key, tabular figures so numbers line up.
- No gradients, no glow, no rounded pills, and no box round every row.
- HUD: ticked bars with a red trail for damage taken, a ruler compass with
  a shape per marker, an objective card, toasts on ink strips, a keycap
  prompt, and title cards flanked by rules.
- The board, gear, forge, Exchange, title and pause screens follow the
  same style. The forge shows costs as material swatches and tiers as pips.
- The hotbar (2026-11-15, owner: "better formats"):
  - One tray of ink holds four square slots and the release slot, set apart
    by a rule.
  - Each technique has an engraved mark per kind, drawn in single strokes:
    sever, rise, lance, toll, guard, gnash, and the six hybrid arts.
  - Each slot shows its key, its spirit cost (red when you cannot pay), a
    clock sweep with seconds while it returns, a white flash the moment it
    is back, and its short name under the tray.
  - The release slot fills with spirit pressure from the bottom and
    flashes when full. Empty slots are dashed and silent.
- Pop-ups each have their own place and form:
  - Messages on the left carry a mark of their kind (brass diamond for a
    gain, keycap frame for a hint, a rule for the story).
  - Key names inside a message (LMB, SHIFT, F, [K]) are drawn as keycaps.
  - The same line twice counts up (x2) instead of stacking.
  - Pickups gather bottom right, one line per material, adding up while
    you walk over more. A dropped charm gets a card in its rarity colour.
  - Levels and grades get a banner in the middle with what they give.
