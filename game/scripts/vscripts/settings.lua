-- In this file you can set up all the properties and settings for your game mode.
USE_DEBUG = false                       -- Should we print statements on almost every function/event call? For debugging.
KILL_VOTE_RESULT = {}
KILL_VOTE_DEFAULT = "NORMAL"
EFFECT_VOTE_RESULT = {}
EFFECT_VOTE_DEFAULT = "DISABLE"
FAST_BOSSES_VOTE_RESULT = {}
FAST_BOSSES_VOTE_DEFAULT = "DISABLE"
GOLD_VOTE_RESULT = {}
GOLD_VOTE_DEFAULT = "DISABLE"
EXP_VOTE_RESULT = {}
EXP_VOTE_DEFAULT = "DISABLE"

PLAYER_DONATOR_LIST = {} -- Never touch this, it's populated automatically

NEW_GAME_PLUS_VOTE_RESULT = {}
NEW_GAME_PLUS_VOTE_DEFAULT = "0"
NEW_GAME_PLUS_NETWORTH_SCALE = 1000000
NEW_GAME_PLUS_SCALING_MULTIPLIER = 1.65
NEW_GAME_PLUS_DAMAGE_REDUCTION_SCALING_ADDITION = 30

DUMMY_TARGET_DPS_CHECK_DURATION = 30

AUTOLOOT_ON = 1
AUTOLOOT_OFF = 0
AUTOLOOT_ON_NO_SOULS = 2

GOLD_BANK_MAX_LIMIT = 1000000000

MAX_ALLOWED_RUNES = 6

PVP_CP_CAPTURE_TIME = 15
PVP_CP_HOLD_TIME = 90
PVP_CP_AKASHA_CAPTURES = 100 -- How many times they need to capture the CP for Akasha to spawn
PVP_KILL_LIMIT = 100 -- Kills required to win

WAVE_VOTE_RESULT = {}
WAVE_VOTE_DEFAULT = "DISABLE"

DIFFICULTY_ENEMY_BOUNTY_EASY = 2.0
DIFFICULTY_ENEMY_DAMAGE_EASY = 0.5
DIFFICULTY_ENEMY_HEALTH_EASY = 0.5
DIFFICULTY_ENEMY_ARMOR_EASY = 1.0

DIFFICULTY_ENEMY_BOUNTY_NORMAL = 1.0
DIFFICULTY_ENEMY_DAMAGE_NORMAL = 1.0
DIFFICULTY_ENEMY_HEALTH_NORMAL = 1.0
DIFFICULTY_ENEMY_ARMOR_NORMAL = 1.0

DIFFICULTY_ENEMY_BOUNTY_HARD = 1.0
DIFFICULTY_ENEMY_DAMAGE_HARD = 1.5
DIFFICULTY_ENEMY_HEALTH_HARD = 1.5
DIFFICULTY_ENEMY_ARMOR_HARD = 1.0

DIFFICULTY_ENEMY_BOUNTY_IMPOSSIBLE = 1.0
DIFFICULTY_ENEMY_DAMAGE_IMPOSSIBLE = 2.0
DIFFICULTY_ENEMY_HEALTH_IMPOSSIBLE = 2.0
DIFFICULTY_ENEMY_ARMOR_IMPOSSIBLE = 1.0

DIFFICULTY_ENEMY_BOUNTY_HELL = 1.0
DIFFICULTY_ENEMY_DAMAGE_HELL = 3.0
DIFFICULTY_ENEMY_HEALTH_HELL = 3.0
DIFFICULTY_ENEMY_ARMOR_HELL = 1.0

DIFFICULTY_ENEMY_BOUNTY_HARDCORE = 1.0
DIFFICULTY_ENEMY_DAMAGE_HARDCORE = 3.0
DIFFICULTY_ENEMY_HEALTH_HARDCORE = 3.0
DIFFICULTY_ENEMY_ARMOR_HARDCORE = 1.0
DIFFICULTY_HARDCORE_SCALING_REDUCTION_CONSTANT = 1.85

DIFFICULTY_BOSS_AGHANIM_DAMAGE_MULTIPLIER_HARD = 1.5
DIFFICULTY_BOSS_AGHANIM_DAMAGE_MULTIPLIER_IMPOSSIBLE = 1.9
DIFFICULTY_BOSS_AGHANIM_DAMAGE_MULTIPLIER_HELL = 2.5
DIFFICULTY_BOSS_AGHANIM_DAMAGE_MULTIPLIER_HARDCORE = 4

DIFFICULTY_GPOINTS_MULTIPLIER_HARD = 0.5
DIFFICULTY_GPOINTS_MULTIPLIER_IMPOSSIBLE = 1.0
DIFFICULTY_GPOINTS_MULTIPLIER_HELL = 2.0
DIFFICULTY_GPOINTS_MULTIPLIER_HARDCORE = 8.0

DIFFICULTY_GPOINTS_REWARD_ROSHAN = 50
DIFFICULTY_GPOINTS_REWARD_FOREST = 150
DIFFICULTY_GPOINTS_REWARD_SPIDER = 300
DIFFICULTY_GPOINTS_REWARD_LAKE = 450
DIFFICULTY_GPOINTS_REWARD_WRAITH = 675
DIFFICULTY_GPOINTS_REWARD_WINTER = 1012
DIFFICULTY_GPOINTS_REWARD_LAVA = 1518
DIFFICULTY_GPOINTS_REWARD_HEAVEN = 2278

CREEP_RESPAWN_TIME = 30
BOSS_RESPAWN_TIME = 60

ELITE_SPAWN_CHANCE = 10
ELITE_NEUTRAL_T1_CHANCE = 30
ELITE_NEUTRAL_T2_CHANCE = 10
ELITE_NEUTRAL_T3_CHANCE = 5

DONATOR_BONUS_GOLD = 1.15
DONATOR_BONUS_XP = 1.15

ENABLE_HERO_RESPAWN = true              -- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE = true             -- Should the shops contain all items?
ALLOW_SAME_HERO_SELECTION = false       -- Should we let people select the same hero as each other
LOCK_TEAMS = false                      -- Should we Lock (true) or unlock (false) team assignemnt. If team assignment is locked players cannot change teams.

