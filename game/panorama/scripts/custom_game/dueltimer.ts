class DuelTimer {
    // Instance variables
    panel: Panel;
    timerLabel: LabelPanel;

    constructor(parent: Panel, timeRemaining: string) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("DuelTimer");

        // Find components
        this.timerLabel = panel.FindChildTraverse("TimeRemaining") as LabelPanel;
        this.diffImage = panel.FindChildTraverse("DiffImage") as Image;
        this.timerDescription = panel.FindChildTraverse("TimeLabel") as LabelPanel;
        /*this.killsNeededLabel = panel.FindChildTraverse("KillsNeeded") as LabelPanel;
        this.radiantKills = panel.FindChildTraverse("RadiantKills") as LabelPanel;
        this.direKills = panel.FindChildTraverse("DireKills") as LabelPanel;*/

        //TopBarRadiantScore
        let TopBarRadiantScore = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("TopBarRadiantScore")
        let TopBarDireScore = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("TopBarDireScore")

        /*this.killsNeededLabel.text = "Kills Needed To Win"

        this.radiantKills.text = ""
        this.direKills.text = ""
        */

        //this.timerDescription.text = "Difficulty"
        this.diffImage.SetImage("file://{resources}/images/custom_game/diff_"+timeRemaining.toLowerCase()+".png")
        this.started = false

        var mainHud = $.GetContextPanel().GetParent().GetParent().GetParent()
        var cParent = mainHud.FindChildTraverse("TopBarDireTeamContainer")

        this.panel.SetParent(cParent);

        //this.timerLabel.text = "—"

        // Set player name label

        //GameEvents.Subscribe("timer_player_death_radiant", (event) => this.OnTimerPlayerDeathRadiant(event));
        //GameEvents.Subscribe("timer_player_death_dire", (event) => this.OnTimerPlayerDeathDire(event));

        let canAlert = true
    }

    FancyTimeFormat(duration:any)
    {   
        // Hours, minutes and seconds
        var hrs:any = ~~(duration / 3600);
        var mins:any = ~~((duration % 3600) / 60);
        var secs:any = ~~duration % 60;

        // Output like "1:01" or "4:03:59" or "123:03:59"
        var ret:any = "";

        if (hrs > 0) {
            ret += "" + hrs + ":" + (mins < 10 ? "0" : "");
        }

        ret += "" + mins + ":" + (secs < 10 ? "0" : "");
        ret += "" + secs;
        return ret;
    }

    ToSeconds(fancy:any) {
        let minutes = parseInt(fancy.split(":")[0])
        let seconds = parseInt(fancy.split(":")[1])

        return (minutes * 60) + seconds
    }

    // Set the health bar to a certain percentage (0-100)
    UpdateTimer(difficulty: String) {
        const sDiff = difficulty.toLowerCase()

        let img = "diff_easy"
        let loca = "#difficulty_easy_info"

        if(sDiff == "normal") {
            img = "diff_normal"
            loca = "#difficulty_normal_info"
        }

        if(sDiff == "hard") {
            img = "diff_hard"
            loca = "#difficulty_hard_info"
        }

        if(sDiff == "hardcore") {
            img = "diff_hardcore"
            loca = "#difficulty_hardcore_info"
        }

        if(sDiff == "hell") {
            img = "diff_hell"
            loca = "#difficulty_infinity_info"
        }

        if(sDiff == "impossible") {
            img = "diff_impossible"
            loca = "#difficulty_impossible_info"
        }
        
        this.timerLabel.text = difficulty
        this.diffImage.SetImage("file://{resources}/images/custom_game/"+img+".png")

        const _diffImage = this.diffImage

        this.diffImage.SetPanelEvent(
          "onmouseover", 
          function(){
            $.DispatchEvent("DOTAShowTextTooltip", _diffImage, $.Localize(loca));
          }
        )

        this.diffImage.SetPanelEvent(
          "onmouseout", 
          function(){
            $.DispatchEvent("DOTAHideTextTooltip");
          }
        )
    }

    OnTimerPlayerDeathRadiant(data: Any) {
        //this.radiantKills.text = `Angels: ${data.killsNeeded}`
    }

    OnTimerPlayerDeathDire(data: Any) {
        //this.direKills.text = `Demons: ${data.killsNeeded}`
    }

    SetTimerLabel(time) {
        this.timerLabel.text = time
    }

    GetTimerLabel() {
        return this.timerLabel.text
    }
}