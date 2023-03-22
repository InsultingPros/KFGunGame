class KFDMScoreBoard extends KFScoreBoard;

function DrawTitle(Canvas Canvas, float HeaderOffsetY, float PlayerAreaY, float PlayerBoxSizeY) {
    local string TitleString, ScoreInfoString, RestartString;
    local float TitleXL, ScoreInfoXL, YL, TitleY, TitleYL;

    TitleString = "DeathMatch" @ Eval(GRI.GoalScore > 0, "|" @ "Frag Limit:" @ GRI.GoalScore @ "|", "|") @ Level.Title;
    Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);
    Canvas.StrLen(TitleString, TitleXL, TitleYL);

    if (GRI.TimeLimit != 0) {
        ScoreInfoString = TimeLimit $ FormatTime(GRI.RemainingTime);
    } else {
        ScoreInfoString = FooterText @ FormatTime(GRI.ElapsedTime);
    }

    Canvas.DrawColor = HUDClass.default.RedColor;

    if (UnrealPlayer(Owner).bDisplayLoser) {
        ScoreInfoString = class'HUDBase'.default.YouveLostTheMatch;
    } else if (UnrealPlayer(Owner).bDisplayWinner) {
        ScoreInfoString = class'HUDBase'.default.YouveWonTheMatch;
    } else if (PlayerController(Owner).IsDead()) {
        RestartString = Restart;
        ScoreInfoString = RestartString;
    }

    TitleY = Canvas.ClipY * 0.13;
    Canvas.SetPos(0.5 * (Canvas.ClipX - TitleXL), TitleY);
    Canvas.DrawText(TitleString);

    Canvas.StrLen(ScoreInfoString, ScoreInfoXL, YL);
    Canvas.SetPos(0.5 * (Canvas.ClipX - ScoreInfoXL), TitleY + TitleYL);
    Canvas.DrawText(ScoreInfoString);
}

