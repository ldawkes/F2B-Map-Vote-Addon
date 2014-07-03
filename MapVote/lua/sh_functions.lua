if SERVER then

	util.AddNetworkString("sv_ChatAddText");

	chat = {};
	function chat.AddText(...)
		local arg = {...};
		local ply = nil;
		if ( type(arg[1]) == "Player" ) then ply = arg[1] end
		
		net.Start("sv_ChatAddText");		
			net.WriteUInt(#arg, 4);		
			for _, v in pairs(arg) do
				if (type(v) == "string") then
					net.WriteString(v);
				elseif (type(v) == "table") then
					net.WriteUInt( v.r, 8 );
					net.WriteUInt( v.g, 8 );
					net.WriteUInt( v.b, 8 );
					net.WriteUInt( v.a, 8 );
				end
			end
		if (ply) then net.Send(ply) else net.Broadcast() end
	end

else

	net.Receive("sv_ChatAddText", 
		function()
			local _argc = net.ReadUInt(4);
			local args = { };
			
			for i = 1, _argc / 2, 1 do
				table.insert( args, Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)) );
				table.insert( args, net.ReadString() );
			end
			
			chat.AddText( unpack(args) );
		end );
		
end