class GGHUDKillingFloor extends HUDKillingFloor
    config(KFGunGameGarbage);

var byte PLCount,PLPosition;
var float NextPosUpdate;
var localized string LostMatchStr,WonMatchStr,OtherWinnerStr;

simulated final function UpdatePosition() {
    local int i;
    local PlayerReplicationInfo PRI;

    PLCount = 1;
    PLPosition = 1;
    PRI = PlayerOwner.PlayerReplicationInfo;
    for (i = 0; i < KFGRI.PRIArray.Length; i += 1) {
        if (KFGRI.PRIArray[i] == none || KFGRI.PRIArray[i] == PRI || KFGRI.PRIArray[i].bOnlySpectator) {
            continue;
        }
        PLCount++;
        if (KFGRI.PRIArray[i].Kills > PRI.Kills) {
            PLPosition += 1;
        }
    }
}

simulated function DrawHud(Canvas C) {
    local KFGameReplicationInfo CurrentGame;
    local rotator CamRot;
    local vector CamPos, ViewDir;
    local int i;
    local bool bBloom;

    if (KFGameType(PlayerOwner.Level.Game) != none) {
        CurrentGame = KFGameReplicationInfo(PlayerOwner.Level.GRI);
    }

    if (FontsPrecached < 2) {
        PrecacheFonts(C);
    }

    UpdateHud();

    PassStyle = STY_Modulated;
    DrawModOverlay(C);

    bBloom = bool(ConsoleCommand("get ini:Engine.Engine.ViewportManager Bloom"));
    if (bBloom) {
        PlayerOwner.PostFX_SetActive(0, true);
    }

    if (bHideHud) {
        return;
    }

    if (bShowTargeting) {
        DrawTargeting(C);
    }

    // Grab our View Direction
    C.GetCameraLocation(CamPos, CamRot);
    ViewDir = vector(CamRot);

    // Draw the Name, Health, Armor, and Veterancy above other players
    for (i = 0; i < PlayerInfoPawns.Length; i += 1) {
        if (
            PlayerInfoPawns[i].Pawn != none &&
            PlayerInfoPawns[i].Pawn.Health > 0 &&
            (PlayerInfoPawns[i].Pawn.Location - PawnOwner.Location) dot ViewDir > 0.8 &&
            PlayerInfoPawns[i].RendTime > Level.TimeSeconds
        ) {
            DrawPlayerInfo(
                C,
                PlayerInfoPawns[i].Pawn,
                PlayerInfoPawns[i].PlayerInfoScreenPosX,
                PlayerInfoPawns[i].PlayerInfoScreenPosY
            );
        } else {
            PlayerInfoPawns.Remove(i--, 1);
        }
    }

    PassStyle = STY_Alpha;
    DrawDamageIndicators(C);
    if (!bShowScoreboard) {
        DrawHudPassA(C);
    }

    DrawHudPassC(C);

    if (KFPlayerController(PlayerOwner) != none && KFPlayerController(PlayerOwner).ActiveNote != none) {
        if (PlayerOwner.Pawn == none) {
            KFPlayerController(PlayerOwner).ActiveNote = none;
        } else {
            KFPlayerController(PlayerOwner).ActiveNote.RenderNote(C);
        }
    }

    PassStyle = STY_None;
    DisplayLocalMessages(C);
    if (!bShowScoreboard) {
        DrawWeaponName(C);
        DrawVehicleName(C);
    }

    PassStyle = STY_Modulated;

    if (KFGameReplicationInfo(Level.GRI) != none && KFGameReplicationInfo(Level.GRI).EndGameType > 0) {
        if (KFGameReplicationInfo(Level.GRI).EndGameType == 2) {
            DrawEndGameHUD(C, true);
        } else {
            DrawEndGameHUD(C, false);
        }
    } else {
        DrawKFHUDTextElements(C);
    }

    if (bShowNotification) {
        DrawPopupNotification(C);
    }
}

function DrawDoorHealthBars(Canvas C) {
    if (PlayerOwner.Pawn != none) {
        super.DrawDoorHealthBars(C);
    }
}

simulated function DrawKFHUDTextElements(Canvas C);

