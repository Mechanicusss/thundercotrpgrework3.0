-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

-- Creating a global gamemode class variable;
if barebones == nil then
	_G.barebones = class({})
else
	DebugPrint("[BAREBONES] barebones class name is already in use, change the name if this is the first time you launch the game!")
	DebugPrint("[BAREBONES] If this is not your first time, you probably used script_reload in console.")
end

require('util')
require('libraries/timers')                      -- Core lua library
require('libraries/player_resource')             -- Core lua library
require('gamemode')  
require("libraries/selection")                            -- Core barebones file
require("libraries/spell_caster")
require("libraries/projectiles") 
require("libraries/player")  
require('libraries/animations')
require('libraries/cfinder')
require('libraries/filters')

require( "heroes/bosses/aghanim/boss_aghanim" )


function Precache(context)
--[[
  This function is used to precache resources/units/items/abilities that will be needed
  for sure in your game and that will not be precached by hero selection.  When a hero
  is selected from the hero selection screen, the game will precache that hero's assets,
  any equipped cosmetics, and perform the data-driven precaching defined in that hero's
  precache{} block, as well as the precache{} block for any equipped abilities.

  See GameMode:PostLoadPrecache() in gamemode for more information
  ]]

	DebugPrint("[BAREBONES] Performing pre-load precache")

	-- Particles can be precached individually or by folder
	-- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
    ----------------------------------------------------------------------------------------
	PrecacheResource( "model", "models/heroes/wraith_king/wraith_king.vmdl", context )
	PrecacheResource( "model", "models/heroes/aghanim/aghanim_model.vmdl", context )
	PrecacheResource( "model", "models/items/warlock/golem/puppet_summoner_golem/puppet_summoner_golem.vmdl", context )
	PrecacheResource( "model", "models/items/razor/razor_arcana/razor_arcana.vmdl", context )
	PrecacheResource( "model", "models/heroes/abyssal_underlord/abyssal_underlord_v2.vmdl", context )
	PrecacheResource( "model", "models/creeps/knoll_1/werewolf_boss.vmdl", context )
	PrecacheResource( "model", "models/heroes/undying/undying_flesh_golem.vmdl", context )
	PrecacheResource( "model", "models/heroes/dragon_knight_persona/dk_persona_dragon.vmdl", context )
	PrecacheResource( "model", "models/items/pudge/arcana/pudge_arcana_base.vmdl", context )
	PrecacheResource( "model", "models/heroes/mars/mars.vmdl", context )
	PrecacheResource( "model", "heroes/bosses/destruction_lord/boss_destruction_lord_soul_towers", context )
	PrecacheResource( "model", "models/creeps/lane_creeps/creep_radiant_melee/radiant_flagbearer.vmdl", context )
	PrecacheResource( "model", "models/creeps/lane_creeps/creep_radiant_melee/radiant_melee_mega_crystal_flagbearer.vmdl", context )
	PrecacheResource( "model", "models/items/hex/fish_hex/fish_hex.vmdl", context )
	----------------------------------------------------------------------------------
	PrecacheResource("particle", "particles/status_fx/status_effect_earth_spirit_petrify.vpcf", context)
	PrecacheResource("particle", "particles/generic_gameplay/radiant_fountain_regen.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_necrolyte/necrolyte_pulse_enemy.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_slardar/slardar_water_puddle_2.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok.vpcf", context)
	PrecacheResource("particle", "particles/base_static/team_portal_active.vpcf", context)
	PrecacheResource("particle", "particles/base_static/team_portal_ambient.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/ogre_magi/ogre_magi_arcana/ogre_magi_arcana_midas_coinshower.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/centaur/centaur_2022_immortal/centaur_2022_immortal_stampede_gold__2overhead.vpcf", context)
	PrecacheResource("particle", "particles/econ/events/fall_2022/_2player/fall_2022_emblem_effect_player_base.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/razor/razor_arcana/razor_arcana_eye_of_the_storm.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/razor/razor_arcana/razor_arcana_eye_of_the_storm_rain.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/antimage/antimage_weapon_basher_ti5/antimage_manavoid_ti_5.vpcf", context)
	PrecacheResource("particle", "particles/items2_fx/pipe_of_insight.vpcf", context)
	PrecacheResource("particle", "particles/models/items/warlock/ti10_puppet_summoner_golem/ti10_puppet_summoner_golem.vpcf", context)
	PrecacheResource("particle", "particles/items3_fx/octarine_core_lifesteal.vpcf", context)
	PrecacheResource("particle", "particles/ui/hud/levelupburst.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_phantom_lancer/phantomlancer_edge_boost.vpcf", context)
	PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/ogre_magi/ogre_ti8_immortal_weapon/ogre_ti8_immortal_bloodlust_buff.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf", context)
	PrecacheResource("particle", "particles/items2_fx/refresher.vpcf", context)
	PrecacheResource("particle", "particles/econ/events/frostivus/frostivus_fireworks.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_crystalmaiden_persona/cm_persona_attack.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_crystalmaiden_persona/cm_persona_ambient.vpcf", context)
	PrecacheResource("particle", "particles/arena/units/heroes/hero_zaken/stitching_strikes.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf", context)

	PrecacheResource("particle", "particles/econ/events/fall_2021/fountain_regen_fall_2021_lvl3.vpcf", context)
	PrecacheResource("particle", "particles/customgames/capturepoints/cp_wind.vpcf", context)

	PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_remote_mine.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_remote_mine_plant.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_remote_mines_detonate.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/roshan_timer.vpcf", context)


	PrecacheResource("particle_folder", "particles/reaper/necrolyte_spirit.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/necrolyte_spirit_dark.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/necrolyte_spirit_edge.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/necrolyte_spirit_ground.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/necrolyte_spirit_ground_glow.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/necrolyte_spirit_ground_projection.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/necrolyte_spirit_ground_streak.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/necrolyte_spirit_haze.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/necrolyte_spirit_ring.vpcf", context)

	PrecacheResource("particle_folder", "particles/units/heroes/hero_clinkz/clinkz_burning_army_ground_heat.vpcf", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_invoker/invoker_cold_snap_status.vpcf", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf", context)
	PrecacheResource("particle_folder", "particles/econ/items/effigies/status_fx_effigies/aghs_statue_destruction_gold.vpcf", context)
	PrecacheResource("particle_folder", "particles/econ/items/effigies/status_fx_effigies/aghs_statue_gold_ambient.vpcf", context)
	
	PrecacheResource("particle_folder", "particles/capture_point_ring", context)

	PrecacheResource("particle_folder", "particles/reaper/ghosts/wraith_king_ambient_beams_b.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/ghosts/wraith_king_ambient_beams_c.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/ghosts/wraith_king_ambient_d.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/ghosts/wraith_king_ghosts_ambient.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/ghosts/wraith_king_ghosts_ambient_b.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/ghosts/wraith_king_ghosts_ambient_beams_a.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/ghosts/wraith_king_ghosts_ambient_beams_f.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/ghosts/wraith_king_ghosts_glow.vpcf", context)
	PrecacheResource("particle_folder", "particles/reaper/ghosts/wraith_king_ghosts_spirits_copy.vpcf", context)

	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_enemy.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_enemy_explosion.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_enemy_hand.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_enemy_hand_dark.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_enemy_hand_dark_c.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_enemy_hand_smoke.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_enemy_sparks.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_launch.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_sparks_reverse.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_trail_enemy_b.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_trail_enemy_c.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necro_sullen_pulse_trail_enemy_d.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/necrolyte_spirit_ground_streak.vpcf", context)

	PrecacheResource("particle_folder", "particles/necrolyte_pulse/explosion/necro_sullen_pulse_enemy_explosion_cloud.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/explosion/necro_sullen_pulse_enemy_explosion_gas.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/explosion/necro_sullen_pulse_enemy_sparks.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/explosion/necro_sullen_pulse_explosion_debris.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/explosion/necro_sullen_pulse_explosion_debris_b.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/explosion/necro_sullen_pulse_explosion_flash_glow.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/explosion/necro_sullen_pulse_explosion_flash_ray.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_pulse/explosion/necro_sullen_pulse_explosion_vapor.vpcf", context)

	PrecacheResource("particle_folder", "particles/necrolyte_aura/necrolyte_spirit_debuff.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_aura/necrolyte_spirit_debuff_a.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_aura/necrolyte_spirit_debuff_b.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_aura/necrolyte_spirit_debuff_debris.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_aura/necrolyte_spirit_debuff_ember.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_aura/necrolyte_spirit_debuff_rings.vpcf", context)
	PrecacheResource("particle_folder", "particles/necrolyte_aura/necrolyte_spirit_ground_projection.vpcf", context)

	PrecacheResource("particle_folder", "particles/units/heroes/hero_faceless_void/faceless_void_chrono_speed.vpcf", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_zuus/zuus_lightning_bolt_aoe_ground.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_cracks_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_edgeroll_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_elec_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_energy_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_glow_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_ground_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_light_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_mist_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_ring_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_ring_warp_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_start_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_start_dust_hit_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_start_dust_hit_ring_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_start_dust_hit_shock_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_warp_b_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_warp_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/arc_warden_magnetic_warp_sprite_custom.vpcf", context)
	PrecacheResource("particle_folder", "particles/fv_chronosphere_aeons_a_custom.vpcf", context)

	PrecacheResource("particle_folder", "particles/darkmoon_calldown_marker_ring.vpcf", context)
	PrecacheResource("particle_folder", "particles/darkmoon_creep_warning.vpcf", context)
	PrecacheResource("particle_folder", "particles/darkmoon_creep_warning_pulse.vpcf", context)
	PrecacheResource("particle_folder", "particles/darkmoon_creep_warning_ring.vpcf", context)
	PrecacheResource("particle_folder", "particles/darkmoon_creep_warning_streak.vpcf", context)

	PrecacheResource("particle", "particles/creeps/lane_creeps/creep_radiant_hulk_swipe_right.vpcf", context)
	PrecacheResource("particle", "particles/creeps/lane_creeps/creep_radiant_hulk_swipe_left.vpcf", context)
	PrecacheResource("particle", "particles/econ/events/frostivus/frostivus_fireworks.vpcf", context)

	PrecacheResource("particle", "particles/econ/events/diretide_2020/emblem/fall20_emblem_v3_effect.vpcf", context)
	PrecacheResource("particle", "particles/econ/events/fall_2021/fall_2021_emblem_game_effect.vpcf", context)
	PrecacheResource("particle", "particles/econ/events/ti10/emblem/ti10_emblem_effect.vpcf", context) --rank 1 scoreboard
	PrecacheResource("particle", "particles/econ/events/ti9/ti9_emblem_effect.vpcf", context) --rank 1 event
	PrecacheResource("particle", "particles/econ/events/summer_2021/summer_2021_emblem_effect.vpcf", context) --rank 3

	PrecacheResource("particle", "particles/econ/items/alchemist/alchemist_midas_knuckles/alch_hand_of_midas.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodbath.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_clean_low.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_terrorblade_reflection.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_medusa_stone_gaze.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf", context)
	PrecacheResource("particle", "particles/generic_gameplay/generic_manaburn.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_skeletonking/wraith_king_ghosts_ambient.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", context)
	PrecacheResource("particle", "particles/generic_gameplay/generic_disarm.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_blast_off.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/axe/axe_ti9_immortal/axe_ti9_beserkers_call_owner.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_drow/drow_ice_trail.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/huskar/huskar_2021_immortal/huskar_2021_immortal_burning_spear_debuff.vpcf", context)
	PrecacheResource("particle", "particles/creatures/aghanim/aghanim_crystal_impact.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_axe/axe_beserkers_call_hero_effect.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/wraith_king/wraith_king_destruction_lord/wraith_king_destruction_lord_ambient.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/wraith_king/wraith_king_destruction_lord/wraith_king_destruction_lord_weapon.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_skeletonking/wraith_king_reincarnate.vpcf", context)
	PrecacheResource("particle", "particles/creatures/aghanim/portal_summon_a.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/underlord/underlord_2021_immortal/underlord_2021_immortal_portal_2.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/antimage_female/nemesis_slayer/nemesis_weapon_l_ambient.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/antimage_female/nemesis_slayer/nemesis_weapon_r_ambient.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/antimage_female/nemesis_slayer/nemesis_head_ambient.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/antimage_female/nemesis_slayer/nemesis_armor_ambient.vpcf", context)
	
	PrecacheResource("particle", "particles/econ/items/spectre/spectre_arcana/spectre_arcana_dispersion.vpcf", context)
	
	PrecacheModel("models/units/anakim_pet/anakim_pet.vmdl", context)
	PrecacheModel("models/heroes/crystal_maiden_persona/crystal_maiden_persona_temp.vmdl", context)
	PrecacheModel("models/heroes/phantom_assassin_persona/phantom_assassin_persona_head.vmdl", context)
	PrecacheModel("models/heroes/phantom_assassin_persona/phantom_assassin_persona_armor.vmdl", context)
	PrecacheModel("models/heroes/phantom_assassin_persona/phantom_assassin_persona_legs.vmdl", context)
	PrecacheModel("models/heroes/phantom_assassin_persona/phantom_assassin_persona_weapon.vmdl", context)
	
	PrecacheModel("models/props_gameplay/temple_portal001.vmdl", context)
	PrecacheModel("models/items/courier/mighty_chicken/mighty_chicken.vmdl", context)
	PrecacheModel("models/props_generic/gate_wooden_locked_02.vmdl", context)
	PrecacheModel("models/props_generic/gate_wooden_destruction_02.vmdl", context)
	PrecacheModel("models/props_gameplay/team_portal/team_portal.vmdl", context)
	PrecacheModel("models/units/anakim_pet/anakim_pet.vmdl", context)
	PrecacheModel("models/spidersack.vmdl", context)
	PrecacheModel("models/gameplay/aghanim_crystal.vmdl", context)
	PrecacheModel("models/heroes/crystal_maiden_persona/crystal_maiden_persona.vmdl", context)
	PrecacheModel("models/heroes/monkey_king/transform_invisiblebox.vmdl", context)
	PrecacheModel("models/items/hex/sheep_hex/sheep_hex.vmdl", context)
	PrecacheModel("models/units/zaken/zaken.vmdl", context)
	PrecacheModel("models/units/saitama/zasaitamaken.vmdl", context)
	PrecacheModel("models/hero_shinobu/shinobu_01.vmdl", context)
	PrecacheModel("models/units/stegius/stegius.vmdl", context)
	PrecacheModel("models/creeps/lane_creeps/creep_2021_radiant/creep_2021_radiant_melee_mega.vmdl", context)
	PrecacheModel("models/units/doppelganger/doppelganger.vmdl", context)
	PrecacheModel("models/heroes/nightstalker/nightstalker.vmdl", context)
	PrecacheModel("models/heroes/nightstalker/nightstalker_night.vmdl", context)
	PrecacheModel("models/heroes/nightstalker/nightstalker_wings_night.vmdl", context)
	PrecacheModel("models/heroes/nightstalker/nightstalker_legarmor_night.vmdl", context)
	PrecacheModel("models/heroes/nightstalker/nightstalker_tail_night.vmdl", context)
	PrecacheModel("models/creeps/ice_biome/ogreseal/ogreseal.vmdl", context)
	PrecacheModel("models/creeps/knoll_1/werewolf_boss.vmdl", context)
	PrecacheModel("models/creeps/ice_biome/tuskfolk/tuskfolk001a_f.vmdl", context)
	PrecacheModel("models/creeps/ice_biome/tuskfolk/tuskfolk001b_f.vmdl", context)
	PrecacheModel("models/heroes/tuskarr/tusk_fish_basket.vmdl", context)
	PrecacheModel("models/heroes/tuskarr/tusk_fish.vmdl", context)
	PrecacheModel("models/creeps/ogre_1/ogre_web.vmdl", context)
	PrecacheModel("models/creeps/ogre_1/large_ogre.vmdl", context)
	PrecacheModel("models/creeps/nyx_swarm/nyx_swarm.vmdl", context)
	PrecacheModel("models/creeps/spiders/spider_kidnap.vmdl", context)
	PrecacheModel("models/creeps/spiders/spidersack.vmdl", context)
	PrecacheModel("models/creeps/omniknight_golem/omniknight_golem.vmdl", context)
	PrecacheModel("models/props_structures/radiant_checkpoint_01.vmdl", context)
	PrecacheModel("models/heroes/antimage_female/antimage_female.vmdl", context)
	PrecacheModel("models/items/antimage_female/anti_mage_nemesis_slayer_armor_persona_1/anti_mage_nemesis_slayer_armor_persona_1.vmdl", context)
	PrecacheModel("models/items/antimage_female/anti_mage_nemesis_slayer_head_persona_1/anti_mage_nemesis_slayer_head_persona_1.vmdl", context)
	PrecacheModel("models/items/antimage_female/anti_mage_nemesis_slayer_offhand_weapon_persona_1/anti_mage_nemesis_slayer_offhand_weapon_persona_1.vmdl", context)
	PrecacheModel("models/items/antimage_female/anti_mage_nemesis_slayer_weapon_persona_1/anti_mage_nemesis_slayer_weapon_persona_1.vmdl", context)
	

	PrecacheResource("particle_folder", "particles/dazzle/dazzle_shadow_step.vpcf", context)
  PrecacheResource("particle_folder", "particles/dazzle/wd_ti10_immortal_voodoo_center.vpcf", context)
  PrecacheResource("particle_folder", "particles/dazzle/wd_ti10_immortal_voodoo_ember.vpcf", context)
  PrecacheResource("particle_folder", "particles/dazzle/wd_ti10_immortal_voodoo_flame.vpcf", context)
  PrecacheResource("particle_folder", "particles/dazzle/wd_ti10_immortal_voodoo_glow.vpcf", context)
  PrecacheResource("particle_folder", "particles/dazzle/wd_ti10_immortal_voodoo_grass.vpcf", context)
  PrecacheResource("particle_folder", "particles/dazzle/wd_ti10_immortal_voodoo_ground_cover.vpcf", context)
  PrecacheResource("particle_folder", "particles/dazzle/wd_ti10_immortal_voodoo_projection.vpcf", context)
  PrecacheResource("particle_folder", "particles/dazzle/wd_ti10_immortal_voodoo_ring.vpcf", context)
  PrecacheResource("particle_folder", "particles/dazzle/wd_ti10_immortal_voodoo_spore.vpcf", context)
  PrecacheResource("particle_folder", "particles/units/heroes/hero_broodmother/broodmother_hunger_buff.vpcf", context)

  PrecacheResource("particle_folder", "particles/econ/items/lanaya/lanaya_epit_trap/templar_assassin_epit_trap_explode.vpcf", context)
  
  PrecacheResource("particle_folder", "particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf", context)

	-- Models can also be precached by folder or individually
	-- PrecacheModel should generally used over PrecacheResource for individual models

	--PrecacheResource("model_folder", "particles/heroes/antimage", context)
	--PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
	--PrecacheModel("models/heroes/viper/viper.vmdl", context)
	--PrecacheModel("models/props_gameplay/treasure_chest001.vmdl", context)
	--PrecacheModel("models/props_debris/merchant_debris_chest001.vmdl", context)
	--PrecacheModel("models/props_debris/merchant_debris_chest002.vmdl", context)

	-- Sounds can precached here like anything else
	
	PrecacheResource("soundfile", "soundevents/game_sounds.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/soundevents_dota_ui.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/soundevents_aghanim.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_ui_imported.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_roshan_halloween.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_skeleton_king.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_earth_spirit.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_undying.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_magnataur.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_visage.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_centaur.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_arc_warden.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_snapfire.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_phantom_lancer.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_viper.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lina.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_riki.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_broodmother.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_dazzle.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_elder_titan.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lion.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_clinkz.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_tusk.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_winter_wyvern.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_phantom_assassin.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_doombringer.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lone_druid.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_dark_seer.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_abaddon.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_alchemist.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_treant.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_warlock.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_zuus.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_templar_assassin.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_techies.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_razor.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_sven.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_necrolyte.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ogre_magi.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_legion_commander.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_crystalmaiden.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_pudge.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_pugna.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_wisp.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_enigma.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_venomancer.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_rattletrap.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_witchdoctor.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lich.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_shadowshaman.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_pangolier.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_phantom_assassin.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_mars.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lycan.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_techies.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_juggernaut.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_axe.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_tinker.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_huskar.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_bloodseeker.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_sandking.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_meepo.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_nevermore.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_antimage.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_life_stealer.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ancient_apparition.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_creeps.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_arena.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_asan.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_vo_tanya.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_waves.vsndevts", context)


	PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_juggernaut.vsndevts", context)
	
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_obsidian_destroyer.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_abyssal_underlord.vsndevts", context)

	-- Entire items can be precached by name
	-- Abilities can also be precached in this way despite the name
	PrecacheItemByNameSync("example_ability", context)
	PrecacheItemByNameSync("item_example_item", context)

	-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
	-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
	PrecacheUnitByNameSync("npc_dota_creature_150_boss_last", context)
	PrecacheUnitByNameSync("boss_queen_of_pain", context)
	PrecacheUnitByNameSync("npc_dota_creature_80_boss", context)
	PrecacheUnitByNameSync("npc_dota_creature_70_boss", context)
	PrecacheUnitByNameSync("npc_dota_creature_40_boss", context)
	PrecacheUnitByNameSync("npc_dota_creature_30_boss", context)
	PrecacheUnitByNameSync("npc_dota_creature_50_boss", context)
	PrecacheUnitByNameSync("npc_dota_creature_100_boss", context)
	PrecacheUnitByNameSync("npc_dota_creature_130_boss_death", context)
	PrecacheUnitByNameSync("npc_dota_creature_10_boss", context)
	PrecacheUnitByNameSync("npc_dota_creature_20_boss", context)
	PrecacheUnitByNameSync("npc_dota_creature_roshan_boss", context)
	PrecacheUnitByNameSync("npc_dota_creature_100_boss_2", context)
	PrecacheUnitByNameSync("npc_dota_creature_100_boss_3", context)
	PrecacheUnitByNameSync("npc_dota_creature_100_boss_4", context)
	PrecacheUnitByNameSync("npc_dota_creature_100_boss_5", context)

	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_keeper_of_the_light.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_spectre.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_death_prophet.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_queenofpain.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_queenofpain.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_faceless_void.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_medusa.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_slark.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_terrorblade.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ursa.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_items.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/soundevents_conquest.vsndevts", context)
end

require("duel")


LinkLuaModifier("modifier_int_scaling", "modifiers/modifier_int_scaling", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_auto_pickup", "modifiers/modifier_auto_pickup", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_creep_elite", "modifiers/modifier_creep_elite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_happy_new_year", "modifiers/modifier_happy_new_year", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_auto_buy", "items/custom/item_auto_buy", LUA_MODIFIER_MOTION_NONE)

-- Create the game mode when we activate
function Activate()
	barebones:InitGameMode()

	FilterManager:Init()

	_G.DebugEnabled = false

	_G.AghanimGateUnit = nil
	_G.AghanimDefeated = false
	_G.UberBossesGateUnit = nil

	_G.tPlayers 				= {}
	_G.tHeroesRadiant 			= {}
	_G.tHeroesDire 				= {}
	_G.SummonedZeus = false
	_G.SummonedZeusDeaths = 0
	_G.receivedGold 			= {}
	_G.autoPickup 				= {}
	_G.lostItems				= {}
	_G.bWavesEnabled = false
	_G.stageSkafian = 1
	_G.morplingPartChance = 0.13
	_G.PlayerAddedAbilityCount = {}
	_G.PlayerBookRandomAbilities = {}
	_G.PlayerStoredAbilities = {}
	_G.PlayerDamageTimer = {}
	_G.PlayerDamageTest = {}
	_G.DifficultyEasyBuffs = {}
	_G.DifficultyNormalPlayerBuffs = {}
	_G.DifficultyNormalEnemyBuffs = {}
	_G.DifficultyHardPlayerBoons = {}
	_G.DifficultyHardEnemyBuffs = {}
	_G.DifficultyUnfairPlayerBoons = {}
	_G.DifficultyUnfairEnemyBuffs = {}
	_G.DifficultyImpossiblePlayerBoons = {}
	_G.DifficultyImpossibleEnemyBuffs = {}
	_G.DifficultyHellPlayerBoons = {}
	_G.DifficultyHellEnemyBuffs = {}
	_G.DifficultyHardcorePlayerBoons = {}
	_G.DifficultyHardcoreEnemyBuffs = {}
	_G.DifficultyEnemyBuffs = {}
	_G.MovementFreezeCounter = {} -- Used for the movement freeze difficulty modifier. Contains player ID's and counts.
	_G.PlayerNeutralDropCooldowns = {}
	_G.AkashaSpawned = false
	_G.PlayerGoldBank = {}
	_G.PlayerIsHost = {}
	_G.CapturedOutposts = {}
	_G.CPCaptures = 0
	_G.ItemDroppedAsanBlade1 = false
	_G.ItemDroppedAsanBlade2 = false
	_G.ItemDroppedAsanBlade3 = false
	_G.ItemDroppedMeteoriteSword = false
	_G.ItemDroppedAkashaConversion = false
	_G.ItemDroppedCarlConversion = false
	_G.ItemDroppedFrozenCrystal = false
	_G.PlayerDamageReduction = {}
	_G.ItemDroppedEnrageCrystal = false
	_G.NewGamePlusBonusBossEffects = {}

	_G.CreepsSpiderSpawned = false
    _G.CreepsSkafianSpawned = false
    _G.CreepsReefSpawned = false
    _G.CreepsMineSpawned = false
    _G.CreepsZeusSpawned = false
    _G.CreepsSFSpawned = false

	_G.NewGamePlusCounter = 0
	_G.IsResettingNewGamePlus = false --old and unused

	_G.OutpostTimerHandle = nil

	_G.DifficultyChatTablePlayers = {}
	_G.DifficultyChatTableEnemies = {}

	_G.HephaestusKilled = false
	_G.HephaestusKilledInitially = false

	_G.AghanimCrystalCount = 0
	_G.AghanimCrystalCountMax = 5

	_G.PerformanceUnitsTable = {}
	_G.PerformanceHeroesTable = {}

	_G.PlayerRunes = {}
	_G.PlayerRuneInventory = {}
	_G.PlayerRuneItems = {}

	_G.PlayerCurrentTalent = {}
	_G.PlayerTalentList = {}

	_G.FinalGameWavesEnabled = false
	_G.GameHasEnded = false

	_G.BossesKilled = {
		["forest"] = false,
		["spider"] = false,
		["lake"] = false,
		["wraith"] = false,
		["roshan"] = false,
		["skafian"] = false,
		["winter"] = false,
		["lava"] = false,
		["heaven"] = false,
	}

	_G.PlayerBonusDropChance = {}

	_G.PlayerBuffList = {}
	_G.PlayerBuffTimers = {}
	_G.PlayerBuffCountdownPanoramaTimers = {}
	_G.PlayerBuffListRandom = {} -- Contains 3 buffs that the timer will random from if it runs out
	_G.PlayerBuffRerollRemaining = {}

	_G.KeyMasterDeath1 = false
	_G.KeyMasterDeath2 = false
	_G.KeyMasterDeath3 = false

	_G.WavesNecrolyteAlive = false

	_G.BookOfLiesPurchases = {}

	_G.PlayerLevelsObtained = {}

	_G.GlobalTalentsInitiated = false

	_G.PlayerList = {}

	_G.AghanimTowers = {
		[1] = false,
		[2] = false,
		[3] = false,
		[4] = false,
		[5] = false
	}

	_G.PlayerNeutralDropTimer = {}

	if GetMapName() == "tcotrpg_1v1" then
		InitDuel()
	end

	-- Clear drops --
	Timers:CreateTimer(3.0, function()
		ClearItems(true) -- Removes containers, etc. dropped on the ground by creeps
		return 3.0
	end)

	--PrintTable(LoadKeyValues("scripts/npc/npc_abilities.txt"))
end