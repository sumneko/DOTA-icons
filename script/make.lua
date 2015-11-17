
local map_dir	= arg[1] or ''
local root_dir	= arg[2] or ''

--添加require搜寻路径
package.path = package.path .. ';' .. root_dir .. 'script\\?.lua'
package.cpath = package.cpath .. ';' .. root_dir .. 'build\\?.dll'

require 'luabind'
require 'filesystem'
require 'utility'
require 'stormlib'
require 'localization'

if not arg or #arg < 2 then
	print '笨蛋,把地图拖到bat里来导出啊'
	return
end

local real_print = print

local function print(...)
	local args = {...}
	for i = 1, #args do
		args[i] = utf8_to_ansi(tostring(args[i]))
	end
	return real_print(table.unpack(args))
end

local function read_ini()
	local path = fs.path(root_dir) / '配置文件.ini'
	local content = io.load(path)
	local tbl = {}
	if content then
		content = ansi_to_utf8(content)
		for key, value in content:gmatch '(%C-)%=(%C+)' do
			tbl[key] = value
		end
	end
	return tbl
end

local race_list = 'campaign common human neutral nightelf orc undead'
local cate_list = 'unit ability'

local function main()
	local ini			= read_ini()
	local input_map		= fs.path(map_dir)
	local root_dir		= fs.path(root_dir)
	local output_dir	= root_dir / 'output'
	local temp_dir		= root_dir / 'temp'
	local war3_dir		= ini['魔兽目录']
	if not war3_dir then
		print('配置文件错误,没有找到[魔兽目录]一项')
		return
	end
	local mpq_dir		= fs.path(war3_dir) / 'war3.mpq' 

	fs.create_directories(output_dir)
	fs.create_directories(temp_dir)

	local map = mpq_open(input_map)
	local mpq = mpq_open(mpq_dir)
	if not map then
		print('地图打开失败,请确认文件是否被占用')
		return
	end
	if not mpq then
		print('mpq打开失败,请确认魔兽路径是否配置正确')
		return
	end
	--导出slk文件
	local slk_dir = fs.path 'units'
	for race in race_list:gmatch '%S+' do
		for cate in cate_list:gmatch '%S+' do
			local name = race .. cate .. 'func.txt'
			local res = map:extract(slk_dir / name, (temp_dir / name):string())
			print(res)
		end
	end
end

main()
