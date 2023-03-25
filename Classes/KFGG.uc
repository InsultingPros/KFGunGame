//=============================================================================
// KFGG
//=============================================================================
// Killing Floor Gun Game Game Type
//=============================================================================
// Killing Floor Source
// Copyright (C) 2011 John "Ramm-Jaeger" Gibson
// Some elements based off of KFTDM by Marco
//=============================================================================
class KFGG extends KFGameType
    config(KFGunGameGarbage);

var int WarmupTime; // How long to do a pre match warmup before starting the round
var bool bDidWarmup, bDoingWarmup;
var int WarmupCountDown;

var private transient KFGGGameReplicationInfo GG_GRI;
var private transient array<string> WeaponList;

static function Texture GetRandomTeamSymbol(int base) {
    return Texture'Engine.S_Actor';
}

event Tick(float DeltaTime){}
function DramaticEvent(float BaseZedTimePossibility, optional float DesiredZedTimeDuration){}
function ShowPathTo(PlayerController P, int TeamNum){}
function DoBossDeath(){}
// For now don't dynamically load/unload weapons. TODO: find a way to dynamically
// load a set of the GG weapons at a time to save on memory
function WeaponSpawned(Inventory Weapon){}
function WeaponDestroyed(class<Weapon> WeaponClass){}
function CheckScore(PlayerReplicationInfo Scorer){}

event PostLogin(PlayerController NewPlayer) {
    local int i;

    super.PostLogin(NewPlayer);

    // Precache all the weapons
    if (KFPlayerController(NewPlayer) != none) {
        for (i = 0; i < WeaponList.Length; i++) {
            KFPlayerController(NewPlayer).ClientWeaponSpawned(class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[i])), none);
        }
    }
}

function bool CheckMaxLives(PlayerReplicationInfo Scorer) {
    return false;
}

event PreBeginPlay() {
    local int i;

    super(xTeamGame).PreBeginPlay();

    GG_GRI = KFGGGameReplicationInfo(GameReplicationInfo);
    if (GG_GRI == none) {
        warn("This should NOT happen: KFGGGameReplicationInfo is none! Terminating.");
        Destroy();
        return;
    }
    WarmupTime = GG_GRI.WarmupTime;

    GameReplicationInfo.bNoTeamSkins = true;
    GameReplicationInfo.bForceNoPlayerLights = true;
    GameReplicationInfo.bNoTeamChanges = false;

    for (i = 0; i < 100; i += 1) {
        if (GG_GRI.Weapons[i] == "") {
            continue;
        }
        WeaponList[WeaponList.length] = GG_GRI.Weapons[i];
    }
}

event InitGame(string Options, out string Error) {
    local KFLevelRules KFLRit;
    local ShopVolume SH;
    local ZombieVolume ZZ;

    MaxLives = 0;
    super(DeathMatch).InitGame(Options, Error);

    foreach DynamicActors(class'KFLevelRules', KFLRit) {
        KFLRit.Destroy();
    }
    foreach AllActors(class'ShopVolume', SH) {
        ShopList[ShopList.Length] = SH;
    }
    foreach AllActors(class'ZombieVolume', ZZ) {
        ZedSpawnList[ZedSpawnList.Length] = ZZ;
    }
    // foreach AllActors(class'KFRandomSpawn',RS)
    // {
    //     TestSpawnPoint(RS);
    //     RS.SetTimer(0,false);
    //     RS.Destroy();
    // }
    // foreach AllActors(class'Pickup',I)
    // {
    //     TestSpawnPoint(I);
    //     I.Destroy();
    // }
    // if (SpawningPoints.Length==0 )
    //     Warn("Could not find any possible spawn areas on this map!!!");
    // for(N=Level.NavigationPointList; N!= none; N=N.nextNavigationPoint )
    //     if (PlayerStart(N)!= none && PointIsGood(N.Location) )
    //         SpawningPoints[SpawningPoints.Length] = PlayerStart(N);
    // if (SpawnTester!= none )
    //     SpawnTester.Destroy();

    // provide default rules if mapper did not need custom one
    if (KFLRules == none) {
        KFLRules = spawn(class'KFLevelRules');
    }
}

function UnrealTeamInfo GetBotTeam(optional int TeamBots) {
    return super(xTeamGame).GetBotTeam(TeamBots);
}

function byte PickTeam(byte num, Controller C) {
    return super(TeamGame).PickTeam(num, C);

    // if (C.PlayerReplicationInfo.Team.TeamIndex == 0 )
    // {
    //         C.SetPawnClass(DefaultPlayerClassName, "Sergeant_Powers");
    // }
    // else if (C.PlayerReplicationInfo.Team.TeamIndex == 1 )
    // {
    //         C.SetPawnClass(DefaultPlayerClassName, "Police_Constable_Briar");
    // }
}

function bool ChangeTeam(Controller Other, int num, bool bNewTeam) {
    return super(xTeamGame).ChangeTeam(Other, num, bNewTeam);

    // if (Other.PlayerReplicationInfo.Team.TeamIndex == 0 )
    // {
    //         Other.SetPawnClass(DefaultPlayerClassName, "Sergeant_Powers");
    // }
    // else if (Other.PlayerReplicationInfo.Team.TeamIndex == 1 )
    // {
    //         Other.SetPawnClass(DefaultPlayerClassName, "Police_Constable_Briar");
    // }
}

