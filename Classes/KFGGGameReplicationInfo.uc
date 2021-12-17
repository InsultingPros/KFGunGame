class KFGGGameReplicationInfo extends KFGameReplicationInfo
  dependson(o_WeaponList);


var byte MaxWeaponLevel; // The maximum weapon level before someone wins the match

var o_WeaponList.sTeamCharInfo TeamChars;


replication
{
  reliable if (Role == ROLE_Authority)
    MaxWeaponLevel, TeamChars;
}


defaultproperties{}