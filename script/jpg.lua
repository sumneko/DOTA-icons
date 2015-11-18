
local ffi = require 'ffi'

ffi.cdef[[
	void    BmpToJpg(const char *bmp_name, const char *jpg_name, bool color, int i);
	void    JpgToBmp(const char *jpg_name, const char *bmp_name, int i);
]]

local lib = ffi.load 'JpgVSbmp'

local mt = {}
mt.__index = mt

function mt.parser()
	local self = {}
	setmetatable(self, mt)
	self.datas = {}
	return self
end

function mt:feed(data)
	table.insert(self.datas, data)
	return self
end

function mt:get()
	return table.concat(self.datas)
end

function mt:convert()
	local temp_jpg = 'temp.jpg'
	local temp_bmp = 'temp.bmp'
	local s = self:get()
	local f = io.open(temp_jpg, 'wb')
	f:write(s)
	f:close()
	lib.JpgToBmp(temp_jpg, temp_bmp, 3)
	local f = io.open(temp_bmp, 'rb')
	local content = f:read 'a'
	f:close()
	return content
end

return mt
