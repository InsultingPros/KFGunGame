class GGLobbyMenu extends UT2k4MainPage;

var	automated	GUIButton			TeamButtons[2];

var automated   moCheckBox			ReadyBox[16];
var automated   KFPlayerReadyBar	PlayerBox[16];
var automated   GUIImage			PlayerPerk[16];
var automated   GUILabel			PlayerVetLabel[16];

var automated   moCheckBox			ReadyBox2[16];
var automated   KFPlayerReadyBar	PlayerBox2[16];
var automated   GUIImage			PlayerPerk2[16];
var automated   GUILabel			PlayerVetLabel2[16];

var automated   KFLobbyChat	t_ChatBox;
var automated   GUILabel	label_TimeOutCounter;
var automated   GUILabel	SpectatorsLabel;

var	bool	bAllowClose;
var	int		ActivateTimeoutTime;    // When was the lobby timeout turned on?
var	bool	bTimeoutTimeLogged;     // Was it already logged once?
var bool	bTimedOut;              // Have we timed out out successfully?
var	bool	bShouldUpdateVeterancy;

// Video Ad
var automated	GUISectionBackground	ADBackground;
var				LobbyMenuAd				LobbyMenuAd;
var				float					VideoTimer;
var				bool					VideoPlayed;

// Localized Strings
var	localized	string	LvAbbrString;
var	localized	string	SelectPerkInformationString;
var	localized	string	WaitingForServerStatus;
var	localized	string	WaitingForOtherPlayers;
var	localized	string	AutoCommence;
var	localized	string	SpectatorsString;

function InitComponent(GUIController MyC, GUIComponent MyO)
{
	local int i;

	super.InitComponent(MyC, MyO);

	LobbyMenuAd = new class'LobbyMenuAd';

	for ( i = 0; i < 16; i++ )
	{
		PlayerPerk[i].WinWidth = PlayerPerk[i].ActualHeight();
		PlayerPerk[i].WinLeft += ((PlayerBox[i].ActualHeight() - PlayerPerk[i].ActualHeight()) / 2) / MyC.ResX;

		PlayerPerk2[i].WinWidth = PlayerPerk2[i].ActualHeight();
		PlayerPerk2[i].WinLeft += ((PlayerBox2[i].ActualHeight() - PlayerPerk2[i].ActualHeight()) / 2) / MyC.ResX;
	}
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
	local int i;
	local bool bVoiceChatKey;
	local array<string> BindKeyNames, LocalizedBindKeyNames;

	Controller.GetAssignedKeys( "VoiceTalk", BindKeyNames, LocalizedBindKeyNames );

	for ( i = 0; i < BindKeyNames.Length; i++ )
	{
		if ( Mid( GetEnum(enum'EInputKey', Key), 3 ) ~= BindKeyNames[i] )
		{
			bVoiceChatKey = true;
			break;
		}
	}

	if ( bVoiceChatKey )
	{
		if ( state == 1 || state == 2 )
		{
			if ( PlayerOwner() != none )
			{
				PlayerOwner().bVoiceTalk = 1;
			}
		}
		else
		{
			if ( PlayerOwner() != none )
			{
				PlayerOwner().bVoiceTalk = 0;
				return false;
			}
		}

		return true;
	}

	return false;
}

function CheckBotButtonAccess();
function UpdateBotSlots();

function ClearChatBox()
{
	t_ChatBox.lb_Chat.SetContent("");
}

function TimedOut()
{
	bTimedOut = true;
	PlayerOwner().ServerRestartPlayer();
	bAllowClose = true;
}

