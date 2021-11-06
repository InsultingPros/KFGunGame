// Red Team player. iSnipe!
class KFRedGGPlayer_IS extends KFRedGGPlayer;


simulated function bool IsTeamColorCharacter(string CheckString)
{
  if (CheckString == "Pyro_Red")
  {
    return true;
  }
  else
  {
    return false;
  }
}


simulated function string GetDefaultCharacter()
{
  return "Pyro_Red";
}


defaultproperties
{
  bNoTeamBeacon=false
  bScriptPostRender=true
}