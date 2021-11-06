// Blue Team player. iSnipe!
class KFBlueGGPlayer_IS extends KFBlueGGPlayer;


simulated function bool IsTeamColorCharacter(string CheckString)
{
  if (CheckString == "Pyro_Blue")
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
  return "Pyro_Blue";
}


defaultproperties{}