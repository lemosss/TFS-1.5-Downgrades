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

-- ---- onLogout: refuse if selling ----
local logout = CreatureEvent("PlayerShopLogout")
logout:type("logout")
logout:onLogout(function(player)
    if PlayerShop_IsSelling(player:getId()) then
        player:sendCancelMessage("Voce nao pode deslogar com a loja aberta. Feche-a primeiro (use !fecharloja).")
        return false
    end
    return true
end)
logout:register()

-- ---- onMoveItem: prevent moving items that are in a shop slot ----
-- Use EventCallback (chained, multi-listener safe).
local ec = EventCallback
ec.onMoveItem = function(self, item, count, fromPos, toPos, fromCylinder, toCylinder)
    if not self then return true end
    local shop = ActiveShops[self:getId()]
    if not shop then return true end
    local uid = item:getUniqueId()
    for _, e in pairs(shop.items) do
        if e.itemUid == uid then
            self:sendCancelMessage("Este item esta em sua loja. Feche a loja para movimenta-lo.")
            return false
        end
    end
    return true
end
ec:register()

-- ---- tick: warp seller back if pushed; close shop if seller leaves PZ ----
local lastPos = {}

local tick = GlobalEvent("PlayerShopTick")
-- "think" is the default; setting type() with "think" errors -- just set interval + onThink.
tick:interval(500)
tick:onThink(function()
    for sellerId, shop in pairs(ActiveShops) do
        local seller = Player(sellerId)
        if seller then
            local cur = seller:getPosition()
            local saved = lastPos[sellerId]
            if not saved then
                lastPos[sellerId] = cur
            elseif cur.x ~= saved.x or cur.y ~= saved.y or cur.z ~= saved.z then
                if PlayerShop_TileIsPZ(saved) then
                    seller:teleportTo(saved, false)
                else
                    PlayerShop_Close(sellerId, "Loja fechada (saiu da zona protegida).")
                    lastPos[sellerId] = nil
                end
            end
            if seller.resetIdleTime then seller:resetIdleTime() end
        else
            PlayerShop_Close(sellerId, "Vendedor offline.")
            lastPos[sellerId] = nil
        end
    end
    -- expiration
    local now = os.time()
    for sellerId, shop in pairs(ActiveShops) do
        if now - shop.startTime >= PlayerShopConfig.maxShopDuration then
            PlayerShop_Close(sellerId, "Tempo limite da loja atingido (8h).")
            lastPos[sellerId] = nil
        end
    end
    return true
end)
tick:register()
