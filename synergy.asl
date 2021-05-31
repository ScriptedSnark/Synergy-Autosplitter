// SYNERGY AUTOSPLITTER
// CREDITS:
// - SmileyAG for basic sigscanning functionality
// - ScriptedSnark for initial splitter codework
// HOW TO USE: https://github.com/ScriptedSnark/Synergy-Autosplitter/blob/main/README.md
// PLEASE REPORT THE PROBLEMS TO EITHER THE ISSUES SECTION IN THE GITHUB REPOSITORY ABOVE

state("synergy") {}

startup
{
    settings.Add("AutostartILs", false, "Autostart for ILs");

    vars.startmaps = new List<string>() 
    {"d1_trainstation_01", "ep1_citadel_00", "ep2_outland_01"};

    vars.aslVersion = "2021/05/30";
}

init
{
    print("=========+++=========");
    print("SYNERGY AUTOSPLITTER VERSION " + vars.aslVersion + " by SmileyAG, ScriptedSnark!");
    print("=========+++=========");

    ProcessModuleWow64Safe process = modules.FirstOrDefault(x => x.ModuleName.ToLower() == "engine.dll");
    if (process == null)
    {
        Thread.Sleep(1000);
        print("process not loaded!");
                throw new Exception();
    }
    
    var TheScanner = new SignatureScanner(game, process.BaseAddress, process.ModuleMemorySize);
    
    var sig_serverState = new SigScanTarget(22, "83 F8 01 0F 8C ?? ?? 00 00 3D 00 02 00 00 0F 8F ?? ?? 00 00 83 3D ?? ?? ?? ?? 02 7D"); // https://github.com/fatalis/SourceSplit/blob/1056cc59c662e3cb7d77e64aef8bbc26c1e90061/GameMemory.cs#L63-L74
    var sig_mapName = new SigScanTarget(13, "D9 ?? 2C D9 C9 DF F1 DD D8 76 ?? 80 ?? ?? ?? ?? ?? 00"); // https://github.com/fatalis/SourceSplit/blob/1056cc59c662e3cb7d77e64aef8bbc26c1e90061/GameMemory.cs#L193-L201

    sig_serverState.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;
    sig_mapName.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

    IntPtr ptr_serverState = TheScanner.Scan(sig_serverState);
    IntPtr ptr_mapName = TheScanner.Scan(sig_mapName);

    vars.serverState = new MemoryWatcher<int>(ptr_serverState);
    vars.mapName = new StringWatcher(ptr_mapName, ReadStringType.ASCII, 64);

    vars.watchList = new MemoryWatcherList(){
	vars.mapName
    };
}

update
{
    vars.watchList.UpdateAll(game);
    vars.serverState.Update(game);
}

isLoading
{
    return (vars.serverState.Current == 1);
}

start
{
    if (settings["AutostartILs"] && vars.serverState.Current == 2 && vars.serverState.Old == 1)
        return true;
}

split
{
    if (vars.serverState.Current == 1 && vars.serverState.Old == 2 && !vars.startmaps.Contains(vars.mapName.Current)) // https://github.com/fatalis/SourceSplit/blob/1056cc59c662e3cb7d77e64aef8bbc26c1e90061/GameMemory.cs#L891-L892
        return true;
}
