
local ffi = require 'ffi'

ffi.cdef[[
	IJLERR               ijlInit(JPEG_CORE_PROPERTIES *jcprops);
	IJLERR               ijlFree(JPEG_CORE_PROPERTIES *jcprops);
	IJLERR               ijlRead(JPEG_CORE_PROPERTIES *jcprops, IJLIOTYPE iotype);
	IJLERR               ijlWrite(JPEG_CORE_PROPERTIES *jcprops, IJLIOTYPE iotype);
	const IJLibVersion*  ijlGetLibVersion();
	const char*          ijlErrorStr(IJLERR code);
]]

local jpg = ffi.load 'ijl15'

function 

return jpg
