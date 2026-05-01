-- ===========================================================================
-- Player Shop core logic: open / close / buy.
-- All transactions are synchronous (no addEvent / yield).
-- ===========================================================================

-- Sanitize the shop text + wrap em 2 linhas pra caber no title acima da
-- cabeca do char. Max 22 chars por linha, total 44. O \n eh interpretado
-- pelo Creature:setTitle no client (CachedText do OTC v8 quebra naturalmente
-- em \n).
local SHOP_TEXT_LINE_LEN = 22
local function sanitizeText(text)
    if type(text) ~= 'string' then return "" end
    text = text:gsub("[%c]", "")
    if #text > PlayerShopConfig.maxShopTextLength then
        text = text:sub(1, PlayerShopConfig.maxShopTextLength)
    end
    if #text > SHOP_TEXT_LINE_LEN then
        -- Tenta quebrar num espaco perto do limite (pra nao cortar palavra
        -- no meio); se nao houver espaco proximo, corta hard em 22.
        local breakAt = SHOP_TEXT_LINE_LEN
        local space = text:sub(1, SHOP_TEXT_LINE_LEN + 1):find(" [^ ]*$")
        if space and space > 1 then breakAt = space - 1 end
        text = text:sub(1, breakAt) .. "\n" .. text:sub(breakAt + 1):gsub("^ +", "")
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
    if skull == SKULL_WHITE then
        return false, "Voce esta com white skull (PK). Nao pode abrir loja."
    end
    if skull == SKULL_RED then
        return false, "Voce esta com red skull (PK). Nao pode abrir loja."
    end
    if skull == SKULL_BLACK then
        return false, "Voce esta com black skull. Nao pode abrir loja."
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

-- forward decl (used by findItemInDepot/cross-slot check before its definition).
local isNonEmptyContainer

