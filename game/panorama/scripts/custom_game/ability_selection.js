var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var AbilitySelectionUI = /** @class */ (function () {
    // AbilitySelectionUI constructor
    function AbilitySelectionUI(panel) {
        var _this_1 = this;
        this.onAbilityMenuReplace = function (_, _, res) {
            if (!res) {
                return;
            }
            if (res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()))
                return;
            _this_1.panelContainer.RemoveAndDeleteChildren();
            for (var randomName in res.selection) {
                var ability = res.selection[randomName];
                if (_this_1.isValidAbility(ability)) {
                    var changable = _this_1.canAbilityBeChanged(res.changableAbilities, ability);
                    var fnl = new AbilitySelectionContainer(_this_1.panelContainer, ability, res.userEntIndex, 2, res.oldAbility, changable);
                }
            }
            _this_1.panelContainer.style.height = (700 - _this_1.panelContainer.GetParent().FindChildTraverse("AbilitySelectionHeader").contentheight) + "px";
            return;
        };
        this.onAbilityMenuOpen = function (_, _, res) {
            if (!res) {
                return;
            }
            if (res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()))
                return;
            _this_1.container.RemoveAndDeleteChildren();
            _this_1.createHeader();
            _this_1.panelContainer = $.CreatePanel("Panel", _this_1.container, "AbilitySelectionContainer");
            _this_1.panelContainer.RemoveAndDeleteChildren();
            for (var name_1 in res.abilities) {
                var ability = res.abilities[name_1];
                if (_this_1.isValidAbility(ability)) {
                    var ab = new AbilitySelectionContainer(_this_1.panelContainer, ability, res.userEntIndex, 1, null, true);
                }
            }
            return;
        };
        //
        this.onAbilityMenuSwap = function (_, _, res) {
            if (!res) {
                return;
            }
            if (res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()))
                return;
            _this_1.createHeader();
            //this.container.RemoveAndDeleteChildren();
            _this_1.panelContainer = $.CreatePanel("Panel", _this_1.container, "AbilitySelectionContainer");
            _this_1.panelContainer.RemoveAndDeleteChildren();
            _this_1.storedAbilities = [];
            for (var name_2 in res.abilities) {
                var ability = res.abilities[name_2];
                if (_this_1.isValidAbility(ability)) {
                    var ab = new AbilitySelectionContainer(_this_1.panelContainer, ability, res.userEntIndex, 4, null, true);
                    _this_1.storedAbilities.push(ability);
                }
            }
            return;
        };
        this.onAbilityMenuSwapReplace = function (_, _, res) {
            if (!res) {
                return;
            }
            if (res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()))
                return;
            _this_1.createHeader();
            //this.container.RemoveAndDeleteChildren();
            _this_1.panelContainer = $.CreatePanel("Panel", _this_1.container, "AbilitySelectionContainer");
            _this_1.panelContainer.RemoveAndDeleteChildren();
            for (var _i = 0, _a = _this_1.storedAbilities; _i < _a.length; _i++) {
                var name_3 = _a[_i];
                var ability = name_3;
                if (_this_1.isValidAbility(ability)) {
                    var ab = new AbilitySelectionContainer(_this_1.panelContainer, ability, res.userEntIndex, 5, res.oldAbility, true);
                }
            }
            return;
        };
        var _this = this;
        this.panel = panel;
        this.container = this.panel.FindChild("AbilitySelection");
        this.panelContainer = undefined;
        this.heroes = [
            "chicken",
            "timmy",
            "muerta",
            "timbersaw",
            "gun_joe",
            "windranger",
            "alchemist",
            "ancient_apparition",
            "antimage",
            "axe",
            "bane",
            "beastmaster",
            "bloodseeker",
            "chen",
            "crystal_maiden",
            "dark_seer",
            "dazzle",
            "dragon_knight",
            "doom_bringer",
            "doom",
            "drow_ranger",
            "earthshaker",
            "enchantress",
            "enigma",
            "faceless_void",
            "furion",
            "juggernaut",
            "kunkka",
            "leshrac",
            "lich",
            "life_stealer",
            "lina",
            "lion",
            "mirana",
            "morphling",
            "necrolyte",
            "nevermore",
            "night_stalker",
            "omniknight",
            "puck",
            "pudge",
            "pugna",
            "rattletrap",
            "razor",
            "riki",
            "sand_king",
            "shadow_shaman",
            "slardar",
            "sniper",
            "spectre",
            "storm_spirit",
            "sven",
            "tidehunter",
            "tinker",
            "tiny",
            "vengefulspirit",
            "venomancer",
            "viper",
            "weaver",
            "windrunner",
            "witch_doctor",
            "zuus",
            "broodmother",
            "skeleton_king",
            "queenofpain",
            "huskar",
            "jakiro",
            "batrider",
            "warlock",
            "death_prophet",
            "ursa",
            "bounty_hunter",
            "silencer",
            "spirit_breaker",
            "invoker",
            "clinkz",
            "obsidian_destroyer",
            "obsidian",
            "shadow_demon",
            "lycan",
            "lone_druid",
            "brewmaster",
            "phantom_lancer",
            "treant",
            "ogre_magi",
            "chaos_knight",
            "phantom_assassin",
            "gyrocopter",
            "rubick",
            "luna",
            "wisp",
            "disruptor",
            "undying",
            "templar_assassin",
            "naga_siren",
            "nyx_assassin",
            "keeper_of_the_light",
            "visage",
            "meepo",
            "magnataur",
            "centaur",
            "slark",
            "shredder",
            "medusa",
            "troll_warlord",
            "tusk",
            "bristleback",
            "skywrath_mage",
            "elder_titan",
            "abaddon",
            "earth_spirit",
            "ember_spirit",
            "legion_commander",
            "phoenix",
            "terrorblade",
            "techies",
            "oracle",
            "winter_wyvern",
            "arc_warden",
            "abyssal_underlord",
            "underlord",
            "monkey_king",
            "dark_willow",
            "pangolier",
            "grimstroke",
            "mars",
            "snapfire",
            "void_spirit",
            "hoodwink",
            "dawnbreaker",
            "marci",
            "primal_beast",
            "stargazer",
            "zaken",
            "stegius",
            "saitama",
            "hero_akasha",
            "fenrir",
            "asan",
            "saber",
            "gabriel",
            "tanya"
        ];
        this.storedAbilities = [];
        // Load snippet into panel
        CustomNetTables.SubscribeNetTableListener("ability_selection_open", this.onAbilityMenuOpen);
        CustomNetTables.SubscribeNetTableListener("ability_selection_open_replace", this.onAbilityMenuReplace);
        CustomNetTables.SubscribeNetTableListener("ability_selection_swap_position", this.onAbilityMenuSwap);
        CustomNetTables.SubscribeNetTableListener("ability_selection_swap_position_replace", this.onAbilityMenuSwapReplace);
        $.Msg(panel); // Print the panel
    }
    AbilitySelectionUI.prototype.createHeader = function () {
        return __awaiter(this, void 0, void 0, function () {
            var _this, old, ability;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        _this = this;
                        old = this.container.FindChildTraverse("AbilitySelectionHeader");
                        if (!(old != null && old.IsValid())) return [3 /*break*/, 2];
                        old.RemoveAndDeleteChildren();
                        return [4 /*yield*/, old.DeleteAsync(0)];
                    case 1:
                        _a.sent();
                        _a.label = 2;
                    case 2:
                        this.headerPanel = $.CreatePanel("Panel", this.container, "AbilitySelectionHeader");
                        this.header = $.CreatePanel("Label", this.headerPanel, "AbilitySelectionHeaderText");
                        this.header.text = "Ability Selection";
                        ability = $.CreatePanelWithProperties("DOTAAbilityImage", this.headerPanel, "", {
                            "class": "ability_cancel",
                            html: "true",
                            selectionpos: "auto",
                            hittest: "true",
                            hittestchildren: "false",
                            abilityname: "ability_selection_cancel",
                            onmouseover: "DOTAShowAbilityTooltip('ability_selection_cancel')",
                            onmouseout: "DOTAHideAbilityTooltip()"
                        });
                        ability.SetPanelEvent("onactivate", function () {
                            _this.container.RemoveAndDeleteChildren();
                        });
                        return [2 /*return*/];
                }
            });
        });
    };
    AbilitySelectionUI.prototype.isValidAbility = function (name) {
        for (var i = 0; i < this.heroes.length; i++) {
            if (name.startsWith(this.heroes[i])) {
                return true;
            }
        }
        return false;
    };
    AbilitySelectionUI.prototype.canAbilityBeChanged = function (tArray, name) {
        for (var ability in tArray) {
            if (tArray[ability] == name) {
                return true;
            }
        }
        return false;
    };
    return AbilitySelectionUI;
}());
var ui = new AbilitySelectionUI($.GetContextPanel());
