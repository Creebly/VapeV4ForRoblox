repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

local vape
local bedwarsExperience = game.GameId == 2619619496
	or table.find({6872265039, 6872274481, 8560631822, 8444591321}, game.PlaceId) ~= nil
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	local autoBank = bedwarsExperience and vape.Modules.AutoBank
	if autoBank then
		autoBank:SetVisible(true, true)
		autoBank.Object.Visible = true
		local category = vape.Categories.Inventory
		category.Button.Object.Visible = true
		if not category.Button.Enabled then category.Button:Toggle() end
		category.Object.Visible = true
		if not category.Expanded then category:Expand() end
	end
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('newvape/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..readfile('newvape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
				end
			]]

			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end

			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end

			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Settings.GUI.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.GUIBind.Keys, ' + '):upper()..' to open GUI', 5)
		end
	end
end

if not isfile('newvape/profiles/gui.txt') then
	writefile('newvape/profiles/gui.txt', 'new')
end
local gui = 'new'--readfile('newvape/profiles/gui.txt')

if not isfolder('newvape/assets/'..gui) then
	makefolder('newvape/assets/'..gui)
end
vape = loadstring(downloadFile('newvape/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape

-- Register before universal dependencies or legacy game setup can fail.
if bedwarsExperience then
	local success, err = pcall(function()
		loadstring(downloadFile('newvape/libraries/autobank.lua'), 'autobank')(vape)
	end)
	if not success then
		warn('[Vape] AutoBank registration failed: '..tostring(err))
		vape:CreateNotification('AutoBank', 'Could not create the module: '..tostring(err), 30, 'alert')
	end
end

if not shared.VapeIndependent then
	local universalSuccess, universalError = pcall(function()
		loadstring(downloadFile('newvape/games/universal.lua'), 'universal')()
	end)
	if not universalSuccess then
		if not bedwarsExperience then error(universalError) end
		warn('[Vape] Universal compatibility: '..tostring(universalError))
		vape:CreateNotification('Vape', 'Some general modules failed to load. AutoBank is independent.', 10, 'alert')
	end
	local arguments = table.pack(...)
	local function loadGame()
		if isfile('newvape/games/'..game.PlaceId..'.lua') then
			loadstring(readfile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(table.unpack(arguments, 1, arguments.n))
		elseif not shared.VapeDeveloper then
			local success, data = pcall(downloadFile, 'newvape/games/'..game.PlaceId..'.lua')
			if success then
				loadstring(data, tostring(game.PlaceId))(table.unpack(arguments, 1, arguments.n))
			end
		end
	end
	if bedwarsExperience then
		task.spawn(function()
			local success, err = pcall(loadGame)
			if not success then warn('[Vape] BedWars compatibility: '..tostring(err)) end
		end)
	else
		loadGame()
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
