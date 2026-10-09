"use strict";

// Lobby: team selection. Left (blue) half of the art = Radiant, right (red) half = Dire.
// Keep this file ASCII-only: Russian texts live in resource/addon_english.txt (#team_select_*).

var TEAMS = [
	{ id: 2, prefix: "Radiant" }, // DOTA_TEAM_GOODGUYS
	{ id: 3, prefix: "Dire" },    // DOTA_TEAM_BADGUYS
];
var NO_TEAM = 5;                  // DOTA_TEAM_NOTEAM

function SafeCall( name, fn )
{
	try
	{
		fn();
	}
	catch ( e )
	{
		$.Msg( "[team_select] " + name + " failed: " + e );
	}
}

function JoinTeam( teamId )
{
	if ( Game.GetTeamSelectionLocked() )
		return;

	Game.PlayerJoinTeam( teamId );
}

function LeaveTeam()
{
	if ( Game.GetTeamSelectionLocked() )
		return;

	Game.PlayerJoinTeam( NO_TEAM );
}

function FillPlayerList( container, playerIds )
{
	container.RemoveAndDeleteChildren();

	for ( var i = 0; i < playerIds.length; i++ )
	{
		var info = Game.GetPlayerInfo( playerIds[i] );
		if ( !info )
			continue;

		var entry = $.CreatePanel( "Panel", container, "" );
		entry.BLoadLayoutSnippet( "PlayerEntry" );
		entry.FindChildTraverse( "PlayerAvatar" ).steamid = info.player_steamid;
		entry.FindChildTraverse( "PlayerName" ).text = info.player_name;
		entry.SetHasClass( "is_local", !!info.player_is_local );
		entry.SetHasClass( "is_host", !!info.player_has_host_privileges );
	}
}

function UpdateTeams()
{
	for ( var i = 0; i < TEAMS.length; i++ )
	{
		var team = TEAMS[i];
		var details = Game.GetTeamDetails( team.id );

		if ( details )
		{
			$( "#" + team.prefix + "Name" ).text = $.Localize( details.team_name );
			$( "#" + team.prefix + "Count" ).text = details.team_num_players + " / " + details.team_max_players;
		}
		FillPlayerList( $( "#" + team.prefix + "Players" ), Game.GetPlayerIDsOnTeam( team.id ) );
	}

	var unassigned = Game.GetUnassignedPlayerIDs();
	FillPlayerList( $( "#UnassignedPlayers" ), unassigned );
	$( "#UnassignedBlock" ).SetHasClass( "empty", unassigned.length === 0 );

	UpdateButtons();
}

// Highlight own team and enable/disable buttons (depends on lock state, so the timer calls it too)
function UpdateButtons()
{
	var localInfo = Game.GetLocalPlayerInfo();
	var localTeam = localInfo ? localInfo.player_team_id : NO_TEAM;
	var locked = Game.GetTeamSelectionLocked();

	$.GetContextPanel().SetHasClass( "teams_locked", locked );

	for ( var i = 0; i < TEAMS.length; i++ )
	{
		var team = TEAMS[i];
		var details = Game.GetTeamDetails( team.id );
		var isFull = details ? details.team_num_players >= details.team_max_players : false;
		var isLocal = localTeam === team.id;

		$( "#" + team.prefix + "Side" ).SetHasClass( "local_team", isLocal );
		$( "#" + team.prefix + "Side" ).SetHasClass( "team_full", isFull );
		$( "#ArtHalf" + team.prefix ).SetHasClass( "local_team", isLocal );
		$( "#" + team.prefix + "Join" ).enabled = !locked && !isLocal && !isFull;
	}
}

function UpdateHostControls()
{
	var localInfo = Game.GetLocalPlayerInfo();
	var isHost = !!( localInfo && localInfo.player_has_host_privileges );
	var locked = Game.GetTeamSelectionLocked();

	$( "#HostControls" ).SetHasClass( "visible", isHost );
	$( "#LockButton" ).SetHasClass( "hidden", locked );
	$( "#UnlockButton" ).SetHasClass( "hidden", !locked );
	$( "#LockButton" ).enabled = Game.GetUnassignedPlayerIDs().length === 0;
}

function UpdateTimerText()
{
	var transitionTime = Game.GetStateTransitionTime();

	if ( transitionTime >= 0 )
	{
		var seconds = Math.max( 0, Math.floor( transitionTime - Game.GetGameTime() ) );
		$( "#TimerLabel" ).text = String( seconds );
		$( "#TimerCaption" ).text = $.Localize( Game.GetTeamSelectionLocked() ? "#team_select_starting" : "#team_select_countdown" );
		$( "#TimerBlock" ).SetHasClass( "urgent", seconds <= 5 );
	}
	else
	{
		$( "#TimerLabel" ).text = "--";
		$( "#TimerCaption" ).text = $.Localize( "#team_select_waiting_host" );
		$( "#TimerBlock" ).SetHasClass( "urgent", false );
	}
}

function UpdateTimer()
{
	SafeCall( "timer", UpdateTimerText );
	SafeCall( "buttons", UpdateButtons );
	SafeCall( "host controls", UpdateHostControls );
	$.Schedule( 0.1, UpdateTimer );
}

// Host buttons, same as Valve's default team_select
function OnLockAndStartPressed()
{
	if ( Game.GetUnassignedPlayerIDs().length > 0 )
		return;

	Game.SetTeamSelectionLocked( true );
	Game.SetAutoLaunchEnabled( false );
	Game.SetRemainingSetupTime( 4 );
}

function OnCancelAndUnlockPressed()
{
	Game.SetTeamSelectionLocked( false );
	Game.SetRemainingSetupTime( -1 );
}

function BindEvents()
{
	TEAMS.forEach( function ( team )
	{
		var join = function () { JoinTeam( team.id ); };
		$( "#" + team.prefix + "Join" ).SetPanelEvent( "onactivate", join );
		$( "#ArtHalf" + team.prefix ).SetPanelEvent( "onactivate", join );
	} );

	$( "#UnassignedBlock" ).SetPanelEvent( "onactivate", LeaveTeam );
	$( "#AutoAssignButton" ).SetPanelEvent( "onactivate", function () { Game.AutoAssignPlayersToTeams(); } );
	$( "#ShuffleButton" ).SetPanelEvent( "onactivate", function () { Game.ShufflePlayerTeamAssignments(); } );
	$( "#LockButton" ).SetPanelEvent( "onactivate", OnLockAndStartPressed );
	$( "#UnlockButton" ).SetPanelEvent( "onactivate", OnCancelAndUnlockPressed );

	var refresh = function () { SafeCall( "teams", UpdateTeams ); };
	$.RegisterForUnhandledEvent( "DOTAGame_TeamPlayerListChanged", refresh );
	$.RegisterForUnhandledEvent( "DOTAGame_PlayerDetailsChanged", refresh );
}

( function ()
{
	$.Msg( "[team_select] loaded" );

	SafeCall( "bind events", BindEvents );
	SafeCall( "teams", UpdateTeams );
	UpdateTimer();
} )();
