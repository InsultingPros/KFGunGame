class GGShopTrigger extends Triggers
    NotPlaceable;

var byte Team;

function Touch(Actor Other) {
    if (
        Pawn(Other) != none &&
        PlayerController(Pawn(Other).Controller) != none &&
        Pawn(Other).GetTeamNum() == Team
    ) {
        PlayerController(Pawn(Other).Controller).ReceiveLocalizedMessage(class'KFMainMessages', 3);
    }
}

function UsedBy(Pawn user) {
    // Set the pawn to an idle anim so he wont keep making footsteps
    User.SetAnimAction(User.IdleWeaponAnim);

    if (KFPlayerController(user.Controller) != none && user.GetTeamNum() == Team) {
        KFPlayerController(user.Controller).ShowBuyMenu("Mee", KFHumanPawn(user).MaxCarryWeight);
    }
}

function Destroyed() {
    local KFPawn P;

    foreach TouchingActors(class'KFPawn', P) {
        if (PlayerController(P.Controller) != none) {
            PlayerController(P.Controller).ClientCloseMenu(true, true);
        }
    }
}

defaultproperties {
    LifeSpan=30.000000
    CollisionRadius=200.000000
    CollisionHeight=60.000000
}