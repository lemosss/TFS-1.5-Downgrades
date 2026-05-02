-- ===========================================================================
-- Player Shop sales history (lifetime SQL log).
--
-- Each successful PlayerShop_DoBuy() inserts one row here. The seller's
-- create-shop window pulls paginated pages on demand via OPCODE_SHOP_HISTORY.
--
-- The table survives server restarts and player relogs (it's tied to the
-- seller's account_id-derived `players.id` GUID, not to the in-memory
-- ActiveShops table). Rows are NEVER deleted automatically -- the user
-- explicitly chose "lifetime" history. Add a manual purge talkaction or
-- a maintenance script later if the table starts costing too much storage.
-- ===========================================================================

-- ---- schema (idempotent at boot) ----
db.query([[
CREATE TABLE IF NOT EXISTS `playershop_history` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seller_guid`  INT UNSIGNED NOT NULL,
    `buyer_name`   VARCHAR(40)  NOT NULL,
    `item_id`      SMALLINT UNSIGNED NOT NULL,
    `item_name`    VARCHAR(120) NOT NULL,
    `item_count`   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `price_total`  BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `ts`           INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_seller_ts` (`seller_guid`, `ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
]])

-- ---- record one sale ----
-- Called from inside PlayerShop_DoBuy() right after the seller is credited
-- and stock decremented. Async because we don't want to block the BUY
-- transaction on a disk write. The seller may not even have a current
-- shop session open at this point (rare race) and that's fine.
function PlayerShop_LogSale(sellerGuid, buyerName, itemId, itemName, count, priceTotal)
    if not sellerGuid or sellerGuid <= 0 then return end
    -- Defensive truncation: items.xml names rarely exceed ~30 chars but a
    -- malformed name would otherwise blow up the INSERT against the
    -- VARCHAR(120) column.
    itemName  = tostring(itemName or "item"):sub(1, 120)
    buyerName = tostring(buyerName or "?"):sub(1, 40)
    db.asyncQuery(string.format(
        "INSERT INTO `playershop_history` "
            .. "(`seller_guid`,`buyer_name`,`item_id`,`item_name`,"
            .. "`item_count`,`price_total`,`ts`) "
            .. "VALUES (%d, %s, %d, %s, %d, %d, %d)",
        sellerGuid,
        db.escapeString(buyerName),
        itemId or 0,
        db.escapeString(itemName),
        count or 1,
        priceTotal or 0,
        os.time()
    ))
end

-- ---- fetch a page of sales for a given seller ----
-- Returns (entries, totalEntries, totalPages). Page is 1-indexed.
-- Entries sorted newest-first.
function PlayerShop_FetchHistory(sellerGuid, page, pageSize)
    pageSize = math.max(1, math.min(100, pageSize or 20))
    page     = math.max(1, page or 1)
    local offset = (page - 1) * pageSize

    local totalEntries = 0
    local rid = db.storeQuery(string.format(
        "SELECT COUNT(*) AS n FROM `playershop_history` WHERE `seller_guid` = %d",
        sellerGuid))
    if rid then
        totalEntries = result.getNumber(rid, 'n') or 0
        result.free(rid)
    end
    local totalPages = math.max(1, math.ceil(totalEntries / pageSize))

    local entries = {}
    rid = db.storeQuery(string.format(
        "SELECT `buyer_name`,`item_id`,`item_name`,`item_count`,`price_total`,`ts` "
            .. "FROM `playershop_history` "
            .. "WHERE `seller_guid` = %d "
            .. "ORDER BY `ts` DESC, `id` DESC "
            .. "LIMIT %d OFFSET %d",
        sellerGuid, pageSize, offset))
    if rid then
        repeat
            entries[#entries + 1] = {
                buyerName  = result.getString(rid, 'buyer_name') or '?',
                itemId     = result.getNumber(rid, 'item_id') or 0,
                itemName   = result.getString(rid, 'item_name') or 'item',
                count      = result.getNumber(rid, 'item_count') or 1,
                priceTotal = result.getNumber(rid, 'price_total') or 0,
                ts         = result.getNumber(rid, 'ts') or 0,
            }
        until not result.next(rid)
        result.free(rid)
    end
    return entries, totalEntries, totalPages
end

-- ---- send paginated history page to the requesting player ----
-- Wire format (matches the client's onShopHistory parser in playershop.lua):
--   u16 currentPage, u16 totalPages, u32 totalEntries, u16 entryCount
--   per entry: u32 ts, str buyer, str itemName, u16 count, u32 priceTotal
function PlayerShop_SendHistoryPage(player, page, pageSize)
    if not player then return end
    local entries, totalEntries, totalPages =
        PlayerShop_FetchHistory(player:getId(), page, pageSize)

    local payload = PlayerShop_PackU16(page)
                 .. PlayerShop_PackU16(totalPages)
                 .. PlayerShop_PackU32(math.min(totalEntries, 0xFFFFFFFF))
                 .. PlayerShop_PackU16(#entries)
    for _, e in ipairs(entries) do
        payload = payload
               .. PlayerShop_PackU32(e.ts)
               .. PlayerShop_PackStr(e.buyerName)
               .. PlayerShop_PackStr(e.itemName)
               .. PlayerShop_PackU16(math.min(e.count, 0xFFFF))
               .. PlayerShop_PackU32(math.min(e.priceTotal, 0xFFFFFFFF))
    end
    PlayerShop_SendOpcode(player, PlayerShopOpcode.HISTORY, payload)
end
