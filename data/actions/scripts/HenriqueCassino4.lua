local positions = {{x = 32354, y = 32229, z = 4}, {x = 32354, y = 32230, z = 4}, {x = 32354, y = 32231, z = 4}} -- Posicao q os items nascem
local price = 1 -- Preco para jogar
local eventcoins = 8426
local items = {8418, 8417, 8353}
local rand = math.random(1, #items)
--local test = items[math.random(1, #items)]

function onUse(cid, item, fromPosition, itemEx, toPosition)
    local first = items[math.random(1, #items)]
    local second = items[math.random(1, #items)]
    local third = items[math.random(1, #items)]
    local tab = {}
    local recheck = 0
        
    if getGlobalStorageValue(722405) > os.time() then
        doPlayerSendCancel(cid, "wait 3 seconds to new bet.")
        return true
    end
    
     if getPlayerItemCount(cid,eventcoins) < price then
        doPlayerSendCancel(cid, "You need " .. price .. " slotmachine coin to play.")
        return true
    end

    if getPlayerStorageValue(cid,722406) > os.time() then
        doPlayerSendCancel(cid,"wait 3 seconds to new bet.")
        return true
    end
    doPlayerSetStorageValue(cid,722406,os.time()+6)
    
    setGlobalStorageValue(722405, os.time() + 6)
    for i = 1, (#positions) do
        doSendMagicEffect(positions[i], 25)
    end
    
    doTransformItem(item.uid, item.itemid == 1945 and 1946 or 1945)
    doPlayerRemoveItem(cid,eventcoins,price)
    doCreateItem(first, 1, positions[1])
    doSendMagicEffect(positions[1], 25)
    addEvent(doSendMagicEffect, 100, positions[1], 25)
    table.insert(tab, first) 
	setGlobalStorageValue(items[first], getGlobalStorageValue(items[first])+1) 
    addEvent(function()
        doCreateItem(second, positions[2])             
		setGlobalStorageValue(items[second], getGlobalStorageValue(items[second])+1) 
        doSendMagicEffect(positions[2], 25)
        addEvent(doSendMagicEffect, 100, positions[2], 25)
        table.insert(tab, second)
    end, 900)
    addEvent(function()
        doCreateItem(third, 1, positions[3])
        doSendMagicEffect(positions[3], 25)
        addEvent(doSendMagicEffect, 100, positions[3], 25)
        setGlobalStorageValue(items[third], getGlobalStorageValue(items[third])+1)
        table.insert(tab, third)
    end, 2000)
    addEvent(function()
        doCleanTile(positions[1])
        doCleanTile(positions[2])
        doCleanTile(positions[3])
            doSendMagicEffect(positions[1], 54)
            doSendMagicEffect(positions[2], 54)
            doSendMagicEffect(positions[3], 54)
        if tab[1] == tab[2] and tab[1] == tab[3] then
            doPlayerAddItem(cid, tab[1])
			doPlayerSendTextMessage(cid, 27, "You Won"..getItemNameById(first)..". Congratulations!" )
            doSendAnimatedText(getThingPos(cid), "You", 25)
            addEvent(doSendAnimatedText, 800, getThingPos(cid), "Wins!!!!", 25)
            doSendMagicEffect(getThingPos(cid), 30)
            doSendMagicEffect(positions[1], 30)
            doSendMagicEffect(positions[2], 30)
            doSendMagicEffect(positions[3], 30)
            addEvent(doSendMagicEffect, 800, getThingPos(cid), 29)
            addEvent(doSendMagicEffect, 800, positions[1], 29)
            addEvent(doSendMagicEffect, 800, positions[2], 29)
            addEvent(doSendMagicEffect, 800, positions[3], 29)
            addEvent(doSendMagicEffect, 1600, getThingPos(cid), 28)
            addEvent(doSendMagicEffect, 1600, positions[1], 28)
            addEvent(doSendMagicEffect, 1600, positions[2], 28)
            addEvent(doSendMagicEffect, 1600, positions[3], 28)
        else
            doSendAnimatedText(getThingPos(cid), "YOU LOSE", 144)
        end
    end, 4200)
    return true
end