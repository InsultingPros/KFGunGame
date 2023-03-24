class KFGGSettings extends Object
    config(KFGunGameSettings);

const INI="KFGunGameSettings";

var config int WarmupTime;              // How long to do a pre match warmup before starting the round
var config string WeaponListName;       // what weapon list to use
var transient array<string> Weapons;    // weapons!

event Created() {
    local array<string> lists;
    local bool bFoundInList;
    local int i;

    lists = GetAllWeaponLists();
    if (lists.length > 0) {
        for (i = 0; i < lists.length; i++) {
            log(lists[i]);
            if (WeaponListName ~= lists[i]) {
                bFoundInList = true;
            }
        }
    }

    if (bFoundInList) {
        Weapons = GetSelectedWeaponList(WeaponListName);
    } else {
        Weapons = class'WeaponList'.default.Weapons;
    }
}

simulated function array<string> GetSelectedWeaponList(string listName)
{
    local WeaponList WeaponList;

    WeaponList = new(none, listName) class'WeaponList';
    return WeaponList.Weapons;
}

simulated function array<string> GetAllWeaponLists() {
    return GetPerObjectNames(INI, string(class'WeaponList'.name));
}

defaultproperties {
    // defaults in case someone forgets about config
    WarmupTime=30
    WeaponListName="Default"
}