static event bool AcceptPlayInfoProperty(string PropertyName) {
    return super(GameInfo).AcceptPlayInfoProperty(PropertyName);
}

// Rate whether player should choose this NavigationPoint as its start
function float RatePlayerStart(NavigationPoint N, byte Team, Controller Player) {
    return super(TeamGame).RatePlayerStart(N, Team, Player);
}

exec function AddBots(int num) {
    num = Clamp(num, 0, 32 - (NumPlayers + NumBots));

    while (--num >= 0) {
        if (Level.NetMode != NM_Standalone) {
            MinPlayers = Max(MinPlayers + 1, NumPlayers + NumBots + 1);
        }
        AddBot();
    }
}

function Bot SpawnBot(optional string botName) {
    local KFGGBot NewBot;
    local RosterEntry Chosen;
    local UnrealTeamInfo BotTeam;

    BotTeam = GetBotTeam();
    Chosen = BotTeam.ChooseBotClass(botName);

    if (Chosen.PawnClass == none) {
        Chosen.Init(); //amb
    }
    NewBot = Spawn(class'KFGGBot');

    if (NewBot != none) {
        InitializeBot(NewBot, BotTeam, Chosen);
    }
    NewBot.PlayerReplicationInfo.Score = StartingCash;

    return NewBot;
}

//function int ReduceDamage(int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
//{
//    if (instigatedBy!= none && instigatedBy!=injured && injured.GetTeamNum()==instigatedBy.GetTeamNum() )
//    {
//        if (FriendlyFireScale==0.f || Damage<=0 )
//            return 0;
//        else return super.ReduceDamage(Max(Damage*FriendlyFireScale,1),injured,instigatedBy,HitLocation,Momentum,DamageType);
//    }
//    return super.ReduceDamage(Damage,injured,instigatedBy,HitLocation,Momentum,DamageType);
//}

function PlayEndOfMatchMessage() {
    local Controller C;

    for (C = Level.ControllerList; C != none; C = C.NextController) {
        if (C.IsA('PlayerController')) {
            // PlayerController(C).ClientPlaySound(Sound'KF_MaleVoiceOne.Insult_Specimens_9', true, 2.f, SLOT_Talk);
            if (FRand() < 0.25) {
                PlayerController(C).ClientPlaySound(Sound'KF_BasePatriarch.Kev_Victory5', true, 2.f, SLOT_Talk);
            } else if (FRand() < 0.25) {
                PlayerController(C).ClientPlaySound(Sound'KF_BasePatriarch.Kev_Victory3', true, 2.f, SLOT_Talk);
            } else if (FRand() < 0.25) {
                PlayerController(C).ClientPlaySound(Sound'KF_BasePatriarch.Kev_Victory2', true, 2.f, SLOT_Talk);
            } else {
                PlayerController(C).ClientPlaySound(Sound'KF_BasePatriarch.Kev_Talk3', true, 2.f, SLOT_Talk);
            }
        }
    }
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason) {
    local Controller P, NextController;
    local PlayerController Player;

    if ((GameRulesModifiers != none) && !GameRulesModifiers.CheckEndGame(Winner, Reason)) {
        return false;
    }

    // if (Winner == none )
    // {
    //     // find winner
    //     for (P=Level.ControllerList; P!= none; P=P.nextController )
    //         if (P.bIsPlayer && ((Winner == none) || (P.PlayerReplicationInfo.Kills>= Winner.Kills)) )
    //         {
    //             Winner = P.PlayerReplicationInfo;
    //         }
    // }

    // check for tie
    // for (P=Level.ControllerList; P!= none; P=P.nextController )
    // {
    //     if (P.bIsPlayer && (Winner != P.PlayerReplicationInfo) && (P.PlayerReplicationInfo.Kills==Winner.Kills) )
    //     {
    //         if (!bOverTimeBroadcast )
    //         {
    //             BroadcastLocalizedMessage(class'KFDMTimeMessage', -1);
    //             bOverTimeBroadcast = true;
    //         }
    //         return false;
    //     }
    // }

    EndTime = Level.TimeSeconds + EndTimeDelay + 5;
    GameReplicationInfo.Winner = Winner;

    EndGameFocus = Controller(Winner.Owner).Pawn;
    if (EndGameFocus != none) {
        EndGameFocus.bAlwaysRelevant = true;
    }
    for (P = Level.ControllerList; P != none; P = NextController) {
        NextController = P.NextController;
        Player = PlayerController(P);
        if (Player != none) {
            // if (!Player.PlayerReplicationInfo.bOnlySpectator )
            //    PlayWinMessage(Player, (Player.PlayerReplicationInfo == Winner));
            Player.ClientSetBehindView(true);
            if (EndGameFocus != none) {
                Player.ClientSetViewTarget(EndGameFocus);
                Player.SetViewTarget(EndGameFocus);
            }
            Player.ClientGameEnded();
        }
        P.GameHasEnded();
    }
    return true;
}

