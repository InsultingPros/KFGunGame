// Written by Marco
class KFGGBaseMut extends KillingFloorMut
    HideDropDown
    CacheExempt;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant) {
    if (Controller(Other) != none) {
        Controller(Other).PlayerReplicationInfoClass = class'KFGGPRI';
    }
    return true;
}