function bool InternalOnPreDraw(Canvas C)
{
	local int i, z, Team1Index, Team2Index;
	local KFGameReplicationInfo KFGRI;
	local PlayerController PC;
	local PlayerReplicationInfo InList[16], InList2[16];
	local bool bWasThere, bShowProfilePage;
	local string SpectatingString;

	PC = PlayerOwner();

	if ( PC == none || PC.Level == none ) // Error?
	{
		return false;
	}

	if ( PC.PlayerReplicationInfo != none && (!PC.PlayerReplicationInfo.bWaitingPlayer || PC.PlayerReplicationInfo.bOnlySpectator) )
	{
		PC.ClientCloseMenu(True,False);
		return false;
	}

	t_Footer.InternalOnPreDraw(C);

   	KFGRI = KFGameReplicationInfo(PC.GameReplicationInfo);

	if ( KFPlayerController(PC) != none && bShouldUpdateVeterancy )
	{
		if ( KFPlayerController(PC).SelectedVeterancy == none )
		{
			bShowProfilePage = true;

			if ( PC.SteamStatsAndAchievements == none )
			{
				if ( PC.Level.NetMode != NM_Client )
				{
	    			PC.SteamStatsAndAchievements = PC.Spawn(PC.default.SteamStatsAndAchievementsClass, PC);
					if ( !PC.SteamStatsAndAchievements.Initialize(PC) )
					{
		            	Controller.OpenMenu(Controller.QuestionMenuClass);
				    	GUIQuestionPage(Controller.TopPage()).SetupQuestion(class'KFMainMenu'.default.UnknownSteamErrorText, QBTN_Ok, QBTN_Ok);
						PC.SteamStatsAndAchievements.Destroy();
						PC.SteamStatsAndAchievements = none;
	    			}
	    			else
	    			{
	    				PC.SteamStatsAndAchievements.OnDataInitialized = OnSteamStatsAndAchievementsReady;
	    			}
	    		}

   				bShowProfilePage = false;
			}
    		else if ( !PC.SteamStatsAndAchievements.bInitialized )
    		{
   				PC.SteamStatsAndAchievements.OnDataInitialized = OnSteamStatsAndAchievementsReady;
   				PC.SteamStatsAndAchievements.GetStatsAndAchievements();
   				bShowProfilePage = false;
    		}

			if ( KFSteamStatsAndAchievements(PC.SteamStatsAndAchievements) != none )
			{
	    		for ( i = 0; i < class'KFGameType'.default.LoadedSkills.Length; i++ )
	    		{
	    			if ( KFSteamStatsAndAchievements(PC.SteamStatsAndAchievements).GetPerkProgress(i) < 0.0 )
	    			{
	    				PC.SteamStatsAndAchievements.OnDataInitialized = OnSteamStatsAndAchievementsReady;
	    				PC.SteamStatsAndAchievements.GetStatsAndAchievements();
				    	bShowProfilePage = false;
	    			}
	    		}
	    	}

			if ( bShowProfilePage )
			{
				OnSteamStatsAndAchievementsReady();
			}
		}
		else if ( PC.SteamStatsAndAchievements != none && PC.SteamStatsAndAchievements.bInitialized )
		{
			KFPlayerController(PC).SendSelectedVeterancyToServer();
		}
	}

	// First fill in non-ready players.
	if ( KFGRI != none )
	{
		for ( i = 0; i < KFGRI.PRIArray.Length; i++ )
		{
			if ( KFGRI.PRIArray[i] == none || KFGRI.PRIArray[i].bReadyToPlay )
			{
				continue;
			}

			if ( KFGRI.PRIArray[i].Team == none || KFGRI.PRIArray[i].bOnlySpectator  )
			{
				if ( SpectatingString != "" )
				{
					SpectatingString $= ", ";
				}

				SpectatingString $= Left(KFGRI.PRIArray[i].PlayerName, 20);

				continue;
			}

			if ( KFGRI.PRIArray[i].Team.TeamIndex == 0 )
			{
				if ( Team1Index >= 16 )
					continue;

				PlayerPerk[Team1Index].Image = none;
				ReadyBox[Team1Index].Checked(false);
				ReadyBox[Team1Index].SetCaption(Left(KFGRI.PRIArray[i].PlayerName, 20));

				if ( KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkill != none )
				{
					PlayerVetLabel[Team1Index].Caption = LvAbbrString @ KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkillLevel;
					PlayerPerk[Team1Index].Image = KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkill.default.OnHUDIcon;
				}

				InList[Team1Index] = KFGRI.PRIArray[i];
				Team1Index++;
			}
			else
			{
				if ( Team2Index >= 16 )
					continue;

				PlayerPerk2[Team2Index].Image = none;
				ReadyBox2[Team2Index].Checked(false);
				ReadyBox2[Team2Index].SetCaption(Left(KFGRI.PRIArray[i].PlayerName, 20));

				if ( KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkill != none )
				{
					PlayerVetLabel2[Team2Index].Caption = LvAbbrString @ KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkillLevel;
					PlayerPerk2[Team2Index].Image = KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkill.default.OnHUDIcon;
				}

				InList2[Team2Index] = KFGRI.PRIArray[i];
				Team2Index++;
			}
		}

		// Then comes rest.
		for ( i = 0; i < KFGRI.PRIArray.Length; i++ )
		{
			if ( KFGRI.PRIArray[i] == none || KFGRI.PRIArray[i].bOnlySpectator || KFGRI.PRIArray[i].Team == none )
			{
				continue;
			}

			bWasThere = false;

			for ( z = 0; z < 16; z++ )
			{
				if ( InList[z] == KFGRI.PRIArray[i] || InList2[z] == KFGRI.PRIArray[i] )
				{
					bWasThere = true;
					break;
				}
			}

			if ( bWasThere )
			{
				continue;
			}

			if ( KFGRI.PRIArray[i].Team == none || KFGRI.PRIArray[i].Team.TeamIndex == 0 )
			{
				if ( Team1Index >= 16 )
					continue;

				PlayerPerk[Team1Index].Image = none;
				ReadyBox[Team1Index].Checked(KFGRI.PRIArray[i].bReadyToPlay);
				ReadyBox[Team1Index].SetCaption(Left(KFGRI.PRIArray[i].PlayerName, 20));

				if ( KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkill != none )
				{
					PlayerVetLabel[Team1Index].Caption = LvAbbrString @ KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkillLevel;
					PlayerPerk[Team1Index].Image = KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkill.default.OnHUDIcon;
				}

				Team1Index++;
			}
			else
			{
				if ( Team2Index >= 16 )
					continue;

				PlayerPerk2[Team2Index].Image = none;
				ReadyBox2[Team2Index].Checked(KFGRI.PRIArray[i].bReadyToPlay);
				ReadyBox2[Team2Index].SetCaption(Left(KFGRI.PRIArray[i].PlayerName, 20));

				if ( KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkill != none )
				{
					PlayerVetLabel2[Team2Index].Caption = LvAbbrString @ KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkillLevel;
					PlayerPerk2[Team2Index].Image = KFPlayerReplicationInfo(KFGRI.PRIArray[i]).ClientVeteranSkill.default.OnHUDIcon;
				}

				Team2Index++;
			}

			if ( KFGRI.PRIArray[i].bReadyToPlay )
			{
				if ( !bTimeoutTimeLogged )
				{
					ActivateTimeoutTime = PC.Level.TimeSeconds;
					bTimeoutTimeLogged = true;
				}
			}
		}
	}

	while( Team1Index < 16 )
	{
		PlayerPerk[Team1Index].Image = none;
		ReadyBox[Team1Index].Checked(False);
		ReadyBox[Team1Index].SetCaption("");
		PlayerVetLabel[Team1Index].Caption = "";
		Team1Index++;
	}

	while( Team2Index < 16 )
	{
		PlayerPerk2[Team2Index].Image = none;
		ReadyBox2[Team2Index].Checked(False);
		ReadyBox2[Team2Index].SetCaption("");
		PlayerVetLabel2[Team2Index].Caption = "";
		Team2Index++;
	}

	SpectatorsLabel.Caption = SpectatorsString @ SpectatingString;

	return false;
}

