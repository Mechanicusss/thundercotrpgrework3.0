var PlayerBuffSelection = (function() {
    function PlayerBuffSelection(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        var shopHud = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("shop")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.visibility = "collapse"
        this.opacity = "0"

        this.TIME_COUNT = 60
        this.TIME_REMAINING = this.TIME_COUNT
        this.SELECTED_BUFF = null

        this.TimerCountDown = function() {
            _this.TIME_REMAINING = _this.TIME_REMAINING - 1

            _this.selectionContainerTimerText.text = _this.TIME_REMAINING
        }

        this.ActivatePlayerBuff = function(buff) {
            if(buff == null || !buff) return;
            
            var localID = Players.GetLocalPlayer()
            var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

            GameEvents.SendCustomGameEventToServer("player_buffs_activated", {
                unit: lastRememberedHero,
                buff: buff
            })

            _this.playerBuffDisplayContainer.style.visibility = "visible"
            _this.playerBuffDisplayContainer.style.opacity = "1"

            this.SELECTED_BUFF = null
        }

        this.OnConnect = function(data) {
            let old = _this.playerBuffDisplayBodyWrap.Children();
            if (old) {
                old.forEach(async (child) => {
                    if(child.id == "PlayerBuffDisplayBodyItem" || child.id == "PlayerBuffSelectionConfirm") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            const buffs = data.buffs 
            if(buffs) {
                for(const [_,buff] of Object.entries(buffs)) {
                    _this.CreatePlayerBuff_Display(_this.playerBuffDisplayBodyWrap, buff)
                }
            }

            _this.playerBuffDisplayContainer.style.visibility = "visible"
            _this.playerBuffDisplayContainer.style.opacity = "1"
        }
        
        this.OnRandomize = function(data) {
            let buff = data.buff

            if(buff != null) {
                _this.ActivatePlayerBuff(buff)
            }
        }

        this.OnTimerCount = function(data) {
            _this.TimerCountDown()

            if(_this.TIME_REMAINING < 1) {
                _this.container.style.visibility = _this.visibility
                _this.container.style.opacity = _this.opacity
            }
        }

        this.OnActivate = function(data) {
            // Delete old elements first
            let old = _this.selectionContainer.Children();
            if (old) {
                old.forEach(async (child) => {
                    if(child.id == "PlayerBuffSelectionContainerBuff") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            _this.playerBuffSelectionReroll.text = `Reroll (3)`
            _this.TIME_REMAINING = _this.TIME_COUNT
            _this.selectionContainerTimerText.text = _this.TIME_REMAINING

            // Load new elements
            let buffs = data.buffs 

            if(buffs != null) {
                for(const [k, buff] of Object.entries(buffs)) {
                    _this.CreatePlayerBuff(_this.selectionContainer, buff)
                }
            }

            _this.container.style.visibility = "visible"
            _this.container.style.opacity = "1"
        }

        this.OnReroll = function(data) {
            // Delete old elements first
            let old = _this.selectionContainer.Children();
            if (old) {
                old.forEach(async (child) => {
                    if(child.id == "PlayerBuffSelectionContainerBuff") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            _this.SELECTED_BUFF = null

            // Load new elements
            let buffs = data.buffs 
            let count = data.remaining 

            if(count != null) {
                _this.playerBuffSelectionReroll.text = `Reroll (${count})`
            }

            if(buffs != null) {
                for(const [k, buff] of Object.entries(buffs)) {
                    _this.CreatePlayerBuff(_this.selectionContainer, buff)
                }
            }
        }

        this.CreatePlayerBuff = function(container, buff) {
            this.playerBuff = $.CreatePanel("Panel", container, "PlayerBuffSelectionContainerBuff");
            this.playerBuffImage = $.CreatePanel("Image", this.playerBuff, "PlayerBuffSelectionContainerBuffImage");
            this.playerBuffImage.SetImage("file://{resources}/images/custom_game/player_buffs/"+buff+".png")

            this.playerBuffTextContainer = $.CreatePanel("Panel", this.playerBuff, "PlayerBuffSelectionContainerBuffTextContainer");
            this.playerBuffName = $.CreatePanel("Label", this.playerBuffTextContainer, "PlayerBuffSelectionContainerBuffName");
            this.playerBuffName.text = $.Localize("#DOTA_Tooltip_"+buff)
            this.playerBuffDesc = $.CreatePanel("Label", this.playerBuffTextContainer, "PlayerBuffSelectionContainerBuffDesc");
            
            let description = $.Localize("#DOTA_Tooltip_"+buff+"_Description").replace('%%%', '%')
            this.playerBuffDesc.text = description

            const btn = this.playerBuff

            this.playerBuff.SetPanelEvent(
                "onactivate", 
                function(){
                    let old = container.Children();
                    if (old) {
                        old.forEach(async (child) => {
                            if(child.id == "PlayerBuffSelectionContainerBuff") {
                                child.RemoveClass("selected")
                            }
                        });
                    }

                    btn.AddClass("selected")
                    
                    _this.SELECTED_BUFF = buff
                }
            )
        }

        this.CreatePlayerBuff_Display = function(container, buff) {
            this.playerBuffDisplayBodyItem = $.CreatePanel("Panel", container, "PlayerBuffDisplayBodyItem")
            this.playerBuffDisplayBodyItemImage = $.CreatePanel("Image", this.playerBuffDisplayBodyItem, "PlayerBuffDisplayBodyItemImage")
            this.playerBuffDisplayBodyItemImage.SetImage("file://{resources}/images/custom_game/player_buffs/"+buff+".png")

            this.playerBuffDisplayBodyItemImage.SetPanelEvent(
                "onmouseover", 
                function(){
                    const info = "<b>"+$.Localize("#DOTA_Tooltip_"+buff)+"</b><br>"+$.Localize("#DOTA_Tooltip_"+buff+"_Description")
                    $.DispatchEvent("DOTAShowTextTooltip", _this.playerBuffDisplayBodyItemImage, info);
                }
            )

            this.playerBuffDisplayBodyItemImage.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip", _this.playerBuffDisplayBodyItemImage);
                }
            )

            this.playerBuffDisplayBodyItemImage.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    if(!GameUI.IsAltDown()) return 

                    var localID = Players.GetLocalPlayer()
                    var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                    GameEvents.SendCustomGameEventToServer("player_buffs_chat_notify", {
                        unit: lastRememberedHero,
                        buff: $.Localize("#DOTA_Tooltip_"+buff)
                    })
                }
            )
        }

        GameEvents.Subscribe("player_buff_selection_activate", this.OnActivate);
        GameEvents.Subscribe("player_buff_selection_randomize", this.OnRandomize);
        GameEvents.Subscribe("player_buff_selection_timer_count", this.OnTimerCount);
        GameEvents.Subscribe("player_buff_selection_connect", this.OnConnect);
        GameEvents.Subscribe("player_buff_selection_reroll", this.OnReroll);

        this.container = $.CreatePanel("Panel", context, "PlayerBuffSelectionContainer")

        this.container.style.visibility = this.visibility
        this.container.style.opacity = this.opacity
        
        this.selectionContainer = $.CreatePanel("Panel", this.container, "PlayerBuffSelectionContainerSelection");

        this.selectionContainerInfo = $.CreatePanel("Panel", this.selectionContainer, "PlayerBuffSelectionContainerSelectionInfo");
        
        this.selectionContainerHeaderContainer = $.CreatePanel("Panel", this.selectionContainerInfo, "PlayerBuffSelectionContainerHeaderContainer");
        this.selectionContainerInfoTextHeader = $.CreatePanel("Label", this.selectionContainerHeaderContainer, "PlayerBuffSelectionContainerSelectionInfoTextHeader");
        this.selectionContainerInfoTextHeader.text = $.Localize("#player_buffs_intro_title")
        
        this.selectionContainerInfoText = $.CreatePanel("Label", this.selectionContainerInfo, "PlayerBuffSelectionContainerSelectionInfoText");
        this.selectionContainerInfoText.text = $.Localize("#player_buffs_intro_text")

        this.selectionContainerTimer = $.CreatePanel("Panel", this.selectionContainerHeaderContainer, "PlayerBuffSelectionContainerSelectionTimer");
        this.selectionContainerTimerText = $.CreatePanel("Label", this.selectionContainerTimer, "PlayerBuffSelectionContainerSelectionTimerText");
        this.selectionContainerTimerText.text = this.TIME_REMAINING
        
        // Confirm/Reroll button
        this.playerBuffSelectionButtonContainer = $.CreatePanel("Panel", this.container, "PlayerBuffSelectionButtonContainer")

        this.playerBuffSelectionReroll = $.CreatePanel("Label", this.playerBuffSelectionButtonContainer, "PlayerBuffSelectionReroll")
        this.playerBuffSelectionReroll.text = "Reroll (3)"

        this.playerBuffSelectionReroll.SetPanelEvent(
            "onmouseactivate", 
            function(){
                _this.SELECTED_BUFF = null 

                Game.EmitSound("ui_generic_button_click")
                Game.EmitSound("ui_settings_slide_out")

                var localID = Players.GetLocalPlayer()
                var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

                GameEvents.SendCustomGameEventToServer("player_buffs_reroll", {
                    unit: lastRememberedHero
                })
            }
        )

        this.playerBuffSelectionConfirm = $.CreatePanel("Label", this.playerBuffSelectionButtonContainer, "PlayerBuffSelectionConfirm")
        this.playerBuffSelectionConfirm.text = "Confirm"

        this.playerBuffSelectionConfirm.SetPanelEvent(
            "onmouseactivate", 
            function(){
                if(_this.SELECTED_BUFF == null || !_this.SELECTED_BUFF) return;

                Game.EmitSound("ui_generic_button_click")
                Game.EmitSound("ui_settings_slide_out")
                Game.EmitSound("TCOTRPG.Buffs.Select")

                _this.container.style.visibility = _this.visibility
                _this.container.style.opacity = _this.opacity

                _this.ActivatePlayerBuff(_this.SELECTED_BUFF)
            }
        )

        // Create the list that displays your current buffs
        this.playerBuffDisplayContainer = $.CreatePanel("Panel", context, "PlayerBuffDisplayContainer")
        this.playerBuffDisplayContainer.style.visibility = this.visibility
        this.playerBuffDisplayContainer.style.opacity = this.opacity

        this.playerBuffDisplayHeader = $.CreatePanel("Panel", this.playerBuffDisplayContainer, "PlayerBuffDisplayHeader")
        this.playerBuffDisplayHeaderText = $.CreatePanel("Label", this.playerBuffDisplayHeader, "PlayerBuffDisplayHeaderText")
        this.playerBuffDisplayHeaderText.text = $.Localize("#player_buffs_list_title")

        this.playerBuffDisplayBody = $.CreatePanel("Panel", this.playerBuffDisplayContainer, "PlayerBuffDisplayBody")
        this.playerBuffDisplayBodyWrap = $.CreatePanel("Panel", this.playerBuffDisplayBody, "PlayerBuffDisplayBodyWrap")
    }

    return PlayerBuffSelection;
}());

var ui = new PlayerBuffSelection($.GetContextPanel());
