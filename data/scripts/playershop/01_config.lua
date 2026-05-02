-- ===========================================================================
-- Player Shop System (Priston Tale style)
-- 28/04/2026 - Realera TFS 1.5 / 8.0
--
-- Shared config + opcode IDs. Loaded first (revscript alphabetical order).
-- ===========================================================================

PlayerShopConfig = {
    maxShopDuration       = 8 * 60 * 60,       -- 8h
    maxItemsPerShop       = 20,
    maxShopTextLength     = 45,                -- ate 22 chars/linha, max 2 linhas
    minItemPrice          = 1,
    maxItemPrice          = 1000000000,        -- 1kkk
    bubbleStyle           = "ShopBubble",
    closeShopOnSave       = true,
    rateLimitShopRequest  = 1000,              -- ms between OPCODE_SHOP_REQUEST per buyer
    serverSaveHookKey     = "playershop:save", -- onShutdown / globalevent
    storageKey            = 88810,             -- player storage flag for "is selling"
}

-- Extended-opcode IDs (single byte 0..255). Avoid clashes with other modules.
PlayerShopOpcode = {
    OPEN              = 130, -- C->S: open shop with payload (items, prices, text)
    CLOSE             = 131, -- C->S: close own shop
    REQUEST           = 132, -- C->S: request shop data of player X (on click)
    BUY               = 133, -- C->S: buy item slot N qty Q from seller X
    DATA              = 134, -- S->C: shop data (items, prices, text, sellerName)
    STATE_BROADCAST   = 135, -- S->C: someone nearby opened/closed a shop (bubble+icon)
    VIP_STATUS        = 136, -- S->C: VIP entry opened/closed shop
    INVENTORY_LIST    = 137, -- S->C: inventory snapshot for the create-shop window
    REJECT            = 138, -- S->C: reject reason text
    HISTORY_REQUEST   = 139, -- C->S: u16 page, u16 pageSize -- fetch sales log
    HISTORY           = 140, -- S->C: paginated history page (see 07_history.lua)
}

-- ---- runtime tables (in-memory) ----
ActiveShops      = ActiveShops      or {}  -- [sellerId] = {items, text, startTime}
OpenShopWindows  = OpenShopWindows  or {}  -- [buyerId]  = sellerId
LastShopRequest  = LastShopRequest  or {}  -- [buyerId]  = ms timestamp of last REQUEST

-- ---- byte-packing helpers (network LE) ----
function PlayerShop_PackU8(n)  return string.char(n % 256) end
function PlayerShop_PackU16(n) return string.char(n % 256, math.floor(n/256) % 256) end
function PlayerShop_PackU32(n)
    return string.char(n % 256,
                       math.floor(n/256) % 256,
                       math.floor(n/65536) % 256,
                       math.floor(n/16777216) % 256)
end
function PlayerShop_PackStr(s)
    s = s or ""
    return PlayerShop_PackU16(#s) .. s
end

-- Send an extended opcode with the entire payload packed into a single
-- addString call. The OTClient parser strips the u16-length framing and
-- delivers `buffer` to Lua as exactly the bytes packed here. Multiple
-- addByte/addU32 calls AFTER addByte(opcode) corrupt this framing.
function PlayerShop_SendOpcode(player, opcode, payload)
    if not player then return end
    local msg = NetworkMessage()
    msg:addByte(0x32)
    msg:addByte(opcode)
    msg:addString(payload or "")
    msg:sendToPlayer(player)
    msg:delete()
end

function PlayerShop_Reject(player, reason)
    if not player then return end
    PlayerShop_SendOpcode(player, PlayerShopOpcode.REJECT, reason or "Invalid operation.")
    -- After every reject, resync the player's true selling state so the client's
    -- iAmSelling flag matches reality. (Without this, the client's optimistic
    -- iAmSelling=true that was set on commitCreateShop gets RESET to false by
    -- onReject, and a player who already has an active shop briefly walks free.)
    local payload = PlayerShop_PackU32(player:getId())
                 .. PlayerShop_PackU8(PlayerShop_IsSelling(player:getId()) and 1 or 0)
    if PlayerShop_IsSelling(player:getId()) then
        local shop = ActiveShops[player:getId()]
        payload = payload .. PlayerShop_PackStr(shop and shop.text or "")
    end
    PlayerShop_SendOpcode(player, PlayerShopOpcode.STATE_BROADCAST, payload)
end

function PlayerShop_IsSelling(playerId)
    return ActiveShops[playerId] ~= nil
end

function PlayerShop_TileIsPZ(pos)
    local tile = Tile(pos)
    return tile and tile:hasFlag(TILESTATE_PROTECTIONZONE) or false
end
