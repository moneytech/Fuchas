package.loaded["liburf"] = nil
print("Launching..")
print("Importing liburf..")
local liburf = require("liburf")
print("Importing io..")
print("Opening A:/test.urf as write")
local s = io.open("A:/Temporary/test.urf", "w")
print("Creating new archive..")
local arc = liburf.newArchive()
print("Creating child entry \"test.lua\"")
local f = arc.root.childEntry("test.lua", false)
f.content = "print(\"The next-to-be official format for .FPE (Fuchas Portable Executable) will be based on URF\")"
print("Writing archive..")
liburf.writeArchive(arc, s)
print("Closing stream..")
s:close()