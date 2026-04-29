-- ===========================================================================
-- Player Shop core logic: open / close / buy.
-- All transactions are synchronous (no addEvent / yield).
-- ===========================================================================

-- Sanitize the shop text (no control chars, max length).
local function sanitizeText(text)
    if type(text) ~= 'string' then return "" end
    text = text:gsub("[%c]", "")
    if #text > PlayerShopConfig.maxShopTextLength then
        text = text:sub(1, PlayerShopConfig.maxShopTextLength)
    end
    return text
end

-- Validate that a player is in PZ, no battle, no skull, no other shop, not in trade.
local function canOpenShop(player)
    if not player then return false, "Player invalido." end
    if PlayerShop_IsSelling(player:getId()) then
        return false, "Voce ja tem uma loja aberta."
    end
    if not PlayerShop_TileIsPZ(player:getPosition()) then
        return false, "Voce precisa estar em zona protegida."
    end
    if player:getCondition(CONDITION_INFIGHT) then
        return false, "Voce esta em battle. Saia do combate primeiro."
    end
    local skull = player:getSkull()
    if skull == SKULL_RED or skull == SKULL_BLACK then
        return false, "Skull red/black nao pode abrir loja."
    end
    -- (getTradeState() not available in this TFS build; trade lock skipped)
    return true
end

-- Check if a slot definition (from client) matches a real item the seller owns.
-- Returns the matched Item* or nil.
-- Iterate all of the player's depot chests (towns 1..10). Returns each
-- top-level depot Container; caller walks contents.
local function eachDepot(player, fn)
    for depotId = 1, 10 do
        local d = player:getDepotChest(depotId, false)  -- false = don't auto-create
        if d then fn(d) end
    end
end

-- Recursive depth-first search across ALL depots for the first matching itemId.
local function findItemInDepot(player, itemUid, itemId)
    if itemUid and itemUid ~= 0 then
        local it = Item(itemUid)
        if it and it:getHolder() and it:getHolder():getId() == player:getId() then
            return it
        end
    end
    local function search(it)
        if not it then return nil end
        if it:getId() == itemId then return it end
        local container = it.getContainer and it:getContainer()
        if container then
            for i = 0, container:getSize() - 1 do
                local found = search(container:getItem(i))
                if found then return found end
            end
        end
        return nil
    end
    local out = nil
    eachDepot(player, function(depot)
        if out then return end
        for i = 0, depot:getSize() - 1 do
            local found = search(depot:getItem(i))
            if found then out = found; return end
        end
    end)
    return out
end