CUSTOM_GAME_SETUP_TIME = 25.0           -- How long should custom game setup last - the screen where players pick a team?
HERO_SELECTION_TIME = 59940.0              -- How long should we let people select their hero? Should be at least 5 seconds.
HERO_SELECTION_PENALTY_TIME = 30.0      -- How long should the penalty time for not picking a hero last? During this time player loses gold.
ENABLE_BANNING_PHASE = false            -- Should we enable banning phase? Set to true if "EnablePickRules" is "1" in 'addoninfo.txt'
BANNING_PHASE_TIME = 20.0               -- How long should the banning phase last? This will work only if "EnablePickRules" is "1" in 'addoninfo.txt'
STRATEGY_TIME = 10.0                    -- How long should strategy time last? Bug: You can buy items during strategy time and it will not be spent!
SHOWCASE_TIME = 0.0                    -- How long should show case time be?
PRE_GAME_TIME = 0.0                    -- How long after showcase time should the horn blow and the game start?
POST_GAME_TIME = 15.0                   -- How long should we let people stay around before closing the server automatically?
TREE_REGROW_TIME = 999999.0                -- How long should it take individual trees to respawn after being cut down/destroyed?

GOLD_PER_TICK = 6                     -- How much gold should players get per tick? DOESN'T WORK
GOLD_TICK_TIME = 1.0                    -- How long should we wait in seconds between gold ticks? DOESN'T WORK

NORMAL_START_GOLD = 850                 -- Starting Gold

RECOMMENDED_BUILDS_DISABLED = false     -- Should we disable the recommended item builds for heroes? Turns the panel for showing recommended items at the shop off/on.
CAMERA_DISTANCE_OVERRIDE = 1500       -- How far out should we allow the camera to go? 1134 is the default in Dota.

MINIMAP_ICON_SIZE = 1                   -- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1             -- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 1              -- What icon size should we use for runes?

BUYBACK_ENABLED = false                  -- Should we allow players to buyback when they die?
CUSTOM_BUYBACK_COST_ENABLED = false     -- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = false -- Should we use a custom buyback time?
CUSTOM_BUYBACK_COOLDOWN_TIME = 480.0    -- Custom buyback cooldown time (needed if CUSTOM_BUYBACK_COOLDOWN_ENABLED is true).
BUYBACK_FIXED_GOLD_COST = 500           -- Fixed custom buyback gold cost (needed if CUSTOM_BUYBACK_COST_ENABLED is true).

CUSTOM_SCAN_COOLDOWN = 210              -- Custom cooldown of Scan in seconds. Doesn't affect Scan's starting cooldown!
CUSTOM_GLYPH_COOLDOWN = 300             -- Custom cooldown of Glyph in seconds. Doesn't affect Glyph's starting cooldown!

DISABLE_FOG_OF_WAR_ENTIRELY = false     -- Should we disable fog of war entirely for both teams?
USE_UNSEEN_FOG_OF_WAR = false           -- Should we make unseen and fogged areas of the map completely black until uncovered by each team? 
-- NOTE: DISABLE_FOG_OF_WAR_ENTIRELY must be false for USE_UNSEEN_FOG_OF_WAR to work
USE_STANDARD_DOTA_BOT_THINKING = false  -- Should we have bots act like they would in Dota? (This requires 3 lanes, vanilla items, vanilla heroes etc)

USE_CUSTOM_HERO_GOLD_BOUNTY = false     -- Should the gold for hero kills be modified (true) or same as in default Dota (false)?
HERO_KILL_GOLD_BASE = 110               -- Hero gold bounty base value
HERO_KILL_GOLD_PER_LEVEL = 10           -- Hero gold bounty increase per level
HERO_KILL_GOLD_PER_STREAK = 60          -- Hero gold bounty per his kill-streak (Killing Spree: +HERO_KILL_GOLD_PER_STREAK gold; Ultrakill: +2 x HERO_KILL_GOLD_PER_STREAK gold ...)
DISABLE_ALL_GOLD_FROM_HERO_KILLS = false    -- Should we remove gold gain from hero kills? USE_CUSTOM_HERO_GOLD_BOUNTY needs to be true.
-- NOTE: DISABLE_ALL_GOLD_FROM_HERO_KILLS requires GoldFilter.
USE_CUSTOM_HERO_LEVELS = true          -- Should the heroes give a custom amount of XP when killed? Can malfunction for levels above 30!

USE_CUSTOM_TOP_BAR_VALUES = true        -- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = true                  -- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true             -- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES

ENABLE_TOWER_BACKDOOR_PROTECTION = false -- Should we enable backdoor protection for our buildings?
--REMOVE_ILLUSIONS_ON_DEATH = false       -- Should we remove all illusions if the main hero dies? DOESN'T WORK
DISABLE_GOLD_SOUNDS = false             -- Should we disable the gold sound when players acquire gold?

END_GAME_ON_KILLS = true               -- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 10000        -- How many kills for a team should signify an end of game? (not used)
KILLS_PER_PLAYER_TO_END_GAME_FOR_TEAM = 10

USE_CUSTOM_XP_VALUES = true            -- Should we use custom XP values to level up heroes, or the default Dota numbers?
MAX_LEVEL = 300                         -- What level should we let heroes get to? (USE_CUSTOM_XP_VALUES must be true).
-- NOTE: MAX_LEVEL and XP_PER_LEVEL_TABLE will not work if USE_CUSTOM_XP_VALUES is false or nil.

-- Fill this table up with the required XP per level if you want to change it
XP_PER_LEVEL_TABLE = {}
XP_PER_LEVEL_TABLE[1] = 0
for i=2,MAX_LEVEL do
  XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i-1] + i * 250
end

ENABLE_FIRST_BLOOD = true               -- Should we enable first blood for the first kill in this game?
HIDE_KILL_BANNERS = false               -- Should we hide the kill banners that show when a player is killed?
LOSE_GOLD_ON_DEATH = false               -- Should we have players lose the normal amount of dota gold on death?
SHOW_ONLY_PLAYER_INVENTORY = false      -- Should we allow players to only see their own inventory even when selecting other units?
DISABLE_STASH_PURCHASING = false        -- Should we prevent players from being able to buy items into their stash when not at a shop?
DISABLE_ANNOUNCER = false               -- Should we disable the announcer from working in the game?
FORCE_PICKED_HERO = nil                 -- What hero should we force all players to spawn as? (e.g. "npc_dota_hero_axe").  Use nil to allow players to pick their own hero.
-- This will not work if "EnablePickRules" is "1" in 'addoninfo.txt'!

ADD_ITEM_TO_HERO_ON_SPAWN = false       -- Add an example item to the picked hero when he spawns?

-- NOTE: use FIXED_RESPAWN_TIME if you want the same respawn time on every level.
MAX_RESPAWN_TIME = 5					-- Default Dota doesn't have a limit (it can go above 125). Fast game modes should have 20 seconds.
USE_CUSTOM_RESPAWN_TIMES = true		-- Should we use custom respawn times (true) or dota default (false)?