// function used for debugging levelling up
function ForceLevelUp(Controller Killer) {
    local class<Weapon> WeaponClass;

    WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));

    if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < (WeaponList.Length - 1)) {
        if (KFGGHumanPawn(Killer.Pawn) != none) {
            KFGGHumanPawn(Killer.Pawn).ClearOutCurrentWeapons();
        }

        KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
        Killer.PlayerReplicationInfo.Score += 1;

        if (KFGGHumanPawn(Killer.Pawn) != none) {
            KFGGHumanPawn(Killer.Pawn).CreateInventory(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel]);
            Killer.SwitchToBestWeapon();
        }

        if (PlayerController(Killer) != none) {
            PlayerController(Killer).ClientPlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Exit',true,2.f,SLOT_None);
        }

        if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.25)) {
            BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0, Killer.PlayerReplicationInfo,, WeaponClass);
        } else if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.5)) {
            BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0, Killer.PlayerReplicationInfo,, WeaponClass);
        } else if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.75)) {
            BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0, Killer.PlayerReplicationInfo,, WeaponClass);
        } else if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == (WeaponList.Length - 1)) {
            BroadcastLocalizedMessage(class'GGAnnouncementMessage', 1, Killer.PlayerReplicationInfo,, WeaponClass);
        }
    } else if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < WeaponList.Length) {
        KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
        Killer.PlayerReplicationInfo.Score += 1;
    }
}

function Killed(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType) {
    local bool bKilledWithRightWeapon;
    local bool bKnifeKill;
    local Controller C;
    local string S;
    local class<Weapon> WeaponClass;

    super(DeathMatch).Killed(Killer, Killed, KilledPawn, DamageType);

    if (
        KFGGPRI(Killer.PlayerReplicationInfo) != none &&
        Killer.PlayerReplicationInfo.Team.TeamIndex != Killed.PlayerReplicationInfo.Team.TeamIndex
    ) {
        if (
            class<DamTypeKnife>(damageType) != none &&
            KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < (WeaponList.Length - 1) &&
            KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel > 0
        ) {
            bKnifeKill = true;
            bKilledWithRightWeapon = true;
        }

        if (!bKnifeKill) {
            // Check to make sure they got a kill with the right weapon
            if (
                class<WeaponDamageType>(damageType).default.WeaponClass ==
                BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel])
            ) {
                bKilledWithRightWeapon = true;
            }
            // Special handling for weapons that don't apparantly have the weapon class plugged into the damage type
            // TODO: fix up the base damage classes to have thier weapon class plugged
            // in!!! - Ramm
            else if (
                WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFMod.Single" &&
                class<DamTypeDualies>(damageType) != none
            ) {
                bKilledWithRightWeapon = true;
            } else if (
                WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFMod.BoomStick" &&
                class<DamTypeDBShotgun>(damageType) != none
            ) {
                bKilledWithRightWeapon = true;
            } else if (
                WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFMod.Crossbow" &&
                class<DamTypeCrossbow>(damageType) != none ||
                class<DamTypeCrossbowHeadShot>(damageType) != none
            ) {
                bKilledWithRightWeapon = true;
            } else if (
                WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFMod.FlameThrower" &&
                class<DamTypeBurned>(damageType) != none
            ) {
                bKilledWithRightWeapon = true;
            } else if (
                WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFGunGame.GG_M79GrenadeLauncher" &&
                class<DamTypeM79Grenade>(damageType) != none
            ) {
                bKilledWithRightWeapon = true;
            } else if (
                WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFGunGame.GG_M4203AssaultRifle" &&
                class<DamTypeM203Grenade>(damageType) != none ||
                class<DamTypeM4203AssaultRifle>(damageType) != none
            ) {
                bKilledWithRightWeapon = true;
            } else if (
                WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFGunGame.GG_M32GrenadeLauncher" &&
                class<DamTypeM32Grenade>(damageType) != none
            ) {
                bKilledWithRightWeapon = true;
            } else if (
                WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFGunGame.GG_HuskGun" &&
                class<DamTypeBurned>(damageType) != none ||
                class<DamTypeHuskGun>(damageType) != none ||
                class<DamTypeHuskGunProjectileImpact>(damageType) != none
            ) {
                bKilledWithRightWeapon = true;
            } else if (
                WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "KFGunGame.GG_LAW" &&
                class<DamTypeLAW>(damageType) != none
            ) {
                bKilledWithRightWeapon = true;
            }
        }

        if (bKilledWithRightWeapon) {
            if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < (WeaponList.Length - 1)) {
                if (KFGGHumanPawn(Killer.Pawn) != none) {
                    KFGGHumanPawn(Killer.Pawn).ClearOutCurrentWeapons();
                }

                KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
                Killer.PlayerReplicationInfo.Score += 1;

                if (KFGGHumanPawn(Killer.Pawn) != none) {
                    KFGGHumanPawn(Killer.Pawn).CreateInventory(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel]);
                    Killer.SwitchToBestWeapon();
                }

                if (PlayerController(Killer) != none) {
                    PlayerController(Killer).ClientPlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Exit', true, 2.f, SLOT_None);
                }

                if (bKnifeKill && KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel > 0) {
                    // if (Killer.Pawn != none )
                    // {
                    //     Killer.Pawn.PlayOwnedSound(Sound'KF_MaleVoiceOne.Insult_Specimens_9', SLOT_Talk,2.0,true,500);
                    //     PlayerController(Killer).ClientPlaySound(Sound'KF_MaleVoiceOne.Insult_Specimens_9',true,2.f,SLOT_Talk);
                    // }
                    BroadcastLocalizedMessage(class'GGAnnouncementMessage', 2, Killer.PlayerReplicationInfo, Killed.PlayerReplicationInfo);

                    if (KFGGHumanPawn(Killed.Pawn) != none) {
                        KFGGHumanPawn(Killed.Pawn).ClearOutCurrentWeapons();
                    }

                    KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel--;
                    Killed.PlayerReplicationInfo.Score -= 1;

                    if (KFGGHumanPawn(Killed.Pawn) != none) {
                        KFGGHumanPawn(Killed.Pawn).CreateInventory(WeaponList[KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel]);
                        Killed.SwitchToBestWeapon();
                    }
                    PlayerController(Killed).ClientPlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Enter', true, 2.f, SLOT_None);
                }

                if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.25)) {
                    WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
                    BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0,Killer.PlayerReplicationInfo,Killed.PlayerReplicationInfo,WeaponClass);
                } else if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.5)) {
                    WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
                    BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0,Killer.PlayerReplicationInfo,Killed.PlayerReplicationInfo,WeaponClass);
                } else if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.75)) {
                    WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
                    BroadcastLocalizedMessage(class'GGAnnouncementMessage', 0,Killer.PlayerReplicationInfo,Killed.PlayerReplicationInfo,WeaponClass);
                } else if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == (WeaponList.Length - 1)) {
                    WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
                    BroadcastLocalizedMessage(class'GGAnnouncementMessage', 1,Killer.PlayerReplicationInfo,Killed.PlayerReplicationInfo,WeaponClass);
                }
            } else if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < WeaponList.Length) {
                KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
                Killer.PlayerReplicationInfo.Score += 1;
            }
        }

        if (!bDoingWarmup && KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel >= WeaponList.Length) {
            MusicPlaying = true;
            CalmMusicPlaying = false;

            // Give the guy that won 100% health so we won't get any weird dying hud effects or sounds
            if (Killer.Pawn != none) {
                Killer.Pawn.GiveHealth(100, Killer.Pawn.HealthMax);
            }

            if (FRand() < 0.5) {
                S = "DirgeDisunion1";
            } else {
                S = "KF_Containment";
            }

            for (C = Level.ControllerList; C != none; C = C.NextController) {
                if (KFPlayerController(C) != none) {
                    KFPlayerController(C).NetPlayMusic(S, 0.25, 1.0);
                }
            }

            EndGame(Killer.PlayerReplicationInfo, "fraglimit");
        }
    }
}

