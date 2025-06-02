var CustomHeroStats = (function() {
    function CustomHeroStats(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        let parentHud = mainHud.FindChildTraverse("AbilitiesAndStatBranch")
        let lowerHud = mainHud.FindChildTraverse("lower_hud")
        let abilitiesHud = mainHud.FindChildTraverse("abilities")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.visibility = "collapse"
        this.opacity = "0"

        this.currentUnit = null
        this.isOpen = false

        this.DeleteOldContainer = async function() {
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "CustomHeroStatsContainer") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            _this.CustomHeroStatsContainer = $.CreatePanel("Panel", context, "CustomHeroStatsContainer")
            _this.CustomHeroStatsContainer.style.visibility = _this.visibility
            _this.CustomHeroStatsContainer.style.opacity = _this.opacity
        }

        this.OnUnitSelected = function(data) {
            let units = Players.GetSelectedEntities(Players.GetLocalPlayer())
            if(units) {
                let portraitUnit = Players.GetLocalPlayerPortraitUnit() // this is the currently selected unit
                var localID = Players.GetLocalPlayer()
                var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID) // this is your hero, and units[0] is the same as this

                _this.currentUnit = portraitUnit

                if(portraitUnit != lastRememberedHero) {
                    _this.CustomHeroStatsContainer.style.visibility = "collapse"
                    _this.CustomHeroStatsContainer.style.opacity = "0"
                    _this.CustomHeroStatsButton.style.visibility = "collapse"
                    _this.CustomHeroStatsButton.style.opacity = "0"
                    _this.isOpen = false
                    _this.visibility = "collapse"
                    _this.opacity = "0"
                } else if(portraitUnit == lastRememberedHero) {
                    _this.CustomHeroStatsButton.style.visibility = "visible"
                    _this.CustomHeroStatsButton.style.opacity = "1"
                }
            }
        }

        this.OnUpdate = function(data) {
            _this.DeleteOldContainer()
            
            // Offensive
            let CustomHeroStatsSection_Offensive = $.CreatePanel("Panel", _this.CustomHeroStatsContainer, "CustomHeroStatsSection")
                        
            let CustomHeroStatsSectionHeader_Offensive = $.CreatePanel("Label", CustomHeroStatsSection_Offensive, "CustomHeroStatsSectionHeader")
            CustomHeroStatsSectionHeader_Offensive.text = "Offensive"

            let CustomHeroStatsSectionAttributes_Offensive = $.CreatePanel("Panel", CustomHeroStatsSection_Offensive, "CustomHeroStatsSectionAttributes")

            let CustomHeroStatsSectionAttributeItem_Offensive_CritChance = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Offensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Offensive_CritChance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_CritChance, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Offensive_CritChance.text = "Critical Chance:"
            let CustomHeroStatsSectionAttributeItemValue_Offensive_CritChance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_CritChance, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Offensive_CritChance.text = (data.critChance || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Offensive_CritDamage = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Offensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Offensive_CritDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_CritDamage, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Offensive_CritDamage.text = "Critical Damage:"
            let CustomHeroStatsSectionAttributeItemValue_Offensive_CritDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_CritDamage, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Offensive_CritDamage.text = (data.critDamage || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Offensive_FireDamage = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Offensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Offensive_FireDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_FireDamage, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Offensive_FireDamage.text = "Fire Damage:"
            let CustomHeroStatsSectionAttributeItemValue_Offensive_FireDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_FireDamage, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Offensive_FireDamage.text = (data.fireDamage || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Offensive_ColdDamage = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Offensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Offensive_ColdDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_ColdDamage, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Offensive_ColdDamage.text = "Cold Damage:"
            let CustomHeroStatsSectionAttributeItemValue_Offensive_ColdDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_ColdDamage, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Offensive_ColdDamage.text = (data.coldDamage || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Offensive_LightningDamage = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Offensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Offensive_LightningDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_LightningDamage, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Offensive_LightningDamage.text = "Lightning Damage:"
            let CustomHeroStatsSectionAttributeItemValue_Offensive_LightningDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_LightningDamage, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Offensive_LightningDamage.text = (data.lightningDamage || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Offensive_NatureDamage = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Offensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Offensive_NatureDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_NatureDamage, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Offensive_NatureDamage.text = "Nature Damage:"
            let CustomHeroStatsSectionAttributeItemValue_Offensive_NatureDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_NatureDamage, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Offensive_NatureDamage.text = (data.natureDamage || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Offensive_NecroticDamage = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Offensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Offensive_NecroticDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_NecroticDamage, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Offensive_NecroticDamage.text = "Necrotic Damage:"
            let CustomHeroStatsSectionAttributeItemValue_Offensive_NecroticDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_NecroticDamage, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Offensive_NecroticDamage.text = (data.necroticDamage || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Offensive_ArcaneDamage = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Offensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Offensive_ArcaneDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_ArcaneDamage, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Offensive_ArcaneDamage.text = "Arcane Damage:"
            let CustomHeroStatsSectionAttributeItemValue_Offensive_ArcaneDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_ArcaneDamage, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Offensive_ArcaneDamage.text = (data.arcaneDamage || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Offensive_TemporalDamage = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Offensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Offensive_TemporalDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_TemporalDamage, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Offensive_TemporalDamage.text = "Temporal Damage:"
            let CustomHeroStatsSectionAttributeItemValue_Offensive_TemporalDamage = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Offensive_TemporalDamage, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Offensive_TemporalDamage.text = (data.temporalDamage || 0) + "%"

            // Defensive
            let CustomHeroStatsSection_Defensive = $.CreatePanel("Panel", _this.CustomHeroStatsContainer, "CustomHeroStatsSection")

            let CustomHeroStatsSectionHeader_Defensive = $.CreatePanel("Label", CustomHeroStatsSection_Defensive, "CustomHeroStatsSectionHeader")
            CustomHeroStatsSectionHeader_Defensive.text = "Defensive"

            let CustomHeroStatsSectionAttributes_Defensive = $.CreatePanel("Panel", CustomHeroStatsSection_Defensive, "CustomHeroStatsSectionAttributes")

            let CustomHeroStatsSectionAttributeItem_Defensive_DamageReduction = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Defensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Defensive_DamageReduction = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_DamageReduction, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Defensive_DamageReduction.text = "Damage Reduction:"
            let CustomHeroStatsSectionAttributeItemValue_Defensive_DamageReduction = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_DamageReduction, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Defensive_DamageReduction.text = (Math.abs(data.damageReduction) || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Defensive_FireResistance = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Defensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Defensive_FireResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_FireResistance, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Defensive_FireResistance.text = "Fire Resistance:"
            let CustomHeroStatsSectionAttributeItemValue_Defensive_FireResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_FireResistance, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Defensive_FireResistance.text = (Math.abs(data.fireResistance) || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Defensive_ColdResistance = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Defensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Defensive_ColdResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_ColdResistance, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Defensive_ColdResistance.text = "Cold Resistance:"
            let CustomHeroStatsSectionAttributeItemValue_Defensive_ColdResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_ColdResistance, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Defensive_ColdResistance.text = (Math.abs(data.coldResistance) || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Defensive_LightningResistance = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Defensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Defensive_LightningResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_LightningResistance, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Defensive_LightningResistance.text = "Lightning Resistance:"
            let CustomHeroStatsSectionAttributeItemValue_Defensive_LightningResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_LightningResistance, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Defensive_LightningResistance.text = (Math.abs(data.lightningResistance) || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Defensive_NatureResistance = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Defensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Defensive_NatureResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_NatureResistance, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Defensive_NatureResistance.text = "Nature Resistance:"
            let CustomHeroStatsSectionAttributeItemValue_Defensive_NatureResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_NatureResistance, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Defensive_NatureResistance.text = (Math.abs(data.natureResistance) || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Defensive_NecroticResistance = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Defensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Defensive_NecroticResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_NecroticResistance, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Defensive_NecroticResistance.text = "Necrotic Resistance:"
            let CustomHeroStatsSectionAttributeItemValue_Defensive_NecroticResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_NecroticResistance, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Defensive_NecroticResistance.text = (Math.abs(data.necroticResistance) || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Defensive_ArcaneResistance = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Defensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Defensive_ArcaneResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_ArcaneResistance, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Defensive_ArcaneResistance.text = "Arcane Resistance:"
            let CustomHeroStatsSectionAttributeItemValue_Defensive_ArcaneResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_ArcaneResistance, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Defensive_ArcaneResistance.text = (Math.abs(data.arcaneResistance) || 0) + "%"

            let CustomHeroStatsSectionAttributeItem_Defensive_TemporalResistance = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Defensive, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Defensive_TemporalResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_TemporalResistance, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Defensive_TemporalResistance.text = "Temporal Resistance:"
            let CustomHeroStatsSectionAttributeItemValue_Defensive_TemporalResistance = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Defensive_TemporalResistance, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Defensive_TemporalResistance.text = (Math.abs(data.temporalResistance) || 0) + "%"

            // Other
            let CustomHeroStatsSection_Other = $.CreatePanel("Panel", _this.CustomHeroStatsContainer, "CustomHeroStatsSection")
            CustomHeroStatsSection_Other.style.borderRight = "0px"

            let CustomHeroStatsSectionHeader_Other = $.CreatePanel("Label", CustomHeroStatsSection_Other, "CustomHeroStatsSectionHeader")
            CustomHeroStatsSectionHeader_Other.text = "Other"

            let CustomHeroStatsSectionAttributes_Other = $.CreatePanel("Panel", CustomHeroStatsSection_Other, "CustomHeroStatsSectionAttributes")

            let CustomHeroStatsSectionAttributeItem_Other_DropRate = $.CreatePanel("Panel", CustomHeroStatsSectionAttributes_Other, "CustomHeroStatsSectionAttributeItem")
            let CustomHeroStatsSectionAttributeItemName_Other_DropRate = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Other_DropRate, "CustomHeroStatsSectionAttributeItemName")
            CustomHeroStatsSectionAttributeItemName_Other_DropRate.text = "Magic Find:"
            let CustomHeroStatsSectionAttributeItemValue_Other_DropRate = $.CreatePanel("Label", CustomHeroStatsSectionAttributeItem_Other_DropRate, "CustomHeroStatsSectionAttributeItemValue")
            CustomHeroStatsSectionAttributeItemValue_Other_DropRate.text = (data.bonusDropRate || 0) + "%"

            _this.CustomHeroStatsContainer.style.visibility = _this.visibility
            _this.CustomHeroStatsContainer.style.opacity = _this.opacity
        }

        this.CreateButton = function() {
            let parent = mainHud.FindChildTraverse("center_block").FindChildTraverse("PortraitGroup")

            let old = parent.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "CustomHeroStatsButton") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            _this.CustomHeroStatsButton = $.CreatePanel("Panel", context, "CustomHeroStatsButton")
            _this.CustomHeroStatsButtonText = $.CreatePanel("Label", _this.CustomHeroStatsButton, "CustomHeroStatsButtonText")
            _this.CustomHeroStatsButtonText.text = "▲"

            _this.CustomHeroStatsButton.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    Game.EmitSound("TCOT_Option_Click")
                    if(_this.CustomHeroStatsContainer.style.visibility != "visible") {
                        _this.CustomHeroStatsContainer.style.visibility = "visible"
                        _this.CustomHeroStatsContainer.style.opacity = "1"
                        _this.visibility = "visible"
                        _this.opacity = "1"
                        _this.isOpen = true
                    } else {
                        _this.CustomHeroStatsContainer.style.visibility = "collapse"
                        _this.CustomHeroStatsContainer.style.opacity = "0"
                        _this.visibility = "collapse"
                        _this.opacity = "0"
                        _this.isOpen = false
                    }
                }
            )

            _this.CustomHeroStatsButton.SetParent(parent)
        }

        this.DeleteOldContainer()

        this.CreateButton()

        GameEvents.Subscribe("dota_player_update_selected_unit", this.OnUnitSelected);
        GameEvents.Subscribe("dota_player_update_query_unit", this.OnUnitSelected);
        GameEvents.Subscribe("hero_stats_manager_on_update", this.OnUpdate);
    }

    return CustomHeroStats;
}());

var ui = new CustomHeroStats($.GetContextPanel());
