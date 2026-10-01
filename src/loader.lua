local baseURL = 'https://raw.githubusercontent.com/Creebly/VapeV4ForRoblox/refs/heads/main/runtime/'
-- The build embeds its version: startup does not need to download version.txt.
local buildVersion = '__FORK_BUILD_VERSION__'
local watermark = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.'
local isfile = isfile or function(file)
	local success, value = pcall(readfile, file)
	return success and value ~= nil and value ~= ''
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

local function invalidate(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if isfolder(file) then
			invalidate(file)
		elseif isfile(file) and readfile(file):sub(1, #watermark) == watermark then
			if delfile then delfile(file) else writefile(file, '') end
		end
	end
end

if not shared.VapeDeveloper then
	local versionPath = 'newvape/profiles/fork-version.txt'
	if not isfile(versionPath) or readfile(versionPath) ~= buildVersion then
		for _, folder in {'newvape/games', 'newvape/guis', 'newvape/libraries', 'newvape/assets'} do
			invalidate(folder)
		end
		for _, file in {'newvape/main.lua', 'newvape/loader.lua'} do
			if isfile(file) and readfile(file):sub(1, #watermark) == watermark then
				if delfile then delfile(file) else writefile(file, '') end
			end
		end
		writefile(versionPath, buildVersion)
	end
	writefile('newvape/profiles/commit.txt', 'main')
	writefile('newvape/profiles/asset.txt', '1')
end

local function download(relativePath)
	local success, source = pcall(function()
		return game:HttpGet(baseURL..relativePath, true)
	end)
	assert(success, 'Could not download '..relativePath..': '..tostring(source))
	assert(type(source) == 'string' and source ~= '' and source ~= '404: Not Found', 'The fork runtime is missing '..relativePath)
	return source
end

local mainPath = 'newvape/main.lua'
if not shared.VapeDeveloper or not isfile(mainPath) then
	local source = download('main.lua')
	writefile(mainPath, watermark..'\n'..source)
	-- Refresh this small independent module even if a previous cache was edited.
	if not shared.VapeDeveloper then
		local autoBankSource = download('libraries/autobank.lua')
		writefile('newvape/libraries/autobank.lua', watermark..'\n'..autoBankSource)
	end
end
local main, err = loadstring(readfile(mainPath), 'main')
assert(main, err)
return main()
