local HttpService = game:GetService("HttpService")

local function getExecutorEnv(): any
	local ok, env = pcall(function()
		return (getgenv :: any)()
	end)
	if ok and type(env) == "table" then
		return env
	end
	return _G
end

local function serializeOptionValue(v: any): any
	if typeof(v) == "EnumItem" then
		return (v :: EnumItem).Name
	end
	return v
end

local function stripConfigPath(path: string, folder: string): string?
	local cleanPath = string.gsub(path, "\\", "/")
	local cleanFolder = string.gsub(folder, "\\", "/") .. "/"
	local prefix = string.sub(cleanPath, 1, #cleanFolder)
	if prefix == cleanFolder then
		cleanPath = string.sub(cleanPath, #cleanFolder + 1)
	end
	if string.sub(cleanPath, -5) == ".json" then
		return string.sub(cleanPath, 1, -6)
	end
	return nil
end

return function(Library: any)
	local SaveManager: any = {
		_folder = "IgnisConfigs",
		_key = "default",
		_autoStop = nil,
		_saveSubs = {},
		_loadSubs = {},
	}

	function SaveManager:SetFolder(folder: string)
		self._folder = folder
	end

	function SaveManager:SetKey(key: string)
		self._key = key
	end

	function SaveManager:GetData(): {[string]: any}
		local out: {[string]: any} = {}
		local options = Library.Options or {}
		for id, el in pairs(options) do
			local ok, v = pcall(function()
				return el:Get()
			end)
			if ok and v ~= nil then
				out[id] = serializeOptionValue(v)
			end
		end
		return out
	end

	function SaveManager:SetData(data: {[string]: any})
		local options = Library.Options or {}
		for id, v in pairs(data) do
			local el = options[id]
			if el and el.Set then
				pcall(function()
					el:Set(v)
				end)
			end
		end
		for _, fn in ipairs(self._loadSubs) do
			xpcall(fn, debug.traceback)
		end
	end

	function SaveManager:Save(key: string?): boolean
		local genv = getExecutorEnv()
		local wf = rawget(genv, "writefile")
		if not wf then
			return false
		end
		local mf = rawget(genv, "makefolder")
		if mf then
			pcall(mf, self._folder)
		end
		local k = key or self._key
		local ok, enc = pcall(function()
			return HttpService:JSONEncode(self:GetData())
		end)
		if not ok then
			return false
		end
		local ok2 = pcall(wf, self._folder .. "/" .. k .. ".json", enc)
		if ok2 then
			for _, fn in ipairs(self._saveSubs) do
				xpcall(fn, debug.traceback)
			end
		end
		return ok2
	end

	function SaveManager:Load(key: string?): boolean
		local genv = getExecutorEnv()
		local rf = rawget(genv, "readfile")
		if not rf then
			return false
		end
		local isf = rawget(genv, "isfile")
		local k = key or self._key
		local path = self._folder .. "/" .. k .. ".json"
		if isf then
			local ok, res = pcall(isf, path)
			if not ok or not res then
				return false
			end
		end
		local ok, raw = pcall(rf, path)
		if not ok or type(raw) ~= "string" or raw == "" then
			return false
		end
		local ok2, data = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if not ok2 or type(data) ~= "table" then
			return false
		end
		self:SetData(data)
		return true
	end

	function SaveManager:Delete(key: string?): boolean
		local genv = getExecutorEnv()
		local df = rawget(genv, "delfile") or rawget(genv, "deletefile")
		if not df then
			return false
		end
		local k = key or self._key
		return pcall(df, self._folder .. "/" .. k .. ".json")
	end

	function SaveManager:ListConfigs(): {string}
		local genv = getExecutorEnv()
		local lf = rawget(genv, "listfiles")
		if not lf then
			return {}
		end
		local ok, files = pcall(lf, self._folder)
		if not ok or type(files) ~= "table" then
			return {}
		end
		local names = {}
		for _, file in ipairs(files) do
			local name = stripConfigPath(tostring(file), self._folder)
			if name then
				table.insert(names, name)
			end
		end
		table.sort(names)
		return names
	end

	function SaveManager:AutoLoad(name: string): boolean
		return self:Load(name)
	end

	function SaveManager:AutoSave(interval: number)
		self:StopAutoSave()
		local running = true
		self._autoStop = function()
			running = false
		end
		task.spawn(function()
			while running do
				self:Save()
				local elapsed = 0
				local step = math.min(0.5, interval)
				while running and elapsed < interval do
					task.wait(step)
					elapsed += step
				end
			end
		end)
	end

	function SaveManager:StopAutoSave()
		if self._autoStop then
			self._autoStop()
			self._autoStop = nil
		end
	end

	function SaveManager:OnSave(fn: () -> ()): () -> ()
		table.insert(self._saveSubs, fn)
		return function()
			for i, f in ipairs(self._saveSubs) do
				if f == fn then
					table.remove(self._saveSubs, i)
					break
				end
			end
		end
	end

	function SaveManager:OnLoad(fn: () -> ()): () -> ()
		table.insert(self._loadSubs, fn)
		return function()
			for i, f in ipairs(self._loadSubs) do
				if f == fn then
					table.remove(self._loadSubs, i)
					break
				end
			end
		end
	end

	Library.SaveManager = SaveManager
	function Library:GetSaveManager(): any
		return SaveManager
	end

	return SaveManager
end
