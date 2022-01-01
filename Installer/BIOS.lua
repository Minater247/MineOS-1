
local result, reason = ""

do
    if not http then
        error("Required HTTP API not found!")
    end
	local handle, chunk = http.get("https://raw.githubusercontent.com/Minater247/MineOS-1/master/Installer/Main.lua")

	result = handle.readAll()

	handle.close()
end

result, reason = load(result, "=installer")

if result then
	result, reason = xpcall(result, debug.traceback)

	if not result then
		error(reason)
	end
else
	error(reason)	
end