function AmmoPickedUp(KFAmmoPickup PickedUp) {
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
//    NewPlayer = super.Login(Portal, Options, Error);
//
//    if (NewPlayer.PlayerReplicationInfo.Team.TeamIndex == 0 )
//    {
//           NewPlayer.SetPawnClass(DefaultPlayerClassName, "Sergeant_Powers");
//    }
//    else  if (NewPlayer.PlayerReplicationInfo.Team.TeamIndex == 1 )
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

function int ReduceDamage(
    int Damage,
    pawn injured,
    pawn instigatedBy,
    vector HitLocation,
    out vector Momentum,
    class<DamageType> DamageType
) {
    // WeaponList(0)="KFMod.Single"
    // WeaponList(1)="KFMod.Dualies"
    // WeaponList(2)="KFMod.Magnum44Pistol"
    // WeaponList(3)="KFMod.Dual44Magnum"
    // WeaponList(4)="KFMod.Winchester"
    // WeaponList(5)="KFMod.MAC10MP"
    // WeaponList(6)="KFMod.MP7MMedicGun"
    // WeaponList(7)="KFMod.MP5MMedicGun"
    // WeaponList(8)="KFMod.Bullpup"
    // WeaponList(9)="KFMod.Crossbow"
    // WeaponList(10)="KFMod.Shotgun"
    // WeaponList(11)="KFMod.FlameThrower"
    // WeaponList(12)="KFMod.Deagle"
    // WeaponList(13)="KFMod.M4AssaultRifle"
    // WeaponList(14)="KFMod.AK47AssaultRifle"
    // WeaponList(15)="KFMod.BoomStick"
    // WeaponList(16)="KFMod.M14EBRBattleRifle"
    // WeaponList(17)="KFMod.DualDeagle"
    // WeaponList(18)="KFMod.BenelliShotgun"
    // WeaponList(19)="KFGunGame.GG_M79GrenadeLauncher"
    // WeaponList(20)="KFMod.SCARMK17AssaultRifle"
    // WeaponList(21)="KFGunGame.GG_M4203AssaultRifle"
    // WeaponList(22)="KFGunGame.GG_M32GrenadeLauncher"
    // WeaponList(23)="KFGunGame.GG_HuskGun"
    // WeaponList(24)="KFMod.AA12AutoShotgun"
    // WeaponList(25)="KFGunGame.GG_LAW"
    // WeaponList(26)="KFMod.Katana"

    // Adjust damage for gungame, as KF weapons were all balanced for shooting zombies not players! :)
    if (
        class<DamTypeDualies>(damageType) != none ||
        class<DamTypeMK23Pistol>(damageType) != none ||
        class<DamTypeDualMK23Pistol>(damageType) != none
    ) {
        Damage *= 0.5;
    } else if (
        class<DamTypeMagnum44Pistol>(damageType) != none ||
        class<DamTypeDual44Magnum>(damageType) != none
    ) {
        Damage *= 0.5;
    } else if (class<DamTypeWinchester>(damageType) != none) {
        Damage *= 0.75;
    } else if (class<DamTypeMAC10MP>(damageType) != none) {
        Damage *= 0.65;
    } else if (class<DamTypeMP7M>(damageType) != none) {
        Damage *= 0.65;
    } else if (class<DamTypeMP5M>(damageType) != none) {
        Damage *= 0.65;
    } else if (class<DamTypeBullpup>(damageType) != none) {
        Damage *= 1.0;
    } else if (
        class<DamTypeCrossbow>(damageType) != none ||
        class<DamTypeCrossbowHeadShot>(damageType) != none ||
        class<DamTypeM99SniperRifle>(damageType) != none ||
        class<DamTypeM99HeadShot>(damageType) != none
    ) {
        Damage *= 0.65;
    } else if (
        class<DamTypeShotgun>(damageType) != none ||
        class<DamTypeKSGShotgun>(damageType) != none
    ) {
        Damage *= 0.41; // 1 Hit kill if all pellets hit you
    } else if (class<DamTypeBurned>(damageType) != none) {
        Damage *= 2.0;
    } else if (
        class<DamTypeDeagle>(damageType) != none ||
        class<DamTypeDualDeagle>(damageType) != none
    ) {
        Damage *= 0.5;
    } else if (
        class<DamTypeM4AssaultRifle>(damageType) != none ||
        class<DamTypeM4203AssaultRifle>(damageType) != none
    ) {
        Damage *= 0.75;
    } else if (class<DamTypeAK47AssaultRifle>(damageType) != none) {
        Damage *= 0.75;
    } else if (class<DamTypeDBShotgun>(damageType) != none) {
        Damage *= 0.3;
    } else if (
        class<DamTypeM14EBR>(damageType) != none ||
        class<DamTypeM7A3M>(damageType) != none
    ) {
        Damage *= 0.75;
    } else if (
        class<DamTypeSCARMK17AssaultRifle>(damageType) != none ||
        class<DamTypeFNFALAssaultRifle>(damageType) != none
    ) {
        Damage *= 0.65;
    } else if (class<DamTypeAA12Shotgun>(damageType) != none) {
        Damage *= 0.35;
    } else if (class<DamTypeBenelli>(damageType) != none) {
        Damage *= 0.35;
    } else if (
        class<DamTypeM79Grenade>(damageType) != none ||
        class<DamTypeM203Grenade>(damageType) != none
    ) {
        Damage *= 0.4;
    } else if (class<DamTypeM32Grenade>(damageType) != none) {
        Damage *= 0.3;
    } else if (class<DamTypeLAW>(damageType) != none) {
        Damage *= 0.15;
    } else if (class<DamTypeKatana>(damageType) != none) {
        Damage *= 0.8;
    } else if (class<DamTypeRocketImpact>(damageType) != none) {
        Damage *= 0.25;
    } else if (class<DamTypeHuskGun>(damageType) != none) {
        Damage *= 1.0;
    } else if (class<DamTypeHuskGunProjectileImpact>(damageType) != none) {
        Damage *= 0.3;
    } else if (class<DamTypeKnife>(damageType) != none) {
        Damage *= 3.0;
    }

    return super.ReduceDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
}

function ScoreKill(Controller Killer, Controller Other) {
    if (GameRulesModifiers != none) {
        GameRulesModifiers.ScoreKill(Killer, Other);
    }

    if (killer == Other || killer == none) {
        return;
    }

    if (Killer.PlayerReplicationInfo == none) {
        return;
    }

    Killer.PlayerReplicationInfo.Kills++;
    Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
    ScoreEvent(Killer.PlayerReplicationInfo, 1, "frag");
}

function AddGameSpecificInventory(Pawn p) {
    p.CreateInventory(WeaponList[KFGGPRI(p.PlayerReplicationInfo).WeaponLevel]);
    p.Controller.SwitchToBestWeapon();
}

final function UpdateViewsNow() {
    local Controller C;

    for (C = Level.ControllerList; C != none; C = C.nextController) {
        if (
            C.PlayerReplicationInfo != none &&
            !C.PlayerReplicationInfo.bOnlySpectator &&
            PlayerController(C) != none &&
            C.Pawn != none
        ) {
            PlayerController(C).ClientSetBehindView(false);
            PlayerController(C).ClientSetViewTarget(C.Pawn);
            // PlayerController(C).ReceiveLocalizedMessage(class'KFMainMessages',3);
        }
        // else if (KFInvasionBot(C)!= none && C.Pawn!= none && FRand()<0.5f )
        //     KFInvasionBot(C).DoTrading();
    }
}

function RestartPlayer(Controller aPlayer) {
    if (aPlayer.PlayerReplicationInfo.bOutOfLives || aPlayer.Pawn != none) {
        return;
    }
    if (aPlayer.PlayerReplicationInfo.Team.TeamIndex == 0) {
        aPlayer.PawnClass = class'KFRedGGPlayer';
    } else {
        aPlayer.PawnClass = class'KFBlueGGPlayer';
    }
    aPlayer.PreviousPawnClass = aPlayer.PawnClass;
    KFPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).ClientVeteranSkill = class'KFVeterancyTypes';
    aPlayer.PlayerReplicationInfo.Score = Max(MinRespawnCash, int(aPlayer.PlayerReplicationInfo.Score));
    super(Invasion).RestartPlayer(aPlayer);
}