-- ---------------------------------------------------------------------------
-- Open shop (called from opcode handler after payload deserialized).
-- payload.items[i] = { itemUid, itemId, count, price }
-- payload.text     = string
-- ---------------------------------------------------------------------------
function PlayerShop_Open(player, payload)
    if PlayerShop_IsSelling(player:getId()) then
        PlayerShop_Reject(player, "Voce ja tem uma loja aberta.")
        return false
    end
    local ok, why = canOpenShop(player)
    if not ok then
        PlayerShop_Reject(player, why)
        return false
    end

    local items = {}
    local seenIds = {}
    for slot, entry in ipairs(payload.items or {}) do
        if slot > PlayerShopConfig.maxItemsPerShop then break end
        local price = tonumber(entry.price) or 0
        local count = tonumber(entry.count) or 1
        local itemId = tonumber(entry.itemId) or 0
        local itemUid = tonumber(entry.itemUid) or 0
        if price < PlayerShopConfig.minItemPrice or price > PlayerShopConfig.maxItemPrice then
            PlayerShop_Reject(player, ("Preco invalido no slot %d."):format(slot))
            return false
        end
        if count <= 0 then
            PlayerShop_Reject(player, ("Quantidade invalida no slot %d."):format(slot))
            return false
        end
        local realItem = findItemInDepot(player, itemUid, itemId)
        if not realItem then
            PlayerShop_Reject(player,
                ("Voce nao possui o item do slot %d no depot."):format(slot))
            return false
        end
        local realCount = realItem:getCount()
        if count > realCount then
            count = realCount
        end
        items[slot] = {
            itemUid = realItem:getUniqueId(),
            itemId  = realItem:getId(),
            count   = count,
            price   = price,
            charges = realItem:getCharges() or 0,
            actionId = realItem:getActionId() or 0,
        }
    end

    if #items == 0 then
        PlayerShop_Reject(player, "Loja vazia. Adicione pelo menos um item.")
        return false
    end

    -- Cross-slot stock check across the DEPOT only.
    local advertisedById = {}
    for _, e in pairs(items) do
        advertisedById[e.itemId] = (advertisedById[e.itemId] or 0) + e.count
    end
    for itemId, totalNeeded in pairs(advertisedById) do
        local have = 0
        local function visit(it)
            if not it then return end
            if it:getId() == itemId then have = have + (it:getCount() or 1) end
            local container = it.getContainer and it:getContainer()
            if container then
                for i = 0, container:getSize() - 1 do
                    visit(container:getItem(i))
                end
            end
        end
        eachDepot(player, function(depot)
            for i = 0, depot:getSize() - 1 do visit(depot:getItem(i)) end
        end)
        if totalNeeded > have then
            local nm = ItemType(itemId):getName() or ('id ' .. itemId)
            PlayerShop_Reject(player,
                ("Voce nao tem %d %s no depot (so tem %d)."):format(totalNeeded, nm, have))
            return false
        end
    end

    local cleanText = sanitizeText(payload.text)
    if cleanText:gsub("%s+", "") == "" then
        PlayerShop_Reject(player, "Voce precisa colocar um titulo na loja.")
        return false
    end

    -- Physically take the items OUT of the depot. Each shop entry's `count`
    -- is the virtual stock now; on close, unsold counts are recreated in the
    -- depot via player:getDepotChest(...):addItem.
    -- We use removeItem(itemId, count, -1) over the whole player so it walks
    -- depot too (subType -1 = any). Since at this point the items are in
    -- depots (not inventory), this should pull from there.
    -- Fallback: if removeItem doesn't reach depot (build-specific), iterate
    -- depots manually.
    local function removeFromDepots(itemId, qty)
        local left = qty
        eachDepot(player, function(depot)
            if left <= 0 then return end
            local function strip(container)
                if left <= 0 then return end
                for i = container:getSize() - 1, 0, -1 do
                    if left <= 0 then return end
                    local it = container:getItem(i)
                    if it then
                        if it:getId() == itemId then
                            local c = it:getCount() or 1
                            if c <= left then
                                it:remove()
                                left = left - c
                            else
                                it:setCount(c - left)
                                left = 0
                            end
                        else
                            local sub = it.getContainer and it:getContainer()
                            if sub then strip(sub) end
                        end
                    end
                end
            end
            strip(depot)
        end)
        return left == 0
    end
    for _, e in pairs(items) do
        if not removeFromDepots(e.itemId, e.count) then
            PlayerShop_Reject(player,
                "Falha ao retirar itens do depot. Loja cancelada.")
            return false
        end
    end

    ActiveShops[player:getId()] = {
        items     = items,
        text      = cleanText,
        startTime = os.time(),
        sellerName = player:getName(),
    }
    player:setStorageValue(PlayerShopConfig.storageKey, 1)
    player:sendTextMessage(MESSAGE_INFO_DESCR, "Loja aberta. Voce nao pode se mover ate fechar.")

    -- Broadcast to nearby clients (bubble+icon).
    PlayerShop_BroadcastState(player, true)
    -- Notify VIP watchers.
    PlayerShop_NotifyVipWatchers(player, true)
    return true
end

-- ---------------------------------------------------------------------------
-- Close shop (manually, on logout, on save, on stock empty, on timeout, etc.)
-- reason: short string for the seller's MSG.
-- ---------------------------------------------------------------------------
function PlayerShop_Close(playerId, reason)
    local shop = ActiveShops[playerId]
    if not shop then return end
    ActiveShops[playerId] = nil

    local seller = Player(playerId)
    if seller then
        -- Return any unsold stash items back to the seller's depot.
        -- Use depotId 1 (Thais) as the default home depot.
        local depot = seller:getDepotChest(1, true)
        if depot then
            for _, e in pairs(shop.items or {}) do
                if e.count and e.count > 0 then
                    -- Game.createItem handles stackable count automatically.
                    local newItem = Game.createItem(e.itemId, e.count)
                    if newItem then
                        if e.charges and e.charges > 0 then
                            newItem:setSubType(e.charges)
                        end
                        if e.actionId and e.actionId > 0 then
                            newItem:setActionId(e.actionId)
                        end
                        depot:addItem(newItem)
                    end
                end
            end
        end
        seller:setStorageValue(PlayerShopConfig.storageKey, -1)
        seller:sendTextMessage(MESSAGE_INFO_DESCR, reason or "Loja fechada.")
        PlayerShop_BroadcastState(seller, false)
        PlayerShop_NotifyVipWatchers(seller, false)
    end

    -- Force-close every buyer that was looking at this shop.
    for buyerId, sellerId in pairs(OpenShopWindows) do
        if sellerId == playerId then
            local buyer = Player(buyerId)
            if buyer then
                buyer:sendTextMessage(MESSAGE_STATUS_WARNING, "Esta loja nao esta mais disponivel.")
                PlayerShop_SendOpcode(buyer, PlayerShopOpcode.STATE_BROADCAST,
                    PlayerShop_PackU32(playerId) .. PlayerShop_PackU8(0))
            end
            OpenShopWindows[buyerId] = nil
        end
    end
