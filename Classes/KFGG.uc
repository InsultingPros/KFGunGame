//=============================================================================
// KFGG
//=============================================================================
// Killing Floor Gun Game Game Type
//=============================================================================
// Killing Floor Source
// Copyright (C) 2011 John "Ramm-Jaeger" Gibson
// Some elements based off of KFTDM by Marco
//=============================================================================
class KFGG extends KFGameType;

var config int NumAmmoSpawns;
var config int WarmupTime; // How long to do a pre match warmup before starting the round
var config bool bReverseList; // Do the weapon list backwards
var config bool bShortList; // Do the weapon list backwards
var bool bDidWarmup, bDoingWarmup;
var int WarmupCountDown;

var array<string>    WeaponList;            // A list of weapons that the players have to go through to win
var array<string>    StandardWeaponList;    // A list of weapons that the players have to go through to win that includes the longer list of weapons weapons
var array<string>    ShortWeaponList;    // A list of weapons that the players have to go through to win that is shortened down
//var string FinalWeapon;                   // The final weapon to get a kill with to get the victory
var localized string WarmupDescription;
var localized string ReverseDescription;
var localized string ShortListDescription;

static function Texture GetRandomTeamSymbol(int base)
{
    return Texture'Engine.S_Actor';
}
event Tick(float DeltaTime);
function DramaticEvent(float BaseZedTimePossibility, optional float DesiredZedTimeDuration);
function ShowPathTo(PlayerController P, int TeamNum);
function DoBossDeath();

event PostLogin( PlayerController NewPlayer )
{
    local int i;

    Super.PostLogin(NewPlayer);

    // Precache all the weapons
    if ( KFPlayerController(NewPlayer) != none )
    {
        for ( i = 0; i < StandardWeaponList.Length; i++ )
        {
            KFPlayerController(NewPlayer).ClientWeaponSpawned(class<Weapon>(BaseMutator.GetInventoryClass(StandardWeaponList[i])), none);
        }
    }
}

// For now don't dynamically load/unload weapons. TODO: find a way to dynamically
// load a set of the GG weapons at a time to save on memory
function WeaponSpawned(Inventory Weapon){}
function WeaponDestroyed(class<Weapon> WeaponClass){}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super(Info).FillPlayInfo(PlayInfo);  // Always begin with calling parent

    PlayInfo.AddSetting(default.GameGroup,   "TimeLimit",GetDisplayText("TimeLimit"),0, 0, "Text","3;0:999");
    PlayInfo.AddSetting(default.GameGroup,   "WarmupTime",default.WarmupDescription,0, 0, "Text","3;0:999");
    PlayInfo.AddSetting(default.GameGroup, "bReverseList",    default.ReverseDescription,    0, 0, "Check",             ,    ,True,True);
    PlayInfo.AddSetting(default.GameGroup, "bShortList", default.ShortListDescription,    0, 0, "Check",             ,    ,True,True);

    //AddSetting(string Group, string PropertyName, string Description, byte SecLevel, byte Weight, string RenderType, optional string Extras, optional string ExtraPrivs, optional bool bMultiPlayerOnly, optional bool bAdvanced);
    //PlayInfo.AddSetting(default.GameGroup,   "NumAmmoSpawns","Num Ammo Pickups",0, 0, "Text","2;0:10");

    PlayInfo.AddSetting(default.ServerGroup,   "MinPlayers","Num Bots",0, 0, "Text","2;0:64",,True,True);
    PlayInfo.AddSetting(default.ServerGroup, "LobbyTimeOut",    GetDisplayText("LobbyTimeOut"),        0, 1, "Text",    "3;0:120",    ,True,True);
    PlayInfo.AddSetting(default.ServerGroup, "bAdminCanPause",    GetDisplayText("bAdminCanPause"),    1, 1, "Check",             ,    ,True,True);
    PlayInfo.AddSetting(default.ServerGroup, "MaxSpectators",    GetDisplayText("MaxSpectators"),    1, 1, "Text",     "6;0:32",    ,True,True);
    PlayInfo.AddSetting(default.ServerGroup, "MaxPlayers",        GetDisplayText("MaxPlayers"),        0, 1, "Text",      "6;0:32",    ,True);
    PlayInfo.AddSetting(default.ServerGroup, "MaxIdleTime",        GetDisplayText("MaxIdleTime"),        0, 1, "Text",    "3;0:300",    ,True,True);

    // Add GRI's PIData
    if (default.GameReplicationInfoClass != None)
    {
        default.GameReplicationInfoClass.static.FillPlayInfo(PlayInfo);
        PlayInfo.PopClass();
    }

    if (default.VoiceReplicationInfoClass != None)
    {
        default.VoiceReplicationInfoClass.static.FillPlayInfo(PlayInfo);
        PlayInfo.PopClass();
    }

    if (default.BroadcastClass != None)
        default.BroadcastClass.static.FillPlayInfo(PlayInfo);
    else class'BroadcastHandler'.static.FillPlayInfo(PlayInfo);

    PlayInfo.PopClass();

    if (class'Engine.GameInfo'.default.VotingHandlerClass != None)
    {
        class'Engine.GameInfo'.default.VotingHandlerClass.static.FillPlayInfo(PlayInfo);
        PlayInfo.PopClass();
    }
}

static event string GetDescriptionText(string PropName)
{
    switch (PropName)
    {
        //case "NumAmmoSpawns":        return "Number of ammo pickups that can be available at once.";
        //case "MinPlayers":        return "Minimum number of players in game (rest will be filled with bots.";
        //case "InitGrenadesCount":    return "Initial amount of grenades players start with.";
        case "WarmupTime":        return default.WarmupDescription;
        case "bReverseList":        return default.ReverseDescription;
    }
    return Super.GetDescriptionText(PropName);
}

function bool CheckMaxLives(PlayerReplicationInfo Scorer)
{
    return false;
}

