local cfg = {
	--[action id]
	[10600] = {
		storage = 50001, -- storage do baú
		success_message = {"You received %s.", MESSAGE_EVENT_ADVANCE}, -- mensagem ao pegar premio
		fail_message = {"Its empty.", MESSAGE_EVENT_ADVANCE}, -- mensagem caso já ter pego o premio
		items = {
			-- items ganhos
			{id = 5805, count = 1}
		}
	},
}

do
	for _, t in pairs(cfg) do
		local str = ""
		for i = 1, #t.items do
			local reward = t.items[i]
			local itemInfo = getItemInfo(reward.id)
			str = str .. reward.count .. " " .. (itemInfo and (reward.count > 1 and itemInfo.plural or itemInfo.name) or "UNK_ITEM") .. ", "
		end

		t.items_description = (str:sub(1, #str - 2):gsub("(.+), ", "%1 e ", 1))
	end
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
	local t = cfg[item.actionid]
	if (not t) then
		return false
	end

	local storageValue = tonumber(getCreatureStorage(cid, t.storage)) or -1
	if (storageValue > 0) then
		doPlayerSendTextMessage(cid, t.fail_message[2], t.fail_message[1])
		return true
	end

	doCreatureSetStorage(cid, t.storage, 1)

	for i = 1, #t.items do
		local reward = t.items[i]
		doPlayerAddItem(cid, reward.id, reward.count, true)
	end

	doPlayerSendTextMessage(cid, t.success_message[2], t.success_message[1]:format(t.items_description))
	doSendMagicEffect(getThingPosition(cid), CONST_ME_MAGIC_BLUE)
	return true
end
