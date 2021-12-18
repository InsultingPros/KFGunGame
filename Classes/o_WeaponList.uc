class o_WeaponList extends Object
  PerObjectConfig
  config(KFGunGame);


struct sTeamCharInfo
{
  var string Red;
  var string Blue;
};
var config sTeamCharInfo TeamChars;     // team character list

var config int WarmupTime;              // initial warmup time
var config array<string> WeaponList;    // weapon list aka levels

var config int RemainingTime;           // time limit for matches


defaultproperties{}