local slk = {}

local function split(str, p)
	local rt = {}
	string.gsub(str, '[^'..p..']+', function (w) table.insert(rt, w) end)
	return rt
end

local function trim(str) 
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

string.trim = trim

local function slk_value(v)
	-- 34 == '"'
	v = trim(v)
	if v:byte(1) == 34 and v:byte(-1) == 34 then
		return v:sub(2, -2)
	else
		return tonumber(v)
	end
end

function slk:line_c(l)
	for i, v in ipairs(l) do
		if i ~= 1 then
			if v:byte(1) == 75 then
				-- K
				if self.x == 1 then
					self.row[self.y] = slk_value(v:sub(2, -1))
				elseif self.y == 1 then
					self.col[self.x] = slk_value(v:sub(2, -1))
				else
					table.insert(self.list, {self.x, self.y, slk_value(v:sub(2, -1))})
				end
			elseif v:byte(1) == 88 then
				-- X
				self.x = tonumber(v:sub(2, -1))
			elseif v:byte(1) == 89 then
				-- y
				self.y = tonumber(v:sub(2, -1))
			end
		end
	end
end

function slk:load_begin()
	self.row = {}
	self.col = {}
	self.list = {}
	self.x = 0
	self.y = 0
end

function slk:load_end(c)
	local tbl = {}
	if c then
		for _, v in pairs(self.col) do
			tbl[v] = {}
		end
		for _, v in pairs(self.list) do
			tbl[self.col[v[1]]][self.row[v[2]]] = v[3]
		end
	else
		for _, v in pairs(self.row) do
			tbl[v] = {}
		end
		for _, v in pairs(self.list) do
			tbl[self.row[v[2]]][self.col[v[1]]] = v[3]
		end
	end
	return tbl
end

function slk:loadfile(filename, c)
	local f, e = io.open(filename:string(), "rb")
	if not f then
		return nil, e
	end
	if 'ID;PWXL;N;E' ~= f:read('l'):sub(1, 11) then
		f:close()
		return nil, 'slk data corrupted.'
	end
	self:load_begin()
	for line in f:lines() do
		local l = split(line, ';')
		if     l[1] == 'B' then
		elseif l[1] == 'C' then
			self:line_c(l)
		elseif l[1] == 'E' then
			break
		elseif l[1] == 'F' then
		else
		end
	end
	local tbl = self:load_end(c)
	f:close()
	return tbl
end

function slk:loadstring(str, c)
	self:load_begin()
	for i, line in ipairs(split(str, '\n')) do
		if i == 1 then
			if 'ID;PWXL;N;E' ~= line:sub(1, 11) then
				return nil, 'slk data corrupted.'
			end
		else
			local l = split(line, ';')
			if     l[1] == 'B' then
			elseif l[1] == 'C' then
				self:line_c(l)
			elseif l[1] == 'E' then
				break
			elseif l[1] == 'F' then
			else
			end
		end
	end
	return self:load_end(c)
end

function slk:loadtxt(path)
	local f, e = io.open(path:string(), "r")
	if not f then
		return nil, e
	end
	local tbl = {}
	local section = nil
	for line in f:lines() do
		line = string.trim(line)
		if string.sub(line,1,1) == "[" then
			section = string.trim(string.sub(line, 2, string.len(line) - 1 ))
			tbl[section] = {}
		elseif string.sub(line,1,2) == "//" then
		elseif line ~= "" then
			local key = string.trim(string.sub(line, 1, string.find(line, "=") - 1))
			local value = string.trim(string.sub(line, string.find(line, "=") + 1))
			tbl[section][key] = value or ""
		end
	end
	f:close()
	return tbl
end

return slk