simulated event UpdateScoreBoard(Canvas Canvas) {
    local PlayerReplicationInfo PRI, OwnerPRI;
    local int i, FontReduction, NetXPos, PlayerCount, HeaderOffsetY, HeadFoot, MessageFoot,
		PlayerBoxSizeY, BoxSpaceY, NameXPos, BoxTextOffsetY, OwnerOffset, HealthXPos, BoxXPos,
		KillsXPos, TitleYPos, BoxWidth, VetXPos;
    local float XL,YL, MaxScaling;
    local float deathsXL, KillsXL, netXL,HealthXL, MaxNamePos, KillWidthX, HealthWidthX;
    local bool bNameFontReduction;

    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
    OwnerOffset = -1;

    for (i = 0; i < GRI.PRIArray.Length; i++) {
        PRI = GRI.PRIArray[i];

        if (!PRI.bOnlySpectator) {
            if (PRI == OwnerPRI) {
                OwnerOffset = i;
            }
            PlayerCount++;
        }
    }

    PlayerCount = Min(PlayerCount, MAXPLAYERS);

    // Select best font size and box size to fit as many players as possible on screen
    Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);
    Canvas.StrLen("Test", XL, YL);
    BoxSpaceY = 0.25 * YL;
    PlayerBoxSizeY = 1.2 * YL;
    HeadFoot = 7 * YL;
    MessageFoot = 1.5 * HeadFoot;

    if (PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot) / (PlayerBoxSizeY + BoxSpaceY)) {
        BoxSpaceY = 0.125 * YL;
        PlayerBoxSizeY = 1.25 * YL;

        if (PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot) / (PlayerBoxSizeY + BoxSpaceY)) {
            if (PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot) / (PlayerBoxSizeY + BoxSpaceY)) {
                PlayerBoxSizeY = 1.125 * YL;
            }

            // if (PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) )
            // {
            //     FontReduction++;
            //     Canvas.Font = GetSmallerFontFor(Canvas, FontReduction);
            //     Canvas.StrLen("Test", XL, YL);
            //     BoxSpaceY = 0.125 * YL;
            //     PlayerBoxSizeY = 1.125 * YL;
            //     HeadFoot = 7 * YL;

            //     if (PlayerCount > (Canvas.ClipY - HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) )
            //     {
            //         FontReduction++;
            //         Canvas.Font = GetSmallerFontFor(Canvas, FontReduction);
            //         Canvas.StrLen("Test", XL, YL);
            //         BoxSpaceY = 0.125 * YL;
            //         PlayerBoxSizeY = 1.125 * YL;
            //         HeadFoot = 7 * YL;

            //         if ((Canvas.ClipY >= 768) && (PlayerCount > (Canvas.ClipY - HeadFoot) / (PlayerBoxSizeY + BoxSpaceY)) )
            //         {
            //             FontReduction++;
            //             Canvas.Font = GetSmallerFontFor(Canvas,FontReduction);
            //             Canvas.StrLen("Test", XL, YL);
            //             BoxSpaceY = 0.125 * YL;
            //             PlayerBoxSizeY = 1.125 * YL;
            //             HeadFoot = 7 * YL;
            //         }
            //     }
            // }
        }
    }

    if (Canvas.ClipX < 512) {
        PlayerCount = Min(PlayerCount, 1+(Canvas.ClipY - HeadFoot) / (PlayerBoxSizeY + BoxSpaceY));
    } else {
        PlayerCount = Min(PlayerCount, (Canvas.ClipY - HeadFoot) / (PlayerBoxSizeY + BoxSpaceY));
    }

    if (FontReduction > 2) {
        MaxScaling = 3;
    } else {
        MaxScaling = 2.125;
    }

    PlayerBoxSizeY = FClamp((1.25 + (Canvas.ClipY - 0.67 * MessageFoot)) / PlayerCount - BoxSpaceY, PlayerBoxSizeY, MaxScaling * YL);
    bDisplayMessages = (PlayerCount <= (Canvas.ClipY - MessageFoot) / (PlayerBoxSizeY + BoxSpaceY));
    HeaderOffsetY = 10 * YL;
    BoxWidth = 0.7 * Canvas.ClipX;
    BoxXPos = 0.5 * (Canvas.ClipX - BoxWidth);
    BoxWidth = Canvas.ClipX - 2 * BoxXPos;
    VetXPos = BoxXPos + 0.0001 * BoxWidth;
    NameXPos = BoxXPos + 0.08 * BoxWidth;
    KillsXPos = BoxXPos + 0.60 * BoxWidth;
    HealthXpos = BoxXPos + 0.75 * BoxWidth;
    NetXPos = BoxXPos + 0.90 * BoxWidth;

    // draw background boxes
    Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.DrawColor.A = 128;

    for (i = 0; i < PlayerCount; i++) {
        Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY) * i);
        Canvas.DrawTileStretched(BoxMaterial, BoxWidth, PlayerBoxSizeY);
    }

    // draw title
    Canvas.Style = ERenderStyle.STY_Normal;
    DrawTitle(Canvas, HeaderOffsetY, (PlayerCount + 1) * (PlayerBoxSizeY + BoxSpaceY), PlayerBoxSizeY);

    // Draw headers
    TitleYPos = HeaderOffsetY - 1.1 * YL;
    Canvas.StrLen(HealthText, HealthXL, YL);
    Canvas.StrLen(DeathsText, DeathsXL, YL);
    Canvas.StrLen(KillsText, KillsXL, YL);
    Canvas.StrLen("50", HealthWidthX, YL);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(NameXPos, TitleYPos);
    Canvas.DrawText(PlayerText,true);

    if (bDisplayWithKills) {
        Canvas.SetPos(KillsXPos - 0.5 * KillsXL, TitleYPos);
        Canvas.DrawText(KillsText,true);
    }

    Canvas.SetPos(HealthXPos - 0.5 * HealthXL, TitleYPos);
    Canvas.DrawText(HealthText,true);

    // draw player names
    MaxNamePos = 0.9 * (KillsXPos - NameXPos);

    for (i = 0; i < PlayerCount; i++) {
        Canvas.StrLen(GRI.PRIArray[i].PlayerName, XL, YL);
        if (XL > MaxNamePos) {
            bNameFontReduction = true;
            break;
        }
    }

    if (bNameFontReduction) {
        Canvas.Font = GetSmallerFontFor(Canvas, FontReduction + 1);
    }

    Canvas.Style = ERenderStyle.STY_Normal;
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(0.5 * Canvas.ClipX, HeaderOffsetY + 4);
    BoxTextOffsetY = HeaderOffsetY + 0.5 * (PlayerBoxSizeY - YL);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    MaxNamePos = Canvas.ClipX;
    Canvas.ClipX = KillsXPos - 4.f;

    for (i = 0; i < PlayerCount; i++) {
        Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);

        if (i == OwnerOffset) {
            Canvas.DrawColor.G = 0;
            Canvas.DrawColor.B = 0;
        } else {
            Canvas.DrawColor.G = 255;
            Canvas.DrawColor.B = 255;
        }

        Canvas.DrawTextClipped(GRI.PRIArray[i].PlayerName);
    }

    Canvas.ClipX = MaxNamePos;
    Canvas.DrawColor = HUDClass.default.WhiteColor;

    if (bNameFontReduction) {
        Canvas.Font = GetSmallerFontFor(Canvas, FontReduction);
    }

    Canvas.Style = ERenderStyle.STY_Normal;
    MaxScaling = FMax(PlayerBoxSizeY,30.f);
    Canvas.DrawColor = HUDClass.default.WhiteColor;

    // Draw the player informations.
    for (i = 0; i < PlayerCount; i++) {
        // draw kills
        Canvas.StrLen(KFPlayerReplicationInfo(GRI.PRIArray[i]).Kills, KillWidthX, YL);
        Canvas.SetPos(KillsXPos - 0.5 * KillWidthX, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
        Canvas.DrawText(GRI.PRIArray[i].Kills, true);

        // draw deaths
        Canvas.SetPos(HealthXpos - 0.5 * HealthWidthX, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
        Canvas.DrawText(string(int(GRI.PRIArray[i].Deaths)), true);
    }

    if (Level.NetMode == NM_Standalone) {
        return;
	}

    Canvas.StrLen(NetText, NetXL, YL);
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(NetXPos - 0.5 * NetXL, TitleYPos);
    Canvas.DrawText(NetText,true);

    for (i=0; i<GRI.PRIArray.Length; i++) {
        PRIArray[i] = GRI.PRIArray[i];
    }

    DrawNetInfo(Canvas, FontReduction, HeaderOffsetY, PlayerBoxSizeY, BoxSpaceY, BoxTextOffsetY, OwnerOffset, PlayerCount, NetXPos);
    DrawMatchID(Canvas, FontReduction);
}

defaultproperties {
    HealthText="Deaths"
    bDisplayWithKills=True
}