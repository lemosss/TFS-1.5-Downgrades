local KIT_GREEN = 8185
local KIT_RED = 8186
local KIT_YELLOW = 8193
local KIT_REMOVAL = 8324

local BEDS = {
	[KIT_GREEN] =	{{8212, 8213}, {8214, 8215}},
	[KIT_RED] =	{{8238, 8239}, {8240, 8241}},
	[KIT_YELLOW] =	{{8261, 8262}, {8263, 8264}},
	[KIT_REMOVAL] =	{{1754, 1755}, {1760, 1761}}
}

local function internalBedTransform(item, itemEx, toPosition, id1, id2)
	doTransformItem(itemEx.uid, id1)
	doTransformItem(getThingfromPos(toPosition).uid, id2)
	doRemoveItem(item.uid)

	doSendMagicEffect(getThingPos(itemEx.uid), CONST_ME_POFF)
	doSendMagicEffect(toPosition, CONST_ME_POFF)
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
	local newBed = BEDS[item.itemid]
	if not newBed or getTileHouseInfo(getCreaturePosition(cid)) == FALSE then
		return FALSE
	end

	if isInArray({newBed[1][1], newBed[2][1]}, itemEx.itemid) == TRUE then
		doPlayerSendCancel(cid, "You already have this bed modification.")
		return TRUE
	end

	for kit, bed in pairs(BEDS) do
		if bed[1][1] == itemEx.itemid then
			toPosition.y = toPosition.y + 1
			internalBedTransform(item, itemEx, toPosition, newBed[1][1], newBed[1][2])
			break
		elseif bed[2][1] == itemEx.itemid then
			toPosition.x = toPosition.x + 1
			internalBedTransform(item, itemEx, toPosition, newBed[2][1], newBed[2][2])
			break
		end
	end

	return TRUE
end