event PreBeginPlay()
{
    local int i;

    Super(xTeamGame).PreBeginPlay();
    GameReplicationInfo.bNoTeamSkins = true;
    GameReplicationInfo.bForceNoPlayerLights = true;
    GameReplicationInfo.bNoTeamChanges = false;


    if( bShortList )
    {
        for ( i = 0; i < ShortWeaponList.Length; i++ )
        {
            if( bReverseList )
            {
                if( ShortWeaponList[i] != "" )
                {
                    if( i > 0 )
                    {
                        WeaponList[WeaponList.Length] = ShortWeaponList[ShortWeaponList.Length - (i + 1)];

                    }
                }
            }
            else
            {
                if( ShortWeaponList[i] != "" )
                {
                    WeaponList[i] = ShortWeaponList[i];
                }
            }
        }
    }
    else
    {
        for ( i = 0; i < StandardWeaponList.Length; i++ )
        {
            if( bReverseList )
            {
                if( StandardWeaponList[i] != "" )
                {
                    if( i > 0 )
                    {
                        WeaponList[WeaponList.Length] = StandardWeaponList[StandardWeaponList.Length - (i + 1)];

                    }
                }
            }
            else
            {
                if( StandardWeaponList[i] != "" )
                {
                    WeaponList[i] = StandardWeaponList[i];
                }
            }
        }
    }

    // Add the final weapon when in reverse mode
    if( bReverseList )
    {
        if( bShortList )
        {
            if( ShortWeaponList[ShortWeaponList.Length - 1] != "" )
            {
                WeaponList[WeaponList.Length] = ShortWeaponList[ShortWeaponList.Length-1];
            }
        }
        else
        {
            if( StandardWeaponList[StandardWeaponList.Length - 1] != "" )
            {
                WeaponList[WeaponList.Length] = StandardWeaponList[StandardWeaponList.Length-1];
            }
        }
    }

//    for ( i = 0; i < WeaponList.Length; i++ )
//    {
//        log("i = "$i$" WeaponList.Length = "$WeaponList.Length$" WeaponList[i] = "$WeaponList[i]);
//    }

    KFGGGameReplicationInfo(GameReplicationInfo).MaxWeaponLevel = WeaponList.Length;
}

event InitGame( string Options, out string Error )
{
    local KFLevelRules KFLRit;
    local ShopVolume SH;
    local ZombieVolume ZZ;

    MaxLives = 0;
    Super(DeathMatch).InitGame(Options, Error);

    foreach DynamicActors(class'KFLevelRules',KFLRit)
        KFLRit.Destroy();
    foreach AllActors(class'ShopVolume',SH)
        ShopList[ShopList.Length] = SH;
    foreach AllActors(class'ZombieVolume',ZZ)
        ZedSpawnList[ZedSpawnList.Length] = ZZ;
//    foreach AllActors(class'KFRandomSpawn',RS)
//    {
//        TestSpawnPoint(RS);
//        RS.SetTimer(0,false);
//        RS.Destroy();
//    }
//    foreach AllActors(class'Pickup',I)
//    {
//        TestSpawnPoint(I);
//        I.Destroy();
//    }
//    if( SpawningPoints.Length==0 )
//        Warn("Could not find any possible spawn areas on this map!!!");
//    for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
//        if( PlayerStart(N)!=None && PointIsGood(N.Location) )
//            SpawningPoints[SpawningPoints.Length] = PlayerStart(N);
//    if( SpawnTester!=None )
//        SpawnTester.Destroy();

    //provide default rules if mapper did not need custom one
    if(KFLRules==none)
        KFLRules = spawn(class'KFLevelRules');
}

function UnrealTeamInfo GetBotTeam(optional int TeamBots)
{
    return Super(xTeamGame).GetBotTeam(TeamBots);
}

function byte PickTeam(byte num, Controller C)
{
    return Super(TeamGame).PickTeam(num,C);

//    if( C.PlayerReplicationInfo.Team.TeamIndex == 0 )
//    {
//           C.SetPawnClass(DefaultPlayerClassName, "Sergeant_Powers");
//    }
//    else if( C.PlayerReplicationInfo.Team.TeamIndex == 1 )
//    {
//           C.SetPawnClass(DefaultPlayerClassName, "Police_Constable_Briar");
//    }
}

function bool ChangeTeam(Controller Other, int num, bool bNewTeam)
{
    return Super(xTeamGame).ChangeTeam(Other,num,bNewTeam);

//    if( Other.PlayerReplicationInfo.Team.TeamIndex == 0 )
//    {
//           Other.SetPawnClass(DefaultPlayerClassName, "Sergeant_Powers");
//    }
//    else if( Other.PlayerReplicationInfo.Team.TeamIndex == 1 )
//    {
//           Other.SetPawnClass(DefaultPlayerClassName, "Police_Constable_Briar");
//    }
}

static event bool AcceptPlayInfoProperty(string PropertyName)
{
    return Super(GameInfo).AcceptPlayInfoProperty(PropertyName);
}

/* Rate whether player should choose this NavigationPoint as its start
*/
function float RatePlayerStart(NavigationPoint N, byte Team, Controller Player)
{
    return super(TeamGame).RatePlayerStart(N,Team,Player);
}

exec function AddBots(int num)
{
    num = Clamp(num, 0, 32 - (NumPlayers + NumBots));

    while (--num >= 0)
    {
        if ( Level.NetMode != NM_Standalone )
            MinPlayers = Max(MinPlayers + 1, NumPlayers + NumBots + 1);
        AddBot();
    }
}

function Bot SpawnBot(optional string botName)
{
    local KFGGBot NewBot;
    local RosterEntry Chosen;
    local UnrealTeamInfo BotTeam;

    BotTeam = GetBotTeam();
    Chosen = BotTeam.ChooseBotClass(botName);

    if (Chosen.PawnClass == None)
        Chosen.Init(); //amb
    NewBot = Spawn(class'KFGGBot');

    if ( NewBot != None )
        InitializeBot(NewBot,BotTeam,Chosen);
    NewBot.PlayerReplicationInfo.Score = StartingCash;

    return NewBot;
}

//function int ReduceDamage(int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
//{
//    if( instigatedBy!=None && instigatedBy!=injured && injured.GetTeamNum()==instigatedBy.GetTeamNum() )
//    {
//        if( FriendlyFireScale==0.f || Damage<=0 )
//            return 0;
//        else return Super.ReduceDamage(Max(Damage*FriendlyFireScale,1),injured,instigatedBy,HitLocation,Momentum,DamageType);
//    }
//    return Super.ReduceDamage(Damage,injured,instigatedBy,HitLocation,Momentum,DamageType);
//}

