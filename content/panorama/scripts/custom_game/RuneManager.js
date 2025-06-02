var RuneManager = (function() {
    function RuneManager(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        var shopHud = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("shop")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        var mainShop = shopHud.FindChildTraverse("GridMainShop");
        var shopHeaders = mainShop.FindChildTraverse("GridShopHeaders").FindChildTraverse("GridMainTabs");
        var basicTab = shopHeaders.FindChildTraverse("GridBasicsTab");
        var upgradesTab = shopHeaders.FindChildTraverse("GridUpgradesTab");
        var neutralsTab = shopHeaders.FindChildTraverse("GridNeutralsTab");
        var upgradeContent = mainShop.FindChildTraverse("GridUpgradeItems");

        // Important variables
        this.EQUIPMENT_CURRENT_SELECTION = undefined;
        this.EQUIPMENT_TEMP = [];

        this.RUNE_INVENTORY_CURRENT_SELECTION = undefined;
        this.RUNE_INVENTORY_TEMP = []; // Array to store individual rune rows in for changing class names to reflect active state etc.

        this.PLAYER_RUNES = [];
        this.PLAYER_RUNE_INVENTORY = [];
        this.PLAYER_STEAM_ID = [];

        this.visibility = "collapse";
        this.opacity = "0";

        let MAX_RUNES_PER_EQUIPMENT = 6;

        this.OnRuneSend = function(data) {
            // you dont have to populate sockets in UI
            // if they already fetch runes when loaded!
            //todo: remove rune from rune inventory when it's added,
            // todo: why doesnt the reload thing work initially?
            _this.PLAYER_RUNES = data.runes
            _this.PLAYER_RUNE_INVENTORY = data.runeInventory

            if(data.steamID) {
                _this.PLAYER_STEAM_ID = data.steamID // contains entindex of items
            }

            _this.DeleteOldContainer()
        }

        this.DeleteOldContainer = async function() {
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "RuneManagerContainer") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            _this.CreateRuneManagerContainer()
        }

        this.OnRuneDataGet = function(data) {
            _this.PLAYER_RUNES = data.runes
            _this.PLAYER_RUNE_INVENTORY = data.runeInventory
        }

        this.RequestRuneData = function() {
            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("rune_manager_send_data", { unit: lastRememberedHero })
        }

        this.CreateRuneManagerContainer = function() {
            _this.RequestRuneData()

            // Reset some variables
            
            _this.EQUIPMENT_TEMP = [];
            _this.RUNE_INVENTORY_TEMP = [];
            _this.RUNE_INVENTORY_CURRENT_SELECTION = undefined;

            const runeManagerContainer = $.CreatePanel("Panel", context, "RuneManagerContainer");
            runeManagerContainer.style.opacity = _this.opacity
            runeManagerContainer.style.visibility = _this.visibility

            const runeManagerContainerHeader = $.CreatePanel("Label", runeManagerContainer, "runeManagerContainerHeader");
            runeManagerContainerHeader.text = $.Localize("#rune_gem_manager_title")

            const runeManagerContainerBody = $.CreatePanel("Panel", runeManagerContainer, "runeManagerContainerBody");
            runeManagerContainerBody.BLoadLayoutSnippet("RuneManagerContainer")

            _this.CreateEquipmentContainer(runeManagerContainerBody)
            _this.CreateRuneInventoryContainer(runeManagerContainerBody)
        }

        this.CreateEquipmentContainer = function(parent) {
            const equipmentContainerParent = $.CreatePanel("Panel", parent, "EquipmentContainerParent");

            // Go through the players inventory
            var _playerID = Players.GetLocalPlayer()
            var _playerEntIndx = Players.GetPlayerHeroEntityIndex(_playerID)
            var steam = _this.PLAYER_STEAM_ID

            let runes = []
            if(steam > -1 && steam != null && steam != undefined) {
                _this.EQUIPMENT_CURRENT_SELECTION = steam
                if(_this.PLAYER_RUNES != undefined) {
                    if(runes.length <= MAX_RUNES_PER_EQUIPMENT) {
                        for(const [z, runeName] of Object.entries(_this.PLAYER_RUNES)) {
                            runes.push(runeName)
                        }
                    }
                }

                _this.CreateEquipmentItem(equipmentContainerParent, steam, runes)
            }

            /*
            for(let i = 0; i <= 5; i++) {
                var _playerID = Players.GetLocalPlayer()
                var _playerEntIndx = Players.GetPlayerHeroEntityIndex(_playerID)

                let runes = []
                const itemIndex = Entities.GetItemInSlot(_playerEntIndx, i)

                if(itemIndex != -1) {
                    if(this.PLAYER_RUNES != undefined) {
                        for(const [key, value] of Object.entries(this.PLAYER_RUNES)) {
                            if(itemIndex == key && runes.length <= MAX_RUNES_PER_EQUIPMENT) {
                                for(const [z, runeName] of Object.entries(value)) {
                                    runes.push(runeName)
                                }
                            }
                        }
                    }

                    CreateEquipmentItem(equipmentContainerParent, itemIndex, runes)
                }
            }*/
        }

        this.CreateRuneInventoryContainer = function(parent) {
            // Rune Inventory
            const runeInventoryParentContainer = $.CreatePanel("Panel", parent, "runeInventoryParentContainer");
            const runeInventoryContainer = $.CreatePanel("Panel", runeInventoryParentContainer, "RuneInventoryContainer");

            let runes = []
            if(_this.PLAYER_RUNE_INVENTORY != undefined && _this.PLAYER_RUNE_INVENTORY != null) {
                for(const [key, value] of Object.entries(_this.PLAYER_RUNE_INVENTORY)) {
                    runes.push({
                        uId: value.uId,
                        name: value.name,
                        isLegendary: value.isLegendary
                    })
                }
            }

            if(runes.length > 0) {
                _this.UpdateRuneInventory(runeInventoryContainer, runes)
            } else {
                _this.UpdateRuneInventory(runeInventoryContainer, [
                    {
                        uId: -1,
                        name: "no_runes_available",
                        isLegendary: false,
                    }
                ])
            }

            _this.CreateButtons(runeInventoryParentContainer)
        }

        this.CreateButtons = function(parent) {
            const runeInventoryButtonContainer = $.CreatePanel("Panel", parent, "runeInventoryButtonContainer");

            // Add rune
            // This will add the currently selected rune from the rune inventory to the currently selected equipment piece
            const runeInventoryButtonAdd = $.CreatePanel("TextButton", runeInventoryButtonContainer, "runeInventoryButtonAdd");
            runeInventoryButtonAdd.text = $.Localize("#rune_apply_gem")
            runeInventoryButtonAdd.AddClass("runeInventoryButtonAdd")

            runeInventoryButtonAdd.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    if(_this.RUNE_INVENTORY_CURRENT_SELECTION == undefined) return
                    if(_this.EQUIPMENT_CURRENT_SELECTION == undefined) return

                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                    GameEvents.SendCustomGameEventToServer("rune_manager_equipment_add_rune", { 
                        unit: lastRememberedHero, 
                        item: _this.EQUIPMENT_CURRENT_SELECTION,
                        rune: _this.RUNE_INVENTORY_CURRENT_SELECTION 
                    })

                    _this.ClearRuneInventorySelection()
                }
            )

            // Remove rune
            // This is does something different. This will remove a rune from the currently selected
            // equipment piece and add it to the rune inventory. It removes rune from top to bottom, you can't
            // select a specific rune to remove.
            /*
            const runeInventoryButtonRemove = $.CreatePanel("TextButton", runeInventoryButtonContainer, "runeInventoryButtonRemove");
            runeInventoryButtonRemove.text = $.Localize("#rune_extract_gem")
            runeInventoryButtonRemove.AddClass("runeInventoryButtonRemove")

            runeInventoryButtonRemove.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    if(_this.EQUIPMENT_CURRENT_SELECTION == undefined) return

                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                    GameEvents.SendCustomGameEventToServer("rune_manager_equipment_remove_rune", { 
                        unit: lastRememberedHero, 
                        item: _this.EQUIPMENT_CURRENT_SELECTION,
                    })

                    _this.ClearRuneInventorySelection()
                }
            )*/
        }

        this.ClearRuneInventorySelection = function() {
            for(const o of _this.RUNE_INVENTORY_TEMP) {
                // Remove all other selected classes
                if(o) {
                    o.RemoveClass("selected")
                }
            }

            _this.RUNE_INVENTORY_CURRENT_SELECTION = undefined 
        }

        this.ClearEquipmentSelection = function() {
            for(const o of _this.EQUIPMENT_TEMP) {
                // Remove all other selected classes
                if(o) {
                    o.RemoveClass("selected")
                }
            }

            _this.EQUIPMENT_CURRENT_SELECTION = undefined 
        }

        this.UpdateRuneInventory = function(parent, runes) {
            for(const rune of runes) {
                // Single runes
                const inventoryRune = $.CreatePanel("Panel", parent, "inventoryRune");
                if(rune.uId == -1) {
                    const emptyLabel = $.CreatePanel("Label", inventoryRune, "inventoryRuneEmptyLabel");
                    emptyLabel.text = $.Localize("#rune_no_runes_found")
                    emptyLabel.GetParent().AddClass("NoBorder")
                    return
                }

                // Class mojo
                inventoryRune.RemoveClass("selected")

                // Setup events
                inventoryRune.SetPanelEvent(
                    "onmouseactivate", 
                    function(){
                        _this.ClearRuneInventorySelection()

                        inventoryRune.AddClass("selected")

                        _this.RUNE_INVENTORY_CURRENT_SELECTION = rune
                    }
                )

                // Children
                const inventoryRuneImageContainer = $.CreatePanel("Panel", inventoryRune, "inventoryRuneImageContainer");
                const inventoryRuneImage = $.CreatePanel("DOTAItemImage", inventoryRuneImageContainer, "inventoryRuneImage");
                inventoryRuneImage.itemname = rune.name

                const inventoryRuneDescContainer = $.CreatePanel("Panel", inventoryRune, "inventoryRuneDescContainer");
                const inventoryRuneName = $.CreatePanel("Label", inventoryRuneDescContainer, "inventoryRuneName");
                inventoryRuneName.html = true;
                inventoryRuneName.text = $.Localize("#DOTA_Tooltip_Ability_"+rune.name)


                const inventoryRuneDesc = $.CreatePanel("Label", inventoryRuneDescContainer, "inventoryRuneDesc");
                inventoryRuneDesc.html = true
                inventoryRuneDesc.text = $.Localize("#DOTA_Tooltip_Ability_"+rune.name+"_Description")

                // Sell button
                const inventoryRuneSell = $.CreatePanel("Image", inventoryRune, "inventoryRuneSell");
                inventoryRuneSell.SetImage("file://{resources}/images/custom_game/cancel_search_png.png")
                inventoryRuneSell.uId = rune.uId

                inventoryRuneSell.SetPanelEvent(
                  "onmouseover", 
                  function(){
                    $.DispatchEvent("DOTAShowTextTooltip", inventoryRuneSell, $.Localize("#rune_sell_gem"));
                  }
                )

                inventoryRuneSell.SetPanelEvent(
                  "onmouseout", 
                  function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                  }
                )

                inventoryRuneSell.SetPanelEvent(
                    "onmouseactivate", 
                    function(){
                        var localID = Players.GetLocalPlayer()
                        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                        GameEvents.SendCustomGameEventToServer("rune_manager_equipment_delete_rune", { 
                            unit: lastRememberedHero, 
                            rune: inventoryRuneSell.uId,
                        })

                        _this.ClearRuneInventorySelection()
                    }
                )

                _this.RUNE_INVENTORY_TEMP.push(inventoryRune)
            }
        }

        this.CreateEquipmentItem = function(parent, itemIndex, runes) {
            const equipmentContainer = $.CreatePanel("Panel", parent, "EquipmentContainer");

            equipmentContainer.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    _this.ClearEquipmentSelection()

                    equipmentContainer.AddClass("selected")

                    _this.EQUIPMENT_CURRENT_SELECTION = itemIndex // this MUST contain entindex of the item
                }
            )

            if(_this.EQUIPMENT_CURRENT_SELECTION != undefined && itemIndex == _this.EQUIPMENT_CURRENT_SELECTION) {
                equipmentContainer.AddClass("selected")
                _this.EQUIPMENT_TEMP.push(equipmentContainer)
            }

            // Item Image
            //const itemName = Abilities.GetAbilityName(itemIndex)
            //const itemImage = $.CreatePanel("DOTAItemImage", equipmentContainer, "ItemImage");
            //itemImage.itemname = itemName

            // Hero Header Container
            const heroHeaderContainer = $.CreatePanel("Panel", equipmentContainer, "HeroHeaderContainer");
            const heroImage = $.CreatePanel("DOTAHeroImage", heroHeaderContainer, "HeroImage");
            const heroLabel = $.CreatePanel("Label", heroHeaderContainer, "HeroLabel");

            const localHero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());
            const heroName = Entities.GetUnitName(localHero);

            heroImage.heroname = heroName
            heroLabel.text = $.Localize("#" + heroName)

            // Rune Container
            const itemRuneContainer = $.CreatePanel("Panel", equipmentContainer, "ItemRuneContainer");

            if(runes.length < MAX_RUNES_PER_EQUIPMENT) {
                let iSockets = MAX_RUNES_PER_EQUIPMENT - runes.length
                //if(runes.length == 1) iSockets = 1
                //if(runes.length == 0) iSockets = 2

                // Display empty sockets
                for(i = 0; i < iSockets; i++) {
                    // Single runes
                    const itemSocket = $.CreatePanel("Panel", itemRuneContainer, "itemRune");

                    const itemSocketImageContainer = $.CreatePanel("Panel", itemSocket, "itemRuneImageContainer");
                    const itemSocketImage = $.CreatePanel("Image", itemSocketImageContainer, "itemRuneImage");
                    itemSocketImage.SetImage("file://{resources}/images/custom_game/settings_button_add_psd_5801fb7d.png")

                    const itemSocketDescContainer = $.CreatePanel("Panel", itemSocket, "itemRuneDescContainer");
                    const itemSocketName = $.CreatePanel("Label", itemSocketDescContainer, "itemRuneName");
                    itemSocketName.text = $.Localize("#rune_empty_socket")
                    itemSocketName.AddClass("emptySocket")
                }
            }

            for(const rune of runes) {
                // Single runes
                const itemRune = $.CreatePanel("Panel", itemRuneContainer, "itemRune");

                const itemRuneImageContainer = $.CreatePanel("Panel", itemRune, "itemRuneImageContainer");
                const itemRuneImage = $.CreatePanel("DOTAItemImage", itemRuneImageContainer, "itemRuneImage");
                itemRuneImage.itemname = rune.name

                const itemRuneDescContainer = $.CreatePanel("Panel", itemRune, "itemRuneDescContainer");
                const itemRuneName = $.CreatePanel("Label", itemRuneDescContainer, "itemRuneName");
                itemRuneName.html = true;
                itemRuneName.text = $.Localize("#DOTA_Tooltip_Ability_"+rune.name)
                //const itemRuneDesc = $.CreatePanel("Label", itemRuneDescContainer, "itemRuneDesc");
                //itemRuneDesc.text = $.Localize("#DOTA_Tooltip_Ability_"+rune.name+"_Description")

                const itemRuneRemove = $.CreatePanel("Image", itemRuneDescContainer, "itemRuneRemove");
                itemRuneRemove.uId = rune.uId
                itemRuneRemove.SetImage("file://{resources}/images/custom_game/cancel_search_png.png")

                itemRuneRemove.SetPanelEvent(
                  "onmouseover", 
                  function(){
                    $.DispatchEvent("DOTAShowTextTooltip", itemRuneRemove, $.Localize("#rune_extract_gem"));
                  }
                )

                itemRuneRemove.SetPanelEvent(
                  "onmouseout", 
                  function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                  }
                )

                itemRuneRemove.SetPanelEvent(
                    "onmouseactivate", 
                    function(){
                        var localID = Players.GetLocalPlayer()
                        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                        GameEvents.SendCustomGameEventToServer("rune_manager_equipment_remove_rune", { 
                            unit: lastRememberedHero, 
                            rune: itemRuneRemove.uId,
                        })

                        _this.ClearRuneInventorySelection()
                    }
                )
            }
            
            _this.EQUIPMENT_TEMP.push(equipmentContainer)
        }

        this.CreateRuneInventoryButton = function() {
            // Make the button for the rune UI
            var inventory = mainHud.FindChildTraverse("center_block")
            const old = inventory.FindChildTraverse("runeManagerToggleButton")
            if(old) {
                old.RemoveAndDeleteChildren()
                old.DeleteAsync(0)
            }

            const btn = $.CreatePanel("Label", context, "runeManagerToggleButton");
            btn.text = " "
            const icon = $.CreatePanel("Image", btn, "runeManagerToggleButtonIcon");
            icon.SetImage("file://{resources}/images/custom_game/gem-solid.png")
            btn.SetParent(inventory)
            //Particles.CreateParticle("particles/ui/hud/levelupburst.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, 0)

            btn.SetPanelEvent(
              "onmouseover", 
              function(){
                $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#rune_button_info"));
                icon.SetImage("file://{resources}/images/custom_game/gem-solid-hover.png")
              }
            )

            btn.SetPanelEvent(
              "onmouseout", 
              function(){
                $.DispatchEvent("DOTAHideTextTooltip");
                icon.SetImage("file://{resources}/images/custom_game/gem-solid.png")
              }
            )

            btn.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)
                    
                    GameEvents.SendCustomGameEventToServer("rune_manager_equipment_reload_rune", { 
                        unit: lastRememberedHero, 
                    })

                    const container = context.FindChildTraverse("RuneManagerContainer")
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

        GameEvents.Subscribe("rune_manager_rune_send", this.OnRuneSend);
        GameEvents.Subscribe("rune_manager_get_data", this.OnRuneDataGet);

        this.CreateRuneInventoryButton()
        this.CreateRuneManagerContainer()
    }

    return RuneManager;
}());

var ui = new RuneManager($.GetContextPanel());
