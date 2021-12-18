class KFGGPlayerController extends KFPlayerController
  config(KFGGUser);
// just in case something decides to save the config - keep vanilla User.ini clean

//=============================================================================
//                              DISABLED FUNCTIONS
//=============================================================================

// this is a very big no-no
exec function ToggleBehindView()
{
  ClientMessage("DON'T CHEAT!!! ToggleBehindView is disabled.");
}


// allows you to abuse and do not let your opponents to get 'levels'
exec function Suicide()
{
  ClientMessage("DON'T CHEAT!!! Suicide is disabled.");
}


// no perks, at all
simulated function SendSelectedVeterancyToServer(optional bool bForceChange);
function SelectVeterancy(class<KFVeterancyTypes> VetSkill, optional bool bForceChange);


//=============================================================================
//                                  OTHER
//=============================================================================

// Overriden to clear shakes / rot no matter what
function ViewShake(float DeltaTime)
{
  if (ShakeOffsetRate != vect(0, 0, 0))
  {
    // modify shake offset
    ShakeOffset.X += DeltaTime * ShakeOffsetRate.X;
    CheckShake(ShakeOffsetMax.X, ShakeOffset.X, ShakeOffsetRate.X, ShakeOffsetTime.X, DeltaTime);

    ShakeOffset.Y += DeltaTime * ShakeOffsetRate.Y;
    CheckShake(ShakeOffsetMax.Y, ShakeOffset.Y, ShakeOffsetRate.Y, ShakeOffsetTime.Y, DeltaTime);

    ShakeOffset.Z += DeltaTime * ShakeOffsetRate.Z;
    CheckShake(ShakeOffsetMax.Z, ShakeOffset.Z, ShakeOffsetRate.Z, ShakeOffsetTime.Z, DeltaTime);
  }
  else
  {
    ShakeOffset = vect(0, 0, 0);
  }

  if (ShakeRotRate != vect(0, 0, 0))
  {
    UpdateShakeRotComponent(ShakeRotMax.X, ShakeRot.Pitch, ShakeRotRate.X, ShakeRotTime.X, DeltaTime);
    UpdateShakeRotComponent(ShakeRotMax.Y, ShakeRot.Yaw,   ShakeRotRate.Y, ShakeRotTime.Y, DeltaTime);
    UpdateShakeRotComponent(ShakeRotMax.Z, ShakeRot.Roll,  ShakeRotRate.Z, ShakeRotTime.Z, DeltaTime);
  }
  else
  {
    ShakeRot = Rot(0, 0, 0);
  }
}


simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
  super.DisplayDebug(Canvas, YL, YPos);

  Canvas.SetDrawColor(255, 255, 255);
  Canvas.DrawText("ShakeOffset: " $ ShakeOffset);
  YPos += YL;
  Canvas.SetPos(4, YPos);
}


function PlayWarmupMessage(byte StartupStage)
{
  ReceiveLocalizedMessage(class'GGWarmupMessage', StartupStage, PlayerReplicationInfo);
}


function PlayStartupMessage(byte StartupStage)
{
  ReceiveLocalizedMessage(class'GGStartupMessage', StartupStage, PlayerReplicationInfo);
}


event ClientSetViewTarget(Actor a)
{
  super.ClientSetViewTarget(a);

  StopViewShaking();
}


simulated function StopViewShaking()
{
  ShakeRotMax  = vect(0, 0, 0);
  ShakeRotRate = vect(0, 0, 0);
  ShakeRotTime = vect(0, 0, 0);
  ShakeOffsetMax  = vect(0, 0, 0);
  ShakeOffsetRate = vect(0, 0, 0);
  ShakeOffsetTime = vect(0, 0, 0);

  // if _RO_
  ShakeOffset = vect(0, 0, 0);
  ShakeRot = Rot(0, 0, 0);
  // end _RO_
}


//=============================================================================
//                      MARCO's (SERVER PERKS) COPY-CAT
//=============================================================================