function bool OnTeam1ButtonClick(GUIComponent Sender)
{
	local PlayerController PC;

	PC = PlayerOwner();

	if ( PC != none )
	{
		PC.ServerChangeTeam(1);
	}

	return true;
}

function bool OnTeam2ButtonClick(GUIComponent Sender)
{
	local PlayerController PC;

	PC = PlayerOwner();

	if ( PC != none )
	{
		PC.ServerChangeTeam(1);
	}

	return true;
}

function bool StopClose(optional bool bCancelled)
{
	ClearChatBox();

	// this is for the OnCanClose delegate
	// can't close now unless done by call to CloseAll,
	// or the bool has been set to true by LobbyFooter
	return false;
}

event Opened(GUIComponent Sender)                   // Called when the Menu Owner is opened
{
	if ( LobbyMenuAd == none)
	{
		LobbyMenuAd = new class'LobbyMenuAd';
	}

	bShouldUpdateVeterancy = true;
	SetTimer(1,true);
	VideoTimer = 0.0;
	VideoPlayed = false;
}

function InternalOnClosed(bool bCancelled)
{
	if ( PlayerOwner() != none)
	{
		PlayerOwner().Advertising_ExitZone();
	}

	if ( LobbyMenuAd != none )
	{
		LobbyMenuAd.DestroyMovie();
		LobbyMenuAd = none;
	}
}

event Timer()
{
	local KFGameReplicationInfo KF;

	if ( PlayerOwner().PlayerReplicationInfo.bOnlySpectator )
	{
		label_TimeOutCounter.caption = "You are a spectator.";
		Return;
	}

	KF = KFGameReplicationInfo(PlayerOwner().GameReplicationInfo);

	if ( KF == none )
	{
		label_TimeOutCounter.caption = WaitingForServerStatus;
	}
//	else if ( KF.LobbyTimeout <= 0 )
//	{
		label_TimeOutCounter.caption = WaitingForOtherPlayers;
//	}
//	else
//	{
//		label_TimeOutCounter.caption = AutoCommence$":" @ KF.LobbyTimeout;
//	}
}

function DrawAd(Canvas Canvas)
{
	local float X;
	local AdAsset.AdAssetState adState;
	local bool bFocused;

	bFocused = Controller.ActivePage == self;

	if ( bFocused )
	{
		VideoTimer += Controller.RenderDelta;
	}
	else
	{
		if ( LobbyMenuAd == None || !LobbyMenuAd.MenuMovie.IsPlaying() )
		{
			VideoTimer = 0.0;
		}

		VideoPlayed = false;
	}

	if ( bFocused && LobbyMenuAd != none )
	{
		Canvas.SetPos(0.349700 * Canvas.ClipX + 5, 0.037343 * Canvas.ClipY + 30);
		X = Canvas.ClipX / 1024; // X & Y scale

		AdBackground.WinWidth = 320 * X + 10;
		AdBackground.WinHeight = 240 * X + 37;

		// refresh state from ad
		VideoPlayed = LobbyMenuAd.HasBeenDisplayed();

		adState = LobbyMenuAd.GetState();
		if (adState == 2) // ADASSET_STATE_DOWNLOADED
		{
			if ( !VideoPlayed && !LobbyMenuAd.MenuMovie.IsPlaying() )
			{
				// Start video
				VideoPlayed = true;
				LobbyMenuAd.MenuMovie.Play(false);
			}

			// Hold on the first frame for 3 seconds so it doesn't
			// Overwhelm the player
			if (VideoTimer < 3.0 )
			{
				LobbyMenuAd.MenuMovie.Pause(true);
			}
			else
			{
				LobbyMenuAd.MenuMovie.Pause(false);

				if (!VideoPlayed)
				{
					VideoPlayed = true;

					// Report interaction on advertisement
					LobbyMenuAd.Displayed();
				}

			}

			Canvas.DrawTile(LobbyMenuAd.MenuMovie, 320 * X, 240 * X,
					0, 0, 320, 240);
		}
		else if (VideoTimer >= 30.0)
		{
			if (!VideoPlayed)
			{
				VideoPlayed = true;

				// Assume it timed out
				// Report interaction on the default advertisement
				LobbyMenuAd.Displayed();
			}
		}
	}
}

function bool ShowPerkMenu(GUIComponent Sender)
{
	if ( PlayerOwner() != none)
	{
		PlayerOwner().ClientOpenMenu("KFGUI.KFProfilePage", false);
	}

	return true;
}

function OnSteamStatsAndAchievementsReady()
{
	Controller.OpenMenu("KFGUI.KFProfilePage");

	Controller.OpenMenu(Controller.QuestionMenuClass);
	GUIQuestionPage(Controller.TopPage()).SetupQuestion(SelectPerkInformationString, QBTN_Ok, QBTN_Ok);
}

