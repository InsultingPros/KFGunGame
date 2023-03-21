class GGHUDKillingFloor extends HUDKillingFloor;

var byte PLCount,PLPosition;
var float NextPosUpdate;
var localized string LostMatchStr,WonMatchStr,OtherWinnerStr;

simulated final function UpdatePosition()
{
	local int i;
	local PlayerReplicationInfo PRI;

	PLCount = 1;
	PLPosition = 1;
	PRI = PlayerOwner.PlayerReplicationInfo;
	for( i=0; i<KFGRI.PRIArray.Length; i++ )
	{
		if( KFGRI.PRIArray[i]==None || KFGRI.PRIArray[i]==PRI || KFGRI.PRIArray[i].bOnlySpectator )
			continue;
		PLCount++;
		if( KFGRI.PRIArray[i].Kills>PRI.Kills )
			PLPosition++;
	}
}

simulated function DrawHud(Canvas C)
{
	local KFGameReplicationInfo CurrentGame;
	local rotator CamRot;
	local vector CamPos, ViewDir;
	local int i;
	local bool bBloom;

	if ( KFGameType(PlayerOwner.Level.Game) != none )
		CurrentGame = KFGameReplicationInfo(PlayerOwner.Level.GRI);

	if ( FontsPrecached < 2 )
		PrecacheFonts(C);

	UpdateHud();

	PassStyle = STY_Modulated;
	DrawModOverlay(C);

	bBloom = bool(ConsoleCommand("get ini:Engine.Engine.ViewportManager Bloom"));
	if ( bBloom )
	{
		PlayerOwner.PostFX_SetActive(0, true);
	}

	if( bHideHud )
		return;

	if ( bShowTargeting )
		DrawTargeting(C);

	// Grab our View Direction
	C.GetCameraLocation(CamPos,CamRot);
	ViewDir = vector(CamRot);

	// Draw the Name, Health, Armor, and Veterancy above other players
	for ( i = 0; i < PlayerInfoPawns.Length; i++ )
	{
		if ( PlayerInfoPawns[i].Pawn != none && PlayerInfoPawns[i].Pawn.Health > 0 && (PlayerInfoPawns[i].Pawn.Location - PawnOwner.Location) dot ViewDir > 0.8 &&
			 PlayerInfoPawns[i].RendTime > Level.TimeSeconds )
			DrawPlayerInfo(C, PlayerInfoPawns[i].Pawn, PlayerInfoPawns[i].PlayerInfoScreenPosX, PlayerInfoPawns[i].PlayerInfoScreenPosY);
		else PlayerInfoPawns.Remove(i--, 1);
	}

	PassStyle = STY_Alpha;
	DrawDamageIndicators(C);
	if( !bShowScoreboard )
	{
	   DrawHudPassA(C);
	}

	DrawHudPassC(C);

	if ( KFPlayerController(PlayerOwner)!= None && KFPlayerController(PlayerOwner).ActiveNote!= None )
	{
		if( PlayerOwner.Pawn == none )
			KFPlayerController(PlayerOwner).ActiveNote = None;
		else KFPlayerController(PlayerOwner).ActiveNote.RenderNote(C);
	}

	PassStyle = STY_None;
	DisplayLocalMessages(C);
	if( !bShowScoreboard )
	{
    	DrawWeaponName(C);
    	DrawVehicleName(C);
	}

	PassStyle = STY_Modulated;

	if ( KFGameReplicationInfo(Level.GRI)!= None && KFGameReplicationInfo(Level.GRI).EndGameType > 0 )
	{
		if ( KFGameReplicationInfo(Level.GRI).EndGameType == 2 )
			DrawEndGameHUD(C, True);
		else DrawEndGameHUD(C, False);
	}
	else DrawKFHUDTextElements(C);

	if ( bShowNotification )
		DrawPopupNotification(C);
}

function DrawDoorHealthBars(Canvas C)
{
	if( PlayerOwner.Pawn!=None )
		Super.DrawDoorHealthBars(C);
}

simulated function DrawKFHUDTextElements(Canvas C);

