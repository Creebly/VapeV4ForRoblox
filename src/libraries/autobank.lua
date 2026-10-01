local vape = ...
assert(vape and vape.Categories.Inventory, 'Inventory category missing')
local inventoryCategory = vape.Categories.Inventory
if vape.Modules.AutoBank then return vape.Modules.AutoBank end

local players = game:GetService('Players')
local replicatedStorage = game:GetService('ReplicatedStorage')
local collectionService = game:GetService('CollectionService')
local lplr = players.LocalPlayer
local resources = {
	iron = true,
	gold = true,
	diamond = true,
	emerald = true,
	void_crystal = true
}

local function notify(message, duration)
	pcall(function()
		vape:CreateNotification('AutoBank', message, duration or 5)
	end)
end

local function getPosition(object)
	if object:IsA('BasePart') then return object.Position end
	if object:IsA('Model') then return object:GetPivot().Position end
	local part = object:FindFirstChildWhichIsA('BasePart', true)
	return part and part.Position
end

local function getPersonalChest()
	local inventories = replicatedStorage:FindFirstChild('Inventories') or replicatedStorage:FindFirstChild('Inventories', true)
	return inventories and inventories:FindFirstChild(lplr.Name..'_personal')
end

local function nearPersonalChest(root)
	for _, chestObject in collectionService:GetTagged('personal-chest') do
		local position = getPosition(chestObject)
		if position and (position - root.Position).Magnitude < 20 then
			return true
		end
	end
	return false
end

local function atOwnBase(root)
	local mapCFrames = workspace:FindFirstChild('MapCFrames')
	local teamName = lplr:GetAttribute('Team') or (lplr.Team and lplr.Team.Name)
	local spawnPoint = mapCFrames and teamName and mapCFrames:FindFirstChild(tostring(teamName)..'_spawn')
	return spawnPoint and (root.Position - spawnPoint.Value.Position).Magnitude < 80
end

local AutoBank
AutoBank = inventoryCategory:CreateModule({
	Name = 'AutoBank',
	Function = function(enabled)
		if not enabled then return end
		if game.PlaceId == 6872265039 then
			notify('Join a BedWars match to use your personal chest.', 8)
			if AutoBank.Enabled then AutoBank:Toggle() end
			return
		end
		local success, failure = pcall(function()
			local ts = replicatedStorage:WaitForChild('TS', 10)
			assert(ts, 'ReplicatedStorage.TS was not found')
			local remotes = ts:WaitForChild('remotes', 10)
			assert(remotes, 'BedWars remotes were not found')
			local client = require(remotes).default.Client
			local playerTs = lplr.PlayerScripts:WaitForChild('TS', 10)
			assert(playerTs and playerTs:FindFirstChild('ui') and playerTs.ui:FindFirstChild('store'), 'BedWars inventory store was not found')
			local clientStore = require(playerTs.ui.store).ClientStore
			local inventoryNamespace = client:GetNamespace('Inventory')
			local getRemote = inventoryNamespace:Get('ChestGetItem')
			local giveRemote = inventoryNamespace:Get('ChestGiveItem')

			local function getInventoryItems()
				local state = clientStore:getState()
				local inventoryState = state and state.Inventory
				local observed = inventoryState and inventoryState.observedInventory
				local inventory = observed and observed.inventory
				return inventory and inventory.items or {}
			end

			repeat
				local character = lplr.Character
				local root = character and character:FindFirstChild('HumanoidRootPart')
				local chest = root and getPersonalChest()
				if root and chest and nearPersonalChest(root) then
					if atOwnBase(root) then
						for _, item in chest:GetChildren() do
							if resources[item.Name] then
								task.spawn(function()
									pcall(function() getRemote:CallServer(chest, item) end)
								end)
							end
						end
					else
						for _, item in getInventoryItems() do
							if resources[item.itemType] and item.tool then
								task.spawn(function()
									pcall(function() giveRemote:CallServer(chest, item.tool) end)
								end)
							end
						end
					end
				end
				task.wait(0.5)
			until not AutoBank.Enabled
		end)

		if not success then
			notify('Stopped: '..tostring(failure), 15)
			if AutoBank.Enabled then
				AutoBank:Toggle()
			end
		end
	end,
	Tooltip = 'Automatically moves resources through your personal chest'
})

AutoBank:SetVisible(true, true)
AutoBank.Object.Visible = true
inventoryCategory.Button.Object.Visible = true
if not inventoryCategory.Button.Enabled then
	inventoryCategory.Button:Toggle()
end
inventoryCategory.Object.Visible = true
if not inventoryCategory.Expanded then
	inventoryCategory:Expand()
end
notify('AutoBank is available under Inventory')

return AutoBank
