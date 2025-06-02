var WavesUI = /** @class */ (function () {
    // WavesUI constructor
    function WavesUI(panel) {
        var _this = this;
        this.onWaveUpdate = function (_, _, res) {
            if (!res || _this.disabled) {
                return;
            }
            var maxWidth = 296;
            if (res.state == 2) {
                _this.wavesBar.RemoveClass("flashing");
                _this.wavesBar.AddClass("counting");
                _this.wavesBar.style.width = ((maxWidth / res.max_interval) * parseInt(res.progress)) + "px";
                _this.wavesBarInfo.text = res.interval + "s";
                _this.wavesCountCurrent.text = res.wave;
            }
            if (res.state == 1) {
                _this.wavesBar.RemoveClass("counting");
                _this.wavesBar.AddClass("flashing");
                _this.wavesBarInfo.text = $.Localize("#waves_preparing");
            }
        };
        this.onWaveDisable = function () {
            _this.disabled = true;
            _this.container.RemoveAndDeleteChildren();
        };
        this.panel = panel;
        this.container = this.panel.FindChild("Waves");
        var panelContainer = $.CreatePanel("Panel", this.container, "");
        this.panelContainer = panelContainer;
        // Load snippet into panel
        panelContainer.BLoadLayoutSnippet("WavesSnippet");
        CustomNetTables.SubscribeNetTableListener("waves", this.onWaveUpdate);
        GameEvents.Subscribe("waves_disable", function (event) { return _this.onWaveDisable(event); });
        //CustomNetTables.SubscribeNetTableListener("waves_disable", this.onWaveDisable);
        // Find components
        this.waves = panelContainer.FindChildTraverse("Waves");
        this.wavesCountCurrent = panelContainer.FindChildTraverse("waves-count-current");
        this.wavesCountCurrent.text = 0;
        this.wavesCountMax = panelContainer.FindChildTraverse("waves-count-max");
        this.wavesCountMax.text = "/57";
        this.wavesCountLabel = panelContainer.FindChildTraverse("waves-count-label");
        this.wavesCountLabel.text = $.Localize("#waves_time_remaining");
        this.wavesBar = panelContainer.FindChildTraverse("waves-bar");
        this.wavesBarInfo = panelContainer.FindChildTraverse("waves-bar-info");
        this.wavesLabel = panelContainer.FindChildTraverse("waves-label");
        this.wavesLabel.text = $.Localize("#waves_label");
        // We add this so it's the default appearance!
        this.wavesBar.AddClass("flashing");
        this.wavesBarInfo.text = $.Localize("#waves_preparing");
        this.disabled = false;
        $.Msg(panel); // Print the panel
    }
    return WavesUI;
}());
var ui = new WavesUI($.GetContextPanel());