function PlayEndOfMatchMessage()
{
    local Controller C;

    for ( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if ( C.IsA('PlayerController') )
        {
            //PlayerController(C).ClientPlaySound(Sound'KF_MaleVoiceOne.Insult_Specimens_9',true,2.f,SLOT_Talk);
            if( FRand() < 0.25 )
            {
                PlayerController(C).ClientPlaySound(Sound'KF_BasePatriarch.Kev_Victory5',true,2.f,SLOT_Talk);
            }
            else if( FRand() < 0.25 )
            {
                PlayerController(C).ClientPlaySound(Sound'KF_BasePatriarch.Kev_Victory3',true,2.f,SLOT_Talk);
            }
            else if( FRand() < 0.25 )
            {
                PlayerController(C).ClientPlaySound(Sound'KF_BasePatriarch.Kev_Victory2',true,2.f,SLOT_Talk);
            }
            else
            {
                PlayerController(C).ClientPlaySound(Sound'KF_BasePatriarch.Kev_Talk3',true,2.f,SLOT_Talk);
            }
        }
    }
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
    local Controller P, NextController;
    local PlayerController Player;

    if ( (GameRulesModifiers != None) && !GameRulesModifiers.CheckEndGame(Winner, Reason) )
        return false;

//    if ( Winner == None )
//    {
//        // find winner
//        for ( P=Level.ControllerList; P!=None; P=P.nextController )
//            if ( P.bIsPlayer && ((Winner == None) || (P.PlayerReplicationInfo.Kills>= Winner.Kills)) )
//            {
//                Winner = P.PlayerReplicationInfo;
//            }
//    }

    // check for tie
//    for ( P=Level.ControllerList; P!=None; P=P.nextController )
//    {
//        if ( P.bIsPlayer && (Winner != P.PlayerReplicationInfo) && (P.PlayerReplicationInfo.Kills==Winner.Kills) )
//        {
//            if ( !bOverTimeBroadcast )
//            {
//                BroadcastLocalizedMessage(class'KFDMTimeMessage', -1);
//                bOverTimeBroadcast = true;
//            }
//            return false;
//        }
//    }

    EndTime = Level.TimeSeconds + EndTimeDelay + 5;
    GameReplicationInfo.Winner = Winner;

    EndGameFocus = Controller(Winner.Owner).Pawn;
    if ( EndGameFocus != None )
        EndGameFocus.bAlwaysRelevant = true;
    for ( P=Level.ControllerList; P!=None; P=NextController )
    {
        NextController = P.NextController;
        Player = PlayerController(P);
        if ( Player != None )
        {
            //if ( !Player.PlayerReplicationInfo.bOnlySpectator )
            //    PlayWinMessage(Player, (Player.PlayerReplicationInfo == Winner));
            Player.ClientSetBehindView(true);
            if ( EndGameFocus != None )
            {
                Player.ClientSetViewTarget(EndGameFocus);
                Player.SetViewTarget(EndGameFocus);
            }
            Player.ClientGameEnded();
        }
        P.GameHasEnded();
    }
    return true;
}

// Function used for debugging levelling up
function ForceLevelUp(Controller Killer)
{
    local class<Weapon> WeaponClass;

    WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));

    if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < (WeaponList.Length - 1) )
    {
        if( KFGGHumanPawn(Killer.Pawn) != none )
        {
            KFGGHumanPawn(Killer.Pawn).ClearOutCurrentWeapons();
        }

        KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
        Killer.PlayerReplicationInfo.Score += 1;

        if( KFGGHumanPawn(Killer.Pawn) != none )
        {
            KFGGHumanPawn(Killer.Pawn).CreateInventory(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel]);
            Killer.SwitchToBestWeapon();
        }

        if( PlayerController(Killer) != none )
        {
            PlayerController(Killer).ClientPlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Exit',true,2.f,SLOT_None);
        }

        if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.25) )
        {
            BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0,Killer.PlayerReplicationInfo,,WeaponClass);
        }
        else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.5) )
        {
            BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0,Killer.PlayerReplicationInfo,,WeaponClass);
        }
        else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.75) )
        {
            BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0,Killer.PlayerReplicationInfo,,WeaponClass);
        }
        else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == (WeaponList.Length - 1) )
        {
            BroadcastLocalizedMessage(class'GGAnnouncementMessage', 1,Killer.PlayerReplicationInfo,,WeaponClass);
        }
    }
    else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < WeaponList.Length )
    {
        KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
        Killer.PlayerReplicationInfo.Score += 1;
    }
}