// Poosh's preloading code fix.
simulated function PreloadFireModeAssets(class<WeaponFire> WF)
{
  local class<Projectile> P;

  if (WF == none || WF == Class'KFMod.NoFire') 
    return;

  if (class<KFFire>(WF) != none && class<KFFire>(WF).default.FireSoundRef != "")
    class<KFFire>(WF).static.PreloadAssets(Level);
  else if (class<KFMeleeFire>(WF) != none && class<KFMeleeFire>(WF).default.FireSoundRef != "")
    class<KFMeleeFire>(WF).static.PreloadAssets();
  else if (class<KFShotgunFire>(WF) != none && class<KFShotgunFire>(WF).default.FireSoundRef != "")
    class<KFShotgunFire>(WF).static.PreloadAssets(Level);

  // preload projectile assets
  P = WF.default.ProjectileClass;
  //log("Projectile =" @ P, default.class.outer.name);
  if (P == none)
    return;
        
  if (class<CrossbuzzsawBlade>(P) != none)
    class<CrossbuzzsawBlade>(P).static.PreloadAssets();
  else if (class<LAWProj>(P) != none && class<LAWProj>(P).default.StaticMeshRef != "")
    class<LAWProj>(P).static.PreloadAssets();
  else if (class<M79GrenadeProjectile>(P) != none && class<M79GrenadeProjectile>(P).default.StaticMeshRef != "")
    class<M79GrenadeProjectile>(P).static.PreloadAssets();
  else if (class<SPGrenadeProjectile>(P) != none && class<SPGrenadeProjectile>(P).default.StaticMeshRef != "")
    class<SPGrenadeProjectile>(P).static.PreloadAssets();
  else if (class<HealingProjectile>(P) != none && class<HealingProjectile>(P).default.StaticMeshRef != "")
    class<HealingProjectile>(P).static.PreloadAssets();
  else if (class<CrossbowArrow>(P) != none && class<CrossbowArrow>(P).default.MeshRef != "")
    class<CrossbowArrow>(P).static.PreloadAssets();
  else if (class<M99Bullet>(P) != none)
    class<M99Bullet>(P).static.PreloadAssets();
  else if ( class<PipeBombProjectile>(P) != none && class<PipeBombProjectile>(P).default.StaticMeshRef != "" )
    class<PipeBombProjectile>(P).static.PreloadAssets();
  // More DLC
  else if ( class<SealSquealProjectile>(P) != none && class<SealSquealProjectile>(P).default.StaticMeshRef != "" )
    class<SealSquealProjectile>(P).static.PreloadAssets();
}

simulated final function UnloadFireModeAssets(class<WeaponFire> WF)
{
  local class<Projectile> P;

  if ( WF==none || WF==Class'KFMod.NoFire' ) 
    return;

  if ( class<KFFire>(WF) != none && class<KFFire>(WF).default.FireSoundRef != "" )
    class<KFFire>(WF).static.UnloadAssets();
  else if ( class<KFMeleeFire>(WF) != none && class<KFMeleeFire>(WF).default.FireSoundRef != "" )
    class<KFMeleeFire>(WF).static.UnloadAssets();
  else if ( class<KFShotgunFire>(WF) != none && class<KFShotgunFire>(WF).default.FireSoundRef != "" )
    class<KFShotgunFire>(WF).static.UnloadAssets();

  // Unload projectile assets only if refs aren't empty (i.e. they have been dynamically loaded)
  P = WF.default.ProjectileClass;
  if ( P == none || P.default.StaticMesh != none )
    return;

  if ( class<CrossbuzzsawBlade>(P) != none )
    class<CrossbuzzsawBlade>(P).static.UnloadAssets();
  else if ( class<LAWProj>(P) != none && class<LAWProj>(P).default.StaticMeshRef != "" )
    class<LAWProj>(P).static.UnloadAssets();
  else if ( class<M79GrenadeProjectile>(P) != none && class<M79GrenadeProjectile>(P).default.StaticMeshRef != "" )
    class<M79GrenadeProjectile>(P).static.UnloadAssets();
  else if ( class<SPGrenadeProjectile>(P) != none && class<SPGrenadeProjectile>(P).default.StaticMeshRef != "" )
    class<SPGrenadeProjectile>(P).static.UnloadAssets();
  else if ( class<HealingProjectile>(P) != none && class<HealingProjectile>(P).default.StaticMeshRef != "" )
    class<HealingProjectile>(P).static.UnloadAssets();
  else if ( class<CrossbowArrow>(P) != none && class<CrossbowArrow>(P).default.MeshRef != "" )
    class<CrossbowArrow>(P).static.UnloadAssets();
  else if ( class<M99Bullet>(P) != none )
    class<M99Bullet>(P).static.UnloadAssets();
  else if ( class<PipeBombProjectile>(P) != none && class<PipeBombProjectile>(P).default.StaticMeshRef != "" )
    class<PipeBombProjectile>(P).static.UnloadAssets();
  // More DLC
  else if ( class<SealSquealProjectile>(P) != none && class<SealSquealProjectile>(P).default.StaticMeshRef != "" )
    class<SealSquealProjectile>(P).static.UnloadAssets();
}


