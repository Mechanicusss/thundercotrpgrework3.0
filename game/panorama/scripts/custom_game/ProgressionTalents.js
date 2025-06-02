var ProgressionTalents = (function() {
    function ProgressionTalents(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        var shopHud = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("shop")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.visibility = "collapse";
        this.opacity = "0";

        this.DeleteOldContainer = async function() {
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "ProgressionTalentsContainer") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }
        }

        this.OnTalentResetComplete = function(data) {
            const reset = _this.PlayerPersonalResetTalentButton

            let time = 300
            
            function Countdown() {
                if(time < 1) {
                    reset.text = "Reset Talents"
                    return
                }
                reset.text = `Reset Talents (${time}s)`

                time = time - 1

                $.Schedule(1, Countdown)
            }

            Countdown()
        }

        this.OnTalentLevelsComplete = function(data) {
            _this.PlayerExperienceContainer_CurrentLevel.text = data.exp
            _this.PlayerExperienceContainer_NextLevel.text = data.nextLevelExp
            _this.PlayerPersonalTextPlaceholder.text = `Current Level: ${data.level} (Unspent Points: ${data.points})`

            /*const percentage = (data.exp / data.nextLevelExp) * 100

            _this.PlayerExperienceContainer_Bar.style.width = percentage+"%"*/

            const currentLevelExp = data.nextLevelExp - data.prevLevelExp;
            const currentLevelProgress = data.exp - data.prevLevelExp;
            const percentage = (currentLevelProgress / currentLevelExp) * 100;

            _this.PlayerExperienceContainer_Bar.style.width = percentage + "%";
        }

        this.OnTalentLearnedComplete = function(data) {
            const talent = data.talent // talent name
            const talentType = data.attribute 
            const talentNum = data.talentNum
            const level = data.level
            const maxLevel = data.maxLevel

            if(talent) {
                const element = _this[`branch_${talentType}_Talent_${talentNum}_Level`]
                if(element.IsValid()) {
                    element.text = level + "/" + maxLevel

                    const parentElement = _this[`branch_${talentType}_Talent_${talentNum}`]
                    if(parentElement.IsValid()) {
                        parentElement.style.opacity = "1"
                    }
                }
            }
        }

        this.OnTalentsFetchComplete = function(data) {
            var old = _this.container.FindChildTraverse("ProgressionTalentsAbilityContainer").Children()
            
            if (old) {
                old.forEach(async (child) => {
                    const containerChild = child.Children()

                    containerChild.forEach(async (moreChild) => {
                        if(moreChild.id == "ProgressionTalentsTalentContainer") {
                            const talentChildren = moreChild.Children()

                            talentChildren.forEach(async (nChild) => {
                                if (nChild.id == "ProgressionTalentsTalentAbilityContainer") {
                                    nChild.RemoveAndDeleteChildren();
                                    await nChild.DeleteAsync(0)
                                }
                            })
                        }
                    });
                });
            }

            const talents = data.talents
            const personalTalents = data.personalTalents
            const playerPrimaryAttribute = data.attribute // this returns the primary attribute of the player

            if(playerPrimaryAttribute != "DOTA_ATTRIBUTE_STRENGTH") {
                _this.branch_Strength.style.backgroundColor = "rgba(0,0,0,1)"
                _this.branch_Strength.style.opacity = "0.25"
            }

            if(playerPrimaryAttribute != "DOTA_ATTRIBUTE_AGILITY") {
                _this.branch_Agility.style.backgroundColor = "rgba(0,0,0,1)"
                _this.branch_Agility.style.opacity = "0.25"
            }

            if(playerPrimaryAttribute != "DOTA_ATTRIBUTE_INTELLECT") {
                _this.branch_Intellect.style.backgroundColor = "rgba(0,0,0,1)"
                _this.branch_Intellect.style.opacity = "0.25"
            }

            _this.branch_Universal.style.backgroundColor = "rgba(0,0,0,0)"
            _this.branch_Universal.style.opacity = "1"

            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("xp_manager_fetch_levels", { 
                unit: lastRememberedHero
            })

            if(talents && talents != "[object Object]") {
                const entries = JSON.parse(talents).body
                let entriesPersonal = null

                if(personalTalents) {
                    entriesPersonal = personalTalents.body

                    const steamID = entriesPersonal.steam // steam id 64
                    const XP = entriesPersonal.experience // the player's total XP
                    const learnedTalents = entriesPersonal.talents // Learned talents
                }
                
                for(const [i,obj] of Object.entries(entries)) {
                    const attribute = obj.attribute // attribute tree the talent belongs to
                    const name = obj.name // ability name
                    const maxLevel = obj.max_level // ability max level
                    const requirement = obj.requirement // array (name=ability name, level=required level of said ability)
                    const isBig = maxLevel == 1 // If the ability only has one level, it's a big talent
                    let currentLevel = 0

                    if(personalTalents && entriesPersonal.talents) {
                        for(const [_,learned] of Object.entries(entriesPersonal.talents)) {
                            if(learned.name == name) {
                                currentLevel = learned.level
                            }
                        }
                    }

                    let elementKeyword = ""

                    if(attribute == "DOTA_ATTRIBUTE_STRENGTH") elementKeyword = "Strength"
                    if(attribute == "DOTA_ATTRIBUTE_AGILITY") elementKeyword = "Agility"
                    if(attribute == "DOTA_ATTRIBUTE_INTELLECT") elementKeyword = "Intellect"
                    if(attribute == "DOTA_ATTRIBUTE_ALL") elementKeyword = "Universal"

                    //step 1:load all talents
                    //step 2:before we populate the UI we must check which talents the player have learned already so we can set levels
                    _this.CreateTalentAbility(_this[`branch_${elementKeyword}_Talent_Container`], name, isBig, i, currentLevel, maxLevel, attribute)
                }
            }
        }

        this.CreateTalentAbility = function(parent, talentName, talentBig, talentNum, talentCurrentLevel, talentMaxLevel, talentType) {
            this[`branch_${talentType}_Talent_${talentNum}_Container`] = $.CreatePanel("Panel", parent, "ProgressionTalentsTalentAbilityContainer")
            this[`branch_${talentType}_Talent_${talentNum}_Level`] = $.CreatePanel("Label", this[`branch_${talentType}_Talent_${talentNum}_Container`], "ProgressionTalentsTalentAbilityLevel")
            
            this[`branch_${talentType}_Talent_${talentNum}`] = $.CreatePanel("DOTAAbilityImage", this[`branch_${talentType}_Talent_${talentNum}_Container`], "ProgressionTalentsTalent")
            
            const talent = this[`branch_${talentType}_Talent_${talentNum}`]
            talent.abilityname = talentName

            if(talentCurrentLevel == 0) {
                talent.style.opacity = "0.1"
            }
            
            if(talentMaxLevel > 0) {
                this[`branch_${talentType}_Talent_${talentNum}_Container`].AddClass("Background")
                this[`branch_${talentType}_Talent_${talentNum}_Level`].text = talentCurrentLevel + "/" + talentMaxLevel
                this[`branch_${talentType}_Talent_${talentNum}_Level`].hittest = false

                talent.style.boxShadow = "0 0 6px rgba(0,0,0,0.5) inset"

                if(talentBig) {
                    talent.style.height = "80px"
                    talent.style.width = "80px"
                }
    
                talent.SetPanelEvent(
                    "onmouseover", 
                    function(){
                        const localizationString = "<b>" + $.Localize("#DOTA_Tooltip_Ability_"+talentName) + "</b><br>" + $.Localize("#DOTA_Tooltip_Ability_"+talentName+"_Description")
                        $.DispatchEvent("DOTAShowTextTooltip", talent, localizationString);
                    }
                )
    
                talent.SetPanelEvent(
                    "onmouseout", 
                    function(){
                        $.DispatchEvent("DOTAHideTextTooltip");
                    }
                )

                talent.SetPanelEvent(
                    "onactivate", 
                    function(){
                        var localID = Players.GetLocalPlayer()
                        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                        GameEvents.SendCustomGameEventToServer("xp_manager_talent_learn", { 
                            unit: lastRememberedHero,
                            talent: talentName,
                            attribute: talentType,
                            talentNum: talentNum
                        })
                    }
                )
            } else {
                talent.style.opacity = "0"
            }

            return this[`branch_${talentType}_Talent_${talentNum}_Container`]
        }

        this.RemoveTalentTree = function () {
            // Find the talent tree and disable it
            var context = $.GetContextPanel()
            var mainHud = context.GetParent().GetParent().GetParent()
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

        this.CreateTalentToggleButton = function() {
            // Make the button for the rune UI
            const mainPanelParent = mainHud.FindChildTraverse("lower_hud")

            // Make the button for the rune UI
            const StatBranch = mainHud.FindChildTraverse("StatBranch")

            const parent = StatBranch.GetParent()

            const old = parent.FindChildTraverse("ProgressionTalentsPlayerButton")
            if(old) {
                old.RemoveAndDeleteChildren()
                old.DeleteAsync(0);
            }

            _this.RemoveTalentTree()
            
            const btn = $.CreatePanel("Label", context, "ProgressionTalentsPlayerButton");
            btn.text = " "
            const icon = $.CreatePanel("Image", btn, "ProgressionTalentsPlayerButtonIcon");
            icon.SetImage("file://{resources}/images/custom_game/hex_icon_rarity_shadow_tier_5_large_selected_psd.png")
            btn.SetParent(parent)

            parent.MoveChildBefore(btn, parent.Children()[1])

            btn.SetPanelEvent(
                "onmouseover", 
                function(){
                  $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#progression_talents_name"));
                }
              )
  
              btn.SetPanelEvent(
                "onmouseout", 
                function(){
                  $.DispatchEvent("DOTAHideTextTooltip");
                }
              )
        
            btn.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    const container = context.FindChildTraverse("ProgressionTalentsContainer")
                    if(container) {
                        if(container.style.visibility == "collapse") {
                            _this.opacity = "1"
                            _this.visibility = "visible"
                            icon.GetParent().AddClass("active")
                        } else if(container.style.visibility == "visible") {
                            _this.opacity = "0"
                            _this.visibility = "collapse"
                            icon.GetParent().RemoveClass("active")
                        }

                        container.style.opacity = _this.opacity
                        container.style.visibility = _this.visibility
                    }
                }
            )
        }

        this.DeleteOldContainer()

        this.container = $.CreatePanel("Panel", context, "ProgressionTalentsContainer")
        this.container.style.visibility = this.visibility
        this.container.style.opacity = this.opacity

        this.abilityContainer = $.CreatePanel("Panel", this.container, "ProgressionTalentsAbilityContainer")

        // Player XP Area
        this.PlayerExperienceContainer = $.CreatePanel("Panel", this.container, "ProgressionTalentsPlayerXPContainer")

        // Player points/whatever area
        this.PlayerPersonalContainer = $.CreatePanel("Panel", this.PlayerExperienceContainer, "ProgressionTalentsPlayerPersonalContainer")
        this.PlayerPersonalTextPlaceholder = $.CreatePanel("Label", this.PlayerPersonalContainer, "ProgressionTalentsPlayerPersonalTextPlaceholder")
        this.PlayerPersonalTextPlaceholder.html = true
        this.PlayerPersonalTextPlaceholder.text = "Current Level: 0 (Unspent Points: 0)"
        
        this.PlayerPersonalResetTalentButton = $.CreatePanel("Label", this.PlayerPersonalContainer, "ProgressionTalentsPlayerPersonalResetTalentButton")
        this.PlayerPersonalResetTalentButton.text = "Reset Talents"

        this.PlayerPersonalResetTalentButton.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", _this.PlayerPersonalResetTalentButton, "Reset all of your talents and refund all points. Can be used once every 5 minutes.");
            }
        )

        this.PlayerPersonalResetTalentButton.SetPanelEvent(
            "onmouseout", 
            function(){
                $.DispatchEvent("DOTAHideTextTooltip");
            }
        )

        this.PlayerPersonalResetTalentButton.SetPanelEvent(
            "onmouseactivate", 
            function(){
                var localID = Players.GetLocalPlayer()
                var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                GameEvents.SendCustomGameEventToServer("xp_manager_talent_reset", { 
                    unit: lastRememberedHero
                })
            }
        )

        // XP Bar
        this.PlayerExperienceContainerInner = $.CreatePanel("Panel", this.PlayerExperienceContainer, "ProgressionTalentsPlayerXPContainerInner")

        this.PlayerExperienceContainer_Background = $.CreatePanel("Panel", this.PlayerExperienceContainerInner, "ProgressionTalentsPlayerXPContainerBackground")
        this.PlayerExperienceContainer_Bar = $.CreatePanel("Panel", this.PlayerExperienceContainer_Background, "ProgressionTalentsPlayerXPContainerBar")

        this.PlayerExperienceContainer_CurrentLevel = $.CreatePanel("Label", this.PlayerExperienceContainer_Background, "ProgressionTalentsPlayerXPContainerCurrentLevel")
        this.PlayerExperienceContainer_CurrentLevel.text = "0"

        this.PlayerExperienceContainer_NextLevel = $.CreatePanel("Label", this.PlayerExperienceContainer_Background, "ProgressionTalentsPlayerXPContainerNextLevel")
        this.PlayerExperienceContainer_NextLevel.text = "0"

        // Strength Branch
        this.branch_Strength = $.CreatePanel("Panel", this.abilityContainer, "ProgressionTalentsStrengthBranchContainer")
        
        this.branch_Strength_Header = $.CreatePanel("Panel", this.branch_Strength, "ProgressionTalentsStrengthBranchContainerHeader")
        this.branch_Strength_Icon = $.CreatePanel("Label", this.branch_Strength_Header, "ProgressionTalentsStrengthBranchContainerIcon")
        this.branch_Strength_Title = $.CreatePanel("Label", this.branch_Strength_Header, "ProgressionTalentsStrengthBranchContainerTitle")
        this.branch_Strength_Title.text = "Strength"

        this.branch_Strength_Talent_Container = $.CreatePanel("Label", this.branch_Strength, "ProgressionTalentsTalentContainer")

        // Intellect Branch
        this.branch_Intellect = $.CreatePanel("Panel", this.abilityContainer, "ProgressionTalentsIntellectBranchContainer")
        
        this.branch_Intellect_Header = $.CreatePanel("Panel", this.branch_Intellect, "ProgressionTalentsIntellectBranchContainerHeader")
        this.branch_Intellect_Icon = $.CreatePanel("Label", this.branch_Intellect_Header, "ProgressionTalentsIntellectBranchContainerIcon")
        this.branch_Intellect_Title = $.CreatePanel("Label", this.branch_Intellect_Header, "ProgressionTalentsIntellectBranchContainerTitle")
        this.branch_Intellect_Title.text = "Intellect"

        this.branch_Intellect_Talent_Container = $.CreatePanel("Label", this.branch_Intellect, "ProgressionTalentsTalentContainer")

        // Agility Branch
        this.branch_Agility = $.CreatePanel("Panel", this.abilityContainer, "ProgressionTalentsAgilityBranchContainer")
        
        this.branch_Agility_Header = $.CreatePanel("Panel", this.branch_Agility, "ProgressionTalentsAgilityBranchContainerHeader")
        this.branch_Agility_Icon = $.CreatePanel("Label", this.branch_Agility_Header, "ProgressionTalentsAgilityBranchContainerIcon")
        this.branch_Agility_Title = $.CreatePanel("Label", this.branch_Agility_Header, "ProgressionTalentsAgilityBranchContainerTitle")
        this.branch_Agility_Title.text = "Agility"

        this.branch_Agility_Talent_Container = $.CreatePanel("Label", this.branch_Agility, "ProgressionTalentsTalentContainer")

        // Universal Branch
        this.branch_Universal = $.CreatePanel("Panel", this.abilityContainer, "ProgressionTalentsUniversalBranchContainer")
        
        this.branch_Universal_Header = $.CreatePanel("Panel", this.branch_Universal, "ProgressionTalentsUniversalBranchContainerHeader")
        this.branch_Universal_Icon = $.CreatePanel("Label", this.branch_Universal_Header, "ProgressionTalentsUniversalBranchContainerIcon")
        this.branch_Universal_Title = $.CreatePanel("Label", this.branch_Universal_Header, "ProgressionTalentsUniversalBranchContainerTitle")
        this.branch_Universal_Title.text = "Universal"

        this.branch_Universal_Talent_Container = $.CreatePanel("Label", this.branch_Universal, "ProgressionTalentsTalentContainer")

        GameEvents.Subscribe("xp_manager_fetch_talents_complete", this.OnTalentsFetchComplete);
        GameEvents.Subscribe("xp_manager_talent_learn_complete", this.OnTalentLearnedComplete);
        GameEvents.Subscribe("xp_manager_fetch_levels_complete", this.OnTalentLevelsComplete);
        GameEvents.Subscribe("xp_manager_reset_complete", this.OnTalentResetComplete);

        this.CreateTalentToggleButton()
    }

    return ProgressionTalents;
}());

var ui = new ProgressionTalents($.GetContextPanel());
