var SaveManager = (function() {
    function SaveManager(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        let parentHud = mainHud.FindChildTraverse("AbilitiesAndStatBranch")
        let lowerHud = mainHud.FindChildTraverse("lower_hud")
        let abilitiesHud = mainHud.FindChildTraverse("abilities")
        let centerBlockHud = mainHud.FindChildTraverse("center_block")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.SELECTED = "none"

        this.DeleteOldContainer = async function() {
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "SaveManagerContainer") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }
        }

        this.CreateItem = function(data) {
            let heroName = data.hero 
            let level = data.level 
            let difficulty = data.difficulty

            let SaveManagerContainerListItem = $.CreatePanel("Panel", _this.SaveManagerContainerList, "SaveManagerContainerListItem")
            SaveManagerContainerListItem._id = data._id
            
            // Hero name
            let SaveManagerContainerListNameContainer = $.CreatePanel("Panel", SaveManagerContainerListItem, "SaveManagerContainerListNameContainer")
            let SaveManagerContainerListName = $.CreatePanel("Label", SaveManagerContainerListNameContainer, "SaveManagerContainerListName")
            SaveManagerContainerListName.text = $.Localize("#"+heroName)
            let SaveManagerContainerListLevel = $.CreatePanel("Label", SaveManagerContainerListNameContainer, "SaveManagerContainerListLevel")
            SaveManagerContainerListLevel.text = " " + level

            // Hero image
            let SaveManagerContainerListHero = $.CreatePanel("DOTAHeroImage", SaveManagerContainerListItem, "SaveManagerContainerListHero")
            SaveManagerContainerListHero.heroname = heroName

            // Difficulty image
            let SaveManagerContainerListDifficulty = $.CreatePanel("Label", SaveManagerContainerListItem, "SaveManagerContainerListDifficulty")
            let difficultyTooltip = ""
            switch(difficulty) {
                case 1:
                    SaveManagerContainerListDifficulty.style.backgroundImage = "url('file://{images}/custom_game/difficulty_casual.png')"
                    difficultyTooltip = "Casual"
                    break;
                case 2:
                    SaveManagerContainerListDifficulty.style.backgroundImage = "url('file://{images}/custom_game/difficulty_hard.png')"
                    difficultyTooltip = "Hard"
                    break;
                case 3:
                    SaveManagerContainerListDifficulty.style.backgroundImage = "url('file://{images}/custom_game/difficulty_insane.png')"
                    difficultyTooltip = "Insane"
                    break;
            }

            SaveManagerContainerListDifficulty.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", SaveManagerContainerListDifficulty, difficultyTooltip);
                    
                }
            )
    
            SaveManagerContainerListDifficulty.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip", SaveManagerContainerListDifficulty);
                }
            )
            
            // Abilities
            let SaveManagerContainerListAbilityContainer = $.CreatePanel("Panel", SaveManagerContainerListItem, "SaveManagerContainerListAbilityContainer")
            for(const [_,name] of Object.entries(data.abilities)) {
                let SaveManagerContainerListAbilityContainerItem
                if(typeof(name) == "object") {
                    SaveManagerContainerListAbilityContainerItem = $.CreatePanel("DOTAAbilityImage", SaveManagerContainerListAbilityContainer, "SaveManagerContainerListAbilityContainerItem")
                    SaveManagerContainerListAbilityContainerItem.abilityname = name.name
                } else {
                    SaveManagerContainerListAbilityContainerItem = $.CreatePanel("DOTAAbilityImage", SaveManagerContainerListAbilityContainer, "SaveManagerContainerListAbilityContainerItem")
                    SaveManagerContainerListAbilityContainerItem.abilityname = name
                }

                SaveManagerContainerListAbilityContainerItem.SetPanelEvent("onmouseover", function () {
                    $.DispatchEvent("DOTAShowAbilityTooltip", SaveManagerContainerListAbilityContainerItem, SaveManagerContainerListAbilityContainerItem.abilityname);
                });
        
                SaveManagerContainerListAbilityContainerItem.SetPanelEvent("onmouseout", function () {
                    $.DispatchEvent("DOTAHideAbilityTooltip");
                    $.DispatchEvent("DOTAHideTextTooltip");
                });
            }

            // Inventory
            let SaveManagerContainerListItemContainer = $.CreatePanel("Panel", SaveManagerContainerListItem, "SaveManagerContainerListItemContainer")
            for(const [_,invObj] of Object.entries(data.inventory)) {
                let name = invObj["name"]
                let SaveManagerContainerListItemContainerItem = $.CreatePanel("DOTAItemImage", SaveManagerContainerListItemContainer, "SaveManagerContainerListItemContainerItem")
                SaveManagerContainerListItemContainerItem.itemname = name
            }

            // Load button
            let SaveManagerContainerListLoadButton = $.CreatePanel("Label", SaveManagerContainerListItem, "SaveManagerContainerListLoadButton")
            SaveManagerContainerListLoadButton.text = $.Localize("#save_manager_load")

            SaveManagerContainerListLoadButton.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                    let old = context.Children();
                    if (old) {
                        old.forEach(async (child) => {
                            if (child.id == "SaveManagerContainerListDeleteButtonConfirmContainer") {
                                child.RemoveAndDeleteChildren();
                                await child.DeleteAsync(0);
                            }
                        });
                    }

                    GameEvents.SendCustomGameEventToServer("save_manager_load_character", { 
                        unit: lastRememberedHero, 
                        hero: heroName
                    })
                }
            )

            // Delete button
            let SaveManagerContainerListDeleteButton = $.CreatePanel("Label", SaveManagerContainerListItem, "SaveManagerContainerListDeleteButton")
            SaveManagerContainerListDeleteButton.text = $.Localize("#save_manager_delete_hero")

            SaveManagerContainerListDeleteButton.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    let old = context.Children();
                    if (old) {
                        old.forEach(async (child) => {
                            if (child.id == "SaveManagerContainerListDeleteButtonConfirmContainer") {
                                child.RemoveAndDeleteChildren();
                                await child.DeleteAsync(0);
                            }
                        });
                    }

                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)
                    
                    let SaveManagerContainerListDeleteButtonConfirmContainer = $.CreatePanel("Panel", context, "SaveManagerContainerListDeleteButtonConfirmContainer")
                    let SaveManagerContainerListDeleteButtonConfirmText = $.CreatePanel("Label", SaveManagerContainerListDeleteButtonConfirmContainer, "SaveManagerContainerListDeleteButtonConfirmText")
                    SaveManagerContainerListDeleteButtonConfirmText.text = $.Localize("#save_manager_delete_hero_confirmation")
                    let SaveManagerContainerListDeleteButtonConfirmButtonContainer = $.CreatePanel("Panel", SaveManagerContainerListDeleteButtonConfirmContainer, "SaveManagerContainerListDeleteButtonConfirmButtonContainer")
                    let SaveManagerContainerListDeleteButtonConfirmButtonYes = $.CreatePanel("Label", SaveManagerContainerListDeleteButtonConfirmButtonContainer, "SaveManagerContainerListDeleteButtonConfirmButtonYes")
                    SaveManagerContainerListDeleteButtonConfirmButtonYes.text = $.Localize("#save_manager_delete_hero_confirmation_yes")
                    let SaveManagerContainerListDeleteButtonConfirmButtonNo = $.CreatePanel("Label", SaveManagerContainerListDeleteButtonConfirmButtonContainer, "SaveManagerContainerListDeleteButtonConfirmButtonNo")
                    SaveManagerContainerListDeleteButtonConfirmButtonNo.text = $.Localize("#save_manager_delete_hero_confirmation_no")

                    SaveManagerContainerListDeleteButtonConfirmButtonYes.SetPanelEvent(
                        "onmouseactivate", 
                        function(){
                            let old = context.Children();
                            if (old) {
                                GameEvents.SendCustomGameEventToServer("save_manager_delete_character", { 
                                    unit: lastRememberedHero, 
                                    _id: SaveManagerContainerListItem._id
                                })

                                old.forEach(async (child) => {
                                    if (child.id == "SaveManagerContainerListDeleteButtonConfirmContainer") {
                                        child.RemoveAndDeleteChildren();
                                        await child.DeleteAsync(0);
                                    }
                                });
                            }
                        }
                    )

                    SaveManagerContainerListDeleteButtonConfirmButtonNo.SetPanelEvent(
                        "onmouseactivate", 
                        function(){
                            let old = context.Children();
                            if (old) {
                                old.forEach(async (child) => {
                                    if (child.id == "SaveManagerContainerListDeleteButtonConfirmContainer") {
                                        child.RemoveAndDeleteChildren();
                                        await child.DeleteAsync(0);
                                    }
                                });
                            }
                        }
                    )
                }
            )
        }

        this.OnOpenInterface = function(data) {
            _this.CreateSaveButton()
            _this.DeleteOldContainer()

            _this.SaveManagerContainer = $.CreatePanel("Panel", context, "SaveManagerContainer")
            _this.SaveManagerHeaderContainer = $.CreatePanel("Panel", _this.SaveManagerContainer, "SaveManagerHeaderContainer")
            _this.SaveManagerHeader = $.CreatePanel("Label", _this.SaveManagerHeaderContainer, "SaveManagerHeader")
            _this.SaveManagerHeader.text = $.Localize("#save_manager_header")
            _this.SaveManagerHeaderClose = $.CreatePanel("Label", _this.SaveManagerHeaderContainer, "SaveManagerHeaderClose")

            _this.SaveManagerContainerList = $.CreatePanel("Panel", _this.SaveManagerContainer, "SaveManagerContainerList")

            _this.SaveManagerHeaderClose.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    _this.SaveManagerContainer.style.visibility = "collapse"
                    _this.SaveManagerContainer.style.opacity = "0"
                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                    let old = context.Children();
                    if (old) {
                        old.forEach(async (child) => {
                            if (child.id == "SaveManagerContainerListDeleteButtonConfirmContainer") {
                                child.RemoveAndDeleteChildren();
                                await child.DeleteAsync(0);
                            }
                        });
                    }

                    GameEvents.SendCustomGameEventToServer("save_manager_close_ui", { 
                        unit: lastRememberedHero
                    })
                }
            )

            // Data
            let heroes = data.heroes
            if(heroes) {
                let body = heroes.body
                if(body) {
                    for(const [k,v] of Object.entries(body)) {
                        _this.CreateItem(v)
                    }
                }
            }
        }

        this.OnLoadComplete = function() {
            _this.SaveManagerContainer.style.visibility = "collapse"
            _this.SaveManagerContainer.style.opacity = "0"
        }

        this.CreateSaveButton = function() {
            const buttonParent = mainHud.FindChildTraverse("ButtonBar")

            // Button
            let old = buttonParent.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "SaveManagerButtonImage") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            const image = $.CreatePanel("Button", context, "SaveManagerButtonImage")
            image.SetParent(buttonParent)

            buttonParent.MoveChildAfter(image, buttonParent.FindChildTraverse("SettingsButton"))

            image.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    Game.EmitSound("ui_generic_button_click")
                    /*
                    let elem = _this.SaveManagerSavePrompt 
                    if(elem.style.visibility == "visible") {
                        elem.style.visibility = "collapse"
                        elem.style.opacity = "0"
                    } else {
                        elem.style.visibility = "visible"
                        elem.style.opacity = "1"
                    }*/
                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)
                    GameEvents.SendCustomGameEventToServer("save_manager_save_character", { 
                        unit: lastRememberedHero
                    })
                }
            )

            image.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", image, $.Localize("#save_current_progress"));
                }
            )

            image.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                }
            )
        }

        this.OnBackpackComplete = function(data) {
            _this.InitClickEvent()

            let old = _this.SaveManagerContainerBackpackItemList.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "SaveManagerContainerBackpackItemBox") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            let heroes = data.inventory
            if(heroes) {
                let body = heroes.body
                if(body) {
                    for(const [k,bpObj] of Object.entries(body[1].backpack)) {
                        let name = bpObj["name"]
                        _this.CreateBackpackItem(name)
                    }
                }
            }
        }

        this.InitClickEvent = function() {
            // First 6 slots
            let inventoryContainer = mainHud.FindChildTraverse("inventory_list_container")
            if(inventoryContainer) {
                inventoryContainer.Children().forEach(async (child) => {
                    if (child.id == "inventory_list" || child.id == "inventory_list2") {
                        let children = child.Children()
                        children.forEach(async (parentSlotHolder) => {
                            let itemBox = parentSlotHolder.FindChildTraverse("ItemImage")
                            let itemName = itemBox.itemname 
                            if(itemName) {
                                itemBox.SetPanelEvent(
                                    "onmouseactivate", 
                                    function(){
                                        if(GameUI.IsControlDown()) {
                                            let slot = parentSlotHolder
                                            if(slot) {
                                                let slotNumber = slot.id.substr(-1)
                                                var localID = Players.GetLocalPlayer()
                                                var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                                                GameEvents.SendCustomGameEventToServer("save_manager_backpack_add_item", { 
                                                    unit: lastRememberedHero, 
                                                    item: itemName,
                                                    slot: slotNumber
                                                })
                                            }
                                        }
                                    }
                                )
                            }
                        })
                    }
                });
            }

            // Backpack slots (3)
            let backpackContainer = mainHud.FindChildTraverse("inventory_backpack_list")
            if(backpackContainer) {
                backpackContainer.Children().forEach(async (child) => {
                    if (child.id == "inventory_slot_6" || child.id == "inventory_slot_7" || child.id == "inventory_slot_8") {
                        let children = child.Children()
                        children.forEach(async (parentSlotHolder) => {
                            let itemBox = parentSlotHolder.FindChildTraverse("ItemImage")
                            let itemName = itemBox.itemname 
                            if(itemName) {
                                itemBox.SetPanelEvent(
                                    "onmouseactivate", 
                                    function(){
                                        if(GameUI.IsControlDown()) {
                                            let slot = parentSlotHolder
                                            if(slot) {
                                                let slotNumber = child.id.substr(-1)
                                                var localID = Players.GetLocalPlayer()
                                                var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                                                GameEvents.SendCustomGameEventToServer("save_manager_backpack_add_item", { 
                                                    unit: lastRememberedHero, 
                                                    item: itemName,
                                                    slot: slotNumber
                                                })
                                            }
                                        }
                                    }
                                )
                            }
                        })
                    }
                });
            }

            // Neutral item slot (1)
            let neutralItemContainer = mainHud.FindChildTraverse("inventory_neutral_slot_container")
            if(neutralItemContainer) {
                neutralItemContainer.Children().forEach(async (child) => {
                    if (child.id == "inventory_neutral_slot") {
                        let children = child.Children()
                        children.forEach(async (parentSlotHolder) => {
                            let itemBox = parentSlotHolder.FindChildTraverse("ItemImage")
                            let itemName = itemBox.itemname 
                            if(itemName) {
                                itemBox.SetPanelEvent(
                                    "onmouseactivate", 
                                    function(){
                                        if(GameUI.IsControlDown()) {
                                            let slot = parentSlotHolder
                                            if(slot) {
                                                let slotNumber = 16 // neutral slot
                                                var localID = Players.GetLocalPlayer()
                                                var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                                                GameEvents.SendCustomGameEventToServer("save_manager_backpack_add_item", { 
                                                    unit: lastRememberedHero, 
                                                    item: itemName,
                                                    slot: slotNumber
                                                })
                                            }
                                        }
                                    }
                                )
                            }
                        })
                    }
                });
            }

            $.Schedule(1, _this.InitClickEvent)
        }

        this.CreateBackpack = function() {
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "SaveManagerContainerBackpack") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            _this.SaveManagerContainerBackpack = $.CreatePanel("Panel", context, "SaveManagerContainerBackpack")
            _this.SaveManagerContainerBackpackHeader = $.CreatePanel("Label", _this.SaveManagerContainerBackpack, "SaveManagerContainerBackpackHeader")
            _this.SaveManagerContainerBackpackHeader.text = $.Localize("#save_manager_account_stash")
            _this.SaveManagerContainerBackpackItemListContainer = $.CreatePanel("Panel", _this.SaveManagerContainerBackpack, "SaveManagerContainerBackpackItemListContainer")
            _this.SaveManagerContainerBackpackItemSearchContainer = $.CreatePanel("Panel", _this.SaveManagerContainerBackpackItemListContainer, "SaveManagerContainerBackpackItemSearchContainer")
            _this.SaveManagerContainerBackpackItemSearchPlaceholder = $.CreatePanel("Label", _this.SaveManagerContainerBackpackItemSearchContainer, "SaveManagerContainerBackpackItemSearchPlaceholder")
            _this.SaveManagerContainerBackpackItemSearchPlaceholder.text = $.Localize("#save_manager_account_stash_search_placeholder")
            _this.SaveManagerContainerBackpackItemSearch = $.CreatePanel("TextEntry", _this.SaveManagerContainerBackpackItemSearchContainer, "SaveManagerContainerBackpackItemSearch")
            _this.SaveManagerContainerBackpackItemList = $.CreatePanel("Panel", _this.SaveManagerContainerBackpackItemListContainer, "SaveManagerContainerBackpackItemList")

            let placeholder = _this.SaveManagerContainerBackpackItemSearchPlaceholder
            _this.SaveManagerContainerBackpackItemSearch.SetPanelEvent(
                "onfocus", 
                function(){
                    placeholder.style.opacity = "0"
                }
            )

            _this.SaveManagerContainerBackpackItemSearch.SetPanelEvent(
                "onblur", 
                function(){
                    placeholder.style.opacity = "1"
                }
            )

            $.Schedule(0.1, _this.ListenToAccountStashSearchInput)
            
            _this.SaveManagerContainerBackpackTip = $.CreatePanel("Label", _this.SaveManagerContainerBackpack, "SaveManagerContainerBackpackTip")
            _this.SaveManagerContainerBackpackTip.text = $.Localize("#save_manager_account_stash_tip")
        }

        this.ListenToAccountStashSearchInput = function() {
            let items = _this.SaveManagerContainerBackpackItemList
            let search = _this.SaveManagerContainerBackpackItemSearch
            for(const v of items.Children()) {
                for(const box of v.Children()) {
                    if(box.itemname.match(search.text)) {
                        box.style.visibility = "visible"
                    } else {
                        box.style.visibility = "collapse"
                    }
                }
            }

            $.Schedule(0.1, _this.ListenToAccountStashSearchInput)
        }

        this.CreateBackpackItem = function(itemName) {
            let SaveManagerContainerBackpackItemBox = $.CreatePanel("Panel", _this.SaveManagerContainerBackpackItemList, "SaveManagerContainerBackpackItemBox")
            let SaveManagerContainerBackpackItemImage = $.CreatePanel("DOTAItemImage", SaveManagerContainerBackpackItemBox, "SaveManagerContainerBackpackItemImage")
            SaveManagerContainerBackpackItemImage.itemname = itemName

            SaveManagerContainerBackpackItemBox.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                    GameEvents.SendCustomGameEventToServer("save_manager_backpack_remove_item", { 
                        unit: lastRememberedHero, 
                        item: itemName
                    })
                }
            )
        }

        this.CreateBackpackButton = function() {
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "SaveManagerBackpackButton") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            /*_this.SaveManagerBackpackButton = $.CreatePanel("Panel", context, "SaveManagerBackpackButton")
            let btn = _this.SaveManagerBackpackButton

            btn.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    let elem = _this.SaveManagerContainerBackpack
                    if(elem.style.visibility == "visible") {
                        elem.style.visibility = "collapse"
                        elem.style.opacity = "0"
                    } else {
                        elem.style.visibility = "visible"
                        elem.style.opacity = "1"
                    }
                }
            )

            btn.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", btn, $.Localize("#account_stash_open"));
                }
            )

            btn.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                }
            )

            _this.SaveManagerBackpackButton.SetParent(centerBlockHud)*/
        }

        this.CreateSavePrompt = function() {
            // Box to ask what to save
            let oldSavePrompt = context.Children();
            if (oldSavePrompt) {
                oldSavePrompt.forEach(async (child) => {
                    if (child.id == "SaveManagerSavePrompt") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            _this.SaveManagerSavePrompt = $.CreatePanel("Panel", context, "SaveManagerSavePrompt")
            _this.SaveManagerSavePromptButtons = $.CreatePanel("Panel", _this.SaveManagerSavePrompt, "SaveManagerSavePromptButtons")
            _this.SaveManagerSavePromptButtonTextHero = $.CreatePanel("TextButton", _this.SaveManagerSavePromptButtons, "SaveManagerSavePromptButtonTextHero")
            _this.SaveManagerSavePromptButtonTextHero.text = $.Localize("#save_hero_info")
            _this.SaveManagerSavePromptButtonTextStash = $.CreatePanel("TextButton", _this.SaveManagerSavePromptButtons, "SaveManagerSavePromptButtonTextStash")
            _this.SaveManagerSavePromptButtonTextStash.text = $.Localize("#save_stash_info")

            /*
            _this.SaveManagerSavePromptButtonTextHero.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    Game.EmitSound("ui_generic_button_click")
                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                    GameEvents.SendCustomGameEventToServer("save_manager_save_character", { 
                        unit: lastRememberedHero,
                        order: 1
                    })
                }
            )

            _this.SaveManagerSavePromptButtonTextStash.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    Game.EmitSound("ui_generic_button_click")
                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                    GameEvents.SendCustomGameEventToServer("save_manager_save_character", { 
                        unit: lastRememberedHero,
                        order: 2
                    })
                }
            )*/
        }

        this.OnLoadSaveButton = function() {
            _this.CreateSaveButton()
        }

        this.OnUnitSelected = function(data) {
            let units = Players.GetSelectedEntities(Players.GetLocalPlayer())
            if(units) {
                let portraitUnit = Players.GetLocalPlayerPortraitUnit()
                var localID = Players.GetLocalPlayer()
                var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)
                let container = centerBlockHud.FindChildTraverse("SaveManagerBackpackButton")

                if(units[0] == lastRememberedHero && portraitUnit == lastRememberedHero) {
                    container.style.visibility = "visible"
                    container.style.opacity = "1"
                } else {
                    container.style.visibility = "collapse"
                    container.style.opacity = "0"
                }
            }
        }

        this.OnToggleUI = function() {
            let elem = _this.SaveManagerContainerBackpack
            if(elem.style.visibility == "visible") {
                elem.style.visibility = "collapse"
                elem.style.opacity = "0"
            } else {
                elem.style.visibility = "visible"
                elem.style.opacity = "1"
            }
        }

        _this.CreateBackpack()
        _this.InitClickEvent()
        _this.CreateBackpackButton()
        _this.CreateSavePrompt()
        
        GameEvents.Subscribe("save_manager_on_toggle_ui", this.OnToggleUI);
        GameEvents.Subscribe("save_manager_load_complete", this.OnLoadComplete);
        GameEvents.Subscribe("save_manager_open_interface", this.OnOpenInterface);
        GameEvents.Subscribe("save_manager_backpack_load_complete", this.OnBackpackComplete);
        GameEvents.Subscribe("save_manager_load_save_button", this.OnLoadSaveButton);
        /*GameEvents.Subscribe("dota_player_update_selected_unit", this.OnUnitSelected);
        GameEvents.Subscribe("dota_player_update_query_unit", this.OnUnitSelected);*/
    }

    return SaveManager;
}());

var ui = new SaveManager($.GetContextPanel());
