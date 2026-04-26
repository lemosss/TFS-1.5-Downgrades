local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local typeBag = {}
local typeCount = {}

-- OTServ event handling functions start
function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) 			npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) 	npcHandler:onCreatureSay(cid, type, msg) end
function onThink() 						npcHandler:onThink() end
-- OTServ event handling functions end

local config = {
	-- vials need explicit description
	[1] = {
		keywords = {"bp of lf", "bp of life fluid", "bp lf"}, 
		costBackpack = 1200, 
		item = 2006, 
		subType = 10, -- amount/subType
		container = 2000, 
		description = "life fluid",  
		state = 1
	},
	[2] = {
		keywords = {"bp br", "bp of blank rune", "bp blankrune", "bp of br"}, 
		costBackpack = 200, 
		item = 2260, 
		subType = 1, -- amount/subType
		container = 2003, 
		state = 2
	},
	[3] = {
		keywords = {"bp of mf", "bp of manafluid", "bp mf"}, 
		costBackpack = 1200, 
		item = 2006, 
		subType = 7, -- amount/subType
		container = 2001, 
		description = "mana fluid",  
		state = 3
	}
}

function greetCallback(talkUser)
    if typeBag[talkUser] ~= nil then
    	typeBag[talkUser] = nil
    end
    if typeCount[talkUser] ~= nil then
    	typeCount[talkUser] = nil
    end
    return true
end

function creatureSayCallback(cid, _type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
	for k, v in pairs(config) do
		for i = 1, #v.keywords do
			if msgcontains(msg, v.keywords[i]) then
				-- in case player is being exchanging backpack types
				if typeCount[talkUser] then
					typeCount[talkUser] = nil
				end

				local countBp = 0
				local n = msg:gsub("%D", "")
				if (n ~= "") then
					local n = tonumber(n)
					countBp = math.abs(n)
					if (countBp > 0) then
						typeCount[talkUser] = countBp
					end
				end

				npcHandler:say('Do you want to buy '..(countBp > 1 and countBp or "a")..' backpack of '..(v.description or getItemNameById(v.item))..' for '..(v.costBackpack * (countBp > 1 and countBp or 1))..' gold coins?')
				typeBag[talkUser] = k
			end
		end
	end

	if (msgcontains(msg, "yes") and (typeBag[talkUser])) then
		local v = config[typeBag[talkUser]]
		local plural = typeCount[talkUser] or 1
		if doPlayerRemoveMoney(cid, (v.costBackpack * plural)) then
		npcHandler:say('Here are you.')
			for j = 1, plural do
				local bag = doCreateItemEx(v.container, 1)
				for i = 1, getContainerCap(bag) do
					doAddContainerItemEx(bag, doCreateItemEx(v.item, v.subType))
				end
				doPlayerAddItemEx(cid, bag, true)
			end
		else
			npcHandler:say('You dont have enough money.')
		end
	end		
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())