-- Fill this table with respawn times on each level if USE_CUSTOM_RESPAWN_TIMES is true.
CUSTOM_RESPAWN_TIME = {}

for i = 1, MAX_LEVEL do
    CUSTOM_RESPAWN_TIME[i] = 10
end

FOUNTAIN_CONSTANT_MANA_REGEN = 50       -- What should we use for the constant fountain mana regen?  Use -1 to keep the default dota behavior.
FOUNTAIN_PERCENTAGE_MANA_REGEN = 500     -- What should we use for the percentage fountain mana regen?  Use -1 to keep the default dota behavior.
FOUNTAIN_PERCENTAGE_HEALTH_REGEN = 500   -- What should we use for the percentage fountain health regen?  Use -1 to keep the default dota behavior.
MAXIMUM_ATTACK_SPEED = 1500             -- What should we use for the maximum attack speed?
MINIMUM_ATTACK_SPEED = 100               -- What should we use for the minimum attack speed?

DISABLE_DAY_NIGHT_CYCLE = false         -- Should we disable the day night cycle from naturally occurring? (Manual adjustment still possible)
DISABLE_KILLING_SPREE_ANNOUNCER = false -- Should we disable the killing spree announcer?
DISABLE_STICKY_ITEM = false             -- Should we disable the sticky item button in the quick buy area?
ENABLE_PAUSING = false                   -- Should we allow players to pause the game?
DEFAULT_DOTA_COURIER = true             -- Enable courier for each player with default dota properties

FORCE_MINIMAP_ON_THE_LEFT = true       -- Should we disable hud flip aka force the default dota hud positions? 
-- Note: Some players have minimap on the right and gold/shop on the left.

USE_DEFAULT_RUNE_SYSTEM = true          -- Should we use the default dota rune spawn timings and the same runes as dota have?
BOUNTY_RUNE_SPAWN_INTERVAL = 10        -- How long in seconds should we wait between bounty rune spawns? BUGGED! WORKS FOR POWERUPS TOO!
POWER_RUNE_SPAWN_INTERVAL = 9999         -- How long in seconds should we wait between power-up runes spawns? BUGGED! WORKS FOR BOUNTIES TOO!

ENABLED_RUNES = {}                      -- Which power-up runes should be enabled to spawn in our game mode?
ENABLED_RUNES[DOTA_RUNE_DOUBLEDAMAGE] = false
ENABLED_RUNES[DOTA_RUNE_HASTE] = false
ENABLED_RUNES[DOTA_RUNE_ILLUSION] = false
ENABLED_RUNES[DOTA_RUNE_INVISIBILITY] = false
ENABLED_RUNES[DOTA_RUNE_REGENERATION] = false
ENABLED_RUNES[DOTA_RUNE_ARCANE] = false  -- BUGGED! NEVER SPAWNS!
ENABLED_RUNES[DOTA_RUNE_XP] = false  -- BUGGED! NEVER SPAWNS!
ENABLED_RUNES[DOTA_RUNE_SHIELD] = false  -- BUGGED! NEVER SPAWNS!
ENABLED_RUNES[DOTA_RUNE_BOUNTY] = true

MAX_NUMBER_OF_TEAMS = 1                         -- How many potential teams can be in this game mode?
USE_CUSTOM_TEAM_COLORS = false                  -- Should we use custom team colors?
USE_CUSTOM_TEAM_COLORS_FOR_PLAYERS = false      -- Should we use custom team colors to color the players/minimap?

TEAM_COLORS = {}                        -- If USE_CUSTOM_TEAM_COLORS is set, use these colors.
TEAM_COLORS[DOTA_TEAM_GOODGUYS] = { 61, 210, 150 }  --    Teal
TEAM_COLORS[DOTA_TEAM_BADGUYS]  = { 243, 201, 9 }   --    Yellow
TEAM_COLORS[DOTA_TEAM_CUSTOM_1] = { 197, 77, 168 }  --    Pink
TEAM_COLORS[DOTA_TEAM_CUSTOM_2] = { 255, 108, 0 }   --    Orange
TEAM_COLORS[DOTA_TEAM_CUSTOM_3] = { 52, 85, 255 }   --    Blue
TEAM_COLORS[DOTA_TEAM_CUSTOM_4] = { 101, 212, 19 }  --    Green
TEAM_COLORS[DOTA_TEAM_CUSTOM_5] = { 129, 83, 54 }   --    Brown
TEAM_COLORS[DOTA_TEAM_CUSTOM_6] = { 27, 192, 216 }  --    Cyan
TEAM_COLORS[DOTA_TEAM_CUSTOM_7] = { 199, 228, 13 }  --    Olive
TEAM_COLORS[DOTA_TEAM_CUSTOM_8] = { 140, 42, 244 }  --    Purple

USE_AUTOMATIC_PLAYERS_PER_TEAM = false   -- Should we set the number of players to 10 / MAX_NUMBER_OF_TEAMS?

CUSTOM_TEAM_PLAYER_COUNT = {}           -- If we're not automatically setting the number of players per team, use this table
if GetMapName() == "tcotrpg" then
  MAX_NUMBER_OF_TEAMS = 1
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 5 -- you need to set this for each map if maps have a different max number of players per team
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 0 -- you need to set this for each map if maps have a different max number of players
end

if GetMapName() == "tcotrpgv2" then
  USE_UNSEEN_FOG_OF_WAR = true
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 5 -- you need to set this for each map if maps have a different max number of players per team
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 0 -- you need to set this for each map if maps have a different max number of players
end

if GetMapName() == "5v5" then
  MAX_NUMBER_OF_TEAMS = 2
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 5 -- you need to set this for each map if maps have a different max number of players per team
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 5 -- you need to set this for each map if maps have a different max number of players
end

if GetMapName() == "tcotrpgv3" then
  USE_UNSEEN_FOG_OF_WAR = true
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 5 -- you need to set this for each map if maps have a different max number of players per team
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 0 -- you need to set this for each map if maps have a different max number of players
end

if IsPvP() then
  MAX_NUMBER_OF_TEAMS = 2
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 3 -- you need to set this for each map if maps have a different max number of players per team
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 3 -- you need to set this for each map if maps have a different max number of players

  GOLD_PER_TICK = 60
  GOLD_TICK_TIME = 1 
end

CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_1] = 0
CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_2] = 0
CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_3] = 0
CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_4] = 0
CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_5] = 0
CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_6] = 0
CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_7] = 0
CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_8] = 0

