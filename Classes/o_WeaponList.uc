class o_WeaponList extends Object
  PerObjectConfig
  config(KFGunGame);


struct sTeamCharInfo
{
  var array<string> Red;
  var array<string> Blue;
};
var config sTeamCharInfo TeamChars;

var config int WarmupTime;
var config array<string> WeaponList;