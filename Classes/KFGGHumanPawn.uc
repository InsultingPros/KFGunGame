//=============================================================================
// KFGGHumanPawn
//=============================================================================
class KFGGHumanPawn extends KFHumanPawn
    config(KFGunGameGarbage);

// Just changed to pendingWeapon
simulated function ChangedWeapon() {
    super.ChangedWeapon();

    if (Level.NetMode != NM_DedicatedServer && KFPlayerController(Controller) != none) {
        KFPlayerController(Controller).TransitionFOV(KFPlayerController(Controller).DefaultFOV, 0.25);
    }
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation) {
    // local Vector TossVel;
    local Trigger T;
    local NavigationPoint N;
    local PlayerDeathMark D;
    local Projectile PP;
    local FakePlayerPawn FP;

    if (bDeleteMe || Level.bLevelChange || Level.Game == none) {
        return; // already destroyed, or level is being cleaned up
    }

    if (
        DamageType.default.bCausedByWorld &&
        (Killer == none || Killer == Controller) &&
        LastHitBy != none
    ) {
        Killer = LastHitBy;
    }

    // mutator hook to prevent deaths
    // WARNING - don't prevent bot suicides - they suicide when really needed
    if (Level.Game.PreventDeath(self, Killer, damageType, HitLocation)) {
        Health = max(Health, 1); //mutator should set this higher
        return;
    }

    // Turn off the auxilary collision when the player dies
    if (AuxCollisionCylinder != none) {
        AuxCollisionCylinder.SetCollision(false, false, false);
    }

    // Hack fix for team-killing.
    if (KFPlayerReplicationInfo(PlayerReplicationInfo) != none) {
        FP = KFPlayerReplicationInfo(PlayerReplicationInfo).GetBlamePawn();
        if (FP != none) {
            ForEach DynamicActors(class'Projectile', PP) {
                if (PP.Instigator == Self) {
                    PP.Instigator = FP;
                }
            }
        }
    }

    D = Spawn(class'PlayerDeathMark');
    if (D != none) {
        D.Velocity = Velocity;
    }

    Health = Min(0, Health);

    if (Weapon != none && (DrivenVehicle == none || DrivenVehicle.bAllowWeaponToss)) {
        if (Controller != none) {
            Controller.LastPawnWeapon = Weapon.class;
        }
        Weapon.HolderDied();
        // TossVel = Vector(GetViewRotation());
        // TossVel = TossVel * ((Velocity Dot TossVel) + 500) + Vect(0,0,200);
        // TossWeapon(TossVel);
    }
    if (DrivenVehicle != none) {
        Velocity = DrivenVehicle.Velocity;
        DrivenVehicle.DriverDied();
    }

    if (Controller != none) {
        Controller.WasKilledBy(Killer);
        Level.Game.Killed(Killer, Controller, self, damageType);
    } else {
        Level.Game.Killed(Killer, Controller(Owner), self, damageType);
    }

    DrivenVehicle = none;

    if (Killer != none) {
        TriggerEvent(Event, self, Killer.Pawn);
    } else {
        TriggerEvent(Event, self, none);
    }

    // make sure to untrigger any triggers requiring player touch
    if (IsPlayerPawn() || WasPlayerPawn()) {
        PhysicsVolume.PlayerPawnDiedInVolume(self);
        ForEach TouchingActors(class'Trigger', T) {
            T.PlayerToucherDied(self);
        }

        // event for HoldObjectives
        ForEach TouchingActors(class'NavigationPoint', N) {
            if (N.bReceivePlayerToucherDiedNotify) {
                N.PlayerToucherDied(Self);
            }
        }
    }
    // remove powerup effects, etc.
    RemovePowerups();
    Velocity.Z *= 1.3;
    if (IsHumanControlled()) {
        PlayerController(Controller).ForceDeathUpdate();
    }

    NetUpdateFrequency = default.NetUpdateFrequency;
    PlayDying(DamageType, HitLocation);
    if (!bPhysicsAnimUpdate && !IsLocallyControlled()) {
        ClientDying(DamageType, HitLocation);
    }
}

