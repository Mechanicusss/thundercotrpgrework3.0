var ShortcutMenu = (function() {
    function ShortcutMenu(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        var centerBlockHud = mainHud.FindChildTraverse("center_block")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.visibility = "visible"
        this.opacity = "1"

        this.QUEST_MARKERS = []

        this.DeleteOldContainer = async function() {
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "ShortcutMenuContainer") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            // hide minimap
            let minimap = mainHud.FindChildTraverse("minimap_container")
            minimap.style.visibility = "collapse"
            minimap.style.opacity = "0"

            _this.ShortcutMenuContainer = $.CreatePanel("Panel", context, "ShortcutMenuContainer")
            _this.ShortcutMenuContainer.style.visibility = _this.visibility
            _this.ShortcutMenuContainer.style.opacity = _this.opacity

            // hide facets/innate
            let statBranch = mainHud.FindChildTraverse("AbilitiesAndStatBranch")
            let leftRightFlow = statBranch.FindChildrenWithClassTraverse("LeftRightFlow")[0]
            let innate = leftRightFlow.FindChildrenWithClassTraverse("RootInnateDisplay")[0]
            innate.style.visibility = "collapse"
            innate.style.opacity = "0"

            // Factions
            /*
            _this.ShortcutMenuFactions = $.CreatePanel("Panel", _this.ShortcutMenuContainer, "ShortcutMenuFactions")
            _this.ShortcutMenuFactionsItem = $.CreatePanel("Label", _this.ShortcutMenuFactions, "ShortcutMenuFactionsItem")

            let FactionsButton = _this.ShortcutMenuFactions
            FactionsButton.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", FactionsButton, "Factions");
                    Game.EmitSound("TCOT_Option_Click")
                }
            )
    
            FactionsButton.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                    
                }
            )

            FactionsButton.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    let openFactionHud = mainHud.FindChildTraverse("FactionManagerContainer")
                    if(openFactionHud.style.visibility == "visible") {
                        openFactionHud.style.visibility = "collapse"
                        openFactionHud.style.opacity = "0"
                    } else {
                        let ui = mainHud.FindChildTraverse("FactionManagerSelectionContainer")
                        if(ui.style.visibility != "visible") {
                            ui.style.visibility = "visible"
                            ui.style.opacity = "1"
                            Game.EmitSound("TCOT_Window_Open")
                        } else {
                            ui.style.visibility = "collapse"
                            ui.style.opacity = "0"
                            Game.EmitSound("TCOT_Window_Close")
                        }
                    }
                    
                }
            )*/

            // Quest Journal
            _this.ShortcutMenuQuestJournal = $.CreatePanel("Panel", _this.ShortcutMenuContainer, "ShortcutMenuQuestJournal")
            _this.ShortcutMenuQuestJournalItem = $.CreatePanel("Label", _this.ShortcutMenuQuestJournal, "ShortcutMenuQuestJournalItem")

            let questJournalButton = _this.ShortcutMenuQuestJournal
            questJournalButton.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", questJournalButton, "Quest Journal");
                    Game.EmitSound("TCOT_Option_Click")
                }
            )
    
            questJournalButton.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                    
                }
            )

            questJournalButton.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    let questJournalUI = mainHud.FindChildTraverse("QuestManagerJournalContainer")
                    if(questJournalUI.style.visibility != "visible") {
                        questJournalUI.style.visibility = "visible"
                        questJournalUI.style.opacity = "1"
                        Game.EmitSound("TCOT_Window_Open")
                    } else {
                        questJournalUI.style.visibility = "collapse"
                        questJournalUI.style.opacity = "0"
                        Game.EmitSound("TCOT_Window_Close")
                    }
                }
            )

            // DPS Meter
            _this.ShortcutMenuDPSMeter = $.CreatePanel("Panel", _this.ShortcutMenuContainer, "ShortcutMenuDPSMeter")
            _this.ShortcutMenuDPSMeterItem = $.CreatePanel("Label", _this.ShortcutMenuDPSMeter, "ShortcutMenuDPSMeterItem")
            _this.ShortcutMenuDPSMeter.toggled = 0

            let DPSMeterButton = _this.ShortcutMenuDPSMeter
            DPSMeterButton.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", DPSMeterButton, "Damage Meter");
                    Game.EmitSound("TCOT_Option_Click")
                }
            )
    
            DPSMeterButton.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                    
                }
            )

            DPSMeterButton.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    let dpsMeterHud = mainHud.FindChildTraverse("DpsManagerContainer")
                    if(dpsMeterHud.style.visibility != "visible") {
                        dpsMeterHud.style.visibility = "visible"
                        dpsMeterHud.style.opacity = "1"
                        _this.ShortcutMenuDPSMeter.toggled = 1
                    } else {
                        dpsMeterHud.style.visibility = "collapse"
                        dpsMeterHud.style.opacity = "0"
                        _this.ShortcutMenuDPSMeter.toggled = 0
                    }
                }
            )

            // Account Stash
            
            _this.ShortcutMenuAccountStash = $.CreatePanel("Panel", _this.ShortcutMenuContainer, "ShortcutMenuAccountStash")
            _this.ShortcutMenuAccountStashItem = $.CreatePanel("Label", _this.ShortcutMenuAccountStash, "ShortcutMenuAccountStashItem")

            let AccountStashButton = _this.ShortcutMenuAccountStash
            AccountStashButton.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", AccountStashButton, "Account Stash");
                    Game.EmitSound("TCOT_Option_Click")
                }
            )
    
            AccountStashButton.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                    
                }
            )

            AccountStashButton.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    Game.EmitSound("TCOT_Option_Click")
                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                    GameEvents.SendCustomGameEventToServer("save_manager_toggle_ui", { 
                        unit: lastRememberedHero, 
                    })
                }
            )
        }

        this.DeleteOldShopContainer = async function() {
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "CustomShopMenu") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            _this.CustomShopMenu = $.CreatePanel("Panel", context, "CustomShopMenu")

            _this.CustomShopMenuRows = $.CreatePanel("Panel", _this.CustomShopMenu, "CustomShopMenuRows")

            // Legendary
            _this.CustomShopMenuRow_Legendary = $.CreatePanel("Panel", _this.CustomShopMenuRows, "CustomShopMenuRow")
            _this.CustomShopMenuRow_Legendary.AddClass("legendary")
            _this.CustomShopMenuRow_LegendaryImage = $.CreatePanel("Image", _this.CustomShopMenuRow_Legendary, "CustomShopMenuRowImage")
            _this.CustomShopMenuRow_LegendaryImage.AddClass("legendary")
            _this.CustomShopMenuRow_LegendaryText = $.CreatePanel("Label", _this.CustomShopMenuRow_Legendary, "CustomShopMenuRowText")
            _this.CustomShopMenuRow_LegendaryText.text = "0"
            _this.CustomShopMenuRow_LegendaryText.style.color = "orange"
            
            let rowLegendary = _this.CustomShopMenuRow_Legendary
            rowLegendary.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", rowLegendary, "Your current amount of <b color='orange'>[Legendary]</b> essence, used to craft equipment of <b color='orange'>[Legendary]</b> quality.");
                }
            )
    
            rowLegendary.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                }
            )

            // Mythical
            _this.CustomShopMenuRow_Mythical = $.CreatePanel("Panel", _this.CustomShopMenuRows, "CustomShopMenuRow")
            _this.CustomShopMenuRow_Mythical.AddClass("mythical")
            _this.CustomShopMenuRow_MythicalImage = $.CreatePanel("Image", _this.CustomShopMenuRow_Mythical, "CustomShopMenuRowImage")
            _this.CustomShopMenuRow_MythicalImage.AddClass("mythical")
            _this.CustomShopMenuRow_MythicalText = $.CreatePanel("Label", _this.CustomShopMenuRow_Mythical, "CustomShopMenuRowText")
            _this.CustomShopMenuRow_MythicalText.text = "0"
            _this.CustomShopMenuRow_MythicalText.style.color = "MediumOrchid"

            let rowMythical = _this.CustomShopMenuRow_Mythical
            rowMythical.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", rowMythical, "Your current amount of <b color='MediumOrchid'>[Mythical]</b> essence, used to craft equipment of <b color='MediumOrchid'>[Mythical]</b> quality.");
                }
            )
    
            rowMythical.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                }
            )

            // Rare
            _this.CustomShopMenuRow_Rare = $.CreatePanel("Panel", _this.CustomShopMenuRows, "CustomShopMenuRow")
            _this.CustomShopMenuRow_Rare.AddClass("rare")
            _this.CustomShopMenuRow_RareImage = $.CreatePanel("Image", _this.CustomShopMenuRow_Rare, "CustomShopMenuRowImage")
            _this.CustomShopMenuRow_RareImage.AddClass("rare")
            _this.CustomShopMenuRow_RareText = $.CreatePanel("Label", _this.CustomShopMenuRow_Rare, "CustomShopMenuRowText")
            _this.CustomShopMenuRow_RareText.text = "0"
            _this.CustomShopMenuRow_RareText.style.color = "DeepSkyBlue"

            let rowRare = _this.CustomShopMenuRow_Rare
            rowRare.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", rowRare, "Your current amount of <b color='DeepSkyBlue'>[Rare]</b> essence, used to craft equipment of <b color='DeepSkyBlue'>[Rare]</b> quality.");
                }
            )
    
            rowRare.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                }
            )

            // Common
            _this.CustomShopMenuRow_Common = $.CreatePanel("Panel", _this.CustomShopMenuRows, "CustomShopMenuRow")
            _this.CustomShopMenuRow_Common.AddClass("common")
            _this.CustomShopMenuRow_CommonImage = $.CreatePanel("Image", _this.CustomShopMenuRow_Common, "CustomShopMenuRowImage")
            _this.CustomShopMenuRow_CommonImage.AddClass("common")
            _this.CustomShopMenuRow_CommonText = $.CreatePanel("Label", _this.CustomShopMenuRow_Common, "CustomShopMenuRowText")
            _this.CustomShopMenuRow_CommonText.text = "0"
            _this.CustomShopMenuRow_CommonText.style.color = "Silver"

            let rowCommon = _this.CustomShopMenuRow_Common
            rowCommon.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", rowCommon, "Your current amount of <b color='silver'>[Common]</b> essence, used to craft equipment of <b color='silver'>[Common]</b> quality.");
                }
            )
    
            rowCommon.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                }
            )

            // Gold
            _this.CustomShopMenuGoldContainer = $.CreatePanel("Panel", _this.CustomShopMenu, "CustomShopMenuGoldContainer")
            _this.CustomShopMenuGoldImage = $.CreatePanel("Panel", _this.CustomShopMenuGoldContainer, "CustomShopMenuGoldImage")
            _this.CustomShopMenuGoldAmount = $.CreatePanel("Label", _this.CustomShopMenuGoldContainer, "CustomShopMenuGoldAmount")

            var localID = Players.GetLocalPlayer()

            let gold = Players.GetGold(localID)

            _this.CustomShopMenuGoldAmount.text = _this.nFormatter(gold, 1)

            let goldui = _this.CustomShopMenuGoldContainer
            goldui.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", goldui, "Your current amount of gold.");
                }
            )
    
            goldui.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                }
            )
        }

        this.onModifyEssenceList = function(data) {
            let essenceCommon = data.essenceCommon
            let essenceRare = data.essenceRare 
            let essenceMythical = data.essenceMythical 
            let essenceLegendary = data.essenceLegendary

            _this.CustomShopMenuRow_LegendaryText.text = essenceLegendary || 0
            _this.CustomShopMenuRow_MythicalText.text = essenceMythical || 0
            _this.CustomShopMenuRow_RareText.text = essenceRare || 0
            _this.CustomShopMenuRow_CommonText.text = essenceCommon || 0
        }
    
        this.onModifyGoldBank = function(_, _, res) {
            if (!res) {
                return
            }
    
            if(res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) return;

            var localID = Players.GetLocalPlayer()

            let gold = Players.GetGold(localID)

            _this.CustomShopMenuGoldAmount.text = _this.nFormatter(res.amount+gold, 1)
    
            return
        }

        this.nFormatter = function(num, digits) {
            const lookup = [
              { value: 1, symbol: "" },
              //{ value: 1e3, symbol: "k" },
              { value: 1e6, symbol: "M" },
              { value: 1e9, symbol: "B" },
              { value: 1e12, symbol: "T" },
              { value: 1e15, symbol: "P" },
              { value: 1e18, symbol: "E" }
            ];
            const rx = /\.0+$|(\.[0-9]*[1-9])0+$/;
            var item = lookup.slice().reverse().find(function(item) {
              return num >= item.value;
            });
            return item ? (num / item.value).toFixed(digits).replace(rx, "$1") + item.symbol : "0";
        }

        this.DeleteOldContainer()
        this.DeleteOldShopContainer()

        CustomNetTables.SubscribeNetTableListener("modify_gold_bank", this.onModifyGoldBank);
        GameEvents.Subscribe("modify_essence_list", this.onModifyEssenceList);
    }

    return ShortcutMenu;
}());

var ui = new ShortcutMenu($.GetContextPanel());
