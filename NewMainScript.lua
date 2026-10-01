local baseURL = 'https://raw.githubusercontent.com/Creebly/VapeV4ForRoblox/main/runtime/'
local watermark = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.'
local isfile = isfile or function(file)
	local success, value = pcall(readfile, file)
	return success and value ~= nil and value ~= ''
end

for _, folder in {'creeblyvape', 'creeblyvape/games', 'creeblyvape/profiles', 'creeblyvape/assets', 'creeblyvape/libraries', 'creeblyvape/guis'} do
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
	local version = game:HttpGet(baseURL..'version.txt'):match('^%x+')
	assert(version, 'Could not read the fork build version')
	local versionPath = 'creeblyvape/profiles/fork-version.txt'
	if not isfile(versionPath) or readfile(versionPath) ~= version then
		for _, folder in {'creeblyvape/games', 'creeblyvape/guis', 'creeblyvape/libraries', 'creeblyvape/assets'} do
			invalidate(folder)
		end
		for _, file in {'creeblyvape/main.lua', 'creeblyvape/loader.lua'} do
			if isfile(file) and readfile(file):sub(1, #watermark) == watermark then
				if delfile then delfile(file) else writefile(file, '') end
			end
		end
		writefile(versionPath, version)
	end
	writefile('creeblyvape/profiles/commit.txt', 'main')
	writefile('creeblyvape/profiles/asset.txt', '1')
end

local mainPath = 'creeblyvape/main.lua'
if not isfile(mainPath) then
	local source = game:HttpGet(baseURL..'main.lua')
	assert(source ~= '404: Not Found', 'The fork runtime is missing main.lua')
	writefile(mainPath, watermark..'\n'..source)
end
local main, err = loadstring(readfile(mainPath), 'main')
assert(main, err)
return main()
