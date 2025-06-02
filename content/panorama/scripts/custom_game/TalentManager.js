var TalentManager = (function() {
    function TalentManager(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        var shopHud = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("shop")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.SELECTED_SIDE = 0
        this.SELECTED_SIDE_LEVEL = 0
        this.TALENT_ELEMENTS = []
        this.HERO_TALENTS = []

        this.visibility = "collapse";
        this.opacity = "0";

        this.OnTalentManagerInitiationComplete = function() {
            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("talent_manager_verify_valid_talent_on_hero", { 
                unit: lastRememberedHero
            })

            _this.GetTalentData()
        }

        this.OnTalentManagerHeroValidateTalentExists = function(data) {
            if(data.exists.toString() == "1") {
                _this.CreateTalentManagerButton()
            }   
        }

        /*
        this.OnTalentManagerGetCurrentSelectedTalent = function(data) {
            if(data.talent != null && data.talent.length > 0) {
                $.Msg("[Talent Manager] Client requested re-fetching of current talent.")
                _this.SELECTED_SIDE = data.talent.substr(-1)
                _this.SELECTED_SIDE_LEVEL = data.level
                _this.GetTalentData()
            }
        }
        */

        this.DeleteOldContainer = async function() {
            const mainPanelParent = mainHud.FindChildTraverse("lower_hud")
            let old = mainPanelParent.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "TalentManagerContainer") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }
        }

        this.OnTalentManagerHeroChanged = function(data) {
            _this.HERO_TALENTS = []
            _this.OnTalentSend(data)

            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("talent_manager_verify_valid_talent_on_hero", { 
                unit: lastRememberedHero
            })
        }

        this.OnTalentSend = function(data) {
            if(!data.talents) return;

            for(const talent of Object.entries(data.talents)) {
                _this.HERO_TALENTS.push(talent[1])
            }

            _this.HERO_TALENTS.sort()

            _this.CreateTalentManagerContainer(_this.HERO_TALENTS)
        }

        this.OnTalentResetComplete = function() {
            _this.SELECTED_SIDE = 0
            _this.SELECTED_SIDE = 0
            _this.SELECTED_SIDE_LEVEL = 0
            _this.TALENT_ELEMENTS = []
            _this.HERO_TALENTS = []

            _this.GetTalentData()
        }

        this.GetCurrentSelectedTalent = function() {
            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("talent_manager_get_current_selected_talent", { 
                unit: lastRememberedHero
            })
        }

        this.GetTalentData = function() {
            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("talent_manager_get_talents", { 
                unit: lastRememberedHero
            })
        }

        this.CreateTalentManagerContainer = function(talents) {
            _this.DeleteOldContainer()

            // Reset some variables
            const panelParent = mainHud.FindChildTraverse("lower_hud")
            const TalentManagerContainer = $.CreatePanel("Panel", context, "TalentManagerContainer");

            TalentManagerContainer.style.opacity = _this.opacity
            TalentManagerContainer.style.visibility = _this.visibility

            const TalentManagerContainerHeader = $.CreatePanel("Label", TalentManagerContainer, "TalentManagerContainerHeader");
            TalentManagerContainerHeader.text = $.Localize("#talents_header")

            const TalentManagerContainerBody = $.CreatePanel("Panel", TalentManagerContainer, "TalentManagerContainerBody");
            TalentManagerContainerBody.BLoadLayoutSnippet("TalentManagerContainer")

            const TalentManagerContainerBodyLeft = $.CreatePanel("Panel", TalentManagerContainerBody, "TalentManagerContainerBody_Left");
            const TalentManagerContainerBodyRight = $.CreatePanel("Panel", TalentManagerContainerBody, "TalentManagerContainerBody_Right");


            const TalentManagerResetButtonParent = $.CreatePanel("Panel", TalentManagerContainer, "TalentManagerResetButtonParent");
            const TalentManagerResetButtonInfo = $.CreatePanel("Label", TalentManagerResetButtonParent, "TalentManagerResetButtonInfo");
            TalentManagerResetButtonInfo.text = $.Localize("#talents_abnormal_info");
            const TalentManagerResetButton = $.CreatePanel("Label", TalentManagerResetButtonParent, "TalentManagerResetButton");
            TalentManagerResetButton.text = $.Localize("#talents_reset")

            TalentManagerResetButton.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID);

                    GameEvents.SendCustomGameEventToServer("talent_manager_reset_talents", { 
                        unit: lastRememberedHero, 
                    })
                }
            )

            const talentsLeft = []
            const talentsRight = []

            for(const side of talents) {
                const num = side.substr(-1)

                // We don't push in case it somehow manages to push more than once
                if(num == 1 && talentsLeft.length < 1) {
                    talentsLeft[0] = side
                }

                if(num == 2 && talentsRight.length < 1) {
                    talentsRight[0] = side
                }
            }

            _this.CreateTalentSegment(TalentManagerContainerBodyLeft, talentsLeft, 1)
            _this.CreateTalentSegment(TalentManagerContainerBodyRight, talentsRight, 2)

            TalentManagerContainer.SetParent(panelParent)
        }

        this.TalentGetCurrentLearnedLevel = function(side) {
            for(const elem of _this.TALENT_ELEMENTS) {
                if(elem) {
                    if(elem.side == side && elem.learned == true) {
                        return elem.level
                    }
                }
            }

            return 0
        }

        this.CreateTalentSegment = function(parent, abilityNames, sideNum) {
            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            const maxLevels = 3;
            let level = 4;

            for(let z = 1; z <= maxLevels; z++) {
                level--;
                const abilityName = abilityNames[0]
                const TalentContainer = $.CreatePanel("Panel", parent, "TalentContainer_"+sideNum+"_"+level);
                TalentContainer.AddClass("TalentContainer")
                TalentContainer.AddClass("unlearned")
                TalentContainer.side = sideNum 
                TalentContainer.level = level
                TalentContainer.learned = false
                TalentContainer.talent = abilityName

                _this.TALENT_ELEMENTS.push(TalentContainer)

                const side = sideNum

                if(level == 1) {
                    TalentContainer.RemoveClass("unlearned")
                }

                if(sideNum == 1) {
                    TalentContainer.AddClass("TalentBorder")
                }

                // Image
                const TalentImage = $.CreatePanel("DOTAAbilityImage", TalentContainer, "TalentImage");
                TalentImage.abilityname = abilityName

                // Text body
                const TalentBodyContainer = $.CreatePanel("Panel", TalentContainer, "TalentBodyContainer");
                const TalentBody = $.CreatePanel("Panel", TalentBodyContainer, "TalentBody");
                
                const TalentBodyName = $.CreatePanel("Label", TalentBody, "TalentBodyName");
                const TalentBodyDesc = $.CreatePanel("Label", TalentBody, "TalentBodyDesc");
                
                TalentBodyName.text = $.Localize("#DOTA_Tooltip_Ability_"+abilityName) + " (Lv. "+level+")"

                TalentBodyDesc.html = true;
                TalentBodyDesc.text = $.Localize("#DOTA_Tooltip_Ability_"+abilityName+"_"+level+"_Desc")

                // Event
                TalentContainer.SetPanelEvent(
                    "onmouseactivate", 
                    function(){
                        const clickedLevel = TalentContainer.level
                        const clickedSide = TalentContainer.side
                        const playerLevel = Players.GetLevel(localID)
                        
                        if((clickedLevel == 2 && playerLevel < 150) || (clickedLevel == 3 && playerLevel < 300)) {
                            if(clickedSide != _this.SELECTED_SIDE) return
                            let _errorLevel = clickedLevel == 2 ? "150" : (clickedLevel == 3 ? "300" : "1")
                            GameEvents.SendCustomGameEventToServer("talent_manager_send_error", { 
                                unit: lastRememberedHero, 
                                reason: $.Localize("#talents_requires_level") + " " + _errorLevel
                            })
                            return
                        }

                        if(_this.TalentGetCurrentLearnedLevel(clickedSide) < 1 && clickedLevel > 1) {
                            return
                        }

                        if(_this.SELECTED_SIDE == 0 || _this.SELECTED_SIDE == clickedSide) {
                            _this.SELECTED_SIDE = side

                            for(const elem of _this.TALENT_ELEMENTS) {
                                if(elem.IsValid()) {
                                    if(elem.side != _this.SELECTED_SIDE) {
                                        elem.RemoveClass("selected")
                                        elem.AddClass("faded")
                                    } else if(elem.side == _this.SELECTED_SIDE && elem.level == clickedLevel && elem.side == clickedSide && elem.learned == false && clickedLevel-1 == _this.TalentGetCurrentLearnedLevel(elem.side)) {
                                        elem.AddClass("selected")
                                        elem.RemoveClass("faded")
                                        elem.RemoveClass("unlearned")
                                        elem.learned = true;

                                        GameEvents.SendCustomGameEventToServer("talent_manager_learn_talent", { 
                                            unit: lastRememberedHero, 
                                            talent: TalentContainer.talent
                                        })

                                        TalentBodyDesc.text = $.Localize("#DOTA_Tooltip_Ability_"+abilityName+"_"+clickedLevel+"_Desc_"+clickedLevel)
                                    }
                                }
                            }
                        }
                    }
                )
            }
        }

        this.RemoveDotaTalentTree = function() {
            // Find the talent tree and disable it
            const talentTree = mainHud
                .FindChildTraverse("HUDElements")
                .FindChildTraverse("lower_hud")
                .FindChildTraverse("center_with_stats")
                .FindChildTraverse("center_block")
                .FindChildTraverse("AbilitiesAndStatBranch")
                .FindChildTraverse("StatBranch");
            talentTree.style.visibility = "collapse";
            talentTree.SetPanelEvent("onmouseover", function () {});
            talentTree.SetPanelEvent("onactivate", function () {});

            const popupTalentTree = mainHud
            .FindChildTraverse("DOTAStatBranch")
            .FindChildTraverse("StatBranchOuter")
            popupTalentTree.style.visibility = "collapse";
            popupTalentTree.SetPanelEvent("onmouseover", function () {});
            popupTalentTree.SetPanelEvent("onactivate", function () {});
            popupTalentTree.SetPanelEvent("onmouseactivate", function () {});

            // Disable the level up frame for the talent tree
            const levelUpButton = mainHud
                .FindChildTraverse("HUDElements")
                .FindChildTraverse("lower_hud")
                .FindChildTraverse("center_with_stats")
                .FindChildTraverse("center_block")
                .FindChildTraverse("level_stats_frame");
            levelUpButton.style.visibility = "collapse";
        }

        this.CreateTalentManagerButton = function() {
            const mainPanelParent = mainHud.FindChildTraverse("lower_hud")

            // Make the button for the rune UI
            const StatBranch = mainHud.FindChildTraverse("StatBranch")

            const parent = StatBranch.GetParent()

            const old = parent.FindChildTraverse("TalentManagerToggleButton")
            if(old) {
                old.RemoveAndDeleteChildren()
                old.DeleteAsync(0);
            }
            
            _this.RemoveDotaTalentTree()

            const btn = $.CreatePanel("Label", context, "TalentManagerToggleButton");
            btn.text = " "
            const icon = $.CreatePanel("Image", btn, "TalentManagerToggleButtonIcon");
            icon.SetImage("file://{resources}/images/custom_game/custom_talent_icon_off.png")
            btn.SetParent(parent)

            parent.MoveChildBefore(btn, parent.Children()[1])

            btn.SetPanelEvent(
              "onmouseover", 
              function(){
                $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#talent_button_info"));

                icon.SetImage("file://{resources}/images/custom_game/custom_talent_icon.png")
              }
            )

            btn.SetPanelEvent(
              "onmouseout", 
              function(){
                $.DispatchEvent("DOTAHideTextTooltip");
                if(icon.IsValid()) {
                    icon.SetImage("file://{resources}/images/custom_game/custom_talent_icon_off.png")
                }
              }
            )

            btn.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    if(_this.HERO_TALENTS.length < 1) {
                        //_this.GetTalentData()
                        var localID = Players.GetLocalPlayer()
                        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)
                        GameEvents.SendCustomGameEventToServer("talent_manager_send_error", { 
                            unit: lastRememberedHero, 
                            reason: $.Localize("#talents_hero_missing")
                        })
                        return
                    }

                    const container = mainPanelParent.FindChildTraverse("TalentManagerContainer")
                    if(container) {
                        if(container.style.visibility == "collapse") {
                            _this.opacity = "1"
                            _this.visibility = "visible"
                        } else if(container.style.visibility == "visible") {
                            _this.opacity = "0"
                            _this.visibility = "collapse"
                        }

                        container.style.opacity = _this.opacity
                        container.style.visibility = _this.visibility
                    }
                }
            )
        }

        this.OnUPressed = function() {
            if(_this.HERO_TALENTS.length < 1) {
                var localID = Players.GetLocalPlayer()
                var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)
                GameEvents.SendCustomGameEventToServer("talent_manager_send_error", { 
                    unit: lastRememberedHero, 
                    reason: $.Localize("#talents_hero_missing")
                })
                return
            }

            const mainPanelParent = mainHud.FindChildTraverse("lower_hud")
            const container = mainPanelParent.FindChildTraverse("TalentManagerContainer")
            if(container) {
                if(container.style.visibility == "collapse") {
                    _this.opacity = "1"
                    _this.visibility = "visible"
                } else if(container.style.visibility == "visible") {
                    _this.opacity = "0"
                    _this.visibility = "collapse"
                }

                container.style.opacity = _this.opacity
                container.style.visibility = _this.visibility
            }
        }

        GameEvents.Subscribe("talent_manager_send_talents", this.OnTalentSend);
        GameEvents.Subscribe("talent_manager_reset_talents_complete", this.OnTalentResetComplete);
        GameEvents.Subscribe("talent_manager_initation_complete", this.OnTalentManagerInitiationComplete);
        GameEvents.Subscribe("talent_manager_hero_changed", this.OnTalentManagerHeroChanged);
        GameEvents.Subscribe("talent_manager_send_verify_talent_exists_for_hero", this.OnTalentManagerHeroValidateTalentExists);
        //GameEvents.Subscribe("talent_manager_send_current_selected_talent", this.OnTalentManagerGetCurrentSelectedTalent);

        Game.AddCommand("CustomGameKeyU", _this.OnUPressed, "", 0);

        _this.GetTalentData()
    }

    return TalentManager;
}());

var ui = new TalentManager($.GetContextPanel());
