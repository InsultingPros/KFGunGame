class GGAnnouncementMessage extends CriticalEventPlus;

// var localized string FirstBloodString;
// var sound FirstBloodSound; // OBSOLETE
// var localized string Stage[4];
var localized string HasReachedString;
var localized string FirstString;
var localized string FinalWeaponString;
var localized string LevelString;
var localized string StoleALevelFromString;
var sound StageSound, FinalStageSound;
var sound StoleLevelSound;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
) {
    local string wItemName;
    // if (Switch < 7 )
    // {
    //     P.Level.FillPrecacheMaterialsArray(false);
    //     P.Level.FillPrecacheStaticMeshesArray(false);
    //     P.PrecacheAnnouncements();
    // }
    // // don't play sound if quickstart=true, so no 'play' voiceover at start of tutorials
    // if (Switch == 5 && P != none )
    // {
    //     //P.PlayStatusAnnouncement('Play',1,true);
    //     P.ClientPlaySound(sound'KF_BasePatriarch.Kev_Entrance1', false, 2.0);
    //     P.ClientPlaySound(sound'KF_FoundrySnd.Alarm_BellWarning01', false, 2.0);
    // }
    // else if ((Switch > 1) && (Switch < 5) )
    //     //P.PlayBeepSound();
    //     P.ClientPlaySound(sound'Miscsounds.Enter', true, 2.0);
    // else if (Switch == 7 )
    //     P.ClientPlaySound(default.Riff);

    if (class<Weapon>(OptionalObject) == none) {
        wItemName = "404 Weapon";
    } else {
        wItemName = class<Weapon>(OptionalObject).default.ItemName;
    }

    if (RelatedPRI_1 == none) {
        return "";
    }
    if (RelatedPRI_1.PlayerName == "") {
        return "";
    }

    if (switch == 0) {
        return RelatedPRI_1.PlayerName @
            default.HasReachedString @
            wItemName @
            default.LevelString @
            KFGGPRI(RelatedPRI_1).WeaponLevel $
            "/" $
            KFGGGameReplicationInfo(RelatedPRI_1.Level.GRI).MaxWeaponLevel $
            "!";
    } else if (switch == 1) {
        return RelatedPRI_1.PlayerName @
            default.FinalWeaponString @
            wItemName $
            "!!!";
    } else if (switch == 2) {
        return RelatedPRI_1.PlayerName @ default.StoleALevelFromString @ RelatedPRI_2.PlayerName $ "!";
    }
}

static simulated function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
) {
    super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

    if (Switch == 0) {
        P.ClientPlaySound(default.StageSound, true, 2.0);
    } else if (Switch == 1) {
        P.ClientPlaySound(default.FinalStageSound, true, 2.0);
    } else if (Switch == 2) {
        P.ClientPlaySound(default.StoleLevelSound, true, 2.0);
    }
}

defaultproperties {
    HasReachedString="has reached the"
    FirstString="first!"
    FinalWeaponString="has reached the final weapon"
    LevelString="level"
    StoleALevelFromString="stole a level from"
    StageSound=Sound'KF_InterfaceSnd.Perks.PerkAchieved'
    FinalStageSound=Sound'KF_FoundrySnd.Alarm_SirenLoop01'
    StoleLevelSound=Sound'Miscsounds.Egg.DeanScream'
    bIsUnique=false
    Lifetime=4
    DrawColor=(B=0,G=255)
    PosY=0.300000
}