simulated function DrawHudPassC(Canvas C)
{
	DrawFadeEffect(C);

	if ( bShowScoreBoard && ScoreBoard != None )
	{
		ScoreBoard.DrawScoreboard(C);
	}

	// portrait
	if ( bShowPortrait && (Portrait != None) )
	{
		DrawPortrait(C);
	}

	if ( PawnOwner != None && PawnOwner.Weapon != None && KFWeapon(PawnOwner.Weapon) != none )
	{
		if( !KFWeapon(PawnOwner.Weapon).bAimingRifle && !PawnOwner.Weapon.IsA('Crossbow')
            && !PawnOwner.Weapon.IsA('M14EBRBattleRifle') && !PawnOwner.Weapon.IsA('M99SniperRifle') )
        {
            DrawCrosshair(C);
        }
	}

	// Slow, for debugging only
	if( bDebugPlayerCollision && (class'ROEngine.ROLevelInfo'.static.RODebugMode() || Level.NetMode == NM_StandAlone) )
	{
		DrawPointSphere();
	}

}

simulated function DrawCrosshair (Canvas C)
{
	local float NormalScale;
	local int i, CurrentCrosshair;
	local float OldScale,OldW, CurrentCrosshairScale;
	local color CurrentCrosshairColor;
	local SpriteWidget CHtexture;

//	if (!bCrosshairShow /*|| !class'ROEngine.ROLevelInfo'.static.RODebugMode() || !bShowKFDebugXHair*/)
//		return;

	if ( (PawnOwner != None) && (PawnOwner.Weapon != None) && (PawnOwner.Weapon.CustomCrosshair >= 0) )
	{
		CurrentCrosshairColor = PawnOwner.Weapon.CustomCrosshairColor;
		CurrentCrosshair = PawnOwner.Weapon.CustomCrosshair;
		CurrentCrosshairScale = PawnOwner.Weapon.CustomCrosshairScale;
		if ( PawnOwner.Weapon.CustomCrosshairTextureName != "" )
		{
			if ( PawnOwner.Weapon.CustomCrosshairTexture == None )
			{
				PawnOwner.Weapon.CustomCrosshairTexture = Texture(DynamicLoadObject(PawnOwner.Weapon.CustomCrosshairTextureName,class'Texture'));
				if ( PawnOwner.Weapon.CustomCrosshairTexture == None )
				{
					log(PawnOwner.Weapon$" custom crosshair texture not found!");
					PawnOwner.Weapon.CustomCrosshairTextureName = "";
				}
			}
			CHTexture = Crosshairs[0];
			CHTexture.WidgetTexture = PawnOwner.Weapon.CustomCrosshairTexture;
		}
	}
	else
	{
		CurrentCrosshair = CrosshairStyle;
		CurrentCrosshairColor = CrosshairColor;
		CurrentCrosshairScale = CrosshairScale;
	}

	CurrentCrosshair = Clamp(CurrentCrosshair, 0, Crosshairs.Length - 1);

	NormalScale = Crosshairs[CurrentCrosshair].TextureScale;
	if ( CHTexture.WidgetTexture == None )
		CHTexture = Crosshairs[CurrentCrosshair];
	CHTexture.TextureScale *= CurrentCrosshairScale;

	for( i = 0; i < ArrayCount(CHTexture.Tints); i++ )
		CHTexture.Tints[i] = CurrentCrossHairColor;

	OldScale = HudScale;
	HudScale=1;
	OldW = C.ColorModulate.W;
	C.ColorModulate.W = 1;
	DrawSpriteWidget (C, CHTexture);
	C.ColorModulate.W = OldW;
	HudScale=OldScale;
	CHTexture.TextureScale = NormalScale;

	//DrawEnemyName(C);
}

simulated function DrawEndGameHUD(Canvas C, bool bVictory)
{
	C.SetDrawColor(255, 255, 255, 255);
	C.Font = LoadFont(1);
	C.SetPos(0,C.ClipY*0.7f);
	C.bCenter = true;
//	if( TeamInfo(KFGRI.Winner)==None )
//		C.DrawText(LostMatchStr,false);
//	else if( TeamInfo(KFGRI.Winner).TeamIndex==0 )
//		C.DrawText("Red Team"$OtherWinnerStr,false);
//	else C.DrawText("Blue Team"$OtherWinnerStr,false);
	if( PlayerReplicationInfo(KFGRI.Winner)==None )
		C.DrawText(LostMatchStr,false); // Do something else here
	else if( KFGRI.Winner==PlayerOwner.PlayerReplicationInfo )
		C.DrawText(WonMatchStr,false);
	else C.DrawText(PlayerReplicationInfo(KFGRI.Winner).PlayerName$WonMatchPostFix,false);

	C.bCenter = false;
	if ( bShowScoreBoard && ScoreBoard != None )
		ScoreBoard.DrawScoreboard(C);
}

defaultproperties
{
     LostMatchStr="You've have lost the match!"
     WonMatchStr="You've have won the match!"
     OtherWinnerStr=" is the winner!"
}
