g_PluginInfo =
{
	Name = "CClans",
	Version = "1.1",
	Date = "2022-02-06",
	Description = [[Implements clans on the server]],
	Commands =
	{
		['/clan'] =
		{
			Permission = "cclans.basic",
			HelpString = "Clans plugin",
			Handler = clanHandler
		}
	}
}
