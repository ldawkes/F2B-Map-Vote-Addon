local _blnMenuOpen = false;
local _blnMapsSynced = false;
local _intSecondsLeft = 20;
local _strSecondsorSecond = "seconds";
local _strMaps = {};
local _strExcludedMaps = {};
local _strWinningMap = "";
local _btnMapButtons = {};

function MV_CreateMenu()
	pnlMain 		= vgui.Create("DPanel");
	pnlExcluded		= vgui.Create("DPanel");
	lblMainTitle	= vgui.Create("DLabel", pnlMain);
	lblExclTitle	= vgui.Create("DLabel", pnlExcluded);
	lblExclWarning 	= vgui.Create("DLabel", pnlExcluded);
	lblTimer 		= vgui.Create("DLabel", pnlMain);
	btnClose 		= vgui.Create("DButton", pnlMain);
	sclMaps			= vgui.Create("DScrollPanel", pnlMain);
	lytMaps 		= vgui.Create("DIconLayout", sclMaps);
end

function MV_OpenMenu()
	
	if !(_blnMenuOpen) then
		if !(pnlMain) then
			MV_CreateMenu();
		end
		
		pnlMain:SetSize(700, ScrH() - 150);
		pnlMain:SetPos((ScrW()/2) - (pnlMain:GetWide()/2), ScrH() + pnlMain:GetTall());
		pnlMain:SetVisible(true);
		pnlMain.Paint = function(_, w, h)
							draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,200));
						end
		pnlMain.Think = function()
							if _blnMenuOpen then gui.EnableScreenClicker(true) else gui.EnableScreenClicker(false) end
						end
						
		local _intOldX, _intOldY = pnlMain:GetPos();
		
		pnlExcluded:SetSize(200, 180);
		pnlExcluded:SetPos(ScrW() + pnlExcluded:GetWide(), (ScrH()/2) - (pnlExcluded:GetTall()/2));
		pnlExcluded:SetVisible(true);
		pnlExcluded.Paint = 	function(_, w, h)
									draw.RoundedBoxEx(4, 0, 0, w, h, Color(0,0,0,200), false, true, false, true);
								end
		pnlExcluded.Think = 	function()
									if _blnMenuOpen then gui.EnableScreenClicker(true) else gui.EnableScreenClicker(false) end
								end
		
		local _intExclOldX, _intExclOldY = pnlExcluded:GetPos();
		
		lblMainTitle:SetText("Vote for a map!");
		lblMainTitle:SetFont("Treb24");
		lblMainTitle:SetTextColor(Color(0,255,255,255));
		lblMainTitle:SizeToContents();
		lblMainTitle:SetPos((pnlMain:GetWide()/2) - (lblMainTitle:GetWide()/2), 10);
		
		if (_strWinningMap == "") then
			lblTimer:SetText(tostring(_intSecondsLeft) .. " " .. _strSecondsorSecond .. " left");
		else
			lblTimer:SetText("Winning Map: " .. _strWinningMap);
		end
		lblTimer:SetTextColor(Color(0,255,0,255));
		lblTimer:SetFont("Treb20Bold");
		lblTimer:SizeToContents();
		lblTimer:SetPos((pnlMain:GetWide()/2) - (lblTimer:GetWide()/2), pnlMain:GetTall() - (lblTimer:GetTall() + 20));
		
		btnClose:SetText("X");
		btnClose:SetFont("Treb20Bold");
		btnClose:SetTextColor(Color(0,0,0,255));
		btnClose:SetSize(50, 25);
		btnClose:SetPos(pnlMain:GetWide() - (btnClose:GetWide() + 10), 10);
		btnClose.DoClick = 	function()
								pnlMain:MoveTo(_intOldX, _intOldY, 0.4, 0, 0.5, function() pnlMain:SetVisible(false) end);
								pnlExcluded:MoveTo(_intExclOldX, _intExclOldY, 0.4, 0, 0.5, function() pnlExcluded:SetVisible(false) end);
								_blnMenuOpen = false;
								gui.EnableScreenClicker(false);
							end
		btnClose.Paint = 	function(_, w, h)
								draw.RoundedBox(8, 0, 0, w, h, Color(255,50,50,255));
							end
		
		sclMaps:SetSize(pnlMain:GetWide() - 25, pnlMain:GetTall() - 100);
		sclMaps:Center();
		
		lytMaps:SetSize(sclMaps:GetWide() - 15, sclMaps:GetTall());
		lytMaps:SetPos(0,0);
		lytMaps:SetSpaceX(10);
		lytMaps:SetSpaceY(5);
		
		lblExclTitle:SetText("Last Played Maps:");
		lblExclTitle:SetFont("Treb20Bold");
		lblExclTitle:SetTextColor(Color(255,255,0,255));
		lblExclTitle:SizeToContents();
		lblExclTitle:SetPos(5,5);
		
		lblExclWarning:SetText("These maps have been\nexcluded from the list");
		lblExclWarning:SetFont("Treb14");
		lblExclWarning:SetTextColor(Color(255,50,50,255));
		lblExclWarning:SizeToContents();
		lblExclWarning:SetPos(5, pnlExcluded:GetTall() - (lblExclWarning:GetTall() + 5));
		
		if !(_blnMapsSynced) then
			for _, strMapName in pairs(_strMaps) do
				_btnMapButtons[strMapName] = lytMaps:Add("DButton");
				local btnMap = _btnMapButtons[strMapName];
				
				btnMap:SetSize(210, 25);
				btnMap:SetText(strMapName);
				btnMap:SetTextColor(Color(255,255,255,255));
				btnMap.NumVotes = 0;
				
				btnMap["Label"] = vgui.Create("DLabel", btnMap);
				local lblVoteCount = btnMap["Label"];
				
				lblVoteCount:SetText(btnMap.NumVotes);
				lblVoteCount:SetFont("Treb24");
				lblVoteCount:SizeToContents();
				lblVoteCount:SetPos(5, (btnMap:GetTall()/2) - (lblVoteCount:GetTall()/2));
				
				btnMap.DoClick =	function()
										net.Start("MV_SetPlayerWant");
											// I should really send the UniqueID, but the net library
											// does some weird shit when sending larger numbers, 
											// even with 32-bit storage space
											net.WriteEntity(LocalPlayer());
											net.WriteString(strMapName);
										net.SendToServer();
									end
				btnMap.Paint = 	function(_, w, h)
									draw.RoundedBox(2, 0, 0, w, h, Color(100,100,100,255))
								end
				btnMap.Think = 	function()
									if (btnMap.NumVotes > 0) then
										lblVoteCount:SetTextColor(Color(0,255,0,255));
									else
										lblVoteCount:SetTextColor(Color(255,0,0,255));
									end									
									lblVoteCount:SetText(btnMap.NumVotes);
								end
			end
			
			local _intBaseY = 20;
			
			for id, map in pairs(_strExcludedMaps) do
				lblExcludedMap = vgui.Create("DLabel", pnlExcluded);
				lblExcludedMap:SetText(id .. ". " .. map["MapName"]);
				lblExcludedMap:SetFont("Treb16");
				lblExcludedMap:SizeToContents();
				lblExcludedMap:SetPos(10, (_intBaseY + (lblExcludedMap:GetTall() + 5)));
				_intBaseY = _intBaseY + lblExcludedMap:GetTall();
			end
			
			_blnMapsSynced = true;	
		end
		
		local _intCenterX, _intCenterY = (ScrW()/2) - (pnlMain:GetWide()/2), (ScrH()/2) - (pnlMain:GetTall()/2);
		pnlMain:SetVisible(true)
		pnlMain:MoveTo(_intCenterX, _intCenterY, 0.4, 0, 0.5);
		
		local _intExclX, _intExclY = (ScrW()/2) + (pnlMain:GetWide()/2), (ScrH()/2) - (pnlExcluded:GetTall()/2);
		pnlExcluded:MoveTo(_intExclX, _intExclY, 0.4, 0, 0.5);
		gui.EnableScreenClicker(true);
		_blnMenuOpen = true;
	end