function Killed(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType)
{
    local bool bKilledWithRightWeapon;
    local bool bKnifeKill;
    local Controller C;
    local string S;
    local class<Weapon> WeaponClass;

    Super(DeathMatch).Killed(Killer,Killed,KilledPawn,DamageType);

    if( KFGGPRI(Killer.PlayerReplicationInfo) != none &&
        Killer.PlayerReplicationInfo.Team.TeamIndex != Killed.PlayerReplicationInfo.Team.TeamIndex )
    {
        if( class<DamTypeKnife>(damageType) != none && KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < (WeaponList.Length - 1)
            && KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel > 0 )
        {
            bKnifeKill = true;
            bKilledWithRightWeapon = true;
        }

        if( !bKnifeKill )
        {
            // Check to make sure they got a kill with the right weapon
            if( class<WeaponDamageType>(damageType).default.WeaponClass == BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel]) )
            {
                bKilledWithRightWeapon = true;
            }
            // Special handling for weapons that don't apparantly have the weapon class plugged into the damage type
            // TODO: fix up the base damage classes to have thier weapon class plugged
            // in!!! - Ramm
            else if( WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFMod.Single" &&
                class<DamTypeDualies>(damageType) != none )
            {
                bKilledWithRightWeapon = true;
            }
            else if( WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFMod.BoomStick" &&
                class<DamTypeDBShotgun>(damageType) != none )
            {
                bKilledWithRightWeapon = true;
            }
            else if( WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFMod.Crossbow" &&
                class<DamTypeCrossbow>(damageType) != none || class<DamTypeCrossbowHeadShot>(damageType) != none )
            {
                bKilledWithRightWeapon = true;
            }
            else if( WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFMod.FlameThrower" &&
                class<DamTypeBurned>(damageType) != none )
            {
                bKilledWithRightWeapon = true;
            }
            else if( WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFGunGame.GG_M79GrenadeLauncher" &&
                class<DamTypeM79Grenade>(damageType) != none )
            {
                bKilledWithRightWeapon = true;
            }
            else if( WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFGunGame.GG_M4203AssaultRifle" &&
                class<DamTypeM203Grenade>(damageType) != none || class<DamTypeM4203AssaultRifle>(damageType) != none )
            {
                bKilledWithRightWeapon = true;
            }
            else if( WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFGunGame.GG_M32GrenadeLauncher" &&
                class<DamTypeM32Grenade>(damageType) != none )
            {
                bKilledWithRightWeapon = true;
            }
            else if( WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFGunGame.GG_HuskGun" &&
                class<DamTypeBurned>(damageType) != none || class<DamTypeHuskGun>(damageType) != none
                || class<DamTypeHuskGunProjectileImpact>(damageType) != none )
            {
                bKilledWithRightWeapon = true;
            }
            else if( WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFGunGame.GG_LAW" &&
                class<DamTypeLAW>(damageType) != none )
            {
                bKilledWithRightWeapon = true;
            }
        }

        if( bKilledWithRightWeapon )
        {
            if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < (WeaponList.Length - 1) )
            {
                if( KFGGHumanPawn(Killer.Pawn) != none )
                {
                    KFGGHumanPawn(Killer.Pawn).ClearOutCurrentWeapons();
                }

                KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
                Killer.PlayerReplicationInfo.Score += 1;

                if( KFGGHumanPawn(Killer.Pawn) != none )
                {
                    KFGGHumanPawn(Killer.Pawn).CreateInventory(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel]);
                    Killer.SwitchToBestWeapon();
                }

                if( PlayerController(Killer) != none )
                {
                    PlayerController(Killer).ClientPlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Exit',true,2.f,SLOT_None);
                }

                if( bKnifeKill && KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel > 0 )
                {
//                    if( Killer.Pawn != none )
//                    {
//                        Killer.Pawn.PlayOwnedSound(Sound'KF_MaleVoiceOne.Insult_Specimens_9', SLOT_Talk,2.0,true,500);
//                        PlayerController(Killer).ClientPlaySound(Sound'KF_MaleVoiceOne.Insult_Specimens_9',true,2.f,SLOT_Talk);
//                    }

                    BroadcastLocalizedMessage(class'GGAnnouncementMessage', 2,Killer.PlayerReplicationInfo,Killed.PlayerReplicationInfo);

                    if( KFGGHumanPawn(Killed.Pawn) != none )
                    {
                        KFGGHumanPawn(Killed.Pawn).ClearOutCurrentWeapons();
                    }

                    KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel--;
                    Killed.PlayerReplicationInfo.Score -= 1;

                    if( KFGGHumanPawn(Killed.Pawn) != none )
                    {
                        KFGGHumanPawn(Killed.Pawn).CreateInventory(WeaponList[KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel]);
                        Killed.SwitchToBestWeapon();
                    }
                    PlayerController(Killed).ClientPlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Enter',true,2.f,SLOT_None);
                }

                if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.25) )
                {
                    WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
                    BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0,Killer.PlayerReplicationInfo,Killed.PlayerReplicationInfo,WeaponClass);
                }
                else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.5) )
                {
                    WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
                    BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0,Killer.PlayerReplicationInfo,Killed.PlayerReplicationInfo,WeaponClass);
                }
                else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.75) )
                {
                    WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
                    BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0,Killer.PlayerReplicationInfo,Killed.PlayerReplicationInfo,WeaponClass);
                }
                else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == (WeaponList.Length - 1) )
                {
                    WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
                    BroadcastLocalizedMessage(class'GGAnnouncementMessage', 1,Killer.PlayerReplicationInfo,Killed.PlayerReplicationInfo,WeaponClass);
                }
            }
            else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < WeaponList.Length )
            {
                KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
                Killer.PlayerReplicationInfo.Score += 1;
            }
        }

        if( !bDoingWarmup && KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel >= WeaponList.Length )
        {
            MusicPlaying = True;
            CalmMusicPlaying = False;

            // Give the guy that won 100% health so we won't get any weird dying hud effects or sounds
            if( Killer.Pawn != none )
            {
                Killer.Pawn.GiveHealth(100,Killer.Pawn.HealthMax);
            }

            if( FRand() < 0.5 )
            {
                S = "DirgeDisunion1";
            }
            else
            {
                S = "KF_Containment";
            }

            for( C=Level.ControllerList;C!=None;C=C.NextController )
            {
                if (KFPlayerController(C)!= none)
                    KFPlayerController(C).NetPlayMusic(S, 0.25,1.0);
            }

            EndGame(Killer.PlayerReplicationInfo,"fraglimit");
        }
    }
}

function AmmoPickedUp(KFAmmoPickup PickedUp)
{
    PickedUp.Destroy(); // Kill all ammo pickups.
}

//event PlayerController Login
//(
//    string Portal,
//    string Options,
//    out string Error
//)
//{
//    local PlayerController NewPlayer;
//
//    NewPlayer = Super.Login(Portal, Options, Error);
//
//    if( NewPlayer.PlayerReplicationInfo.Team.TeamIndex == 0 )
//    {
//           NewPlayer.SetPawnClass(DefaultPlayerClassName, "Sergeant_Powers");
//    }
//    else  if( NewPlayer.PlayerReplicationInfo.Team.TeamIndex == 1 )
//    {
//           NewPlayer.SetPawnClass(DefaultPlayerClassName, "Police_Constable_Briar");
//    }
//
////       // Green
////       Corporal_Lewis
////       Lieutenant_Masterson
////       Sergeant_Powers
////
////    // Blue
////    Police_Constable_Briar
////    Police_Sergeant_Davin
//
//    return NewPlayer;
//}

