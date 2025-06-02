var WaveManagerLeaderboardParty = (function() {
    function WaveManagerLeaderboardParty(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        var shopHud = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("shop")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.visibility = "collapse"
        this.opacity = "0"

        this.SELECTED_DIFFICULTY = "easy"
        this.LEADERBOARD_DATA = []

        this.UpdateSelectedButton = function(difficulty) {
            _this.difficultyButton_Easy.RemoveClass("selected")
            _this.difficultyButton_Normal.RemoveClass("selected")
            _this.difficultyButton_Hard.RemoveClass("selected")
            _this.difficultyButton_Impossible.RemoveClass("selected")
            _this.difficultyButton_Hell.RemoveClass("selected")
            _this.difficultyButton_Hardcore.RemoveClass("selected")

            if(difficulty == 1) {
                _this.difficultyButton_Easy.AddClass("selected")
            }

            if(difficulty == 2) {
                _this.difficultyButton_Normal.AddClass("selected")
            }

            if(difficulty == 3) {
                _this.difficultyButton_Hard.AddClass("selected")
            }

            if(difficulty == 4) {
                _this.difficultyButton_Impossible.AddClass("selected")
            }

            if(difficulty == 5) {
                _this.difficultyButton_Hell.AddClass("selected")
            }

            if(difficulty == 6) {
                _this.difficultyButton_Hardcore.AddClass("selected")
            }
        }

        this.TranslateDifficultyToText = function(difficulty) {
            if(difficulty == 1) {
                return "Easy"
            }

            if(difficulty == 2) {
                return "Normal"
            }

            if(difficulty == 3) {
                return "Hard"
            }

            if(difficulty == 4) {
                return "Impossible"
            }

            if(difficulty == 5) {
                return "Hell"
            }

            if(difficulty == 6) {
                return "Hardcore"
            }
        }

        this.UpdateLeaderboardDifficulty = function(difficulty) {
            let old = _this.itemContainer.Children();
            if (old) {
                old.forEach(async (child) => {
                    child.RemoveAndDeleteChildren();
                    await child.DeleteAsync(0);
                });
            }

            // Delete header and remake it...
            _this.difficultyHeader.text = _this.TranslateDifficultyToText(difficulty)
            _this.UpdateSelectedButton(difficulty)

            // stuff
            const dataArray = _this.LEADERBOARD_DATA.filter(f => f.difficulty == difficulty && f.players.length > 1)

            dataArray.sort(function(a, b) {
              return b.points - a.points
            });

            if(dataArray != null) {
                let rank = 0;
                let lastPoints = null;

                let lData = Object.entries(dataArray)
                for(const [i,obj] of lData) {
                    if (obj.points !== lastPoints) {
                        rank++;
                    }

                    lastPoints = obj.points;
                    _this.CreatePlayerItem(obj.steam, obj.points, rank);
                }
            }
        }

        this.ToggleLeaderBoardVisibility = function() {
            _this.container.style.visibility = "visible"
            _this.container.style.opacity = "1"
        }

        this.OnDataFetched = function(data) {
            let old = _this.itemContainer.Children();
            if (old) {
                old.forEach(async (child) => {
                    child.RemoveAndDeleteChildren();
                    await child.DeleteAsync(0);
                });
            }

            let query = JSON.parse(data.leaderboard)
            let dataArray = query.body

            _this.LEADERBOARD_DATA = dataArray

            dataArray = _this.LEADERBOARD_DATA.filter(f => f.difficulty == 2 && f.players.length > 1) // Normal

            dataArray.sort(function(a, b) {
              return b.points - a.points
            });

            if(dataArray != null) {
                let rank = 0;
                let lastPoints = null;

                let lData = Object.entries(dataArray)
                for(const [i,obj] of lData) {
                    if (obj.points !== lastPoints) {
                        rank++;
                    }

                    lastPoints = obj.points;
                    _this.CreatePlayerItem(obj.steam, obj.points, rank);
                }
            }
        }

        this.CreateButton = function() {
            const buttonParent = mainHud.FindChildTraverse("ButtonBar")

            let old = buttonParent.Children();
            if (old) {
                old.forEach(async (child) => {
                    if (child.id == "WaveManagerLeaderboardPartyButtonImage") {
                        child.RemoveAndDeleteChildren();
                        await child.DeleteAsync(0);
                    }
                });
            }

            const image = $.CreatePanel("Button", context, "WaveManagerLeaderboardPartyButtonImage")
            image.SetParent(buttonParent)

            buttonParent.MoveChildAfter(image, buttonParent.FindChildTraverse("SettingsButton"))

            image.SetPanelEvent(
                "onmouseactivate", 
                function(){
                    if(_this.container.style.visibility == "collapse") {
                        _this.ToggleLeaderBoardVisibility()
                        Game.EmitSound("ui_generic_button_click")
                    } else {
                        _this.container.style.visibility = "collapse"
                        _this.container.style.opacity = "0"
                        Game.EmitSound("ui_settings_slide_out")
                        //_this.UpdateSelectedButton(2)
                        _this.UpdateLeaderboardDifficulty(2)
                        _this.difficultyHeader.text = _this.TranslateDifficultyToText(2)
                    }
                }
            )

            image.SetPanelEvent(
                "onmouseover", 
                function(){
                    $.DispatchEvent("DOTAShowTextTooltip", image, $.Localize("#leaderboard_header_party"));
                }
            )

            image.SetPanelEvent(
                "onmouseout", 
                function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                }
            )
        }

        this.CreatePlayerItem = function(steam, points, rank) {
            rank = parseInt(rank)

            // Player item
            const item = $.CreatePanel("Panel", _this.itemContainer, "WaveManagerLeaderboardPartyItem");

            const playerContainer = $.CreatePanel("Panel", item, "WaveManagerLeaderboardPartyItemPlayerContainer");

            const playerImage = $.CreatePanel("DOTAAvatarImage", playerContainer, "WaveManagerLeaderboardPartyItemPlayerImage");
            playerImage.steamid = steam
            playerImage.style.width = "36px";
            playerImage.style.height = "36px";

            const playerRank = $.CreatePanel("Label", playerContainer, "WaveManagerLeaderboardPartyItemPlayerRank");
            playerRank.text = "#"+rank

            const playerName = $.CreatePanel("DOTAUserName", playerContainer, "WaveManagerLeaderboardPartyItemPlayerName");
            playerName.steamid = steam

            const scoreContainer = $.CreatePanel("Panel", item, "WaveManagerLeaderboardPartyItemScoreContainer");
            const score = $.CreatePanel("Label", scoreContainer, "WaveManagerLeaderboardPartyItemScore");
            score.text = points

            if(points < 0) {
                score.style.color = "red"
            }

            if(rank == 1) {
                playerRank.style.color = "#D4AF37"
                playerName.style.color = "#D4AF37"
                score.style.color = "#D4AF37"
            } else if(rank == 2) {
                playerRank.style.color = "#C0C0C0"
                playerName.style.color = "#C0C0C0"
                score.style.color = "#C0C0C0"
            } else if(rank == 3) {
                playerRank.style.color = "#CD7F32"
                playerName.style.color = "#CD7F32"
                score.style.color = "#CD7F32"
            }
        }

        GameEvents.Subscribe("wave_manager_request_leaderboard_data_complete", this.OnDataFetched);

        this.container = $.CreatePanel("Panel", context, "WaveManagerLeaderboardPartyContainer");

        this.container.style.visibility = this.visibility
        this.container.style.opacity = this.opacity

        // Header
        const header = $.CreatePanel("Label", this.container, "WaveManagerLeaderboardPartyHeader");
        header.text = $.Localize("#leaderboard_header_party")

        // Difficulties
        this.difficultyContainer = $.CreatePanel("Panel", this.container, "WaveManagerLeaderboardPartyDifficultyContainer");
        this.difficultyContainerChildren = $.CreatePanel("Panel", this.difficultyContainer, "WaveManagerLeaderboardPartyDifficultyContainerChildren");

        // Easy
        this.difficultyButton_Easy = $.CreatePanel("Button", this.difficultyContainerChildren, "WaveManagerLeaderboardPartyDifficultyButton");
        this.difficultyButton_Easy.AddClass("Easy")
        this.difficultyButton_Easy.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", _this.difficultyButton_Easy, $.Localize("#difficulty_easy"));
            }
        )

        this.difficultyButton_Easy.SetPanelEvent(
            "onmouseout", 
            function(){
                $.DispatchEvent("DOTAHideTextTooltip");
            }
        )

        this.difficultyButton_Easy.SetPanelEvent(
            "onmouseactivate", 
            function(){
                _this.SELECTED_DIFFICULTY = "easy"
                _this.UpdateLeaderboardDifficulty(1)
            }
        )

        // Normal
        this.difficultyButton_Normal = $.CreatePanel("Button", this.difficultyContainerChildren, "WaveManagerLeaderboardPartyDifficultyButton");
        this.difficultyButton_Normal.AddClass("Normal")
        this.difficultyButton_Normal.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", _this.difficultyButton_Normal, $.Localize("#difficulty_normal"));
            }
        )

        this.difficultyButton_Normal.SetPanelEvent(
            "onmouseout", 
            function(){
                $.DispatchEvent("DOTAHideTextTooltip");
            }
        )

        this.difficultyButton_Normal.SetPanelEvent(
            "onmouseactivate", 
            function(){
                _this.SELECTED_DIFFICULTY = "normal"
                _this.UpdateLeaderboardDifficulty(2)
            }
        )

        // Hard
        this.difficultyButton_Hard = $.CreatePanel("Button", this.difficultyContainerChildren, "WaveManagerLeaderboardPartyDifficultyButton");
        this.difficultyButton_Hard.AddClass("Hard")
        this.difficultyButton_Hard.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", _this.difficultyButton_Hard, $.Localize("#difficulty_hard"));
            }
        )

        this.difficultyButton_Hard.SetPanelEvent(
            "onmouseout", 
            function(){
                $.DispatchEvent("DOTAHideTextTooltip");
            }
        )

        this.difficultyButton_Hard.SetPanelEvent(
            "onmouseactivate", 
            function(){
                _this.SELECTED_DIFFICULTY = "hard"
                _this.UpdateLeaderboardDifficulty(3)
            }
        )

        // Impossible
        this.difficultyButton_Impossible = $.CreatePanel("Button", this.difficultyContainerChildren, "WaveManagerLeaderboardPartyDifficultyButton");
        this.difficultyButton_Impossible.AddClass("Impossible")
        this.difficultyButton_Impossible.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", _this.difficultyButton_Impossible, $.Localize("#difficulty_impossible"));
            }
        )

        this.difficultyButton_Impossible.SetPanelEvent(
            "onmouseout", 
            function(){
                $.DispatchEvent("DOTAHideTextTooltip");
            }
        )

        this.difficultyButton_Impossible.SetPanelEvent(
            "onmouseactivate", 
            function(){
                _this.SELECTED_DIFFICULTY = "impossible"
                _this.UpdateLeaderboardDifficulty(4)
            }
        )

        // Hell
        this.difficultyButton_Hell = $.CreatePanel("Button", this.difficultyContainerChildren, "WaveManagerLeaderboardPartyDifficultyButton");
        this.difficultyButton_Hell.AddClass("Hell")
        this.difficultyButton_Hell.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", _this.difficultyButton_Hell, $.Localize("#difficulty_hell"));
            }
        )

        this.difficultyButton_Hell.SetPanelEvent(
            "onmouseout", 
            function(){
                $.DispatchEvent("DOTAHideTextTooltip");
            }
        )

        this.difficultyButton_Hell.SetPanelEvent(
            "onmouseactivate", 
            function(){
                _this.SELECTED_DIFFICULTY = "hell"
                _this.UpdateLeaderboardDifficulty(5)
            }
        )

        // Hardcore
        this.difficultyButton_Hardcore = $.CreatePanel("Button", this.difficultyContainerChildren, "WaveManagerLeaderboardPartyDifficultyButton");
        this.difficultyButton_Hardcore.AddClass("Hardcore")
        this.difficultyButton_Hardcore.SetPanelEvent(
            "onmouseover", 
            function(){
                $.DispatchEvent("DOTAShowTextTooltip", _this.difficultyButton_Hardcore, $.Localize("#difficulty_hardcore"));
            }
        )

        this.difficultyButton_Hardcore.SetPanelEvent(
            "onmouseout", 
            function(){
                $.DispatchEvent("DOTAHideTextTooltip");
            }
        )

        this.difficultyButton_Hardcore.SetPanelEvent(
            "onmouseactivate", 
            function(){
                _this.SELECTED_DIFFICULTY = "hardcore"
                _this.UpdateLeaderboardDifficulty(6)
            }
        )

        // Difficulty Header
        this.difficultyHeader = $.CreatePanel("Label", this.container, "WaveManagerLeaderboardPartyDifficultyHeader");
        this.difficultyHeader.text = "Normal"
        this.UpdateSelectedButton(2)

        this.itemContainer = $.CreatePanel("Panel", this.container, "WaveManagerLeaderboardPartyItemContainer");

        this.CreateButton()

        // Fetch data
        GameEvents.SendCustomGameEventToServer("wave_manager_request_leaderboard_data", {})
    }

    return WaveManagerLeaderboardParty;
}());

var ui = new WaveManagerLeaderboardParty($.GetContextPanel());