-- Recursive depth-first search across ALL depots for the first matching itemId.
-- Skips non-empty containers so we don't return a backpack-with-stuff when
-- the seller asked to sell "an empty backpack".
local function findItemInDepot(player, itemUid, itemId)
    if itemUid and itemUid ~= 0 then
        local it = Item(itemUid)
        if it and it:getHolder() and it:getHolder():getId() == player:getId() then
            return it
        end
    end
    local function search(it)
        if not it then return nil end
        if it:getId() == itemId and not isNonEmptyContainer(it) then return it end
        -- Item ja eh Container userdata se isContainer()=true neste TFS.
        if ItemType(it:getId()):isContainer() then
            local sz = it:getSize() or 0
            for i = 0, sz - 1 do
                local found = search(it:getItem(i))
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
            -- Containers nao-vazios nao contam como estoque vendavel
            -- (mesma logica de findItemInDepot/removeFromDepots).
            if it:getId() == itemId and not isNonEmptyContainer(it) then
                have = have + (it:getCount() or 1)
            end
            -- Item com isContainer=true JA eh Container userdata.
            if ItemType(it:getId()):isContainer() then
                local sz = it:getSize() or 0
                for i = 0, sz - 1 do
                    visit(it:getItem(i))
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
    -- Returns (ok, byDepotId) — byDepotId maps depotId -> count actually pulled
    -- from that depot, so on close we can return to the right city's depot.
    local function removeFromDepots(itemId, qty)
        local left = qty
        local byDepotId = {}
        for depotId = 1, 10 do
            if left <= 0 then break end
            local depot = player:getDepotChest(depotId, false)
            if depot then
                local function strip(container)
                    if left <= 0 then return end
                    for i = container:getSize() - 1, 0, -1 do
                        if left <= 0 then return end
                        local it = container:getItem(i)
                        if it then
                            local idMatches = it:getId() == itemId
                            local itype = ItemType(it:getId())
                            local isCont = itype:isContainer()
                            local hasContent = isCont and (it:getSize() or 0) > 0

                            -- NUNCA remover container com conteudo. Mesmo que
                            -- o id bata, descemos na recursao pra achar o
                            -- item alvo dentro dele. Defesa em profundidade:
                            -- checa via isCont+getSize direto aqui, em vez
                            -- de depender so da funcao isNonEmptyContainer.
                            if idMatches and not hasContent then
                                local c = it:getCount() or 1
                                local pulled = math.min(c, left)
                                if c <= left then
                                    it:remove()
                                else
                                    it:setCount(c - left)
                                end
                                left = left - pulled
                                byDepotId[depotId] = (byDepotId[depotId] or 0) + pulled
                            elseif isCont then
                                -- Container (cheio ou nao do id certo): desce.
                                strip(it)
                            end
                        end
                    end
                end
                strip(depot)
            end
        end
        return left == 0, byDepotId
    end
    for slot, e in pairs(items) do
        local ok2, byDepotId = removeFromDepots(e.itemId, e.count)
        if not ok2 then
            PlayerShop_Reject(player,
                "Falha ao retirar itens do depot. Loja cancelada.")
            return false
        end
        e.byDepotId = byDepotId  -- remember origin per slot for return-on-close
    end

    ActiveShops[player:getId()] = {
        items     = items,
        text      = cleanText,
        startTime = os.time(),
        sellerName = player:getName(),
    }
    player:setStorageValue(PlayerShopConfig.storageKey, 1)
    player:sendTextMessage(MESSAGE_INFO_DESCR, "Loja aberta. Voce nao pode se mover ate fechar.")

    -- Force imediato: o servidor C++ chama getSkullClient(player) e envia
    -- o novo skull (SHOP_ICON=7) pra todos os specs via packet nativo.
    -- Igual o PK skull -- nada de tick periodico ou opcode custom.
    if Game.updateCreatureSkull then Game.updateCreatureSkull(player) end

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
function PlayerShop_Close(playerId, reason, sellerOverride, viaInventory)
    local shop = ActiveShops[playerId]
    if not shop then return end
    ActiveShops[playerId] = nil

    -- During onLogout the player is mid-disconnection so Player(id) may
    -- already return nil; allow callers to pass the live reference directly.
    local seller = sellerOverride or Player(playerId)
    if seller then
        -- Return unsold stash items.
        --
        -- IMPORTANT: at logout (viaInventory=true) we MUST drop into the
        -- player's inventory, not the depot chest. The TFS save logic
        -- (iologindata.cpp:797-846) only writes depot tables when
        -- depotLockerMap[*]:needsSave() is true, but DepotChest::addItem
        -- bypasses the locker's save flag (depotchest.cpp:58 / postAdd
        -- skips the locker via getParent() returning grandparent). Result:
        -- depot inserts at logout silently fail to persist. Inventory is
        -- saved unconditionally (iologindata.cpp:786-795) so this works.
        local ok, err = pcall(function()
            for _, e in pairs(shop.items or {}) do
                if e.count and e.count > 0 then
                    local itType = ItemType(e.itemId)
                    if viaInventory then
                        -- Stuff into player inventory; falls back to ground
                        -- via TFS internal logic if cap is full.
                        if itType:isStackable() then
                            local left = e.count
                            while left > 0 do
                                local chunk = math.min(left, 100)
                                seller:addItem(e.itemId, chunk)
                                left = left - chunk
                            end
                        else
                            local sub = (e.charges and e.charges > 0) and e.charges or 1
                            for _ = 1, e.count do
                                seller:addItem(e.itemId, sub)
                            end
                        end
                    else
                        -- Each slot remembers byDepotId = { depotId -> originalCount }.
                        -- Distribute remaining count proportionally across the original depots.
                        local totalPulled = 0
                        for _, c in pairs(e.byDepotId or {}) do totalPulled = totalPulled + c end
                        if totalPulled <= 0 then totalPulled = e.count end

                        local distributed = 0
                        local order = {}
                        for depotId, _ in pairs(e.byDepotId or {}) do order[#order + 1] = depotId end
                        table.sort(order)
                        if #order == 0 then order = { 1 } end  -- safety fallback to Thais

                        for idx, depotId in ipairs(order) do
                            local originalShare = (e.byDepotId and e.byDepotId[depotId]) or e.count
                            local share = idx == #order
                                and (e.count - distributed)
                                or math.floor(e.count * originalShare / totalPulled)
                            if share > 0 then
                                local chest = seller:getDepotChest(depotId, true)
                                if chest then
                                    if itType:isStackable() then
                                        local left = share
                                        while left > 0 do
                                            local chunk = math.min(left, 100)
                                            chest:addItem(e.itemId, chunk)
                                            left = left - chunk
                                        end
                                    else
                                        local sub = (e.charges and e.charges > 0) and e.charges or 1
                                        for _ = 1, share do
                                            chest:addItem(e.itemId, sub)
                                        end
                                    end
                                end
                                distributed = distributed + share
                            end
                        end
                    end
                end
            end
        end)
        if not ok then
            print('[playershop] return items error: ' .. tostring(err))
        end
        seller:setStorageValue(PlayerShopConfig.storageKey, -1)
        -- Force imediato: getSkullClient agora retorna o skull real
        -- (PK ou nenhum), e o servidor envia o update nativo pra todos
        -- os specs. Resultado: o icone some na hora pra todo mundo.
        if Game.updateCreatureSkull then Game.updateCreatureSkull(seller) end
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
    local isOwner = buyer:getId() == sellerId
    -- Buyer normal precisa estar em PZ pra abrir a janela. O dono nao precisa
    -- (ele consulta o estado da propria loja em qualquer canto da PZ).
    if not isOwner and not PlayerShop_TileIsPZ(buyer:getPosition()) then
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

    -- O dono nao entra em OpenShopWindows -- isso eh tracking de COMPRADORES
    -- pra forcar fechamento quando shop expira. Ele eh dono, nao buyer.
    if not isOwner then
        OpenShopWindows[buyer:getId()] = sellerId
    end

    -- Compute the buyer's spendable balance: bank + cash (gold + plat*100
    -- + crystal*10000). The 7.72 protocol doesn't push wallet info to the
    -- client natively, so the shop UI piggybacks on SHOP_DATA.
    local function countItemInBP(player, itemId)
        local total = 0
        local bp = player:getSlotItem(CONST_SLOT_BACKPACK)
        if not bp then return 0 end
        local stack = { bp }
        while #stack > 0 do
            local cur = stack[#stack]; stack[#stack] = nil
            local size = cur:getSize() or 0
            for i = 0, size - 1 do
                local it = cur:getItem(i)
                if it then
                    if it:getId() == itemId then
                        total = total + (it:getCount() or 1)
                    end
                    if ItemType(it:getId()):isContainer() then
                        stack[#stack + 1] = it
                    end
                end
            end
        end
        return total
    end
    local cash = countItemInBP(buyer, 2148)
              + countItemInBP(buyer, 2152) * 100
              + countItemInBP(buyer, 2160) * 10000
    local bank = (buyer.getBankBalance and buyer:getBankBalance()) or 0
    local total = cash + bank
    if total > 0xFFFFFFFF then total = 0xFFFFFFFF end

    local payload = PlayerShop_PackU32(sellerId)
                 .. PlayerShop_PackStr(seller:getName())
                 .. PlayerShop_PackStr(shop.text or "")
                 .. PlayerShop_PackU8(isOwner and 1 or 0)  -- flag owner-mode
                 .. PlayerShop_PackU32(total)              -- buyer balance (bank + cash)
    local n = 0
    for _ in pairs(shop.items) do n = n + 1 end
    payload = payload .. PlayerShop_PackU8(n)
    for slot, entry in pairs(shop.items) do
        local it = ItemType(entry.itemId)
        -- Send clientId so the OTC widget's setItemId renders the correct
        -- sprite from Tibia.dat. Server-side we keep tracking entry.itemId
        -- (server id) by slot, the buyer only echoes the slot back to buy.
        local weightPer = (it.getWeight and it:getWeight()) or 0  -- in 0.01 oz units (g*100)
        payload = payload
               .. PlayerShop_PackU8(slot)
               .. PlayerShop_PackU16(it:getClientId())
               .. PlayerShop_PackU16(entry.count)
               .. PlayerShop_PackU32(entry.price)
               .. PlayerShop_PackU16(entry.charges or 0)
               .. PlayerShop_PackU32(weightPer)
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
    --
    -- IMPORTANTE: passamos canDropOnMap=false (3o param) pra que addItem
    -- RETORNE NIL quando nao houver cap/slot/bp livre, em vez de jogar o
    -- item no chao. Assim conseguimos bloquear a compra com rollback.
    local itType = ItemType(entry.itemId)
    local newItem
    if itType:isStackable() then
        newItem = buyer:addItem(entry.itemId, qty, false)
    else
        if qty ~= 1 then
            PlayerShop_Reject(buyer, "Item nao-stackable so pode ser comprado em qty=1.")
            buyer:addMoney(fromBp)
            buyer:setBankBalance((buyer:getBankBalance() or 0) + fromBank)
            return false
        end
        -- preserve charges on non-stackables (UH/GFB charges live in subType)
        local sub = entry.charges and entry.charges > 0 and entry.charges or 1
        newItem = buyer:addItem(entry.itemId, sub, false)
    end

    if not newItem then
        -- ROLLBACK: sem cap, sem slot livre ou bag cheia. Devolve o gold.
        buyer:addMoney(fromBp)
        buyer:setBankBalance((buyer:getBankBalance() or 0) + fromBank)
        PlayerShop_Reject(buyer,
            "Voce nao tem espaco/cap pra esse item. Compra cancelada.")
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
    -- Mensagem verde flutuante (centerGreen via MESSAGE_INFO_DESCR=22) pro
    -- vendedor saber em tempo real quem comprou o que.
    seller:sendTextMessage(MESSAGE_INFO_DESCR,
        ("VENDA! %s comprou %dx %s por %d gold (no banco)."):format(
            buyer:getName(), qty, itemName, total))

    -- If shop now empty, auto-close.
    local remaining = 0
    for _ in pairs(shop.items) do remaining = remaining + 1 end
    if remaining == 0 then
        PlayerShop_Close(sellerId, "Todos os itens foram vendidos! Loja fechada.")
    else
        -- Refresh buyer's window.
        PlayerShop_SendShopDataTo(buyer, sellerId)
        -- Refresh owner-view window se o vendedor estiver olhando o estoque
        -- da propria loja (cliente decide ignorar se nao tiver janela aberta).
        PlayerShop_SendShopDataTo(seller, sellerId)
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Send inventory snapshot to player for the create-shop window.
-- ---------------------------------------------------------------------------
-- Aggregate items the player has in their depots, summing counts of identical
-- items so the picker shows "5x fireball rune" not 5 separate entries.
-- Bind the forward-declared local (defined near top of file) to the real fn.
--
-- IMPORTANT API NOTE: this TFS 1.5 fork does NOT expose Item:getContainer().
-- Instead, when ItemType:isContainer() returns true, the item userdata is
-- ALREADY assigned the Container metatable (Container is registered as a
-- subclass of Item in luascript.cpp:2287, and setItemMetatable assigns
-- Container directly when item->getContainer() is non-null in C++).
-- So we call Container methods (getSize, getItem) DIRECTLY on the item.
isNonEmptyContainer = function(it)
    if not it then return false end
    local itype = ItemType(it:getId())
    if not itype:isContainer() then return false end
    return (it:getSize() or 0) > 0
end

function PlayerShop_SendInventoryList(player)
    local agg = {}  -- entries que serao enviadas pro client
    local nonStackCounter = 0  -- gera keys unicas pra cada non-stackable

    -- Cada visita esta em pcall. Erro num item especifico (ex: tipo
    -- "exotico") nao deve abortar a listagem inteira.
    local function visit(it)
        if not it then return end
        local ok, err = pcall(function()
            local id = it:getId()
            local itype = ItemType(id)

            -- Skip moedas (gold/plat/crystal).
            if not (id == 2148 or id == 2152 or id == 2160) then
                -- Containers (bp, bag, qualquer tipo) so entram na lista se
                -- estiverem 100% vazios. A recursao continua sempre.
                if not isNonEmptyContainer(it) then
                    local cnt = it:getCount() or 1
                    local charges = it:getCharges() or 0
                    local stackable = itype:isStackable() and true or false
                    -- Stackable: agrega tudo pelo itemId (1 entry total).
                    -- Non-stackable: cada instancia eh entry separada pra
                    -- o vendedor poder criar offers diferentes pra cada.
                    local key
                    if stackable then
                        key = id
                    else
                        nonStackCounter = nonStackCounter + 1
                        key = 'ns_' .. nonStackCounter
                    end
                    if agg[key] then
                        agg[key].count = agg[key].count + cnt
                    else
                        agg[key] = {
                            id = id,
                            count = cnt,
                            charges = charges,
                            stackable = stackable,
                            name = itype:getName() or "item",
                        }
                    end
                end
            end

            -- Recursar dentro do container pra listar os filhos.
            -- Item com isContainer=true JA eh Container userdata.
            if itype:isContainer() then
                local sz = it:getSize() or 0
                for i = 0, sz - 1 do
                    visit(it:getItem(i))
                end
            end
        end)
        if not ok then
            print('[playershop] visit error on item id=' ..
                tostring(it and it:getId() or '?') .. ': ' .. tostring(err))
        end
    end

    -- Walk all depots (towns 1..10).
    eachDepot(player, function(depot)
        local sz = depot:getSize() or 0
        for i = 0, sz - 1 do
            visit(depot:getItem(i))
        end
    end)

    -- Convert map -> list. Cada entry recebe um indice incremental que vira
    -- "uid virtual" no client, util pra non-stackables onde cada entry eh
    -- uma instancia distinta. (Pro server, na hora do Open, esse uid eh
    -- ignorado e a busca eh por itemId.)
    local items = {}
    for _, e in pairs(agg) do items[#items + 1] = e end

    local payload = PlayerShop_PackU16(#items)
    for idx, e in ipairs(items) do
        -- Send BOTH ids: serverId is what the depot lookup uses on OPEN, and
        -- clientId is what the OTC widget needs to render the sprite. The
        -- old format only sent clientId, which made findItemInDepot fail for
        -- runes (server 2304 vs client.dat 3191 etc) and rejected the open.
        payload = payload
               .. PlayerShop_PackU32(idx)               -- entry index (virtual uid)
               .. PlayerShop_PackU16(e.id)              -- serverId (used for depot lookup)
               .. PlayerShop_PackU16(ItemType(e.id):getClientId())
               .. PlayerShop_PackU16(math.min(e.count, 0xFFFF))
               .. PlayerShop_PackU16(e.charges)
               .. PlayerShop_PackU8(e.stackable and 1 or 0)
               .. PlayerShop_PackStr(e.name)
    end
    PlayerShop_SendOpcode(player, PlayerShopOpcode.INVENTORY_LIST, payload)
end