function int ReduceDamage( int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{

//    WeaponList(0)="KFMod.Single"
//    WeaponList(1)="KFMod.Dualies"
//    WeaponList(2)="KFMod.Magnum44Pistol"
//    WeaponList(3)="KFMod.Dual44Magnum"
//    WeaponList(4)="KFMod.Winchester"
//    WeaponList(5)="KFMod.MAC10MP"
//    WeaponList(6)="KFMod.MP7MMedicGun"
//    WeaponList(7)="KFMod.MP5MMedicGun"
//    WeaponList(8)="KFMod.Bullpup"
//    WeaponList(9)="KFMod.Crossbow"
//    WeaponList(10)="KFMod.Shotgun"
//    WeaponList(11)="KFMod.FlameThrower"
//    WeaponList(12)="KFMod.Deagle"
//    WeaponList(13)="KFMod.M4AssaultRifle"
//    WeaponList(14)="KFMod.AK47AssaultRifle"
//    WeaponList(15)="KFMod.BoomStick"
//    WeaponList(16)="KFMod.M14EBRBattleRifle"
//    WeaponList(17)="KFMod.DualDeagle"
//    WeaponList(18)="KFMod.BenelliShotgun"
//    WeaponList(19)="KFGunGame.GG_M79GrenadeLauncher"
//    WeaponList(20)="KFMod.SCARMK17AssaultRifle"
//    WeaponList(21)="KFGunGame.GG_M4203AssaultRifle"
//    WeaponList(22)="KFGunGame.GG_M32GrenadeLauncher"
//    WeaponList(23)="KFGunGame.GG_HuskGun"
//    WeaponList(24)="KFMod.AA12AutoShotgun"
//    WeaponList(25)="KFGunGame.GG_LAW"
//    WeaponList(26)="KFMod.Katana"

    // Adjust damage for gungame, as KF weapons were all balanced for shooting zombies not players! :)
    if( class<DamTypeDualies>(damageType) != none || class<DamTypeMK23Pistol>(damageType) != none
        || class<DamTypeDualMK23Pistol>(damageType) != none)
    {
        Damage *= 0.5;
    }
    else if( class<DamTypeMagnum44Pistol>(damageType) != none || class<DamTypeDual44Magnum>(damageType) != none )
    {
        Damage *= 0.5;
    }
    else if( class<DamTypeWinchester>(damageType) != none )
    {
        Damage *= 0.75;
    }
    else if( class<DamTypeMAC10MP>(damageType) != none )
    {
        Damage *= 0.65;
    }
    else if( class<DamTypeMP7M>(damageType) != none )
    {
        Damage *= 0.65;
    }
    else if( class<DamTypeMP5M>(damageType) != none )
    {
        Damage *= 0.65;
    }
    else if( class<DamTypeBullpup>(damageType) != none )
    {
        Damage *= 1.0;
    }
    else if( class<DamTypeCrossbow>(damageType) != none || class<DamTypeCrossbowHeadShot>(damageType) != none
        || class<DamTypeM99SniperRifle>(damageType) != none || class<DamTypeM99HeadShot>(damageType) != none)
    {
        Damage *= 0.65;
    }
    else if( class<DamTypeShotgun>(damageType) != none || class<DamTypeKSGShotgun>(damageType) != none )
    {
        Damage *= 0.41;// 1 Hit kill if all pellets hit you
    }
    else if( class<DamTypeBurned>(damageType) != none )
    {
        Damage *= 2.0;
    }
    else if( class<DamTypeDeagle>(damageType) != none || class<DamTypeDualDeagle>(damageType) != none )
    {
        Damage *= 0.5;
    }
    else if( class<DamTypeM4AssaultRifle>(damageType) != none || class<DamTypeM4203AssaultRifle>(damageType) != none )
    {
        Damage *= 0.75;
    }
    else if( class<DamTypeAK47AssaultRifle>(damageType) != none )
    {
        Damage *= 0.75;
    }
    else if( class<DamTypeDBShotgun>(damageType) != none )
    {
        Damage *= 0.3;
    }
    else if( class<DamTypeM14EBR>(damageType) != none || class<DamTypeM7A3M>(damageType) != none )
    {
        Damage *= 0.75;
    }
    else if( class<DamTypeSCARMK17AssaultRifle>(damageType) != none || class<DamTypeFNFALAssaultRifle>(damageType) != none )
    {
        Damage *= 0.65;
    }
    else if( class<DamTypeAA12Shotgun>(damageType) != none )
    {
        Damage *= 0.35;
    }
    else if( class<DamTypeBenelli>(damageType) != none )
    {
        Damage *= 0.35;
    }
    else if( class<DamTypeM79Grenade>(damageType) != none || class<DamTypeM203Grenade>(damageType) != none)
    {
        Damage *= 0.4;
    }
    else if( class<DamTypeM32Grenade>(damageType) != none )
    {
        Damage *= 0.3;
    }
    else if( class<DamTypeLAW>(damageType) != none )
    {
        Damage *= 0.15;
    }
    else if( class<DamTypeKatana>(damageType) != none )
    {
        Damage *= 0.8;
    }
    else if( class<DamTypeRocketImpact>(damageType) != none )
    {
        Damage *= 0.25;
    }
    else if( class<DamTypeHuskGun>(damageType) != none )
    {
        Damage *= 1.0;
    }
    else if( class<DamTypeHuskGunProjectileImpact>(damageType) != none )
    {
        Damage *= 0.3;
    }
    else if( class<DamTypeKnife>(damageType) != none )
    {
        Damage *= 3.0;
    }

    return Super.ReduceDamage( Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );
}

function ScoreKill(Controller Killer, Controller Other)
{
    if ( GameRulesModifiers != None )
        GameRulesModifiers.ScoreKill(Killer, Other);

    if( (killer == Other) || (killer == None) )
    {
        return;
    }

    if ( Killer.PlayerReplicationInfo==None )
        return;

    Killer.PlayerReplicationInfo.Kills++;
    Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
    ScoreEvent(Killer.PlayerReplicationInfo, 1, "frag");
}

function AddGameSpecificInventory(Pawn p)
{
    p.CreateInventory(WeaponList[KFGGPRI(p.PlayerReplicationInfo).WeaponLevel]);
    p.Controller.SwitchToBestWeapon();
}

final function UpdateViewsNow()
{
    local Controller C;

    for( C=Level.ControllerList; C!=None; C=C.nextController )
    {
        if( C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && PlayerController(C)!=None && C.Pawn!=None )
        {
            PlayerController(C).ClientSetBehindView(false);
            PlayerController(C).ClientSetViewTarget(C.Pawn);
            //PlayerController(C).ReceiveLocalizedMessage(Class'KFMainMessages',3);
        }
//        else if( KFInvasionBot(C)!=None && C.Pawn!=None && FRand()<0.5f )
//            KFInvasionBot(C).DoTrading();
    }
}

function CheckScore(PlayerReplicationInfo Scorer);

function RestartPlayer( Controller aPlayer )
{
    if ( aPlayer.PlayerReplicationInfo.bOutOfLives || aPlayer.Pawn!=None )
        return;
    if( aPlayer.PlayerReplicationInfo.Team.TeamIndex==0 )
        aPlayer.PawnClass = Class'KFRedGGPlayer';
    else aPlayer.PawnClass = Class'KFBlueGGPlayer';
    aPlayer.PreviousPawnClass = aPlayer.PawnClass;
    KFPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).ClientVeteranSkill = Class'KFVeterancyTypes';
    aPlayer.PlayerReplicationInfo.Score = Max(MinRespawnCash, int(aPlayer.PlayerReplicationInfo.Score));
    Super(Invasion).RestartPlayer(aPlayer);
}

