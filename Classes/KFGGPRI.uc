class KFGGPRI extends KFPlayerReplicationInfo;

var int WeaponLevel;

replication {
    // Things the server should send to the client.
    reliable if (bNetDirty && Role == Role_Authority)
        WeaponLevel;
}

simulated function SetGRI(GameReplicationInfo GRI);

function Reset(){
    super.Reset();
    bReadyToPlay = true;
}