// SYNERGY AUTOSPLITTER
// CREDITS:
// - SmileyAG for basic sigscanning functionality (i modified some 2838 code yes)
// - ScriptedSnark for initial splitter codework
// HOW TO USE: https://github.com/ScriptedSnark/Synergy-Autosplitter/blob/main/README.md
// PLEASE REPORT THE PROBLEMS TO EITHER THE ISSUES SECTION IN THE GITHUB REPOSITORY ABOVE
// MAYBE IT SHOULD BE BETTER TO INCLUDED IN SOURCESPLIT INSTEAD OF ASL SCRIPT? -SmileyAG

state("synergy")
{
}

startup
{
    settings.Add("AutostartILs", false, "Autostart for ILs");

    vars.aslVersion = "2021/05/26";
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
    
    var sig_serverState = new SigScanTarget(22, "83 F8 01 0F 8C ?? ?? 00 00 3D 00 02 00 00 0F 8F ?? ?? 00 00 83 3D ?? ?? ?? ?? 02 7D"); // https://github.com/fatalis/SourceSplit/blob/master/GameMemory.cs#L68-L74

    sig_serverState.OnFound = (proc, scanner, ptr) => !proc.ReadPointer(ptr, out ptr) ? IntPtr.Zero : ptr;

    IntPtr ptr_serverState = TheScanner.Scan(sig_serverState);

    vars.serverState = new MemoryWatcher<int>(ptr_serverState);
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
    if (vars.serverState.Current == 1 && vars.serverState.Old == 2) // https://github.com/fatalis/SourceSplit/blob/master/GameMemory.cs#L891-L892
        return true;
}

update
{
    vars.serverState.Update(game);
}
