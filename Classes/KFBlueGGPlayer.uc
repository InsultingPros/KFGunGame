// Blue Team player.
class KFBlueGGPlayer extends KFRedGGPlayer;

simulated function bool IsTeamColorCharacter(string CheckString) {
    if (
        CheckString == "Police_Constable_Briar" ||
        CheckString == "Police_Sergeant_Davin" ||
        CheckString == "Paramedic_Alfred_Anderson"
    ) {
        return true;
    } else {
        return false;
    }
}

simulated function string GetDefaultCharacter() {
    local int RandChance;

    RandChance = Rand(2);

    if (RandChance == 0) {
        return "Police_Constable_Briar";
    } else if (RandChance == 1) {
        return "Paramedic_Alfred_Anderson";
    } else {
        return "Police_Sergeant_Davin";
    }

    // kinda fits
    // Agent_Wilkes
    // FoundryWorker_Aldridge
    // KF_German
    // MR_Foster
    // Pyro_Blue
}