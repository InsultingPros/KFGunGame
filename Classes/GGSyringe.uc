//=============================================================================
// Syringe Inventory class
//=============================================================================
class GGSyringe extends Syringe;

simulated function PostBeginPlay() {
    super(KFWeapon).PostBeginPlay(); // No additional health boost.
}

defaultproperties {
    FireModeClass(0)=class'GGSyringeFire'
    PickupClass=class'GGSyringePickup'
}