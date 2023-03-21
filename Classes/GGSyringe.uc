//=============================================================================
// Syringe Inventory class
//=============================================================================
class GGSyringe extends Syringe;

simulated function PostBeginPlay()
{
	Super(KFWeapon).PostBeginPlay(); // No additional health boost.
}

defaultproperties
{
     FireModeClass(0)=Class'GGSyringeFire'
     PickupClass=Class'GGSyringePickup'
}
