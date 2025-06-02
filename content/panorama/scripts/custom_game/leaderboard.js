var LeaderboardUI = /** @class */ (function () {
    function LeaderboardUI(panel) {
        var _this = this;
        this.OnLeaderboardFetch = function (res) {
            if (!res) {
                return;
            }
            for (var _i = 0, res_1 = res; _i < res_1.length; _i++) {
                var obj = res_1[_i];
                if (!obj)
                    break;
                if (obj.rank == undefined)
                    break;
                _this.leaderboardArray.push(new PlayerPortrait(_this.container, "#" + obj.rank, obj.steam, obj.steam, obj.points));
            }
            _this.leaderboardArray[0].panel.AddClass("First");
            _this.leaderboardArray[_this.leaderboardArray.length - 1].panel.AddClass("LastPlayer");
        };
        this.OnLeaderboardFetchSelf = function (res) {
            if (!res) {
                return;
            }
            for (var _i = 0, res_2 = res; _i < res_2.length; _i++) {
                var obj = res_2[_i];
                if (!obj)
                    break;
                if (obj.rank == undefined)
                    break;
                var selfP = new PlayerPortrait(_this.headerPanel, "#" + obj.rank, obj.steam, obj.steam, obj.points);
                selfP.panel.AddClass("SelfPortrait");
            }
        };
        this.panel = panel;
        this.container = this.panel.FindChild("Leaderboard");
        this.container.RemoveAndDeleteChildren();
        this.headerPanel = $.CreatePanel("Panel", this.container, "");
        this.headerPanel.BLoadLayoutSnippet("LeaderbordHeader");
        //CustomNetTables.SubscribeNetTableListener("pregame_leaderboard", this.OnLeaderboardFetch);
        CustomNetTables.SubscribeNetTableListener("pregame_leaderboard_self", this.OnLeaderboardFetchSelf);
        //this.OnLeaderboardFetch(null, "game_info", CustomNetTables.GetTableValue("end_game_scoreboard", "game_info"));
        //this.OnLeaderboardFetchSelf(null, "game_info", CustomNetTables.GetTableValue("pregame_leaderboard_self", "game_info"));
        //GameEvents.Subscribe("loading_screen_leaderboard_fetch", (event) => this.OnLeaderboardFetch(event));
        //GameEvents.Subscribe("loading_screen_leaderboard_fetch_self", (event) => this.OnLeaderboardFetchSelf(event));
        this.leaderboardArray = [];
        // ALL players
        $.AsyncWebRequest('http://77.232.143.65/api/leaderboard/all?start=0&end=100', {
            type: 'GET',
            dataType: "json",
            headers: { 'Content-type': 'application/json', 'Accept': 'application/json' },
            contentType: "application/json",
            data: {},
            timeout: 5000,
            success: function (data) {
                _this.OnLeaderboardFetch(data);
            },
            error: function (e) {
                $.Msg(e);
            }
        });
        // ONE Player
        $.AsyncWebRequest('http://77.232.143.65/api/leaderboard/all?target=' + Game.GetLocalPlayerInfo().player_steamid, {
            type: 'GET',
            dataType: "json",
            headers: { 'Content-type': 'application/json', 'Accept': 'application/json' },
            contentType: "application/json",
            data: {},
            timeout: 5000,
            success: function (data) {
                _this.OnLeaderboardFetchSelf(data);
            },
            error: function (e) {
                $.Msg(e);
            }
        });
        $.Msg(panel); // Print the panel
    }
    return LeaderboardUI;
}());
var ui = new LeaderboardUI($.GetContextPanel());
