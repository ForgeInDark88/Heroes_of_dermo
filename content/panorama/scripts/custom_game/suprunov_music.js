"use strict";

// Track picker for Suprunov's ultimate with Aghanim's Scepter.
// Server: scripts/vscripts/abilities/custom_earthquake_bounce.lua
// Keep this file ASCII-only: texts live in the XML.

var TRACKS = [ "chronoshift", "terra", "opa" ];

var current = null; // { ability, menu, deadline }

function ShowMenu( data )
{
	current = {
		ability: data.ability,
		menu: data.menu,
		deadline: Game.GetGameTime() + data.time,
	};
	$( "#MusicMenu" ).SetHasClass( "visible", true );
}

function HideMenu()
{
	current = null;
	$( "#MusicMenu" ).SetHasClass( "visible", false );
}

function PickTrack( track )
{
	if ( !current )
		return;

	GameEvents.SendCustomGameEventToServer( "suprunov_music_pick", {
		ability: current.ability,
		menu: current.menu,
		track: track,
	} );
	HideMenu();
}

function Update()
{
	if ( current )
	{
		var left = current.deadline - Game.GetGameTime();
		if ( left <= 0 )
			HideMenu();
		else
			$( "#MusicTimer" ).text = String( Math.ceil( left ) );
	}

	$.Schedule( 0.1, Update );
}

( function ()
{
	$.Msg( "[suprunov_music] loaded" );

	TRACKS.forEach( function ( track )
	{
		$( "#Track_" + track ).SetPanelEvent( "onactivate", function () { PickTrack( track ); } );
	} );

	GameEvents.Subscribe( "suprunov_music_menu", ShowMenu );
	Update();
} )();
