interface TimerChangedEvent {
    playerID: PlayerID;
    isDuelActive: boolean;
    duration: number;
    ended: boolean;
}

interface DuelEndEvent {}

class CustomHeroSelectionUI {
    // Instance variables
    panel: Panel;

    // CustomHeroSelectionUI constructor
    constructor(panel: Panel) {
        CustomNetTables.SubscribeNetTableListener("select_custom_hero", this.onSelectCustomHero);
        CustomNetTables.SubscribeNetTableListener("select_custom_hero_open", this.onSelectCustomHeroOpen);

        this.panel = panel;

        this.container = this.panel.FindChild("CustomHeroSelection")
        this.container.RemoveAndDeleteChildren();

        const panelContainer = $.CreatePanel("Panel", this.container, "");
        this.panelContainer = panelContainer;

        this.container.style.visibility = "collapse"

        // Load snippet into panel
        panelContainer.BLoadLayoutSnippet("CustomHeroSelection");

        this.close = this.panelContainer.FindChildTraverse("Close") as LabelPanel;

        this.close.SetPanelEvent(
            "onactivate", 
            () => {
              this.container.style.visibility = "collapse"
            }
          )

        $.Msg(panel); // Print the panel
    }

    onSelectCustomHeroOpen = (_, _, res) => {
      if (!res) {
          return
      }

      if(res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) return

      this.container.style.visibility = "visible"

      return
    }

    onSelectCustomHero = (_, _, res) => {
      if (!res) {
          return
      }

      if(res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) return

      this.container.style.visibility = "collapse"

      return
    }

    function ChangeHero(hero, dummy) {
      const user = Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())
      GameEvents.SendCustomGameEventToServer("select_custom_hero", { user: user, hero: hero, dummy: dummy })
    }
}

let ui = new CustomHeroSelectionUI($.GetContextPanel());