local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
-- OTServ event handling functions end

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)
shopModule:addSellableItem({'abaddon coin'},8425, 1000,'abaddon coin')
shopModule:addSellableItem({'abaddon armor'},8102, 5000,'abaddon armor')
shopModule:addSellableItem({'abaddon legs'},8103, 5000,'abaddon legs')
shopModule:addSellableItem({'abaddon shield'},8104, 5000,'abaddon shield')
shopModule:addSellableItem({'abaddon helmet'},8105, 5000,'abaddon helmet')
shopModule:addSellableItem({'abaddon boots'},8106, 5000,'abaddon boots')
shopModule:addBuyableItem({'abaddon token'},7234, 3000,'abaddon token')

-- OTServ event handling functions start
function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid)             npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg)     npcHandler:onCreatureSay(cid, type, msg)

	if not npcHandler:isFocused(cid) then
		return false
	end
	
	if msgcontains(msg, 'heal') then
		if hasCondition(cid, CONDITION_FIRE) == TRUE then
			npcHandler:say('You are burning. I will help you.')
			doRemoveCondition(cid, CONDITION_FIRE)
			doSendMagicEffect(getCreaturePosition(cid), 14)
		elseif hasCondition(cid, CONDITION_POISON) == TRUE then
			npcHandler:say('You are poisoned. I will help you.')
			doRemoveCondition(cid, CONDITION_POISON)
			doSendMagicEffect(getCreaturePosition(cid), 13)
		elseif getCreatureHealth(cid) < 65 then
			npcHandler:say('You are looking really bad. Let me heal your wounds.')
			doCreatureAddHealth(cid, 65 - getCreatureHealth(cid))
			doSendMagicEffect(getCreaturePosition(cid), 12)
		else
			npcHandler:say('You aren\'t looking really bad. Eat some food to regain strength.')
		end
		return TRUE
	end
end
function onThink()                         npcHandler:onThink() end
-- OTServ event handling functions end
npcHandler:addModule(FocusModule:new())
