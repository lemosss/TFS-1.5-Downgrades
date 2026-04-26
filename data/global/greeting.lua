-- Custom greeting words shim imported from OTX.
-- Some NPCs do `dofile(getDataDir() .. 'global/greeting.lua')` to override
-- FocusModule:init with extended greet/farewell vocabularies.
-- Keep behavior identical to TFS default but accept the OTX greet list too.

function FocusModule:init(handler)
	FOCUS_GREETWORDS = {'hi', 'hello', 'yo', 'sup', 'good day'}
	FOCUS_FAREWELLWORDS = {'bye', 'farewell', 'see ya'}
	self.npcHandler = handler
	for _, word in pairs(FOCUS_GREETWORDS) do
		local obj = {}
		table.insert(obj, word)
		obj.callback = FOCUS_GREETWORDS.callback or FocusModule.messageMatcher
		handler.keywordHandler:addKeyword(obj, FocusModule.onGreet, {module = self})
	end

	for _, word in pairs(FOCUS_FAREWELLWORDS) do
		local obj = {}
		table.insert(obj, word)
		obj.callback = FOCUS_FAREWELLWORDS.callback or FocusModule.messageMatcher
		handler.keywordHandler:addKeyword(obj, FocusModule.onFarewell, {module = self})
	end

	return true
end
