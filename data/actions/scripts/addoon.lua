local outfits = {
    {storage = 8470001, outfit1 = 258, outfit2 = 267, itemid = 8357, message = 'You have received all addons of citizen outfit.'},
    {storage = 8470002, outfit1 = 259, outfit2 = 268, itemid = 8361, message = 'You have received all addons of hunter outfit.'},
    {storage = 8470003, outfit1 = 260, outfit2 = 269, itemid = 8404, message = 'You have received all addons of mage outfit.'},
    {storage = 8470004, outfit1 = 261, outfit2 = 270, itemid = 8356, message = 'You have received all addons of knight outfit.'},
    {storage = 8470005, outfit1 = 262, outfit2 = 271, itemid = 8428, message = 'You have received all addons of noble outfit.'},
    {storage = 8470006, outfit1 = 316, outfit2 = 432, itemid = 8349, message = 'You have received all addons of summoner outfit.'},
    {storage = 8470007, outfit1 = 263, outfit2 = 272, itemid = 8427, message = 'You have received all addons of warrior outfit.'},
    {storage = 8470008, outfit1 = 436, outfit2 = 431, itemid = 8362, message = 'You have received all addons of druid outfit.'},
    {storage = 8470009, outfit1 = 414, outfit2 = 434, itemid = 8360, message = 'You have received all addons of oriental outfit.'},
    {storage = 8470010, outfit1 = 435, outfit2 = 437, itemid = 8358, message = 'You have received all addons of assassin outfit.'},
    {storage = 8470011, outfit1 = 337, outfit2 = 308, itemid = 8431, message = 'You have received all addons of guardian outfit.'},
    {storage = 8470012, outfit1 = 338, outfit2 = 309, itemid = 8432, message = 'You have received all addons of spike elite outfit.'},
    {storage = 8470013, outfit1 = 307, outfit2 = 336, itemid = 8433, message = 'You have received all addons of mysticelite outfit.'},
    {storage = 8470014, outfit1 = 275, outfit2 = 266, itemid = 8430, message = 'You have received all addons of yalahari outfit.'},
    {storage = 8470015, outfit1 = 273, outfit2 = 265, itemid = 8355, message = 'You have received all addons of brotherhood outfit.'},
    {storage = 8470016, outfit1 = 449, outfit2 = 456, itemid = 8348, message = 'You have received all addons of golden outfit.'},
    {storage = 8470017, outfit1 = 452, outfit2 = 451, itemid = 8429, message = 'You have received all addons of crown outfit.'},
    {storage = 8470018, outfit1 = 454, outfit2 = 455, itemid = 8417, message = 'You have received all addons of dragon slayer outfit.'},
    {storage = 8470019, outfit1 = 450, outfit2 = 457, itemid = 8353, message = 'You have received all addons of conjurer outfit.'},
    {storage = 8470020, outfit1 = 462, outfit2 = 461, itemid = 8363, message = 'You have received all addons of guaxinim outfit.'},
    {storage = 8470021, outfit1 = 460, outfit2 = 459, itemid = 8434, message = 'You have received all addons of poltergeist outfit.'},
    {storage = 8470022, outfit1 = 469, outfit2 = 468, itemid = 8422, message = 'You have received all addons of angel outfit.'},
    {storage = 8470023, outfit1 = 470, outfit2 = 470, itemid = 8418, message = 'You have received all addons of demon outfit.'},
    {storage = 8470024, outfit1 = 471, outfit2 = 471, itemid = 8419, message = 'You have received all addons of centurion outfit.'},
    {storage = 8470025, outfit1 = 453, outfit2 = 458, itemid = 8354, message = 'You have received all addons of tomb assassin outfit.'}
}

function onUse(cid, item, frompos, item2, topos)
    for _, outfit in ipairs(outfits) do
        if getPlayerStorageValue(cid, outfit.storage) <= 0 and item.itemid == outfit.itemid then
            setPlayerStorageValue(cid, outfit.storage, 1)
            doPlayerAddOutfit(cid, outfit.outfit1, 3)
            doPlayerAddOutfit(cid, outfit.outfit2, 3)
            doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, outfit.message)
            doRemoveItem(item.uid, 1)
            return true
        end
    end
    return true
end