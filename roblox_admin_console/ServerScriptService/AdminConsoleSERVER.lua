--[[
	AdminConsoleSERVER.lua
	ضع هذا السكربت داخل: ServerScriptService
	مُشغّل سكربتات للإدمن فقط — يعمل داخل لعبتك أنت، وليس أداة خارجية.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local CONFIG = {
	Admins = {
		[123456789] = true, -- 👈 بدّل هذا برقم UserId الخاص بك / الإدمن
		-- [987654321] = true, -- أضف إدمن آخر هنا
	},
	MaxCodeLength = 20000,
	Cooldown = 0.2,
	ClientScriptLifetime = 0, -- 0 = لا يُحذف تلقائياً (عدّله لو تبي تنظيف)
}

-- loadstring معطّل افتراضياً في Roblox، نفعّله هنا (ويفضّل تفعيله يدوياً أيضاً من الخصائص)
pcall(function()
	game:GetService("ServerScriptService").LoadStringEnabled = true
end)

local folder = ReplicatedStorage:FindFirstChild("AdminConsole")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "AdminConsole"
	folder.Parent = ReplicatedStorage
end

local function remote(name, class)
	local r = folder:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = folder
	end
	return r
end

local Ready   = remote("Ready", "RemoteEvent")
local Auth    = remote("Auth", "RemoteEvent")
local RunReq  = remote("Run", "RemoteEvent")
local RunResp = remote("Response", "RemoteEvent")

local function isAdmin(player)
	return CONFIG.Admins[player.UserId] == true
end

local function serialize(value, depth)
	depth = depth or 0
	if depth > 3 then return "…" end
	local kind = typeof(value)
	if kind == "nil" then return "nil" end
	if kind == "string" then
		return '"' .. value:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
	elseif kind == "number" or kind == "boolean" then
		return tostring(value)
	elseif kind == "Instance" then
		return value:GetFullName()
	elseif kind == "table" then
		local items, count = {}, 0
		for k, v in pairs(value) do
			if count >= 12 then break end
			count += 1
			items[#items + 1] = tostring(k) .. " = " .. serialize(v, depth + 1)
		end
		return "{" .. table.concat(items, ", ") .. "}"
	end
	return tostring(value)
end

-- السيرفر يرسل تأكيد الصلاحية فقط للإدمن (العميل ما يقرر بنفسه)
Ready.OnServerEvent:Connect(function(player)
	if isAdmin(player) then
		Auth:FireClient(player, true)
	end
end)

local lastRun = {}

RunReq.OnServerEvent:Connect(function(player, code, target)
	if not isAdmin(player) then
		warn("[AdminConsole] محاولة غير مصرّحة من " .. player.Name .. " (" .. player.UserId .. ")")
		return
	end

	if type(code) ~= "string" or code:gsub("%s", "") == "" then
		RunResp:FireClient(player, false, "⚠️ اكتب كود أولاً.")
		return
	end
	if #code > CONFIG.MaxCodeLength then
		RunResp:FireClient(player, false, "⚠️ الكود طويل جداً (الحد " .. CONFIG.MaxCodeLength .. ").")
		return
	end

	local now = os.clock()
	if lastRun[player] and now - lastRun[player] < CONFIG.Cooldown then
		RunResp:FireClient(player, false, "⏳ انتظر ثانية بين التشغيلات.")
		return
	end
	lastRun[player] = now

	-- ================= تنفيذ على العميل =================
	-- نزرع LocalScript داخل PlayerGui (لأن loadstring غير متاح للعميل في Roblox)
	if target == "client" then
		local pg = player:WaitForChild("PlayerGui")
		local holder = pg:FindFirstChild("AdminConsoleScripts")
		if not holder then
			holder = Instance.new("Folder")
			holder.Name = "AdminConsoleScripts"
			holder.Parent = pg
		end
		for _, old in ipairs(holder:GetChildren()) do
			old:Destroy()
		end

		local ls = Instance.new("LocalScript")
		ls.Name = "AdminCode"
		ls.Source = code
		ls.Parent = holder
		if CONFIG.ClientScriptLifetime > 0 then
			Debris:AddItem(ls, CONFIG.ClientScriptLifetime)
		end

		print(string.format("[AdminConsole] %s شغّل كود على العميل:\n%s", player.Name, code))
		RunResp:FireClient(player, true,
			"✅ تم زرع الكود كلوكال سكربت في PlayerGui.\n" ..
			"مخرجات print تظهر في Output / F9 Console عند العميل.", "client")
		return
	end

	-- ================= تنفيذ على السيرفر =================
	-- نحقن print/warn محليين داخل الكود بدل ما نغيّر global print (أنظف وأأمن)
	local logs = {}
	local token = string.format("__AC_%d_%d", player.UserId, os.time() * 1000 + math.random(1, 999))
	_G[token] = logs
	_G[token .. "_ser"] = serialize

	local prefix = string.format([[
local __cap = _G[%q]
local __ser = _G[%q]
local print = function(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[i] = __ser(select(i, ...)) end
	__cap[#__cap + 1] = table.concat(parts, "\t")
end
local warn = print
]], token, token .. "_ser")

	local chunk, loadErr = loadstring(prefix .. "\n" .. code)
	local okRun, result
	if chunk then
		okRun, result = pcall(chunk)
	else
		okRun, result = false, loadErr
	end

	_G[token] = nil
	_G[token .. "_ser"] = nil

	local out = {}
	if #logs > 0 then out[#out + 1] = table.concat(logs, "\n") end
	if result ~= nil then out[#out + 1] = "=> " .. serialize(result) end
	local text = table.concat(out, "\n")
	if not okRun then
		text = (text ~= "" and text .. "\n" or "") .. "❌ " .. tostring(result)
	end
	if text == "" then text = "✅ تم التنفيذ بدون مخرجات." end

	print(string.format("[AdminConsole] %s شغّل:\n%s\n---\n%s", player.Name, code, text))
	RunResp:FireClient(player, okRun, text, "server")
end)