INT_MAX_LIMIT = 2147483637 -- For max hp etc. max is 2,147,483,647

--143 032 032 (143m)
if GetMapName() == "tcotrpg_1v1" then
    MAX_NUMBER_OF_TEAMS = 2
    CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 1 -- you need to set this for each map if maps have a different max number of players per team
    CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 1
end

-- Abilities that can not deal damage to bosses --
DAMAGE_FILTER_BANNED_BOSS_ABILITIES = {
  "phantom_assassin_fan_of_knives", -- Too high damage
  "ancient_apparition_ice_blast", -- Shatter might work on bosses, unsure
  "shadow_demon_soul_catcher", -- Too high damage
  "zuus_static_field", -- Not sure if it's health removal, might be...
  "tinker_shrink_ray", -- No
  "tinker_laser", -- No
  "night_stalker_hunter_in_the_night", -- No
  "doom_bringer_infernal_blade",
  "spectre_dispersion",
}

-- Abilities that cannot target bosses --
BANNED_BOSS_ABILITIES = {
  "tusk_walrus_kick",
  "legion_commander_duel",
  "enchantress_enchant",
  "huskar_life_break",
  "chen_holy_persuasion",
  "snapfire_gobble_up",
  "snapfire_spit_creep",
  "bloodseeker_bloodrage",
  "mirana_arrow",
  "zuus_static_field",
  "vengefulspirit_nether_swap",
  "phantom_assassin_fan_of_knives",
  "life_stealer_feast",
  "life_stealer_open_wounds",
  "life_stealer_infest",
  "doom_bringer_devour",
  "tinker_shrink_ray",
  "pugna_decrepify",
  "ancient_apparition_ice_blast",
  "doom_bringer_infernal_blade",
  "windrunner_powershot",
  "obsidian_destroyer_astral_imprisonment",
  "axe_culling_blade",
  "shadow_demon_disruption",
  "obsidian_destroyer_arcane_orb",
  "item_force_staff",
  "item_hurricane_pike",
  "bloodseeker_rupture",
  "servants_from_below_uba",
  "eternal_damnation",
  "tinker_laser",
  "marci_grapple",
  "night_stalker_hunter_in_the_night"
}

BANNED_BOSS_MODIFIERS = {
  "modifier_abyssal_underlord_atrophy_aura_effect",
  "modifier_razor_eye_of_the_storm_armor",
  "modifier_axe_counter_helix_damage_reduction",
  "modifier_tidehunter_smash_attack",
  "modifier_spirit_breaker_greater_bash"
}


BOOK_ABILITY_SELECTION = {
  "asan_dagger_flurry",
  "asan_sisters_of_the_veil",
  "asan_marked_for_death",
  "alchemist_berserk_potion",
  "alchemist_chemical_greevils_greed_custom",
  "fenrir_summon_pup",
  "fenrir_ice_shards",
  "medusa_split_shot_custom",
  "primal_beast_onslaught_custom",
  "primal_beast_trample_custom",
  "primal_beast_uproar_custom",
  "luna_moon_beam_custom",
  "sven_greater_cleave_custom",
  "sven_warcry_custom",
  "hoodwink_acorn_shot_custom",
  "hoodwink_hunters_boomerang_custom",
  "hoodwink_scurry_custom",
  "omniknight_purification_custom",
  "omniknight_repel_custom",
  "omniknight_hammer_of_purity_custom",
  "omniknight_degen_aura_custom",
  "mars_spear_of_mars_custom",
  "mars_gods_rebuke_custom",
  "grimstroke_dark_artistry_custom",
  "grimstroke_ink_creature_custom",
  "grimstroke_ink_swell_custom",
  "dragon_knight_breathe_fire_custom",
  "dragon_knight_fireball",
  "dragon_knight_dragon_tail_custom",
  "lich_frost_nova_custom",
  "lich_frost_shield_custom",
  "templar_assassin_meld_custom",
  "morphling_wave_custom",
  "morphling_adaptive_strike_custom",
  "underlord_firestorm_custom",
  "underlord_pit_of_malice_custom",
  "razor_plasma_field_custom",
  "razor_static_link_custom",
  "razor_unstable_current_custom",
  "alchemist_chemical_gold_transfusion_custom",
  "crystal_maiden_crystal_nova_custom",
  "crystal_maiden_freezing_field_custom",
  "crystal_maiden_arcane_aura_custom",
  "riki_decoy",
  "riki_backstab_custom",
  "techies_stasis_trap_custom",
  "viper_corrosive_skin",
  "viper_nethertoxin",
  "obsidian_astral_eclipse",
  "obsidian_essence_flux",
  "zuus_heavenly_jump_custom",
  "ancient_apparition_chilling_barrier",
  "ancient_apparition_chilling_ground",
  "leshrac_diabolic_edict_custom",
  "leshrac_lightning_storm_custom",
  "leshrac_greater_lightning_storm",
  "shadow_shaman_plague_ward",
  "shadow_shaman_cog",
  "shadow_shaman_healing_ward",
  "nevermore_shadow_raze_custom",
  "nevermore_presence_of_the_dark_lord_custom",
  "shredder_whirling_death_custom",
  "timbersaw_reactive_armor_custom",
  "shredder_flamethrower",
  "bristleback_viscous_nasal_goo_custom",
  "bristleback_quill_spray_custom",
  "lion_earth_spike_custom",
  "lion_fireball",
  "monkey_king_jingu_mastery_datadriven",
  "troll_warlord_berserkers_rage_custom",
  "troll_warlord_rampage_custom",
  "pudge_rot_custom",
  "pudge_meat_hook_lua",
  "lycan_summon_wolves_custom",
  "lycan_howl_custom",
  "lycan_feral_impulse_custom",
  "juggernaut_wind_gust_custom",
  "juggernaut_jade_dragonling_custom",
  "juggernaut_blade_dance_custom",
  "drow_ranger_frost_arrows_custom",
  "drow_ranger_multishot_custom",
  "drow_ranger_glacier_custom",
  "axe_berserkers_call_custom",
  "axe_battle_hunger_custom",
  "axe_counter_helix_custom",
  "ogre_magi_fireblast_custom",
  "ogre_magi_ignite_custom",
  "ogre_magi_bloodlust_custom",
  "dazzle_poison_touch_custom",
  "dazzle_shadow_step",
  "silencer_silent_bliss_custom",
  "bloodseeker_bloodrage_custom",
  "bloodseeker_blood_mist_custom",
  "furion_sufferwood_sapling_custom",
  "furion_breezing_wind_custom",
  "doom_eternal_fire",
  "doom_scorched_earth_custom",
  "doom_infernal_blade_custom",
  "phantom_assassin_daggers",
  "phantom_assassin_despair",
  "phantom_assassin_blur_custom",
  "treant_bark_custom",
  "windranger_spring_lightning",
  "windranger_powershot_custom",
  "centaur_hoof_stomp_custom",
  "centaur_double_edge_custom",
  "centaur_return_custom",
  "terrorblade_demon_zeal_custom",
  "terrorblade_true_power_custom",
  "terrorblade_foulfell_retreat_custom",
  "huskar_vitality_explosion_custom",
  "huskar_berserkers_blood_custom",
  "huskar_double_throw_custom",
  "slardar_slithereen_crush_custom",
  "slardar_bash_of_the_deep_custom",
  "faceless_void_time_lock_custom",
  "faceless_void_temporal_reversion_custom",
  "faceless_void_backtrack_custom",
  "legion_commander_battlefield_custom",
  "legion_commander_press_the_attack_custom",
  "stargazer_gamma_ray",
  "stargazer_inverse_field",
  "stegius_desolus_wave",
  "stegius_rage_of_desolus",
  "saber_mana_burst",
  "saber_instinct",
  "saber_invisible_air",
  "muerta_dead_shot_custom",
  "muerta_the_calling_custom",
  "muerta_gunslinger_custom",
  "lina_dragon_slave_custom",
  "lina_light_strike_array_custom",
  "tiny_avalanche_custom",
  "spectre_desolate_custom",
  "spectre_dispersion_custom",
  "spectre_spectral_dagger_custom",
  "clinkz_searing_arrows_custom",
  "huskar_burning_spear_custom",
  "viper_poison_attack",
  "night_stalker_erupting_void_custom",
  "night_stalker_crippling_fear_custom",
  "snapfire_scatterblast_custom",
  "snapfire_firesnap_cookie_custom",
  "snapfire_lil_shredder_custom",
  "hero_akasha_shadow_strike",
  "hero_akasha_sadist",
  "hero_akasha_scream_of_pain",
  "obsidian_arcane_orb_custom",
  "bloodseeker_thirst_custom",
  "medusa_heavy_arrows",
  "ancient_apparition_chilling_touch_custom",
  "zuus_arc_lightning_custom",
  "templar_assassin_psi_blades_custom",
  "silencer_glaives_of_wisdom_custom",
  "tidehunter_tentacle_custom",
  "tidehunter_kraken_shell_custom",
  "tidehunter_anchor_smash_custom",
  "weaver_the_swarm_custom",
  "weaver_shukuchi_custom",
  "weaver_geminate_attack_custom",
  "ursa_earthshock_custom",
  "ursa_overpower_custom",
  "ursa_fury_swipes_custom",
  "necrolyte_death_coil_reaper",
  "necrolyte_death_aura",
  "necrolyte_hollowed_ground",
  "gabriel_purity",
  "gabriel_divine_retribution",
  "gabriel_heavenly_balance",
  "sniper_armor_bullets_custom",
  "sniper_take_aim_custom",
  "tanya_sharp_edges",
  "tanya_glaive_rush",
  "tanya_counterattack",
  "viper_nethertoxin_custom",
  "viper_poison_attack_custom"
}

