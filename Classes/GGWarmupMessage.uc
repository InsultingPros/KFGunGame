class GGWarmupMessage extends CriticalEventPlus;

var localized string Stage[8], NotReady, SinglePlayer;
var sound Riff;

#EXEC OBJ LOAD FILE=Miscsounds.uax

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
    // don't play sound if quickstart=true, so no 'play' voiceover at start of tutorials
    if (Switch == 5 && P != none) {
        // P.PlayStatusAnnouncement('Play',1,true);
        P.ClientPlaySound(sound'KF_BasePatriarch.Kev_Entrance1', false, 2.0);
        P.ClientPlaySound(sound'KF_FoundrySnd.Alarm_BellWarning01', false, 2.0);
    } else if (Switch > 1 && Switch < 5) {
        P.ClientPlaySound(sound'Miscsounds.Enter', true, 2.0);
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
        if (
            DeathMatch(RelatedPRI_1.Level.Game) != none &&
            DeathMatch(RelatedPRI_1.Level.Game).bQuickstart
        ) {
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
        for (i = 0; i < GRI.PRIArray.Length; i += 1) {
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
    Stage(2)="The warmup is about to begin...3"
    Stage(3)="The warmup is about to begin...2"
    Stage(4)="The warmup is about to begin...1"
    Stage(5)="The warmup has begun!"
    Stage(6)="The warmup has begun!"
    Stage(7)="OVER TIME!"
    NotReady="You're not Ready. Click Ready!"
    SinglePlayer="Click Ready to start!"
    bIsConsoleMessage=false
    DrawColor=(B=64,G=64,R=255)
}