simulated function ClientWeaponSpawned(class<Weapon> WClass, Inventory Inv)
{
  local class<KFWeapon> W;
  local class<KFWeaponAttachment> Att;

  // log("ScrnPlayerController.ClientWeaponSpawned()" @ WClass $ ". Default Mesh = " $ WClass.default.Mesh, default.class.outer.name);
  // super.ClientWeaponSpawned(WClass, Inv);

  W = class<KFWeapon>(WClass);
  // preload assets only for weapons that have no static ones
  // damned Tripwire's code doesn't bother for cheking is there ref set or not!
  if ( W != none)
  {
    log("ClientWeaponSpawned: " $ W $ " " $ Inv);
    // preload weapon assets
    if ( W.default.Mesh == none )
      W.static.PreloadAssets(Inv);
    Att = class<KFWeaponAttachment>(W.default.AttachmentClass);
    // 2013/01/22 EDIT: bug fix 
    if ( Att != none && Att.default.Mesh == none )
    {
      if ( Inv != none )
        Att.static.PreloadAssets(KFWeaponAttachment(Inv.ThirdPersonActor));    
      else
        Att.static.PreloadAssets();
    }
    PreloadFireModeAssets(W.default.FireModeClass[0]);
    PreloadFireModeAssets(W.default.FireModeClass[1]);
  }
}

simulated function ClientWeaponDestroyed(class<Weapon> WClass)
{
  local class<KFWeapon> W;
  local class<KFWeaponAttachment> Att;

  // log(default.class @ "ClientWeaponDestroyed()" @ WClass, default.class.outer.name);
  // super.ClientWeaponDestroyed(WClass); 

  W = class<KFWeapon>(WClass);
  // if default mesh is set, then count that weapon has static assets, so don't unload them
  // that's lame, but not so lame as Tripwire's original code
  if ( W != none && W.default.MeshRef != "" && W.static.UnloadAssets() )
  {
    Att = class<KFWeaponAttachment>(W.default.AttachmentClass);
    if ( Att != none && Att.default.Mesh == none )
      Att.static.UnloadAssets();
    UnloadFireModeAssets(W.default.FireModeClass[0]);
    UnloadFireModeAssets(W.default.FireModeClass[1]);
  }
}



// exec function M79(optional bool bMaxAmmo)
// {
//   Pawn.GiveWeapon("KFGunGame.GG_M79GrenadeLauncher");
// }


// exec function LevelUp()
// {
//   KFGG(Level.Game).ForceLevelUp(self);
// }


defaultproperties
{
  LobbyMenuClassString="KFGunGame.GGLobbyMenu"
  MidGameMenuClass="KFGunGame.KFGGMidGameMenu"
}