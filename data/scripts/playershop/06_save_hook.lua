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
    local pid = player:getId()
    addEvent(function()
        local p = Player(pid)
        if not p then return end
        for sellerId, _ in pairs(ActiveShops) do
            local seller = Player(sellerId)
            if seller and seller:getId() ~= pid then
                local sellerGuid = seller:getGuid()
                local vips = p:getVipList()
                if vips then
                    for _, v in ipairs(vips) do
                        if v == sellerGuid then
                            local msg = NetworkMessage()
                            msg:addByte(0x32)
                            msg:addByte(PlayerShopOpcode.VIP_STATUS)
                            msg:addU32(sellerGuid)
                            msg:addString(seller:getName())
                            msg:addByte(1)
                            msg:sendToPlayer(p)
                            msg:delete()
                            break
                        end
                    end
                end
            end
        end
    end, 1500)
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
