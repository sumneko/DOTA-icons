
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

local function log(...)
	print('[' .. os.clock() .. ']', ...)
end

if not arg or #arg < 2 then
	print '[错误] 笨蛋,把地图拖到bat里来导出啊'
	return
end

local function read_ini()
	local path = fs.path(root_dir) / '配置文件.ini'
	local content = io.load(path)
	local tbl = {}
	if content then
		for key, value in content:gmatch '(%C-)%=(%C+)' do
			tbl[key] = value
		end
	end
	return tbl
end

local function add_slk(data, new)
	for k, new_v in pairs(new) do
		local data_v = data[k]
		if not data_v then
			data_v = {}
			data[k] = data_v
		end
		if type(data_v) == 'table' and type(new_v) == 'table' then
			for ck, v in pairs(new_v) do
				data_v[ck] = v
			end
		end
	end
end

local race_list = 'campaign common human neutral nightelf orc undead'
local cate_list = 'unit ability'
local cate2_list = 'func strings'
local slk_list = 'unitabilities abilitydata'

local function main()
	local slk			= require 'slk'
	local ini			= read_ini()
	local input_map		= fs.path(map_dir)
	local root_dir		= fs.path(root_dir)
	local output_dir	= root_dir / 'output'
	local temp_dir		= root_dir / 'temp'
	local war3_dir		= ini['魔兽目录']
	if not war3_dir then
		print('[错误] 配置文件错误,没有找到[魔兽目录]一项')
		return
	end
	local mpq_dir		= fs.path(war3_dir) / 'war3.mpq' 
	local mpqx_dir		= fs.path(war3_dir) / 'war3x.mpq' 

	fs.create_directories(output_dir)
	fs.create_directories(temp_dir)

	log '初始化完毕,开始打开文件'

	local map = mpq_open(input_map)
	local mpq = mpq_open(mpq_dir)
	local mpqx = mpq_open(mpqx_dir)
	if not map then
		print('[错误] 地图打开失败,请确认文件是否被占用')
		return
	end
	if not mpq then
		print('[错误] mpq打开失败,请确认魔兽路径是否配置正确')
		return
	end

	log '文件打开完毕,开始解析slk'

	local slk_dir = fs.path 'units'
	local datas = {}
	--读取txt文件
	for race in race_list:gmatch '%S+' do
		for cate in cate_list:gmatch '%S+' do
			for cate2 in cate2_list:gmatch '%S+' do
				local name = race .. cate .. cate2 .. '.txt'
				local res = mpq:extract((slk_dir / name):string(), temp_dir / name)
				if res then
					local slk_data = slk:loadtxt(temp_dir / name)
					add_slk(datas, slk_data)
				end
				local res = mpqx:extract((slk_dir / name):string(), temp_dir / name)
				if res then
					local slk_data = slk:loadtxt(temp_dir / name)
					add_slk(datas, slk_data)
				end
				local res = map:extract((slk_dir / name):string(), temp_dir / name)
				if res then
					local slk_data = slk:loadtxt(temp_dir / name)
					add_slk(datas, slk_data)
				end
			end
		end
	end
	--读取slk文件
	for name in slk_list:gmatch '%S+' do
		local name = name .. '.slk'
		local res = mpq:extract((slk_dir / name):string(), temp_dir / name)
		if res then
			local slk_data = slk:loadfile(temp_dir / name)
			add_slk(datas, slk_data)
		end
		local res = mpqx:extract((slk_dir / name):string(), temp_dir / name)
		if res then
			local slk_data = slk:loadfile(temp_dir / name)
			add_slk(datas, slk_data)
		end
		local res = map:extract((slk_dir / name):string(), temp_dir / name)
		if res then
			local slk_data = slk:loadfile(temp_dir / name)
			add_slk(datas, slk_data)
		end
	end

	log 'slk解析完毕,开始搜索酒馆'

	--搜索酒馆
	local taverns = {}
	local tip = ini['酒馆标题']
	if not tip then
		print('[错误] 配置文件错误,没有找到[酒馆标题]一项')
		return
	end
	for id, data in pairs(datas) do
		if data['Tip'] == tip then
			table.insert(taverns, data)
		end
	end
	if #taverns == 0 then
		print('[错误] 没有找到任何酒馆')
		return
	end

	log '酒馆搜索完毕,开始搜索英雄'

	--搜索英雄
	local heros = {}
	for _, data in ipairs(taverns) do
		local hero_list = data['Sellunits']
		if hero_list then
			for id in hero_list:gmatch '[^,]+' do
				table.insert(heros, id)
			end
		end
	end
	if #heros == 0 then
		print('[错误] 没有找到任何英雄')
		return
	end

	log('英雄搜索完毕,共搜索到 ' .. #heros .. ' 个英雄,开始搜索图标路径')

	--搜索图标
	local hero_format = ini['英雄头像']
	local skill_format = ini['技能图标']
	if not hero_format then
		print('[错误] 配置文件错误,没有找到[英雄头像]一项')
		return
	end
	if not skill_format then
		print('[错误] 配置文件错误,没有找到[技能图标]一项')
		return
	end
	local icons = {}
	for _, id in ipairs(heros) do
		local data = datas[id]
		local dir = data['Art']
		local name = hero_format:gsub('%$(.-)%$', function(k)
			if k == '英雄名' then
				return data['Tip']
			elseif k == '英雄ID' then
				return id
			end
		end)
		icons[name] = dir
		--搜索技能
		local skill_list = data['heroAbilList']
		if not skill_list then
			print('[错误] 英雄没有技能列表:' .. id)
			return
		end
		for sid in skill_list:gmatch '[^%,]+' do
			local sdata = datas[sid]
			if not sdata then
				print('[错误] 没有找到技能:' .. sid)
				return
			end
			local dir = sdata['Art']
			local name = skill_format:gsub('%$(.-)%$', function(k)
				if k == '英雄名' then
					return data['Name']
				elseif k == '英雄ID' then
					return id
				elseif k == '技能名' then
					return sdata['Name']
				elseif k == '技能ID' then
					return sid
				end
			end)
			icons[name] = dir
		end
	end

	log '图标搜索完毕,开始导出图标'

	--导出图标
	local count = 0
	for name, dir in pairs(icons) do
		count = count + 1
		local res = map:extract(dir, output_dir / name)
		if not res then
			local res = mpq:extract(dir, output_dir / name)
			if not res then
				print('[错误] 没有找到文件或文件名错误:', dir, (output_dir / name):string())
				count = count - 1
			end
		end
	end

	log('图标导出完毕,共导出图标数:', count)
end

main()
