/* global $, CustomNetTables, Game, DOTATeam_t */

'use strict';

(function () {
  CustomNetTables.SubscribeNetTableListener('end_game_scoreboard', EndScoreboard);
  EndScoreboard(null, 'game_info', CustomNetTables.GetTableValue('end_game_scoreboard', 'game_info'));
})();

function EndScoreboard (table, key, args) {
  if (!args || key !== 'game_info') {
    $.Msg(table)
    $.Msg(args)
    $.Msg(key);
    $.Msg("Could not load end data...");
    return;
  }

  // Hide all other UI
  var MainPanel = $.GetContextPanel().GetParent().GetParent().GetParent().GetParent();
  MainPanel.FindChildTraverse('topbar').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('minimap_container').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('lower_hud').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('HudChat').style.visibility = 'collapse'; // can be useful to keep but in 10v10 panels override on it
  MainPanel.FindChildTraverse('NetGraph').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('quickstats').style.visibility = 'collapse';
  MainPanel.FindChildTraverse('WinLabelContainer').style.visibility = 'collapse';

  // Gather info
  var playerResults = args.players;
  var playersGain = args.playersGain;
  var playersDamageDone = args.damageDone;
  var playersDamageTaken = args.damageTaken;
  var serverInfo = args.info;
  var mapInfo = Game.GetMapInfo();
  var radiantPlayerIds = Game.GetPlayerIDsOnTeam(DOTATeam_t.DOTA_TEAM_GOODGUYS);
  var direPlayerIds = Game.GetPlayerIDsOnTeam(DOTATeam_t.DOTA_TEAM_BADGUYS);

  $.Msg({
    args: args,
    info: {
      map: mapInfo,
      ids1: radiantPlayerIds,
      ids2: direPlayerIds
    }
  });

  // Victory Info text
  var victoryMessage = 'winning_team_name Victory!';
  var victoryMessageLabel = $('#es-victory-info-text');

  if (serverInfo.winner === 2) {
    victoryMessage = victoryMessage.replace('winning_team_name', $.Localize('#DOTA_GoodGuys'));
  } else if (serverInfo.winner === 3) {
    victoryMessage = victoryMessage.replace('winning_team_name', $.Localize('#DOTA_BadGuys'));
  }

  victoryMessageLabel.text = victoryMessage;

  // Load frequently used panels
  // var teamsContainer = $('#es-teams');

  var panels = {
    radiant: $('#es-radiant'),
    dire: $('#es-dire'),
    radiantPlayers: $('#es-radiant-players'),
    direPlayers: $('#es-dire-players')
  };

  // the panorama xml file used for the player lines
  var playerXmlFile = 'file://{resources}/layout/custom_game/multiteam_end_screen_player.xml';

  // sort a player by merging results from server and using getplayerinfo
  var loadPlayer = function (id) {
    var playerInfo = Game.GetPlayerInfo(id);
    var resultInfo = null;
    var xp = null;
    var steamid = null;
    var playerSteamId = playerInfo.player_steamid + '';



    for(const p of JSON.parse(playerResults["1"].Body)) {
      if(p.steam == playerSteamId) {

        resultInfo = p
      }
    }

    return {
      id: id,
      info: playerInfo,
      result: resultInfo,
      xp: xp
    };
  };

  // Load players = sort our data we got from above
  var radiantPlayers = [];
  var direPlayers = [];

  $.Each(radiantPlayerIds, function (id) { radiantPlayers.push(loadPlayer(id)); });
  $.Each(direPlayerIds, function (id) { direPlayers.push(loadPlayer(id)); });

  var createPanelForPlayer = function (player, parent) {
    // Create a new Panel for this player
    var pp = $.CreatePanel('Panel', parent, 'es-player-' + player.id);
    pp.AddClass('es-player');
    pp.BLoadLayout(playerXmlFile, false, false);

    var xpBar = pp.FindChildrenWithClassTraverse('es-player-xp');

    //    $.Msg("Player:");
    //    $.Msg(player);

    var values = {
      name: pp.FindChildInLayoutFile('es-player-name'),
      avatar: pp.FindChildInLayoutFile('es-player-avatar'),
      hero: pp.FindChildInLayoutFile('es-player-hero'),
      desc: pp.FindChildInLayoutFile('es-player-desc'),
      kills: pp.FindChildInLayoutFile('es-player-k'),
      deaths: pp.FindChildInLayoutFile('es-player-d'),
      assists: pp.FindChildInLayoutFile('es-player-a'),
      imr: pp.FindChildInLayoutFile('es-player-imr'),
      gold: pp.FindChildInLayoutFile('es-player-gold'),
      level: pp.FindChildInLayoutFile('es-player-level'),
      damagedone: pp.FindChildInLayoutFile('es-player-damage-done'),
      damagetaken: pp.FindChildInLayoutFile('es-player-damage-taken'),
    };

    var rp = $('#es-player-reward-container');

    var rewards = {
      name: rp.FindChildInLayoutFile('es-player-reward-name'),
      rarity: rp.FindChildInLayoutFile('es-player-reward-rarity'),
      image: rp.FindChildInLayoutFile('es-player-reward-image')
    };

    // Avatar + Hero Image
    values.avatar.steamid = player.info.player_steamid;
    values.hero.heroname = player.info.player_selected_hero;

    // Steam Name + Hero name
    values.name.text = player.info.player_name;
    values.desc.text = $.Localize(player.info.player_selected_hero);

    // Stats
    values.kills.text = player.info.player_kills;
    values.deaths.text = player.info.player_deaths;
    values.assists.text = player.info.player_assists;
    values.gold.text = player.info.player_gold;
    values.level.text = player.info.player_level;
    values.damagedone.text = intToString(playersDamageDone[player.id]);
    values.damagetaken.text = intToString(playersDamageTaken[player.id]);

    const teamID = Players.GetTeam(player.id);
    const winnerTeamID = serverInfo.winner;
    const gain = playersGain[player.id]

    if(player.result != null) {
      if (gain > 0) {
        values.imr.text = (parseInt(player.result.points) + parseInt(gain)) + ' (+'+gain+')';
        values.imr.AddClass('es-text-green');
      } else if(gain == 0) {
        values.imr.text = (parseInt(player.result.points));
        values.imr.AddClass('es-text-white');
      }
      else {
        values.imr.text = (parseInt(player.result.points) + parseInt(gain)) + ' ('+gain+')';
        values.imr.AddClass('es-text-red');
      }
    }
  };

  // Create the panels for the players
  $.Each(radiantPlayers, function (player) {
    createPanelForPlayer(player, panels.radiantPlayers);
  });

  $.Each(direPlayers, function (player) {
    createPanelForPlayer(player, panels.direPlayers);
  });

  // Configure Stats Button, to see this game info automatically created on website
//  $("#es-buttons-stats").SetPanelEvent("onactivate", function () {
//    $.DispatchEvent("DOTADisplayURL", "http://www.dota2imba.org/stats/game/" + serverInfo.gameid);
//  });
}

function intToString(value) {
    /*if(value < 10000) return value;
    var suffixes = ["", "K", "M", "B","T"];
    var suffixNum = Math.floor((""+value).length/3);
    var shortValue = parseInt((suffixNum != 0 ? (value / Math.pow(1000,suffixNum)) : value).toPrecision(2));
    if (shortValue % 1 != 0) {
        shortValue = shortValue.toFixed(1);
    }

    let rr = shortValue+suffixes[suffixNum]
    if(rr == "NaNB") rr = "N/A"
    return rr;*/
  return value.toFixed(0)
}