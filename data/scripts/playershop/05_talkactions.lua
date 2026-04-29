-- ===========================================================================
-- Talkactions:
--   !fecharloja            - seller closes own shop
--   !lojas                 - list active shops
--   /shop list             - GOD: list all
--   /shop close <name>     - GOD: force close
-- ===========================================================================

local fechar = TalkAction("!fecharloja")
fechar:onSay(function(player, words, param)
    if not PlayerShop_IsSelling(player:getId()) then
        player:sendCancelMessage("Voce nao tem loja aberta.")
        return false
    end
    PlayerShop_Close(player:getId(), "Loja fechada manualmente.")
    return false
end)
fechar:separator(" ")
fechar:register()

local lojas = TalkAction("!lojas")
lojas:onSay(function(player, words, param)
    local count = 0
    local lines = {}
    for sellerId, shop in pairs(ActiveShops) do
        local seller = Player(sellerId)
        if seller then
            count = count + 1
            local pos = seller:getPosition()
            local n = 0
            for _ in pairs(shop.items) do n = n + 1 end
            lines[#lines + 1] = ("[%s] %d itens at (%d,%d,%d) - %s"):format(
                seller:getName(), n, pos.x, pos.y, pos.z, shop.text or "")
        end
    end
    if count == 0 then
        player:sendTextMessage(MESSAGE_INFO_DESCR, "Nenhuma loja ativa no momento.")
    else
        player:sendTextMessage(MESSAGE_INFO_DESCR,
            ("Lojas ativas (%d):\n%s"):format(count, table.concat(lines, "\n")))
    end
    return false
end)
lojas:separator(" ")
lojas:register()

-- /shop ...
local shopAdmin = TalkAction("/shop")
shopAdmin:onSay(function(player, words, param)
    if player:getAccountType() < ACCOUNT_TYPE_GOD then
        return false
    end
    local args = {}
    for w in (param or ""):gmatch("%S+") do args[#args + 1] = w end
    local sub = args[1]
    if sub == "list" then
        local n = 0
        for sellerId, shop in pairs(ActiveShops) do
            local seller = Player(sellerId)
            if seller then
                n = n + 1
                local pos = seller:getPosition()
                local nItems = 0
                for _ in pairs(shop.items) do nItems = nItems + 1 end
                player:sendTextMessage(MESSAGE_INFO_DESCR,
                    ("%s | %d slots | (%d,%d,%d) | %s"):format(
                    seller:getName(), nItems, pos.x, pos.y, pos.z, shop.text or ""))
            end
        end
        if n == 0 then
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Sem lojas ativas.")
        end
    elseif sub == "close" and args[2] then
        local target = Player(args[2])
        if not target then
            player:sendCancelMessage("Player nao online.")
            return false
        end
        if not PlayerShop_IsSelling(target:getId()) then
            player:sendCancelMessage("Esse player nao tem loja aberta.")
            return false
        end
        PlayerShop_Close(target:getId(), "Loja fechada por GOD: " .. player:getName())
        player:sendTextMessage(MESSAGE_INFO_DESCR, "Loja de " .. target:getName() .. " fechada.")
    else
        player:sendTextMessage(MESSAGE_INFO_DESCR, "/shop list  |  /shop close <name>")
    end
    return false
end)
shopAdmin:separator(" ")
shopAdmin:register()
