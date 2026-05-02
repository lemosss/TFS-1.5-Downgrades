-- Free-account boat travel policy.
--
-- Standard 8.0 Tibia rule applied to this server: a free account can travel
-- by ship ONLY to one of the five free cities. Every other destination
-- (Edron, Liberty Bay, Port Hope, Svargrond, Yalahar, Ankrahmun, Darashia,
-- ice islands, special-area NPCs, etc.) requires premium.
--
-- Each captain's local addTravelKeyword function passes the destination
-- keyword to this helper to set the StdModule.travel `premium` flag, instead
-- of hardcoding `premium = false` (which made every route free).

FREE_CITY_DESTINATIONS = {
	['thais']        = true,
	['carlin']       = true,
	['venore']       = true,
	["ab'dendriel"]  = true,
	['ab\'dendriel'] = true,
	['kazordoon']    = true,
}

-- Returns true when the destination must require premium (i.e. it is NOT a
-- free city). The captain's local helper passes its `keyword` argument here.
function isPremiumDestination(keyword)
	if not keyword then return true end
	return not FREE_CITY_DESTINATIONS[string.lower(keyword)]
end