-- Abilities that won't be randomly given to players
BOOK_ABILITY_SELECTION_EXCEPTIONS = {
  "bloodseeker_bloodrage_custom",
  "bloodseeker_blood_mist_custom",
  "axe_culling_blade_custom",
  "night_stalker_dark_ascension_custom",
  "night_stalker_hunter_in_the_night_custom",
  "nevermore_necromastery_custom",
  "nevermore_requiem_custom",
  "primal_beast_rock_throw_custom",
  "spectre_reality_custom",
  "talent_sniper_1_sub",
  "luna_might_of_the_moon_custom",
  "nevermore_shadowraze1_custom",
  "nevermore_shadowraze2_custom",
  "nevermore_shadowraze3_custom",
  "bristleback_bristleback_custom",
  "asan_marked_for_death",
  "asan_sword_mastery",
  "templar_assassin_refraction_custom",
  "lich_ice_spire_custom",
  "lich_chain_frost_custom",
  "templar_assassin_psionic_explosion_custom",
  "crystal_maiden_blizzard",
  "underlord_atrophy_aura_custom",
  "underlord_pit_of_abyss_custom",
  "abyssal_underlord_dark_portal",
  "abyssal_underlord_dark_rift",
  "abyssal_underlord_firestorm",
  "abyssal_underlord_pit_of_malice",
  "monkey_king_boundless_strike_custom",
  "crystal_maiden_frostbite",
  "crystal_maiden_brilliance_aura",
  "crystal_maiden_freezing_field",
  "crystal_maiden_crystal_nova",
  "crystal_maiden_let_it_go",
  "riki_backstab",
  "plague_ward_corrosion",
  "razor_static_link",
  "weaver_geminate_attack",
  "techies_go_nuclear",
  "techies_sticky_bomb_passive_proc",
  "techies_sticky_bomb",
  "techies_focused_detonate_datadriven",
  "techies_remote_mines_datadriven",
  "techies_land_mines",
  "stargazer_inverse_field",
  "centaur_return_custom",
  "nevermore_shadowraze2",
  "nevermore_shadowraze3",
  "nevermore_shadowraze1",
  "tiny_toss",
  "spectre_vengeance_custom",
  "alchemist_chemical_rage",
  "antimage_mana_void",
  "bane_fiends_grip",
  "batrider_flaming_lasso",
  "doom_bringer_doom",
  "medusa_stone_gaze",
  "windranger_focus_fire_custom",
  "treant_overgrowth_custom",
  "bristleback_warpath_custom",
  "dazzle_shadow_step",
  "eternal_damnation_uba",
  "servants_from_below_uba",
  "oracle_backtrack",
  "stegius_brightness_of_desolate",
  "legion_commander_moment_of_courage",
  "leshrac_pulse_nova_custom",
  "obsidian_destroyer_astral_imprisonment",
  "obsidian_destroyer_equilibrium",
  "obsidian_destroyer_sanity_eclipse",
  "obsidian_destroyer_essence_aura",
  "zuus_transcendence_custom_descend",
  "zuus_heavenly_jump_custom",
  "zuus_static_field_custom",
  "zuus_thundergods_wrath_custom",
  "necrolyte_aesthetics_death",
  "necrolyte_death_aura_reaper",
  "necrolyte_hollowed_ground_reaper",
  "necrolyte_corpse_charges",
  "necrolyte_reaper_form",
  "ancient_apparition_sharp_ice",
  "ancient_apparition_frozen_time",
  "ancient_apparition_ice_blast",
  "ancient_apparition_ice_vortex",
  "ancient_apparition_cold_feet",
  "leshrac_lightning_storm",
  "leshrac_pulse_nova",
  "ancient_apparition_chilling_touch",
  "leshrac_eternal_torment_custom",
  "medusa_mana_shield",
  "bristleback_quill_spray_custom",
  "gun_joe_calibrated_shot",
  "bloodseeker_rupture_custom",
  "stargazer_celestial_selection",
  "arc_warden_tempest_double_custom",
  "generic_hidden",
  "saitama_limiter",
  "saitama_serious_punch",
  "shredder_return_chakram",
  "shredder_return_chakram_2",
  "morphling_morph_str",
  "morphling_morph_agi",
  "obsidian_destroyer_arcane_orb",
  "undying_consume_custom",
  "slark_essence_shift_custom",
  "terrorblade_true_power_custom",
  "legion_commander_duel_custom",
  "phantom_assassin_coup_de_grace_custom",
  "snapfire_kisses_custom",
  "undying_infection_custom",
  "undying_flesh_golem_custom",
  "tinker_rearm",
  "ogre_magi_multicast_custom",
  "lina_laguna_blade_custom",
  "timbersaw_chakram_custom",
  "timbersaw_chakram_2_custom",
  "timbersaw_return_chakram_custom",
  "timbersaw_return_chakram_2_custom",
  "drow_ranger_marksmanship",
  "drow_ranger_frost_arrows",
  "drow_ranger_multishot",
  "drow_ranger_silence",
  "drow_ranger_wave_of_silence",
  "faceless_void_chronosphere_custom",
  "axe_helix_proc_custom",
  "dazzle_good_juju",
  "monkey_king_wukongs_command",
  "dawnbreaker_solar_hammer_replace",
  "dawnbreaker_luminosity_custom_daybreak",
  "pangolier_lucky_shot",
  "pangolier_heartpiercer",
  "mars_bulwark_custom",
  "mars_gods_rebuke_custom",
  "snapfire_lil_shredder",
  "clinkz_burning_spear_custom",
  "lina_fiery_soul_custom",
  "lina_sun_ray_custom",
  "lina_laguna_blade_custom",
  "muerta_dead_shot_custom",
  "muerta_the_calling_custom",
}

