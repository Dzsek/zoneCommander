local slotblock = {}
function slotblock.onPlayerTryChangeSlot(playerId, side, slotId)
	local gname = DCS.getUnitProperty(slotId, DCS.UNIT_GROUPNAME)
	local _status,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag(\""..gname.."\"); ")
	
	if _status then
		local isblocked = tonumber(_status)
		if isblocked==1 then
			net.send_chat_to('Can not spawn as '..gname..' in enemy/neutral zone' , playerId)
			net.force_player_slot(playerId, 0, '')
			return false
		end
	end
end

DCS.setUserCallbacks(slotblock)
