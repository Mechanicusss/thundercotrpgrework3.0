ItemManager = ItemManager or class({})

modifier_item_manager_player = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

function ItemManager:Init()
    -- Stat definitions
    self.statDefs = {
        -- Legendary Effect Values 
        -- These can be specified to regulate effect values on legendary and unique items
        -- e.g. 10% chance on attack to do [10-100%] damage
        -- Note: Supports up to max 3 values
        ["lev1"] = {
            id = 22
        },
        ["lev2"] = {
            id = 23
        },
        ["lev3"] = {
            id = 24
        },
        -- Regular stats
        ["damage"] = {
            id = 1
        },
        ["health"] = {
            id = 2
        },
        ["mana"] = {
            id = 3
        },
        ["armor"] = {
            id = 4
        },
        ["physical_block"] = {
            id = 5
        },
        ["movement_speed"] = {
            id = 6
        },
        ["hp_regen"] = {
            id = 7
        },
        ["mp_regen"] = {
            id = 8
        },
        ["attack_range"] = {
            id = 9
        },
        ["attack_speed"] = {
            id = 10
        },
        ["spell_lifesteal"] = {
            id = 11
        },
        ["special_ability"] = {
            id = 12
        },
        ["intellect"] = {
            id = 13
        },
        ["strength"] = {
            id = 14
        },
        ["agility"] = {
            id = 15
        },
        ["evasion"] = {
            id = 16
        },
        ["cooldown_reduction"] = {
            id = 17
        },
        ["ultimate_cooldown_reduction"] = {
            id = 18
        },
        ["nature_damage"] = {
            id = 19
        },
        ["cold_damage"] = {
            id = 20
        },
        ["fire_damage"] = {
            id = 21
        },
        ["nature_resistance"] = {
            id = 25
        },
        ["cold_resistance"] = {
            id = 26
        },
        ["fire_resistance"] = {
            id = 27
        },
        ["lightning_resistance"] = {
            id = 28
        },
        ["temporal_resistance"] = {
            id = 29
        },
        ["necrotic_resistance"] = {
            id = 30
        },
        ["arcane_resistance"] = {
            id = 31
        },
        ["thorns"] = {
            id = 32
        },
        ["crit_chance"] = {
            id = 33
        },
        ["crit_damage"] = {
            id = 34
        },
        ["necrotic_damage"] = {
            id = 35
        },
        ["hp_regen_pct"] = {
            id = 36
        },
        ["health_pct"] = {
            id = 37
        },
        ["lifesteal"] = {
            id = 38
        },
    }

    -- Item stat pool to select from during affix rerolling
    self.rerollPool = {
        ["common"] = {
            "health",
            "mana",
            "physical_block",
            "hp_regen",
            "mp_regen",
            "intellect",
            "strength",
            "agility",
            "nature_resistance",
            "cold_resistance",
            "fire_resistance",
            "lightning_resistance",
            "temporal_resistance",
            "necrotic_resistance",
            "arcane_resistance",
        },
        ["uncommon"] = {
            "thorns",
            "attack_range",
            "attack_speed",
            "armor",
            "movement_speed",
            "lifesteal",
            "spell_lifesteal",
            "damage",
            "evasion",
        },
        ["rare"] = {
            "crit_chance",
            "crit_damage",
            "special_ability",
            "health_pct",
            "hp_regen_pct",
        },
    }

    self.rerollPoolRanges = {
        ["health"] = {
            ["common"] = { min = 10, max = 50 },
            ["uncommon"] = { min = 50, max = 500 },
            ["rare"] = { min = 1000, max = 2000 }
        },
        ["mana"] = {
            ["common"] = { min = 50, max = 300 },
            ["uncommon"] = { min = 300, max = 600 },
            ["rare"] = { min = 600, max = 1200 }
        },
        ["physical_block"] = {
            ["common"] = { min = 10, max = 50 },
            ["uncommon"] = { min = 50, max = 100 },
            ["rare"] = { min = 100, max = 200 }
        },
        ["hp_regen"] = {
            ["common"] = { min = 5, max = 10 },
            ["uncommon"] = { min = 10, max = 15 },
            ["rare"] = { min = 15, max = 20 }
        },
        ["mp_regen"] = {
            ["common"] = { min = 0.3, max = 1.5 },
            ["uncommon"] = { min = 1.5, max = 3 },
            ["rare"] = { min = 3, max = 6 }
        },
        ["intellect"] = {
            ["common"] = { min = 1, max = 15 },
            ["uncommon"] = { min = 15, max = 20 },
            ["rare"] = { min = 20, max = 40 }
        },
        ["strength"] = {
            ["common"] = { min = 1, max = 15 },
            ["uncommon"] = { min = 15, max = 20 },
            ["rare"] = { min = 20, max = 40 }
        },
        ["agility"] = {
            ["common"] = { min = 1, max = 15 },
            ["uncommon"] = { min = 15, max = 20 },
            ["rare"] = { min = 20, max = 40 }
        },
        ["nature_resistance"] = {
            ["common"] = { min = MIN_RESISTANCE_BASE_VALUE/3, max = MAX_RESISTANCE_BASE_VALUE/3 },
            ["uncommon"] = { min = MIN_RESISTANCE_BASE_VALUE/2, max = MAX_RESISTANCE_BASE_VALUE/2 },
            ["rare"] = { min = MIN_RESISTANCE_BASE_VALUE, max = MAX_RESISTANCE_BASE_VALUE }
        },
        ["cold_resistance"] = {
            ["common"] = { min = MIN_RESISTANCE_BASE_VALUE/3, max = MAX_RESISTANCE_BASE_VALUE/3 },
            ["uncommon"] = { min = MIN_RESISTANCE_BASE_VALUE/2, max = MAX_RESISTANCE_BASE_VALUE/2 },
            ["rare"] = { min = MIN_RESISTANCE_BASE_VALUE, max = MAX_RESISTANCE_BASE_VALUE }
        },
        ["fire_resistance"] = {
            ["common"] = { min = MIN_RESISTANCE_BASE_VALUE/3, max = MAX_RESISTANCE_BASE_VALUE/3 },
            ["uncommon"] = { min = MIN_RESISTANCE_BASE_VALUE/2, max = MAX_RESISTANCE_BASE_VALUE/2 },
            ["rare"] = { min = MIN_RESISTANCE_BASE_VALUE, max = MAX_RESISTANCE_BASE_VALUE }
        },
        ["lightning_resistance"] = {
            ["common"] = { min = MIN_RESISTANCE_BASE_VALUE/3, max = MAX_RESISTANCE_BASE_VALUE/3 },
            ["uncommon"] = { min = MIN_RESISTANCE_BASE_VALUE/2, max = MAX_RESISTANCE_BASE_VALUE/2 },
            ["rare"] = { min = MIN_RESISTANCE_BASE_VALUE, max = MAX_RESISTANCE_BASE_VALUE }
        },
        ["temporal_resistance"] = {
            ["common"] = { min = MIN_RESISTANCE_BASE_VALUE/3, max = MAX_RESISTANCE_BASE_VALUE/3 },
            ["uncommon"] = { min = MIN_RESISTANCE_BASE_VALUE/2, max = MAX_RESISTANCE_BASE_VALUE/2 },
            ["rare"] = { min = MIN_RESISTANCE_BASE_VALUE, max = MAX_RESISTANCE_BASE_VALUE }
        },
        ["necrotic_resistance"] = {
            ["common"] = { min = MIN_RESISTANCE_BASE_VALUE/3, max = MAX_RESISTANCE_BASE_VALUE/3 },
            ["uncommon"] = { min = MIN_RESISTANCE_BASE_VALUE/2, max = MAX_RESISTANCE_BASE_VALUE/2 },
            ["rare"] = { min = MIN_RESISTANCE_BASE_VALUE, max = MAX_RESISTANCE_BASE_VALUE }
        },
        ["arcane_resistance"] = {
            ["common"] = { min = MIN_RESISTANCE_BASE_VALUE/3, max = MAX_RESISTANCE_BASE_VALUE/3 },
            ["uncommon"] = { min = MIN_RESISTANCE_BASE_VALUE/2, max = MAX_RESISTANCE_BASE_VALUE/2 },
            ["rare"] = { min = MIN_RESISTANCE_BASE_VALUE, max = MAX_RESISTANCE_BASE_VALUE }
        },
        ["thorns"] = {
            ["common"] = { min = 10, max = 500 },
            ["uncommon"] = { min = 500, max = 1000 },
            ["rare"] = { min = 1000, max = 2000 }
        },
        ["attack_range"] = {
            ["common"] = { min = 10, max = 50 },
            ["uncommon"] = { min = 50, max = 100 },
            ["rare"] = { min = 100, max = 200 }
        },
        ["attack_speed"] = {
            ["common"] = { min = 10, max = 25 },
            ["uncommon"] = { min = 25, max = 50 },
            ["rare"] = { min = 50, max = 100 }
        },
        ["armor"] = {
            ["common"] = { min = 1, max = 5 },
            ["uncommon"] = { min = 5, max = 15 },
            ["rare"] = { min = 15, max = 30 }
        },
        ["movement_speed"] = {
            ["common"] = { min = 1, max = 5 },
            ["uncommon"] = { min = 5, max = 10 },
            ["rare"] = { min = 10, max = 20 }
        },
        ["lifesteal"] = {
            ["common"] = { min = 1, max = 5 },
            ["uncommon"] = { min = 5, max = 10 },
            ["rare"] = { min = 10, max = 20 }
        },
        ["damage"] = {
            ["common"] = { min = 1, max = 20 },
            ["uncommon"] = { min = 20, max = 50 },
            ["rare"] = { min = 50, max = 100 }
        },
        ["spell_lifesteal"] = {
            ["common"] = { min = 1, max = 5 },
            ["uncommon"] = { min = 5, max = 10 },
            ["rare"] = { min = 10, max = 20 }
        },
        ["evasion"] = {
            ["common"] = { min = 1, max = 5 },
            ["uncommon"] = { min = 5, max = 10 },
            ["rare"] = { min = 10, max = 20 }
        },
        ["crit_chance"] = {
            ["common"] = { min = 1, max = 5 },
            ["uncommon"] = { min = 5, max = 10 },
            ["rare"] = { min = 10, max = 20 }
        },
        ["crit_damage"] = {
            ["common"] = { min = 1, max = 10 },
            ["uncommon"] = { min = 10, max = 20 },
            ["rare"] = { min = 20, max = 40 }
        },
        ["special_ability"] = {
            ["common"] = { min = 1, max = 1 },
            ["uncommon"] = { min = 2, max = 2 },
            ["rare"] = { min = 3, max = 3 }
        },
        ["health_pct"] = {
            ["common"] = { min = 1, max = 5 },
            ["uncommon"] = { min = 5, max = 10 },
            ["rare"] = { min = 10, max = 20 }
        },
        ["hp_regen_pct"] = {
            ["common"] = { min = 1, max = 5 },
            ["uncommon"] = { min = 5, max = 10 },
            ["rare"] = { min = 10, max = 20 }
        },
    }
    

    -- Ability pool to select from when giving a random ability level
    self.abilityPool = {
        "juggernaut_wind_gust_custom",
        "juggernaut_blade_fury_custom",
        "juggernaut_blade_dance_custom",
        "juggernaut_omni_slash_custom",
        "drow_ranger_frost_arrows_custom",
        "drow_ranger_glacier_custom",
        "drow_ranger_archery_custom",
        "drow_ranger_multishot_custom",
        "life_stealer_corpse_eater_custom",
        "life_stealer_feast_custom",
        "life_stealer_ghoul_frenzy_custom",
        "life_stealer_rage_custom",
        "necrolyte_death_coil_reaper",
        "necrolyte_death_aura",
        "necrolyte_hollowed_ground",
        "necrolyte_reapers_scythe_custom",
    }

    -- Item pool to select from when making random items
    self.itemPool = {
        ["common"] = {
            "item_claymore_custom",
            "item_ring_of_tarrasque_custom",
            "item_helm_of_iron_will_custom",
            "item_stout_shield_custom",
            "item_boots_custom",
            "item_ring_of_regen_custom",
            "item_tiara_of_selemene_custom",
            "item_gloves_custom",
        },
        ["rare"] = {
            "item_longsword_custom",
            "item_blitz_knuckles_custom",
            "item_chainmail_custom",
            "item_ring_of_health_custom",
            "item_diadem_custom",
            "item_ogre_axe_custom",
        },
        ["mythical"] = {
            "item_voodoo_mask_custom",
            "item_falcon_blade_custom",
            "item_oblivion_staff_custom",
            "item_blade_of_alacrity_custom",
            "item_power_treads_custom",
            "item_talisman_of_evasion_custom",
            "item_cornucopia_custom",
            "item_crown_custom",
        },
        ["legendary"] = {
            "item_crab_lance_custom",
            "item_bear_claw_custom",
            "item_seed_of_life_custom",
            "item_meteorite_sword",
            "item_cleavers_axe_custom",
            "item_scythe_of_ice_custom",
            "item_razorplate_custom",
            "item_carapace_of_qaldin_custom",
            "item_bogduggs_baldric_custom",
            "item_guardian_shell_custom",
            "item_longclaws_amulet_custom",
            "item_caustic_finale_custom",
            "item_blade_of_zephyr_custom",
            "item_dredged_trident_custom",
            "item_sanguinem_claws_custom",
        },
        ["unique"] = {
            "item_dread_retribution_bracers_custom",
            "item_reapers_respite_custom",
        },
    }

    -- These items can NEVER drop randomly from an enemy
    self.bannedItemPool = {
        "item_crab_lance_custom",
        "item_bear_claw_custom",
        "item_seed_of_life_custom",
        "item_meteorite_sword",
        "item_cleavers_axe_custom",
        "item_scythe_of_ice_custom",
    }

    -- Item definitions (stats, stat values, etc)
    --[[
        ["special_ability"] = {
            -- "name" is an optional parameter, can be set to prevent it from randoming an ability from the pool
            -- e.g. name = "juggernaut_wind_gust_custom"
        },
    ]]
    self.itemDefs = {
        -- Common
        ["item_claymore_custom"] = {
            ["stats"] = {
                ["damage"] = {
                    min = 2,
                    max = 5
                }
            }
        },
        ["item_ring_of_tarrasque_custom"] = {
            ["stats"] = {
                ["health"] = {
                    min = 50,
                    max = 150
                }
            }
        },
        ["item_helm_of_iron_will_custom"] = {
            ["stats"] = {
                ["armor"] = {
                    min = 2,
                    max = 3
                }
            }
        },
        ["item_stout_shield_custom"] = {
            ["stats"] = {
                ["physical_block"] = {
                    min = 5,
                    max = 10
                }
            }
        },
        ["item_boots_custom"] = {
            ["stats"] = {
                ["movement_speed"] = {
                    min = 10,
                    max = 20
                }
            }
        },
        ["item_ring_of_regen_custom"] = {
            ["stats"] = {
                ["hp_regen"] = {
                    min = 3,
                    max = 5
                }
            }
        },
        ["item_tiara_of_selemene_custom"] = {
            ["stats"] = {
                ["mp_regen"] = {
                    min = 1,
                    max = 2
                }
            }
        },
        ["item_gloves_custom"] = {
            ["stats"] = {
                ["attack_speed"] = {
                    min = 3,
                    max = 6
                }
            }
        },
        -- Rare
        ["item_longsword_custom"] = {
            ["stats"] = {
                ["damage"] = {
                    min = 15,
                    max = 20
                },
                ["attack_range"] = {
                    min = 15,
                    max = 25
                },
            }
        },
        ["item_blitz_knuckles_custom"] = {
            ["stats"] = {
                ["damage"] = {
                    min = 10,
                    max = 15
                },
                ["attack_speed"] = {
                    min = 6,
                    max = 9
                },
            }
        },
        ["item_chainmail_custom"] = {
            ["stats"] = {
                ["armor"] = {
                    min = 3,
                    max = 5
                },
                ["physical_block"] = {
                    min = 10,
                    max = 15
                },
            }
        },
        ["item_ring_of_health_custom"] = {
            ["stats"] = {
                ["health"] = {
                    min = 200,
                    max = 400
                },
                ["hp_regen"] = {
                    min = 5,
                    max = 10
                },
            }
        },
        ["item_diadem_custom"] = {
            ["stats"] = {
                ["mana"] = {
                    min = 25,
                    max = 50
                },
                ["mp_regen"] = {
                    min = 1,
                    max = 3
                },
            }
        },
        ["item_ogre_axe_custom"] = {
            ["stats"] = {
                ["strength"] = {
                    min = 1,
                    max = 5
                },
                ["damage"] = {
                    min = 5,
                    max = 10
                },
            }
        },
        -- Mythical
        ["item_voodoo_mask_custom"] = {
            ["stats"] = {
                ["spell_lifesteal"] = {
                    min = 8,
                    max = 16
                },
                ["intellect"] = {
                    min = 3,
                    max = 6
                },
                ["special_ability"] = {
                    min = 1,
                    max = 1,
                    --name = "juggernaut_wind_gust_custom"
                },
            }
        },
        ["item_falcon_blade_custom"] = {
            ["stats"] = {
                ["health"] = {
                    min = 200,
                    max = 300
                },
                ["mp_regen"] = {
                    min = 1,
                    max = 5
                },
                ["damage"] = {
                    min = 30,
                    max = 50
                },
            }
        },
        ["item_oblivion_staff_custom"] = {
            ["stats"] = {
                ["intellect"] = {
                    min = 5,
                    max = 10
                },
                ["mp_regen"] = {
                    min = 1,
                    max = 5
                },
                ["attack_speed"] = {
                    min = 9,
                    max = 12
                },
            }
        },
        ["item_power_treads_custom"] = {
            ["stats"] = {
                ["strength"] = {
                    min = 5,
                    max = 10
                },
                ["movement_speed"] = {
                    min = 20,
                    max = 40
                },
                ["armor"] = {
                    min = 3,
                    max = 6
                },
            }
        },
        ["item_blade_of_alacrity_custom"] = {
            ["stats"] = {
                ["agility"] = {
                    min = 5,
                    max = 10
                },
                ["attack_speed"] = {
                    min = 4,
                    max = 8
                },
                ["damage"] = {
                    min = 7,
                    max = 14
                },
            }
        },
        ["item_talisman_of_evasion_custom"] = {
            ["stats"] = {
                ["evasion"] = {
                    min = 1,
                    max = 15
                },
                ["movement_speed"] = {
                    min = 10,
                    max = 15
                },
                ["agility"] = {
                    min = 6,
                    max = 9
                },
            }
        },
        ["item_cornucopia_custom"] = {
            ["stats"] = {
                ["hp_regen"] = {
                    min = 10,
                    max = 17
                },
                ["mp_regen"] = {
                    min = 1,
                    max = 5
                },
                ["damage"] = {
                    min = 7,
                    max = 28
                },
            }
        },
        ["item_crown_custom"] = {
            ["stats"] = {
                ["strength"] = {
                    min = 3,
                    max = 6
                },
                ["agility"] = {
                    min = 3,
                    max = 6
                },
                ["intellect"] = {
                    min = 3,
                    max = 6
                },
            }
        },
        -- Legendary
        ["item_crab_lance_custom"] = {
            ["stats"] = {
                ["armor"] = {
                    min = 5,
                    max = 10
                },
                ["attack_range"] = {
                    min = 25,
                    max = 75
                },
                ["damage"] = {
                    min = 50,
                    max = 75
                },
                -- Chance
                ["lev1"] = {
                    min = 7,
                    max = 14,
                    pct = true
                },
                -- Armor
                ["lev2"] = {
                    min = 5,
                    max = 10,
                    pct = false
                },
            }
        },
        ["item_bear_claw_custom"] = {
            ["stats"] = {
                ["damage"] = {
                    min = 25,
                    max = 50
                },
                ["strength"] = {
                    min = 7,
                    max = 14
                },
                ["nature_damage"] = {
                    min = 5,
                    max = 10
                },
                -- Bleed current hp% damage
                ["lev1"] = {
                    min = 2,
                    max = 6,
                    pct = true
                },
            }
        },
        ["item_seed_of_life_custom"] = {
            ["stats"] = {
                ["strength"] = {
                    min = 15,
                    max = 30
                },
                ["agility"] = {
                    min = 15,
                    max = 30
                },
                ["intellect"] = {
                    min = 15,
                    max = 30
                },
                -- Hp Regen%
                ["lev1"] = {
                    min = 1,
                    max = 3,
                    pct = true
                },
                -- Double regen duration
                ["lev2"] = {
                    min = 3,
                    max = 6,
                    pct = false
                },
            }
        },
        ["item_meteorite_sword"] = {
            ["stats"] = {
                ["fire_damage"] = {
                    min = 10,
                    max = 20
                },
                -- Meteor proc chance
                ["lev1"] = {
                    min = 7,
                    max = 15,
                    pct = true
                },
                -- Meteor impact damage
                ["lev2"] = {
                    min = 250,
                    max = 500,
                    pct = false
                },
                -- Meteor DoT
                ["lev3"] = {
                    min = 45,
                    max = 90,
                    pct = false
                },
            }
        },
        ["item_cleavers_axe_custom"] = {
            ["stats"] = {
                ["damage"] = {
                    min = 10,
                    max = 25
                },
                -- Cleave
                ["lev1"] = {
                    min = 15,
                    max = 30,
                    pct = true
                },
            }
        },
        ["item_scythe_of_ice_custom"] = {
            ["stats"] = {
                ["cold_damage"] = {
                    min = 5,
                    max = 10
                },
                -- Chance
                ["lev1"] = {
                    min = 7,
                    max = 15,
                    pct = true
                },
                -- Duration
                ["lev2"] = {
                    min = 1,
                    max = 2,
                    pct = false
                },
            }
        },
        ["item_razorplate_custom"] = {
            ["stats"] = {
                ["armor"] = {
                    min = 10,
                    max = 20
                },
                ["thorns"] = {
                    min = 100,
                    max = 1000
                },
                -- % Of Thorns As Damage
                ["lev1"] = {
                    min = 100,
                    max = 200,
                    pct = true
                },
            }
        },
        ["item_carapace_of_qaldin_custom"] = {
            ["stats"] = {
                ["armor"] = {
                    min = 5,
                    max = 10
                },
                ["hp_regen"] = {
                    min = 5,
                    max = 25
                },
                ["mp_regen"] = {
                    min = 2,
                    max = 10
                },
                ["strength"] = {
                    min = 15,
                    max = 30
                },
                -- Storm Damage
                ["lev1"] = {
                    min = 100,
                    max = 200,
                    pct = false
                },
                -- Storm Trigger Interval
                ["lev2"] = {
                    min = 6,
                    max = 10,
                    pct = false
                },
            }
        },
        ["item_bogduggs_baldric_custom"] = {
            ["stats"] = {
                ["armor"] = {
                    min = 20,
                    max = 40
                },
                ["fire_resistance"] = {
                    min = 24,
                    max = 45
                },
                ["cold_resistance"] = {
                    min = 24,
                    max = 45
                },
                ["nature_resistance"] = {
                    min = 24,
                    max = 45
                },
                ["arcane_resistance"] = {
                    min = 24,
                    max = 45
                },
                ["nature_resistance"] = {
                    min = 24,
                    max = 45
                },
                ["lightning_resistance"] = {
                    min = 24,
                    max = 45
                },
                ["necrotic_resistance"] = {
                    min = 24,
                    max = 45
                },
                ["temporal_resistance"] = {
                    min = 24,
                    max = 45
                },
                -- % Movement Slow
                ["lev1"] = {
                    min = 15,
                    max = 30,
                    pct = true
                },
            }
        },
        ["item_guardian_shell_custom"] = {
            ["stats"] = {
                ["armor"] = {
                    min = 10,
                    max = 15
                },
            }
        },
        ["item_longclaws_amulet_custom"] = {
            ["stats"] = {
                ["spell_lifesteal"] = {
                    min = 16,
                    max = 32
                },
                ["cooldown_reduction"] = {
                    min = 8,
                    max = 16
                },
                ["special_ability"] = {
                    min = 1,
                    max = 4,
                },
                -- % Chance
                ["lev1"] = {
                    min = 12,
                    max = 24,
                    pct = true
                },
                -- % To Decrease
                ["lev2"] = {
                    min = 8,
                    max = 16,
                    pct = true
                },
            }
        },
        ["item_caustic_finale_custom"] = {
            ["stats"] = {
                ["damage"] = {
                    min = 100,
                    max = 160
                },
                ["attack_speed"] = {
                    min = 18,
                    max = 36
                },
                -- % Armor Per Stack
                ["lev1"] = {
                    min = 1,
                    max = 5,
                    pct = true
                },
                -- Explosion Damage
                ["lev2"] = {
                    min = 300,
                    max = 600,
                    pct = false
                },
            }
        },
        ["item_blade_of_zephyr_custom"] = {
            ["stats"] = {
                ["agility"] = {
                    min = 15,
                    max = 30
                },
                ["attack_speed"] = {
                    min = 12,
                    max = 24
                },
                ["evasion"] = {
                    min = 10,
                    max = 20
                },
                ["damage"] = {
                    min = 7,
                    max = 14
                },
                -- Attack Speed
                ["lev1"] = {
                    min = 25,
                    max = 50,
                    pct = false
                },
                -- Evasion
                ["lev2"] = {
                    min = 5,
                    max = 10,
                    pct = true
                },
                -- Cooldown
                ["lev3"] = {
                    min = 5,
                    max = 10,
                    pct = false
                },
            }
        },
        ["item_dredged_trident_custom"] = {
            ["stats"] = {
                ["crit_chance"] = {
                    min = 10,
                    max = 15
                },
                ["crit_damage"] = {
                    min = 25,
                    max = 50
                },
                -- Damage
                ["lev1"] = {
                    min = 100,
                    max = 150,
                    pct = false
                },
                -- Vulnerability Duration
                ["lev2"] = {
                    min = 2,
                    max = 5,
                    pct = false
                },
            }
        },
        -- Unique
        ["item_dread_retribution_bracers_custom"] = {
            ["stats"] = {
                ["cold_damage"] = {
                    min = 20,
                    max = 20
                },
                ["special_ability"] = {
                    min = 5,
                    max = 5,
                    name = "drow_ranger_multishot_custom"
                },
                -- Damage
                ["lev1"] = {
                    min = 50,
                    max = 150,
                    pct = true
                },
            }
        },
        ["item_reapers_respite_custom"] = {
            ["stats"] = {
                ["necrotic_damage"] = {
                    min = 10,
                    max = 10
                },
                ["special_ability"] = {
                    min = 5,
                    max = 5,
                    name = "necrolyte_hollowed_ground"
                },
                ["hp_regen_pct"] = {
                    min = 3,
                    max = 3
                },
                ["health_pct"] = {
                    min = 20,
                    max = 20
                },
                -- Max Hp % Damage taken every second
                ["lev1"] = {
                    min = 0.5,
                    max = 0.5,
                    pct = true
                },
            }
        },
        ["item_sanguinem_claws_custom"] = {
            ["stats"] = {
                ["agility"] = {
                    min = 12,
                    max = 25
                },
                ["crit_damage"] = {
                    min = 15,
                    max = 25
                },
                ["lifesteal"] = {
                    min = 10,
                    max = 20
                },
                ["attack_speed"] = {
                    min = 27,
                    max = 54
                },
                -- Attack Speed %
                ["lev1"] = {
                    min = 1,
                    max = 2,
                    pct = true
                },
                -- % Max Hp Heal per hit
                ["lev2"] = {
                    min = 0.5,
                    max = 1,
                    pct = true
                },
                -- Attack Damage Boost %
                ["lev3"] = {
                    min = 150,
                    max = 200,
                    pct = true
                },
            },
        },
    }
    
    -- Contains the items the player owns currently (even if they're not in their inventory)
    self.playerItems = {}

    -- Contains the players choice of item they're currently rerolling
    self.playerRerollCache = {}

    -- Events
    CustomGameEventManager:RegisterListener("item_tooltip_can_item_be_seen", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local accountId = tostring(PlayerResource:GetSteamAccountID(unit:GetPlayerID()))

        if unit:HasModifier("modifier_save_manager_player_loading") then return end

        local items = event.items 
        local results = {}

        for _,label in pairs(items) do 
            local itemIndex = label.itemIndex 
            local item = EntIndexToHScript(itemIndex)
            local canBeSeen = unit:CanEntityBeSeenByMyTeam(item)

            results[itemIndex] = results[itemIndex] or false
            results[itemIndex] = canBeSeen
        end
        
        CustomGameEventManager:Send_ServerToPlayer(player, "item_tooltip_can_item_be_seen_result", {
            results = results,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    CustomGameEventManager:RegisterListener("item_tooltip_pickup_item", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local accountId = tostring(PlayerResource:GetSteamAccountID(unit:GetPlayerID()))

        if unit:HasModifier("modifier_save_manager_player_loading") then return end

        local itemIndex = event.itemIndex

        local hItem = EntIndexToHScript(itemIndex)
        if not hItem then
            print("Cannot pick up item that does not exist")
            return
        end

        local itemPos = hItem:GetAbsOrigin()
        local distance = (itemPos - unit:GetAbsOrigin()):Length2D()
        if distance <= 300 then
            hItem:SetAbsOrigin(unit:GetAbsOrigin())
        end

        unit:PickupDroppedItem(hItem)
    end)

    CustomGameEventManager:RegisterListener("item_tooltip_display_item", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local accountId = tostring(PlayerResource:GetSteamAccountID(unit:GetPlayerID()))

        if unit:HasModifier("modifier_save_manager_player_loading") then return end

        local itemName = event.itemName

        local selectedUnit = EntIndexToHScript(event.selectedUnit)

        if not selectedUnit then
            print("Unit does not exist!")
            return
        end

        if not selectedUnit:HasInventory() then
            print("Unit does not have an inventory!")
            return
        end

        local item = nil

        local slot = event.inventorySlot
        if slot ~= -1 then
            if not slot then 
                print("Slot not found!")
                return 
            end 

            item = selectedUnit:GetItemInSlot(slot)

            if not item then
                print("Item not found!") 
                return 
            end 

            itemName = item:GetAbilityName()
        end

        -- Get ent index and level of the item being viewed
        local itemEntIndex = -1
        local itemLevel = -1

        if item ~= nil then 
            itemEntIndex = item:entindex()
            itemLevel = item:entindex()
        end

        -- If an item does not have randomized stat values it's just a normal item
        -- We still want to display the custom tooltip for it, just without stats
        if not self:IsItem(itemName) then 
            CustomGameEventManager:Send_ServerToPlayer(player, "item_tooltip_display_item_return", {
                stats = {},
                values = {},
                slot = slot,
                itemName = itemName,
                itemIndex = itemEntIndex,
                itemLevel = itemLevel,
                rarity = "common",
                upgradeLevel = 0,
                level1 = ITEM_LEVEL_INCREMENT_1,
                level2 = ITEM_LEVEL_INCREMENT_2,
                level3 = ITEM_LEVEL_INCREMENT_3,
                a = RandomFloat(1,1000),
                b = RandomFloat(1,1000),
                c = RandomFloat(1,1000),
            })
            return 
        end 

        local itemPreStats = self.itemDefs[itemName]
        if not itemPreStats then 
            print("Stats not found for item: " .. itemName)
            return 
        end 

        local statTemplate = itemPreStats["stats"]
        
        local itemData = {}
        
        local itemUID = -1
        local itemOwnerAccountID = nil

        if slot ~= -1 then
            --[[
            print(accountId, item.uId)
            itemData = self.playerItems[accountId][item.uId]
            if not itemData then 
                print("Values not found!")
                return 
            end 
            --]]
            -- Get the ID of the item purchaser
            local itemOwner = item:GetPurchaser()
            itemOwnerAccountID = tostring(PlayerResource:GetSteamAccountID(itemOwner:GetPlayerID()))

            itemUID = item.uId

            -- Not sure why but this method is more stable
            itemData = self:GetItemData(itemOwnerAccountID, item.uId)
            if not itemData then 
                print("Values not found!")
                return 
            end 

            -- This is done so the tooltip displays the stats of the item the player actually has
            -- and not just the stats are defined in the code
            local newStatTemplate = {}
            for statName,itemObj in pairs(itemData) do
                if string.match(statName, "_resistance") and self.playerItems[itemOwnerAccountID][item.uId][statName]["was_added_randomly"] == true then 
                    newStatTemplate[statName] = {
                        min = MIN_RESISTANCE_BASE_VALUE,
                        max = MAX_RESISTANCE_BASE_VALUE,
                    }
                elseif statName == "special_ability" and self.playerItems[itemOwnerAccountID][item.uId][statName]["was_added_randomly"] == true then 
                    newStatTemplate[statName] = {
                        min = MIN_SPECIAL_ABILITY_BASE_VALUE,
                        max = MAX_SPECIAL_ABILITY_BASE_VALUE,
                    }
                elseif itemObj.affixRerollValueMin ~= nil and itemObj.affixRerollValueMin > 0 then
                    newStatTemplate[statName] = {
                        min = itemObj.affixRerollValueMin,
                        max = itemObj.affixRerollValueMax,
                        pct = 0
                    }
                elseif statTemplate[statName] ~= nil then
                    newStatTemplate[statName] = {
                        min = statTemplate[statName].min,
                        max = statTemplate[statName].max,
                        pct = statTemplate[statName].pct,
                    }
                end
            end

            statTemplate = newStatTemplate
        end

        CustomGameEventManager:Send_ServerToPlayer(player, "item_tooltip_display_item_return", {
            stats = statTemplate,
            values = itemData,
            slot = slot,
            itemName = itemName,
            itemIndex = itemEntIndex,
            itemLevel = itemLevel,
            rarity = self:GetItemRarity(itemName),
            upgradeLevel = self:GetItemLevel(itemOwnerAccountID, itemUID),
            level1 = ITEM_LEVEL_INCREMENT_1,
            level2 = ITEM_LEVEL_INCREMENT_2,
            level3 = ITEM_LEVEL_INCREMENT_3,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    CustomGameEventManager:RegisterListener("item_manager_upgrade_item", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local accountId = tostring(PlayerResource:GetSteamAccountID(unit:GetPlayerID()))

        if unit:HasModifier("modifier_save_manager_player_loading") then return end

        local itemUID = event.item
        local item = self.playerItems[accountId][itemUID]

        if not item then 
            DisplayError(id, "Invalid Item.")
            return 
        end

        local itemIndex = self:GetItemEntityIndex(accountId, itemUID)
        local hItem = EntIndexToHScript(itemIndex)

        if not hItem then return end

        local rarity = self:GetItemRarity(hItem:GetAbilityName())
        if rarity ~= "legendary" and rarity ~= "unique" then return end

        local currentLevel = self:GetItemLevel(accountId, itemUID)

        if not currentLevel then 
            print("Level is invalid for item " .. itemUID)
            return
        end

        if currentLevel == 3 then 
            DisplayError(id, "Item Is Max Level.")
            return 
        end

        local cost = 0

        if currentLevel == 0 then
            cost = ITEM_LEVEL_UPGRADE_COST_1
        elseif currentLevel == 1 then
            cost = ITEM_LEVEL_UPGRADE_COST_2
        elseif currentLevel == 2 then
            cost = ITEM_LEVEL_UPGRADE_COST_3
        end

        local bankID = PlayerResource:GetSteamAccountID(unit:GetPlayerID())
        local balance = _G.PlayerGoldBank[bankID] + unit:GetGold()
        if balance < cost then
            DisplayError(id, "Not Enough Gold.")
            return
        end

        -- Remove gold
        local remaining = unit:GetGold() - cost
        if remaining < 0 then
            unit:ModifyGold(-unit:GetGold(), false, 98)
            _G.PlayerGoldBank[bankID] = _G.PlayerGoldBank[bankID] - math.abs(remaining)

            if _G.PlayerGoldBank[bankID] < 0 then
                _G.PlayerGoldBank[bankID] = 0
            end

            CustomNetTables:SetTableValue("modify_gold_bank", "game_info", { 
                userEntIndex = unit:GetEntityIndex(),
                amount = _G.PlayerGoldBank[bankID],
            })
        else
            unit:ModifyGold(-cost, false, 98)
        end

        -- make check for upgrade resource here
        -- !!!!!!!!

        -- Set multipliers
        local incrementPct = 1
        if currentLevel == 0 then
            incrementPct = ITEM_LEVEL_INCREMENT_1
        elseif currentLevel == 1 then
            incrementPct = ITEM_LEVEL_INCREMENT_2
        elseif currentLevel == 2 then 
            incrementPct = ITEM_LEVEL_INCREMENT_3
        end

        local totalMultiplier = (100+incrementPct)/100

        -- Increase values
        --self.playerItems[accountId][uId][statName]["value"] = statValue
        for statName,obj in pairs(item) do 
            local statValue = self.playerItems[accountId][itemUID][statName]["value"]
            local updatedValue = ""

            if statName == "special_ability" then 
                local specialName, specialValue = string.match(statValue, "([^:]+):([^:]+)")
                specialValue = math.floor(specialValue * totalMultiplier)
                updatedValue = specialName .. ":" .. specialValue

                self.playerItems[accountId][itemUID][statName]["value"] = updatedValue

                -- This is done to update stats
                -- Not sure if this is 100% bug free (for example, special ability or crit)
                local mods = unit:FindAllModifiersByName("modifier_stats_"..statName)
                for _,mod in pairs(mods) do 
                    if mod.uId == itemUID then 
                        mod.stats = updatedValue
                        mod:InvokeStats()
                        unit:CalculateStatBonus(true)
                    end
                end
            else
                if statName ~= "lev1" and statName ~= "lev2" and statName ~= "lev3" then 
                    updatedValue = math.floor(statValue * totalMultiplier)
                    self.playerItems[accountId][itemUID][statName]["value"] = updatedValue

                    -- This is done to update stats
                    -- Not sure if this is 100% bug free (for example, special ability or crit)
                    local mods = unit:FindAllModifiersByName("modifier_stats_"..statName)
                    for _,mod in pairs(mods) do 
                        if mod.uId == itemUID then 
                            mod.stats = updatedValue
                            mod:InvokeStats()
                            unit:CalculateStatBonus(true)
                        end
                    end
                end
            end
        end

        -- Level up item
        local newUpgradeLevel = currentLevel + 1
        self:SetItemLevel(accountId, itemUID, newUpgradeLevel)

        -- Update ability UI
        AbilityLevelManager:FetchAbilities(unit, false)

        -- This must be done to make sure stats are re-applied
        -- Bug: Upgrading an item when duplicates are in inventory will duplicate stats
        --ItemManager:Unequip(unit, hItem)
        --ItemManager:Equip(unit, hItem)

        CustomGameEventManager:Send_ServerToPlayer(player, "item_manager_upgrade_item_ui_reload", {
            forceDisplay = itemUID,
            playerItems = self.playerItems[accountId],
            itemDefs = self.itemDefs,
            itemPool = self.itemPool,
            level1 = ITEM_LEVEL_INCREMENT_1,
            level2 = ITEM_LEVEL_INCREMENT_2,
            level3 = ITEM_LEVEL_INCREMENT_3,
            level1cost = ITEM_LEVEL_UPGRADE_COST_1,
            level2cost = ITEM_LEVEL_UPGRADE_COST_2,
            level3cost = ITEM_LEVEL_UPGRADE_COST_3,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    CustomGameEventManager:RegisterListener("item_manager_reroll_affix_item", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local accountId = tostring(PlayerResource:GetSteamAccountID(unit:GetPlayerID()))

        if unit:HasModifier("modifier_save_manager_player_loading") then return end

        local itemUID = event.item
        local item = self.playerItems[accountId][itemUID]

        if not item then 
            DisplayError(id, "Invalid Item.")
            return 
        end

        local itemIndex = self:GetItemEntityIndex(accountId, itemUID)
        local hItem = EntIndexToHScript(itemIndex)

        if not hItem then return end

        local itemName = hItem:GetAbilityName()

        local stat = event.stat 

        if not stat or stat == -1 then 
            return 
        end 

        if self:IsAffixRerollLockedForItem(accountId, itemUID, stat) then 
            DisplayError(id, "Affix Reroll Limit Reached.")
            return
        end

        local rolls = self:GetItemRolls(accountId, itemUID, stat)
        local cost = ITEM_AFFIX_REROLL_BASE_COST * (1 + ((ITEM_AFFIX_REROLL_INCREASE_PER_ROLL_PCT/100)*rolls))
        if cost > GOLD_BANK_MAX_LIMIT or cost < 0 then
            cost = GOLD_BANK_MAX_LIMIT
        end

        local bankID = PlayerResource:GetSteamAccountID(unit:GetPlayerID())
        local balance = _G.PlayerGoldBank[bankID] + unit:GetGold()
        if balance < cost then
            DisplayError(id, "Not Enough Gold.")
            return
        end

        -- Remove gold
        local remaining = unit:GetGold() - cost
        if remaining < 0 then
            unit:ModifyGold(-unit:GetGold(), false, 98)
            _G.PlayerGoldBank[bankID] = _G.PlayerGoldBank[bankID] - math.abs(remaining)

            if _G.PlayerGoldBank[bankID] < 0 then
                _G.PlayerGoldBank[bankID] = 0
            end

            CustomNetTables:SetTableValue("modify_gold_bank", "game_info", { 
                userEntIndex = unit:GetEntityIndex(),
                amount = _G.PlayerGoldBank[bankID],
            })
        else
            unit:ModifyGold(-cost, false, 98)
        end

        local roll = RandomInt(0,100)
        local rollCategory = "common"

        if roll <= 10 then
            rollCategory = "rare"
        elseif roll > 10 and roll <= 25 then
            rollCategory = "uncommon"
        end

        local pool = shallowcopy(self.rerollPool)
        local statPool = pool[rollCategory]

        -- Convert existing stats to a set for quick lookup
        local existingStats = {}
        for statName, _ in pairs(self.playerItems[accountId][itemUID]) do
            existingStats[statName] = true

            if statName ~= stat then 
                -- Lock the stat
                self.playerItems[accountId][itemUID][statName]["affixRerollLocked"] = true
            else
                -- Increase the roll count
                self.playerItems[accountId][itemUID][statName]["affixRerollCount"] = self.playerItems[accountId][itemUID][statName]["affixRerollCount"] or 0
                self.playerItems[accountId][itemUID][statName]["affixRerollCount"] = self.playerItems[accountId][itemUID][statName]["affixRerollCount"] + 1
            end
        end

        -- Remove duplicate affixes
        for i = #statPool, 1, -1 do
            if existingStats[statPool[i]] then
                table.remove(statPool, i)
            end
        end

        local selectedRandomStat = statPool[RandomInt(1,#statPool)]

        local rollValueRange = RandomInt(1,100)
        local rollValueRangeCategory = "common"

        if rollValueRange <= 10 then
            rollValueRangeCategory = "rare"
        elseif rollValueRange > 10 and rollValueRange <= 25 then
            rollValueRangeCategory = "uncommon"
        end

        local rollMinMaxValues = self.rerollPoolRanges[selectedRandomStat][rollValueRangeCategory]
        local minValue = rollMinMaxValues.min
        local maxValue = rollMinMaxValues.max

        -- If the new stat exists on the item,
        -- the min/max range value will be what is defined originally
        local statDef = self.itemDefs[itemName]["stats"][selectedRandomStat]
        if statDef ~= nil then
            minValue = statDef.min
            maxValue = statDef.max
        end

        -- Get the items upgrade level
        local upgradeLevel = self:GetItemLevel(accountId, itemUID)

        local selectedRandomStatValue = RandomInt(minValue, maxValue)

        -- If the min/max value is a float then the value should also be a float
        if (minValue % 1 ~= 0) or (maxValue % 1 ~= 0) then 
            selectedRandomStatValue = RandomFloat(minValue, maxValue)
        end

        -- Modify value depending on the level of the item
        if upgradeLevel > 0 then 
            if upgradeLevel == 1 then 
                local levelMultiplier = (100+ITEM_LEVEL_INCREMENT_1)/100
                selectedRandomStatValue = math.floor(selectedRandomStatValue * levelMultiplier)
            end

            if upgradeLevel == 2 then 
                local levelMultiplier = (100+ITEM_LEVEL_INCREMENT_1)/100
                selectedRandomStatValue = math.floor(selectedRandomStatValue * levelMultiplier)
                local levelMultiplier2 = (100+ITEM_LEVEL_INCREMENT_2)/100
                selectedRandomStatValue = math.floor(selectedRandomStatValue * levelMultiplier2)
            end

            if upgradeLevel == 3 then 
                local levelMultiplier = (100+ITEM_LEVEL_INCREMENT_1)/100
                selectedRandomStatValue = math.floor(selectedRandomStatValue * levelMultiplier)
                local levelMultiplier2 = (100+ITEM_LEVEL_INCREMENT_2)/100
                selectedRandomStatValue = math.floor(selectedRandomStatValue * levelMultiplier2)
                local levelMultiplier3 = (100+ITEM_LEVEL_INCREMENT_3)/100
                selectedRandomStatValue = math.floor(selectedRandomStatValue * levelMultiplier3)
            end
        end

        -- If the random stat is an ability
        if selectedRandomStat == "special_ability" then 
            local abilityName = self.abilityPool[RandomInt(1, #self.abilityPool)]

            selectedRandomStatValue = abilityName..":"..selectedRandomStatValue
        end

        self.playerRerollCache[accountId] = self.playerRerollCache[accountId] or {}
        self.playerRerollCache[accountId] = {
            itemUID = itemUID,
            oldStat = stat,
            newStat = selectedRandomStat,
            newStatValue = selectedRandomStatValue,
            rerollTier = rollValueRangeCategory,
            minValue = minValue,
            maxValue = maxValue
        }

        -- Update ability UI
        AbilityLevelManager:FetchAbilities(unit, false)

        -- Update Affix Reroll UI
        self:ReloadItemAffixRerollUI(unit)

        CustomGameEventManager:Send_ServerToPlayer(player, "item_manager_affix_reroll_item_ui_result", {
            itemUID = itemUID,
            itemName = itemName,
            playerItems = self.playerItems[accountId],
            statName = selectedRandomStat,
            statValue = selectedRandomStatValue,
            itemLevel = upgradeLevel,
            valueRange = {
                min = minValue,
                max = maxValue
            },
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    CustomGameEventManager:RegisterListener("item_manager_reroll_affix_confirm_item", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local accountId = tostring(PlayerResource:GetSteamAccountID(unit:GetPlayerID()))

        if unit:HasModifier("modifier_save_manager_player_loading") then return end

        local cache = self.playerRerollCache[accountId]

        if not cache then 
            print("Cache does not exist.")
            return 
        end 

        local itemUID = cache.itemUID

        if not itemUID then 
            print("ItemUID does not exist.")
            return
        end

        local oldStat = cache.oldStat
        local newStat = cache.newStat
        local newStatValue = cache.newStatValue
        local rerollTier = cache.rerollTier
        local minValue = cache.minValue
        local maxValue = cache.maxValue

        -- Double check just in case
        if self:IsAffixRerollLockedForItem(accountId, itemUID, oldStat) then 
            DisplayError(id, "Affix Reroll Limit Reached.")
            return
        end

        local itemIndex = self:GetItemEntityIndex(accountId, itemUID)
        local hItem = EntIndexToHScript(itemIndex)

        if not hItem then
            print("Could not find item.")
            return
        end

        local itemName = hItem:GetAbilityName()

        -- Remove old affix
        local mods = unit:FindAllModifiersByName("modifier_stats_"..oldStat)
        for _,mod in pairs(mods) do 
            if mod.uId == itemUID then 
                mod:Destroy()
            end
        end

        local upgradeLevel = self:GetItemLevel(accountId, itemUID)

        -- Set stat values
        self.playerItems[accountId][itemUID] = self.playerItems[accountId][itemUID] or {}
        self.playerItems[accountId][itemUID][newStat] = self.playerItems[accountId][itemUID][newStat] or {}
        self.playerItems[accountId][itemUID][newStat]["item"] = self.playerItems[accountId][itemUID][newStat]["item"] or itemName 
        self.playerItems[accountId][itemUID][newStat]["item"] = itemName
        self.playerItems[accountId][itemUID][newStat]["value"] = self.playerItems[accountId][itemUID][newStat]["value"] or newStatValue 
        self.playerItems[accountId][itemUID][newStat]["value"] = newStatValue
        self.playerItems[accountId][itemUID][newStat]["entindex"] = self.playerItems[accountId][itemUID][newStat]["entindex"] or itemIndex 
        self.playerItems[accountId][itemUID][newStat]["entindex"] = itemIndex
        self.playerItems[accountId][itemUID][newStat]["upgradeLevel"] = self.playerItems[accountId][itemUID][newStat]["upgradeLevel"] or 0
        self.playerItems[accountId][itemUID][newStat]["upgradeLevel"] = upgradeLevel or 0
        self.playerItems[accountId][itemUID][newStat]["affixRerollLocked"] = self.playerItems[accountId][itemUID][newStat]["affixRerollLocked"] or false
        self.playerItems[accountId][itemUID][newStat]["affixRerollLocked"] = false
        self.playerItems[accountId][itemUID][newStat]["affixRerollValueTier"] = self.playerItems[accountId][itemUID][newStat]["affixRerollValueTier"] or "common"
        self.playerItems[accountId][itemUID][newStat]["affixRerollValueTier"] = rerollTier
        self.playerItems[accountId][itemUID][newStat]["affixRerollValueMin"] = self.playerItems[accountId][itemUID][newStat]["affixRerollValueMin"] or 0
        self.playerItems[accountId][itemUID][newStat]["affixRerollValueMin"] = minValue
        self.playerItems[accountId][itemUID][newStat]["affixRerollValueMax"] = self.playerItems[accountId][itemUID][newStat]["affixRerollValueMax"] or 0
        self.playerItems[accountId][itemUID][newStat]["affixRerollValueMax"] = maxValue
        self.playerItems[accountId][itemUID][newStat]["affixRerollCount"] = self.playerItems[accountId][itemUID][oldStat]["affixRerollCount"]

        -- Set old stat to nil
        self.playerItems[accountId][itemUID][oldStat] = nil

        -- Add new affix
        local modifierName = "modifier_stats_"..newStat
        local modifiers = unit:FindAllModifiersByName(modifierName)

        local modifierTable = { uId = itemUID, stats = newStatValue }

        if #modifiers < 1 then
            unit:AddNewModifier(unit, hItem, modifierName, modifierTable)
        else
            for _,modifier in pairs(modifiers) do 
                if not self:HasReceivedStatBonus(unit, newStat, itemUID) then 
                    unit:AddNewModifier(unit, hItem, modifierName, modifierTable)
                end
            end
        end

        -- Update ability UI
        AbilityLevelManager:FetchAbilities(unit, false)

        -- Empty cache
        self.playerRerollCache[accountId] = nil

        -- Update hero stats
        unit:CalculateStatBonus(true)

        -- Update upgrade UI
        self:ReloadItemUpgradeUI(unit)

        CustomGameEventManager:Send_ServerToPlayer(player, "item_manager_affix_reroll_item_ui_result", {
            itemUID = itemUID,
            itemName = itemName,
            playerItems = self.playerItems[accountId],
            itemLevel = upgradeLevel,
            rerollComplete = true,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)
end

function ItemManager:HeroSwapFix(hero)
    self:LoadPlayer(hero)

    hero:AddNewModifier(hero, nil, "modifier_item_manager_player", {})
end

function ItemManager:LoadAllPlayers()
    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and hero:GetUnitName() ~= "outpost_placeholder_unit" then
            self:LoadPlayer(hero)

            hero:AddNewModifier(hero, nil, "modifier_item_manager_player", {})
        end
    end
end

function ItemManager:LoadPlayer(hero)
    local playerID = hero:GetPlayerID()
    local accountID = PlayerResource:GetSteamAccountID(playerID)
    local id = tostring(accountID)
    local hPlayer = PlayerResource:GetPlayer(playerID)

    self.playerItems[id] = self.playerItems[id] or {}
end

function ItemManager:FindStatDef(id)
    for statName,statObj in pairs(self.statDefs) do 
        if statObj.id == id then
            return statName
        end
    end

    return nil
end

-- Creates an item with predefined stats and values (e.g. from a save)
function ItemManager:CreateItemWithData(owner, data)
    -- Get steam ID
    local accountId = tostring(PlayerResource:GetSteamAccountID(owner:GetPlayerID()))

    -- Get all necessary data
    local uId = data.uId
    local itemName = data.name
    local itemStats = data.stats

    -- Make sure stats exist for the item
    local itemDefData = self.itemDefs[itemName]

    if not itemDefData then 
        print("Item '" .. itemName .. "' does not exist!")
        return 
    end 

    -- Create the item
    local item = CreateItem(itemName, owner, owner)

    -- Set the unique ID on the item directly (just in case)
    item.uId = uId

    for _,statObj in pairs(itemStats) do 
        local statName = self:FindStatDef(statObj.id)
        local statValue = statObj.value

        local minValue = 0
        local maxValue = 0

        local rerollTier = statObj.rerollTier
        if rerollTier then
            if string.match(rerollTier, "common") or string.match(rerollTier, "uncommon") or string.match(rerollTier, "rare") then
                minValue = self.rerollPoolRanges[statName][rerollTier].min
                maxValue = self.rerollPoolRanges[statName][rerollTier].max
            end
        end

        local statLocked = false
        if statObj.locked ~= 0 then
            statLocked = true
        end

        -- Set stat values
        self.playerItems[accountId][uId] = self.playerItems[accountId][uId] or {}
        self.playerItems[accountId][uId][statName] = self.playerItems[accountId][uId][statName] or {}
        self.playerItems[accountId][uId][statName]["item"] = self.playerItems[accountId][uId][statName]["item"] or itemName 
        self.playerItems[accountId][uId][statName]["item"] = itemName
        self.playerItems[accountId][uId][statName]["value"] = self.playerItems[accountId][uId][statName]["value"] or statValue 
        self.playerItems[accountId][uId][statName]["value"] = statValue
        self.playerItems[accountId][uId][statName]["entindex"] = self.playerItems[accountId][uId][statName]["entindex"] or item:entindex() 
        self.playerItems[accountId][uId][statName]["entindex"] = item:entindex()
        self.playerItems[accountId][uId][statName]["upgradeLevel"] = self.playerItems[accountId][uId][statName]["upgradeLevel"] or 0
        self.playerItems[accountId][uId][statName]["upgradeLevel"] = data.level or 0
        self.playerItems[accountId][uId][statName]["affixRerollLocked"] = self.playerItems[accountId][uId][statName]["affixRerollLocked"] or false
        self.playerItems[accountId][uId][statName]["affixRerollLocked"] = statLocked or false
        self.playerItems[accountId][uId][statName]["affixRerollValueMin"] = self.playerItems[accountId][uId][statName]["affixRerollValueMin"] or 0
        self.playerItems[accountId][uId][statName]["affixRerollValueMin"] = minValue
        self.playerItems[accountId][uId][statName]["affixRerollValueMax"] = self.playerItems[accountId][uId][statName]["affixRerollValueMax"] or 0
        self.playerItems[accountId][uId][statName]["affixRerollValueMax"] = maxValue
        self.playerItems[accountId][uId][statName]["affixRerollCount"] = self.playerItems[accountId][uId][statName]["affixRerollCount"] or 0
        self.playerItems[accountId][uId][statName]["affixRerollCount"] = statObj.rolls or 0

        if statObj.addedRandomly == true then 
            self.playerItems[accountId][uId][statName]["was_added_randomly"] = true
        end
    end

    item:SetOwner(owner)
    item:SetPurchaser(owner)
    item:SetShareability(ITEM_NOT_SHAREABLE)
    item.itemManagerOwner = owner

    owner:AddItem(item)
end

-- Creates an item with completely random stat values (e.g. generating an item drop or when crafted)
function ItemManager:CreateItem(owner, name)
    -- Make sure stats exist for the item
    local itemDefData = self.itemDefs[name]

    if not itemDefData then 
        print("Item '" .. name .. "' does not exist!")
        return 
    end 

    -- Get steam ID
    local accountId = tostring(PlayerResource:GetSteamAccountID(owner:GetPlayerID()))

    -- Create the item
    local item = CreateItem(name, owner, owner)
    local seed = name .. tostring(RandomInt(100,9999))
    local uId = DoUniqueString(seed)

    -- Set the unique ID on the item directly (just in case)
    item.uId = uId

    -- Generate stat values
    -- We need to do a shallow copy because Lua is stupid
    local statData = shallowcopy(itemDefData["stats"])

    -- Generate random resistance with chance
    -- Does not add it if the item already has said resistance
    local randomResistancePool = {"fire", "cold", "nature", "lightning", "arcane", "temporal", "necrotic"}
    local rollChanceRandomResistance = RANDOM_RESISTANCE_CHANCE
    
    -- Mythical items have half the chance to roll a random resistance
    if self:GetItemRarity(name) == "mythical" then
        rollChanceRandomResistance = math.floor(rollChanceRandomResistance/2)
    end
    
    if (self:GetItemRarity(name) == "mythical" or self:GetItemRarity(name) == "legendary")  then 
        if RollPercentage(rollChanceRandomResistance) then
            local selectedRandomResistance = randomResistancePool[RandomInt(1, #randomResistancePool)]

            if statData[selectedRandomResistance.."_resistance"] == nil then 
                statData[selectedRandomResistance .. "_resistance"] = {
                    min = MIN_RESISTANCE_BASE_VALUE,
                    max = MAX_RESISTANCE_BASE_VALUE,
                    addedRandomly = true
                }
            end
        end
    end

    -- Generate random special ability with chance
    -- Does not add it if the item already has said stat
    local rollChanceRandomSpecialAbility = RANDOM_SPECIAL_ABILITY_CHANCE
    local minRandomAbilityValue = MIN_SPECIAL_ABILITY_BASE_VALUE
    local maxRandomAbilityValue = MAX_SPECIAL_ABILITY_BASE_VALUE

    -- Mythical items have a smaller chance to roll and roll less value
    if self:GetItemRarity(name) == "mythical" then
        rollChanceRandomSpecialAbility = math.floor(rollChanceRandomSpecialAbility/5)
        minRandomAbilityValue = 1
        maxRandomAbilityValue = 1
    end

    if (self:GetItemRarity(name) == "mythical" or self:GetItemRarity(name) == "legendary") and RollPercentage(rollChanceRandomSpecialAbility) then 
        local selectedRandomAbility = self.abilityPool[RandomInt(1, #self.abilityPool)]

        if statData["special_ability"] == nil then 
            statData["special_ability"] = {
                min = minRandomAbilityValue,
                max = maxRandomAbilityValue,
                name = selectedRandomAbility,
                addedRandomly = true
            }
        end
    end

    for statName,statRanges in pairs(statData) do 
        local minValue = statRanges.min 
        local maxValue = statRanges.max 

        local randomValue = RandomInt(minValue, maxValue)
        local statValue = randomValue

        -- Custom rules for ability level increments
        if statName == "special_ability" then 
            local predefinedAbilityName = statRanges.name 
            local abilityName = predefinedAbilityName

            if not abilityName then
                abilityName = self.abilityPool[RandomInt(1, #self.abilityPool)]
            end

            statValue = abilityName..":"..randomValue
        end

        self.playerItems[accountId][uId] = self.playerItems[accountId][uId] or {}
        self.playerItems[accountId][uId][statName] = self.playerItems[accountId][uId][statName] or {}
        self.playerItems[accountId][uId][statName]["item"] = self.playerItems[accountId][uId][statName]["item"] or name 
        self.playerItems[accountId][uId][statName]["item"] = name
        self.playerItems[accountId][uId][statName]["value"] = self.playerItems[accountId][uId][statName]["value"] or statValue 
        self.playerItems[accountId][uId][statName]["value"] = statValue
        self.playerItems[accountId][uId][statName]["entindex"] = self.playerItems[accountId][uId][statName]["entindex"] or item:entindex() 
        self.playerItems[accountId][uId][statName]["entindex"] = item:entindex()
        self.playerItems[accountId][uId][statName]["upgradeLevel"] = self.playerItems[accountId][uId][statName]["upgradeLevel"] or 0
        self.playerItems[accountId][uId][statName]["upgradeLevel"] = 0
        self.playerItems[accountId][uId][statName]["affixRerollLocked"] = self.playerItems[accountId][uId][statName]["affixRerollLocked"] or false
        self.playerItems[accountId][uId][statName]["affixRerollLocked"] = false
        self.playerItems[accountId][uId][statName]["affixRerollCount"] = self.playerItems[accountId][uId][statName]["affixRerollCount"] or 0
        self.playerItems[accountId][uId][statName]["affixRerollCount"] = 0

        if statRanges.addedRandomly == true then 
            self.playerItems[accountId][uId][statName]["was_added_randomly"] = true
        end
    end

    item:SetOwner(owner)
    item:SetPurchaser(owner)
    item:SetShareability(ITEM_NOT_SHAREABLE)
    item.itemManagerOwner = owner

    owner:AddItem(item)
end

function ItemManager:CreateItemOnGround(itemName, position)
    local item = CreateItem(itemName, nil, nil)
    
    -- Drop it in the world (starts in the air for nice effect)
    local hItem = CreateItemOnPositionForLaunch(position, item)
    item.itemManagerOwner = nil
    ItemManager:OnItemSpawned(item:entindex())

    -- Play effects
    local rarity = self:GetItemRarity(itemName)
    if rarity ~= nil then
        if rarity == "legendary" then
            local dropEffect = "particles/neutral_fx/neutral_item_drop__2lvl5.vpcf"
            local color = Vector(255, 144, 0)
            local effectCommon = ParticleManager:CreateParticle(dropEffect, PATTACH_ABSORIGIN_FOLLOW, hItem)
            
            ParticleManager:SetParticleControl(effectCommon, 0, hItem:GetAbsOrigin())
            ParticleManager:SetParticleControl(effectCommon, 60, color)
            ParticleManager:SetParticleControl(effectCommon, 61, Vector(1, 0, 0))
            ParticleManager:ReleaseParticleIndex(effectCommon)
            EmitSoundOn("NeutralLootDrop.Spawn", hItem)
        elseif rarity == "unique" then
            local dropEffect = "particles/neutral_fx/neutral_item_drop__2lvl5.vpcf"
            local color = Vector(222, 186, 42)
            local effectCommon = ParticleManager:CreateParticle(dropEffect, PATTACH_ABSORIGIN_FOLLOW, hItem)
            
            ParticleManager:SetParticleControl(effectCommon, 0, hItem:GetAbsOrigin())
            ParticleManager:SetParticleControl(effectCommon, 60, color)
            ParticleManager:SetParticleControl(effectCommon, 61, Vector(1, 0, 0))
            ParticleManager:ReleaseParticleIndex(effectCommon)
            EmitSoundOn("NeutralLootDrop.Spawn", hItem)
        end
    end
end

function ItemManager:OnItemSpawned(itemIndex)
    local hItem = EntIndexToHScript(itemIndex)
    if not hItem then
        print("Item for ground label does not exist")
        return
    end

    local hContainer = hItem:GetContainer()
    if not hContainer then
        -- If the container doesn't exist, it means the item is already a container
        hContainer = hItem
    end

    -- test label
    CustomGameEventManager:Send_ServerToAllClients("item_tooltip_display_ground_label", {
        pool = ItemManager.itemPool,
        posX = hContainer:GetAbsOrigin().x,
        posY = hContainer:GetAbsOrigin().y,
        posZ = hContainer:GetAbsOrigin().z,
        itemIndex = hContainer:entindex(),
        item = hItem:GetAbilityName(),
        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
      })
end

function ItemManager:OnItemPickedUp(playerID, itemName, itemEntityIndex)
    if not self:IsItem(itemName) then return true end 

    local accountId = tostring(PlayerResource:GetSteamAccountID(playerID))

    local itemData = self.playerItems[accountId]

    local itemExists = false
    local hItem = EntIndexToHScript(itemEntityIndex)

    for uId,statObj in pairs(itemData) do 
        for statName,statValueObj in pairs(statObj) do 
            local itemName = statValueObj.item 
            local itemStats = statValueObj.value 
            local itemEntIndex = statValueObj.entindex 

            if itemEntIndex == itemEntityIndex then 
                if hItem then 
                    if hItem.uId and hItem.uId == uId then
                        itemExists = true
                        break
                    end
                end
            end
        end
    end

    -- If the item doesn't exist in the players stored data, it's the first time they pick it up
    if not itemExists and hItem then 
        -- Make sure the item has no owner and no purchaser, then it means it's a fresh drop!
        -- You are not meant to be able to pick up other player's items so they shouldn't give stats if theyre picked up and the owner/purchaser dont match
        if hItem.itemManagerOwner == nil then
            local player = PlayerResource:GetPlayer(playerID):GetAssignedHero()
           
            player:TakeItem(hItem) -- Destroy the dropped item

            ItemManager:CreateItem(player, itemName)
        end
    end
end

function ItemManager:HasReceivedStatBonus(parent, statName, uId)
    local modifierName = "modifier_stats_"..statName
    local modifiers = parent:FindAllModifiersByName(modifierName)
    for _,modifier in pairs(modifiers) do 
        if modifier.uId == uId then
            return true
        end
    end

    return false
end

function ItemManager:GetItemData(accountId, uId)
    for zId,zObj in pairs(self.playerItems) do 
        if zId == accountId then
            for zzId, zzObj in pairs(zObj) do 
                if zzId == uId then
                    return zzObj
                end
            end
        end
    end

    return nil
end

function ItemManager:GetItemNameFromUID(player, uId) 
    for i=0,17 do
        local item = player:GetItemInSlot(i)
        if item ~= nil then
            if item.uId ~= nil and item.uId == uId then 
                return item:GetAbilityName()
            end
        end
    end
end

function ItemManager:Equip(parent, ability)
    local accountId = tostring(PlayerResource:GetSteamAccountID(parent:GetPlayerID()))
    local itemData = self.playerItems[accountId]
    for uId,statObj in pairs(itemData) do 
        local upgradeLevel = self:GetItemLevel(accountId, uId)

        for statName,statValueObj in pairs(statObj) do 
            local itemName = statValueObj.item 
            local itemStats = statValueObj.value 

            -- Fix values that have been changed
            -- We need to make sure that when item max/min values are increased or decreased,
            -- that it reflects on pre-existing items. We achieve this by scaling them up/down.
            local defaultStatValue = self.itemDefs[itemName]["stats"][statName]

            local rerollTier = statValueObj.affixRerollValueTier or nil
            if rerollTier ~= nil then 
                defaultStatValue = self.rerollPoolRanges[statName][rerollTier] or defaultStatValue
            end
            
            if defaultStatValue ~= nil then
                local statToCompare = itemStats
                local specialAbilityLevel = -1
                local specialAbilityName = ""
                
                -- Check if it's a special ability
                if type(itemStats) == "string" and string.find(itemStats, ":") ~= nil then
                    specialAbilityLevel = tonumber(itemStats:gsub("%D", ""))
                    specialAbilityName = string.match(itemStats, "^[^:]*:")
                    statToCompare = specialAbilityLevel
                end
                
                local maxValue = defaultStatValue.max
                local minValue = defaultStatValue.min

                -- Modify min/max values depending on the level of the item
                -- This is very important
                if upgradeLevel > 0 then 
                    if upgradeLevel == 1 then 
                        local levelMultiplier = (100+ITEM_LEVEL_INCREMENT_1)/100
                        maxValue = math.floor(maxValue * levelMultiplier)
                        minValue = math.floor(minValue * levelMultiplier)
                    end

                    if upgradeLevel == 2 then 
                        local levelMultiplier = (100+ITEM_LEVEL_INCREMENT_1)/100
                        maxValue = math.floor(maxValue * levelMultiplier)
                        minValue = math.floor(minValue * levelMultiplier)
                        local levelMultiplier2 = (100+ITEM_LEVEL_INCREMENT_2)/100
                        maxValue = math.floor(maxValue * levelMultiplier2)
                        minValue = math.floor(minValue * levelMultiplier2)
                    end

                    if upgradeLevel == 3 then 
                        local levelMultiplier = (100+ITEM_LEVEL_INCREMENT_1)/100
                        maxValue = math.floor(maxValue * levelMultiplier)
                        minValue = math.floor(minValue * levelMultiplier)
                        local levelMultiplier2 = (100+ITEM_LEVEL_INCREMENT_2)/100
                        maxValue = math.floor(maxValue * levelMultiplier2)
                        minValue = math.floor(minValue * levelMultiplier2)
                        local levelMultiplier3 = (100+ITEM_LEVEL_INCREMENT_3)/100
                        maxValue = math.floor(maxValue * levelMultiplier3)
                        minValue = math.floor(minValue * levelMultiplier3)
                    end
                end

                if statToCompare > maxValue then 
                    local valueToSet = maxValue
                    if specialAbilityLevel == -1 then
                        valueToSet = maxValue
                    else
                        valueToSet = specialAbilityName .. maxValue
                    end

                    itemStats = valueToSet
                    self.playerItems[accountId][uId][statName]["value"] = valueToSet
                end

                if statToCompare < minValue then 
                    local valueToSet = minValue
                    if specialAbilityLevel == -1 then
                        valueToSet = minValue
                    else
                        valueToSet = specialAbilityName .. minValue
                    end

                    itemStats = valueToSet
                    self.playerItems[accountId][uId][statName]["value"] = valueToSet
                end
            else
                -- If the stat wasn't added randomly, and it wasn't a rerolled stat, then it shouldn't be on the item, so we remove it
                if not self.playerItems[accountId][uId][statName]["was_added_randomly"] and self.playerItems[accountId][uId][statName]["affixRerollCount"] <= 0 then
                    itemStats = nil
                    self.playerItems[accountId][uId][statName] = nil
                end
            end

            if itemName == ability:GetAbilityName() and uId == ability.uId and itemStats ~= nil then
                local modifierName = "modifier_stats_"..statName
                local modifiers = parent:FindAllModifiersByName(modifierName)

                local modifierTable = { uId = uId, stats = itemStats }

                if #modifiers < 1 then
                    parent:AddNewModifier(parent, ability, modifierName, modifierTable)
                else
                    for _,modifier in pairs(modifiers) do 
                        if not self:HasReceivedStatBonus(parent, statName, uId) then 
                            parent:AddNewModifier(parent, ability, modifierName, modifierTable)
                        end
                    end
                end
            end
        end
    end

    AbilityLevelManager:FetchAbilities(parent, false)

    self:ReloadItemUpgradeUI(parent)
    self:ReloadItemAffixRerollUI(parent)
end

function ItemManager:Unequip(parent, ability)
    local accountId = tostring(PlayerResource:GetSteamAccountID(parent:GetPlayerID()))
    local itemData = self.playerItems[accountId]
    for uId,statObj in pairs(itemData) do 
        for statName,statValueObj in pairs(statObj) do 
            local itemName = statValueObj.item 
            local itemStats = statValueObj.value 

            if itemName == ability:GetAbilityName() and uId == ability.uId then
                local modifierName = "modifier_stats_"..statName
                local modifiers = parent:FindAllModifiersByName(modifierName)

                for _,modifier in pairs(modifiers) do 
                    if modifier.uId == uId then 
                        modifier:Destroy()
                    end
                end
            end
        end
    end

    AbilityLevelManager:FetchAbilities(parent, false)

    self:ReloadItemUpgradeUI(parent)
    self:ReloadItemAffixRerollUI(parent)
end

function ItemManager:ReloadItemUpgradeUI(unit) 
    local player = PlayerResource:GetPlayer(unit:GetPlayerID())

    local accountId = tostring(PlayerResource:GetSteamAccountID(unit:GetPlayerID()))

    CustomGameEventManager:Send_ServerToPlayer(player, "item_manager_upgrade_item_ui_reload", {
        playerItems = self.playerItems[accountId],
        itemDefs = self.itemDefs,
        itemPool = self.itemPool,
        level1 = ITEM_LEVEL_INCREMENT_1,
        level2 = ITEM_LEVEL_INCREMENT_2,
        level3 = ITEM_LEVEL_INCREMENT_3,
        level1cost = ITEM_LEVEL_UPGRADE_COST_1,
        level2cost = ITEM_LEVEL_UPGRADE_COST_2,
        level3cost = ITEM_LEVEL_UPGRADE_COST_3,
        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
    })
end

function ItemManager:ReloadItemAffixRerollUI(unit) 
    local player = PlayerResource:GetPlayer(unit:GetPlayerID())

    local accountId = tostring(PlayerResource:GetSteamAccountID(unit:GetPlayerID()))

    CustomGameEventManager:Send_ServerToPlayer(player, "item_manager_affix_reroll_item_ui_reload", {
        playerItems = self.playerItems[accountId],
        itemDefs = self.itemDefs,
        itemPool = self.itemPool,
        level1 = ITEM_LEVEL_INCREMENT_1,
        level2 = ITEM_LEVEL_INCREMENT_2,
        level3 = ITEM_LEVEL_INCREMENT_3,
        baseRerollCost = ITEM_AFFIX_REROLL_BASE_COST,
        rerollIncrementCostPct = ITEM_AFFIX_REROLL_INCREASE_PER_ROLL_PCT,
        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
    })
end

function ItemManager:IsItem(name)
    for quality,obj in pairs(self.itemPool) do 
        for _,item in pairs(obj) do 
            if item == name then 
                return true
            end
        end
    end

    return false
end

function ItemManager:GetItemRarity(name)
    for quality,obj in pairs(self.itemPool) do 
        for _,item in pairs(obj) do 
            if item == name then 
                return quality
            end
        end
    end

    return nil
end

function ItemManager:CanRandomlyDrop(name)
    for _,item in pairs(self.bannedItemPool) do 
        if item == name then
            return false
        end
    end

    return true
end

function ItemManager:GetSpecialValueFor(item, attrName)
    local parent = item:GetCaster()
    local accountId = tostring(PlayerResource:GetSteamAccountID(parent:GetPlayerID()))
    local itemData = self.playerItems[accountId]
    local data = self:GetItemData(accountId, item.uId)

    if data then 
        if data[attrName] then 
            return data[attrName]["value"]
        end
    end
end

function ItemManager:GetItemLevel(accountId, uId)
    if uId == -1 then return 0 end 
    if not accountId then return end

    for statName,statObj in pairs(self.playerItems[accountId][uId]) do 
        return statObj["upgradeLevel"] or 0
    end

    return 0
end

function ItemManager:GetItemRolls(accountId, uId, stat)
    if uId == -1 then return 0 end 
    if not accountId then return end

    for statName,statObj in pairs(self.playerItems[accountId][uId]) do 
        if statName == stat then
            return statObj["affixRerollCount"] or 0
        end
    end

    return 0
end

function ItemManager:IsAffixRerollLockedForItem(accountId, uId, stat)
    if uId == -1 then return 0 end 
    if not accountId then return end

    for statName,statObj in pairs(self.playerItems[accountId][uId]) do 
        if statName == stat then
            return statObj["affixRerollLocked"] or false
        end
    end

    return false
end

function ItemManager:SetItemLevel(accountId, uId, level)
    for statName,statObj in pairs(self.playerItems[accountId][uId]) do 
        self.playerItems[accountId][uId][statName]["upgradeLevel"] = level
    end
end

function ItemManager:GetItemEntityIndex(accountId, uId)
    for statName,statObj in pairs(self.playerItems[accountId][uId]) do 
        return statObj["entindex"]
    end

    return nil
end

function ItemManager:GetAffixRerollTier(accountId, uId, stat)
    for statName,statObj in pairs(self.playerItems[accountId][uId]) do 
        if statName == stat then
            return statObj["affixRerollValueTier"]
        end
    end

    return nil
end

