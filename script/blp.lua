
local jpg = require 'jpg'

-- https://github.com/actboy168/py-warcraft3/blob/master/blp.py

local _BLP1 = 0x31504C42
local _BLP_HEADER_SIZE = 156
local _BLP_PALETTE_SIZE = 1024

local function ReadUInt32(data, offset)
    return string.unpack('<I', data, offset + 1)
end

local function MipMap(data, index)
    return ReadUInt32(data, 28+index*4), ReadUInt32(data, 92+index*4)
end

local function LoadCompressed(data)
    local JpegHeaderSize = ReadUInt32(data, _BLP_HEADER_SIZE)
	local Offset, Size = MipMap(data, 0)
	local parser = jpg.parser()
    parser:feed(data:sub(_BLP_HEADER_SIZE+5, _BLP_HEADER_SIZE+4+JpegHeaderSize))
    parser:feed(data:sub(Offset+1,Offset+Size))
    return parser:get()
end

local function Reader(data)
    if (#data < _BLP_HEADER_SIZE) then
        return nil
    end

    local MagicNumber, Compression, _, Width, Height, PictureType, _ = string.unpack('<IIIIIII', data)

    if (_BLP1 ~= MagicNumber) then
	    print('[错误] _BLP1错误')
        return nil
    end

    if (Compression == 0) then
        return LoadCompressed(data)
    elseif (Compression == 1) then
    	print('[错误] 暂不支持该类型的blp')
        --return LoadUncompressed(Width, Height, PictureType, data)
    else
        print('[错误] Compression错误')
        return nil
    end
end

local function Convert(src, dst)
	local f = io.open(src:string(), 'rb')
	if not f then
		print('[错误] 文件打开失败', src:string())
		return false
	end
	local content = f:read 'a'
	f:close()
	if not content then
		print('[错误] 文件读取失败', src:string())
		return false
	end
   	local img = Reader(content)
    if not img then
	    print('[错误] 文件转换失败', src:string())
	    return false
    end
    local f = io.open(dst:string(), 'wb')
    if not f then
    	print('[错误] 文件创建失败', dst:string())
    	return false
    end
    f:write(img)
    f:close()
    return true
end

return Convert
