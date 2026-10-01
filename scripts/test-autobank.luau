-- Run with the generated runtime strings; only mocks are used, never live remotes.
local mainSource, bankSource, loaderSource = ...
local function compile(source, environment)
	environment.loadstring = function(nestedSource, name)
		local nested, err = loadstring(nestedSource, name)
		if nested then setfenv(nested, environment) end
		return nested, err
	end
	local chunk, err = loadstring(source)
	assert(chunk, err)
	setfenv(chunk, setmetatable(environment, {__index = getfenv()}))
	return chunk
end

local cases = {
	{place = 6872265039, universe = 0, bank = true, lobby = true},
	{place = 6872274481, universe = 0, bank = true},
	{place = 8560631822, universe = 0, bank = true},
	{place = 8444591321, universe = 0, bank = true},
	{place = 123, universe = 2619619496, bank = true},
	{place = 123, universe = 0, bank = false},
	{place = 8560631822, universe = 0, bank = true, independent = true}
}
for _, case in cases do
	local loaded, requires, universalRan = 0, 0, false
	local moduleFunction
	local inventory = {Expanded = false, Object = {Visible = false}}
	inventory.Button = {Enabled = false, Object = {Visible = false}}
	function inventory.Button:Toggle() self.Enabled = not self.Enabled end
	function inventory:Expand() self.Expanded = not self.Expanded end
	local vape = {
		Modules = {}, Categories = {Inventory = inventory},
		Settings = {GUI = {Options = {['GUI bind indicator'] = {Enabled = false}}}}
	}
	function inventory:CreateModule(props)
		assert(not universalRan, 'AutoBank must register before universal runs')
		moduleFunction = props.Function
		local module = {Name = props.Name, Object = {Visible = true}, Enabled = false}
		function module:SetVisible(visible) self.Visible = visible; self.Object.Visible = visible end
		function module:Toggle() self.Enabled = not self.Enabled; moduleFunction(self.Enabled) end
		vape.Modules[props.Name] = module
		return module
	end
	function vape:CreateNotification() end
	function vape:Save() end
	function vape:Clean() end
	function vape:Load()
		loaded += 1
		if self.Modules.AutoBank then self.Modules.AutoBank:SetVisible(false) end
		inventory.Button.Enabled = false
		inventory.Object.Visible = false
		inventory.Expanded = false
	end
	local sharedState = {__testVape = vape, VapeIndependent = case.independent}
	local player = {Name = 'TestPlayer', OnTeleport = {Connect = function() return {} end}}
	local services = {Players = {LocalPlayer = player}, ReplicatedStorage = {}, CollectionService = {}}
	local environment = {
		shared = sharedState,
		game = {PlaceId = case.place, GameId = case.universe,
			IsLoaded = function() return true end, GetService = function(_, name) return services[name] end},
		task = {spawn = function() end, wait = function() end},
		isfile = function() return true end, isfolder = function() return true end,
		readfile = function(path)
			if path:find('/guis/') then return 'return shared.__testVape' end
			if path:find('/libraries/autobank.lua') then return bankSource end
			if path:find('/games/universal.lua') then
				universalRan = true
				return case.bank and "error('simulated universal dependency failure')" or 'return nil'
			end
			return 'return nil'
		end,
		require = function() requires += 1; error('Dependencies unavailable in registration test') end,
		warn = function() end
	}
	compile(mainSource, environment)()
	local bank = vape.Modules.AutoBank
	assert((bank ~= nil) == case.bank, 'Wrong registration for place '..case.place)
	assert(requires == 0, 'Registration must not require game dependencies')
	if case.bank then
		assert(bank.Visible and bank.Object.Visible, 'Module must survive hidden profile settings')
		assert(inventory.Button.Enabled and inventory.Button.Object.Visible and inventory.Object.Visible and inventory.Expanded, 'Inventory must be visible and expanded')
		assert(compile(bankSource, environment)(vape) == bank, 'Duplicate registration must reuse module')
		if case.lobby then
			bank:Toggle()
			assert(not bank.Enabled and requires == 0, 'Lobby enable must not initialize match remotes')
		end
	end
	assert(loaded == (case.independent and 0 or 1), 'Main initialization failed')
end

local embeddedVersion = loaderSource:match("local buildVersion = '(%x+)'")
assert(embeddedVersion and #embeddedVersion == 64, 'Build must embed the loader version')
local files = {
	['creeblyvape/profiles/fork-version.txt'] = embeddedVersion,
	['creeblyvape/main.lua'] = 'stale edited copy',
	['creeblyvape/libraries/autobank.lua'] = 'stale edited bank'
}
local freshRequests = 0
local result = compile(loaderSource, {
	shared = {}, isfolder = function() return true end,
	isfile = function(path) return files[path] ~= nil end,
	readfile = function(path) return files[path] end,
	writefile = function(path, contents) files[path] = contents end,
	game = {HttpGet = function(_, url, useCache)
		assert(useCache == true, 'Use the compatible HttpGet format')
		assert(not url:find('?', 1, true), 'Downloads must not use query parameters')
		assert(not url:find('version.txt', 1, true), 'Startup must not download the version file')
		freshRequests += 1
		if url:find('libraries/autobank.lua', 1, true) then return '-- fresh AutoBank' end
		if url:find('main.lua', 1, true) then return "return 'fresh main'" end
		error('Unexpected URL: '..url)
	end}
})()
assert(result == 'fresh main', 'Loader must replace stale main even with unchanged version')
assert(files['creeblyvape/libraries/autobank.lua']:find('fresh AutoBank', 1, true), 'Loader must refresh AutoBank')
assert(freshRequests == 2, 'Expected only main and AutoBank downloads')
return 'PASS: seven startup cases, failed universal dependency, hidden profiles, lobby guard, duplicate registration, and stale cache refresh'
