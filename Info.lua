g_PluginInfo =
{
	Name = "CClans",
	Version = "1",
	Date = "2020-11-19",
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