function Timer() {
    super(xTeamGame).Timer();
}

auto State PendingMatch {
    function RestartPlayer(Controller aPlayer) {
        if (CountDown <= 0) {
            super.RestartPlayer(aPlayer);
        }
    }

    function Timer() {
        local Controller P;
        local bool bReady;

        Global.Timer();

        // first check if there are enough net players, and enough time has elapsed to give people
        // a chance to join
        if (NumPlayers == 0) {
            bWaitForNetPlayers = true;
        }

        if (bWaitForNetPlayers && Level.NetMode != NM_Standalone) {
            if (NumPlayers >= MinNetPlayers) {
                ElapsedTime++;
            } else {
                ElapsedTime = 0;
            }
            if (NumPlayers == MaxPlayers || ElapsedTime > NetWait) {
                bWaitForNetPlayers = false;
                CountDown = default.CountDown;
            }
        }

        if (
            Level.NetMode != NM_Standalone &&
            (bWaitForNetPlayers || (bTournament && (NumPlayers < MaxPlayers)))
        ) {
            PlayStartupMessage();
            return;
        }

        // check if players are ready
        bReady = true;
        StartupStage = 1;
        if (
            !bStartedCountDown &&
            (bTournament /*|| bPlayersMustBeReady*/ || (Level.NetMode == NM_Standalone))
        ) {
            for (P = Level.ControllerList; P != none; P = P.NextController) {
                if (
                    P.IsA('PlayerController') &&
                    P.PlayerReplicationInfo != none &&
                    P.bIsPlayer &&
                    P.PlayerReplicationInfo.bWaitingPlayer &&
                    !P.PlayerReplicationInfo.bReadyToPlay
                ) {
                    bReady = false;
                }
            }
        }
        if (bReady && !bReviewingJumpspots) {
            bStartedCountDown = true;
            CountDown--;
            if (CountDown <= 0) {
                StartMatch();
            } else {
                StartupStage = 5 - CountDown;
            }
        }
        if (!bDidWarmup && WarmupTime > 0) {
            PlayWarmupMessage();
        } else {
            PlayStartupMessage();
        }
    }

    function beginstate() {
        bWaitingToStartMatch = true;
        StartupStage = 0;
        WarmupCountDown = WarmupTime;
        // if (IsA('xLastManStandingGame') )
        //     NetWait = Max(NetWait,10);
    }

    // function EndState()
    // {
    //     KFGameReplicationInfo(GameReplicationInfo).LobbyTimeout = -1;
    // }

Begin:
    if (bQuickStart) {
        StartMatch();
    }
}

