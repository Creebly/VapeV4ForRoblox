local vape = shared.vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
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

vape.Place = 77790193039862
if isfile('creeblyvape/games/'..vape.Place..'.lua') then
	loadstring(readfile('creeblyvape/games/'..vape.Place..'.lua'), '1.8arena')()
else
	if not shared.VapeDeveloper then
		local success, result = pcall(downloadFile, 'creeblyvape/games/'..vape.Place..'.lua')
		if success and result then
			loadstring(result, '1.8arena')()
		end
	end
end