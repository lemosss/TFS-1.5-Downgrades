-- ===========================================================================
-- ExtendedOpcode handler (server side).
-- Player:onExtendedOpcode is fired by engine on packet 0x32.
-- ===========================================================================

-- ---- buffer reader (client serializes via packU16/packU32/packStr) ----
local Reader = {}
Reader.__index = Reader

function Reader.new(buf)
    return setmetatable({buf = buf, pos = 1}, Reader)
end

function Reader:byte()
    local b = self.buf:byte(self.pos) or 0
    self.pos = self.pos + 1
    return b
end

function Reader:u16()
    local lo, hi = self.buf:byte(self.pos), self.buf:byte(self.pos + 1)
    self.pos = self.pos + 2
    return (hi or 0) * 256 + (lo or 0)
end

function Reader:u32()
    local b1, b2, b3, b4 =
        self.buf:byte(self.pos), self.buf:byte(self.pos + 1),
        self.buf:byte(self.pos + 2), self.buf:byte(self.pos + 3)
    self.pos = self.pos + 4
    return ((b4 or 0) * 16777216) + ((b3 or 0) * 65536) + ((b2 or 0) * 256) + (b1 or 0)
end

function Reader:str()
    local len = self:u16()
    local s = self.buf:sub(self.pos, self.pos + len - 1)
    self.pos = self.pos + len
    return s
end

-- ---- dispatcher ----
function PlayerShop_DispatchOpcode(player, opcode, buffer)
    if opcode == PlayerShopOpcode.OPEN then
        local r = Reader.new(buffer)
        local payload = { items = {}, text = r:str() }
        local n = r:byte()
        for i = 1, n do
            payload.items[i] = {
                itemUid = r:u32(),
                itemId  = r:u16(),
                count   = r:u16(),
                price   = r:u32(),
            }
        end
        PlayerShop_Open(player, payload)

    elseif opcode == PlayerShopOpcode.CLOSE then
        PlayerShop_Close(player:getId(), "Loja fechada.")

    elseif opcode == PlayerShopOpcode.REQUEST then
        local now = os.mtime and os.mtime() or (os.time() * 1000)
        local last = LastShopRequest[player:getId()] or 0
        if now - last < PlayerShopConfig.rateLimitShopRequest then
            return
        end
        LastShopRequest[player:getId()] = now
        local r = Reader.new(buffer)
        local sellerId = r:u32()
        PlayerShop_SendShopDataTo(player, sellerId)

    elseif opcode == PlayerShopOpcode.BUY then
        local r = Reader.new(buffer)
        local sellerId = r:u32()
        local slot = r:byte()
        local qty = r:u16()
        PlayerShop_Buy(player, sellerId, slot, qty)

    elseif opcode == PlayerShopOpcode.INVENTORY_LIST then
        PlayerShop_SendInventoryList(player)
    end
end

-- ---- creature event hook ----
local ev = CreatureEvent("PlayerShopExtOp")
ev:type("extendedopcode")
ev:onExtendedOpcode(function(player, opcode, buffer)
    if opcode >= 130 and opcode <= 140 then
        PlayerShop_DispatchOpcode(player, opcode, buffer)
        return true
    end
    return false
end)
ev:register()
