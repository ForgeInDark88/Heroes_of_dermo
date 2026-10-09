"use strict";

// Лобби: выбор стороны. Левая (синяя) половина картинки — Radiant, правая (красная) — Dire.

var TEAMS = [
	{ id: DOTATeam_t.DOTA_TEAM_GOODGUYS, prefix: "Radiant" },
	{ id: DOTATeam_t.DOTA_TEAM_BADGUYS, prefix: "Dire" },
];

function JoinTeam( teamId )
{
	if ( Game.GetTeamSelectionLocked() )
		return;

	Game.PlayerJoinTeam( teamId );
	Game.EmitSound( "ui_team_select_pick_team" );
}

function LeaveTeam()
{
	if ( Game.GetTeamSelectionLocked() )
		return;

	Game.PlayerJoinTeam( DOTATeam_t.DOTA_TEAM_NOTEAM );
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
		entry.SetHasClass( "is_local", info.player_is_local );
		entry.SetHasClass( "is_host", info.player_has_host_privileges );
	}
}

function UpdateTeams()
{
	for ( var i = 0; i < TEAMS.length; i++ )
	{
		var team = TEAMS[i];
		var details = Game.GetTeamDetails( team.id );

		$( "#" + team.prefix + "Name" ).text = $.Localize( details.team_name );
		$( "#" + team.prefix + "Count" ).text = details.team_num_players + " / " + details.team_max_players;
		FillPlayerList( $( "#" + team.prefix + "Players" ), Game.GetPlayerIDsOnTeam( team.id ) );
	}

	FillPlayerList( $( "#UnassignedPlayers" ), Game.GetUnassignedPlayerIDs() );
	$( "#UnassignedBlock" ).SetHasClass( "empty", Game.GetUnassignedPlayerIDs().length === 0 );

	UpdateButtons();
}

// Подсветка своей стороны и доступность кнопок (зависит и от блокировки, поэтому зовётся из таймера)
function UpdateButtons()
{
	var localInfo = Game.GetLocalPlayerInfo();
	var localTeam = localInfo ? localInfo.player_team_id : DOTATeam_t.DOTA_TEAM_NOTEAM;
	var locked = Game.GetTeamSelectionLocked();

	$.GetContextPanel().SetHasClass( "teams_locked", locked );

	for ( var i = 0; i < TEAMS.length; i++ )
	{
		var team = TEAMS[i];
		var details = Game.GetTeamDetails( team.id );
		var isFull = details.team_num_players >= details.team_max_players;
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
	var isHost = localInfo && localInfo.player_has_host_privileges;
	var locked = Game.GetTeamSelectionLocked();

	$( "#HostControls" ).SetHasClass( "visible", !!isHost );
	$( "#LockButton" ).SetHasClass( "hidden", locked );
	$( "#UnlockButton" ).SetHasClass( "hidden", !locked );
	$( "#LockButton" ).enabled = Game.GetUnassignedPlayerIDs().length === 0;
}

function UpdateTimer()
{
	var transitionTime = Game.GetStateTransitionTime();

	if ( transitionTime >= 0 )
	{
		var seconds = Math.max( 0, Math.floor( transitionTime - Game.GetGameTime() ) );
		$( "#TimerLabel" ).text = String( seconds );
		$( "#TimerCaption" ).text = Game.GetTeamSelectionLocked() ? "ИГРА НАЧИНАЕТСЯ" : "ДО НАЧАЛА";
		$( "#TimerBlock" ).SetHasClass( "urgent", seconds <= 5 );
	}
	else
	{
		$( "#TimerLabel" ).text = "∞";
		$( "#TimerCaption" ).text = "ЖДЁМ ХОСТА";
		$( "#TimerBlock" ).SetHasClass( "urgent", false );
	}

	UpdateButtons();
	UpdateHostControls();
	$.Schedule( 0.1, UpdateTimer );
}

// Кнопки хоста — как в стандартном team_select от Valve
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

( function ()
{
	for ( var i = 0; i < TEAMS.length; i++ )
	{
		( function ( team )
		{
			var join = function () { JoinTeam( team.id ); };
			$( "#" + team.prefix + "Join" ).SetPanelEvent( "onactivate", join );
			$( "#ArtHalf" + team.prefix ).SetPanelEvent( "onactivate", join );
		} )( TEAMS[i] );
	}

	$( "#UnassignedBlock" ).SetPanelEvent( "onactivate", LeaveTeam );
	$( "#AutoAssignButton" ).SetPanelEvent( "onactivate", function () { Game.AutoAssignPlayersToTeams(); } );
	$( "#ShuffleButton" ).SetPanelEvent( "onactivate", function () { Game.ShufflePlayerTeamAssignments(); } );
	$( "#LockButton" ).SetPanelEvent( "onactivate", OnLockAndStartPressed );
	$( "#UnlockButton" ).SetPanelEvent( "onactivate", OnCancelAndUnlockPressed );

	$.RegisterForUnhandledEvent( "DOTAGame_TeamPlayerListChanged", UpdateTeams );
	$.RegisterForUnhandledEvent( "DOTAGame_PlayerDetailsChanged", UpdateTeams );

	UpdateTeams();
	UpdateTimer();
} )();
