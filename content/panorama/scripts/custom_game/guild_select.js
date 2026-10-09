"use strict";

// Guild selection after the hero is picked. Logic lives on the server (scripts/vscripts/guilds.lua).
// Names and descriptions: "#guild_<id>" and "#guild_<id>_description" in addon_english.txt.
// Keep this file ASCII-only: Russian texts live in resource/addon_english.txt.

var GUILD_NONE = "none";

// Net tables turn Lua arrays into objects { "1": ..., "2": ... }
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
	$.Msg( "[guild_select] loaded" );

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
		card.FindChildTraverse( "GuildJoinLabel" ).text = $.Localize( "#guild_none_join" );

	var join = card.FindChildTraverse( "GuildJoin" );
	join.SetPanelEvent( "onactivate", function ()
	{
		GameEvents.SendCustomGameEventToServer( "guild_select", { guild: guild.id } );
	} );
}

function BuildCards()
{
	$.Msg( "[guild_select] loaded" );

	$( "#GuildCards" ).RemoveAndDeleteChildren();

	ToArray( CustomNetTables.GetTableValue( "guilds", "list" ) ).forEach( CreateCard );
	CreateCard( { id: GUILD_NONE, icon: "" } );
}

// Shown once the player has a hero (or custom hero selection is disabled)
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
	$.Msg( "[guild_select] loaded" );

	CustomNetTables.SubscribeNetTableListener( "guilds", function ( table, key, data )
	{
		if ( key === "list" )
			BuildCards();
	} );

	BuildCards();
	Update();
} )();