function Timer()
{
    Super(xTeamGame).Timer();
}

auto State PendingMatch
{
    function RestartPlayer( Controller aPlayer )
    {
        if ( CountDown <= 0 )
            Super.RestartPlayer(aPlayer);
    }

    function Timer()
    {
        local Controller P;
        local bool bReady;

        Global.Timer();

        // first check if there are enough net players, and enough time has elapsed to give people
        // a chance to join
        if ( NumPlayers == 0 )
            bWaitForNetPlayers = true;

        if ( bWaitForNetPlayers && (Level.NetMode != NM_Standalone) )
        {
             if ( NumPlayers >= MinNetPlayers )
                ElapsedTime++;
            else
                ElapsedTime = 0;
            if ( (NumPlayers == MaxPlayers) || (ElapsedTime > NetWait) )
            {
                bWaitForNetPlayers = false;
                CountDown = Default.CountDown;
            }
        }

        if ( (Level.NetMode != NM_Standalone) && (bWaitForNetPlayers || (bTournament && (NumPlayers < MaxPlayers))) )
        {
               PlayStartupMessage();
            return;
        }

        // check if players are ready
        bReady = true;
        StartupStage = 1;
        if ( !bStartedCountDown && (bTournament /*|| bPlayersMustBeReady*/ || (Level.NetMode == NM_Standalone)) )
        {
            for (P=Level.ControllerList; P!=None; P=P.NextController )
                if ( P.IsA('PlayerController') && (P.PlayerReplicationInfo != None)
                    && P.bIsPlayer && P.PlayerReplicationInfo.bWaitingPlayer
                    && !P.PlayerReplicationInfo.bReadyToPlay )
                    bReady = false;
        }
        if ( bReady && !bReviewingJumpspots )
        {
            bStartedCountDown = true;
            CountDown--;
            if ( CountDown <= 0 )
                StartMatch();
            else
                StartupStage = 5 - CountDown;
        }
        if( !bDidWarmup && WarmupTime > 0 )
        {
            PlayWarmupMessage();
        }
        else
        {
            PlayStartupMessage();
        }
    }

    function beginstate()
    {
        bWaitingToStartMatch = true;
        StartupStage = 0;
        WarmupCountDown=WarmupTime;
//        if ( IsA('xLastManStandingGame') )
//            NetWait = Max(NetWait,10);
    }

//    function EndState()
//    {
//        KFGameReplicationInfo(GameReplicationInfo).LobbyTimeout = -1;
//    }

Begin:
    if ( bQuickStart )
        StartMatch();
}

function PlayStartupMessage()
{
    local Controller P;

    // keep message displayed for waiting players
    for (P=Level.ControllerList; P!=None; P=P.NextController )
        if ( UnrealPlayer(P) != None )
            UnrealPlayer(P).PlayStartUpMessage(StartupStage);
}

function PlayWarmupMessage()
{
    local Controller P;

    // keep message displayed for waiting players
    for (P=Level.ControllerList; P!=None; P=P.NextController )
        if ( KFGGPlayerController(P) != None )
            KFGGPlayerController(P).PlayWarmupMessage(StartupStage);
}


state MatchInProgress
{
    function OpenShops();
    function CloseShops();

    function Timer()
    {
        local Controller C;

        Global.Timer();

        for( C=Level.ControllerList; C!=None; C=C.nextController )
            if( C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && C.Pawn == none/*C.PlayerReplicationInfo.bReadyToPlay
             && C.IsA('PlayerController') && C.IsInState('PlayerWaiting')*/ )
                RestartPlayer(C);

        if ( !bFinalStartup )
        {
            bFinalStartup = true;
            UpdateViewsNow();
        }

        if ( NeedPlayers() && AddBot() && (RemainingBots > 0) )
            RemainingBots--;
        ElapsedTime++;
        GameReplicationInfo.ElapsedTime = ElapsedTime;

        if( !bDidWarmup && WarmupTime > 0 )
        {
            WarmupCountDown--;

            if( WarmupCountDown <= (Default.CountDown - 1) && WarmupCountDown > 0 )
            {
                StartupStage = 5 - WarmupCountDown;

                PlayStartupMessage();
            }

            if( WarmupCountDown <= 0 )
            {
                ResetBeforeMatchStart();
                bDidWarmup = true;
                bDoingWarmup = false;
                StartMatch();

                for( C=Level.ControllerList; C!=None; C=C.nextController )
                    if( C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && C.Pawn == none/*C.PlayerReplicationInfo.bReadyToPlay
                    && C.IsA('PlayerController') && C.IsInState('PlayerWaiting')*/ )
                {
                    RestartPlayer(C);
                }

                StartupStage = 5;
                PlayStartupMessage();
                StartupStage = 6;

            }
            else
            {
                bDoingWarmup = true;
            }

        }
        else
        {
            bDidWarmup = true;
        }

        if ( bOverTime )
            EndGame(None,"TimeLimit");
        else if ( TimeLimit > 0 )
        {
            GameReplicationInfo.bStopCountDown = false;
            RemainingTime--;
            GameReplicationInfo.RemainingTime = RemainingTime;
            if ( RemainingTime % 60 == 0 )
                GameReplicationInfo.RemainingMinute = RemainingTime;
            if( RemainingTime==600 || RemainingTime==300 || RemainingTime==180 || RemainingTime==120 || RemainingTime==60
                 || RemainingTime==30 || RemainingTime==20 || (RemainingTime<=10 && RemainingTime>=1) )
                BroadcastLocalizedMessage(class'KFGGTimeMessage', RemainingTime);
            if ( RemainingTime <= 0 )
                EndGame(None,"TimeLimit");
        }
    }

    function beginstate()
    {
        local PlayerReplicationInfo PRI;

        ForEach DynamicActors(class'PlayerReplicationInfo',PRI)
            PRI.StartTime = 0;
        ElapsedTime = 0;
        bWaitingToStartMatch = false;
        StartupStage = 5;
        if( !bDidWarmup && WarmupTime > 0 )
        {
            PlayWarmupMessage();
        }
        else
        {
            PlayStartupMessage();
        }
        StartupStage = 6;
    }
}

