-- ===========================================================================
-- Server-save hook + VIP login sync.
-- ===========================================================================

local function closeAllShops(reason)
    for sellerId, _ in pairs(ActiveShops) do
        PlayerShop_Close(sellerId, reason or "Server save em andamento. Sua loja foi fechada.")
    end
end

local shutdown = GlobalEvent("PlayerShopShutdown")
shutdown:type("shutdown")
shutdown:onShutdown(function()
    closeAllShops("Server desligando. Loja fechada.")
    return true
end)
shutdown:register()

-- Public helper for the existing serversave script to call.
function PlayerShop_CloseAll(reason)
    if not PlayerShopConfig.closeShopOnSave then return end
    closeAllShops(reason)
end

-- ---- VIP login sync: paint gold for every active seller in this player's VIP ----
local vipLogin = CreatureEvent("PlayerShopVipSync")
vipLogin:type("login")
vipLogin:onLogin(function(player)
    -- Player:getVipList() not exposed in this TFS 1.5 / 8.0 build; skip VIP sync.
    -- (VIP sellers can still get the gold colour live via STATE_BROADCAST when
    -- they enter the seller's screen range -- handled in PlayerShop_NotifyVipWatchers
    -- if/when getVipList becomes available.)
    return true
end)
vipLogin:register()

-- Also wire the VIP sync into the login chain.
local loginPatch = CreatureEvent("PlayerShopVipSyncReg")
loginPatch:type("login")
loginPatch:onLogin(function(player)
    player:registerEvent("PlayerShopVipSync")
    return true
end)
loginPatch:register()
