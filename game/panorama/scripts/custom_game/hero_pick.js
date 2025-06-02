
const dotaHud = $.GetContextPanel().GetParent().GetParent().GetParent().GetParent();
var PregameBG = dotaHud.FindChildTraverse("PregameBG");
var Footer = dotaHud.FindChildTraverse("Footer");
var PreMinimapContainer = dotaHud.FindChildTraverse("PreMinimapContainer");
var BottomPanels = dotaHud.FindChildTraverse("BottomPanels");
var RandomButton = dotaHud.FindChildTraverse("RandomButton");
var HeroSimpleDescription = dotaHud.FindChildTraverse("HeroSimpleDescription");
var HeroPickRightColumn = dotaHud.FindChildTraverse("HeroPickRightColumn");
var DireTeamPlayers = dotaHud.FindChildTraverse("DireTeamPlayers");
var HeroPickScreenContents = dotaHud.FindChildTraverse("HeroPickScreenContents");
var GameModeLabel = dotaHud.FindChildTraverse("GameModeLabel");
var Header = dotaHud.FindChildTraverse("Header");
var FriendsAndFoes = dotaHud.FindChildTraverse("FriendsAndFoes");
var RightContainer = dotaHud.FindChildTraverse("RightContainer");
// Проверяем наличие PreMinimapContainer и вызываем InitializeHeroCards
var PreMinimapContainer = dotaHud.FindChildTraverse("PreMinimapContainer");
if (PreMinimapContainer) {
    // Используем $.Schedule для отложенного вызова
    $.Schedule(1, InitializeHeroCards);
}
PregameBG.visible = true;
Footer.visible = false;
RightContainer.visible = false;
PreMinimapContainer.visible = false;
BottomPanels.visible = true;
FriendsAndFoes.visible = false;
RandomButton.visible = true;
HeroSimpleDescription.visible = false;
HeroPickRightColumn.style.height = "570px";
DireTeamPlayers.visible = true;
HeroPickScreenContents.style.position = "0.0px 100.0px 0.0px";
GameModeLabel.visible = false;
Header.style.width = "50%";
Header.style.position = "0.0px 0.0px 0.0px";


PregameBG.style.blur = "gaussian(0)";
PregameBG.style.opacity = "0.5";




(function () {
    GameEvents.Subscribe("hidePregameBGImage", function (data) {
        PregameBG.style.opacity = "0"; // Устанавливаем прозрачность на 0
    });
})();

// Создаем новую панель для изображения
var PregameBGImage = $.CreatePanel("Panel", PregameBG, "PregameBGImage");
// Устанавливаем фоновое изображение для новой панели
PregameBGImage.style.backgroundImage = "url('file://{resources}/images/custom_game/loading_screen/gamemode.png')";
PregameBGImage.style.backgroundSize = "100%"; // Используйте "cover" для заполнения панели
PregameBGImage.style.zIndex = "1"; // Убедитесь, что панель выше других
PregameBGImage.style.width = "100%"; // Ширина 100%
PregameBGImage.style.height = "100%"; // Высота 100%
PregameBGImage.style.opacity = "1";


// Убедитесь, что панель видима
PregameBGImage.visible = true;

// Функция для инициализации HeroCards
function InitializeHeroCards() {
    $.Msg("InitializeHeroCards начал работу.");
    // Находим родительский элемент HeroList
    var GridCategories = dotaHud.FindChildTraverse("GridCategories");
    // var agilityIcon = HeroCategory.find((element) => element.BHasClass("AgilityIcon"));
}

// // Функция для установки отображения текста подсказки
function SetShowText(panel, text) {
    panel.SetPanelEvent('onmouseover', function () {
        $.DispatchEvent('DOTAShowTextTooltip', panel, $.Localize(text));
    });

    panel.SetPanelEvent('onmouseout', function () {
        $.DispatchEvent('DOTAHideTextTooltip', panel);
    });
}

(function () {
    GameEvents.Subscribe("start_hero_cards", function (data) {
        InitializeHeroCards()
        $.Msg("ПОЛУЧИЛ СОБЫТИЕ InitializeHeroCards2222");
    });
})();