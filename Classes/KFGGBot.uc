class KFGGBot extends KFInvasionBot;

function float AdjustAimError(float aimerror, float TargetDist, bool bDefendMelee, bool bInstantProj, bool bLeadTargetNow )
{
	return super(Bot).AdjustAimError(aimerror,TargetDist,bDefendMelee,bInstantProj,bLeadTargetNow)*25;
}

function bool FindInjuredAlly()
{
	local controller c;
	local KFHumanPawn aKFHPawn;
	local float AllyDist;
	local float BestDist;

    // Lets test them not healing anyone so they just keep fighting
    return false;

	InjuredAlly = None;

	if( LastHealTime>Level.TimeSeconds || !Level.Game.bTeamGame || (Enemy!=None && VSizeSquared(Enemy.Location-Pawn.Location)<1000000.f && LineOfSightTo(Enemy)) )
		return false;

	if( FindMySyringe()==none || MySyringe.ChargeBar()<0.6f )
		return false;

	for(c=level.ControllerList; c!=none; c=c.nextController)
	{
		if( C==Self || C.PlayerReplicationInfo==None || C.PlayerReplicationInfo.Team!=PlayerReplicationInfo.Team )
			continue;

		aKFHPawn = KFHumanPawn(c.pawn);

		// If he's dead. dont bother.
		if ( aKFHPawn==none || aKFHPawn.Health<=0 || aKFHPawn.Health>85 || !ActorReachable(aKFHPawn) )
			continue;

		AllyDist = VSizeSquared(Pawn.Location - AKFHPawn.Location);

		if( InjuredAlly==none || (AllyDist<BestDist) )
		{
			InjuredAlly = aKFHPawn;
			BestDist = AllyDist;
		}
	}
	return (InjuredAlly!=None);
}

function ExecuteWhatToDoNext()
{
	local float WeaponRating;

	bHasFired = false;
	GoalString = "WhatToDoNext at "$Level.TimeSeconds;
	if ( Pawn == None )
	{
		warn(GetHumanReadableName()$" WhatToDoNext with no pawn");
		return;
	}

	if ( Enemy == None )
	{
		if ( Level.Game.TooManyBots(self) )
		{
			if ( Pawn != None )
			{
				Pawn.Health = 0;
				Pawn.Died( self, class'Suicided', Pawn.Location );
			}
			Destroy();
			return;
		}
		BlockedPath = None;
		bFrustrated = false;
		if (Target == None || (Pawn(Target) != None && Pawn(Target).Health <= 0))
			StopFiring();
	}

	if ( ScriptingOverridesAI() && ShouldPerformScript() )
		return;
	if (Pawn.Physics == PHYS_None)
		Pawn.SetMovementPhysics();
	if ( (Pawn.Physics == PHYS_Falling) && DoWaitForLanding() )
		return;
	if ( (StartleActor != None) && !StartleActor.bDeleteMe && (VSize(StartleActor.Location - Pawn.Location) < StartleActor.CollisionRadius)  )
	{
		Startle(StartleActor);
		return;
	}
	bIgnoreEnemyChange = true;
	if ( (Enemy != None) && ((Enemy.Health <= 0) || (Enemy.Controller == None)) )
		LoseEnemy();
	if ( Enemy == None )
		Squad.FindNewEnemyFor(self,false);
	else if ( !Squad.MustKeepEnemy(Enemy) && !EnemyVisible() )
	{
		// decide if should lose enemy
		// TODO - is losing enemies the right thing to do?
		//        do we need SquadAI?
		if ( Squad.IsDefending(self) )
		{
			if ( LostContact(4) )
				LoseEnemy();
		}
		else if ( LostContact(7) )
			LoseEnemy();
	}
	bIgnoreEnemyChange = false;

	if( FindInjuredAlly() )
	{
		GoHealing();
		return;
	}
	else if ( AssignSquadResponsibility() )
	{
		if ( Pawn == None )
			return;
		SwitchToBestWeapon();
		return;
	}
	if ( ShouldPerformScript() )
		return;
	if ( Enemy != None )
		ChooseAttackMode();
	else
	{
		WeaponRating = Pawn.Weapon.CurrentRating/2000;

		if ( FindInventoryGoal(WeaponRating) )
		{
			if ( InventorySpot(RouteGoal) == None )
				GoalString = "fallback - inventory goal is not pickup but "$RouteGoal;
			else GoalString = "Fallback to better pickup "$InventorySpot(RouteGoal).markedItem$" hidden "$InventorySpot(RouteGoal).markedItem.bHidden;
			GotoState('FallBack');
		}
		else
		{
			// No enemy and no ammo to grab. Guess all there is left to do is to chill out
			GoalString = "WhatToDoNext Wander or Camp at "$Level.TimeSeconds;
			WanderOrCamp(true);
		}
	}
	SwitchToBestWeapon();
}

function bool GetNearestShop()
{
	local KFGameType KFGT;
	local int i,l;
	local float Dist,BDist;
	local ShopVolume Sp;

	KFGT = KFGameType(Level.Game);
	if( KFGT==None )
		return false;
	l = KFGT.ShopList.Length;
	for( i=0; i<l; i++ )
	{
		if( !KFGT.ShopList[i].bCurrentlyOpen )
			continue;
		if( !KFGT.ShopList[i].bTelsInit )
			KFGT.ShopList[i].InitTeleports();
		Dist = VSize(KFGT.ShopList[i].Location-Pawn.Location);
		if( Dist<BDist || Sp==None )
		{
			Sp = KFGT.ShopList[i];
			BDist = Dist;
		}
	}
	if( Sp==None )
		return false;
	if( Sp.BotPoint==None )
	{
		Sp.BotPoint = FindShopPoint(Sp);
		if( Sp.BotPoint==None )
			return false;
	}
	ShoppingPath = Sp.BotPoint;
	return true;
}
final function NavigationPoint FindShopPoint( ShopVolume S )
{
	local NavigationPoint N,BN;
	local float Dist,BDist;

	for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		Dist = VSizeSquared(N.Location-S.Location);
		if( BN==None || BDist>Dist )
		{
			BN = N;
			BDist = Dist;
		}
	}
	return BN;
}

