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
    -- Tambem: se o comprador andou pra mais de 1 SQM do vendedor,
    -- a janela tem que fechar (mesmo limite usado pra abrir). Reject
    -- com texto generico; o cliente fecha automaticamente via onReject.
    for buyerId, sellerId in pairs(OpenShopWindows) do
        local buyer = Player(buyerId)
        if not buyer then
            OpenShopWindows[buyerId] = nil
        elseif not PlayerShop_TileIsPZ(buyer:getPosition()) then
            PlayerShop_Reject(buyer, "Voce saiu da zona protegida. Loja fechada.")
            OpenShopWindows[buyerId] = nil
        else
            local seller = Player(sellerId)
            if not seller then
                OpenShopWindows[buyerId] = nil
            else
                local bp, sp = buyer:getPosition(), seller:getPosition()
                local dist = (bp.z ~= sp.z) and 99
                    or math.max(math.abs(bp.x - sp.x), math.abs(bp.y - sp.y))
                if dist > 1 then
                    PlayerShop_Reject(buyer, "Voce se afastou do vendedor. Loja fechada.")
                    OpenShopWindows[buyerId] = nil
                end
            end
        end
    end
    return true
end)
tick:register()

-- ---- spec-diff broadcast: detecta novos specs em volta do seller
-- (subiram escada, andaram pra perto, logaram) e manda STATE_BROADCAST
-- IMEDIATAMENTE pra cada um. Resultado: o icone aparece quase tao rapido
-- quanto o skull de PK do TFS nativo, sem desperdicar bandwidth com
-- broadcasts redundantes pra quem ja tem a creature em cache.
local LastSeenSpecs = {}  -- [sellerId] = { [specId] = true }

local stateTick = GlobalEvent("PlayerShopStateTick")
stateTick:interval(250)
stateTick:onThink(function()
    for sellerId, shop in pairs(ActiveShops) do
        local seller = Player(sellerId)
        if seller and shop.text and shop.text ~= "" then
            local pos = seller:getPosition()
            local currentSpecs = Game.getSpectators(pos, false, true, 7, 7, 5, 5)
            local current = {}
            for _, p in ipairs(currentSpecs) do
                current[p:getId()] = true
            end
            local previous = LastSeenSpecs[sellerId] or {}

            -- Monta o payload uma vez (mesmo pra todos os novos specs).
            local payload = PlayerShop_PackU32(sellerId)
                         .. PlayerShop_PackU8(1)
                         .. PlayerShop_PackStr(shop.text)

            -- Manda STATE so pros specs que apareceram desde o ultimo tick.
            for specId, _ in pairs(current) do
                if not previous[specId] then
                    local p = Player(specId)
                    if p then
                        PlayerShop_SendOpcode(p, PlayerShopOpcode.STATE_BROADCAST,
                            payload)
                    end
                end
            end

            -- Garantia: re-envia pro proprio seller a cada ~2s pra travar
            -- o iAmSelling/icone caso o cliente dele tenha perdido algum
            -- pacote anterior. Cheap (1 packet/2s/seller).
            shop._reaffirmTicks = (shop._reaffirmTicks or 0) + 1
            if shop._reaffirmTicks >= 8 then  -- 8 * 250ms = 2s
                shop._reaffirmTicks = 0
                PlayerShop_SendOpcode(seller, PlayerShopOpcode.STATE_BROADCAST,
                    payload)
            end

            LastSeenSpecs[sellerId] = current
        end
    end
    -- Limpa entradas de sellers que nao estao mais ativos.
    for sellerId, _ in pairs(LastSeenSpecs) do
        if not ActiveShops[sellerId] then
            LastSeenSpecs[sellerId] = nil
        end
    end
    return true
end)
stateTick:register()