simulated function DrawHudPassC(Canvas C) {
    DrawFadeEffect(C);

    if (bShowScoreBoard && ScoreBoard != none) {
        ScoreBoard.DrawScoreboard(C);
    }

    // portrait
    if (bShowPortrait && (Portrait != none)) {
        DrawPortrait(C);
    }

    if (PawnOwner != none && PawnOwner.Weapon != none && KFWeapon(PawnOwner.Weapon) != none) {
        if (
            !KFWeapon(PawnOwner.Weapon).bAimingRifle &&
            !PawnOwner.Weapon.IsA('Crossbow') &&
            !PawnOwner.Weapon.IsA('M14EBRBattleRifle') &&
            !PawnOwner.Weapon.IsA('M99SniperRifle')
        ) {
            DrawCrosshair(C);
        }
    }

    // Slow, for debugging only
    if (
        bDebugPlayerCollision &&
        (class'ROEngine.ROLevelInfo'.static.RODebugMode() || Level.NetMode == NM_StandAlone)
    ) {
        DrawPointSphere();
    }
}

simulated function DrawCrosshair(Canvas C) {
    local float NormalScale;
    local int i, CurrentCrosshair;
    local float OldScale, OldW, CurrentCrosshairScale;
    local color CurrentCrosshairColor;
    local SpriteWidget CHtexture;

    // if (!bCrosshairShow /*|| !class'ROEngine.ROLevelInfo'.static.RODebugMode() || !bShowKFDebugXHair*/)
    //     return;

    if (PawnOwner != none && PawnOwner.Weapon != none && PawnOwner.Weapon.CustomCrosshair >= 0) {
        CurrentCrosshairColor = PawnOwner.Weapon.CustomCrosshairColor;
        CurrentCrosshair = PawnOwner.Weapon.CustomCrosshair;
        CurrentCrosshairScale = PawnOwner.Weapon.CustomCrosshairScale;
        if (PawnOwner.Weapon.CustomCrosshairTextureName != "") {
            if (PawnOwner.Weapon.CustomCrosshairTexture == none) {
                PawnOwner.Weapon.CustomCrosshairTexture = Texture(
                    DynamicLoadObject(PawnOwner.Weapon.CustomCrosshairTextureName, class'Texture')
                );
                if (PawnOwner.Weapon.CustomCrosshairTexture == none) {
                    log(PawnOwner.Weapon $ " custom crosshair texture not found!");
                    PawnOwner.Weapon.CustomCrosshairTextureName = "";
                }
            }
            CHTexture = Crosshairs[0];
            CHTexture.WidgetTexture = PawnOwner.Weapon.CustomCrosshairTexture;
        }
    } else {
        CurrentCrosshair = CrosshairStyle;
        CurrentCrosshairColor = CrosshairColor;
        CurrentCrosshairScale = CrosshairScale;
    }

    CurrentCrosshair = Clamp(CurrentCrosshair, 0, Crosshairs.Length - 1);

    NormalScale = Crosshairs[CurrentCrosshair].TextureScale;
    if (CHTexture.WidgetTexture == none) {
        CHTexture = Crosshairs[CurrentCrosshair];
    }
    CHTexture.TextureScale *= CurrentCrosshairScale;

    for (i = 0; i < ArrayCount(CHTexture.Tints); i += 1) {
        CHTexture.Tints[i] = CurrentCrossHairColor;
    }

    OldScale = HudScale;
    HudScale=1;
    OldW = C.ColorModulate.W;
    C.ColorModulate.W = 1;
    DrawSpriteWidget (C, CHTexture);
    C.ColorModulate.W = OldW;
    HudScale=OldScale;
    CHTexture.TextureScale = NormalScale;
    // DrawEnemyName(C);
}

simulated function DrawEndGameHUD(Canvas C, bool bVictory) {
    C.SetDrawColor(255, 255, 255, 255);
    C.Font = LoadFont(1);
    C.SetPos(0, C.ClipY * 0.7f);
    C.bCenter = true;
    // if (TeamInfo(KFGRI.Winner)== none )
    //     C.DrawText(LostMatchStr,false);
    // else if (TeamInfo(KFGRI.Winner).TeamIndex==0 )
    //     C.DrawText("Red Team"$OtherWinnerStr,false);
    // else C.DrawText("Blue Team"$OtherWinnerStr,false);
    if (PlayerReplicationInfo(KFGRI.Winner) == none) {
        // Do something else here
        C.DrawText(LostMatchStr, false);
    } else if (KFGRI.Winner == PlayerOwner.PlayerReplicationInfo) {
        C.DrawText(WonMatchStr, false);
    } else {
        C.DrawText(PlayerReplicationInfo(KFGRI.Winner).PlayerName $ WonMatchPostFix, false);
    }

    C.bCenter = false;
    if (bShowScoreBoard && ScoreBoard != none) {
        ScoreBoard.DrawScoreboard(C);
    }
}

defaultproperties {
    LostMatchStr="You've have lost the match!"
    WonMatchStr="You've have won the match!"
    OtherWinnerStr=" is the winner!"
}