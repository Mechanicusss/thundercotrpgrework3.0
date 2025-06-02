var WaveManagerModifierNotification = (function() {
    function WaveManagerModifierNotification(context) {
        var _this = this;

        var mainHud = context.GetParent().GetParent().GetParent()
        var shopHud = mainHud.FindChildTraverse("HUDElements").FindChildTraverse("shop")

        var localID = Players.GetLocalPlayer()
        var lastRememberedHero = Players.GetPlayerHeroEntityIndex(localID)

        this.visibility = "collapse";
        this.opacity = "0";

        this.OnModifierNotification = async function(data) {
            const modifier = data.modifier 
            const image = data.modifierImage

            _this.WaveManagerModifierNotificationContainer.style.visibility = "visible"
            _this.WaveManagerModifierNotificationContainer.style.opacity = "1"

            const container = $.CreatePanel("Panel", _this.WaveManagerModifierNotificationContainer, "WaveManagerModifierNotificationContainer_C");
            const containerSecondary = $.CreatePanel("Panel", container, "WaveManagerModifierNotificationContainer_Secondary_C");

            const modifierImage = $.CreatePanel("Image", containerSecondary, "WaveManagerModifierNotificationContainer_Image");
            modifierImage.SetImage("file://{resources}/images/custom_game/modifiers/"+image+".png")

            const modifierName = $.CreatePanel("Label", containerSecondary, "WaveManagerModifierNotificationContainer_Name");
            modifierName.text = $.Localize("#DOTA_Tooltip_"+modifier)

            const containerDesc = $.CreatePanel("Panel", containerSecondary, "WaveManagerModifierNotificationContainer_Desc_C");
            const modifierDesc = $.CreatePanel("Label", containerDesc, "WaveManagerModifierNotificationContainer_Desc");
            modifierDesc.html = true;

            let descriptionTooltip = $.Localize("#DOTA_Tooltip_"+modifier+"_Description")
            descriptionTooltip = descriptionTooltip.replace('%%%', '%')
            modifierDesc.text = descriptionTooltip

            $.Schedule(8, async function() {
                _this.WaveManagerModifierNotificationContainer.style.visibility = "collapse"
                _this.WaveManagerModifierNotificationContainer.style.opacity = "0"

                $.Schedule(1, async function() {
                    containerSecondary.RemoveAndDeleteChildren();
                    await containerSecondary.DeleteAsync(0);

                    containerDesc.RemoveAndDeleteChildren();
                    await containerDesc.DeleteAsync(0);
                })
            })
        }

        GameEvents.Subscribe("wave_manager_modifier_notification", this.OnModifierNotification);

        const panelParent = mainHud.FindChildTraverse("lower_hud")
        this.WaveManagerModifierNotificationContainer = $.CreatePanel("Panel", context, "WaveManagerModifierNotificationContainer");
        this.WaveManagerModifierNotificationContainer.style.visibility = this.visibility
        this.WaveManagerModifierNotificationContainer.style.opacity = this.opacity
    }

    return WaveManagerModifierNotification;
}());

var ui = new WaveManagerModifierNotification($.GetContextPanel());
