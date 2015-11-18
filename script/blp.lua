
local ImageFile = require 'jpg'

-- https://github.com/actboy168/py-warcraft3/blob/master/blp.py

local _BLP1 = 0x31504C42
local _BLP_HEADER_SIZE = 156 / 4
local _BLP_PALETTE_SIZE = 1024 / 4

local function ReadUInt32(data, offset)
    return string.unpack('<I', data, offset + 1)
end

local function MipMap(data, index)
    return ReadUInt32(data, 7+index), ReadUInt32(data, 23+index)
end

local function LoadCompressed(data)
    local JpegHeaderSize = ReadUInt32(data, _BLP_HEADER_SIZE)
	local Offset, Size = MipMap(data, 0)
	local parser = ImageFile.Parser()
    parser:feed(data:sub(_BLP_HEADER_SIZE+2, _BLP_HEADER_SIZE+1+JpegHeaderSize/4))
    parser:feed(data:sub(Offset+1,Offset/4+Size/4)
    local img = parser:close():convert('RGB')
    local r, g, b = img:split()
    return Image.merge("RGB", (b, g, r))
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
   	local img = Reader(open(src, 'rb').read())
    if img then
        img:save(dst)
        return true
    end
    return false
end