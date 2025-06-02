var WaveManagerCounter = (function() {
    function WaveManagerCounter(context) {
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

            if(killed != null && _this.infoText != null) {
                _this.infoText.text = killed
            }

            if(deaths != null && _this.infoText4 != null) {
                _this.infoText4.text = deaths
            }

            if(timePassed != null && _this.infoText3 != null) {
                var date = new Date(1970,0,1);
                date.setSeconds(timePassed);
                _this.infoText3.text = date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1")
            }

            if(units != null && limit != null && _this.infoText2 != null) {
                if(units >= limit && !_this.warningPlayed) {
                    _this.TriggerWarningText()
                    _this.warningPlayed = true
                }

                if(units < limit && _this.warningPlayed) {
                    _this.warningPlayed = false
                    _this.WaveManagerCounterFlashing.style.visibility = "collapse"
                    _this.warningCounter = _this.warningCounterDelay
                }

                _this.infoText2.text = units + "/" + limit
            }
        }

        this.OnInitiate = function() {
            _this.container.style.visibility = "visible"
            _this.container.style.opacity = "1"

            _this.SeasonalUIContainer.style.visibility = "visible"
            _this.SeasonalUIContainer.style.opacity = "1"
        }

        this.TriggerWarningText = function() {
            _this.WaveManagerCounterFlashing.text = "Too many enemies alive\nYou admit defeat in "+_this.warningCounterDelay+"..."

            Game.EmitSound("TCOTRPG.Waves.Warning.EnemyCount");
            _this.WaveManagerCounterFlashing.style.visibility = "visible"
            _this.warningCounter = _this.warningCounterDelay

            let triggerFunc = function() {
                if(_this.WaveManagerCounterFlashing.style.visibility == "collapse") {
                    _this.warningCounter = _this.warningCounterDelay
                    return
                }

                _this.warningCounter--

                if(_this.warningCounter > 0) {
                    Game.EmitSound("TCOTRPG.Waves.Warning.Tick");
                    _this.WaveManagerCounterFlashing.text = "Too many enemies alive\nYou admit defeat in "+_this.warningCounter+"..."
                } else {
                    _this.WaveManagerCounterFlashing.style.visibility = "collapse"
                    _this.warningCounter = _this.warningCounterDelay;
                }
            }

            for(let i = 1; i <= _this.warningCounterDelay; i++) {
                let timer = $.Schedule(i, triggerFunc)
            }
        }

        // Misc stuff 
        this.ClearMiscElements = async function() {
            const TopBarDireTeamContainer = mainHud.FindChildTraverse("TopBarDireTeam")
            TopBarDireTeamContainer.style.visibility = "collapse";

            const GlyphScanContainer = mainHud.FindChildTraverse("GlyphScanContainer")
            GlyphScanContainer.style.visibility = "collapse";

            const ToggleScoreboardButton = mainHud.FindChildTraverse("ToggleScoreboardButton")
            ToggleScoreboardButton.DeleteAsync(0)

            const RoshanTimerContainer = mainHud.FindChildTraverse("RoshanTimerContainer")
            RoshanTimerContainer.style.visibility = "collapse";

            const inventory_neutral_level_up = mainHud.FindChildTraverse("inventory_neutral_level_up")
            inventory_neutral_level_up.style.visibility = "collapse";

            const inventory_neutral_craft_holder = mainHud.FindChildTraverse("inventory_neutral_craft_holder")
            inventory_neutral_craft_holder.style.visibility = "collapse";

            const ProgressionTalentsPlayerPersonalResetTalentButton = mainHud.FindChildTraverse("ProgressionTalentsPlayerPersonalResetTalentButton")
            ProgressionTalentsPlayerPersonalResetTalentButton.style.visibility = "collapse";

        }

        GameEvents.Subscribe("wave_manager_modifier_unit_count", this.OnModifierCounter);
        GameEvents.Subscribe("wave_manager_modifier_unit_count_init", this.OnInitiate);

        this.container = $.CreatePanel("Panel", context, "WaveManagerCounterContainer");

        this.container.style.visibility = this.visibility
        this.container.style.opacity = this.opacity

        // Enemies Killed
        const list = $.CreatePanel("Panel", this.container, "WaveManagerCounterList")

        const label = $.CreatePanel("Panel", list, "WaveManagerCounterListLabel")
        const info = $.CreatePanel("Panel", list, "WaveManagerCounterListInfo")
        
        const labelText = $.CreatePanel("Label", label, "WaveManagerCounterListLabel_Text")
        labelText.text = "Enemies Killed"

        this.infoText = $.CreatePanel("Label", info, "WaveManagerCounterListInfo_Text")
        this.infoText.text = "0"

        // Enemies Alive
        const list2 = $.CreatePanel("Panel", this.container, "WaveManagerCounterList")

        const label2 = $.CreatePanel("Panel", list2, "WaveManagerCounterListLabel")
        const info2 = $.CreatePanel("Panel", list2, "WaveManagerCounterListInfo")
        
        const labelText2 = $.CreatePanel("Label", label2, "WaveManagerCounterListLabel_Text")
        labelText2.text = "Enemies Alive"

        this.infoText2 = $.CreatePanel("Label", info2, "WaveManagerCounterListInfo_Text")
        this.infoText2.text = "0/0"

        // Time Spent
        const list3 = $.CreatePanel("Panel", this.container, "WaveManagerCounterList")

        const label3 = $.CreatePanel("Panel", list3, "WaveManagerCounterListLabel")
        const info3 = $.CreatePanel("Panel", list3, "WaveManagerCounterListInfo")
        
        const labelText3 = $.CreatePanel("Label", label3, "WaveManagerCounterListLabel_Text")
        labelText3.text = "Time Passed"

        this.infoText3 = $.CreatePanel("Label", info3, "WaveManagerCounterListInfo_Text")
        this.infoText3.text = "0:00"

        // Player Deaths
        const list4 = $.CreatePanel("Panel", this.container, "WaveManagerCounterList")

        const label4 = $.CreatePanel("Panel", list4, "WaveManagerCounterListLabel")
        const info4 = $.CreatePanel("Panel", list4, "WaveManagerCounterListInfo")
        
        const labelText4 = $.CreatePanel("Label", label4, "WaveManagerCounterListLabel_Text")
        labelText4.text = "Total Team Deaths"

        this.infoText4 = $.CreatePanel("Label", info4, "WaveManagerCounterListInfo_Text")
        this.infoText4.text = "0"

        // BIG RED WARNING
        this.WaveManagerCounterFlashing = $.CreatePanel("Label", this.container, "WaveManagerCounterFlashing")
        this.WaveManagerCounterFlashing.text = "Too many enemies alive\nYou admit defeat in "+_this.warningCounterDelay+"..."
        this.WaveManagerCounterFlashing.style.visibility = "collapse"

        // Create the seasonal button thing
        this.difficultyUI = mainHud.FindChildTraverse("topbar")
        
        
        this.SeasonalUIContainer = $.CreatePanel("Panel", context, "SeasonalUIContainer")
        
        this.SeasonalUIContainer.style.visibility = _this.visibility
        this.SeasonalUIContainer.style.opacity = _this.opacity
        
        this.SeasonalEffect = $.CreatePanel("Label", this.SeasonalUIContainer, "SeasonalEffect")
        this.SeasonalEffect.text = $.Localize("#season_effect_title_frenzy")

        this.SeasonalEffect.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", _this.SeasonalEffect, $.Localize("#season_effect_description_frenzy"))
            }
        )

        this.SeasonalEffect.SetPanelEvent(
            "onmouseout", 
            function(){
                $.DispatchEvent("DOTAHideTextTooltip");
            }
        )

        
        context.MoveChildAfter(context, this.difficultyUI)
        this.SeasonalUIContainer.SetParent(this.difficultyUI)

        this.ClearMiscElements()
    }

    return WaveManagerCounter;
}());

var ui = new WaveManagerCounter($.GetContextPanel());