-- Abilities you can't change or replace
BOOK_ABILITY_CHANGE_PROHIBITED = {
  "ancient_apparition_ice_blast_stop_custom",
  "medusa_mana_shield_custom",
  "lone_druid_spirit_bear_custom",
  "lone_druid_true_form_custom",
  "primal_beast_onslaught_stop_custom",
  "grimstroke_soul_bind_custom",
  "night_stalker_dark_ascension_custom",
  "night_stalker_hunter_in_the_night_custom",
  "nevermore_necromastery_custom",
  "primal_beast_onslaught_release_custom",
  "primal_beast_onslaught_custom",
  "primal_beast_trample_custom",
  "primal_beast_rock_throw_custom",
  "spectre_reality_custom",
  "spectre_spectral_dagger_custom",
  "spectre_dispersion_custom",
  "talent_sniper_1_sub",
  "techies_explosive_expert_custom",
  "luna_might_of_the_moon_custom",
  "bristleback_quill_spray_custom",
  "bristleback_warpath_custom",
  "muerta_dead_shot_custom",
  "muerta_the_calling_custom",
  "lina_fiery_soul_custom",
  "lina_sun_ray_custom",
  "gun_joe_machine_gun",
  "gun_joe_rifle",
  "sniper_swift_hands_custom",
  "hoodwink_sharpshooter_cancel_custom",
  "hoodwink_sharpshooter_custom",
  "furion_living_roots_custom",
  "nevermore_shadowraze1_custom",
  "nevermore_shadowraze2_custom",
  "nevermore_shadowraze3_custom",
  "nevermore_ultimate_raze",
  "dragon_knight_dragon_form_switch_custom",
  "dragon_knight_dragon_form_custom",
  "huskar_mayhem_custom",
  "lich_ice_spire_custom",
  "lich_chain_frost_custom",
  "underlord_atrophy_aura_custom",
  "troll_warlord_berserkers_rage_custom",
  "hero_the_entity_change_primary",
  "hero_the_entity_change",
  "hero_the_entity_shuffle",
  "necrolyte_reaper_form_exit",
  "plague_ward_corrosion",
  "techies_focused_detonate_datadriven",
  "techies_remote_mines_datadriven",
  "techies_sticky_bomb_passive_proc",
  "techies_sticky_bomb",
  "zuus_transcendence_custom_descend",
  "zuus_static_field_custom",
  "necrolyte_aesthetics_death",
  "necrolyte_death_aura_reaper",
  "necrolyte_hollowed_ground_reaper",
  "necrolyte_reaper_form",
  "ancient_apparition_frozen_time",
  "leshrac_eternal_torment_custom",
  "medusa_mana_shield",
  "bloodseeker_rupture_custom",
  "stargazer_celestial_selection",
  "arc_warden_tempest_double_custom",
  "generic_hidden",
  "chicken_ability_1",
  "chicken_ability_6",
  "chicken_ability_5",
  "chicken_ability_4",
  "chicken_ability_7",
  "saitama_limiter",
  "saitama_serious_punch",
  "timbersaw_return_chakram_custom",
  "timbersaw_return_chakram_2_custom",
  "lion_agony",
  "lion_finger_of_death_custom",
  "axe_helix_proc_custom",
  "morphling_morph_str",
  "morphling_morph_agi",
  "undying_consume_custom",
  "slark_essence_shift_custom",
  "terrorblade_true_power_custom",
  "legion_commander_duel_custom",
  "phantom_assassin_coup_de_grace_custom",
  "monkey_king_wukongs_command",
  "dawnbreaker_luminosity_custom",
  "dawnbreaker_luminosity_custom_daybreak",
  "dawnbreaker_solar_hammer_replace",
  "pudge_hunger_custom",
  "pudge_flesh_heap_custom",
  "monkey_king_boundless_strike_stack_custom",
  "monkey_king_wukongs_command_custom",
  "monkey_king_primal_spring_early",
  "monkey_king_untransform",
  "monkey_king_boundless_passive_proc_custom",
  "timbersaw_chakram_2_custom",
  "timbersaw_chakram_custom",
  "shredder_return_chakram",
  "shredder_return_chakram_2",
  "tiny_unleashed_fury_custom",
  "tiny_grow_custom",
  "tiny_tree_grab_custom",
}

