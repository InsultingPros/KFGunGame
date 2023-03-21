// Written by Marco
class KFGGBaseMut extends KillingFloorMut
	HideDropDown
	CacheExempt;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if( Controller(Other)!=None )
		Controller(Other).PlayerReplicationInfoClass = Class'KFGGPRI';
	return true;
}

defaultproperties
{
}
