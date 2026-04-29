-- ===========================================================================
-- Creature events: lock movement, logout, item-move while shop is active.
-- ===========================================================================

-- ---- onLogin: register all our hooks for every player ----
local login = CreatureEvent("PlayerShopLogin")
login:type("login")
login:onLogin(function(player)
    player:registerEvent("PlayerShopExtOp")
    player:registerEvent("PlayerShopLogout")
    return true
end)
login:register()

-- ---- onLogout: auto-close shop, devolve unsold items pro depot ----
-- Pass `player` como sellerOverride: durante onLogout, Player(id) pode ja
-- retornar nil mid-disconnection. PlayerShop_Close devolve via
-- player:getDepotChest(...):addItem e o save automatico do engine
-- (chamado depois que voltamos da hook Lua) persiste o depot.
local logout = CreatureEvent("PlayerShopLogout")
logout:type("logout")
logout:onLogout(function(player)
    if PlayerShop_IsSelling(player:getId()) then
        PlayerShop_Close(player:getId(), "Loja fechada (logout).", player)
    end
    return true
end)
logout:register()

-- onMoveItem block REMOVED: items in shops live in a virtual stash (pulled
-- from the depot at open-time), NOT in inventory, so the seller can freely
-- move/drop other items without affecting the shop.

-- ---- tick: warp seller back if pushed; close shop if seller leaves PZ ----
local tick = GlobalEvent("PlayerShopTick")
-- "think" is the default; setting type() with "think" errors -- just set interval + onThink.
tick:interval(500)
tick:onThink(function()
    for sellerId, shop in pairs(ActiveShops) do
        local seller = Player(sellerId)
        if seller then
            local cur = seller:getPosition()
            -- Anchor position lives on the shop entry, so it's cleared automatically
            -- when the shop closes (no more leftover lastPos entries).
            if not shop.anchorPos then
                shop.anchorPos = cur
            elseif cur.x ~= shop.anchorPos.x or cur.y ~= shop.anchorPos.y or cur.z ~= shop.anchorPos.z then
                if PlayerShop_TileIsPZ(shop.anchorPos) then
                    seller:teleportTo(shop.anchorPos, false)
                else
                    PlayerShop_Close(sellerId, "Loja fechada (saiu da zona protegida).")
                end
            end
            if seller.resetIdleTime then seller:resetIdleTime() end
        else
            PlayerShop_Close(sellerId, "Vendedor offline.")
        end
    end
    -- expiration
    local now = os.time()
    for sellerId, shop in pairs(ActiveShops) do
        if now - shop.startTime >= PlayerShopConfig.maxShopDuration then
            PlayerShop_Close(sellerId, "Tempo limite da loja atingido (8h).")
        end
    end
    -- Buyer left PZ -> force-close their shop view.
    for buyerId, sellerId in pairs(OpenShopWindows) do
        local buyer = Player(buyerId)
        if not buyer then
            OpenShopWindows[buyerId] = nil
        elseif not PlayerShop_TileIsPZ(buyer:getPosition()) then
            PlayerShop_Reject(buyer, "Voce saiu da zona protegida. Loja fechada.")
            OpenShopWindows[buyerId] = nil
        end
    end
    return true
end)
tick:register()

-- ---- bubble re-broadcast: STATE every 3s ensures any client (incl. ones
-- ----  that just came into spec range) has the seller in sellingCreatures
-- ----  so the bubble widget renders for them too. Cheap server side, the
-- ----  bubble itself is a persistent UIWidget on each client.
local stateTick = GlobalEvent("PlayerShopStateTick")
stateTick:interval(3000)
stateTick:onThink(function()
    for sellerId, shop in pairs(ActiveShops) do
        local seller = Player(sellerId)
        if seller and shop.text and shop.text ~= "" then
            PlayerShop_BroadcastState(seller, true)
        end
    end
    return true
end)
stateTick:register()