defaultproperties
{
     Begin Object Class=GUIButton Name=Team1Button
         Caption="Green Team"
         Hint="Click to join Green Team"
         WinTop=0.001000
         WinLeft=0.102422
         WinWidth=0.120000
         WinHeight=0.033203
         RenderWeight=2.000000
         TabOrder=4
         bBoundToParent=True
         ToolTip=None

         OnClick=GGLobbyMenu.OnTeam1ButtonClick
         OnKeyEvent=Team1Button.InternalOnKeyEvent
     End Object
     TeamButtons(0)=GUIButton'KFGunGame.GGLobbyMenu.Team1Button'

     Begin Object Class=GUIButton Name=Team2Button
         Caption="Blue Team"
         Hint="Click to join Blue Team"
         WinTop=0.001000
         WinLeft=0.762695
         WinWidth=0.120000
         WinHeight=0.033203
         RenderWeight=2.000000
         TabOrder=4
         bBoundToParent=True
         ToolTip=None

         OnClick=GGLobbyMenu.OnTeam2ButtonClick
         OnKeyEvent=Team2Button.InternalOnKeyEvent
     End Object
     TeamButtons(1)=GUIButton'KFGunGame.GGLobbyMenu.Team2Button'

     Begin Object Class=moCheckBox Name=ReadyBox0
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox0.InternalOnCreateComponent
         WinTop=0.047500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(0)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox0'

     Begin Object Class=moCheckBox Name=ReadyBox1
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME2"
         LabelColor=(B=0)
         OnCreateComponent=ReadyBox1.InternalOnCreateComponent
         WinTop=0.092500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(1)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox1'

     Begin Object Class=moCheckBox Name=ReadyBox012
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME3"
         LabelColor=(B=0)
         OnCreateComponent=ReadyBox012.InternalOnCreateComponent
         WinTop=0.137500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.048000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(2)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox012'

     Begin Object Class=moCheckBox Name=ReadyBox3
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME4"
         LabelColor=(B=0)
         OnCreateComponent=ReadyBox3.InternalOnCreateComponent
         WinTop=0.182500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(3)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox3'

     Begin Object Class=moCheckBox Name=ReadyBox4
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME5"
         LabelColor=(B=0)
         OnCreateComponent=ReadyBox4.InternalOnCreateComponent
         WinTop=0.227500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(4)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox4'

     Begin Object Class=moCheckBox Name=ReadyBox5
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME6"
         LabelColor=(B=0)
         OnCreateComponent=ReadyBox5.InternalOnCreateComponent
         WinTop=0.272500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(5)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox5'

     Begin Object Class=moCheckBox Name=ReadyBox6
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox6.InternalOnCreateComponent
         WinTop=0.317500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(6)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox6'

     Begin Object Class=moCheckBox Name=ReadyBox7
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox7.InternalOnCreateComponent
         WinTop=0.362500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(7)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox7'

     Begin Object Class=moCheckBox Name=ReadyBox8
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox8.InternalOnCreateComponent
         WinTop=0.407500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(8)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox8'

     Begin Object Class=moCheckBox Name=ReadyBox9
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox9.InternalOnCreateComponent
         WinTop=0.452500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(9)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox9'

     Begin Object Class=moCheckBox Name=ReadyBox10
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox10.InternalOnCreateComponent
         WinTop=0.497500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(10)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox10'

     Begin Object Class=moCheckBox Name=ReadyBox11
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox11.InternalOnCreateComponent
         WinTop=0.542500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(11)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox11'

     Begin Object Class=moCheckBox Name=ReadyBox12
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox12.InternalOnCreateComponent
         WinTop=0.587500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(12)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox12'

     Begin Object Class=moCheckBox Name=ReadyBox13
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox13.InternalOnCreateComponent
         WinTop=0.632500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(13)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox13'

     Begin Object Class=moCheckBox Name=ReadyBox14
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox14.InternalOnCreateComponent
         WinTop=0.677500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(14)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox14'

     Begin Object Class=moCheckBox Name=ReadyBox15
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox15.InternalOnCreateComponent
         WinTop=0.722500
         WinLeft=0.052000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox(15)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox15'

     Begin Object Class=KFPlayerReadyBar Name=Player1BackDrop
         WinTop=0.040000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(0)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player1BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player2BackDrop
         WinTop=0.085000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(1)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player2BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player3BackDrop
         WinTop=0.130000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(2)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player3BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player4BackDrop
         WinTop=0.175000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(3)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player4BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player5BackDrop
         WinTop=0.220000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(4)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player5BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player6BackDrop
         WinTop=0.265000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(5)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player6BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player7BackDrop
         WinTop=0.310000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(6)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player7BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player8BackDrop
         WinTop=0.355000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(7)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player8BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player9BackDrop
         WinTop=0.400000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(8)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player9BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player10BackDrop
         WinTop=0.445000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(9)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player10BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player11BackDrop
         WinTop=0.490000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(10)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player11BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player12BackDrop
         WinTop=0.535000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(11)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player12BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player13BackDrop
         WinTop=0.580000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(12)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player13BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player14BackDrop
         WinTop=0.625000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(13)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player14BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player15BackDrop
         WinTop=0.670000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(14)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player15BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player16BackDrop
         WinTop=0.715000
         WinLeft=0.016250
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox(15)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player16BackDrop'

     Begin Object Class=GUIImage Name=Player1P
         ImageStyle=ISTY_Justified
         WinTop=0.043000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(0)=GUIImage'KFGunGame.GGLobbyMenu.Player1P'

     Begin Object Class=GUIImage Name=Player2P
         ImageStyle=ISTY_Justified
         WinTop=0.088000
         WinLeft=0.017000
         WinWidth=0.045000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(1)=GUIImage'KFGunGame.GGLobbyMenu.Player2P'

     Begin Object Class=GUIImage Name=Player3P
         ImageStyle=ISTY_Justified
         WinTop=0.133000
         WinLeft=0.017000
         WinWidth=0.045000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(2)=GUIImage'KFGunGame.GGLobbyMenu.Player3P'

     Begin Object Class=GUIImage Name=Player4P
         ImageStyle=ISTY_Justified
         WinTop=0.178000
         WinLeft=0.017000
         WinWidth=0.045000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(3)=GUIImage'KFGunGame.GGLobbyMenu.Player4P'

     Begin Object Class=GUIImage Name=Player5P
         ImageStyle=ISTY_Justified
         WinTop=0.223000
         WinLeft=0.017000
         WinWidth=0.045000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(4)=GUIImage'KFGunGame.GGLobbyMenu.Player5P'

     Begin Object Class=GUIImage Name=Player6P
         ImageStyle=ISTY_Justified
         WinTop=0.268000
         WinLeft=0.017000
         WinWidth=0.045000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(5)=GUIImage'KFGunGame.GGLobbyMenu.Player6P'

     Begin Object Class=GUIImage Name=Player7P
         ImageStyle=ISTY_Justified
         WinTop=0.313000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(6)=GUIImage'KFGunGame.GGLobbyMenu.Player7P'

     Begin Object Class=GUIImage Name=Player8P
         ImageStyle=ISTY_Justified
         WinTop=0.358000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(7)=GUIImage'KFGunGame.GGLobbyMenu.Player8P'

     Begin Object Class=GUIImage Name=Player9P
         ImageStyle=ISTY_Justified
         WinTop=0.403000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(8)=GUIImage'KFGunGame.GGLobbyMenu.Player9P'

     Begin Object Class=GUIImage Name=Player10P
         ImageStyle=ISTY_Justified
         WinTop=0.448000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(9)=GUIImage'KFGunGame.GGLobbyMenu.Player10P'

     Begin Object Class=GUIImage Name=Player11P
         ImageStyle=ISTY_Justified
         WinTop=0.493000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(10)=GUIImage'KFGunGame.GGLobbyMenu.Player11P'

     Begin Object Class=GUIImage Name=Player12P
         ImageStyle=ISTY_Justified
         WinTop=0.538000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(11)=GUIImage'KFGunGame.GGLobbyMenu.Player12P'

     Begin Object Class=GUIImage Name=Player13P
         ImageStyle=ISTY_Justified
         WinTop=0.583000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(12)=GUIImage'KFGunGame.GGLobbyMenu.Player13P'

     Begin Object Class=GUIImage Name=Player14P
         ImageStyle=ISTY_Justified
         WinTop=0.628000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(13)=GUIImage'KFGunGame.GGLobbyMenu.Player14P'

     Begin Object Class=GUIImage Name=Player15P
         ImageStyle=ISTY_Justified
         WinTop=0.673000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(14)=GUIImage'KFGunGame.GGLobbyMenu.Player15P'

     Begin Object Class=GUIImage Name=Player16P
         ImageStyle=ISTY_Justified
         WinTop=0.718000
         WinLeft=0.017000
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk(15)=GUIImage'KFGunGame.GGLobbyMenu.Player16P'

     Begin Object Class=GUILabel Name=Player1Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.040000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.500000
     End Object
     PlayerVetLabel(0)=GUILabel'KFGunGame.GGLobbyMenu.Player1Veterancy'

     Begin Object Class=GUILabel Name=Player2Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.085000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.500000
     End Object
     PlayerVetLabel(1)=GUILabel'KFGunGame.GGLobbyMenu.Player2Veterancy'

     Begin Object Class=GUILabel Name=Player3Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.130000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(2)=GUILabel'KFGunGame.GGLobbyMenu.Player3Veterancy'

     Begin Object Class=GUILabel Name=Player4Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.175000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(3)=GUILabel'KFGunGame.GGLobbyMenu.Player4Veterancy'

     Begin Object Class=GUILabel Name=Player5Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.220000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(4)=GUILabel'KFGunGame.GGLobbyMenu.Player5Veterancy'

     Begin Object Class=GUILabel Name=Player6Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.265000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(5)=GUILabel'KFGunGame.GGLobbyMenu.Player6Veterancy'

     Begin Object Class=GUILabel Name=Player7Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.310000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(6)=GUILabel'KFGunGame.GGLobbyMenu.Player7Veterancy'

     Begin Object Class=GUILabel Name=Player8Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.355000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(7)=GUILabel'KFGunGame.GGLobbyMenu.Player8Veterancy'

     Begin Object Class=GUILabel Name=Player9Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.400000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(8)=GUILabel'KFGunGame.GGLobbyMenu.Player9Veterancy'

     Begin Object Class=GUILabel Name=Player10Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.445000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(9)=GUILabel'KFGunGame.GGLobbyMenu.Player10Veterancy'

     Begin Object Class=GUILabel Name=Player11Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.490000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(10)=GUILabel'KFGunGame.GGLobbyMenu.Player11Veterancy'

     Begin Object Class=GUILabel Name=Player12Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.535000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(11)=GUILabel'KFGunGame.GGLobbyMenu.Player12Veterancy'

     Begin Object Class=GUILabel Name=Player13Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.580000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(12)=GUILabel'KFGunGame.GGLobbyMenu.Player13Veterancy'

     Begin Object Class=GUILabel Name=Player14Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.625000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(13)=GUILabel'KFGunGame.GGLobbyMenu.Player14Veterancy'

     Begin Object Class=GUILabel Name=Player15Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.670000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(14)=GUILabel'KFGunGame.GGLobbyMenu.Player15Veterancy'

     Begin Object Class=GUILabel Name=Player16Veterancy
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.715000
         WinLeft=0.129070
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel(15)=GUILabel'KFGunGame.GGLobbyMenu.Player16Veterancy'

     Begin Object Class=moCheckBox Name=ReadyBox20
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox20.InternalOnCreateComponent
         WinTop=0.047500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(0)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox20'

     Begin Object Class=moCheckBox Name=ReadyBox21
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME2"
         LabelColor=(B=0)
         OnCreateComponent=ReadyBox21.InternalOnCreateComponent
         WinTop=0.092500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(1)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox21'

     Begin Object Class=moCheckBox Name=ReadyBox22
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME3"
         LabelColor=(B=0)
         OnCreateComponent=ReadyBox22.InternalOnCreateComponent
         WinTop=0.137500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.048000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(2)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox22'

     Begin Object Class=moCheckBox Name=ReadyBox23
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME4"
         LabelColor=(B=0)
         OnCreateComponent=ReadyBox23.InternalOnCreateComponent
         WinTop=0.182500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(3)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox23'

     Begin Object Class=moCheckBox Name=ReadyBox24
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME5"
         LabelColor=(B=0)
         OnCreateComponent=ReadyBox24.InternalOnCreateComponent
         WinTop=0.227500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(4)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox24'

     Begin Object Class=moCheckBox Name=ReadyBox25
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME6"
         LabelColor=(B=0)
         OnCreateComponent=ReadyBox25.InternalOnCreateComponent
         WinTop=0.272500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(5)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox25'

     Begin Object Class=moCheckBox Name=ReadyBox26
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox26.InternalOnCreateComponent
         WinTop=0.317500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(6)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox26'

     Begin Object Class=moCheckBox Name=ReadyBox27
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox27.InternalOnCreateComponent
         WinTop=0.362500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(7)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox27'

     Begin Object Class=moCheckBox Name=ReadyBox28
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox28.InternalOnCreateComponent
         WinTop=0.407500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(8)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox28'

     Begin Object Class=moCheckBox Name=ReadyBox29
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox29.InternalOnCreateComponent
         WinTop=0.452500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(9)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox29'

     Begin Object Class=moCheckBox Name=ReadyBox210
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox210.InternalOnCreateComponent
         WinTop=0.497500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(10)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox210'

     Begin Object Class=moCheckBox Name=ReadyBox211
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox211.InternalOnCreateComponent
         WinTop=0.542500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(11)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox211'

     Begin Object Class=moCheckBox Name=ReadyBox212
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox212.InternalOnCreateComponent
         WinTop=0.587500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(12)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox212'

     Begin Object Class=moCheckBox Name=ReadyBox213
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox213.InternalOnCreateComponent
         WinTop=0.632500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(13)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox213'

     Begin Object Class=moCheckBox Name=ReadyBox214
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox214.InternalOnCreateComponent
         WinTop=0.677500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(14)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox214'

     Begin Object Class=moCheckBox Name=ReadyBox215
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.820000
         Caption="NAME1"
         LabelStyleName=""
         LabelColor=(B=10,G=10,R=10,A=210)
         OnCreateComponent=ReadyBox215.InternalOnCreateComponent
         WinTop=0.722500
         WinLeft=0.717000
         WinWidth=0.290000
         WinHeight=0.045000
         RenderWeight=0.550000
         bAcceptsInput=False
         bNeverFocus=True
         bAnimating=True
     End Object
     ReadyBox2(15)=moCheckBox'KFGunGame.GGLobbyMenu.ReadyBox215'

     Begin Object Class=KFPlayerReadyBar Name=Player1BackDrop2
         WinTop=0.040000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(0)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player1BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player2BackDrop2
         WinTop=0.085000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(1)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player2BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player3BackDrop2
         WinTop=0.130000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(2)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player3BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player4BackDrop2
         WinTop=0.175000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(3)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player4BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player5BackDrop2
         WinTop=0.220000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(4)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player5BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player6BackDrop2
         WinTop=0.265000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(5)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player6BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player7BackDrop2
         WinTop=0.310000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(6)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player7BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player8BackDrop2
         WinTop=0.355000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(7)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player8BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player9BackDrop2
         WinTop=0.400000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(8)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player9BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player10BackDrop2
         WinTop=0.445000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(9)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player10BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player11BackDrop2
         WinTop=0.490000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(10)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player11BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player12BackDrop2
         WinTop=0.535000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(11)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player12BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player13BackDrop2
         WinTop=0.580000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(12)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player13BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player14BackDrop2
         WinTop=0.625000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(13)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player14BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player15BackDrop2
         WinTop=0.670000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(14)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player15BackDrop2'

     Begin Object Class=KFPlayerReadyBar Name=Player16BackDrop2
         WinTop=0.715000
         WinLeft=0.681253
         WinWidth=0.268750
         WinHeight=0.045000
         RenderWeight=0.350000
     End Object
     PlayerBox2(15)=KFPlayerReadyBar'KFGunGame.GGLobbyMenu.Player16BackDrop2'

     Begin Object Class=GUIImage Name=Player1P2
         ImageStyle=ISTY_Justified
         WinTop=0.043000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(0)=GUIImage'KFGunGame.GGLobbyMenu.Player1P2'

     Begin Object Class=GUIImage Name=Player2P2
         ImageStyle=ISTY_Justified
         WinTop=0.088000
         WinLeft=0.681753
         WinWidth=0.045000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(1)=GUIImage'KFGunGame.GGLobbyMenu.Player2P2'

     Begin Object Class=GUIImage Name=Player3P2
         ImageStyle=ISTY_Justified
         WinTop=0.133000
         WinLeft=0.681753
         WinWidth=0.045000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(2)=GUIImage'KFGunGame.GGLobbyMenu.Player3P2'

     Begin Object Class=GUIImage Name=Player4P2
         ImageStyle=ISTY_Justified
         WinTop=0.178000
         WinLeft=0.681753
         WinWidth=0.045000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(3)=GUIImage'KFGunGame.GGLobbyMenu.Player4P2'

     Begin Object Class=GUIImage Name=Player5P2
         ImageStyle=ISTY_Justified
         WinTop=0.223000
         WinLeft=0.681753
         WinWidth=0.045000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(4)=GUIImage'KFGunGame.GGLobbyMenu.Player5P2'

     Begin Object Class=GUIImage Name=Player6P2
         ImageStyle=ISTY_Justified
         WinTop=0.268000
         WinLeft=0.681753
         WinWidth=0.045000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(5)=GUIImage'KFGunGame.GGLobbyMenu.Player6P2'

     Begin Object Class=GUIImage Name=Player7P2
         ImageStyle=ISTY_Justified
         WinTop=0.313000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(6)=GUIImage'KFGunGame.GGLobbyMenu.Player7P2'

     Begin Object Class=GUIImage Name=Player8P2
         ImageStyle=ISTY_Justified
         WinTop=0.358000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(7)=GUIImage'KFGunGame.GGLobbyMenu.Player8P2'

     Begin Object Class=GUIImage Name=Player9P2
         ImageStyle=ISTY_Justified
         WinTop=0.403000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(8)=GUIImage'KFGunGame.GGLobbyMenu.Player9P2'

     Begin Object Class=GUIImage Name=Player10P2
         ImageStyle=ISTY_Justified
         WinTop=0.448000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(9)=GUIImage'KFGunGame.GGLobbyMenu.Player10P2'

     Begin Object Class=GUIImage Name=Player11P2
         ImageStyle=ISTY_Justified
         WinTop=0.493000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(10)=GUIImage'KFGunGame.GGLobbyMenu.Player11P2'

     Begin Object Class=GUIImage Name=Player12P2
         ImageStyle=ISTY_Justified
         WinTop=0.538000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(11)=GUIImage'KFGunGame.GGLobbyMenu.Player12P2'

     Begin Object Class=GUIImage Name=Player13P2
         ImageStyle=ISTY_Justified
         WinTop=0.583000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(12)=GUIImage'KFGunGame.GGLobbyMenu.Player13P2'

     Begin Object Class=GUIImage Name=Player14P2
         ImageStyle=ISTY_Justified
         WinTop=0.628000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(13)=GUIImage'KFGunGame.GGLobbyMenu.Player14P2'

     Begin Object Class=GUIImage Name=Player15P2
         ImageStyle=ISTY_Justified
         WinTop=0.673000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(14)=GUIImage'KFGunGame.GGLobbyMenu.Player15P2'

     Begin Object Class=GUIImage Name=Player16P2
         ImageStyle=ISTY_Justified
         WinTop=0.718000
         WinLeft=0.681753
         WinWidth=0.039000
         WinHeight=0.039000
         RenderWeight=0.560000
     End Object
     PlayerPerk2(15)=GUIImage'KFGunGame.GGLobbyMenu.Player16P2'

     Begin Object Class=GUILabel Name=Player1Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.040000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.500000
     End Object
     PlayerVetLabel2(0)=GUILabel'KFGunGame.GGLobbyMenu.Player1Veterancy2'

     Begin Object Class=GUILabel Name=Player2Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.085000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.500000
     End Object
     PlayerVetLabel2(1)=GUILabel'KFGunGame.GGLobbyMenu.Player2Veterancy2'

     Begin Object Class=GUILabel Name=Player3Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.130000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(2)=GUILabel'KFGunGame.GGLobbyMenu.Player3Veterancy2'

     Begin Object Class=GUILabel Name=Player4Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.175000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(3)=GUILabel'KFGunGame.GGLobbyMenu.Player4Veterancy2'

     Begin Object Class=GUILabel Name=Player5Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.220000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(4)=GUILabel'KFGunGame.GGLobbyMenu.Player5Veterancy2'

     Begin Object Class=GUILabel Name=Player6Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.265000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(5)=GUILabel'KFGunGame.GGLobbyMenu.Player6Veterancy2'

     Begin Object Class=GUILabel Name=Player7Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.310000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(6)=GUILabel'KFGunGame.GGLobbyMenu.Player7Veterancy2'

     Begin Object Class=GUILabel Name=Player8Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.355000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(7)=GUILabel'KFGunGame.GGLobbyMenu.Player8Veterancy2'

     Begin Object Class=GUILabel Name=Player9Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.400000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(8)=GUILabel'KFGunGame.GGLobbyMenu.Player9Veterancy2'

     Begin Object Class=GUILabel Name=Player10Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.445000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(9)=GUILabel'KFGunGame.GGLobbyMenu.Player10Veterancy2'

     Begin Object Class=GUILabel Name=Player11Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.490000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(10)=GUILabel'KFGunGame.GGLobbyMenu.Player11Veterancy2'

     Begin Object Class=GUILabel Name=Player12Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.535000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(11)=GUILabel'KFGunGame.GGLobbyMenu.Player12Veterancy2'

     Begin Object Class=GUILabel Name=Player13Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.580000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(12)=GUILabel'KFGunGame.GGLobbyMenu.Player13Veterancy2'

     Begin Object Class=GUILabel Name=Player14Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.625000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(13)=GUILabel'KFGunGame.GGLobbyMenu.Player14Veterancy2'

     Begin Object Class=GUILabel Name=Player15Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.670000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(14)=GUILabel'KFGunGame.GGLobbyMenu.Player15Veterancy2'

     Begin Object Class=GUILabel Name=Player16Veterancy2
         TextAlign=TXTA_Right
         TextColor=(B=19,G=19,R=19)
         TextFont="UT2SmallFont"
         WinTop=0.715000
         WinLeft=0.793094
         WinWidth=0.151172
         WinHeight=0.045000
         RenderWeight=0.550000
     End Object
     PlayerVetLabel2(15)=GUILabel'KFGunGame.GGLobbyMenu.Player16Veterancy2'

     Begin Object Class=KFLobbyChat Name=ChatBox
         OnCreateComponent=ChatBox.InternalOnCreateComponent
         WinTop=0.807600
         WinLeft=0.016090
         WinWidth=0.971410
         WinHeight=0.100000
         RenderWeight=0.010000
         TabOrder=1
         OnPreDraw=ChatBox.FloatingPreDraw
         OnRendered=ChatBox.FloatingRendered
         OnHover=ChatBox.FloatingHover
         OnMousePressed=ChatBox.FloatingMousePressed
         OnMouseRelease=ChatBox.FloatingMouseRelease
     End Object
     t_ChatBox=KFLobbyChat'KFGunGame.GGLobbyMenu.ChatBox'

     Begin Object Class=GUILabel Name=TimeOutCounter
         Caption="Game will auto-commence in: "
         TextAlign=TXTA_Center
         TextColor=(B=158,G=176,R=175)
         WinTop=0.000010
         WinLeft=0.336310
         WinWidth=0.346719
         WinHeight=0.045704
         TabOrder=6
     End Object
     label_TimeOutCounter=GUILabel'KFGunGame.GGLobbyMenu.TimeOutCounter'

     Begin Object Class=GUILabel Name=Spectators
         Caption="Spectators:"
         TextColor=(B=158,G=176,R=175)
         WinTop=0.760000
         WinLeft=0.017000
         WinWidth=0.966000
         WinHeight=0.045704
         TabOrder=6
     End Object
     SpectatorsLabel=GUILabel'KFGunGame.GGLobbyMenu.Spectators'

     Begin Object Class=GUISectionBackground Name=ADBG
         WinTop=0.037343
         WinLeft=0.349700
         WinWidth=0.322266
         WinHeight=0.360677
         RenderWeight=0.300000
         OnPreDraw=ADBG.InternalPreDraw
     End Object
     ADBackground=GUISectionBackground'KFGunGame.GGLobbyMenu.ADBG'

     LvAbbrString="Lv"
     SelectPerkInformationString="Perks enhance certain abilities of your character.|There are 6 Perks to choose from in the center of the screen.|Each has different Effects shown in the upper right.|Perks improve as you complete the Level Requirements shown on the right."
     WaitingForServerStatus="Awaiting server status..."
     WaitingForOtherPlayers="Pick A Team"
     AutoCommence="Game will auto-commence in"
     SpectatorsString="Spectators:"
     Begin Object Class=GUITabControl Name=PageTabs
         bDockPanels=True
         TabHeight=0.040000
         WinLeft=0.010000
         WinWidth=0.980000
         WinHeight=0.040000
         RenderWeight=0.490000
         TabOrder=3
         bAcceptsInput=True
         OnActivate=PageTabs.InternalOnActivate
     End Object
     c_Tabs=GUITabControl'KFGui.GUIClassMenu.PageTabs'

     Begin Object Class=GUIHeader Name=MyHeader
         WinHeight=-0.350000
         bVisible=False
     End Object
     t_Header=GUIHeader'KFGunGame.GGLobbyMenu.MyHeader'

     Begin Object Class=GGLobbyFooter Name=MyFooter
         RenderWeight=0.300000
         TabOrder=8
         bBoundToParent=False
         bScaleToParent=False
         OnPreDraw=BuyFooter.InternalOnPreDraw
     End Object
     t_Footer=GGLobbyFooter'KFGunGame.GGLobbyMenu.MyFooter'

     bRenderWorld=True
     bAllowedAsLast=True
     OnClose=GGLobbyMenu.InternalOnClosed
     OnCanClose=GGLobbyMenu.StopClose
     WinHeight=0.500000
     OnPreDraw=GGLobbyMenu.InternalOnPreDraw
     OnRendered=GGLobbyMenu.DrawAd
     OnKeyEvent=GGLobbyMenu.InternalOnKeyEvent
}
