var AbilitySelectionContainer = /** @class */ (function () {
    function AbilitySelectionContainer(parent, abilityName, userEntIndex, state, oldAbility, changable) {
        // Create new panel
        var panel = $.CreatePanel("Panel", parent, "");
        this.panel = panel;
        // Load snippet into panel
        panel.BLoadLayoutSnippet("AbilitySelection");
        if (state == 1) {
            var ability = $.CreatePanelWithProperties("DOTAAbilityImage", this.panel, "", {
                "class": "ability",
                html: "true",
                selectionpos: "auto",
                hittest: "true",
                hittestchildren: "false",
                abilityname: abilityName,
                onmouseover: "DOTAShowAbilityTooltip('" + abilityName + "')",
                onmouseout: "DOTAHideAbilityTooltip()"
            });
            ability.SetPanelEvent("onactivate", function () {
                GameEvents.SendCustomGameEventToServer("ability_selection_change", { user: userEntIndex, ability: abilityName });
            });
        }
        else if (state == 2) {
            var ability = $.CreatePanelWithProperties("DOTAAbilityImage", this.panel, "", {
                "class": "ability",
                html: "true",
                selectionpos: "auto",
                hittest: "true",
                hittestchildren: "false",
                abilityname: abilityName,
                onmouseover: "DOTAShowAbilityTooltip('" + abilityName + "')",
                onmouseout: "DOTAHideAbilityTooltip()"
            });
            if (changable == false) {
                var warningLabel_1 = $.CreatePanel("Label", this.panel, "AbilitySelectionWarningLabel");
                warningLabel_1.text = "!";
                warningLabel_1.SetPanelEvent("onmouseover", function () {
                    $.DispatchEvent("DOTAShowTextTooltip", warningLabel_1, $.Localize("#ability_selection_ability_replace_warning"));
                });
                warningLabel_1.SetPanelEvent("onmouseout", function () {
                    $.DispatchEvent("DOTAHideTextTooltip");
                });
            }
            ability.SetPanelEvent("onactivate", function () {
                GameEvents.SendCustomGameEventToServer("ability_selection_change_final", { user: userEntIndex, ability: abilityName, oldAbility: oldAbility });
                panel.GetParent().GetParent().RemoveAndDeleteChildren();
            });
        }
        else if (state == 4) {
            var ability = $.CreatePanelWithProperties("DOTAAbilityImage", this.panel, "", {
                "class": "ability",
                html: "true",
                selectionpos: "auto",
                hittest: "true",
                hittestchildren: "false",
                abilityname: abilityName,
                onmouseover: "DOTAShowAbilityTooltip('" + abilityName + "')",
                onmouseout: "DOTAHideAbilityTooltip()"
            });
            ability.SetPanelEvent("onactivate", function () {
                GameEvents.SendCustomGameEventToServer("ability_selection_swap_position_final", { user: userEntIndex, ability: abilityName });
                panel.GetParent().GetParent().RemoveAndDeleteChildren();
            });
        }
        else if (state == 5) {
            var ability = $.CreatePanelWithProperties("DOTAAbilityImage", this.panel, "", {
                "class": "ability",
                html: "true",
                selectionpos: "auto",
                hittest: "true",
                hittestchildren: "false",
                abilityname: abilityName,
                onmouseover: "DOTAShowAbilityTooltip('" + abilityName + "')",
                onmouseout: "DOTAHideAbilityTooltip()"
            });
            ability.SetPanelEvent("onactivate", function () {
                GameEvents.SendCustomGameEventToServer("ability_selection_swap_position_final_complete", { user: userEntIndex, ability: abilityName, oldAbility: oldAbility });
                panel.GetParent().GetParent().RemoveAndDeleteChildren();
            });
        }
    }
    return AbilitySelectionContainer;
}());
