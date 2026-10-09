"use strict";

// Custom hero selection. Data and logic live on the server (scripts/vscripts/hero_selection.lua);
// this is only the window: net table "hero_selection" -> cards, click -> event to the server.
// Keep this file ASCII-only: Russian texts live in resource/addon_english.txt (#hero_select_*).

var ATTRIBUTES = {
	DOTA_ATTRIBUTE_STRENGTH: { text: "#hero_select_attr_str", cls: "attr_str" },
	DOTA_ATTRIBUTE_AGILITY: { text: "#hero_select_attr_agi", cls: "attr_agi" },
	DOTA_ATTRIBUTE_INTELLECT: { text: "#hero_select_attr_int", cls: "attr_int" },
	DOTA_ATTRIBUTE_ALL: { text: "#hero_select_attr_all", cls: "attr_all" },
};

var TEAM_PICKS = [
	{ id: 2, panel: "#RadiantPicks" },
	{ id: 3, panel: "#DirePicks" },
];

var heroes = [];
var cards = {};
var selectedHero = null;

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

function GetState()
{
	return CustomNetTables.GetTableValue( "hero_selection", "state" ) || {};
}

function GetPicks()
{
	return CustomNetTables.GetTableValue( "hero_selection", "picks" ) || {};
}

function FindHero( name )
{
	for ( var i = 0; i < heroes.length; i++ )
	{
		if ( heroes[i].name === name )
			return heroes[i];
	}
	return null;
}

// Who took which hero: { hero name: playerID }
function GetTakenBy()
{
	var picks = GetPicks();
	var takenBy = {};
	for ( var playerId in picks )
		takenBy[picks[playerId]] = Number( playerId );
	return takenBy;
}

function IsTaken( name )
{
	return !GetState().allow_same && GetTakenBy()[name] !== undefined;
}

function BuildGrid()
{
	heroes = ToArray( CustomNetTables.GetTableValue( "hero_selection", "heroes" ) );

	var grid = $( "#HeroGrid" );
	grid.RemoveAndDeleteChildren();
	cards = {};

	heroes.forEach( function ( hero )
	{
		hero.abilities = ToArray( hero.abilities );

		var card = $.CreatePanel( "Panel", grid, "" );
		card.BLoadLayoutSnippet( "HeroCard" );
		card.FindChildTraverse( "HeroImage" ).heroname = hero.name;
		card.FindChildTraverse( "HeroName" ).text = $.Localize( "#" + hero.name );

		var attribute = ATTRIBUTES[hero.attribute];
		if ( attribute )
			card.AddClass( attribute.cls );

		card.SetPanelEvent( "onactivate", function () { SelectHero( hero.name ); } );
		card.SetPanelEvent( "ondblclick", function () { SelectHero( hero.name ); PickSelected(); } );

		cards[hero.name] = card;
	} );

	if ( heroes.length > 0 && !FindHero( selectedHero ) )
		SelectHero( heroes[0].name );

	UpdatePicks();
}

function SelectHero( name )
{
	var hero = FindHero( name );
	if ( !hero )
		return;

	selectedHero = name;

	for ( var cardName in cards )
		cards[cardName].SetHasClass( "selected", cardName === name );

	$( "#PreviewMovie" ).heroname = name;
	$( "#PreviewName" ).text = $.Localize( "#" + name );

	var attribute = ATTRIBUTES[hero.attribute];
	var attributeLabel = $( "#PreviewAttribute" );
	attributeLabel.text = attribute ? $.Localize( attribute.text ) : "";
	for ( var key in ATTRIBUTES )
		attributeLabel.SetHasClass( ATTRIBUTES[key].cls, attribute === ATTRIBUTES[key] );

	var container = $( "#PreviewAbilities" );
	container.RemoveAndDeleteChildren();

	hero.abilities.forEach( function ( abilityName )
	{
		var image = $.CreatePanel( "DOTAAbilityImage", container, "" );
		image.AddClass( "PreviewAbility" );
		image.abilityname = abilityName;
		image.SetPanelEvent( "onmouseover", function () { $.DispatchEvent( "DOTAShowAbilityTooltip", image, abilityName ); } );
		image.SetPanelEvent( "onmouseout", function () { $.DispatchEvent( "DOTAHideAbilityTooltip", image ); } );
	} );

	UpdatePickButton();
}

function UpdatePickButton()
{
	$( "#PickButton" ).enabled = selectedHero !== null && !IsTaken( selectedHero );
}

function UpdatePicks()
{
	var picks = GetPicks();
	var takenBy = GetTakenBy();
	var allowSame = !!GetState().allow_same;

	for ( var name in cards )
	{
		var card = cards[name];
		var owner = takenBy[name];
		var taken = owner !== undefined;

		card.SetHasClass( "taken", taken && !allowSame );
		card.FindChildTraverse( "TakenBy" ).text = taken ? Players.GetPlayerName( owner ) : "";
	}

	TEAM_PICKS.forEach( function ( team )
	{
		var container = $( team.panel );
		container.RemoveAndDeleteChildren();

		Game.GetPlayerIDsOnTeam( team.id ).forEach( function ( playerId )
		{
			var hero = picks[playerId];
			var entry = $.CreatePanel( "Panel", container, "" );
			entry.BLoadLayoutSnippet( "PickEntry" );
			entry.FindChildTraverse( "PickHero" ).heroname = hero || "";
			entry.FindChildTraverse( "PickPlayer" ).text = Players.GetPlayerName( playerId );
			entry.SetHasClass( "pending", !hero );
			entry.SetHasClass( "is_local", playerId === Players.GetLocalPlayer() );
		} );
	} );

	UpdatePickButton();
}

function PickSelected()
{
	if ( !selectedHero || IsTaken( selectedHero ) )
		return;

	GameEvents.SendCustomGameEventToServer( "hero_selection_pick", { hero: selectedHero } );
}

function PickRandom()
{
	GameEvents.SendCustomGameEventToServer( "hero_selection_random", {} );
}

function Update()
{
	var state = GetState();
	var localId = Players.GetLocalPlayer();
	var visible = state.phase === "picking" && localId >= 0 && GetPicks()[localId] === undefined;

	$( "#HeroSelect" ).SetHasClass( "visible", visible );

	if ( visible )
	{
		var seconds = Math.max( 0, Math.ceil( state.hero_deadline - Game.GetGameTime() ) );
		$( "#HSTimer" ).text = String( seconds );
		$( "#HSTimer" ).SetHasClass( "urgent", seconds <= 10 );
	}

	$.Schedule( 0.1, Update );
}

( function ()
{
	$.Msg( "[hero_select] loaded" );

	$( "#PickButton" ).SetPanelEvent( "onactivate", PickSelected );
	$( "#RandomButton" ).SetPanelEvent( "onactivate", PickRandom );

	CustomNetTables.SubscribeNetTableListener( "hero_selection", function ( table, key, data )
	{
		if ( key === "heroes" )
			BuildGrid();
		else
			UpdatePicks();
	} );

	BuildGrid();
	Update();
} )();
