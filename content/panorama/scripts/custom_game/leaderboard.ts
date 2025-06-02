class LeaderboardUI {
    // Instance variables
    panel: Panel;

    constructor(panel: Panel) {
        this.panel = panel;

        this.container = this.panel.FindChild("Leaderboard")
        this.container.RemoveAndDeleteChildren();

        this.headerPanel = $.CreatePanel("Panel", this.container, "");
        this.headerPanel.BLoadLayoutSnippet("LeaderbordHeader");

        //CustomNetTables.SubscribeNetTableListener("pregame_leaderboard", this.OnLeaderboardFetch);
        CustomNetTables.SubscribeNetTableListener("pregame_leaderboard_self", this.OnLeaderboardFetchSelf);

        //this.OnLeaderboardFetch(null, "game_info", CustomNetTables.GetTableValue("end_game_scoreboard", "game_info"));
        //this.OnLeaderboardFetchSelf(null, "game_info", CustomNetTables.GetTableValue("pregame_leaderboard_self", "game_info"));

        //GameEvents.Subscribe("loading_screen_leaderboard_fetch", (event) => this.OnLeaderboardFetch(event));
        //GameEvents.Subscribe("loading_screen_leaderboard_fetch_self", (event) => this.OnLeaderboardFetchSelf(event));

        this.leaderboardArray = []

        // ALL players
        $.AsyncWebRequest( 'http://77.232.143.65/api/leaderboard/all?start=0&end=100',
        {
            type: 'GET',
            dataType : "json",
            headers : { 'Content-type' : 'application/json', 'Accept' : 'application/json'},
            contentType: "application/json",
            data: {},
            timeout : 5000,
            success: (data) =>
            {
                this.OnLeaderboardFetch(data)
            },
            error: function( e )
            {
                $.Msg(e)
            }
        });

        // ONE Player
        $.AsyncWebRequest( 'http://77.232.143.65/api/leaderboard/all?target=' + Game.GetLocalPlayerInfo().player_steamid,
        {
            type: 'GET',
            dataType : "json",
            headers : { 'Content-type' : 'application/json', 'Accept' : 'application/json'},
            contentType: "application/json",
            data: {},
            timeout : 5000,
            success: (data) =>
            {
                this.OnLeaderboardFetchSelf(data)
            },
            error: function( e )
            {
                $.Msg(e)
            }
        });

        $.Msg(panel); // Print the panel
    }

    OnLeaderboardFetch = (res) => {
        if (!res) {
            return
        }

        for(const obj of res) {
            if(!obj) break;
            if(obj.rank == undefined) break;
            this.leaderboardArray.push(new PlayerPortrait(this.container, `#${obj.rank}`, obj.steam, obj.steam, obj.points))
        }

        this.leaderboardArray[0].panel.AddClass("First")
        this.leaderboardArray[this.leaderboardArray.length-1].panel.AddClass("LastPlayer")
    }

    OnLeaderboardFetchSelf = (res) => {
        if (!res) {
            return
        }

        for(const obj of res) {
            if(!obj) break;
            if(obj.rank == undefined) break;

            const selfP = new PlayerPortrait(this.headerPanel, `#${obj.rank}`, obj.steam, obj.steam, obj.points)
            selfP.panel.AddClass("SelfPortrait")
        }
    }
}

let ui = new LeaderboardUI($.GetContextPanel());