end
net.Receive("MV_OpenMapVote", MV_OpenMenu);

net.Receive("MV_UpdateTimer", 
	function()
		if !pnlMain then MV_CreateMenu() end
	
		_intSecondsLeft = net.ReadInt(8);
		_strSecondsorSecond = "seconds";
		local _intNotifyTimes = { 15, 10, 5, 4, 3, 2, 1 };
		if _intSecondsLeft == 1 then _strSecondsorSecond = "second" end
		
		if (table.KeyFromValue(_intNotifyTimes, _intSecondsLeft)) then
			chat.AddText(Color(0,255,0,255), tostring(_intSecondsLeft), Color(255,255,255,255), " " .. _strSecondsorSecond .. " left until winning map is chosen");
			
			local _strSquishy = {
				"physics/flesh/flesh_squishy_impact_hard1.wav",
				"physics/flesh/flesh_squishy_impact_hard2.wav",
				"physics/flesh/flesh_squishy_impact_hard3.wav",
				"physics/flesh/flesh_squishy_impact_hard4.wav"
			};
			
			if _intSecondsLeft <= 5 and _intSecondsLeft > 0 then surface.PlaySound(table.Random(_strSquishy)) end
		elseif (_intSecondsLeft == 0) then
			surface.PlaySound("vo/k_lab/eli_allset.wav");
			timer.Simple(2, 
				function()
					surface.PlaySound("vo/k_lab/kl_fewmoments01.wav");
					timer.Simple(1, function() surface.PlaySound("vo/k_lab/kl_initializing02.wav") end );				
				end );
		end
		
		lblTimer:SetText(_intSecondsLeft .. " " .. _strSecondsorSecond .. " left");
		lblTimer:SizeToContents();
		lblTimer:SetPos((pnlMain:GetWide()/2) - (lblTimer:GetWide()/2), pnlMain:GetTall() - (lblTimer:GetTall() + 20));
	end );
	
net.Receive("MV_SyncMapList", function() _strMaps, _strExcludedMaps = net.ReadTable(), net.ReadTable() end );

net.Receive("MV_SyncMapVotes",
	function() 
		if !pnlMain then MV_CreateMenu() end
	
		local _intVotes = net.ReadTable();
		for strMap, btnMap in pairs(_btnMapButtons) do
			btnMap.NumVotes = 0;
			
			for strMapVote, intNumVotes in pairs(_intVotes) do
				if (strMap == strMapVote) then
					btnMap.NumVotes = intNumVotes;
				end
			end
		end
	end );
	
net.Receive("MV_SyncWinningMap",
	function()
		if !pnlMain then MV_CreateMenu() end
	
		_strWinningMap = net.ReadString();
		
		chat.AddText(Color(0,255,0,255), "Winning Map: " .. _strWinningMap);
		
		lblTimer:SetText("Winning Map: " .. _strWinningMap);
		lblTimer:SizeToContents();
		lblTimer:SetPos((pnlMain:GetWide()/2) - (lblTimer:GetWide()/2), pnlMain:GetTall() - (lblTimer:GetTall() + 20));
	end );