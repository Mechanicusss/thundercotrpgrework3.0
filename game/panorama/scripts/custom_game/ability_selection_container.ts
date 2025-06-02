class AbilitySelectionContainer {
    // Instance variables
    panel: Panel;
    timerLabel: LabelPanel;

    constructor(parent: Panel, abilityName: String, userEntIndex: String, state: Number, oldAbility: any, changable: Boolean) {
        // Create new panel
        const panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;

        // Load snippet into panel
        panel.BLoadLayoutSnippet("AbilitySelection");

        if(state == 1) {
            const ability = $.CreatePanelWithProperties("DOTAAbilityImage", this.panel, "", {
                class: "ability",
                html: "true",
                selectionpos: "auto",
                hittest: "true",
                hittestchildren: "false",
                abilityname: abilityName,
                onmouseover: "DOTAShowAbilityTooltip('"+abilityName+"')",
                onmouseout: "DOTAHideAbilityTooltip()"
            });

            ability.SetPanelEvent(
              "onactivate", 
              function(){
                GameEvents.SendCustomGameEventToServer("ability_selection_change", { user: userEntIndex, ability: abilityName })
              }
            )
        } else if(state == 2) {
            const ability = $.CreatePanelWithProperties("DOTAAbilityImage", this.panel, "", {
                class: "ability",
                html: "true",
                selectionpos: "auto",
                hittest: "true",
                hittestchildren: "false",
                abilityname: abilityName,
                onmouseover: "DOTAShowAbilityTooltip('"+abilityName+"')",
                onmouseout: "DOTAHideAbilityTooltip()"
            });

            if(changable == false) {
                const warningLabel = $.CreatePanel("Label", this.panel, "AbilitySelectionWarningLabel");
                warningLabel.text = "!"

                warningLabel.SetPanelEvent(
                  "onmouseover", 
                  function(){
                    $.DispatchEvent("DOTAShowTextTooltip", warningLabel, $.Localize("#ability_selection_ability_replace_warning"));
                  }
                )

                warningLabel.SetPanelEvent(
                  "onmouseout", 
                  function(){
                    $.DispatchEvent("DOTAHideTextTooltip");
                  }
                )
            }

            ability.SetPanelEvent(
              "onactivate", 
              function(){
                GameEvents.SendCustomGameEventToServer("ability_selection_change_final", { user: userEntIndex, ability: abilityName, oldAbility: oldAbility })
                
                panel.GetParent().GetParent().RemoveAndDeleteChildren();
              }
            )
        } else if(state == 4) {
            const ability = $.CreatePanelWithProperties("DOTAAbilityImage", this.panel, "", {
                class: "ability",
                html: "true",
                selectionpos: "auto",
                hittest: "true",
                hittestchildren: "false",
                abilityname: abilityName,
                onmouseover: "DOTAShowAbilityTooltip('"+abilityName+"')",
                onmouseout: "DOTAHideAbilityTooltip()"
            });

            ability.SetPanelEvent(
              "onactivate", 
              function(){
                GameEvents.SendCustomGameEventToServer("ability_selection_swap_position_final", { user: userEntIndex, ability: abilityName })
                panel.GetParent().GetParent().RemoveAndDeleteChildren();
              }
            )
        } else if(state == 5) {
            const ability = $.CreatePanelWithProperties("DOTAAbilityImage", this.panel, "", {
                class: "ability",
                html: "true",
                selectionpos: "auto",
                hittest: "true",
                hittestchildren: "false",
                abilityname: abilityName,
                onmouseover: "DOTAShowAbilityTooltip('"+abilityName+"')",
                onmouseout: "DOTAHideAbilityTooltip()"
            });

            ability.SetPanelEvent(
              "onactivate", 
              function(){
                GameEvents.SendCustomGameEventToServer("ability_selection_swap_position_final_complete", { user: userEntIndex, ability: abilityName, oldAbility: oldAbility })
                panel.GetParent().GetParent().RemoveAndDeleteChildren();
              }
            )
        }
        
    }
}