function PlayStartupMessage() {
    local Controller P;

    // keep message displayed for waiting players
    for (P = Level.ControllerList; P != none; P = P.NextController) {
        if (UnrealPlayer(P) != none) {
            UnrealPlayer(P).PlayStartUpMessage(StartupStage);
        }
    }
}

function PlayWarmupMessage() {
    local Controller P;

    // keep message displayed for waiting players
    for (P = Level.ControllerList; P != none; P = P.NextController) {
        if (KFGGPlayerController(P) != none) {
            KFGGPlayerController(P).PlayWarmupMessage(StartupStage);
        }
    }
}


state MatchInProgress {
    function OpenShops();
    function CloseShops();

    function Timer() {
        local Controller C;

        Global.Timer();

        for (C = Level.ControllerList; C != none; C = C.nextController) {
            if (
                C.PlayerReplicationInfo != none &&
                !C.PlayerReplicationInfo.bOnlySpectator &&
                C.Pawn == none
                /*C.PlayerReplicationInfo.bReadyToPlay
                && C.IsA('PlayerController') && C.IsInState('PlayerWaiting')*/
            ) {
                RestartPlayer(C);
            }
        }

        if (!bFinalStartup) {
            bFinalStartup = true;
            UpdateViewsNow();
        }

        if (NeedPlayers() && AddBot() && RemainingBots > 0) {
            RemainingBots--;
        }
        ElapsedTime++;
        GameReplicationInfo.ElapsedTime = ElapsedTime;

        if (!bDidWarmup && WarmupTime > 0) {
            WarmupCountDown--;

            if (WarmupCountDown <= (default.CountDown - 1) && WarmupCountDown > 0) {
                StartupStage = 5 - WarmupCountDown;
                PlayStartupMessage();
            }

            if (WarmupCountDown <= 0) {
                ResetBeforeMatchStart();
                bDidWarmup = true;
                bDoingWarmup = false;
                StartMatch();

                for (C = Level.ControllerList; C != none; C = C.nextController) {
                    if (
                        C.PlayerReplicationInfo != none &&
                        !C.PlayerReplicationInfo.bOnlySpectator &&
                        C.Pawn == none
                        /*C.PlayerReplicationInfo.bReadyToPlay
                        && C.IsA('PlayerController') && C.IsInState('PlayerWaiting')*/
                    ) {
                        RestartPlayer(C);
                    }
                }

                StartupStage = 5;
                PlayStartupMessage();
                StartupStage = 6;

            } else {
                bDoingWarmup = true;
            }
        } else {
            bDidWarmup = true;
        }

        if (bOverTime) {
            EndGame(none, "TimeLimit");
        } else if (TimeLimit > 0) {
            GameReplicationInfo.bStopCountDown = false;
            RemainingTime--;
            GameReplicationInfo.RemainingTime = RemainingTime;
            if (RemainingTime % 60 == 0) {
                GameReplicationInfo.RemainingMinute = RemainingTime;
            }
            if (
                RemainingTime == 600 ||
                RemainingTime == 300 ||
                RemainingTime == 180 ||
                RemainingTime == 120 ||
                RemainingTime == 60 ||
                RemainingTime==30 ||
                RemainingTime==20 ||
                (RemainingTime<=10 && RemainingTime>=1)
            ) {
                BroadcastLocalizedMessage(class'KFGGTimeMessage', RemainingTime);
            }
            if (RemainingTime <= 0) {
                EndGame(none, "TimeLimit");
            }
        }
    }

    function beginstate() {
        local PlayerReplicationInfo PRI;

        ForEach DynamicActors(class'PlayerReplicationInfo', PRI) {
            PRI.StartTime = 0;
        }
        ElapsedTime = 0;
        bWaitingToStartMatch = false;
        StartupStage = 5;
        if (!bDidWarmup && WarmupTime > 0) {
            PlayWarmupMessage();
        } else {
            PlayStartupMessage();
        }
        StartupStage = 6;
    }
}

