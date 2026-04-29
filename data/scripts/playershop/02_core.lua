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
    if player:getTradeState() ~= 0 then  -- 0 = TRADE_NONE
        return false, "Voce esta em trade. Cancele primeiro."
    end
    return true
end

-- Check if a slot definition (from client) matches a real item the seller owns.
-- Returns the matched Item* or nil.
local function findItemInInventory(player, itemUid, itemId)
    if itemUid and itemUid ~= 0 then
        local it = Item(itemUid)
        if it and it:getHolder() and it:getHolder():getId() == player:getId() then
            return it
        end
    end
    -- fallback: walk inventory looking for first matching id (for stackables)
    for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
        local inv = player:getSlotItem(slot)
        if inv then
            if inv:getId() == itemId then return inv end
            if ItemType(inv:getId()):isContainer() then
                for _, sub in ipairs(inv:getItems()) do
                    if sub:getId() == itemId then return sub end
                end
            end
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Open shop (called from opcode handler after payload deserialized).
-- payload.items[i] = { itemUid, itemId, count, price }
-- payload.text     = string
-- ---------------------------------------------------------------------------
function PlayerShop_Open(player, payload)
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
        local realItem = findItemInInventory(player, itemUid, itemId)
        if not realItem then
            PlayerShop_Reject(player, ("Voce nao possui o item do slot %d."):format(slot))
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
        seenIds[#seenIds + 1] = realItem:getId()
    end

    if #items == 0 then
        PlayerShop_Reject(player, "Loja vazia. Adicione pelo menos um item.")
        return false
    end

    ActiveShops[player:getId()] = {
        items     = items,
        text      = sanitizeText(payload.text),
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
                buyer:sendTextMessage(MESSAGE_INFO_DESCR, "Esta loja nao esta mais disponivel.")
                local msg = NetworkMessage()
                msg:addByte(0x32)
                msg:addByte(PlayerShopOpcode.STATE_BROADCAST)
                msg:addU32(playerId)
                msg:addByte(0)  -- 0 = closed
                msg:sendToPlayer(buyer)
                msg:delete()
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
    local msg = NetworkMessage()
    msg:addByte(0x32)
    msg:addByte(PlayerShopOpcode.STATE_BROADCAST)
    msg:addU32(seller:getId())
    msg:addByte(isOpen and 1 or 0)
    if isOpen then
        local shop = ActiveShops[seller:getId()]
        msg:addString(shop and shop.text or "")
    end
    for _, p in ipairs(spec) do
        msg:sendToPlayer(p)
    end
    msg:delete()
end

-- ---------------------------------------------------------------------------
-- VIP watchers: every player who has this seller on VIP gets an opcode update.
-- ---------------------------------------------------------------------------
function PlayerShop_NotifyVipWatchers(seller, isOpen)
    local sellerGuid = seller:getGuid()
    -- Walk all online players, check each one's VIP list (TFS Player:getVipList)
    local sellerName = seller:getName()
    for _, p in ipairs(Game.getPlayers()) do
        if p:getId() ~= seller:getId() then
            local vips = p:getVipList()
            if vips then
                for _, entry in ipairs(vips) do
                    if entry == sellerGuid then
                        local msg = NetworkMessage()
                        msg:addByte(0x32)
                        msg:addByte(PlayerShopOpcode.VIP_STATUS)
                        msg:addU32(sellerGuid)
                        msg:addString(sellerName)
                        msg:addByte(isOpen and 1 or 0)
                        msg:sendToPlayer(p)
                        msg:delete()
                        break
                    end
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Send full shop data to a buyer (after they REQUEST).
-- ---------------------------------------------------------------------------
function PlayerShop_SendShopDataTo(buyer, sellerId)
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

    local msg = NetworkMessage()
    msg:addByte(0x32)
    msg:addByte(PlayerShopOpcode.DATA)
    msg:addU32(sellerId)
    msg:addString(seller:getName())
    msg:addString(shop.text or "")
    -- count of items in shop
    local n = 0
    for _ in pairs(shop.items) do n = n + 1 end
    msg:addByte(n)
    for slot, entry in pairs(shop.items) do
        msg:addByte(slot)
        msg:addU16(entry.itemId)
        msg:addU16(entry.count)
        msg:addU32(entry.price)
        msg:addU16(entry.charges or 0)
        local it = ItemType(entry.itemId)
        msg:addString(it:getName() or "item")
    end
    msg:sendToPlayer(buyer)
    msg:delete()
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

    -- Find the actual item on the seller (uid first, else by id).
    local realItem = findItemInInventory(seller, entry.itemUid, entry.itemId)
    if not realItem then
        PlayerShop_Reject(buyer, "Estoque invalido (vendedor sem o item).")
        shop.items[slot] = nil  -- prune
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
            -- rollback bp
            buyer:addMoney(fromBp)
            PlayerShop_Reject(buyer, "Falha no banco.")
            return false
        end
        buyer:setBankBalance(newBank)
    end

    -- ----- TRANSFER ITEM -----
    -- Stackable: split if needed. Non-stackable: just move the whole item.
    local itType = ItemType(entry.itemId)
    local newItem
    if itType:isStackable() then
        -- split
        local oldCount = realItem:getCount()
        if qty == oldCount then
            -- move whole stack: remove from seller, give to buyer
            realItem:remove()
            newItem = buyer:addItem(entry.itemId, qty)
        else
            realItem:setCount(oldCount - qty)
            newItem = buyer:addItem(entry.itemId, qty)
        end
    else
        if qty ~= 1 then
            PlayerShop_Reject(buyer, "Item nao-stackable so pode ser comprado em qty=1.")
            -- rollback gold
            buyer:addMoney(fromBp)
            buyer:setBankBalance((buyer:getBankBalance() or 0) + fromBank)
            return false
        end
        -- preserve charges on non-stackables (runes etc)
        local subType = realItem:getSubType()
        realItem:remove()
        newItem = buyer:addItem(entry.itemId, subType > 0 and subType or 1)
    end

    if not newItem then
        -- ROLLBACK (item was removed but addItem failed: cap full)
        buyer:addItem(entry.itemId, qty)  -- best effort
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
        if ItemType(id):isContainer() then
            for _, sub in ipairs(it:getItems()) do
                visit(sub)
            end
        end
    end

    for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
        visit(player:getSlotItem(slot))
    end

    local msg = NetworkMessage()
    msg:addByte(0x32)
    msg:addByte(PlayerShopOpcode.INVENTORY_LIST)
    msg:addU16(#items)
    for _, e in ipairs(items) do
        msg:addU32(e.uid)
        msg:addU16(e.id)
        msg:addU16(e.count)
        msg:addU16(e.charges)
        msg:addString(e.name)
    end
    msg:sendToPlayer(player)
    msg:delete()
end
