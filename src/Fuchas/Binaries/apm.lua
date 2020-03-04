-- APM (Application Package Manager)

local liblon = require("liblon")
local fs = require("filesystem")
local driver = require("driver")
local gpu = driver.gpu
local internet = driver.internet
local shared = require("users").getSharedUserPath()
local userPath = require("users").getUserPath()
local githubGet = "https://raw.githubusercontent.com/"
local shell = require("shell")
local args, options = shell.parse(...)
local global = options["g"] or options["global"]

-- File checks
local packages, repoList
if not fs.exists(shared .. "/apm-packages.lon") then
	packages = {
		["apm"] = {
			files = {
				["Fuchas/Binaries/apm.lua"] = "A:/Fuchas/Binaries/apm.lua"
			},
			dependencies = {},
			name = "Application Package Manager",
			description = "Nice application manager.",
			authors = "zenith391",
			version = "bundled",
			revision = 0
		}
	}
	local s = fs.open(shared .. "/apm-packages.lon", "w")
	s:write(liblon.sertable(packages))
	s:close()
else
	local s = io.open(shared .. "/apm-packages.lon", "r")
	packages = liblon.loadlon(s)
	s:close()
end
if not fs.exists(shared .. "/apm-sources.lon") then
	repoList = { -- Default sources
		"zenith391/Fuchas",
		"zenith391/zenith391-Pipboys"
	}
	local s = fs.open(shared .. "/apm-sources.lon", "w")
	s:write(liblon.sertable(repoList))
	s:close()
else
	local s = io.open(shared .. "/apm-sources.lon", "r")
	repoList = liblon.loadlon(s)
	s:close()
end

local function save()
	local s = fs.open(shared .. "/apm-packages.lon", "w")
	s:write(liblon.sertable(packages))
	s:close()
	s = fs.open(shared .. "/apm-sources.lon", "w")
	s:write(liblon.sertable(repoList))
	s:close()
end

local function loadLonSec(txt)
	local ok, out = pcall(liblon.loadlon, txt)
	if not ok then
		io.stderr:write("    " .. out)
	end
	return ok, out
end

local function searchSource(source)
	if not fs.exists("A:/Temporary/apm-cache") then
		fs.makeDirectory("A:/Temporary/apm-cache")
	end
	local txt
	if not fs.exists("T:/apm-cache/" .. source .. ".lon") then
		if not fs.exists(fs.path("T:/apm-cache/" .. source)) then
			fs.makeDirectory(fs.path("T:/apm-cache/" .. source))
		end
		txt = internet.readFully(githubGet .. source .. "/master/programs.lon")
		local stream = io.open("T:/apm-cache/" .. source .. ".lon", "w")
		local _, lon = loadLonSec(txt)
		lon["expiresOn"] = os.time() + 60
		stream:write(liblon.sertable(lon))
		stream:close()
	else
		local stream = io.open("T:/apm-cache/" .. source .. ".lon")
		txt = stream:read("a")
		stream:close()
	end
	local ok, out = loadLonSec(txt)
	if out and out["expiresOn"] then
		if os.time() >= out["expiresOn"] then
			fs.remove("T:/apm-cache/" .. source .. ".lon")
			return searchSource(source)
		end
	end
	return out
end

local function downloadPackage(src, name, pkg, ver)
	local arch = computer.getArchitecture()
	if pkg.archFiles then -- if have architecture-dependent files
		if pkg.archFiles[arch] then
			print("Selected package architecture \"" .. arch .. "\"")
			for k, v in pairs(pkg.archFiles[arch]) do
				for l, w in pairs(pkg.files) do
					if v == w then -- same target
						pkg.files[l] = nil
						pkg.files[k] = v
					end
				end
			end
		end
	end
	for k, v in pairs(pkg.files) do
		v = v:gsub("{userpath}", ifOr(global, shared, userPath))
		local dest = fs.canonical(v)
		if ver == 1 then
			dest = fs.canonical(v) .. "/" .. k
		end
		io.stdout:write("\tDownloading " .. k .. "..  ")
		local txt = internet.readFully(githubGet .. src .. "/master/" .. k)
		if txt == "" then
			local _, fg = gpu.getColor()
			gpu.setForeground(0xFF0000)
			print("NOT FOUND!")
			print("\tDOWNLOAD ABORTED")
			gpu.setForeground(fg)
			return
		end
		local s = fs.open(dest, "w")
		s:write(txt)
		s:close()
		local _, fg = gpu.getColor()
		gpu.setForeground(0x00FF00)
		print("OK!")
		gpu.setForeground(fg)
	end
	packages[name] = pkg
	save()
