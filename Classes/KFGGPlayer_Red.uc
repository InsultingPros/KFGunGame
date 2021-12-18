// main class!! Red Team player.
class KFGGPlayer_Red extends KFGGHumanPawn;

// #exec obj load file="TeamSkins.utx" package="KFGunGame"
var Material TeamSkinX;
// available character array
var array<string> TeamCharsArr;


simulated function PostBeginPlay()
{
  super.PostBeginPlay();

  // AssignInitialPose();

  // if (bActorShadows && bPlayerShadows && (Level.NetMode!=NM_DedicatedServer))
  // {
  //  if (bDetailedShadows)
  //    PlayerShadow = spawn(class'KFShadowProject', self,'', Location);
  //  else PlayerShadow = spawn(class'ShadowProjector', self,'', Location);
  //  PlayerShadow.ShadowActor = self;
  //  PlayerShadow.bBlobShadow = bBlobShadow;
  //  PlayerShadow.LightDirection = Normal(vect(1, 1, 3));
  //  PlayerShadow.InitShadow();
  // }

  Skins[0] = TeamSkinX;
}


simulated function GetReplicatedArray()
{
  local KFGGGameReplicationInfo GGRI;
  local string str;
  local int i;

  GGRI = KFGGGameReplicationInfo(level.GRI);
  log(">>>KFGGPlayer_Red: PlayerReplicationInfo.Team.TeamIndex is: " $ PlayerReplicationInfo.Team.TeamIndex);
  if (PlayerReplicationInfo.Team.TeamIndex == 0)
    str = GGRI.TeamChars.Red;
  else if (PlayerReplicationInfo.Team.TeamIndex == 1)
    str = GGRI.TeamChars.Blue;

  // get and fill our char array
  split(str, ";", TeamCharsArr);

  // for (i = 0; i < TeamCharsArr.length; i++)
  // {
  //   log(">>>KFGGPlayer_Red: Char is " $ TeamCharsArr[i]);
  // }
}


// yyup, this is much cleaner than walls of if-else
simulated function bool IsTeamColorCharacter(string s)
{
  local int i;

  GetReplicatedArray();

  // fallback if our char array is empty
  if (TeamCharsArr.Length == 0)
  {
    log(">>>KFGGPlayer_Red: Array is empty for ..." $ class.name);
    return true;
  }

  for (i = 0; i < TeamCharsArr.Length; i++)
  {
    if (s ~= TeamCharsArr[i])
      return true;
  }

  return false;
}


// give random skin on each respawn
simulated function string GetDefaultCharacter()
{
  // fallback if our char array is empty
  if (TeamCharsArr.Length == 0)
  {
    log(">>> KFGGPlayer_Red: FALLBACK in GetDefaultCharacter()");
    return "Sergeant_Powers";
  }
  return TeamCharsArr[rand(TeamCharsArr.Length)];
}


simulated function Setup(xUtil.PlayerRecord rec, optional bool bLoadNow)
{
  if (IsTeamColorCharacter(rec.DefaultName))
  {
    if (rec.Species == none || class<SPECIES_KFMaleHuman>(rec.Species) == none)
      rec = class'xUtil'.static.FindPlayerRecord(GetDefaultCharacter());
  }
  else
  {
    rec = class'xUtil'.static.FindPlayerRecord(GetDefaultCharacter());
  }

  Species = rec.Species;
  RagdollOverride = rec.Ragdoll;
  if (Species!=none && !Species.static.Setup(self, rec))
  {
    rec = class'xUtil'.static.FindPlayerRecord(GetDefaultCharacter());
    Species = rec.Species;
    RagdollOverride = rec.Ragdoll;
    if (!Species.static.Setup(self, rec))
      return;
  }
  if (class<SPECIES_KFMaleHuman>(Species) != none)
  {
    DetachedArmClass = class<SPECIES_KFMaleHuman>(Species).default.DetachedArmClass;
    DetachedLegClass = class<SPECIES_KFMaleHuman>(Species).default.DetachedLegClass;
  }
  // Skins[0] = TeamSkinX;
  ResetPhysicsBasedAnim();
}


// we are not allowed to buy!
function bool CanBuyNow()
{
  return false;
}


defaultproperties
{
  bNoTeamBeacon=false
  bScriptPostRender=true
}