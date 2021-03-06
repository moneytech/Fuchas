local fs = require("filesystem")
local shell = require("shell")
local sec = require("security")

-- Free some memory
if package.loaded["OCX/OCDraw"] then
	require("OCX/OCDraw").requestMemory()
end

sec.requestPermission("component.unrestricted")

local args, flags = shell.parse(...)

if #args < 1 then
	io.stderr:write("Usage: stardust <path to OpenOS program>\n")
	return
end

local path = shell.resolve(args[1])
if path == nil then
	io.stderr:write(args[1] .. " doesn't exists\n")
	return
end

local env = {
	computer = require("stardust/computer")
	component = _G.component.unrestricted,
	math = _G.math,
	coroutine = _G.coroutine,
	bit32 = _G.bit32,
	string = _G.string,
	table = _G.table,
	unicode = _G.unicode,
	debug = _G.debug,

	assert = _G.assert,
	error = _G.error,
	getmetatable = _G.getmetatable,
	ipairs = _G.ipairs,
	load = _G.load,
	next = _G.next,
	pairs = _G.pairs,
	pcall = _G.pcall,
	rawequal = _G.rawequal,
	rawget = _G.rawget,
	rawlen = _G.rawlen,
	rawset = _G.rawset,
	select = _G.select,
	setmetatable = _G.setmetatable,
	tonumber = _G.tonumber,
	tostring = _G.tostring,
	type = _G.type,
	xpcall = _G.xpcall

	-- APIs,
	filesystem = require("filesystem"), -- no porting necessary.. yet
	colors = require("stardust/colors"),
	rc = require("stardust/rc"),
	sides = require("stardust/sides"),
	os = require("stardust/os")
}

load(path, "$1 over stardust", "bt", env)
