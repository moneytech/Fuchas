local lib = {}
local permtable = {}
local tasks = require("tasks")

local function currentProcess()
	local proc = tasks.getCurrentProcess()
	if not permtable[proc.pid] then
		permtable[proc.pid] = {}
	end
	return proc
end

function lib.revoke(pid)
	if tasks.getProcess(pid).status == "dead" then
		permtable[pid] = nil
		return true
	else
		if lib.hasPermission("security.revoke") then
			permtable[pid] = nil
			return true
		end
	end
	return false
end

function lib.requestPermission(perm, pid)
	if tasks.getCurrentProcess() == nil then
		return
	end
	if package.loaded.users then
		local user = package.loaded.users.getUser()
		if user ~= nil then
			local fileStream = io.open("A:/Fuchas/admins.lon")
			local adminFile = require("liblon").loadlon(fileStream)
			fileStream:close()
			for k, v in pairs(adminFile) do
				if v == user.name then
					permtable[currentProcess().pid] = {
						["*"] = true
					}
					return
				end
			end
		end
	end
	local proc = currentProcess().parent
	if proc.permissionGrant then
		if not permtable[proc.pid] then permtable[proc.pid] = {} end
		if proc.permissionGrant(perm, currentProcess().pid) and lib.hasPermission(perm, proc.pid) then
			permtable[currentProcess().pid][perm] = true
			return true
		else
			return false, "permission not granted"
		end
	end
end

function lib.isRegistered(pid)
	return permtable[pid] ~= nil
end

function lib.hasPermission(perm, pid)
	if not pid and tasks.getCurrentProcess() == nil then
		return true
	end
	local proc = pid or currentProcess().pid
	if permtable[proc]["*"] then
		return true
	else
		return permtable[proc][perm] ~= nil
	end
end

function lib.getPermissions(pid)
	local proc = pid or currentProcess().pid
	local copy = {}
	for k, v in pairs(permtable[proc.pid]) do
		copy[k] = v
	end
	return copy
end

return lib
