include("shared.lua");
include("sh_functions.lua");
include("cl_menu.lua");

/********************/
/**** FONT SETUP ****/
/********************/
surface.CreateFont( "Treb14", {
					font = "Trebuchet",
					size = 14,
					weight = 1,
					} );
surface.CreateFont( "Treb16", {
					font = "Trebuchet",
					size = 16,
					weight = 1,
					} )
surface.CreateFont( "Treb16Bold", {
					font = "Trebuchet",
					size = 16,
					weight = 700,
					} );
surface.CreateFont( "Treb18Bold", {
					font = "Trebuchet",
					size = 18,
					weight = 700,
					} );
surface.CreateFont( "Treb20Bold", {
					font = "Trebuchet",
					size = 20,
					weight = 700,
					} );
surface.CreateFont( 'Treb24', {
					font = 'Trebuchet',
					size = 24,
					weight = 1,
					antialias = true		
					} )

/*******************************/
/**** UNHOOKED NET RECEIVES ****/
/*******************************/
net.Receive("MV_PlaySound", 
	function()
		surface.PlaySound(net.ReadString());
	end );
	
/*************************/
/**** CLIENTSIDE CODE ****/
/*************************/					
local _intRoundsRemaining = 8;
local _blnRTVSettingsOpen = false;
local _blnDrawRoundCounter = true;

function MV_UpdateRoundsRemaining( intNewNum )
	_intRoundsRemaining = intNewNum;
	print("[MapVote] " .. _intRoundsRemaining .. " rounds remaining");
end
net.Receive("MV_UpdRoundsRemaining", function() MV_UpdateRoundsRemaining(net.ReadInt(8)) end);

function MV_LoadUserSettings()
	if (file.Exists("mapvote/settings.txt", "DATA")) then
		local _blnUserSettings = util.JSONToTable(file.Read("mapvote/settings.txt"));		
		_blnDrawRoundCounter = _blnUserSettings["rtvshoulddraw"];
	else
		_blnDrawRoundCounter = true;	
	end
end
net.Receive("MV_UserSettings", function() MV_LoadUserSettings() end);

function MV_DrawHUD()
	if (_blnDrawRoundCounter) then
		local intBoxX, intBoxY, intBoxW, intBoxH = 10, 100, 110, 65;
		
		draw.RoundedBox(6, intBoxX, intBoxY, intBoxW, intBoxH, Color(0,0,0,100));
		
		if !(_intRoundsRemaining == 0) then		
			draw.SimpleTextOutlined(_intRoundsRemaining, "Treb20Bold", (intBoxX + (intBoxW / 2)), intBoxY + 15, Color(255,50,50,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,255));
			
			local strStart = "rounds";
			if _intRoundsRemaining == 1 then strStart = "round" else strStart = "rounds" end
			
			draw.DrawText(strStart .. " until rtv\nis available", "Treb16", (intBoxX + (intBoxW / 2)), intBoxY + 25, Color(255,255,255,255), TEXT_ALIGN_CENTER);
		else
			draw.DrawText("Map Voting\nAvailable", "Treb18Bold", (intBoxX + (intBoxW / 2)), intBoxY + 13, Color(50,255,50,255), TEXT_ALIGN_CENTER);
		end
	end
end
hook.Add("HUDPaint", "MV_DrawHUD", MV_DrawHUD)

function MV_RTVSettings()
	if !(_blnRTVSettingsOpen) then
		if !(pnlRTVSettings) then
			pnlRTVSettings 		= vgui.Create("DPanel");
			lblTitle 			= vgui.Create("DLabel", pnlRTVSettings);
			chkToggleRTVHUD 	= vgui.Create("DCheckBoxLabel", pnlRTVSettings);
			btnCloseRTVSettings = vgui.Create("DButton", pnlRTVSettings);
		end
		
		pnlRTVSettings:SetSize(200, 60);
		pnlRTVSettings:SetPos(-(pnlRTVSettings:GetWide()), (ScrH()/2) - (pnlRTVSettings:GetTall()/2))
		pnlRTVSettings.Paint =	function(_, w, h)
									draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,200));
								end
		pnlRTVSettings.Think =	function()
									if _blnRTVSettingsOpen then gui.EnableScreenClicker(true) end
								end
		
		local _intPosX, _intPosY = pnlRTVSettings:GetPos();		
		
		lblTitle:SetText("RTV Settings")
		lblTitle:SetFont("Treb18Bold");
		lblTitle:SizeToContents()
		lblTitle:SetPos((pnlRTVSettings:GetWide()/2) - (lblTitle:GetWide()/2), 5)
		
		btnCloseRTVSettings:SetText("X");
		btnCloseRTVSettings:SetTextColor(Color(0,0,0,255));
		btnCloseRTVSettings:SetFont("Treb16Bold");
		btnCloseRTVSettings:SetSize(25,15);
		btnCloseRTVSettings:SetPos(pnlRTVSettings:GetWide() - (btnCloseRTVSettings:GetWide() + 5), 5);
		btnCloseRTVSettings.DoClick =	function()
											_blnRTVSettingsOpen = false;		
											gui.EnableScreenClicker(false);
											pnlRTVSettings:MoveTo(_intPosX, _intPosY, 0.4, 0, 0.5);
										end
		btnCloseRTVSettings.Paint = 	function(_, w, h)
											draw.RoundedBox(8, 0, 0, w, h, Color(255,50,50,255));
										end
		
		chkToggleRTVHUD:SetText("Show HUD Round Count");
		chkToggleRTVHUD:SetValue(_blnDrawRoundCounter);
		chkToggleRTVHUD:SizeToContents();
		chkToggleRTVHUD:SetPos((pnlRTVSettings:GetWide()/2) - (chkToggleRTVHUD:GetWide()/2), ((pnlRTVSettings:GetTall()/2) - (chkToggleRTVHUD:GetTall()/2)) + 15);
		chkToggleRTVHUD.OnChange = 	function(self, value)
										_blnDrawRoundCounter = value;
										
										local _blnShouldRTVDraw = { ["rtvshoulddraw"] = value };
										local _tblToWrite = util.TableToJSON(_blnShouldRTVDraw);
										
										file.Write("mapvote/settings.txt", _tblToWrite);
									end
		
		pnlRTVSettings:MoveTo(25, _intPosY, 0.4, 0, 0.5);
		gui.EnableScreenClicker(true);
		
		_blnRTVSettingsOpen = true;
	end
end
net.Receive("MV_RTVSettingsMenu", function() MV_RTVSettings() end);