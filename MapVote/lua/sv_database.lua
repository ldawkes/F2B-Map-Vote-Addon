// Database
function MV_SetLastPlayedMaps()
	if !(sql.TableExists("MV_LastPlayedMaps")) then
		print("[MapVote] No map vote table found, creating one now...");
		sql.Begin();
			sql.Query("CREATE TABLE MV_LastPlayedMaps(MapID TINYINT(5), MapName VARCHAR(255))");
		sql.Commit();
		print("[MapVote] Created SQL Table 'MV_LastPlayedMaps'");
	end
	
	local _intMapHistoryCount = sql.QueryValue("SELECT COUNT(*) FROM MV_LastPlayedMaps");
	print("[MapVote] " .. _intMapHistoryCount .. " maps found in history");
	
	for i = 1, _intMapHistoryCount, 1 do
		local _strMap = sql.QueryValue("SELECT MapName FROM MV_LastPlayedMaps WHERE MapID=" .. i);
		
		print("[MapVote] Map " .. _strMap .. " found at slot " .. i);
	end
	
	if (tonumber(_intMapHistoryCount) >= MV_MAPHISTORY) then
		print("[MapVote] Map history full, removing oldest entry and organising maps\n");
		
		sql.Query("DELETE FROM MV_LastPlayedMaps WHERE MapID=" .. MV_MAPHISTORY);
		print("[MapVote] Deleted Oldest Record\n");
		
		sql.Query("UPDATE MV_LastPlayedMaps SET MapID = MapID + 1");
		print("[MapVote] Incremented IDs of Maps\n");
		
		sql.Query("INSERT INTO MV_LastPlayedMaps(MapID, MapName) VALUES(1, '" .. game.GetMap() .. "')");
		print("[MapVote] Inserted " .. game.GetMap() .. " into slot 1\n");
	else
		for i = MV_MAPHISTORY-1, 1, -1 do
			local _strMap = sql.QueryValue("SELECT MapName FROM MV_LastPlayedMaps WHERE MapID=" .. i);
			
			if (_strMap) then
				print("\n[MapVote] Found " .. _strMap .. " at slot " .. i .. ", incrementing id...");
				sql.Query("UPDATE MV_LastPlayedMaps SET MapID = MapID + 1 WHERE MapID=" .. i);
				print("     [MapVote] " .. _strMap .. " is now at slot " .. i+1);
			end
		end
		
		sql.Query("INSERT INTO MV_LastPlayedMaps(MapID, MapName) VALUES(1, '" .. game.GetMap() .. "')");
		print("\n[MapVote] Set " .. game.GetMap() .. " as most recently played map");
	end
	
	local _strPlayedMaps = sql.Query("SELECT * FROM MV_LastPlayedMaps ORDER BY MapID");
	print("[MapVote] Map History:");
	for id, map in pairs(_strPlayedMaps) do
		print("     " .. id .. ": " .. map["MapName"]);
	end
end

function MV_GetLastPlayedMaps()
	local _tblMapHistory = sql.Query("SELECT MapName FROM MV_LastPlayedMaps ORDER BY MapID");
	
	return _tblMapHistory;
end