function ResetBeforeMatchStart()
{
    local Controller P, NextC;
    local Actor A;

    // Reset all controllers
    P = Level.ControllerList;
    while ( P != none )
    {
        NextC = P.NextController;

        if( AIController(P) != none)
        {
            bKillBots = true;
            P.Destroy();
            bKillBots = false;
            P = NextC;
            continue;
        }

        if( P.Pawn!=None && P.PlayerReplicationInfo!=None )
            P.Pawn.Destroy();

        if ( P.PlayerReplicationInfo == None || !P.PlayerReplicationInfo.bOnlySpectator )
        {
            if ( PlayerController(P) != None )
                PlayerController(P).ClientReset();
            P.Reset();

            if( P.PlayerReplicationInfo != none )
            {
                P.PlayerReplicationInfo.Score = 0;
                P.PlayerReplicationInfo.Deaths = 0;
                P.PlayerReplicationInfo.GoalsScored = 0;
                P.PlayerReplicationInfo.Kills = 0;
                if( TeamPlayerReplicationInfo(P.PlayerReplicationInfo) != none )
                {
                    TeamPlayerReplicationInfo(P.PlayerReplicationInfo).bFirstBlood = false;
                }

                if( KFGGPRI(P.PlayerReplicationInfo) != none )
                {
                    KFGGPRI(P.PlayerReplicationInfo).WeaponLevel = 0;
                }
            }
        }

        P = NextC;
    }

    // Reset ALL actors (except Controllers)
    foreach AllActors(class'Actor', A)
    {
        if (!A.IsA('Controller'))
            A.Reset();

        // Destroy any active projectiles
        if (A.IsA('Projectile'))
            A.Destroy();
    }

    for( P=Level.ControllerList; P!=None; P=NextC )
    {
        NextC = P.nextController;
        if( P.PlayerReplicationInfo!=None && !P.PlayerReplicationInfo.bOnlySpectator && P.PlayerReplicationInfo.Team!=None )
        {
            P.PlayerReplicationInfo.bOutOfLives = false;
            RestartPlayer(P);
        }
    }

    log("End RemainingBots = "$RemainingBots);

    bFinalStartup = false;
}

//final function StartNewRound()
//{
//    local Controller C,NC;
//    local array<Controller> CA;
//    local int i;
//    local Projectile P;
//
//    if( GoalScore>0 ) // Check winners
//    {
//        if( Teams[0].Score>=GoalScore )
//        {
//            EndGame(None,"fraglimit");
//            return;
//        }
//        else if( Teams[1].Score>=GoalScore )
//        {
//            EndGame(None,"fraglimit");
//            return;
//        }
//    }
//
//    // First kill all pawns.
//    for( C=Level.ControllerList; C!=None; C=NC )
//    {
//        NC = C.nextController;
//        if( C.Pawn!=None && C.PlayerReplicationInfo!=None )
//            C.Pawn.Destroy();
//    }
//
//    // Then even the teams.
//    if( Teams[0].Size>(Teams[1].Size+1) ) // To many Reds.
//    {
//        for( C=Level.ControllerList; C!=None; C=C.nextController )
//        {
//            if( C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.Team!=None
//             && C.PlayerReplicationInfo.Team.TeamIndex==0 )
//                CA[CA.Length] = C;
//        }
//        while( Teams[0].Size>(Teams[1].Size+1) && CA.Length>0 )
//        {
//            i = Rand(CA.Length);
//            ChangeTeam(CA[i],1,true);
//            CA.Remove(i,1);
//        }
//    }
//    else if( Teams[1].Size>(Teams[0].Size+1) ) // To many Blues.
//    {
//        for( C=Level.ControllerList; C!=None; C=C.nextController )
//        {
//            if( C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.Team!=None
//             && C.PlayerReplicationInfo.Team.TeamIndex==1 )
//                CA[CA.Length] = C;
//        }
//        while( Teams[1].Size>(Teams[0].Size+1) && CA.Length>0 )
//        {
//            i = Rand(CA.Length);
//            ChangeTeam(CA[i],0,true);
//            CA.Remove(i,1);
//        }
//    }
//
//    // Kill any active projectiles
//    foreach DynamicActors(Class'Projectile',P)
//        P.Destroy();
//
//    // Init new spawns and respawn players.
//    PickSpawnPoints();
//    for( C=Level.ControllerList; C!=None; C=NC )
//    {
//        NC = C.nextController;
//        if( C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.Team!=None )
//        {
//            C.PlayerReplicationInfo.bOutOfLives = false;
//            RestartPlayer(C);
//        }
//    }
//    bFinalStartup = false;
//}