-- Abilities you can't swap positions of (due to duplication bugs usually)
BOOK_ABILITY_FORBIDDEN_SWAP = {
  "timbersaw_chakram_custom",
  "timbersaw_chakram_2_custom",
  "timbersaw_return_chakram_2_custom",
  "timbersaw_return_chakram_custom",
  "abyssal_underlord_portal_warp",
  "chicken_ability_5",
  "chicken_ability_6",
  "chicken_ability_7",
  "ancient_apparition_ice_blast_stop_custom",
}

-- EASY --
PLAYER_EASY_BUFFS = {
  "modifier_player_difficulty_buff_gold_50", -- +50% gold on kill
  "modifier_player_difficulty_buff_heal_on_kill_25", -- heals for 25% of targets hp on kill
  "modifier_player_difficulty_buff_damage_reduction_50", -- 50% damage reduction
  "modifier_player_difficulty_buff_armor_50", -- +50 bonus armor
  "modifier_player_difficulty_buff_damage_25", -- +25% outgoing damage
  "modifier_player_difficulty_buff_bounty_rune_200", -- +200% bounty rune gold and xp
}

-- NORMAL --
PLAYER_NORMAL_BUFFS = {
  "modifier_player_difficulty_buff_gold_10", -- +10% gold on kill
  "modifier_player_difficulty_buff_heal_on_kill_10", -- heals for 10% of targets hp on kill
  "modifier_player_difficulty_buff_bounty_rune_50", -- +50% bounty rune gold and xp
}

-- OTHER MODIFIERS --
PLAYER_ALL_BOONS = {
  --[[
  "modifier_player_difficulty_boon_reduced_healing_40", -- 40% reduced healing
  "modifier_player_difficulty_boon_disarm_30", -- Disarm every 10s
  "modifier_player_difficulty_boon_hex_30", -- Hex every 10s
  "modifier_player_difficulty_boon_self_death_explosion_60", -- Reflects damage back to allies when attacked
  "modifier_player_difficulty_boon_health_drain_5", -- 5% health drain
  "modifier_player_difficulty_boon_ally_proximity_debuff_1", -- When near another hero, you lose 1% of your max health per second (stacks)
  "modifier_player_difficulty_boon_leaky_5", -- When taking damage you lose 5% of your health and have your regen reduced by 30%. Same for spending mana.
  "modifier_player_difficulty_boon_blinded_no_vision_50", -- 50% chance to miss your attacks and vision impacted.
  --]]
}

ENEMY_ALL_BUFFS = {
  --[[
  "modifier_enemy_difficulty_buff_wraith_5_10", -- Enemies turn into wraiths on death that regenerates 5% hp over 20s
  "modifier_enemy_difficulty_buff_death_explosion_10", -- Deals 10% of max hp to nearby heroes on death
  "modifier_enemy_difficulty_buff_extra_attack_10", -- Extra attack with 10s cooldown
  "modifier_enemy_difficulty_buff_hp_regen_pct_1", -- 5% max hp regen
  "modifier_enemy_difficulty_buff_petrify_10", -- 10% chance to petrify you on attack
  "modifier_enemy_difficulty_buff_attack_speed_missing_hp_50", -- Gains attack speed based on missing health, max 50% increase
  "modifier_enemy_difficulty_buff_crit_chance_60", -- 60% chance to crit
  "modifier_enemy_difficulty_buff_mana_burn_5", -- Each hit burns 5% of the targets max mana
  "modifier_enemy_difficulty_buff_magical_damage_40", -- 40% of attack damage is dealt as bonus magical damage
  "modifier_enemy_difficulty_buff_steal_damage_10",
  --]]
  "modifier_apocalypse_corpse_explosion",
  "modifier_apocalypse_increased_speed",
  "modifier_apocalypse_attack_range",
  "modifier_apocalypse_armor",
  "modifier_apocalypse_magic_resistance",
  "modifier_apocalypse_evasion",
  --"modifier_apocalypse_magic_attacks",
  "modifier_apocalypse_mana_burn",
  "modifier_apocalypse_life_blood",
  "modifier_apocalypse_rushing",
  "modifier_apocalypse_health_deny",
  "modifier_apocalypse_magic_shield",
  "modifier_apocalypse_mana_void",
  "modifier_apocalypse_reanimation",
}

PLAYER_ALL_BUFFS = {
  "modifier_player_buffs_enemy_explosion",
  "modifier_player_buffs_adrenaline",
  "modifier_player_buffs_critical_strike",
  "modifier_player_buffs_attack_sacrifice",
  "modifier_player_buffs_spell_sacrifice",
  "modifier_player_buffs_sanguine_clarity",
  "modifier_player_buffs_omniscent_blessing",
  "modifier_player_buffs_vulnerable",
  "modifier_player_buffs_glasscannon",
  "modifier_player_buffs_status_boost",
  "modifier_player_buffs_hard_exterior",
  "modifier_player_buffs_blood_pool",
  "modifier_player_buffs_vitality_curse",
  "modifier_player_buffs_mana_curse",
  "modifier_player_buffs_drunken_brawler",
  "modifier_player_buffs_bloodthirsty_killer",
}

NEUTRAL_ITEM_DROP_TABLE_COMMON = {
    "item_keen_optic",
    "item_ironwood_tree",
    "item_ocean_heart",
    "item_broom_handle",
    "item_faded_broach",
    "item_arcane_ring",
    "item_chipped_vest",
    "item_possessed_mask",
    "item_mysterious_hat",
    "item_philosophers_stone",
    "item_pogo_stick",
    "item_paintball",
    "item_royal_jelly"
}

NEUTRAL_ITEM_DROP_TABLE_UNCOMMON = {
    "item_quickening_charm",
    "item_dragon_scale",
    "item_spider_legs",
    "item_pupils_gift",
    "item_imp_claw",
    "item_orb_of_destruction",
    "item_titan_sliver",
    "item_mind_breaker",
    "item_enchanted_quiver",
    "item_elven_tunic",
    "item_psychic_headband",
    "item_black_powder_bag",
    "item_vambrace",
    "item_misericorde",
    "item_quicksilver_amulet",
    "item_essence_ring",
    "item_nether_shawl",
    "item_bullwhip",
}

