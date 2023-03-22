// Red Team player.
class KFRedGGPlayer extends KFGGHumanPawn;

//#exec obj load file="TeamSkins.utx" package="KFGunGame"

var Material TeamSkinX;

simulated function PostBeginPlay() {
    super.PostBeginPlay();
    // AssignInitialPose();

    // if (bActorShadows && bPlayerShadows && (Level.NetMode!=NM_DedicatedServer) )
    // {
    //     if (bDetailedShadows )
    //         PlayerShadow = Spawn(class'KFShadowProject',Self,'',Location);
    //     else PlayerShadow = Spawn(class'ShadowProjector',Self,'',Location);
    //     PlayerShadow.ShadowActor = self;
    //     PlayerShadow.bBlobShadow = bBlobShadow;
    //     PlayerShadow.LightDirection = Normal(vect(1,1,3));
    //     PlayerShadow.InitShadow();
    // }
    Skins[0] = TeamSkinX;
}

simulated function bool IsTeamColorCharacter(string CheckString) {
    if (
        CheckString == "Sergeant_Powers" ||
        CheckString == "Corporal_Lewis" ||
        CheckString == "Lieutenant_Masterson" ||
        CheckString == "Trooper_Clive_Jenkins" ||
        CheckString == "LanceCorporal_Lee_Baron" ||
        CheckString == "Private_Schnieder"
    ) {
        return true;
    } else {
        return false;
    }
}


simulated function Setup(xUtil.PlayerRecord rec, optional bool bLoadNow) {
    if (IsTeamColorCharacter(rec.DefaultName)) {
        if (rec.Species == none || class<SPECIES_KFMaleHuman>(rec.Species) == none) {
            rec = class'xUtil'.static.FindPlayerRecord(GetDefaultCharacter());
        }
    } else {
        rec = class'xUtil'.static.FindPlayerRecord(GetDefaultCharacter());
    }
    Species = rec.Species;
    RagdollOverride = rec.Ragdoll;
    if (Species != none && !Species.static.Setup(self, rec)) {
        rec = class'xUtil'.static.FindPlayerRecord(GetDefaultCharacter());
        Species = rec.Species;
        RagdollOverride = rec.Ragdoll;
        if (!Species.static.Setup(self, rec)) {
            return;
        }
    }
    if (class<SPECIES_KFMaleHuman>(Species) != none) {
        DetachedArmClass = class<SPECIES_KFMaleHuman>(Species).default.DetachedArmClass;
        DetachedLegClass = class<SPECIES_KFMaleHuman>(Species).default.DetachedLegClass;
    }
    //Skins[0] = TeamSkinX;
    ResetPhysicsBasedAnim();
}

function bool CanBuyNow() {
    // local TDMShopTrigger Sh;

    // if (PlayerReplicationInfo== none || PlayerReplicationInfo.Team== none )
    //     return false;
    // foreach TouchingActors(class'TDMShopTrigger',Sh)
    //     if (Sh.Team==PlayerReplicationInfo.Team.TeamIndex )
    //         return true;
    return false;
}

simulated function string GetDefaultCharacter() {
    local int RandChance;

    RandChance = Rand(5);

    if (RandChance == 0) {
        return "Corporal_Lewis";
    } else if (RandChance == 1) {
        return "Lieutenant_Masterson";
    } else if (RandChance == 2) {
        return "Trooper_Clive_Jenkins";
    } else if (RandChance == 3) {
        return "LanceCorporal_Lee_Baron";
    } else if (RandChance == 4) {
        return "Private_Schnieder";
    } else {
        return "Sergeant_Powers";
    }

    // kinda fits
    // Security_Office_Thorne
}

defaultproperties {
    bNoTeamBeacon=false
    bScriptPostRender=true
}