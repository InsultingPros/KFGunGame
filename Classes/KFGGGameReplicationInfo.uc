class KFGGGameReplicationInfo extends KFGameReplicationInfo;

var byte MaxWeaponLevel; // The maximum weapon level before someone wins the match

replication
{
	reliable if(Role == ROLE_Authority)
		MaxWeaponLevel;
}

defaultproperties
{
}
