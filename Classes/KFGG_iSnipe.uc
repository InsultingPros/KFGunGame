//=============================================================================
// Idea by C.A.T. Nejc
//=============================================================================
class KFGG_iSnipe extends KFGG;


// FIX ME
// Function used for debugging levelling up
function ForceLevelUp(Controller Killer)
{
  local class<Weapon> WeaponClass;

  WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));

  if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < (WeaponList.Length - 1))
  {
    if (KFGGHumanPawn(Killer.Pawn) != none)
    {
      KFGGHumanPawn(Killer.Pawn).ClearOutCurrentWeapons();
    }

    KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
    Killer.PlayerReplicationInfo.Score += 1;

    if (KFGGHumanPawn(Killer.Pawn) != none)
    {
      KFGGHumanPawn(Killer.Pawn).CreateInventory(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel]);
      Killer.SwitchToBestWeapon();
    }

    if (PlayerController(Killer) != none)
    {
      PlayerController(Killer).ClientPlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Exit',true,2.f,SLOT_None);
    }

    // broadcasting removed for iSnipe!!!
  }
  else if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < WeaponList.Length)
  {
    KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
    Killer.PlayerReplicationInfo.Score += 1;
  }
}


// FIX ME!!!
function Killed(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType)
{
  local bool bKilledWithRightWeapon;
  local bool bKnifeKill;
  local Controller C;
  local string S;
  local class<Weapon> WeaponClass;

  super(DeathMatch).Killed(Killer,Killed,KilledPawn,DamageType);

  if (KFGGPRI(Killer.PlayerReplicationInfo) != none && Killer.PlayerReplicationInfo.Team.TeamIndex != Killed.PlayerReplicationInfo.Team.TeamIndex)
  {
    if (class<DamTypeKnife>(damageType) != none && KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < (WeaponList.Length - 1) && KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel > 0 )
    {
      bKnifeKill = true;
      bKilledWithRightWeapon = true;
    }

    if (!bKnifeKill)
    {
      // Check to make sure they got a kill with the right weapon
      if (class<WeaponDamageType>(damageType).default.WeaponClass == BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel]))
      {
        bKilledWithRightWeapon = true;
      }
      // Special handling for weapons that don't apparantly have the weapon class plugged into the damage type
      // TODO: fix up the base damage classes to have thier weapon class plugged
      // in!!! - Ramm
      // ADDITION!!!
      else if (WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel] == "iSnipe.GG_M99SniperRifle" && class<DamTypeM99SniperRifle>(damageType) != none || class<DamTypeM99HeadShot>(damageType) != none)
      {
        bKilledWithRightWeapon = true;
      }
    }

    if (bKilledWithRightWeapon)
    {
      if (KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < (WeaponList.Length - 1))
      {
        if (KFGGHumanPawn(Killer.Pawn) != none)
        {
          KFGGHumanPawn(Killer.Pawn).ClearOutCurrentWeapons();
        }

        KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
        Killer.PlayerReplicationInfo.Score += 1;

        if (KFGGHumanPawn(Killer.Pawn) != none)
        {
          KFGGHumanPawn(Killer.Pawn).CreateInventory(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel]);
          Killer.SwitchToBestWeapon();
        }

        if (PlayerController(Killer) != none)
        {
          PlayerController(Killer).ClientPlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Exit',true,2.f,SLOT_None);
        }

        if (bKnifeKill && KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel > 0)
        {
          //  if( Killer.Pawn != none )
          //  {
          //      Killer.Pawn.PlayOwnedSound(Sound'KF_MaleVoiceOne.Insult_Specimens_9', SLOT_Talk,2.0,true,500);
          //      PlayerController(Killer).ClientPlaySound(Sound'KF_MaleVoiceOne.Insult_Specimens_9',true,2.f,SLOT_Talk);
          //  }

          if (KFGGHumanPawn(Killed.Pawn) != none)
          {
            KFGGHumanPawn(Killed.Pawn).ClearOutCurrentWeapons();
          }

          KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel--;
          Killed.PlayerReplicationInfo.Score -= 1;

          if (KFGGHumanPawn(Killed.Pawn) != none)
          {
            KFGGHumanPawn(Killed.Pawn).CreateInventory(WeaponList[KFGGPRI(Killed.PlayerReplicationInfo).WeaponLevel]);
            Killed.SwitchToBestWeapon();
          }
          PlayerController(Killed).ClientPlaySound(Sound'KF_PlayerGlobalSnd.Zedtime_Enter',true,2.f,SLOT_None);
        }

        if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.25) )
        {
          WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
        }
        else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.5) )
        {
          WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
        }
        else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == int(WeaponList.Length * 0.75) )
        {
          WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
        }
        else if( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel == (WeaponList.Length - 1) )
        {
          WeaponClass = class<Weapon>(BaseMutator.GetInventoryClass(WeaponList[KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel + 1]));
        }
      }
      else if ( KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel < WeaponList.Length )
      {
        KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel++;
        Killer.PlayerReplicationInfo.Score += 1;
      }
    }

    if ( !bDoingWarmup && KFGGPRI(Killer.PlayerReplicationInfo).WeaponLevel >= WeaponList.Length )
    {
      MusicPlaying = true;
      CalmMusicPlaying = false;

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

      for( C=Level.ControllerList;C!=none;C=C.NextController )
      {
        if (KFPlayerController(C)!= none)
          KFPlayerController(C).NetPlayMusic(S, 0.25,1.0);
      }

      EndGame(Killer.PlayerReplicationInfo,"fraglimit");
    }
  }
}


defaultproperties
{
  GameName="iSnipe"
  Description="Sniper party! Every kill instantly gets you fresh M99. Be the first player to get 16 kills to win!"
  HUDType="KFGunGame.GGHUDKillingFloor_IS"
  TeamClass[0]=class'KFGGPlayer_Red_IS'
  TeamClass[1]=class'KFGGPlayer_Blue_IS'
}