/* ChooseAttackMode()
Handles tactical attacking state selection - choose which type of attack to do from here
*/
function ChooseAttackMode()
{
	Super(xBot).ChooseAttackMode();
}

function FightEnemy(bool bCanCharge, float EnemyStrength)
{
	Super(xBot).FightEnemy(bCanCharge,EnemyStrength);
}

function SetCombatTimer()
{
	SetTimer(0.12f, True);
}

function bool CanAfford(class<Pickup> aItem)
{
	local class<kfWeaponPickup> aWeapon;
	local Inventory MyInv;
	local KFWeapon Weap;
	local KFHumanPawn KF;

	aWeapon = class<kfWeaponPickup>(aItem);
	KF = KFHumanPawn(Pawn);
	if( aWeapon==None || KF==None )
		return false;

	for( MyInv=Pawn.Inventory; MyInv!=none; MyInv=Inv.Inventory )
	{
		Weap = KFWeapon(MyInv);
		if( Weap!=none && Weap.PickupClass==aWeapon )
			return (Weap.AmmoClass[0]!=none && PlayerReplicationInfo.Score>=aWeapon.default.ammocost && Weap.AmmoAmount(0)<Weap.AmmoClass[0].Default.MaxAmmo);
	}

	// if we didn't find it above, we need to see if we can buy the whole gun, not just ammo
	return (aWeapon.default.Cost<=PlayerReplicationInfo.Score && aWeapon.default.weight<=(KF.MaxCarryWeight-KF.CurrentWeight));
}
function DoTrading()
{
	local KFWeapon Weap;
	local int i;
	local class<KFWeaponPickup> BuyWeapClass;
	local int NumCanAfford, NumNeeded, NumToBuy;
	local array< class<Pickup> > ShoppingList;
	local byte LCount;
	local KFLevelRules KFLR;

	LastShopTime = level.TimeSeconds+30+500*FRand();

	KFLR = KFGameType(Level.game).KFLRules;
	for(i=0; i<KFLR.MAX_BUYITEMS; i++ )
	{
		if( KFLR.ItemForSale[i]!=None && CanAfford(KFLR.ItemForSale[i]) )
			ShoppingList[ShoppingList.Length] = KFLR.ItemForSale[i];
	}

	while ( PlayerReplicationInfo.Score>20 && LCount++<10 && ShoppingList.Length>0 )
	{
		i = Rand(ShoppingList.length);

		BuyWeapClass = class<KFWeaponPickup>(ShoppingList[i]);
		ShoppingList.Remove(i,1);
		if( BuyWeapClass==None )
			Continue;
		Weap = FindWeaponInInv(BuyWeapClass);

		if(Weap!=none) // already own gun, buy ammo
		{
			NumCanAfford = PlayerReplicationInfo.Score / (BuyWeapClass.default.ammocost);
			NumNeeded = (Weap.AmmoClass[0].default.MaxAmmo-Weap.AmmoAmount(0)) / Weap.MagCapacity;
			NumToBuy = Min(NumCanAfford, NumNeeded);
			PlayerReplicationInfo.Score -= (BuyWeapClass.default.ammocost) * NumToBuy;
			Weap.AddAmmo(Weap.MagCapacity * NumToBuy, 0);
		}
		else // buy that gun
		{
			Weap = KFWeapon(Spawn(BuyWeapClass.default.InventoryType));
			if( Weap!=None )
				Weap.GiveTo(pawn);
			PlayerReplicationInfo.Score -= BuyWeapClass.default.cost;
		}
	}
	SwitchToBestWeapon();
}

state Healing
{
Begin:
	SwitchToBestWeapon();
	WaitForLanding();

KeepMoving:
	if( InjuredAlly==none || InjuredAlly.Health<=0 || InjuredAlly.Health>=90 )
	{
		LastHealTime = Level.TimeSeconds+1.f;
		WhatToDoNext(150);
	}

	if( Enemy==none || VSizeSquared(Pawn.Location-InjuredAlly.Location)<VSizeSquared(Pawn.Location-Enemy.Location) )
		ClientSetWeapon(class'Syringe');

	if( Enemy!=None && VSizeSquared(Enemy.Location-Pawn.Location)<4000000.f && LineOfSightTo(Enemy) )
	{
		LastHealTime = Level.TimeSeconds+6.f;
		WhatToDoNext(152);
	}

	MoveTarget = FindPathToward(InjuredAlly);

	if(MoveTarget!=none)
		MoveToward(MoveTarget,FaceActor(1),,false );
	else
	{
		LastHealTime = Level.TimeSeconds+2.f;
		WhatToDoNext(151);
	}

	if( MySyringe==none )
	{
		FindMySyringe();
		if( MySyringe==none )
		{
			LastHealTime = Level.TimeSeconds+6.f;
			WhatToDoNext(156);
		}
	}
	else if( MySyringe.ChargeBar()<0.5f )
	{
		LastHealTime = Level.TimeSeconds+2.f;
		WhatToDoNext(153);
	}
	GoTo'KeepMoving';
}

defaultproperties
{
     Skill=1.000000
}