end

if args[1] == "help" then
	print("Usage:")
	print("  apm [-g] <help|install|remove|update|upgrade|list>")
	print("Commands:")
	print("  help               : show this help message")
	print("  install [package]  : install the following package.")
	print("  remove  [package]  : remove the following package.")
	print("  update  [package ] : update the following package.")
	print("  upgrade            : update all outdated packages")
	print("  list               : list installed packages")
	print("Flags:")
	print("  -g      : shortcut for --global")
	print("  --global: this flag put packages installing to user path to global user path")
	return
end

if args[1] == "list" then
	print("Package list:")
	for k, v in pairs(packages) do
		print("\t- " .. k .. " " .. v.version .. " (rev " .. v.revision ..")")
	end
	return
end

if args[1] == "remove" then
	local toInstall = {}
	for i=2,#args do
		table.insert(toInstall, args[i])
	end
	for k, v in pairs(packages) do
		for _, i in pairs(toInstall) do
			if k == i then
				for f, dir in pairs(v.files) do
					dir = dir:gsub("{userpath}", ifOr(global, shared, userPath))
					local dest = fs.canonical(dir)
					io.stdout:write("Removing " .. f .. "..  ")
					fs.remove(dest)
					local _, fg = gpu.getColor()
					gpu.setForeground(0xFF0000)
					print("REMOVED!")
					gpu.setForeground(fg)
				end
				packages[k] = nil
				save()
			end
		end
	end
	return
end

if args[1] == "update" then
	if not internet then
		io.stderr:write("Internet card required!")
		return
	end
	local toInstall = {}
	for i=2,#args do
		table.insert(toInstall, args[i])
	end
	local installed = false
	for k, _ in pairs(packages) do
		for _, i in pairs(toInstall) do
			if k == i then
				installed = true
				break
			end
		end
	end
	if not installed then
		print(args[2] .. " is not installed")
		return
	end
	print("Searching packages..")
	local packageList = {}
	for k, v in pairs(repoList) do
		print("  Source: " .. v)
		packageList[v] = searchSource(v)
	end
	for src, v in pairs(packageList) do
		for k, e in pairs(v) do
			for _, i in pairs(toInstall) do
				if k == i then
					local ver = v["_version"] or 1
					if e.revision >= packages[args[2]].revision then
						print(e.name .. " is up-to-date")
					else
						print("Updating " .. e.name)
						local ok, err = pcall(downloadPackage, src, k, e, ver)
						if not ok then
							print("Error downloading package: " .. err)
						end
						print(e.name .. " updated")
					end
				end
			end
		end
	end
	return
end

if args[1] == "install" then
	local toInstall = {}
	if not internet then
		io.stderr:write("Internet card required!")
		return
	end
	for i=2,#args do
		table.insert(toInstall, args[i])

	end
	for k, _ in pairs(packages) do
		for _, i in pairs(toInstall) do
			if k == i then
				print(k .. " is installed")
				return
			end
		end
	end
	print("Searching packages..")
	local packageList = {}
	for k, v in pairs(repoList) do
		print("  Source: " .. v)
		packageList[v] = searchSource(v)
	end
	local isnt = false
	for src, v in pairs(packageList) do
		for k, e in pairs(v) do
			for _, i in pairs(toInstall) do
				if k == i then -- if it's one of the package we want to install
					local ver = v["_version"] or 1
					for k, v in pairs(e.dependencies) do
						if k == "fuchas" then
							local fmajor = OSDATA.VERSION:sub(1,1)
							local fminor = OSDATA.VERSION:sub(3,3)
							local fpatch = OSDATA.VERSION:sub(5,5)

							local major,minor,patch = v:sub(1,1),v:sub(3,3),'*'
							if v:len() > 3 then patch = v:sub(5,5) end
							if fmajor ~= major or fminor ~= minor or (patch ~= '*' and patch ~= fpatch) then
								print("Package " .. e.name .. " doesn't work with the current version of Fuchas.")
								print("It is made for version " .. v .. ", but the current version is " .. OSDATA.VERSION)
								return
							end
						else
							table.insert(toInstall, v)
						end
					end
					print("Installing " .. e.name)
					local ok, err = pcall(downloadPackage, src, k, e, ver)
					if not ok then
						print("Error downloading package: " .. err)
					end
					print(e.name .. " installed")
					isnt = true
				end
			end
		end
	end
	if isnt then
		return
	end
	print("Package not found: " .. args[2])
	return
end

print("No arguments. Type 'apm help' for help.")