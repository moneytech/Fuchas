local drv = {}
local out = nil
local outbuf = ""
local printer = component.getPrimary("openprinter")

function drv.out()
	if out == nil then
		out = {
			write = function(self, str)
				local ln = table.pack(string.find(str, "\n", 1, true))
				local last = 1
				for k, v in pairs(ln) do
					if k ~= "n" then
						if outbuf ~= nil then
							printer.writeln(outbuf)
							outbuf = nil
						end
						printer.writeln(string.sub(last, v))
						last = v+1
					end
				end
				if last < str:len() then
					outbuf = str:sub(last, str:len())
				end
			end,
			flush = function(self)
				printer.writeln(outbuf)
			end,
			print = function(self)
				self.flush()
				return printer.print()
			end
		}
	end
end

function drv.getName()
	return "OpenPrinter (" .. printer.address:sub(1, 3) .. ")"
end

function drv.getRank()
	return 1
end

return component.isAvailable("openprinter"), "printer", drv