class KFGGPlayerController extends KFPlayerController;

// Overriden to clear shakes/rot no matter what
function ViewShake(float DeltaTime)
{
    if ( ShakeOffsetRate != vect(0,0,0) )
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
        ShakeOffset = vect(0,0,0);
    }

    if ( ShakeRotRate != vect(0,0,0) )
    {
        UpdateShakeRotComponent(ShakeRotMax.X, ShakeRot.Pitch, ShakeRotRate.X, ShakeRotTime.X, DeltaTime);
        UpdateShakeRotComponent(ShakeRotMax.Y, ShakeRot.Yaw,   ShakeRotRate.Y, ShakeRotTime.Y, DeltaTime);
        UpdateShakeRotComponent(ShakeRotMax.Z, ShakeRot.Roll,  ShakeRotRate.Z, ShakeRotTime.Z, DeltaTime);
    }
    else
    {
        ShakeRot = Rot(0,0,0);
    }
}


simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	Super.DisplayDebug(Canvas, YL, YPos);

	Canvas.SetDrawColor(255, 255, 255);
	Canvas.DrawText("ShakeOffset: "$ShakeOffset);
	YPos += YL;
	Canvas.SetPos(4, YPos);
}

function PlayWarmupMessage(byte StartupStage)
{
	ReceiveLocalizedMessage( class'GGWarmupMessage', StartupStage, PlayerReplicationInfo );
}

function PlayStartupMessage(byte StartupStage)
{
	ReceiveLocalizedMessage( class'GGStartupMessage', StartupStage, PlayerReplicationInfo );
}

event ClientSetViewTarget( Actor a )
{
    super.ClientSetViewTarget( a );

    StopViewShaking();
}

simulated function StopViewShaking()
{
    ShakeRotMax  = vect(0,0,0);
    ShakeRotRate = vect(0,0,0);
    ShakeRotTime = vect(0,0,0);
	ShakeOffsetMax  = vect(0,0,0);
    ShakeOffsetRate = vect(0,0,0);
    ShakeOffsetTime = vect(0,0,0);

// if _RO_
	ShakeOffset = vect(0,0,0);
	ShakeRot = Rot(0,0,0);
// end _RO_
}

simulated function ClientWeaponSpawned(class<Weapon> WClass, Inventory Inv)
{
    log("ClientWeaponSpawned "$WClass$" "$Inv);
    super.ClientWeaponSpawned(WClass, Inv);
	switch ( WClass )
	{
		case class'GG_HuskGun':
			class'HuskGun'.static.PreloadAssets(Inv);
			class'HuskGunFire'.static.PreloadAssets(Level);
			class'HuskGunProjectile'.static.PreloadAssets();
			class'HuskGunProjectile_Weak'.static.PreloadAssets();
			class'HuskGunProjectile_Strong'.static.PreloadAssets();
			class'HuskGunAttachment'.static.PreloadAssets();
			break;

		case class'GG_LAW':
			class'LAW'.static.PreloadAssets(Inv);
			class'LAWFire'.static.PreloadAssets(Level);
			class'LAWProj'.static.PreloadAssets();
			class'LAWAttachment'.static.PreloadAssets();
			break;

		case class'GG_M32GrenadeLauncher':
			class'M32GrenadeLauncher'.static.PreloadAssets(Inv);
			class'M32Fire'.static.PreloadAssets(Level);
			class'M32GrenadeProjectile'.static.PreloadAssets();
			class'M32Attachment'.static.PreloadAssets();
			break;

		case class'GG_M79GrenadeLauncher':
			class'M79GrenadeLauncher'.static.PreloadAssets(Inv);
			class'M79Fire'.static.PreloadAssets(Level);
			class'M79GrenadeProjectile'.static.PreloadAssets();
			class'M79Attachment'.static.PreloadAssets();
			break;

		case class'GG_M4203AssaultRifle':
			class'M4203AssaultRifle'.static.PreloadAssets(Inv);
			class'M203Fire'.static.PreloadAssets(Level);
			class'M4203BulletFire'.static.PreloadAssets(Level);
			class'M203GrenadeProjectile'.static.PreloadAssets();
			class'M4203Attachment'.static.PreloadAssets();
			break;
	}
}

simulated function ClientWeaponDestroyed(class<Weapon> WClass)
{
    super.ClientWeaponDestroyed(WClass);

	switch ( WClass )
	{
		case class'GG_HuskGun':
			if ( class'HuskGun'.static.UnloadAssets() )
			{
				class'HuskGunFire'.static.UnloadAssets();
				class'HuskGunProjectile'.static.UnloadAssets();
				class'HuskGunAttachment'.static.UnloadAssets();
			}
			break;

		case class'GG_LAW':
			if ( class'LAW'.static.UnloadAssets() )
			{
				class'LAWFire'.static.UnloadAssets();
				class'LAWProj'.static.UnloadAssets();
				class'LAWAttachment'.static.UnloadAssets();
			}
			break;

		case class'GG_M32GrenadeLauncher':
			if ( class'M32GrenadeLauncher'.static.UnloadAssets() )
			{
				class'M32Fire'.static.UnloadAssets();
				class'M32GrenadeProjectile'.static.UnloadAssets();
				class'M32Attachment'.static.UnloadAssets();
			}
			break;

		case class'GG_M79GrenadeLauncher':
			if ( class'M79GrenadeLauncher'.static.UnloadAssets() )
			{
				class'M79Fire'.static.UnloadAssets();
				class'M79GrenadeProjectile'.static.UnloadAssets();
				class'M79Attachment'.static.UnloadAssets();
			}
			break;

		case class'GG_M4203AssaultRifle':
			if ( class'M4203AssaultRifle'.static.UnloadAssets() )
			{
				class'M4203BulletFire'.static.UnloadAssets();
                class'M203Fire'.static.UnloadAssets();
				class'M203GrenadeProjectile'.static.UnloadAssets();
				class'M4203Attachment'.static.UnloadAssets();
			}
			break;
	}
}

/*
exec function M79(optional bool bMaxAmmo)
{
    Pawn.GiveWeapon("KFGunGame.GG_M79GrenadeLauncher");
}

exec function LevelUp()
{
    KFGG(Level.Game).ForceLevelUp(Self);
}*/

defaultproperties
{
     LobbyMenuClassString="KFGunGame.GGLobbyMenu"
     MidGameMenuClass="KFGunGame.KFGGMidGameMenu"
}