function ResetBeforeMatchStart() {
    local Controller P, NextC;
    local Actor A;

    // Reset all controllers
    P = Level.ControllerList;
    while (P != none) {
        NextC = P.NextController;

        if (AIController(P) != none) {
            bKillBots = true;
            P.Destroy();
            bKillBots = false;
            P = NextC;
            continue;
        }

        if (P.Pawn != none && P.PlayerReplicationInfo != none) {
            P.Pawn.Destroy();
        }

        if (P.PlayerReplicationInfo == none || !P.PlayerReplicationInfo.bOnlySpectator) {
            if (PlayerController(P) != none) {
                PlayerController(P).ClientReset();
            }
            P.Reset();

            if (P.PlayerReplicationInfo != none) {
                P.PlayerReplicationInfo.Score = 0;
                P.PlayerReplicationInfo.Deaths = 0;
                P.PlayerReplicationInfo.GoalsScored = 0;
                P.PlayerReplicationInfo.Kills = 0;
                if (TeamPlayerReplicationInfo(P.PlayerReplicationInfo) != none) {
                    TeamPlayerReplicationInfo(P.PlayerReplicationInfo).bFirstBlood = false;
                }

                if (KFGGPRI(P.PlayerReplicationInfo) != none) {
                    KFGGPRI(P.PlayerReplicationInfo).WeaponLevel = 0;
                }
            }
        }

        P = NextC;
    }

    foreach AllActors(class'Actor', A) {
        // destroy any active projectiles
        if (A.IsA('Projectile')) {
            A.Destroy();
            continue;
        }
        // reset ALL actors (except Controllers)
        if (!A.IsA('Controller')) {
            A.Reset();
        }
    }

    for (P = Level.ControllerList; P != none; P = NextC) {
        NextC = P.nextController;
        if (
            P.PlayerReplicationInfo != none &&
            !P.PlayerReplicationInfo.bOnlySpectator &&
            P.PlayerReplicationInfo.Team != none
        ) {
            P.PlayerReplicationInfo.bOutOfLives = false;
            RestartPlayer(P);
        }
    }

    log("End RemainingBots = " $ RemainingBots);
    bFinalStartup = false;
}

// final function StartNewRound()
// {
//    local Controller C,NC;
//    local array<Controller> CA;
//    local int i;
//    local Projectile P;

//    if (GoalScore>0 ) // Check winners
//    {
//        if (Teams[0].Score>=GoalScore )
//        {
//            EndGame(none,"fraglimit");
//            return;
//        }
//        else if (Teams[1].Score>=GoalScore )
//        {
//            EndGame(none,"fraglimit");
//            return;
//        }
//    }

//    // First kill all pawns.
//    for(C=Level.ControllerList; C!= none; C=NC )
//    {
//        NC = C.nextController;
//        if (C.Pawn!= none && C.PlayerReplicationInfo!= none )
//            C.Pawn.Destroy();
//    }

//    // Then even the teams.
//    if (Teams[0].Size>(Teams[1].Size+1) ) // To many Reds.
//    {
//        for(C=Level.ControllerList; C!= none; C=C.nextController )
//        {
//            if (C.PlayerReplicationInfo!= none && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.Team!= none
//             && C.PlayerReplicationInfo.Team.TeamIndex==0 )
//                CA[CA.Length] = C;
//        }
//        while (Teams[0].Size>(Teams[1].Size+1) && CA.Length>0 )
//        {
//            i = Rand(CA.Length);
//            ChangeTeam(CA[i],1,true);
//            CA.Remove(i,1);
//        }
//    }
//    else if (Teams[1].Size>(Teams[0].Size+1) ) // To many Blues.
//    {
//        for(C=Level.ControllerList; C!= none; C=C.nextController )
//        {
//            if (C.PlayerReplicationInfo!= none && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.Team!= none
//             && C.PlayerReplicationInfo.Team.TeamIndex==1 )
//                CA[CA.Length] = C;
//        }
//        while (Teams[1].Size>(Teams[0].Size+1) && CA.Length>0 )
//        {
//            i = Rand(CA.Length);
//            ChangeTeam(CA[i],0,true);
//            CA.Remove(i,1);
//        }
//    }

