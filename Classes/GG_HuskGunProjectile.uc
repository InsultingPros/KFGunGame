//=============================================================================
// GG_HuskGunProjectile
//=============================================================================
// Gun Game Version Fireball projectile for the Husk zombie
//=============================================================================
// Killing Floor Source
// Copyright (C) 2009 Tripwire Interactive LLC
// - John "Ramm-Jaeger" Gibson
//=============================================================================
class GG_HuskGunProjectile extends HuskGunProjectile;

simulated function ProcessTouch(Actor Other, Vector HitLocation) {
    local vector X;
    local Vector TempHitLocation, HitNormal;
    local array<int> HitPoints;
    local KFPawn HitPawn;

    // Don't let it hit this player, or blow up on another player
    if (Other == none || Other == Instigator || Other.Base == Instigator) {
        return;
    }

    // Don't collide with bullet whip attachments
    if (KFBulletWhipAttachment(Other) != none) {
        return;
    }

    // Don't allow hits on poeple on the same team
    if (
        KFHumanPawn(Other) != none &&
        Instigator != none &&
        KFHumanPawn(Other).PlayerReplicationInfo.Team.TeamIndex == Instigator.PlayerReplicationInfo.Team.TeamIndex
    ) {
        return;
    }

    // Use the instigator's location if it exists. This fixes issues with
    // the original location of the projectile being really far away from
    // the real Origloc due to it taking a couple of milliseconds to
    // replicate the location to the client and the first replicated location has
    // already moved quite a bit.
    if (Instigator != none) {
        OrigLoc = Instigator.Location;
    }

    X = Vector(Rotation);

    if (Role == ROLE_Authority) {
        if (ROBulletWhipAttachment(Other) != none) {
            if (!Other.Base.bDeleteMe) {
                Other = Instigator.HitPointTrace(
                    TempHitLocation,
                    HitNormal,
                    HitLocation + (200 * X),
                    HitPoints,
                    HitLocation,,
                    1
                );

                if (Other == none || HitPoints.Length == 0) {
                    return;
                }

                HitPawn = KFPawn(Other);

                if (Role == ROLE_Authority) {
                    if (HitPawn != none) {
                        // Hit detection debugging
                        /*
                        log("Bullet hit "$HitPawn.PlayerReplicationInfo.PlayerName);
                        HitPawn.HitStart = HitLocation;
                        HitPawn.HitEnd = HitLocation + (65535 * X);
                        */

                        if (!HitPawn.bDeleteMe) {
                            HitPawn.ProcessLocationalDamage(
                                ImpactDamage,
                                Instigator,
                                TempHitLocation,
                                MomentumTransfer * Normal(Velocity),
                                ImpactDamageType,
                                HitPoints
                            );
                        }

                        // Hit detection debugging
                        // if (Level.NetMode == NM_Standalone)
                        //    HitPawn.DrawBoneLocation();
                    }
                }
            }
        } else {
            if (Pawn(Other) != none && Pawn(Other).IsHeadShot(HitLocation, X, 1.0)) {
                Pawn(Other).TakeDamage(
                    ImpactDamage * HeadShotDamageMult,
                    Instigator,
                    HitLocation,
                    MomentumTransfer * Normal(Velocity),
                    ImpactDamageType
                );
            } else {
                Other.TakeDamage(
                    ImpactDamage,
                    Instigator,
                    HitLocation,
                    MomentumTransfer * Normal(Velocity),
                    ImpactDamageType
                );
            }
        }
    }

    if (!bDud) {
        Explode(HitLocation, Normal(HitLocation - Other.Location));
    }
}