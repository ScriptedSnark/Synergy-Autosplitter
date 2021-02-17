state("synergy") // Offsets
{
    int loading: "engine.dll", 0x00079624, 0x0;
}

isLoading // Gametimer
{
	return (current.loading != 0);
}

split // Autosplitter
{
	if (current.loading == 1 && old.loading == 0) 
		return true;
}