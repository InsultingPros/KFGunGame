class GGStartupMessage extends CriticalEventPlus;

#EXEC OBJ LOAD FILE=KF_BasePatriarch.uax
#EXEC OBJ LOAD FILE=KF_FoundrySnd.uax

var localized string Stage[8], NotReady, SinglePlayer;
var sound Riff;

static simulated function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
) {
    super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

    if (Switch < 7) {
        P.Level.FillPrecacheMaterialsArray(false);
        P.Level.FillPrecacheStaticMeshesArray(false);
        P.PrecacheAnnouncements();
    }
    if (Switch == 5 && P != none) {
        // P.PlayStatusAnnouncement('Play', 1, true);
        P.ClientPlaySound(sound'KF_BasePatriarch.Kev_KnockedDown2', false, 2.0);
        P.ClientPlaySound(sound'KF_FoundrySnd.Alarm_BellWarning01', false, 2.0);
    } else if (Switch > 1 && Switch < 5) {
        P.ClientPlaySound(sound'KF_FoundrySnd.Alarm_AlertWarning01', true, 2.0);
    } else if (Switch == 7) {
        P.ClientPlaySound(default.Riff);
    }
}

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
) {
    local int i, PlayerCount;
    local GameReplicationInfo GRI;

    if (RelatedPRI_1 != none && RelatedPRI_1.Level.NetMode == NM_Standalone) {
        if (DeathMatch(RelatedPRI_1.Level.Game) != none && DeathMatch(RelatedPRI_1.Level.Game).bQuickstart) {
            return "";
        }
        if (Switch < 2) {
            return default.SinglePlayer;
        }
    } else if (Switch == 0 && RelatedPRI_1 != none) {
        GRI = RelatedPRI_1.Level.GRI;
        if (GRI == none) {
            return default.Stage[0];
        }
        for (i = 0; i < GRI.PRIArray.Length; i++) {
            if (
                GRI.PRIArray[i] != none &&
                !GRI.PRIArray[i].bOnlySpectator &&
                (!GRI.PRIArray[i].bIsSpectator || GRI.PRIArray[i].bWaitingPlayer)
            ) {
                PlayerCount++;
            }
        }
        if (GRI.MinNetPlayers - PlayerCount > 0) {
            return default.Stage[0] @ "(" $ (GRI.MinNetPlayers - PlayerCount) $ ")";
        }
    } else if (switch == 1) {
        if (RelatedPRI_1 == none || !RelatedPRI_1.bWaitingPlayer) {
            return default.Stage[0];
        } else if (RelatedPRI_1.bReadyToPlay) {
            return default.Stage[1];
        } else {
            return default.NotReady;
        }
    }
    return default.Stage[Switch];
}

defaultproperties {
    Stage(0)="Waiting for other players."
    Stage(1)="Waiting for ready signals. You are READY."
    Stage(2)="The match is about to begin...3"
    Stage(3)="The match is about to begin...2"
    Stage(4)="The match is about to begin...1"
    Stage(5)="The match has begun!"
    Stage(6)="The match has begun!"
    Stage(7)="OVER TIME!"
    NotReady="You're not Ready. Click Ready!"
    SinglePlayer="Click Ready to start!"
    bIsConsoleMessage=false
    DrawColor=(B=64,G=64,R=255)
    PosY=0.400000
}