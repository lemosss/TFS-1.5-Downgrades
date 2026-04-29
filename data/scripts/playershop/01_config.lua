-- ===========================================================================
-- Player Shop System (Priston Tale style)
-- 28/04/2026 - Realera TFS 1.5 / 8.0
--
-- Shared config + opcode IDs. Loaded first (revscript alphabetical order).
-- ===========================================================================

PlayerShopConfig = {
    maxShopDuration       = 8 * 60 * 60,       -- 8h
    maxItemsPerShop       = 20,
    maxShopTextLength     = 50,
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
}

-- ---- runtime tables (in-memory) ----
ActiveShops      = ActiveShops      or {}  -- [sellerId] = {items, text, startTime}
OpenShopWindows  = OpenShopWindows  or {}  -- [buyerId]  = sellerId
LastShopRequest  = LastShopRequest  or {}  -- [buyerId]  = ms timestamp of last REQUEST

-- ---- helpers exposed globally ----
function PlayerShop_Reject(player, reason)
    if not player then return end
    local msg = NetworkMessage()
    msg:addByte(0x32)
    msg:addByte(PlayerShopOpcode.REJECT)
    msg:addString(reason or "Operacao invalida.")
    msg:sendToPlayer(player)
    msg:delete()
    player:sendCancelMessage(reason or "Operacao invalida.")
end

function PlayerShop_IsSelling(playerId)
    return ActiveShops[playerId] ~= nil
end

function PlayerShop_TileIsPZ(pos)
    local tile = Tile(pos)
    return tile and tile:hasFlag(TILESTATE_PROTECTIONZONE) or false
end
