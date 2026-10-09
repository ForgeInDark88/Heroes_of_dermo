"use strict";

// Выбор гильдии после выбора героя. Логика — на сервере (scripts/vscripts/guilds.lua).
// Названия и описания: "#guild_<id>" и "#guild_<id>_description" в addon_english.txt.

var GUILD_NONE = "none";

// Net table превращает Lua-массивы в объекты { "1": ..., "2": ... }
function ToArray( obj )
{
	var result = [];
	if ( !obj )
		return result;

	var keys = Object.keys( obj ).sort( function ( a, b ) { return Number( a ) - Number( b ); } );
	for ( var i = 0; i < keys.length; i++ )
		result.push( obj[keys[i]] );

	return result;
}

function CreateCard( guild )
{
	var card = $.CreatePanel( "Panel", $( "#GuildCards" ), "" );
	card.BLoadLayoutSnippet( "GuildCard" );
	card.SetHasClass( "no_guild", guild.id === GUILD_NONE );

	var icon = card.FindChildTraverse( "GuildIcon" );
	var image = card.FindChildTraverse( "GuildImage" );
	if ( guild.image )
	{
		image.SetImage( guild.image );
		icon.visible = false;
	}
	else
	{
		icon.abilityname = guild.icon || "";
		image.visible = false;
	}

	card.FindChildTraverse( "GuildName" ).text = $.Localize( "#guild_" + guild.id );
	card.FindChildTraverse( "GuildDescription" ).text = $.Localize( "#guild_" + guild.id + "_description" );

	if ( guild.id === GUILD_NONE )
		card.FindChildTraverse( "GuildJoinLabel" ).text = "ОСТАТЬСЯ ОДНОМУ";

	var join = card.FindChildTraverse( "GuildJoin" );
	join.SetPanelEvent( "onactivate", function ()
	{
		GameEvents.SendCustomGameEventToServer( "guild_select", { guild: guild.id } );
	} );
}

function BuildCards()
{
	$( "#GuildCards" ).RemoveAndDeleteChildren();

	ToArray( CustomNetTables.GetTableValue( "guilds", "list" ) ).forEach( CreateCard );
	CreateCard( { id: GUILD_NONE, icon: "" } );
}

// Окно показывается, когда игрок уже выбрал героя (или свой выбор героя выключен)
function IsHeroChosen( localId )
{
	var heroState = CustomNetTables.GetTableValue( "hero_selection", "state" ) || {};
	if ( heroState.phase !== "waiting" && heroState.phase !== "picking" )
		return true;

	var picks = CustomNetTables.GetTableValue( "hero_selection", "picks" ) || {};
	return picks[localId] !== undefined;
}

function Update()
{
	var state = CustomNetTables.GetTableValue( "guilds", "state" ) || {};
	var players = CustomNetTables.GetTableValue( "guilds", "players" ) || {};
	var localId = Players.GetLocalPlayer();

	var visible = state.phase === "picking" && localId >= 0
		&& players[localId] === undefined && IsHeroChosen( localId );

	$( "#GuildSelect" ).SetHasClass( "visible", visible );

	if ( visible )
	{
		var seconds = Math.max( 0, Math.ceil( state.deadline - Game.GetGameTime() ) );
		$( "#GSTimer" ).text = String( seconds );
		$( "#GSTimer" ).SetHasClass( "urgent", seconds <= 5 );
	}

	$.Schedule( 0.1, Update );
}

( function ()
{
	CustomNetTables.SubscribeNetTableListener( "guilds", function ( table, key, data )
	{
		if ( key === "list" )
			BuildCards();
	} );

	BuildCards();
	Update();
} )();