//    // Kill any active projectiles
//    foreach DynamicActors(class'Projectile',P)
//        P.Destroy();

//    // Init new spawns and respawn players.
//    PickSpawnPoints();
//    for(C=Level.ControllerList; C!= none; C=NC )
//    {
//        NC = C.nextController;
//        if (C.PlayerReplicationInfo!= none && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.Team!= none )
//        {
//            C.PlayerReplicationInfo.bOutOfLives = false;
//            RestartPlayer(C);
//        }
//    }
//    bFinalStartup = false;
// }

state MatchOver {
    function Timer() {
        local Controller C;

        Global.Timer();

        if (!bGameRestarted && (Level.TimeSeconds > EndTime + RestartWait)) {
            RestartGame();
        }

        if (EndGameFocus != none) {
            EndGameFocus.bAlwaysRelevant = true;
            for (C = Level.ControllerList; C != none; C = C.NextController) {
                if (PlayerController(C) != none) {
                    PlayerController(C).ClientSetViewtarget(EndGameFocus);
                }
            }
        }

        // play end-of-match message for winner/losers (for single and muli-player)
        EndMessageCounter++;
        if (EndMessageCounter == EndMessageWait) {
            PlayEndOfMatchMessage();
        }
    }

    function BeginState() {
        GameReplicationInfo.bStopCountDown = true;
        KFGameReplicationInfo(GameReplicationInfo).EndGameType = 2;
    }
}

static function FillPlayInfo(PlayInfo PlayInfo) {
    super(Info).FillPlayInfo(PlayInfo);  // Always begin with calling parent

    PlayInfo.AddSetting(default.GameGroup, "TimeLimit", GetDisplayText("TimeLimit"),0, 0, "Text", "3;0:999");

    // AddSetting(string Group, string PropertyName, string Description, byte SecLevel, byte Weight, string RenderType, optional string Extras, optional string ExtraPrivs, optional bool bMultiPlayerOnly, optional bool bAdvanced);
    // PlayInfo.AddSetting(default.GameGroup,   "NumAmmoSpawns","Num Ammo Pickups",0, 0, "Text","2;0:10");

    PlayInfo.AddSetting(default.ServerGroup, "MinPlayers","Num Bots",0, 0, "Text","2;0:64",, true, true);
    PlayInfo.AddSetting(default.ServerGroup, "LobbyTimeOut", GetDisplayText("LobbyTimeOut"), 0, 1, "Text", "3;0:120",, true, true);
    PlayInfo.AddSetting(default.ServerGroup, "bAdminCanPause", GetDisplayText("bAdminCanPause"), 1, 1, "Check",,, true, true);
    PlayInfo.AddSetting(default.ServerGroup, "MaxSpectators", GetDisplayText("MaxSpectators"), 1, 1, "Text", "6;0:32",, true, true);
    PlayInfo.AddSetting(default.ServerGroup, "MaxPlayers", GetDisplayText("MaxPlayers"), 0, 1, "Text", "6;0:32",, true);
    PlayInfo.AddSetting(default.ServerGroup, "MaxIdleTime", GetDisplayText("MaxIdleTime"), 0, 1, "Text", "3;0:300",, true, true);

    // Add GRI's PIData
    if (default.GameReplicationInfoClass != none) {
        default.GameReplicationInfoClass.static.FillPlayInfo(PlayInfo);
        PlayInfo.PopClass();
    }

    if (default.VoiceReplicationInfoClass != none) {
        default.VoiceReplicationInfoClass.static.FillPlayInfo(PlayInfo);
        PlayInfo.PopClass();
    }

    if (default.BroadcastClass != none) {
        default.BroadcastClass.static.FillPlayInfo(PlayInfo);
    } else {
        class'BroadcastHandler'.static.FillPlayInfo(PlayInfo);
    }

    PlayInfo.PopClass();

    if (class'Engine.GameInfo'.default.VotingHandlerClass != none) {
        class'Engine.GameInfo'.default.VotingHandlerClass.static.FillPlayInfo(PlayInfo);
        PlayInfo.PopClass();
    }
}

static event string GetDescriptionText(string PropName) {
    switch (PropName) {
        // case "MinPlayers":           return "Minimum number of players in game (rest will be filled with bots.";
        // case "InitGrenadesCount":    return "Initial amount of grenades players start with.";
    }
    return super.GetDescriptionText(PropName);
}

defaultproperties {
    bNoBots=false
    bSpawnInTeamArea=true
    TeamAIType(0)=class'GGTeamAI'
    TeamAIType(1)=class'GGTeamAI'
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
    PlayerControllerClass=class'KFGGPlayerController'
    PlayerControllerClassName="KFGunGame.KFGGPlayerController"
    GameReplicationInfoClass=class'KFGGGameReplicationInfo'
    GameName="KF Gun Game"
    Description="Gun Game With Killing Floor Weapons. Every kill instantly gets you the next weapon in the list. Be the first player to get a kill with every weapon on the list to win!"
    Acronym="GG"
}