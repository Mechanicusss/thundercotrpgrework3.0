var DpsManager = (function() {
    function DpsManager(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        var shopHud = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("shop")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.SELECTED_SIDE = 0
        this.SELECTED_SIDE_LEVEL = 0
        this.TALENT_ELEMENTS = []
        this.HERO_TALENTS = []

        this.visibility = "visible";
        this.opacity = "0";
        this.storedPlayerTotalDamage = []
        this.storedTotalDamage = []
        this.storedDamage = {}
        this.currentlyViewingBreakdown = -1

        this.DeleteOldContainer = async function() {
            let old = context.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "DpsManagerContainer") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            _this.container = $.CreatePanel("Panel", context, "DpsManagerContainer")
            _this.containerTitle = $.CreatePanel("Label", _this.container, "DpsManagerContainerTitle")
            _this.containerTitle.text = "Damage Meter"

            _this.container.style.visibility = _this.visibility

            let shortCutButton = mainHud.FindChildTraverse("left_flare")
            if(shortCutButton && shortCutButton.IsValid()) {
                if(shortCutButton.toggled == 1) {
                    _this.container.style.visibility = "visible"
                } else {
                    _this.container.style.visibility = "visible"
                }
            }

            this.storedPlayerTotalDamage = []
        }

        this.DeleteOldToggleButton = async function() {
            let oldparent = mainHud.FindChildTraverse("left_flare")
            let old = oldparent.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "DpsManagerContainerToggle") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            _this.container = $.CreatePanel("Panel", context, "DpsManagerContainer")
            _this.containerTitle = $.CreatePanel("Label", _this.container, "DpsManagerContainerTitle")
            _this.containerTitle.text = "Damage Meter"

            this.storedPlayerTotalDamage = []
        }

        this.DeleteOldBreakdownContainer = async function() {
            let parent = _this.breakdownContainer
            let old = parent.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "DpsManagerBreakdownHeroContainer") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }
        }

        this.DeleteOldBreakdownItemParentContainer = async function() {
            let parent = _this.breakdownItemParentContainer
            let old = parent.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "DpsManagerBreakdownItemContainer") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }
        }

        this.OnResetComplete = function(data) {
            _this.breakdownContainer.style.visibility = "visible"
            _this.breakdownContainer.style.opacity = "0"
            _this.currentlyViewingBreakdown = -1

            _this.OnUpdate(data)
        }

        this.OnUpdate = function(data) {
            _this.DeleteOldContainer()

            const storedDamage = data.storedDamage
            const storedDPS = data.storedDPS

            if(storedDamage && storedDPS) {
                const sortedSteamObj = Object.entries(storedDamage).sort(([, a], [, b]) => {
                    const damageA = a?.attack?.[1]?.damage || 0; // Default to 0 if properties are missing
                    const damageB = b?.attack?.[1]?.damage || 0; // Default to 0 if properties are missing
                    
                    return damageB - damageA;
                });

                for(const [steamID, steamObj] of sortedSteamObj) {
                    for(const [category, categoryObj] of Object.entries(steamObj)) {
                        for(const [damageType, damageObj] of Object.entries(categoryObj)) {
                            const damage = damageObj.damage
                            const hero = damageObj.hero
                            
                            let playerData = _this.storedPlayerTotalDamage.find(player => player[steamID]);

                            if (!playerData) {
                                playerData = { [steamID]: { "damage": 0, "hero": hero, "dps": 0 } };
                                _this.storedPlayerTotalDamage.push(playerData);
                            }

                            playerData[steamID]["damage"] += parseFloat(damage);
                            playerData[steamID]["dps"] = storedDPS[steamID];

                            _this.storedDamage = storedDamage

                            if(_this.currentlyViewingBreakdown == steamID) {
                                _this.OpenBreakDownPanel(steamID, hero)
                            }
                        }
                    }

                    // Store total damage dealt for each player
                    let playedStoredDamage = _this.storedTotalDamage.find(player => player[steamID]);

                    if (!playedStoredDamage) {
                        playedStoredDamage = { [steamID]: {} };
                        _this.storedTotalDamage.push(playedStoredDamage);
                    }

                    playedStoredDamage[steamID] = _this.GetTotalStoredDamage(steamID)

                    // Create row
                    _this.CreatePlayerInstance(_this.storedPlayerTotalDamage, steamID)
                }
            }
        }

        this.CreatePlayerInstance = function(playerData, steamID) {
            let data = playerData.find(player => player[steamID]);
            let total = _this.storedTotalDamage.find(player => player[steamID]);

            if(data != undefined && total) {
                if(data[steamID] != undefined && total[steamID] != undefined) {
                    total = total[steamID]

                    let damage = data[steamID]["damage"]
                    let hero = data[steamID]["hero"]
                    let dps = data[steamID]["dps"]
                    let totalDps = _this.FormatWithSuffix(dps)

                    this.playerContainer = $.CreatePanel("Panel", this.container, "DpsManagerPlayer")

                    this.playerHeroContainer = $.CreatePanel("DOTAHeroImage", this.playerContainer, "DpsManagerPlayerHeroContainer")
                    this.playerHeroImage = $.CreatePanel("DOTAHeroImage", this.playerHeroContainer, "DpsManagerPlayerHeroImage")
                    this.playerHeroImage.heroname = hero
                    this.playerHeroButton = $.CreatePanel("Label", this.playerHeroContainer, "DpsManagerPlayerHeroButton")
                    this.playerHeroButton.text = "Details"

                    const breakdownButton = this.playerHeroButton
                    breakdownButton.SetPanelEvent(
                        "onmouseactivate", 
                        function(){
                            if(_this.currentlyViewingBreakdown != steamID) {
                                _this.breakdownContainer.style.visibility = "visible"
                                _this.breakdownContainer.style.opacity = "1"
                                _this.currentlyViewingBreakdown = steamID
                                _this.OpenBreakDownPanel(steamID, hero)
                            } else {
                                _this.breakdownContainer.style.visibility = "visible"
                                _this.breakdownContainer.style.opacity = "0"
                                _this.currentlyViewingBreakdown = -1
                            }
                        }
                    )

                    breakdownButton.SetPanelEvent(
                        "onmouseover", 
                        function(){
                            $.DispatchEvent("DOTAShowTextTooltip", breakdownButton, `Shows a complete damage breakdown for ${$.Localize("#"+hero)}. Does not display sources that is less than 1% than the total damage dealt.`)
                        }
                    )
            
                    breakdownButton.SetPanelEvent(
                        "onmouseout", 
                        function(){
                            $.DispatchEvent("DOTAHideTextTooltip");
                        }
                    )
        
                    this.playerBarContainer = $.CreatePanel("Panel", this.playerContainer, "DpsManagerPlayerBarContainer")
                    this.playerBar = $.CreatePanel("Panel", this.playerBarContainer, "DpsManagerPlayerBar")

                    const currentWidthPercentage = (damage / total) * 100;
                    if(isFinite(currentWidthPercentage)) {
                        this.playerBar.style.width = `${currentWidthPercentage}%`
                    }

                    let damageText = `${_this.FormatWithSuffix(damage)} (${totalDps == "NaNundefined" ? 0 : totalDps}/s)`

                    this.playerBarLabel = $.CreatePanel("Label", this.playerBar, "DpsManagerPlayerBarLabel")
                    this.playerBarLabel.text = damageText

                    let tooltip = this.playerBarContainer

                    tooltip.SetPanelEvent(
                        "onmouseover", 
                        function(){
                            $.DispatchEvent("DOTAShowTextTooltip", tooltip, damageText)
                        }
                    )
            
                    tooltip.SetPanelEvent(
                        "onmouseout", 
                        function(){
                            $.DispatchEvent("DOTAHideTextTooltip");
                        }
                    )
                }
            }
            
        }

        this.GetTotalStoredDamage = function(steamID) {
            let total = 0

            let playerData = _this.storedPlayerTotalDamage.find(player => player[steamID]);
            if(playerData) {
                for(const [key, value] of Object.entries(playerData)) {
                    total += value.damage
                }
            }

            return parseFloat(total) // return as float otherwise JS interprets it as an octal literal
        }

        this.FormatWithSuffix = function(number) {
            if(number < 1) return number 
            
            const suffixes = ["", "k", "m", "b", "t"]; // Add more if needed
            const orderOfMagnitude = Math.floor(Math.log10(Math.abs(number)) / 3);
            const suffixIndex = Math.min(orderOfMagnitude, suffixes.length - 1);
        
            const formattedNumber = (number / Math.pow(10, suffixIndex * 3)).toFixed(1);
            const result = formattedNumber + suffixes[suffixIndex];

            return result
        }

        this.CreateBreakdownItem = function(inflictor, damageType, damage, totalDamage, playerIndex) {
            let sDamageType = ""
            if(damageType == 0) {
                sDamageType = "None"
            } else if(damageType == 1) {
                sDamageType = "Physical"
            } else if(damageType == 2) {
                sDamageType = "Magical"
            } else if(damageType == 4) {
                sDamageType = "Pure"
            } else {
                sDamageType = "Unknown Type"
            }

            let sInflictor = ""
            let abilityName = ""
            let localizedAbilityName = ""

            if(inflictor == "attack") {
                sInflictor = "Basic Attack Damage"
                localizedAbilityName = sInflictor
            } else if(inflictor == "other") {
                sInflictor = "Other (Unknown)"
                localizedAbilityName = sInflictor
            } else {
                sInflictor = inflictor // must be an ability/item name
                localizedAbilityName = $.Localize("#dota_tooltip_ability_"+sInflictor)
            }

            abilityName = sInflictor

            let iconNameType = "DOTAAbilityImage"
            let iconNameKey = "abilityname"
            if(abilityName.startsWith("item_")) {
                iconNameType = "DOTAItemImage"
                iconNameKey = "itemname"
            } else if(abilityName == "Basic Attack Damage") {
                abilityName = "creep_piercing"
            }
            
            const abilityIndex = Entities.GetAbilityByName(playerIndex, sInflictor)
            if(abilityIndex > -1) {
                abilityName = Abilities.GetAbilityName(abilityIndex)
            }

            let pctDamage = ((parseFloat(damage) / parseFloat(totalDamage))*100).toFixed(2)

            this.breakdownItemContainer = $.CreatePanel("Panel", _this.breakdownItemParentContainer, "DpsManagerBreakdownItemContainer")

            this.breakdownItemTopContainer = $.CreatePanel("DOTAHeroImage", this.breakdownItemContainer, "DpsManagerBreakdownItemTopContainer")
            this.breakdownItemImage = $.CreatePanel(iconNameType, this.breakdownItemTopContainer, "DpsManagerBreakdownItemImage")
            this.breakdownItemImage[iconNameKey] = abilityName
            this.breakdownItemName = $.CreatePanel("Label", this.breakdownItemTopContainer, "DpsManagerBreakdownItemName")
            this.breakdownItemName.html = true
            this.breakdownItemName.text = `${localizedAbilityName} (${sDamageType})`

            this.breakdownItemBarContainer = $.CreatePanel("Panel", this.breakdownItemContainer, "DpsManagerBreakdownItemBarContainer")
            this.breakdownItemBar = $.CreatePanel("Panel", this.breakdownItemBarContainer, "DpsManagerBreakdownItemBar")
            
            if(sDamageType == "Physical") {
                this.breakdownItemBar.style.backgroundColor = `gradient( linear, 0% 0%, 0% 100%, from( #598307 ), to( #25301d ) )`
            } else if(sDamageType == "Magical") {
                this.breakdownItemBar.style.backgroundColor = `gradient( linear, 0% 0%, 0% 100%, from( #00a287 ), to( #173634 ) )`
            } else if(sDamageType == "Pure") {
                this.breakdownItemBar.style.backgroundColor = `gradient( linear, 0% 0%, 0% 100%, from( gold ), to( #7b6d23 ) )`
            }

            if(isFinite(pctDamage)) {
                this.breakdownItemBar.style.width = `${pctDamage}%`
            }

            const damageText = `${_this.FormatWithSuffix(damage)} (${pctDamage}%)`

            this.breakdownItemBarLabel = $.CreatePanel("Label", this.breakdownItemBar, "DpsManagerBreakdownItemBarLabel")
            this.breakdownItemBarLabel.text = damageText

            let tooltip = this.breakdownItemBarContainer

            tooltip.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", tooltip, damageText)
                }
            )
    
            tooltip.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                }
            )
        }

        this.OpenBreakDownPanel = function(steamID, heroName) {
            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            _this.DeleteOldBreakdownContainer()
            _this.DeleteOldBreakdownItemParentContainer()

            _this.breakdownHeroContainer = $.CreatePanel("Panel", _this.breakdownContainer, "DpsManagerBreakdownHeroContainer")

            _this.breakdownHeroDisplayContainer = $.CreatePanel("Panel", _this.breakdownHeroContainer, "DpsManagerBreakdownHeroDisplayContainer")
            _this.breakdownHeroImage = $.CreatePanel("DOTAHeroImage", _this.breakdownHeroDisplayContainer, "DpsManagerBreakdownHeroImage")
            _this.breakdownHeroImage.heroname = heroName
            _this.breakdownHeroName = $.CreatePanel("Label", _this.breakdownHeroDisplayContainer, "DpsManagerBreakdownHeroName")
            _this.breakdownHeroName.text = $.Localize("#"+heroName)

            _this.breakdownHeroReset = $.CreatePanel("Label", _this.breakdownHeroContainer, "DpsManagerBreakdownHeroReset")
            _this.breakdownHeroReset.text = "Clear All Data"

            if(Entities.GetUnitName(lastRememberedHero) != heroName) {
                _this.breakdownHeroReset.style.visibility = "visible"
                _this.breakdownHeroReset.style.opacity = "0"
            } else {
                _this.breakdownHeroReset.style.visibility = "visible"
                _this.breakdownHeroReset.style.opacity = "1"
            }

            if(!_this.breakdownItemParentContainer) {
                _this.breakdownItemParentContainer = $.CreatePanel("Panel", _this.breakdownContainer, "DpsManagerBreakdownItemParentContainer")
            } else {
                _this.breakdownContainer.MoveChildAfter(_this.breakdownItemParentContainer, _this.breakdownHeroContainer)
            }

            const clearButton = _this.breakdownHeroReset

            clearButton.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                    GameEvents.SendCustomGameEventToServer("dps_manager_reset", { unit: lastRememberedHero, heroName: heroName })
                }
            )

            const storedDamage = _this.storedDamage

            if(storedDamage) {
                const sortedStoredDamage = Object.entries(storedDamage[steamID]).sort((a, b) => {
                    const totalDamageA = Object.values(a[1]).reduce((acc, entry) => acc + entry.damage, 0);
                    const totalDamageB = Object.values(b[1]).reduce((acc, entry) => acc + entry.damage, 0);
                
                    return totalDamageB - totalDamageA;
                });

                for(const [category, categoryObj] of sortedStoredDamage) {
                    for(const [damageType, damageObj] of Object.entries(categoryObj)) {
                        const damage = damageObj.damage
                        const playerIndex = damageObj.playerIndex

                        let totalDamage = _this.storedTotalDamage.find(player => player[steamID]);
                        if(totalDamage[steamID]) {
                            // We only want to display damage instances that's 1% or more of the total damage
                            let pct = (damage / totalDamage[steamID]) * 100
                            if(pct >= 1) {
                                this.CreateBreakdownItem(category, damageType, damage, totalDamage[steamID], playerIndex)
                            }
                        }
                    }
                }
            }
        }

        this.DeleteOldContainer()
        this.DeleteOldToggleButton()

        this.breakdownContainer = $.CreatePanel("Panel", context, "DpsManagerBreakdownContainer")
        this.breakdownContainerTitle = $.CreatePanel("Label", this.breakdownContainer, "DpsManagerBreakdownContainerTitle")
        this.breakdownContainerTitle.text = "Detailed Damage Breakdown"

        let shortCutButton = mainHud.FindChildTraverse("left_flare")
        if(!shortCutButton.IsValid()) {
            const toggleParent = mainHud.FindChildTraverse("left_flare")

            this.containerTogglePanel = $.CreatePanel("Panel", context, "DpsManagerContainerToggle")
            this.containerToggleLabel = $.CreatePanel("Label", this.containerTogglePanel, "DpsManagerContainerToggleLabel")
            this.containerToggleLabel.text = " "
            
            this.containerTogglePanel.SetParent(toggleParent)

            const toggleTooltip = this.containerTogglePanel

            toggleTooltip.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", toggleTooltip, "Toggle Damage Meter")
                }
            )

            toggleTooltip.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                }
            )

            toggleTooltip.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    if(_this.visibility == "visible") {
                        _this.visibility = "visible"
                        _this.opacity = "1"
                        toggleTooltip.AddClass("toggle")
                    } else {
                        _this.visibility = "visible"
                        _this.opacity = "0"
                        toggleTooltip.RemoveClass("toggle")
                        _this.breakdownContainer.style.visibility = "visible"
                        _this.breakdownContainer.style.opacity = "0"
                        _this.currentlyViewingBreakdown = -1
                    }
                    _this.container.style.visibility = _this.visibility
                }
            )
        }

        

        GameEvents.Subscribe("dps_manager_update", this.OnUpdate);
        GameEvents.Subscribe("dps_manager_reset_complete", this.OnResetComplete);
    }

    return DpsManager;
}());

var ui = new DpsManager($.GetContextPanel());
