// main class!! Red Team player.
class KFGGPlayer_Red extends KFGGHumanPawn;

// #exec obj load file="TeamSkins.utx" package="KFGunGame"
var Material TeamSkinX;
// available character array
var array<string> AvailableChars;


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


// yyup, this is much cleaner than walls of if-else
simulated function bool IsTeamColorCharacter(string s)
{
  local int i;

  for (i = 0; i < AvailableChars.Length; i++)
  {
    if (s ~= AvailableChars[i])
      return true;
  }

  return false;
}


// give random skin on each respawn
simulated function string GetDefaultCharacter()
{
  return AvailableChars[rand(AvailableChars.Length)];
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
  // kinda fits - Security_Office_Thorne
  AvailableChars=("Sergeant_Powers","Corporal_Lewis","Lieutenant_Masterson","Trooper_Clive_Jenkins","LanceCorporal_Lee_Baron","Private_Schnieder")
}