end

-- ---------------------------------------------------------------------------
-- Broadcast STATE to nearby clients (bubble+icon visible to neighbors).
-- ---------------------------------------------------------------------------
function PlayerShop_BroadcastState(seller, isOpen)
    local pos = seller:getPosition()
    local spec = Game.getSpectators(pos, false, true, 7, 7, 5, 5)  -- only players
    local payload = PlayerShop_PackU32(seller:getId()) .. PlayerShop_PackU8(isOpen and 1 or 0)
    if isOpen then
        local shop = ActiveShops[seller:getId()]
        payload = payload .. PlayerShop_PackStr(shop and shop.text or "")
    end
    -- Always send to the seller themselves so their client locks chat/walk.
    PlayerShop_SendOpcode(seller, PlayerShopOpcode.STATE_BROADCAST, payload)
    for _, p in ipairs(spec) do
        if p:getId() ~= seller:getId() then
            PlayerShop_SendOpcode(p, PlayerShopOpcode.STATE_BROADCAST, payload)
        end
    end
end

-- ---------------------------------------------------------------------------
-- VIP watchers: every player who has this seller on VIP gets an opcode update.
-- ---------------------------------------------------------------------------
function PlayerShop_NotifyVipWatchers(seller, isOpen)
    -- Player:getVipList() not available in this TFS 1.5 / 8.0 build.
    -- Falling back to the per-screen STATE_BROADCAST (already fired in
    -- PlayerShop_BroadcastState) so anyone NEAR the seller still gets
    -- bubble + icon. VIP sync from any distance is gated until
    -- getVipList is available or we read directly from the DB.
end

-- ---------------------------------------------------------------------------
-- Send full shop data to a buyer (after they REQUEST).
-- ---------------------------------------------------------------------------
function PlayerShop_SendShopDataTo(buyer, sellerId)
    -- Buyer must be inside a protection zone to OPEN a shop window.
    if not PlayerShop_TileIsPZ(buyer:getPosition()) then
        PlayerShop_Reject(buyer, "Voce precisa estar em zona protegida para ver lojas.")
        return false
    end
    local shop = ActiveShops[sellerId]
    if not shop then
        PlayerShop_Reject(buyer, "Esta loja nao esta mais ativa.")
        return false
    end
    local seller = Player(sellerId)
    if not seller then
        PlayerShop_Close(sellerId, "Seller offline.")
        PlayerShop_Reject(buyer, "Vendedor offline.")
        return false
    end

    OpenShopWindows[buyer:getId()] = sellerId

    local payload = PlayerShop_PackU32(sellerId)
                 .. PlayerShop_PackStr(seller:getName())
                 .. PlayerShop_PackStr(shop.text or "")
    local n = 0
    for _ in pairs(shop.items) do n = n + 1 end
    payload = payload .. PlayerShop_PackU8(n)
    for slot, entry in pairs(shop.items) do
        local it = ItemType(entry.itemId)
        payload = payload
               .. PlayerShop_PackU8(slot)
               .. PlayerShop_PackU16(entry.itemId)
               .. PlayerShop_PackU16(entry.count)
               .. PlayerShop_PackU32(entry.price)
               .. PlayerShop_PackU16(entry.charges or 0)
               .. PlayerShop_PackStr(it:getName() or "item")
    end
    PlayerShop_SendOpcode(buyer, PlayerShopOpcode.DATA, payload)
    return true
end

