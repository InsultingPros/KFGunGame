class GGSyringeFire extends SyringeFire;

Function Timer()
{
	local KFPlayerReplicationInfo PRI;
	local int MedicReward;
	local KFHumanPawn Healed;
	local float HealSum; // for modifying based on perks

	Healed = CachedHealee;
	CachedHealee = none;

	if ( Healed != none && Healed.Health > 0 && Healed != Instigator )
	{
		Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);

		MedicReward = Syringe(Weapon).HealBoostAmount;

		if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
			MedicReward *= KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetHealPotency(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo));

		HealSum = MedicReward;

		if ( (Healed.Health + Healed.healthToGive + MedicReward) > Healed.HealthMax )
		{
			MedicReward = Healed.HealthMax - (Healed.Health + Healed.healthToGive);
			if ( MedicReward < 0 )
				MedicReward = 0;
		}

		Healed.GiveHealth(HealSum, Healed.HealthMax);

		// Tell them we're healing them
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).Speech('AUTO', 5, "");
		LastHealMessageTime = Level.TimeSeconds;

		PRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
		if ( PRI != None )
		{
			if ( MedicReward > 0 && KFSteamStatsAndAchievements(PRI.SteamStatsAndAchievements) != none )
				KFSteamStatsAndAchievements(PRI.SteamStatsAndAchievements).AddDamageHealed(MedicReward);
			if ( KFHumanPawn(Instigator) != none )
				KFHumanPawn(Instigator).AlphaAmount = 255;
		}
	}
}
function KFHumanPawn GetHealee()
{
	local KFHumanPawn KFHP, BestKFHP;
	local vector Dir;
	local float TempDot, BestDot;

	Dir = vector(Instigator.GetViewRotation());

	foreach Instigator.VisibleCollidingActors(class'KFHumanPawn', KFHP, 80.0)
	{
		if ( KFHP.Health<100 && KFHP.Health>0 && KFHP.GetTeamNum()==Instigator.GetTeamNum() )
		{
			TempDot = Dir dot (KFHP.Location - Instigator.Location);
			if ( TempDot > 0.7 && TempDot > BestDot )
			{
				BestKFHP = KFHP;
				BestDot = TempDot;
			}
		}
	}

	return BestKFHP;
}

defaultproperties
{
     NoHealTargetMessage="You must be near another team member to heal them!"
}
