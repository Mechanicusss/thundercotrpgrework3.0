var WaveManagerEndScreen = (function() {
    function WaveManagerEndScreen(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        var shopHud = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("shop")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.warningPlayed = false
        this.warningCounterDelay = 10
        this.warningCounter = this.warningCounterDelay - 1

        this.visibility = "collapse"
        this.opacity = "0"

        this.OnModifierCounter = function(data) {
            const units = data.units 
            const limit = data.limit 
            const killed = data.killed
            const timePassed = data.time
            const deaths = data.deaths
            const points = data.points
            const heroes = data.heroes

            if(killed != null && _this.infoText != null) {
                _this.infoText.text = killed
            }

            if(deaths != null && _this.infoText4 != null) {
                _this.infoText4.text = deaths
            }

            if(heroes != null && points != null && _this.infoText5 != null) {
                let colorName = "lightgreen"
                if(parseInt(points) < 0) colorName = "red"

                _this.infoText5.text = "<font color='"+colorName+"'>"+Math.floor(parseInt(points))+"</font>";

                for(const [hero,values] of Object.entries(heroes)) {
                    _this.CreateHeroListItem(_this.heroListContainer, hero, values.stats.attributes, values.stats.items, values.stats.steam)
                }
            }

            if(timePassed != null && _this.infoText3 != null) {
                var date = new Date(1970,0,1);
                date.setSeconds(timePassed);
                _this.infoText3.text = date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
            }

            if(units != null && limit != null && _this.infoText2 != null) {
                if(units >= limit && !_this.warningPlayed) {
                    _this.TriggerWarningText()
                    _this.warningPlayed = true
                }

                if(units < limit && _this.warningPlayed) {
                    _this.warningPlayed = false
                    _this.WaveManagerEndScreenFlashing.style.visibility = "collapse"
                    _this.warningCounter = _this.warningCounterDelay
                }

                _this.infoText2.text = units + "/" + limit
            }
        }

        this.OnInitiate = function() {
            _this.containerBGOverlay.style.visibility = "visible"
            _this.containerBGOverlay.style.opacity = "1"
            _this.container.style.visibility = "visible"
            _this.container.style.opacity = "1"
        }

        this.CreateHeroListItem = function(parent, name, attributes, items, steam) {
            const heroListItem = $.CreatePanel("Panel", parent, "WaveManagerEndScreenHeroListItem");
        
            const heroListPlayerContainer = $.CreatePanel("Panel", heroListItem, "WaveManagerEndScreenHeroListItemPlayerContainer");
            const heroListPlayerAvatar = $.CreatePanel("DOTAAvatarImage", heroListPlayerContainer, "WaveManagerEndScreenHeroListItemPlayerAvatar");
            heroListPlayerAvatar.style.width = "20px"
            heroListPlayerAvatar.style.height = "20px"
            heroListPlayerAvatar.style.borderRadius = "4px"
            heroListPlayerAvatar.style.boxShadow = "0 0 6px black"
            heroListPlayerAvatar.steamid = steam

            const heroListPlayerName = $.CreatePanel("DOTAUserName", heroListPlayerContainer, "WaveManagerEndScreenHeroListItemPlayerName");
            heroListPlayerName.steamid = steam

            const heroListImage = $.CreatePanel("DOTAHeroImage", heroListItem, "WaveManagerEndScreenHeroListItemImage");
            heroListImage.heroname = name

            const heroListInfoContainer = $.CreatePanel("Panel", heroListItem, "WaveManagerEndScreenHeroListInfoContainer");
            
            const heroListInfoStats = $.CreatePanel("Panel", heroListInfoContainer, "WaveManagerEndScreenHeroListInfoStats");
            
            const heroListInfoStats_Strength = $.CreatePanel("Label", heroListInfoStats, "WaveManagerEndScreenHeroListInfoStats_Strength");
            heroListInfoStats_Strength.text = attributes.strength

            const heroListInfoStats_Agility = $.CreatePanel("Label", heroListInfoStats, "WaveManagerEndScreenHeroListInfoStats_Agility");
            heroListInfoStats_Agility.text = attributes.agility

            const heroListInfoStats_Intellect = $.CreatePanel("Label", heroListInfoStats, "WaveManagerEndScreenHeroListInfoStats_Intellect");
            heroListInfoStats_Intellect.text = attributes.intellect

            const heroListInfoItems = $.CreatePanel("Panel", heroListInfoContainer, "WaveManagerEndScreenHeroListInfoItems");
            
            let makeItem = function(parent, name) {
                const heroListInfoItem = $.CreatePanel("DOTAItemImage", parent, "WaveManagerEndScreenHeroListInfoItem");
                heroListInfoItem.itemname = name
            }

            items = Object.entries(items)

            if(items.length) {
                for(const [_,item] of items) {
                    makeItem(heroListInfoItems, item)
                }
            } else {
                makeItem(heroListInfoItems, "item_arena_invuln");
            }
        }

        GameEvents.Subscribe("wave_manager_modifier_unit_count", this.OnModifierCounter);
        GameEvents.Subscribe("wave_manager_modifier_unit_endscreen_init", this.OnInitiate);
        
        this.container = $.CreatePanel("Panel", context, "WaveManagerEndScreenContainer");

        this.containerBGOverlay = $.CreatePanel("Panel", context, "WaveManagerEndScreenContainerBG");

        this.container.style.visibility = this.visibility
        this.container.style.opacity = this.opacity
        this.containerBGOverlay.style.visibility = this.visibility
        this.containerBGOverlay.style.opacity = this.opacity

        // Hero List
        this.heroListContainer = $.CreatePanel("Panel", this.container, "WaveManagerEndScreenHeroListContainer");
        
        const heroListContainerHeaderContainer = $.CreatePanel("Panel", this.heroListContainer, "heroListContainerHeaderContainer");
        const heroListContainerHeader = $.CreatePanel("Label", heroListContainerHeaderContainer, "heroListContainerHeader");
        heroListContainerHeader.text = "Game Stats"

        // Enemies Killed
        const list = $.CreatePanel("Panel", this.container, "WaveManagerEndScreenList")

        const label = $.CreatePanel("Panel", list, "WaveManagerEndScreenListLabel")
        const info = $.CreatePanel("Panel", list, "WaveManagerEndScreenListInfo")
        
        const labelText = $.CreatePanel("Label", label, "WaveManagerEndScreenListLabel_Text")
        labelText.text = "Enemies Killed"

        this.infoText = $.CreatePanel("Label", info, "WaveManagerEndScreenListInfo_Text")
        this.infoText.text = "0"

        // Enemies Alive
        const list2 = $.CreatePanel("Panel", this.container, "WaveManagerEndScreenList")

        const label2 = $.CreatePanel("Panel", list2, "WaveManagerEndScreenListLabel")
        const info2 = $.CreatePanel("Panel", list2, "WaveManagerEndScreenListInfo")
        
        const labelText2 = $.CreatePanel("Label", label2, "WaveManagerEndScreenListLabel_Text")
        labelText2.text = "Enemies Alive"

        this.infoText2 = $.CreatePanel("Label", info2, "WaveManagerEndScreenListInfo_Text")
        this.infoText2.text = "0/0"

        // Time Spent
        const list3 = $.CreatePanel("Panel", this.container, "WaveManagerEndScreenList")

        const label3 = $.CreatePanel("Panel", list3, "WaveManagerEndScreenListLabel")
        const info3 = $.CreatePanel("Panel", list3, "WaveManagerEndScreenListInfo")
        
        const labelText3 = $.CreatePanel("Label", label3, "WaveManagerEndScreenListLabel_Text")
        labelText3.text = "Time Passed"

        this.infoText3 = $.CreatePanel("Label", info3, "WaveManagerEndScreenListInfo_Text")
        this.infoText3.text = "0:00"

        // Player Deaths
        const list4 = $.CreatePanel("Panel", this.container, "WaveManagerEndScreenList")

        const label4 = $.CreatePanel("Panel", list4, "WaveManagerEndScreenListLabel")
        const info4 = $.CreatePanel("Panel", list4, "WaveManagerEndScreenListInfo")
        
        const labelText4 = $.CreatePanel("Label", label4, "WaveManagerEndScreenListLabel_Text")
        labelText4.text = "Total Team Deaths"

        this.infoText4 = $.CreatePanel("Label", info4, "WaveManagerEndScreenListInfo_Text")
        this.infoText4.text = "0"

        // Points
        const list5 = $.CreatePanel("Panel", this.container, "WaveManagerEndScreenList")

        const label5 = $.CreatePanel("Panel", list5, "WaveManagerEndScreenListLabel")
        const info5 = $.CreatePanel("Panel", list5, "WaveManagerEndScreenListInfo")
        
        const labelText5 = $.CreatePanel("Label", label5, "WaveManagerEndScreenListLabel_Text")
        labelText5.text = "Your Points Earned"

        this.infoText5 = $.CreatePanel("Label", info5, "WaveManagerEndScreenListInfo_Text")
        this.infoText5.html = true
        this.infoText5.text = "0"

        // DC button
        const heroListContainerDisconnect = $.CreatePanel("Panel", this.container, "heroListContainerDisconnect");
        const heroListContainerDisconnectButton = $.CreatePanel("TextButton", heroListContainerDisconnect, "heroListContainerDisconnectButton");
        heroListContainerDisconnectButton.text = "Disconnect"

        heroListContainerDisconnectButton.SetPanelEvent(
            "onmouseactivate", 
            function(){
                Game.Disconnect()
            }
        )
    }

    return WaveManagerEndScreen;
}());

var ui = new WaveManagerEndScreen($.GetContextPanel());