state MatchOver
{
    function Timer()
    {
        local Controller C;

        Global.Timer();

        if ( !bGameRestarted && (Level.TimeSeconds > EndTime + RestartWait) )
            RestartGame();

        if ( EndGameFocus != None )
        {
            EndGameFocus.bAlwaysRelevant = true;
            for ( C = Level.ControllerList; C != None; C = C.NextController )
                if ( PlayerController(C) != None )
                    PlayerController(C).ClientSetViewtarget(EndGameFocus);
        }

        // play end-of-match message for winner/losers (for single and muli-player)
        EndMessageCounter++;
        if ( EndMessageCounter == EndMessageWait )
            PlayEndOfMatchMessage();
    }
    function BeginState()
    {
        GameReplicationInfo.bStopCountDown = true;
        KFGameReplicationInfo(GameReplicationInfo).EndGameType = 2;
    }
}

defaultproperties
{
     WarmUpTime=30
     StandardWeaponList(0)="KFMod.Single"
     StandardWeaponList(1)="KFMod.MK23Pistol"
     StandardWeaponList(2)="KFMod.Dualies"
     StandardWeaponList(3)="KFMod.DualMK23Pistol"
     StandardWeaponList(4)="KFMod.Magnum44Pistol"
     StandardWeaponList(5)="KFMod.Dual44Magnum"
     StandardWeaponList(6)="KFMod.Winchester"
     StandardWeaponList(7)="KFMod.MAC10MP"
     StandardWeaponList(8)="KFMod.MP7MMedicGun"
     StandardWeaponList(9)="KFMod.MP5MMedicGun"
     StandardWeaponList(10)="KFMod.Bullpup"
     StandardWeaponList(11)="KFMod.Crossbow"
     StandardWeaponList(12)="KFMod.Shotgun"
     StandardWeaponList(13)="KFMod.M7A3MMedicGun"
     StandardWeaponList(14)="KFMod.FlameThrower"
     StandardWeaponList(15)="KFMod.Deagle"
     StandardWeaponList(16)="KFMod.M4AssaultRifle"
     StandardWeaponList(17)="KFMod.KSGShotgun"
     StandardWeaponList(18)="KFMod.AK47AssaultRifle"
     StandardWeaponList(19)="KFMod.BoomStick"
     StandardWeaponList(20)="KFMod.M14EBRBattleRifle"
     StandardWeaponList(21)="KFMod.DualDeagle"
     StandardWeaponList(22)="KFMod.BenelliShotgun"
     StandardWeaponList(23)="KFGunGame.GG_M79GrenadeLauncher"
     StandardWeaponList(24)="KFMod.SCARMK17AssaultRifle"
     StandardWeaponList(25)="KFMod.FNFAL_ACOG_AssaultRifle"
     StandardWeaponList(26)="KFGunGame.GG_M4203AssaultRifle"
     StandardWeaponList(27)="KFGunGame.GG_M32GrenadeLauncher"
     StandardWeaponList(28)="KFMod.M99SniperRifle"
     StandardWeaponList(29)="KFGunGame.GG_HuskGun"
     StandardWeaponList(30)="KFMod.AA12AutoShotgun"
     StandardWeaponList(31)="KFGunGame.GG_LAW"
     StandardWeaponList(32)="KFMod.Katana"
     ShortWeaponList(0)="KFMod.Single"
     ShortWeaponList(1)="KFMod.MK23Pistol"
     ShortWeaponList(2)="KFMod.Dual44Magnum"
     ShortWeaponList(3)="KFMod.Winchester"
     ShortWeaponList(4)="KFMod.MP5MMedicGun"
     ShortWeaponList(5)="KFMod.Bullpup"
     ShortWeaponList(6)="KFMod.Crossbow"
     ShortWeaponList(7)="KFMod.M7A3MMedicGun"
     ShortWeaponList(8)="KFMod.FlameThrower"
     ShortWeaponList(9)="KFMod.M4AssaultRifle"
     ShortWeaponList(10)="KFMod.AK47AssaultRifle"
     ShortWeaponList(11)="KFMod.BoomStick"
     ShortWeaponList(12)="KFMod.M14EBRBattleRifle"
     ShortWeaponList(13)="KFMod.DualDeagle"
     ShortWeaponList(14)="KFMod.BenelliShotgun"
     ShortWeaponList(15)="KFGunGame.GG_M79GrenadeLauncher"
     ShortWeaponList(16)="KFMod.FNFAL_ACOG_AssaultRifle"
     ShortWeaponList(17)="KFGunGame.GG_M32GrenadeLauncher"
     ShortWeaponList(18)="KFMod.M99SniperRifle"
     ShortWeaponList(19)="KFMod.AA12AutoShotgun"
     ShortWeaponList(20)="KFGunGame.GG_LAW"
     ShortWeaponList(21)="KFMod.Katana"
     WarmupDescription="Warmup Time"
     ReverseDescription="Reverse Weapon List"
     ShortListDescription="Shorter Weapon List"
     bNoBots=False
     bSpawnInTeamArea=True
     TeamAIType(0)=Class'GGTeamAI'
     TeamAIType(1)=Class'GGTeamAI'
     RestartWait=30
     SpawnProtectionTime=2.000000
     DefaultMaxLives=0
     DefaultEnemyRosterClass="XGame.xTeamRoster"
     LoginMenuClass="KFGunGame.KFGGMidGameMenu"
     DefaultPlayerClassName="KFGunGame.KFGGHumanPawn"
     ScoreBoardType="KFGunGame.KFGGScoreBoard"
     HUDType="KFGunGame.GGHUDKillingFloor"
     MapListType="KFGunGame.GGMapList"
     MapPrefix="GG"
     BeaconName="GG"
     MaxLives=0
     TimeLimit=15
     MutatorClass="KFGunGame.KFGGBaseMut"
     PlayerControllerClass=Class'KFGGPlayerController'
     PlayerControllerClassName="KFGunGame.KFGGPlayerController"
     GameReplicationInfoClass=Class'KFGGGameReplicationInfo'
     GameName="KF Gun Game"
     Description="Gun Game With Killing Floor Weapons. Every kill instantly gets you the next weapon in the list. Be the first player to get a kill with every weapon on the list to win!"
     Acronym="GG"
}
