class GGLobbyFooter extends ButtonFooter;

var automated GUIButton b_Ready, b_Cancel, b_Options;

function PositionButtons(Canvas C) {
    local int i;
    local GUIButton b;
    local float x;

    for (i = 0; i < Controls.Length; i++) {
        b = GUIButton(Controls[i]);
        if (b != none) {
            if (x == 0) {
                x = ButtonLeft;
            } else {
                x += GetSpacer();
            }
            b.WinLeft = b.RelativeLeft(x, true);
            x += b.ActualWidth();
        }
    }
}

function bool ButtonsSized(Canvas C) {
    local int i;
    local GUIButton b;
    local bool bResult;
    local string str;
    local float T, AH, AT;

    if (!bPositioned) {
        return false;
}

    bResult = true;
    str = GetLongestCaption(C);

    AH = ActualHeight();
    AT = ActualTop();

    for (i = 0; i < Controls.Length; i++) {
        b = GUIButton(Controls[i]);
        if (b != none) {
            if (bAutoSize && bFixedWidth) {
                if (b.Caption == "") {
                    b.SizingCaption = Left(str,Len(str)/2);
                } else {
                    b.SizingCaption = str;
                }
            } else {
                b.SizingCaption = "";
            }

            bResult = bResult && b.bPositioned;
            if (bFullHeight) {
                b.WinHeight = b.RelativeHeight(AH, true);
            } else {
                b.WinHeight = b.RelativeHeight(ActualHeight(ButtonHeight), true);
            }

            switch (Justification) {
                case TXTA_Left:
                    T = ClientBounds[1];
                    break;
                case TXTA_Center:
                    T = (AT + AH / 2) - (b.ActualHeight() / 2);
                    break;
                case TXTA_Right:
                    T = ClientBounds[3] - b.ActualHeight();
                    break;
            }

            //b.WinTop = AT + ((AH - ActualHeight(ButtonHeight)) / 2);
            b.WinTop = b.RelativeTop(T, true ) + ((WinHeight - ButtonHeight) / 2);
        }
    }
    return bResult;
}

function float GetButtonLeft() {
    local int i;
    local GUIButton b;
    local float TotalWidth, AW, AL;
    local float FooterMargin;

    AL = ActualLeft();
    AW = ActualWidth();
    FooterMargin = GetMargin();

    for (i = 0; i < Controls.Length; i++) {
        b = GUIButton(Controls[i]);
        if (b != none) {
            if (TotalWidth > 0) {
                TotalWidth += GetSpacer();
            }

            TotalWidth += b.ActualWidth();
        }
    }

    if (Alignment == TXTA_Center) {
        return (AL + AW) / 2 - FooterMargin / 2 - TotalWidth / 2;
    }

    if (Alignment == TXTA_Right) {
        return (AL + AW - FooterMargin / 2) - TotalWidth;
    }

    return AL + (FooterMargin / 2);
}

// Finds the longest caption of all the buttons
function string GetLongestCaption(Canvas C) {
    local int i;
    local float XL, YL, LongestW;
    local string str;
    local GUIButton b;

    if (C == none) {
        return "";
    }

    for (i = 0; i < Controls.Length; i++) {
        b = GUIButton(Controls[i]);
        if (b != none) {
            if (b.Style != none) {
                b.Style.TextSize(C, b.MenuState, b.Caption, XL, YL, b.FontScale);
            } else {
                C.StrLen(b.Caption, XL, YL );
            }

            if (LongestW == 0 || XL > LongestW) {
                str = b.Caption;
                LongestW = XL;
            }
        }
    }
    return str;
}

function bool OnFooterClick(GUIComponent Sender) {
    local GUIController C;
    local PlayerController PC;

    PC = PlayerOwner();
    C = Controller;
    if (Sender == b_Cancel) {
        //Kill Window and exit game/disconnect from server
        LobbyMenu(PageOwner).bAllowClose = true;
        C.ViewportOwner.Console.ConsoleCommand("DISCONNECT");
        KFGUIController(C).ReturnToMainMenu();
    } else if (Sender == b_Ready) {
        if (PC.PlayerReplicationInfo.Team != none) {
            // Set Ready
            // PC.ServerRestartPlayer();
            PC.PlayerReplicationInfo.bReadyToPlay = true;
            // if (PC.Level.GRI.bMatchHasBegun)
            PC.ClientCloseMenu(true, false);
        }
    } else if (Sender == b_Options) {
        PC.ClientOpenMenu("KFGUI.KFSettingsPage", false);
    }

    return false;
}

function OnSteamStatsAndAchievementsReady() {
    PlayerOwner().ClientOpenMenu("KFGUI.KFProfilePage", false);
}

defaultproperties {
    Begin Object class=GUIButton Name=ReadyButton
        Caption="Ready"
        Hint="Click here to choose your team and begin"
        WinTop=0.966146
        WinLeft=0.350000
        WinWidth=0.120000
        WinHeight=0.033203
        RenderWeight=2.000000
        TabOrder=5
        bBoundToParent=true
        ToolTip=none
        OnClick=OnFooterClick
        OnKeyEvent=ReadyButton.InternalOnKeyEvent
    End Object
    b_Ready=ReadyButton

    Begin Object class=GUIButton Name=Cancel
        Caption="Disconnect"
        Hint="Disconnect From This Server"
        WinTop=0.966146
        WinLeft=0.280000
        WinWidth=0.120000
        WinHeight=0.033203
        RenderWeight=2.000000
        TabOrder=4
        bBoundToParent=true
        ToolTip=none
        OnClick=OnFooterClick
        OnKeyEvent=Cancel.InternalOnKeyEvent
    End Object
    b_Cancel=Cancel

    Begin Object class=GUIButton Name=Options
        Caption="Options"
        Hint="Change game settings."
        WinTop=0.966146
        WinLeft=-0.500000
        WinWidth=0.120000
        WinHeight=0.033203
        RenderWeight=2.000000
        TabOrder=3
        bBoundToParent=true
        ToolTip=none
        OnClick=OnFooterClick
        OnKeyEvent=Cancel.InternalOnKeyEvent
    End Object
    b_Options=Options

    OnPreDraw=InternalOnPreDraw
}