// SERVER INCLUDES
include("sv_database.lua");
include("shared.lua");
include("sh_functions.lua");

// CLIENT DOWNLOADS
AddCSLuaFile("shared.lua");
AddCSLuaFile("sh_functions.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("cl_menu.lua");

// FILES
resource.AddFile("sound/swigg/swiggalicious.wav");

// NET POOLING
util.AddNetworkString("MV_OpenMapVote");
util.AddNetworkString("MV_PlaySound");
util.AddNetworkString("MV_RTVSettingsMenu");
util.AddNetworkString("MV_SetPlayerWant");
util.AddNetworkString("MV_SyncMapList");
util.AddNetworkString("MV_SyncMapVotes");
util.AddNetworkString("MV_SyncWinningMap");
util.AddNetworkString("MV_UpdRoundsRemaining");
util.AddNetworkString("MV_UpdateTimer");
util.AddNetworkString("MV_UserSettings");

// VARIABLES
local _strVoteCommands = {
		"!rtv",
		"!rockthevote",
		"rtv",
		"rockthevote" };
local _strSettingsCommands = {
		"!rtvsettings",
		"rtvsettings" };
local _strValidMaps = {};		
local _blnRTVsReached = false;
local _blnInMapVote = false;

/********************/
/**** GAME HOOKS ****/
/********************/

function MV_Init()
	print("[MapVote] Addon Loaded");
	
	MV_GetMaps();
end
hook.Add("Initialize", "MV_Init", MV_Init)

function MV_PlayerInitSpawn(ply)
	MV_SyncRoundsLeft(ply);

	ply:SetNWBool("HasRTVd", false);
	ply:SetNWInt("RTVWarnTime", 0);
	
	net.Start("MV_UserSettings");
	net.Send(ply);
	
	timer.Simple(2, 
		function() 
			chat.AddText(ply, Color(225,225,225,255), "We're running a mapvote system, type ", Color(255,0,0,255), "!rtv", Color(225,225,225,255), " to vote for a change!") 
			timer.Simple(1, function() chat.AddText(ply, Color(225,225,225,255), "You can also type ", Color(255,0,0,255), "!rtvsettings", Color(225,225,225,255), " to change the settings") end);
			
			if (_blnInMapVote || _blnRTVsReached) then
				MV_SyncMaps(ply);
			end
		end );
end
hook.Add("PlayerInitialSpawn", "MV_PlayerInitSpawn", MV_PlayerInitSpawn);

function MV_PlayerSay(ply, text)
	if (table.KeyFromValue(_strVoteCommands, string.lower(text))) then
		if (_blnInMapVote) then
			chat.AddText(ply, Color(255,190,0,255), "Map vote has already started, opening the menu for you...");
			net.Start("MV_OpenMapVote");
			net.Send(ply);
		else
			if (_blnRTVsReached) then
				if (CurTime() >= ply:GetNWInt("RTVWarnTime")) then	
					chat.AddText(ply, Color(255,0,0,255), "Needed RTVs reached, map vote will start at the end of the round");
					ply:SetNWInt("RTVWarnTime", CurTime() + MV_RTVWARNTIME);
				end
			else
				if (ply:GetNWBool("HasRTVd")) then
					if (CurTime() >= ply:GetNWInt("RTVWarnTime")) then
						chat.AddText(ply, Color(255,0,0,255), "You've already voted for a change!");
						ply:SetNWInt("RTVWarnTime", CurTime() + MV_RTVWARNTIME);
					end
				else
					if (MV_GetRoundsRemaining() <= 0) then				
						ply:SetNWBool("HasRTVd", true);
						
						if (MV_TotalRTVs() >= MV_NeededRTVs()) then
							chat.AddText(MV_GROUPCOLOURS[ply:GetUserGroup()] or Color(255,255,255,255), ply:Nick(), Color(255,255,255,255), " has voted for a change ");
							MV_QueueMapVote();
						else
							local _strVoteorVotes = "votes";
							if MV_TotalRTVs() == 1 then _strVoteorVotes = "vote" end
							
							chat.AddText(MV_GROUPCOLOURS[ply:GetUserGroup()] or Color(255,255,255,255), ply:Nick(), Color(255,255,255,255), " has voted for a change ", Color(0,255,0,255), "(" .. MV_TotalRTVs() .. " " ..  _strVoteorVotes .. ", " .. MV_NeededRTVs() .. " needed)");
							net.Start("MV_PlaySound");
								//net.WriteString("buttons/button6.wav");
								//net.WriteString("ambient/creatures/teddy.wav");
								//net.WriteString("swigg/swiggalicious.wav");
								net.WriteString("buttons/lightswitch2.wav");
							net.Broadcast();
						end
					else			
						if (CurTime() >= ply:GetNWInt("RTVWarnTime")) then
							local _strRoundorRounds = "rounds";
							if MV_GetRoundsRemaining() == 1 then _strRoundorRounds = "round" end
							
							chat.AddText(ply, Color(255,255,255,255), "You must wait ", Color(255,0,0,255), tostring(MV_GetRoundsRemaining()) , Color(255,255,255,255), " more " .. _strRoundorRounds .. " before trying to rtv");
							ply:SetNWInt("RTVWarnTime", CurTime() + MV_RTVWARNTIME);
						end
					end
				end
			end
		end
		return false;
	elseif (table.HasValue(_strSettingsCommands, string.lower(text))) then
		net.Start("MV_RTVSettingsMenu");
		net.Send(ply);
		
		return false;	
	end
end
hook.Add("PlayerSay", "MV_PlayerSay", MV_PlayerSay);

function MV_PlayerDiscon(ply)
	local _intPlayerCount = table.Count(player.GetAll()) - 1;

	if (_intPlayerCount == 0) then
		print("[MapVote] Everyone left!");
		if (_blnRTVsReached) then
			print("[MapVote] Cancelling mapvote...");
			MV_CancelMapVote();
		end
	else	
		if !(_blnInMapVote) then
			local _intPlayersVoted = 0;
			print("[MapVote] Player Count: " .. _intPlayerCount);
			
			for _, v in pairs(player.GetAll()) do
				if v:GetNWBool("HasRTVd") then _intPlayersVoted = _intPlayersVoted + 1; end
			end
			print("[MapVote] Players Voted: " .. _intPlayersVoted);
			
			if (_intPlayerCount == _intPlayersVoted) then
				chat.AddText(Color(0,255,0,255), "Everyone who hasn't voted has left");
				MV_QueueMapVote();
			end
		end
	end
end
hook.Add("PlayerDisconnected", "MV_PlayerDiscon", MV_PlayerDiscon);

/**********************************/
/**** CUSTOM FUNCTIONS & HOOKS ****/
/**********************************/

/* GETTERS */
function MV_GetRoundsRemaining()
	if (gamemode.Get("terrortown")) then
		local _intMaxRounds = GetConVar("ttt_round_limit"):GetInt();
		local _intRoundToReach = math.Clamp(_intMaxRounds - MV_TTTROUNDSNEEDED, 0, _intMaxRounds);
		if intRoundToReach == 0 then intRoundToReach = math.Round(_intMaxRounds / 2) end
		
		local _intTotalRoundsRemaining = GetGlobalInt("ttt_rounds_left", 10)
		local _intRoundsToVote = math.Clamp(_intTotalRoundsRemaining - _intRoundToReach, 0, _intMaxRounds);
		
		return _intRoundsToVote;
	end
end

function MV_GetWinningMap()
	if !(table.GetWinningKey(MV_GetPlayerVotes())) then
		return table.Random(_strValidMaps);
	else
		return table.GetWinningKey(MV_GetPlayerVotes());
	end
end

function MV_GetMaps()
	if table.Count(_strValidMaps) > 0 then table.Empty(_strValidMaps) end	
	local _strAllMaps = file.Find("maps/*.bsp", "MOD");
	
	for AMKey, AMValue in pairs(_strAllMaps) do
		AMValue = string.gsub(AMValue, ".bsp", "");
		for _, strPrefix in pairs(MV_MAPPREFIXES) do
			if (string.sub(AMValue, 1, #strPrefix) == strPrefix && !(AMValue == game.GetMap())) then
				local _tblExludedMaps = MV_GetLastPlayedMaps();
				local _blnMapIsExcluded = false;
				
				if (_tblExludedMaps) then						
					for id, res in pairs(_tblExludedMaps) do
						if (res["MapName"] == AMValue) then
							_blnMapIsExcluded = true;
							break;
						end
					end
				end
				
				if !(_blnMapIsExcluded) then
					table.insert(_strValidMaps, AMValue);
				end
			end
		end
	end
end

function MV_GetPlayerVotes()
	local _intVotes = {};
	
	for _, ply in pairs(player.GetAll()) do
		local _strVote = ply:GetNWString("Wants");
		
		if (_strVote && _strVote != "") then
			_intVotes[_strVote] = _intVotes[_strVote] or 0;
			_intVotes[_strVote] = _intVotes[_strVote] + 1;
		end
	end
	
	return _intVotes;
end

/* SETTERS */
function MV_SetPlayersWant(ply, strWants)
	if !(ply) then 
		ErrorNoHalt("[MapVote] Attempted to set networked var for nil player\n") 
	else
		ply:SetNWString("Wants", strWants);
	end	
	
	MV_SyncPlayerWants();
end
net.Receive("MV_SetPlayerWant", function() MV_SetPlayersWant(net.ReadEntity(), net.ReadString()) end );

/* RTV FUNCTIONS */
function MV_TotalRTVs()
	local _intTotalVotes = 0;
	for _, ply in pairs(player.GetAll()) do
		if ply:GetNWBool("HasRTVd") then _intTotalVotes = _intTotalVotes + 1 end
	end
	
	return _intTotalVotes;
end

function MV_NeededRTVs()
	local _intPlayerCount = table.Count(player.GetAll());
	local _intNeededRTVs = 0;
	
	if (_intPlayerCount == 1) then
		_intNeededRTVs = 1;
	else
		_intNeededRTVs = math.ceil(_intPlayerCount * MV_RTVPERCENT);
	end
	
	return _intNeededRTVs;
end

/* MAP VOTE SPECIFIC FUNCTIONS */
function MV_QueueMapVote()
	_blnRTVsReached = true;
	chat.AddText(Color(50,255,50,255), "A map vote will begin at the end of the current round");
	net.Start("MV_PlaySound");
		net.WriteString("items/suitchargeok1.wav");
	net.Broadcast();
	
	MV_SyncMaps();
end

function MV_StartMapVote()
	_blnInMapVote = true;
	
	chat.AddText(Color(255,255,255,255), "Starting map vote...");
	timer.Simple(3, 
		function()
			net.Start("MV_OpenMapVote");
			net.Broadcast();
			print("[MapVote] Map vote started!");
			
			local _intCurTime = MV_MAPVOTETIME;
			timer.Create("MV_MapVoteTimer", 1, MV_MAPVOTETIME, 
				function()
					_intCurTime = _intCurTime - 1;
					net.Start("MV_UpdateTimer");
						net.WriteInt(_intCurTime, 8);
					net.Broadcast();
					
					if (_intCurTime <= 0) then
						MV_SetLastPlayedMaps();
						local _strWinningMap = MV_GetWinningMap();
						net.Start("MV_SyncWinningMap");
							net.WriteString(_strWinningMap);
						net.Broadcast();
						timer.Simple(8, function() RunConsoleCommand("changelevel", _strWinningMap) end);
					end
				end );
		end );	
end

function MV_CancelMapVote()
	_blnRTVsReached = false;
	print("[MapVote] Mapvote cancelled!");
end

/* SERVER-CLIENT SYNCHRONISATION */
function MV_SyncRoundsLeft( ply )
	net.Start("MV_UpdRoundsRemaining");
		net.WriteInt(MV_GetRoundsRemaining(), 8);
	if (ply) then
		net.Send(ply);
		print("[MapVote] Completed Sync With " .. ply:Nick());
	else
		net.Broadcast();
		local _strPlayerorPlayers = "Players";
		if table.Count(player.GetAll()) == 1 then _strPlayerorPlayers = "Player" end
		
		print("[MapVote] Rounds Left: " .. MV_GetRoundsRemaining() .. ", Synced With " .. table.Count(player.GetAll()) .. " " .. _strPlayerorPlayers);
	end
end

function MV_SyncPlayerWants()
	local _intPlayerVotes = MV_GetPlayerVotes();
	
	net.Start("MV_SyncMapVotes");
		net.WriteTable(_intPlayerVotes);
	net.Broadcast();
end

function MV_SyncMaps(ply)
	net.Start("MV_SyncMapList");
		net.WriteTable(_strValidMaps);
		net.WriteTable(MV_GetLastPlayedMaps());
	if (ply) then 
		net.Send(ply);
		print("[MapVote] Synced " .. table.Count(_strValidMaps) .. " maps with " .. ply:Nick());
	else 
		net.Broadcast();
		print("[MapVote] Synced " .. table.Count(_strValidMaps) .. " maps with " .. table.Count(player.GetAll()) .. " players");
	end
end

/* TTT HOOKS */
function MV_HandleTTTRounds()
	MV_SyncRoundsLeft();
	
	if (_blnRTVsReached) then 
		MV_StartMapVote();
	elseif(GetGlobalInt("ttt_rounds_left", 10) == 0) then
		MV_SyncMaps();
		MV_StartMapVote();
	end
end
hook.Add("TTTEndRound", "MV_HandleTTTRoundEnd", MV_HandleTTTRounds);

function MV_DelayRoundStart()
	if (_blnInMapVote) then
		return true
	end
end
hook.Add("TTTDelayRoundStartForVote", "MV_DelayRoundStart", MV_DelayRoundStart);