simulated function ClearOutCurrentWeapons() {
    local Inventory I;
    local int Count;
    local class<Inventory> InventoryClass;
    local bool bEquipmentIsRequired;
    local int j;

    // for (I = Inventory; I != none && Count < 50; I = I.Inventory)
    I = Inventory;

    SetAiming(false);

    if (Level.NetMode != NM_DedicatedServer && KFPlayerController(Controller) != none) {
        KFPlayerController(Controller).TransitionFOV(KFPlayerController(Controller).DefaultFOV, 0.25);
    }

    while (I != none && Count < 50) {
        bEquipmentIsRequired = false;

        // log("Attempting to get rid of weapon "$I$" count = "$count);
        for (j = 0; j < 16; j++) {
            if (RequiredEquipment[j] != "") {
                InventoryClass = Level.Game.BaseMutator.GetInventoryClass(RequiredEquipment[j]);
                if (InventoryClass != none && I.class == InventoryClass) {
                    bEquipmentIsRequired = true;
                    break;
                }
            }
        }

        if (bEquipmentIsRequired) {
            I = I.Inventory;
            continue;
        }
        // debug
        // log("Getting Rid of weapon " $ I);

        I.Destroyed();
        if (I != none) {
            I.Destroy();
        }

        Count++;
        I = Inventory;
    }
    // ChangedWeapon();
}

function TossWeapon(Vector TossVel) {
    local Vector X,Y,Z;
    local WeaponPickup W;

    Weapon.Velocity = TossVel;
    GetAxes(Rotation, X, Y, Z);
    X = Location + 0.8 * CollisionRadius * X - 0.5 * CollisionRadius * Y;
    Weapon.DropFrom(X);
    foreach CollidingActors(class'WeaponPickup', W, 100, X) {
        if (W.bDropped) {
            W.LifeSpan = 10.f; // Make sure it gets destroyed.
        }
    }
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc) {
    local LavaDeath LD;
    local MiscEmmiter BE;

    if (Adjuster != none) {
        Adjuster.Destroy();
    }
    bHasFootAdjust = false;
    AmbientSound = none;
    bCanTeleport = false; // sjs - fix karma going crazy when corpses land on teleporters
    bReplicateMovement = false;
    bTearOff = true;
    bPlayedDeath = true;
    //bFrozenBody = true;

    SafeMesh = Mesh;

    if (CurrentCombo != none) {
        CurrentCombo.Destroy();
    }

    HitDamageType = DamageType; // these are replicated to other clients
    TakeHitLocation = HitLoc;

    if (DamageType != none) {
        if (DamageType.default.bSkeletize) {
            SetOverlayMaterial(DamageType.default.DamageOverlayMaterial, 4.0, true);
            if (!bSkeletized) {
                if ((Level.NetMode != NM_DedicatedServer) && DamageType.default.bLeaveBodyEffect) {
                    BE = spawn(class'MiscEmmiter', self);
                    if (BE != none) {
                        BE.DamageType = DamageType;
                        BE.HitLoc = HitLoc;
                        bFrozenBody = true;
                    }
                }
                if (Physics == PHYS_Walking) {
                    Velocity = Vect(0, 0, 0);
                }
                SetTearOffMomemtum(GetTearOffMomemtum() * 0.25);
                bSkeletized = true;
                if (Level.NetMode != NM_DedicatedServer && DamageType == class'FellLava') {
                    LD = spawn(class'LavaDeath', , , Location + vect(0, 0, 10), Rotation);
                    if (LD != none) {
                        LD.SetBase(self);
                    }
                    // KFTODO: Replace this sound
                    PlaySound(sound'Inf_Weapons.F1.f1_explode01', SLOT_None, 1.5 * TransientSoundVolume);
                }
            }
        } else if (DamageType.default.DeathOverlayMaterial != none) {
            SetOverlayMaterial(DamageType.default.DeathOverlayMaterial, DamageType.default.DeathOverlayTime, true);
        } else if (DamageType.default.DamageOverlayMaterial != none && Level.DetailMode != DM_Low && !Level.bDropDetail) {
            SetOverlayMaterial(DamageType.default.DamageOverlayMaterial, 2*DamageType.default.DamageOverlayTime, true);
        }
    }

    // stop shooting
    AnimBlendParams(1, 0.0);
    FireState = FS_None;
    LifeSpan = 60.f;

    GotoState('Dying');
    if (BE != none) {
        return;
    }

    PlayDyingAnimation(DamageType, HitLoc);
}

