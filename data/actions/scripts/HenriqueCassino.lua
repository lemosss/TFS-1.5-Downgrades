local config = {
    effect = 27, -- efeito em cima do jogador
    effectReward = 28, -- efeito em cima do premio
    effectLever = 2, -- efeito em cima da alavanca
    eventCoin = 8367, -- valor para jogar
    qtdCoin = 1, -- quantidade do coin para jogar.
    lose = false, -- se ira ter a opção de não ganhar nada
    itemLose = 2676, -- id do item que representara a perca (Obs: não se esqueça de adiciona-lo a lista de items)
    effectLose = 29, -- efeito em cima do premio quando perder
    exaust = 2, -- Segundos de exaust
    storage = 23111, -- Storage do exaust
    used = 10, -- Tempo da duração da roleta
    used_storage = 23112, -- Storage pra verificar se a roleta esta sendo usada
    used = 10,
    poss = {
        [1] = {x = 32344, y = 32219, z = 4}, -- Coloque a coordenada da POS1 no Map Editor
        [2] = {x = 32345, y = 32219, z = 4}, -- Coloque a coordenada da POS2 no Map Editor
        [3] = {x = 32346, y = 32219, z = 4}, -- Coloque a coordenada da POS3 no Map Editor
        [4] = {x = 32347, y = 32219, z = 4}, -- Coloque a coordenada da POS4 no Map Editor - local do premio
        [5] = {x = 32348, y = 32219, z = 4}, -- Coloque a coordenada da POS5 no Map Editor
		[6] = {x = 32349, y = 32219, z = 4}, -- Coloque a coordenada da POS6 no Map Editor
		[7] = {x = 32350, y = 32219, z = 4}, -- Coloque a coordenada da POS7 no Map Editor
    },
    items = { -- id = id do item - chance = chance de aparecer o item - count = a quantidade de item que a pessoa ira ganhar
        [1] = {id = 5800, chance = 5, count = 3},
        [2] = {id = 8347, chance = 10, count = 1},
        [3] = {id = 8167, chance = 10, count = 1},
        [4] = {id = 8316, chance = 10, count = 1},
        [5] = {id = 8101, chance = 5, count = 1},
        [6] = {id = 8098, chance = 5, count = 1},
        [7] = {id = 8120, chance = 5, count = 1},
        [8] = {id = 8146, chance = 5, count = 1},
        [9] = {id = 8331, chance = 15, count = 1},
        [10] = {id = 8348, chance = 5, count = 1},
        [11] = {id = 5806, chance = 5, count = 1},
        [12] = {id = 8355, chance = 20, count = 1},
        [13] = {id = 8168, chance = 20, count = 1},
        [14] = {id = 8166, chance = 20, count = 1},
        [15] = {id = 8419, chance = 20, count = 1},
        [16] = {id = 2408, chance = 5, count = 1},
        [17] = {id = 2173, chance = 20, count = 1},
        [18] = {id = 2676, chance = 20, count = 6},
        [19] = {id = 8379, chance = 20, count = 1},
        [20] = {id = 5787, chance = 20, count = 1},
        [21] = {id = 2646, chance = 5, count = 1},
    }
}
 
local slot1, slot2, slot3, slot4, slot5, slot6, slot7
 
local function cleanTile(item, i)
    doCleanTile(config.poss[i], true)
    doCreateItem(item, 1, config.poss[i])
end
 
local function raffle(item)
    if slot6 ~= nil then
        slot7 = slot6
        cleanTile(1617, 7)
        doCreateItem(slot5.id, slot5.count, config.poss[7])
    end
    if slot5 ~= nil then
        slot6 = slot5
        cleanTile(1617, 6)
        doCreateItem(slot5.id, slot5.count, config.poss[6])
    end	
    if slot4 ~= nil then
        slot5 = slot4
        cleanTile(1617, 5)
        doCreateItem(slot5.id, slot5.count, config.poss[5])
    end
    if slot3 ~= nil then
        slot4 = slot3
        cleanTile(1485, 4)
        doCreateItem(slot4.id, slot4.count, config.poss[4])
    end
    if slot2 ~= nil then
        slot3 = slot2
        cleanTile(1617, 3)
        doCreateItem(slot3.id, slot3.count, config.poss[3])
    end
    if slot1 ~= nil then
        slot2 = slot1
        cleanTile(1617, 2)
        doCreateItem(slot2.id, slot2.count, config.poss[2])
    end
    slot1 = {id = item.id, count = item.count}
    cleanTile(1617, 1)
    doCreateItem(slot1.id, slot1.count, config.poss[1])
end
 
local function result(uid)
    if isPlayer(uid) then
        if config.lose and slot4.id == config.itemLose then
            doSendMagicEffect(getCreaturePosition(uid), CONST_ME_POFF)
            doSendMagicEffect(config.poss[4], config.effectLose)
            doPlayerSendTextMessage(uid, MESSAGE_STATUS_CONSOLE_BLUE,
                                    "[ROULETTE] What bad luck, try again!")
        else
            doSendMagicEffect(getCreaturePosition(uid), config.effect)
            doSendMagicEffect(config.poss[4], config.effectReward)
            doPlayerSendTextMessage(uid, MESSAGE_STATUS_CONSOLE_BLUE,
                                    "[ROULETTE] You won " .. slot3.count .. " " .. getItemNameById(slot4.id) .. ". Congratulations!")
            doPlayerAddItem(uid, slot4.id, slot4.count)
        end
    end
end
 
function onUse(cid, item, pos, itemEx, posEx)
    if item.itemid == 1945 then doTransformItem(item.uid, item.itemid + 1) end
    if item.itemid == 1946 then doTransformItem(item.uid, item.itemid - 1) end
 
    if getGlobalStorageValue(config.used_storage) <= os.time() then
        if not exhaustion.check(cid, config.storage) then
            if getPlayerItemCount(cid, config.eventCoin) >= config.qtdCoin then
                local rand = math.random(10, 30)
                doSendMagicEffect(pos, config.effectLever)
                setGlobalStorageValue(config.used_storage, rand + os.time())
                exhaustion.set(cid, config.storage, rand)
                doPlayerRemoveItem(cid, config.eventCoin, config.qtdCoin)
                local loop = 0
                slot1 = nil
                slot2 = nil
                slot3 = nil
                slot4 = nil
                slot5 = nil
				slot6 = nil
				slot7 = nil
 
                for i = 1, #config.poss do
                    if i == 4 then
                        cleanTile(1485, i)
                    else
                        cleanTile(1617, i)
                    end
                end
 
                while rand >= loop do
                    local roll = math.random(1, 100)
                    index = math.random(#config.items)
                    if roll <= config.items[index].chance then
                        local item = config.items[index]
                        loop = loop + 1
                        addEvent(raffle, loop * 500, item)
                    end
                end
                addEvent(result, (rand + 2) * 500, cid)
            else
                doSendMagicEffect(getCreaturePosition(cid), CONST_ME_POFF)
                doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
                                        "[ROULETTE] You must have " .. config.qtdCoin .. " " .. getItemNameById(config.eventCoin) .. " with you in backup to use roulette.")
            end
        else
            doSendMagicEffect(fromPosition, CONST_ME_POFF)
            doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR,
                                    "You can not do it that fast, wait " .. exhaustion.get(cid, config.storage) .. " seconds to use roulette again!")
            return false
        end
        return true
    else
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_POFF)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[ROULETTE] Roulette is still hot! Wait a while to roll it again.")
    end
end