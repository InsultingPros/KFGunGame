class KFGGGameReplicationInfo extends KFGameReplicationInfo;

const MAXWEAPONS=100;           // 100 is more than enough for all vanilla weapons + custom gg ones
var byte MaxWeaponLevel;        // The maximum weapon level before someone wins the match
var int WarmupTime;             // How long to do a pre match warmup before starting the round
var string weapons[MAXWEAPONS];

replication {
    reliable if (Role == ROLE_Authority)
        MaxWeaponLevel, WarmupTime, weapons;
}

// load all required stuff from `KFGGSettings`
simulated function PostBeginPlay() {
    local KFGGSettings Settings;
    local array<string> loaded_weapons;
    local int i, loaded_weapons_count;

    super.PostBeginPlay();

    Settings = new(outer) class'KFGGSettings';

    WarmupTime = Settings.WarmupTime;

    loaded_weapons = Settings.Weapons;
    loaded_weapons_count = loaded_weapons.length;
    // check if admins did not load more than MAXWEAPONS num weapons
    if (loaded_weapons_count > MAXWEAPONS) {
        loaded_weapons.length = MAXWEAPONS;
        loaded_weapons_count = MAXWEAPONS;
        warn("Your weapon list in config file exceeds limit of 100. Go fix it!");
    }

    MaxWeaponLevel = loaded_weapons_count;

    for (i = 0; i < loaded_weapons_count ; i += 1) {
        weapons[i] = loaded_weapons[i];
        log("KFGG Weapon #" $ i $ ": " $ weapons[i]);
    }

    // remove logs?
    log(">>> MaxWeaponLevel: " $ MaxWeaponLevel);
    log(">>> WarmupTime: " $ WarmupTime);
    log(">>> Replicated weapons length: " $ loaded_weapons_count);
}