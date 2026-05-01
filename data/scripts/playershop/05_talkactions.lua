-- ===========================================================================
-- Talkactions:
--   /shop list             - GOD: list all
--   /shop close <name>     - GOD: force close
--
-- Player-facing !fecharloja / !lojas commands were removed -- the seller
-- closes their own shop via the "Cancel Shop" button in the owner-view
-- window, and shop discovery happens visually (skull icon over the
-- seller's head). Chat input is also blocked while a shop is open, so
-- this script only registers the GOD-only /shop admin command now.
-- ===========================================================================

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
                player:sendTextMessage(MESSAGE_STATUS_DEFAULT,
                    ("%s | %d slots | (%d,%d,%d) | %s"):format(
                    seller:getName(), nItems, pos.x, pos.y, pos.z, shop.text or ""))
            end
        end
        if n == 0 then
            player:sendTextMessage(MESSAGE_STATUS_DEFAULT, "No active shops.")
        end
    elseif sub == "close" and args[2] then
        local target = Player(args[2])
        if not target then
            player:sendCancelMessage("Player not online.")
            return false
        end
        if not PlayerShop_IsSelling(target:getId()) then
            player:sendCancelMessage("That player doesn't have a shop open.")
            return false
        end
        PlayerShop_Close(target:getId(), "Shop closed by GOD: " .. player:getName())
        player:sendTextMessage(MESSAGE_STATUS_DEFAULT, "Shop of " .. target:getName() .. " closed.")
    else
        player:sendTextMessage(MESSAGE_STATUS_DEFAULT, "/shop list  |  /shop close <name>")
    end
    return false
end)
shopAdmin:separator(" ")
shopAdmin:register()