function PlayDyingAnimation(class<DamageType> DamageType, vector HitLoc) {
    local vector shotDir, hitLocRel, deathAngVel, shotStrength;
    local float maxDim;
    local string RagSkelName;
    local KarmaParamsSkel skelParams;
    local bool PlayersRagdoll;
    local PlayerController pc;

    if (Level.NetMode != NM_DedicatedServer) {
        // Is this the local player's ragdoll?
        if (OldController != none) {
            pc = PlayerController(OldController);
        }
        if (pc != none && pc.ViewTarget == self) {
            PlayersRagdoll = true;
        }

        // Try and obtain a rag-doll setup. Use optional 'override' one out of player record first, then use the species one.
        if (RagdollOverride != "") {
            RagSkelName = RagdollOverride;
        } else if (Species != none) {
            RagSkelName = Species.static.GetRagSkelName(GetMeshName() );
        } else {
            RagSkelName = "Male1"; // Otherwise assume it is Male1 ragdoll were after here.
        }

        KMakeRagdollAvailable();

        if (KIsRagdollAvailable() && RagSkelName != "") {
            skelParams = KarmaParamsSkel(KParams);
            skelParams.KSkeleton = RagSkelName;

            // Stop animation playing.
            StopAnimating(true);

            if (DamageType != none) {
                if (DamageType.default.bLeaveBodyEffect) {
                    TearOffMomentum = vect(0, 0, 0);
                }

                if (DamageType.default.bKUseOwnDeathVel) {
                    RagDeathVel = DamageType.default.KDeathVel;
                    RagDeathUpKick = DamageType.default.KDeathUpKick;
                }
            }

            // Set the dude moving in direction he was shot in general
            shotDir = Normal(GetTearOffMomemtum());
            shotStrength = RagDeathVel * shotDir;

            // Calculate angular velocity to impart, based on shot location.
            hitLocRel = TakeHitLocation - Location;

            // We scale the hit location out sideways a bit, to get more spin around Z.
            hitLocRel.X *= RagSpinScale;
            hitLocRel.Y *= RagSpinScale;

            // If the tear off momentum was very small for some reason, make up some angular velocity for the pawn
            if (VSize(GetTearOffMomemtum()) < 0.01) {
                //Log("TearOffMomentum magnitude of Zero");
                deathAngVel = VRand() * 18000.0;
            } else {
                deathAngVel = RagInvInertia * (hitLocRel Cross shotStrength);
            }

            // Set initial angular and linear velocity for ragdoll.
            // Scale horizontal velocity for characters - they run really fast!
            if (DamageType.default.bRubbery) {
                skelParams.KStartLinVel = vect(0, 0, 0);
            }
            if (Damagetype.default.bKUseTearOffMomentum) {
                skelParams.KStartLinVel = GetTearOffMomemtum() + Velocity;
            } else {
                skelParams.KStartLinVel.X = 0.6 * Velocity.X;
                skelParams.KStartLinVel.Y = 0.6 * Velocity.Y;
                skelParams.KStartLinVel.Z = 1.0 * Velocity.Z;
                skelParams.KStartLinVel += shotStrength;
            }
            // If not moving downwards - give extra upward kick
            if (
                !DamageType.default.bLeaveBodyEffect &&
                !DamageType.default.bRubbery &&
                (Velocity.Z > -10)
            ) {
                skelParams.KStartLinVel.Z += RagDeathUpKick;
            }

            if (DamageType.default.bRubbery) {
                Velocity = vect(0, 0, 0);
                skelParams.KStartAngVel = vect(0, 0, 0);
            } else {
                skelParams.KStartAngVel = deathAngVel;

                // Set up deferred shot-bone impulse
                maxDim = Max(CollisionRadius, CollisionHeight);

                skelParams.KShotStart = TakeHitLocation - (1 * shotDir);
                skelParams.KShotEnd = TakeHitLocation + (2 * maxDim * shotDir);
                skelParams.KShotStrength = RagShootStrength;
            }

            // If this damage type causes convulsions, turn them on here.
            if (DamageType != none && DamageType.default.bCauseConvulsions) {
                RagConvulseMaterial=DamageType.default.DamageOverlayMaterial;
                skelParams.bKDoConvulsions = true;
            }

            // Turn on Karma collision for ragdoll.
            KSetBlockKarma(true);

            // Set physics mode to ragdoll.
            // This doesn't actaully start it straight away, it's deferred to the first tick.
            SetPhysics(PHYS_KarmaRagdoll);

            // If viewing this ragdoll, set the flag to indicate that it is 'important'
            if (PlayersRagdoll) {
                skelParams.bKImportantRagdoll = true;
            }
            skelParams.bRubbery = DamageType.default.bRubbery;
            bRubbery = DamageType.default.bRubbery;

            skelParams.KActorGravScale = RagGravScale;
            return;
        }
        // jag
    }

    // non-ragdoll death fallback
    Velocity += GetTearOffMomemtum();
    BaseEyeHeight = default.BaseEyeHeight;
    SetTwistLook(0, 0);
    SetInvisibility(0.0);
    SetCollision(false);
    SetPhysics(PHYS_Falling);
    LifeSpan = 3.f;
}

// disable potentially exploitable feature
exec function TossCash(int Amount) {
    ClientMessage("TossCash is disabled for gun game. DO NOT TRY TO CHEAT!!!");
}

defaultproperties {
    RequiredEquipment(1)=""
    RequiredEquipment(2)=""
    RequiredEquipment(3)="KFGunGame.GGSyringe"
    RequiredEquipment(4)=""
    bNoTeamBeacon=true
    bScriptPostRender=false
    GroundSpeed=250.000000
}