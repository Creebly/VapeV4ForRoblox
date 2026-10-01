repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

local vape
local bedwarsMatch = table.find({6872274481, 8560631822, 8444591321}, game.PlaceId) ~= nil
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
			return game:HttpGet('https://raw.githubusercontent.com/Creebly/VapeV4ForRoblox/'..readfile('creeblyvape/profiles/commit.txt')..'/runtime/'..select(1, path:gsub('creeblyvape/', '')), true)
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
	local autoBank = bedwarsMatch and vape.Modules.AutoBank
	if autoBank then
		autoBank:SetVisible(true, true)
		autoBank.Object.Visible = true
		local category = vape.Categories.Inventory
		if not category.Button.Enabled then category.Button:Toggle() end
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
					loadstring(readfile('creeblyvape/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/Creebly/VapeV4ForRoblox/'..readfile('creeblyvape/profiles/commit.txt')..'/runtime/loader.lua', true), 'loader')()
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

if not isfile('creeblyvape/profiles/gui.txt') then
	writefile('creeblyvape/profiles/gui.txt', 'new')
end
local gui = 'new'--readfile('creeblyvape/profiles/gui.txt')

if not isfolder('creeblyvape/assets/'..gui) then
	makefolder('creeblyvape/assets/'..gui)
end
vape = loadstring(downloadFile('creeblyvape/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape

if not shared.VapeIndependent then
	loadstring(downloadFile('creeblyvape/games/universal.lua'), 'universal')()
	if bedwarsMatch then
		loadstring(downloadFile('creeblyvape/libraries/autobank.lua'), 'autobank')(vape)
	end
	local arguments = table.pack(...)
	local function loadGame()
		if isfile('creeblyvape/games/'..game.PlaceId..'.lua') then
			loadstring(readfile('creeblyvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(table.unpack(arguments, 1, arguments.n))
		elseif not shared.VapeDeveloper then
			local success, data = pcall(downloadFile, 'creeblyvape/games/'..game.PlaceId..'.lua')
			if success then
				loadstring(data, tostring(game.PlaceId))(table.unpack(arguments, 1, arguments.n))
			end
		end
	end
	if bedwarsMatch then
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
