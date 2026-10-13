-- ignis_fuzzer.lua
-- Stress/fuzz test for the Ignis library.
-- Repeatedly builds random UIs, holds them, destroys them, and logs
-- any errors or unexpected behaviour to a writefile on disk.

local LOG_FILE      = "ignis_fuzz_log.txt"
local ITERATIONS    = 50        -- total build→destroy cycles
local HOLD_TIME     = 2.0       -- seconds to keep each UI alive
local BETWEEN_DELAY = 0.8       -- seconds between destroy and next build

-- ── Logger ────────────────────────────────────────────────────────────────
local _lines: {string} = {}
local function log(msg: string)
	local ts = tostring(os.time())
	local line = string.format("[t=%s] %s", ts, msg)
	table.insert(_lines, line)
	print(line)
	if writefile then
		pcall(writefile, LOG_FILE, table.concat(_lines, "\n"))
	end
end

-- ── RNG helpers ────────────────────────────────────────────────────────────
local rng = Random.new()
local function ri(a, b) return rng:NextInteger(a, b) end
local function rf()      return rng:NextNumber()      end
local function pick(t: {any}) return t[ri(1, #t)] end
local function maybe(p: number) return rf() < p end
local function uid() return "e" .. tostring(ri(100000, 999999)) end

-- ── Vocabulary ─────────────────────────────────────────────────────────────
local TITLES   = { "NEXUS", "CIPHER", "VORTEX", "APEX", "PHANTOM", "IGNIS", "EMBER", "FLARE" }
local TAB_L    = { "Combat", "Movement", "Visual", "Farming", "Misc", "Settings", "Exploit", "Tools", "Aimbot", "ESP" }
local TAB_R    = { "Player", "Config", "Credits", "Debug", "Info" }
local NAMES    = {
	"Speed Boost", "Auto Farm", "God Mode", "Fly Speed", "Jump Power",
	"Kill Aura", "ESP Range", "Walk Speed", "Inf Stamina", "Fast Attack",
	"Teleport", "No Clip", "Auto Click", "Spam Attack", "Aim Assist",
	"Hit Box", "Silent Aim", "Radar", "Bhop", "Anti Cheat Bypass",
	"Fling", "Loop Kill", "Fake Lag", "Spread", "Triggerbot",
}
local DESCS    = {
	"Enables the feature when active",
	"Adjusts the intensity level",
	"Configure this behaviour",
	"Only applies in game servers",
	"May cause detection — use with care",
}
local OPT_SETS = {
	{ "Disabled", "Low", "Medium", "High", "Ultra" },
	{ "Off", "On", "Auto" },
	{ "Red", "Green", "Blue", "Yellow", "White" },
	{ "1x", "2x", "5x", "10x", "50x" },
	{ "Slow", "Normal", "Fast", "Instant" },
	{ "None", "Players", "NPCs", "All" },
}
local KEYS     = {
	Enum.KeyCode.F1, Enum.KeyCode.F2, Enum.KeyCode.F3,
	Enum.KeyCode.Z,  Enum.KeyCode.X,  Enum.KeyCode.C, Enum.KeyCode.V,
	Enum.KeyCode.G,  Enum.KeyCode.H,  Enum.KeyCode.J,
}

-- ── Load library ─────────────────────────────────────────────────────────
log("=== Ignis Fuzz Test Started ===")
log("Loading Ignis...")

local loadOk, Ignis = xpcall(function()
	return loadstring(game:HttpGet(
		"https://raw.githubusercontent.com/ScriptB/Ignis/main/Ignis.lua"
	))()
end, debug.traceback)

if not loadOk then
	log("FATAL: Library failed to load:\n" .. tostring(Ignis))
	return
end
log("Library loaded OK")

-- ── Build a randomised UI and return (Window, errorList, counts) ──────────
local function buildRandom(iter: number): (any, {string}, {tabs: number, elems: number})
	local errs: {string} = {}
	local counts = { tabs = 0, elems = 0 }

	local function caught(label: string, fn: () -> any): (boolean, any)
		local ok, v = xpcall(fn, debug.traceback)
		if not ok then table.insert(errs, string.format("[%s] %s", label, tostring(v))) end
		return ok, v
	end

	-- CreateWindow
	local winOk, Window = caught("CreateWindow", function()
		return Ignis:CreateWindow({
			Title       = pick(TITLES),
			MinimizeKey = Enum.KeyCode.RightShift,
		})
	end)
	if not winOk then return nil, errs, counts end

	-- Left tabs
	local leftN = ri(2, 6)
	local tabObjs: {any} = {}
	for i = 1, leftN do
		local ok, tab = caught("Tab.Left." .. i, function()
			return Window:Tab(pick(TAB_L))
		end)
		if ok then counts.tabs += 1; table.insert(tabObjs, tab) end
	end

	-- Right utility tabs (sometimes none)
	local rightN = ri(0, 3)
	for i = 1, rightN do
		local ok, tab = caught("Tab.Right." .. i, function()
			return Window:Tab(pick(TAB_R), { Side = "right" })
		end)
		if ok then counts.tabs += 1; table.insert(tabObjs, tab) end
	end

	-- Fill each tab with sections + elements
	for ti, tab in ipairs(tabObjs) do
		local secN = ri(1, 3)
		for si = 1, secN do
			local secOk, sec = caught(string.format("Section[%d][%d]", ti, si), function()
				return tab:Section()
			end)
			if not secOk then continue end

			local elemN = ri(2, 10)
			for ei = 1, elemN do
				local kind    = ri(1, 7)
				local hasDesc = maybe(0.30)
				local name    = pick(NAMES)
				local desc    = hasDesc and pick(DESCS) or nil
				local id      = uid()
				local label   = string.format("Elem[%d][%d][%d](kind=%d)", ti, si, ei, kind)

				local ok = caught(label, function()
					if kind == 1 then
						sec:Toggle({
							Id       = id, Name = name, Description = desc,
							Default  = maybe(0.5),
							Callback = function(_v) end,
						})
					elseif kind == 2 then
						local maxV = ri(10, 500)
						sec:Slider({
							Id       = id, Name = name, Description = desc,
							Min = 0, Max = maxV, Step = 1, Default = ri(0, maxV),
							Callback = function(_v) end,
						})
					elseif kind == 3 then
						local opts = pick(OPT_SETS)
						sec:Dropdown({
							Id       = id, Name = name, Description = desc,
							Options  = opts, Default = opts[1],
							Multi    = maybe(0.2),
							Callback = function(_v) end,
						})
					elseif kind == 4 then
						sec:Button({
							Id       = id, Name = name, Description = desc,
							Callback = function() end,
						})
					elseif kind == 5 then
						sec:Input({
							Id          = id, Name = name, Description = desc,
							Placeholder = "Enter value…",
							Callback    = function(_v) end,
						})
					elseif kind == 6 then
						sec:Keybind({
							Id       = id, Name = name, Description = desc,
							Default  = pick(KEYS),
							Callback = function(_k) end,
						})
					else
						sec:Label({
							Id = id, Name = name,
							Value = tostring(ri(0, 9999)),
						})
					end
				end)
				if ok then counts.elems += 1 end
			end
		end
	end

	-- Occasionally fire a notification
	if maybe(0.4) then
		caught("Notify", function()
			Window:Notify({
				Title    = "Fuzz Test",
				Message  = "Iteration " .. iter,
				Duration = 1.2,
			})
		end)
	end

	return Window, errs, counts
end

-- ── Main loop ──────────────────────────────────────────────────────────────
local allErrors: {string} = {}
local destroyOk  = 0
local destroyFail = 0

for iter = 1, ITERATIONS do
	log(string.format("\n=== ITER %d / %d ===", iter, ITERATIONS))

	local t0 = tick()
	local Window, buildErrs, counts = buildRandom(iter)
	local buildMs = math.round((tick() - t0) * 1000)

	for _, e in ipairs(buildErrs) do
		table.insert(allErrors, string.format("[iter=%d] %s", iter, e))
	end

	if Window then
		log(string.format("  Built: %d tabs  %d elems  %dms  build_errors=%d",
			counts.tabs, counts.elems, buildMs, #buildErrs))

		task.wait(HOLD_TIME)

		local dOk, dErr = xpcall(function() Window:Destroy() end, debug.traceback)
		if dOk then
			destroyOk += 1
			log("  Destroyed: OK")
		else
			destroyFail += 1
			local msg = string.format("[iter=%d] Destroy: %s", iter, tostring(dErr))
			table.insert(allErrors, msg)
			log("  Destroyed: FAILED — " .. tostring(dErr))
		end
	else
		log("  Build returned nil — skipping destroy")
	end

	task.wait(BETWEEN_DELAY)
end

-- ── Final report ──────────────────────────────────────────────────────────
log("\n=== FINAL REPORT ===")
log(string.format("Iterations      : %d", ITERATIONS))
log(string.format("Destroy OK      : %d", destroyOk))
log(string.format("Destroy FAILED  : %d", destroyFail))
log(string.format("Total errors    : %d", #allErrors))

if #allErrors > 0 then
	log("--- Errors ---")
	for i, e in ipairs(allErrors) do
		log(string.format("  [%d] %s", i, e))
	end
else
	log("No errors found — all iterations clean.")
end

log("=== End ===")

if writefile then
	writefile(LOG_FILE, table.concat(_lines, "\n"))
	print("[Fuzzer] Full log written to " .. LOG_FILE)
else
	print("[Fuzzer] writefile unavailable — log only in console")
end
