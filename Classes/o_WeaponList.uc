class o_WeaponList extends Object
  PerObjectConfig
  config(KFGunGame);


struct sTeamCharInfo
{
  var string Red;
  var string Blue;
};
var config sTeamCharInfo TeamChars;

var config int WarmupTime;
var config array<string> WeaponList;