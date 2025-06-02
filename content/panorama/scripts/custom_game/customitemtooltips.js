var CustomItemTooltips = (function() {
    function CustomItemTooltips(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        let parentHud = mainHud.FindChildTraverse("AbilitiesAndStatBranch")
        let lowerHud = mainHud.FindChildTraverse("lower_hud")
        let abilitiesHud = mainHud.FindChildTraverse("abilities")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.selectedUnit = lastRememberedHero

        this.itemLabels = []
        this.itemPool = []
        this.visibleItemResults = []
        this.isDisplayingItem = false

        _this.UPGRADE_AMOUNT_1 = 0
        _this.UPGRADE_AMOUNT_2 = 0
        _this.UPGRADE_AMOUNT_3 = 0

        this.DeleteOldRows = function() {
            let abilityTooltip = mainHud.FindChildTraverse("DOTAAbilityTooltip")
            if(abilityTooltip != null) {
                if(abilityTooltip.IsValid()) {
                    let AbilityDetails = abilityTooltip.FindChildTraverse("AbilityDetails")
    
                    let old = AbilityDetails.Children();
                    if (old) {
                        old.forEach(async (child) => {
                            if(child.id == "AbilityDescriptionContainerStatContainer") {
                                child.RemoveAndDeleteChildren();
                                await child.DeleteAsync(0);
                            }
                        });
                    }
                }
            }
        }

        this.DeleteOldCustomTooltip = function() {
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if(child.id == "CustomItemTooltipContainer") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }
        }

        this.OnItemTooltipShown = function(itemPanel, entIndex, inventorySlot) {
            //_this.DeleteOldRows()
            _this.DeleteOldCustomTooltip()

            /*let abilityTooltip = mainHud.FindChildTraverse("DOTAAbilityTooltip")
            abilityTooltip.style.visibility = "visible"
            abilityTooltip.style.opacity = "1"*/

            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("item_tooltip_display_item", { 
                unit: lastRememberedHero,
                selectedUnit: _this.selectedUnit,
                inventorySlot: inventorySlot
            })
        }

        this.GetItemPositionOnScreen = function(slot) {
            if(slot > -1) {
                // First 6 slots only
                if(slot < 6) {
                    let inventoryListContainer = mainHud.FindChildTraverse("inventory_list_container")
                    let itemInSlot = inventoryListContainer.FindChildTraverse("inventory_slot_"+slot)
                    let buttonAndLevel = itemInSlot.FindChildTraverse("ButtonAndLevel")

                    return buttonAndLevel.GetPositionWithinWindow()
                } else if(slot > 5 && slot < 15) {
                    // Backpack items
                    let inventoryListContainer = mainHud.FindChildTraverse("inventory_backpack_list")
                    let itemInSlot = inventoryListContainer.FindChildTraverse("inventory_slot_"+slot)
                    let buttonAndLevel = itemInSlot.FindChildTraverse("ButtonAndLevel")

                    return buttonAndLevel.GetPositionWithinWindow()
                } else if(slot == 15) {
                    // Tp scroll
                    let inventoryListContainer = mainHud.FindChildTraverse("inventory_composition_layer_container")
                    let itemInSlot = inventoryListContainer.FindChildTraverse("inventory_tpscroll_slot")
                    let buttonAndLevel = itemInSlot.FindChildTraverse("ButtonAndLevel")

                    return buttonAndLevel.GetPositionWithinWindow()
                } else if(slot == 16) {
                    // Flask/neutral slot
                    let inventoryListContainer = mainHud.FindChildTraverse("inventory_composition_layer_container")
                    let itemInSlot = inventoryListContainer.FindChildTraverse("inventory_neutral_slot_container")
                    let buttonAndLevel = itemInSlot.FindChildTraverse("ButtonAndLevel")

                    return buttonAndLevel.GetPositionWithinWindow()
                } else {
                    // Fallback to cursor position
                    return _this.GetCursorPositionOnScreen()
                }
            }
        }

        this.GetCursorPositionOnScreen = function() {
            let cursor = GameUI.GetCursorPosition()

            let pos = {
                x: cursor[0],
                y: cursor[1],
            }
            
            return pos
        }

        this.OnShowTooltip = function(data) {
            $.Msg(data)
            //_this.DeleteOldRows()
            _this.DeleteOldCustomTooltip()
            
            let inventorySlot = data.slot 
            let stats = data.stats
            let values = data.values
            let itemName = data.itemName
            let itemIndex = data.itemIndex
            let itemLevel = data.itemLevel
            let itemRarity = data.rarity
            let upgradeLevel = data.upgradeLevel

            _this.UPGRADE_AMOUNT_1 = data.level1
            _this.UPGRADE_AMOUNT_2 = data.level2
            _this.UPGRADE_AMOUNT_3 = data.level3

            let abilityTooltip = mainHud.FindChildTraverse("DOTAAbilityTooltip")
            abilityTooltip.style.visibility = "collapse"
            abilityTooltip.style.opacity = "0"

            let customItemTooltipContainer = $.CreatePanel("Panel", context, "CustomItemTooltipContainer")
            customItemTooltipContainer.style.visibility = "visible"
            customItemTooltipContainer.style.opacity = "1"
            customItemTooltipContainer.hittest = false

            let customItemTooltipHeader = $.CreatePanel("Panel", customItemTooltipContainer, "CustomItemTooltipHeader")
            let customItemTooltipHeaderImage = $.CreatePanel("DOTAItemImage", customItemTooltipHeader, "CustomItemTooltipHeaderImage")
            customItemTooltipHeaderImage.hittest = false // without this it will crash when hovering over the image
            customItemTooltipHeaderImage.itemname = itemName

            let customItemTooltipHeaderNameContainer = $.CreatePanel("Panel", customItemTooltipHeader, "CustomItemTooltipHeaderNameContainer")
            let customItemTooltipHeaderName = $.CreatePanel("Label", customItemTooltipHeaderNameContainer, "CustomItemTooltipHeaderName")
            customItemTooltipHeaderName.html = true
            customItemTooltipHeaderName.text = $.Localize("#DOTA_Tooltip_Ability_"+itemName)

            if((itemRarity == "legendary" || itemRarity == "unique") && Object.keys(values).length > 0) {
                let customItemTooltipHeaderLevel = $.CreatePanel("Label", customItemTooltipHeaderNameContainer, "CustomItemTooltipHeaderLevel")
                customItemTooltipHeaderLevel.text = "Upgrade Level " + upgradeLevel
            }

            let customItemTooltipStatsContainer = $.CreatePanel("Panel", customItemTooltipContainer, "CustomItemTooltipStatsContainer")
            let customItemTooltipEffectContainer = $.CreatePanel("Panel", customItemTooltipContainer, "CustomItemTooltipEffectContainer")
            let customItemTooltipEffectLabel = $.CreatePanel("Label", customItemTooltipEffectContainer, "CustomItemTooltipEffectLabel")
            customItemTooltipEffectLabel.html = true
            customItemTooltipEffectContainer.style.visibility = "collapse"
             
            // If the item is a non-stat item then we can still show the tooltip description at least
            if(Object.keys(stats).length < 1) {
                let nonItemDescription = $.Localize("#DOTA_Tooltip_Ability_"+itemName+"_Description")
                
                nonItemDescription = nonItemDescription.replace(/%(\w+?)%+(%*)/g, (match, p1) => {
                    if(itemIndex != -1) {
                        let specialValue = Abilities.GetLevelSpecialValueFor( itemIndex, p1, itemLevel )
                        if(match.endsWith("%%%")) {
                            return specialValue + "%"
                        }
                        return specialValue;
                    } else {
                        return "???"
                    }
                });

                customItemTooltipEffectLabel.text = nonItemDescription
                customItemTooltipEffectLabel.AddClass("regular")
                
                customItemTooltipEffectContainer.style.visibility = "visible"
            }

            // Show item stats
            let replacements = []

            let translationString = $.Localize("#DOTA_Tooltip_Ability_"+itemName+"_Description")
            let translationReplacementString = ""

            for(const [statName, statRanges] of Object.entries(stats)) {
                // lev1-3 is legendary effect value, it's not supposed to show up in the stat list for tooltips
                if(statName != "lev1" && statName != "lev2" && statName != "lev3") {
                    let value = ""
                    if(values[statName]) {
                        value = values[statName].value
                    }

                    let statRow = $.CreatePanel("Label", customItemTooltipStatsContainer, "CustomItemTooltipStatRow")
                    statRow.html = true

                    let maxValue = statRanges.max
                    let minValue = statRanges.min

                    // range fix
                    if(upgradeLevel == 1) {
                        let rangeMult = (100+_this.UPGRADE_AMOUNT_1)/100
                        minValue = Math.floor(minValue * rangeMult)
                        maxValue = Math.floor(maxValue * rangeMult)
                    }

                    if(upgradeLevel == 2) {
                        let rangeMult = (100+_this.UPGRADE_AMOUNT_1)/100
                        minValue = Math.floor(minValue * rangeMult)
                        maxValue = Math.floor(maxValue * rangeMult)
                        let rangeMult2 = (100+_this.UPGRADE_AMOUNT_2)/100
                        minValue = Math.floor(minValue * rangeMult2)
                        maxValue = Math.floor(maxValue * rangeMult2)
                    }

                    if(upgradeLevel == 3) {
                        let rangeMult = (100+_this.UPGRADE_AMOUNT_1)/100
                        minValue = Math.floor(minValue * rangeMult)
                        maxValue = Math.floor(maxValue * rangeMult)
                        let rangeMult2 = (100+_this.UPGRADE_AMOUNT_2)/100
                        minValue = Math.floor(minValue * rangeMult2)
                        maxValue = Math.floor(maxValue * rangeMult2)
                        let rangeMult3 = (100+_this.UPGRADE_AMOUNT_3)/100
                        minValue = Math.floor(minValue * rangeMult3)
                        maxValue = Math.floor(maxValue * rangeMult3)
                    }

                    let translatedStatNameString = $.Localize("#tcot_stat_"+statName)
                    if(translatedStatNameString.includes("%")) {
                        translatedStatNameString = translatedStatNameString.replace(/%/g, "")
                        
                        maxValue = maxValue + "%"

                        if(value != "") {
                            value = value + "%"
                        }
                    }

                    if(statName == "special_ability" && value != "") {
                        let parts = value.split(":")
                        let level = parts[1]
                        let name = parts[0]

                        translatedStatNameString = $.Localize(`#DOTA_Tooltip_Ability_${name}`)

                        value = level
                    }

                    let isLocked = ""
                    if(values[statName]) {
                        isLocked = values[statName].affixRerollCount > 0 ? `★` : ``
                    }

                    statRow.text = `+ <font color='white'>${value}</font> ${translatedStatNameString} <font color='white'>[${minValue}-${maxValue}] ${isLocked}</font>`
                } else {
                    let addPctSignRange = ""
                    let addPctSignValue = ""
                    if(statRanges.pct && statRanges.pct == 1) {
                        addPctSignRange = "%"
                        addPctSignValue = "%"
                    }

                    let value = ""
                    if(values[statName]) {
                        value = values[statName].value
                    } else {
                        addPctSignValue = ""
                    }

                    let replacementString = `<span class='levprop'>${value}${addPctSignValue} [${statRanges.min}-${statRanges.max}${addPctSignRange}]</span>`;

                    replacements.push({
                        [statName]: replacementString
                    })
                }

                replacements.forEach(replacement => {
                    for (let searchString in replacement) {
                        let replacementString = replacement[searchString];
                        // Create a regular expression to match `%myinput1%`, `%myinput1%%%`, `%myinput2%`, `%myinput2%%%`, etc.
                        let regex = new RegExp(`%${searchString}%+`, 'g');
                        // Replace the matched pattern with the replacement string
                        translationReplacementString = translationString.replace(regex, replacementString);
                        translationString = translationReplacementString
                        customItemTooltipEffectContainer.style.visibility = "visible"
                    }
                });

                // Find all other special values in the string, e.g. "%duration%" and replace it with the right value
                translationReplacementString = translationReplacementString.replace(/%(\w+?)%+(%*)/g, (match, p1) => {
                    if(itemIndex != -1) {
                        let specialValue = Abilities.GetLevelSpecialValueFor( itemIndex, p1, itemLevel )
                        if(match.endsWith("%%%")) {
                            return specialValue + "%"
                        }
                        return specialValue;
                    } else {
                        return "???"
                    }
                })

                // If a legendary item doesn't have special ability values then we need to manually force the description to display
                // Just be careful to not give descriptions to non-legendary items...
                if(translationReplacementString == "") {
                    let fallbackLocalization = $.Localize("#DOTA_Tooltip_Ability_"+itemName+"_Description")
                    if(!fallbackLocalization.includes("#DOTA_Tooltip_Ability")) {
                        translationReplacementString = fallbackLocalization
                        customItemTooltipEffectContainer.style.visibility = "visible"
                    }
                }

                customItemTooltipEffectLabel.text = "<span class='legaff'>(LEGENDARY EFFECT)</span><br>" + translationReplacementString
            }
            
            $.Schedule(.1, function() {
                if(customItemTooltipStatsContainer.IsValid()) {
                    if(!_this.isDisplayingItem) {
                        _this.DeleteOldCustomTooltip()
                    } else {
                        let addedHeight = customItemTooltipContainer.contentheight/1.5
                        if(inventorySlot != -1) {
                            let supposedTooltipPosition = _this.GetItemPositionOnScreen(inventorySlot)

                            if(supposedTooltipPosition != undefined) {
                                let posX = supposedTooltipPosition.x * (1/context.actualuiscale_x)
                                let posY = supposedTooltipPosition.y * (1/context.actualuiscale_y)

                                posX = posX + 72
                                posY = posY - addedHeight
                                
                                customItemTooltipContainer.SetPositionInPixels(posX, posY, 0)
                            }
                        } else {
                            let supposedTooltipPosition = _this.GetCursorPositionOnScreen()
                            if(supposedTooltipPosition != undefined) {
                                let posX = supposedTooltipPosition.x * (1/context.actualuiscale_x)
                                let posY = supposedTooltipPosition.y * (1/context.actualuiscale_y)

                                posX = posX + 25
                                posY = posY - addedHeight
            
                                customItemTooltipContainer.SetPositionInPixels(posX, posY, 0)
                            }
                        }

                        customItemTooltipContainer.style.margin = "0"
                    }
                }
            })

            /*
            if(abilityTooltip.IsValid()) {
                let AbilityDetails = abilityTooltip.FindChildTraverse("AbilityDetails")
                if(AbilityDetails.IsValid()) {
                    let children = AbilityDetails.Children()
                    if (children) {
                        children.forEach(async (child) => {
                            if(child.id == "AbilityDescriptionContainerStatContainer") {
                                if(!child.hasStats) {
                                    child.RemoveAndDeleteChildren();
                                    await child.DeleteAsync(0);
                                }
                            }
                        });
                    }

                    let AbilityTarget = AbilityDetails.FindChildTraverse("AbilityTarget")

                    let statContainerCSS = {
                        "flow-children": "down-wrap",
                        "padding": "0 8px",
                        "width": "100%",
                    }
                    
                    _this.statContainer = $.CreatePanel("Panel", AbilityDetails, "AbilityDescriptionContainerStatContainer")
                    _this.statContainer.hasStats = Object.keys(values).length > 0
                    
                    // Apply CSS
                    Object.keys(statContainerCSS).forEach(key => {
                        _this.statContainer.style[key] = statContainerCSS[key];
                    });
                    
                    let statRowCSS = {
                        "color": "#FFF", //#9ab0cd
                        "padding": "8px 0",
                        "border-bottom": "1px solid #29353b",
                        "width": "100%",
                        "text-transform": "uppercase",
                        "font-weight": "bold",
                        "font-size": "15px",
                        "text-shadow": "1px 1px 1px black"
                    }

                    for(const [statName, statRanges] of Object.entries(stats)) {
                        // lev1-3 is legendary effect value, it's not supposed to show up in the stat list for tooltips
                        if(statName != "lev1" && statName != "lev2" && statName != "lev3") {
                            let value = ""
                            if(values[statName]) {
                                value = values[statName].value
                            }

                            let statRow = $.CreatePanel("Label", _this.statContainer, "AbilityDescriptionContainerStatRow")
                            statRow.html = true

                            let maxValue = statRanges.max

                            let translatedStatNameString = $.Localize("#tcot_stat_"+statName)
                            if(translatedStatNameString.includes("%")) {
                                translatedStatNameString = translatedStatNameString.replace(/%/g, "")
                                
                                maxValue = maxValue + "%"

                                if(value != "") {
                                    value = value + "%"
                                }
                            }

                            if(statName == "special_ability" && value != "") {
                                let parts = value.split(":")
                                let level = parts[1]
                                let name = parts[0]

                                translatedStatNameString = $.Localize(`#DOTA_Tooltip_Ability_${name}`)

                                value = "+" + level
                            }

                            statRow.text = `${value} ${translatedStatNameString} [${statRanges.min}-${maxValue}]`

                            Object.keys(statRowCSS).forEach(key => {
                                statRow.style[key] = statRowCSS[key];
                            });
                        }

                        AbilityDetails.MoveChildAfter(_this.statContainer, AbilityTarget)
                    }
                }
            }*/
        }

        this.OnDroppedItemTooltipShown = function(a,b,c,itemName,e,f,g) {
            //_this.DeleteOldRows()
            _this.DeleteOldCustomTooltip()

            _this.isDisplayingItem = true

            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("item_tooltip_display_item", { 
                unit: lastRememberedHero,
                selectedUnit: _this.selectedUnit,
                inventorySlot: -1,
                itemName: itemName
            })
        }

        this.OnAbilityTooltipShown = function(abilityPanel, itemName) {
            // hide default dota tooltip if it's an item we're displaying
            if(!itemName.includes("item_")) {
                let abilityTooltip = mainHud.FindChildTraverse("DOTAAbilityTooltip")
                abilityTooltip.style.visibility = "visible"
                abilityTooltip.style.opacity = "1"
                return;
            }
            
            //_this.DeleteOldRows()
            _this.DeleteOldCustomTooltip()

            _this.isDisplayingItem = true

            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("item_tooltip_display_item", { 
                unit: lastRememberedHero,
                selectedUnit: _this.selectedUnit,
                inventorySlot: -1,
                itemName: itemName
            })
        }

        this.OnItemTooltipHide = function() {
            //_this.DeleteOldRows()
            _this.isDisplayingItem = false
            _this.DeleteOldCustomTooltip()
        }

        this.OnUnitSelected = function(data) {
            let units = Players.GetSelectedEntities(Players.GetLocalPlayer())
            if(units) {
                let portraitUnit = Players.GetLocalPlayerPortraitUnit() // this is the currently selected unit
                var localID = Players.GetLocalPlayer()
                
                _this.selectedUnit = portraitUnit
            }
        }

        this.OnDisplayGroundLabel = function(data) {
            // delete old
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if(child.id == "ItemGroundLabel") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            // create
            let positionX = data.posX
            let positionY = data.posY
            let positionZ = data.posZ
            let itemIndex = data.itemIndex
            let item = data.item

            _this.itemPool = data.pool
            
            let screenPosX = Game.WorldToScreenX(positionX, positionY, positionZ)
            let screenPosY = Game.WorldToScreenY(positionX, positionY, positionZ)

            if(screenPosX != -1 && screenPosY != -1) {
                let itemLabelContainer = $.CreatePanel("Panel", context, "ItemGroundLabelContainer")

                let category = _this.GetItemCategory(item)

                itemLabelContainer.AddClass(category)
                
                let itemLabel = $.CreatePanel("Label", itemLabelContainer, "ItemGroundLabel")
                itemLabel.html = true
                itemLabel.text = $.Localize("#DOTA_Tooltip_Ability_"+item)
                
                _this.itemLabels.push({
                    panel: itemLabelContainer,
                    positions: {
                        x: screenPosX,
                        y: screenPosY
                    },
                    itemIndex: itemIndex
                })

                itemLabelContainer.SetPanelEvent(
                    "onmouseactivate", 
                    function(){
                        let itemContainer = _this.itemLabels.find((p) => p.panel == itemLabelContainer)
                        
                        var localID = Players.GetLocalPlayer()
                        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                        GameEvents.SendCustomGameEventToServer("item_tooltip_pickup_item", { 
                            unit: lastRememberedHero,
                            itemIndex: itemIndex
                        })
                    }
                )
            }
        }

        this.GetItemCategory = function(name) {
            //{"mythical":{"1":"item_voodoo_mask_custom","2":"item_falcon_blade_custom","3":"item_oblivion_staff_custom","4":"item_blade_of_alacrity_custom","5":"item_power_treads_custom"},"legendary":{"1":"item_vashundol_cleaver","2":"item_kings_guard"},"common":{"1":"item_claymore_custom","2":"item_ring_of_tarrasque_custom","3":"item_helm_of_iron_will_custom","4":"item_stout_shield_custom","5":"item_boots_custom","6":"item_ring_of_regen_custom","7":"item_tiara_of_selemene_custom"},"rare":{"1":"item_longsword_custom","2":"item_blitz_knuckles_custom","3":"item_chainmail_custom","4":"item_ring_of_health_custom","5":"item_diadem_custom"}}

            for(const [k,v] of Object.entries(_this.itemPool)) {
                for(const [a,b] of Object.entries(v)) {
                    if(b == name) return k
                }
            }
        }

        this.CanItemBeSeen = function() {
            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("item_tooltip_can_item_be_seen", { 
                unit: lastRememberedHero,
                items: _this.itemLabels
            })

            $.Schedule(1, _this.CanItemBeSeen)
        }

        this.CanItemBeSeenResult = function(data) {
            let results = data.results

            _this.visibleItemResults = results
        }

        // This returns if the item is visible in FoW for the player
        this.IsItemVisible = function(item) {
            return _this.visibleItemResults[item]
        }

        this.IsCraftingOpen = function() {
            let vis = mainHud.FindChildTraverse("CustomUIRoot").FindChildTraverse("CustomUIContainer_Hud").FindChildTraverse("CraftingManagerContainer").style.visibility

            return vis == "visible"
        }

        this.StartItemLabels = async function() {
            let labels = _this.itemLabels
            
            for (let i = 0; i < labels.length; i++) {
                const label = labels[i];
                
                let containedItem = Entities.GetContainedItem(label.itemIndex)
                if(containedItem > -1) {
                    let containerAbs = Entities.GetAbsOrigin(label.itemIndex)
                    let screenPosX = Game.WorldToScreenX(containerAbs[0], containerAbs[1], containerAbs[2]) * (1/context.actualuiscale_x)
                    let screenPosY = Game.WorldToScreenY(containerAbs[0], containerAbs[1], containerAbs[2]) * (1/context.actualuiscale_y)

                    // Get screen size
                    let screenWidth = Game.GetScreenWidth() * (1/context.actualuiscale_y)
                    let screenHeight = Game.GetScreenHeight() * (1/context.actualuiscale_x)

                    // Check if the coordinates are within the screen bounds
                    if (screenPosX >= 0 && screenPosX <= screenWidth && screenPosY >= 0 && screenPosY <= screenHeight) {
                        label.panel.SetPositionInPixels(screenPosX-((label.panel.contentwidth*(1/context.actualuiscale_x))/2), screenPosY-75, 0)
                    
                        if(_this.IsItemVisible(label.itemIndex) && !_this.IsCraftingOpen()) {
                            label.panel.style.visibility = "visible"
                        } else {
                            label.panel.style.visibility = "collapse"
                        }
                    } else {
                        label.panel.style.visibility = "collapse"
                    }
                } else {
                    // Remove the item from the array since it no longer exists
                    label.panel.RemoveAndDeleteChildren();
                    await label.panel.DeleteAsync(0);
                    labels.splice(i, 1);
                    i--;
                }
            }

            $.Schedule(0.01, _this.StartItemLabels)
        }

        $.Schedule(0.01, _this.StartItemLabels)
        $.Schedule(1, _this.CanItemBeSeen)

        $.RegisterForUnhandledEvent("DOTAShowAbilityInventoryItemTooltip", (itemPanel, inventorySlot, c) => this.OnItemTooltipShown(itemPanel, inventorySlot, c));
        $.RegisterForUnhandledEvent("DOTAHideDroppedItemTooltip", (e) => this.OnItemTooltipHide(e));
        $.RegisterForUnhandledEvent("DOTAShowDroppedItemTooltip", (a,b,c,d,e,f,g) => this.OnDroppedItemTooltipShown(a,b,c,d,e,f,g));
        $.RegisterForUnhandledEvent("DOTAShowAbilityTooltip", (abilityPanel, itemName) => this.OnAbilityTooltipShown(abilityPanel, itemName));
        $.RegisterForUnhandledEvent("DOTAHideAbilityTooltip", (e) => this.OnItemTooltipHide(e));

        GameEvents.Subscribe("item_tooltip_display_ground_label", this.OnDisplayGroundLabel);
        GameEvents.Subscribe("item_tooltip_display_item_return", this.OnShowTooltip);
        GameEvents.Subscribe("dota_player_update_selected_unit", this.OnUnitSelected);
        GameEvents.Subscribe("dota_player_update_query_unit", this.OnUnitSelected);
        GameEvents.Subscribe("item_tooltip_can_item_be_seen_result", this.CanItemBeSeenResult);
    }

    return CustomItemTooltips;
}());

var ui = new CustomItemTooltips($.GetContextPanel());