NEUTRAL_ITEM_DROP_TABLE_RARE = {
    "item_flicker",
    "item_ninja_gear",
    "item_the_leveller",
    "item_minotaur_horn",
    "item_spy_gadget",
    "item_trickster_cloak",
    "item_stormcrafter",
    "item_penta_edged_sword",
    "item_ascetic_cap",
    "item_illusionsts_cape"
}

NEUTRAL_ITEM_DROP_TABLE_LEGENDARY = {
    "item_desolator_2",
    "item_seer_stone",
    "item_mirror_shield",
    "item_apex",
    "item_demonicon",
    "item_fallen_sky",
    "item_ex_machina",
    "item_giants_ring",
    "item_book_of_shadows",
    "item_timeless_relic",
    "item_spell_prism",
}

NEUTRAL_ITEM_LIST_T1 = {
  "item_vindicator_axe",
  "item_eloshar_bracelet",
  "item_vampires_kiss",
  "item_beb",
  "item_ristul_dagger",
  "item_leveller",
  "item_amulet_of_dandelion",
  "item_array_of_specialists",
  "item_lance_pursuit",
  "item_quiver_of_enchants",
  "item_scale_of_dragons"
}

NEUTRAL_ITEM_LIST_T2 = {
  "item_war_horn",
  "item_blast_rig",
  "item_helm_of_the_gladiator",
  "item_shamans_sword",
  "item_jagged_blade",
  "item_dead_book",
  "item_conduit_stone"
}

NEUTRAL_ITEM_LIST_T3 = {
  "item_oak_heart",
  "item_evasion_boots",
  "item_shako_of_witless",
  "item_destruction_orb",
  "item_bow_yama_raskav",
  "item_sacrificial_cloak"
}

-- Modifiers that are not allowed to last forever on bosses
BOSS_LIMITED_MODIFIERS = {
  "generic_hidden"
}

TRIDENT_CRITICAL_IGNORE = {
  "spectre_dispersion",
  "zuus_static_field",
  "death_prophet_spirit_siphon",
  "batrider_sticky_napalm",
}

-- Modifiers that wont be removed from bosses
--[[STACKING_MODIFIERS_EXCEPTION = {
  "modifier_underlord_pit_of_malice_custom",
  "modifier_underlord_firestorm_custom_debuff",
  "modifier_underlord_pit_of_abyss_custom_aura",
  "modifier_ursa_fury_swipes_custom_swipe",
  "modifier_bristleback_quill_spray_custom",
  "modifier_bristleback_quill_spray_custom_stack",
  "modifier_viper_poison_attack",
  "modifier_viper_poison_attack_slow",
  "modifier_viper_viper_strike_slow",
  "modifier_viper_corrosive_skin",
  "modifier_viper_corrosive_skin_slow",
  "modifier_viper_nethertoxin_thinker",
  "modifier_viper_nethertoxin",
  "modifier_viper_nethertoxin_mute",
  "modifier_viper_viper_strike_custom",
  "modifier_viper_viper_strike_custom_debuff",
  "modifier_bloodseeker_rupture_custom_debuff",
  "modifier_stegius_desolating_touch_debuff",
  "modifier_bristleback_viscous_nasal_goo_custom",
  "modifier_huskar_burning_spear_custom_stack",
  "modifier_nevermore_ultimate_raze_debuff",
  "modifier_nevermore_shadowraze_debuff",
  "modifier_battlemage_arsenal_debuff",
  "modifier_huskar_burning_spear_custom",
  "modifier_bloodthorn_debuff",
  "modifier_orchid_malevolence_debuff",
  "modifier_heavens_halberd_debuff",
  "modifier_silver_edge_debuff",
  "modifier_bashed",
  "modifier_silence",
  "modifier_weaver_swarm_debuff",
  "modifier_item_crystalline_debuff",
  "modifier_shining_shivas_antiregen",
  "modifier_shining_shivas_aura",
  "modifier_item_shivas_guard_aura",
  "modifier_necrolyte_aesthetics_death_enemy_execute_debuff",
  "modifier_necrolyte_aesthetics_death_enemy",
  "modifier_necrolyte_death_aura_enemy",
  "modifier_necrolyte_death_aura_reaper_enemy",
  "modifier_necrolyte_hollowed_ground_emitter_aura",
  "modifier_necrolyte_hollowed_ground_reaper_emitter_aura",
  "modifier_obsidian_astral_eclipse_debuff",
  "modifier_item_ethereal_blade_ethereal",
  "modifier_item_ethereal_blade_slow",
  "modifier_item_ethereal_blade",
  "modifier_scorching_malevolence_debuff",
  "modifier_scorching_malevolence_burning",
  "modifier_drow_ranger_frost_arrows_custom_debuff",
  "modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff",
  "modifier_drow_ranger_marksmanship_custom_debuff",
  "modifier_vashundol_cleaver_disarmor",
  "modifier_amaliels_cuirass_aura_enemy",
  "modifier_kings_guard_aura_enemy",
  "modifier_plague_ward_corrosion_debuff",
  "modifier_riki_decoy_emitter_aura",
  "modifier_item_devastator_debuff",
  "modifier_razor_static_link_custom_debuff",
  "modifier_razor_static_link_custom_debuff_finished",
  "modifier_razor_eye_of_the_storm_custom_debuff",
  "modifier_templar_assassin_meld_custom_crit_stacks",
  "modifier_lich_ice_spire_custom_field_aura",
  "modifier_lich_ice_spire_custom_icy_aura_aura_enemy",
  "modifier_item_armor_piercing_crossbow_debuff",
  "modifier_dragon_knight_dragon_form_custom_black_armor_debuff",
  "modifier_dragon_knight_dragon_form_custom_blue_slow_debuff",
  "modifier_dragon_knight_dragon_form_custom_green_poison_debuff",
  "modifier_dragon_knight_dragon_form_custom_red_magic_debuff",
  "modifier_dragon_knight_dragon_blood_custom_fire_shield_aura",
  "modifier_dragon_knight_dragon_blood_custom_poison_debuff",
  "modifier_treant_leech_seed",
  "modifier_treant_leech_seed_slow",
  "modifier_treant_overgrowth_custom_aura_enemy",
  "modifier_treant_overgrowth_custom_debuff",
  "modifier_asan_into_veil_aura_enemy",
  "modifier_asan_dagger_flurry",
  "modifier_asan_marked_for_death_debuff",
  "modifier_fenrir_bite",
}--]]

SERVER_KEY = "1.0"
SERVER_DATE_KEY = "20240713"
SERVER_URI = "http://77.239.118.74:4001"
--SERVER_URI = "http://localhost:4000"