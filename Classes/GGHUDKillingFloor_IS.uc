// iSnipe!
class GGHUDKillingFloor_IS extends GGHUDKillingFloor;


simulated function DrawHudPassC(Canvas C)
{
  DrawFadeEffect(C);

  if (bShowScoreBoard && ScoreBoard != none)
  {
    ScoreBoard.DrawScoreboard(C);
  }

  // portrait
  if (bShowPortrait && Portrait != none)
  {
    DrawPortrait(C);
  }

  // removed M99 check for iSnipe mode
  if (PawnOwner != none && PawnOwner.Weapon != none && KFWeapon(PawnOwner.Weapon) != none)
  {
    if (!KFWeapon(PawnOwner.Weapon).bAimingRifle && !PawnOwner.Weapon.IsA('Crossbow'))
    {
      DrawCrosshair(C);
    }
  }

  // Slow, for debugging only
  if (bDebugPlayerCollision && (class'ROEngine.ROLevelInfo'.static.RODebugMode() || Level.NetMode == NM_StandAlone))
  {
    DrawPointSphere();
  }
}