-- ---------------------------------------------------------------------------
-- Buy: synchronous transaction with rollback.
-- ---------------------------------------------------------------------------
function PlayerShop_Buy(buyer, sellerId, slot, qty)
    local shop = ActiveShops[sellerId]
    if not shop then
        PlayerShop_Reject(buyer, "Loja nao esta mais ativa.")
        return false
    end
    if not PlayerShop_TileIsPZ(buyer:getPosition()) then
        PlayerShop_Reject(buyer, "Voce precisa estar em zona protegida pra comprar.")
        return false
    end
    if buyer:getCondition(CONDITION_INFIGHT) then
        PlayerShop_Reject(buyer, "Voce esta em battle.")
        return false
    end
    local entry = shop.items[slot]
    if not entry then
        PlayerShop_Reject(buyer, "Item ja foi vendido ou slot invalido.")
        return false
    end
    qty = tonumber(qty) or 0
    if qty <= 0 or qty > entry.count then
        PlayerShop_Reject(buyer, "Quantidade invalida.")
        return false
    end

    local seller = Player(sellerId)
    if not seller then
        PlayerShop_Close(sellerId, "Seller offline.")
        PlayerShop_Reject(buyer, "Vendedor offline.")
        return false
    end

    local total = entry.price * qty
    local bpMoney = buyer:getMoney()
    local bankMoney = buyer:getBankBalance() or 0
    if bpMoney + bankMoney < total then
        PlayerShop_Reject(buyer, ("Dinheiro insuficiente. Precisa de %d gold."):format(total))
        return false
    end

    -- ----- DEBIT BUYER -----
    local fromBp = math.min(bpMoney, total)
    local fromBank = total - fromBp
    if fromBp > 0 then
        if not buyer:removeMoney(fromBp) then
            PlayerShop_Reject(buyer, "Falha ao debitar gold da bp.")
            return false
        end
    end
    if fromBank > 0 then
        local newBank = (buyer:getBankBalance() or 0) - fromBank
        if newBank < 0 then
            buyer:addMoney(fromBp)
            PlayerShop_Reject(buyer, "Falha no banco.")
            return false
        end
        buyer:setBankBalance(newBank)
    end

    -- ----- TRANSFER ITEM (from virtual stash, NOT seller's inventory) -----
    -- Items were taken out of the depot at PlayerShop_Open time and now live
    -- only in the shop entry's `count`. We just create a fresh item for the
    -- buyer with the same id/charges and decrement entry.count.
    local itType = ItemType(entry.itemId)
    local newItem
    if itType:isStackable() then
        newItem = buyer:addItem(entry.itemId, qty)
    else
        if qty ~= 1 then
            PlayerShop_Reject(buyer, "Item nao-stackable so pode ser comprado em qty=1.")
            buyer:addMoney(fromBp)
            buyer:setBankBalance((buyer:getBankBalance() or 0) + fromBank)
            return false
        end
        -- preserve charges on non-stackables (UH/GFB charges live in subType)
        local sub = entry.charges and entry.charges > 0 and entry.charges or 1
        newItem = buyer:addItem(entry.itemId, sub)
    end

    if not newItem then
        -- ROLLBACK (addItem failed -> cap full)
        buyer:addMoney(fromBp)
        buyer:setBankBalance((buyer:getBankBalance() or 0) + fromBank)
        PlayerShop_Reject(buyer, "Sua bag esta cheia. Compra cancelada.")
        return false
    end

    -- ----- CREDIT SELLER (bank) -----
    seller:setBankBalance((seller:getBankBalance() or 0) + total)

    -- ----- UPDATE STOCK -----
    entry.count = entry.count - qty
    if entry.count <= 0 then
        shop.items[slot] = nil
    end

    -- Notifications
    local itemName = itType:getName() or "item"
    buyer:sendTextMessage(MESSAGE_INFO_DESCR,
        ("Comprou %dx %s por %d gold (bp: %d, banco: %d)."):format(qty, itemName, total, fromBp, fromBank))
    seller:sendTextMessage(MESSAGE_INFO_DESCR,
        ("%s comprou %dx %s por %d gold (creditado no banco)."):format(buyer:getName(), qty, itemName, total))

    -- If shop now empty, auto-close.
    local remaining = 0
    for _ in pairs(shop.items) do remaining = remaining + 1 end
    if remaining == 0 then
        PlayerShop_Close(sellerId, "Todos os itens foram vendidos! Loja fechada.")
    else
        -- Refresh buyer's window.
        PlayerShop_SendShopDataTo(buyer, sellerId)
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Send inventory snapshot to player for the create-shop window.
-- ---------------------------------------------------------------------------
function PlayerShop_SendInventoryList(player)
    local items = {}
    local function visit(it)
        if not it then return end
        local id = it:getId()
        if id ~= 2148 and id ~= 2152 and id ~= 2160 and id ~= 1987 and not ItemType(id):isContainer() then
            -- skip coins and the empty bag itself; skip nested containers from listing themselves
            items[#items + 1] = {
                uid = it:getUniqueId(),
                id = id,
                count = it:getCount(),
                charges = it:getCharges() or 0,
                name = ItemType(id):getName() or "item",
            }
        end
        local container = it.getContainer and it:getContainer()
        if container then
            for i = 0, container:getSize() - 1 do
                visit(container:getItem(i))
            end
        end
    end

    -- inventory slots 1..10 (head, neck, backpack, body, right, left, legs, feet, ring, ammo)
    for slot = 1, 10 do
        visit(player:getSlotItem(slot))
    end

    local payload = PlayerShop_PackU16(#items)
    for _, e in ipairs(items) do
        payload = payload
               .. PlayerShop_PackU32(e.uid)
               .. PlayerShop_PackU16(e.id)
               .. PlayerShop_PackU16(e.count)
               .. PlayerShop_PackU16(e.charges)
               .. PlayerShop_PackStr(e.name)
    end
    PlayerShop_SendOpcode(player, PlayerShopOpcode.INVENTORY_LIST, payload)
end
