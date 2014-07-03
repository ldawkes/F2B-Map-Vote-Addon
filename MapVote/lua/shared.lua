// SHARED

MV_TTTROUNDSNEEDED = ; // Amount of rounds that must be played before voting is allowed (Default: 8)
MV_RTVWARNTIME = 3; // Spam protection for people spamming rtv (stops the chat filling up with info text)
MV_RTVPERCENT = 0.6; // Needed RTVs in percent of total players (Default: 0.6 (or 60%))
MV_MAPVOTETIME = 20; // How many seconds the map vote should last (Default: 20)
MV_MAPHISTORY = 5; // How many maps to store as history in the database (Default: 5)
MV_MAPPREFIXES = {
	"ttt_", "de_", "dm_",
	"zm_", "zs_", "cs_"	
};
MV_GROUPCOLOURS = {
	["serverregular"] 		= Color(255,255,255,255),
	["f2bmember"] 			= Color(255,255,0,255),
	["f2bmemberlongterm"] 	= Color(255,102,0,255),
	["vipmember"] 			= Color(128,0,255,255),
	["f2bserveradmin"] 		= Color(170,0,0,255),
	["f2bsuperadmin"] 		= Color(0,170,0,255),
	["f2bmasteradmin"] 		= Color(0,85,170),
	["f2bfounder"] 			= Color(0,153,255,255)
};