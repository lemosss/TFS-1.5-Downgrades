-- Rookgaard katana lever — toggle a teleport at (32178, 32144, 11) that
-- sends the player to (32174, 32147, 11). The exit teleport (id 1387) at
-- (32171, 32149, 11) is already in the .otbm and sends back outside;
-- this script only touches the entry-side teleport. Lever 1945 = OFF,
-- 1946 = ON.

local TELEPORT_POS = {x = 32178, y = 32144, z = 11, stackpos = 1}
local DESTINATION  = {x = 32174, y = 32147, z = 11}
local TELEPORT_ID  = 1387

function onUse(cid, item, frompos, item2, topos)
	if item.itemid == 1945 then
		-- Lever was off: open the passage by spawning the teleport
		doCreateTeleport(TELEPORT_ID, DESTINATION, TELEPORT_POS)
		doTransformItem(item.uid, item.itemid + 1)
	elseif item.itemid == 1946 then
		-- Lever was on: close the passage by removing the teleport
		local existing = getThingfromPos(TELEPORT_POS)
		if existing and existing.uid ~= 0 then
			doRemoveItem(existing.uid, 1)
		end
		doTransformItem(item.uid, item.itemid - 1)
	else
		doPlayerSendCancel(cid, "Sorry not possible.")
	end
	return 1
end
