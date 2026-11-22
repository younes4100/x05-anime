--[[
	AdminConsoleCLIENT.lua
	ضع هذا اللوكال سكربت داخل: StarterPlayerScripts
	لا تظهر الواجهة إلا بعد ما السيرفر يأكد أن اللاعب إدمن.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("AdminConsole")
local Ready = folder:WaitForChild("Ready")
local Auth = folder:WaitForChild("Auth")
local RunReq = folder:WaitForChild("Run")
local RunResp = folder:WaitForChild("Response")

local authorized = false
local screenGui

local WHITE = Color3.fromRGB(255, 255, 255)

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
end

local function buildUI()
	if screenGui then return end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminConsoleGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local main = Instance.new("Frame")
	main.Size = UDim2.new(0, 620, 0, 440)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
	main.BorderSizePixel = 0
	main.Parent = screenGui
	corner(main, 12)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 90, 220)
	stroke.Thickness = 2
	stroke.Parent = main

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 44)
	header.BackgroundTransparency = 1
	header.Text = "  🛠  ADMIN CONSOLE  •  X05"
	header.TextColor3 = Color3.fromRGB(235, 235, 255)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Font = Enum.Font.GothamBold
	header.TextSize = 17
	header.Parent = main

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 32, 0, 28)
	close.Position = UDim2.new(1, -40, 0, 8)
	close.BackgroundColor3 = Color3.fromRGB(200, 60, 80)
	close.Text = "✕"
	close.TextColor3 = WHITE
	close.Font = Enum.Font.GothamBold
	close.TextSize = 14
	close.Parent = main
	corner(close, 6)
	close.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
	end)

	-- سحب النافذة من الهيدر
	local dragging, dragStart, startPos
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	local targetBtn = Instance.new("TextButton")
	targetBtn.Size = UDim2.new(0, 130, 0, 30)
	targetBtn.Position = UDim2.new(0, 14, 0, 50)
	targetBtn.BackgroundColor3 = Color3.fromRGB(90, 70, 170)
	targetBtn.TextColor3 = WHITE
	targetBtn.Font = Enum.Font.GothamBold
	targetBtn.TextSize = 12
	targetBtn.Parent = main
	corner(targetBtn, 6)

	local target = "server"
	local function refreshTarget()
		targetBtn.Text = target == "server" and "🖥 SERVER" or "👤 CLIENT"
		targetBtn.BackgroundColor3 = target == "server"
			and Color3.fromRGB(90, 70, 170) or Color3.fromRGB(40, 140, 150)
	end
	refreshTarget()
	targetBtn.MouseButton1Click:Connect(function()
		target = target == "server" and "client" or "server"
		refreshTarget()
	end)

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, -160, 0, 30)
	hint.Position = UDim2.new(0, 154, 0, 50)
	hint.BackgroundTransparency = 1
	hint.Text = "F2 لفتح/إغلاق  •  استخدم return لإظهار النتيجة"
	hint.TextColor3 = Color3.fromRGB(160, 165, 190)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 11
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = main

	local codeBox = Instance.new("TextBox")
	codeBox.Size = UDim2.new(1, -28, 0, 170)
	codeBox.Position = UDim2.new(0, 14, 0, 90)
	codeBox.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	codeBox.TextColor3 = Color3.fromRGB(180, 255, 210)
	codeBox.PlaceholderColor3 = Color3.fromRGB(90, 95, 120)
	codeBox.PlaceholderText = 'print("مرحباً")\nreturn game.Workspace.Name'
	codeBox.Text = ""
	codeBox.Font = Enum.Font.Code
	codeBox.TextSize = 13
	codeBox.TextXAlignment = Enum.TextXAlignment.Left
	codeBox.TextYAlignment = Enum.TextYAlignment.Top
	codeBox.MultiLine = true
	codeBox.ClearTextOnFocus = false
	codeBox.Parent = main
	corner(codeBox, 8)

	local runBtn = Instance.new("TextButton")
	runBtn.Size = UDim2.new(0, 120, 0, 34)
	runBtn.Position = UDim2.new(0, 14, 0, 270)
	runBtn.BackgroundColor3 = Color3.fromRGB(70, 180, 110)
	runBtn.TextColor3 = WHITE
	runBtn.Text = "▶ RUN"
	runBtn.Font = Enum.Font.GothamBold
	runBtn.TextSize = 13
	runBtn.Parent = main
	corner(runBtn, 8)

	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = UDim2.new(0, 100, 0, 34)
	clearBtn.Position = UDim2.new(0, 144, 0, 270)
	clearBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 100)
	clearBtn.TextColor3 = WHITE
	clearBtn.Text = "CLEAR"
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 13
	clearBtn.Parent = main
	corner(clearBtn, 8)

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -270, 0, 34)
	status.Position = UDim2.new(0, 256, 0, 270)
	status.BackgroundTransparency = 1
	status.Text = "جاهز."
	status.TextColor3 = Color3.fromRGB(160, 165, 190)
	status.Font = Enum.Font.Gotham
	status.TextSize = 11
	status.TextXAlignment = Enum.TextXAlignment.Right
	status.Parent = main

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -28, 0, 118)
	scroll.Position = UDim2.new(0, 14, 0, 314)
	scroll.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = main
	corner(scroll, 8)

	local output = Instance.new("TextLabel")
	output.Size = UDim2.new(1, -12, 0, 20)
	output.Position = UDim2.new(0, 6, 0, 4)
	output.BackgroundTransparency = 1
	output.TextColor3 = Color3.fromRGB(200, 230, 255)
	output.Font = Enum.Font.Code
	output.TextSize = 12
	output.TextXAlignment = Enum.TextXAlignment.Left
	output.TextYAlignment = Enum.TextYAlignment.Top
	output.TextWrapped = true
	output.Text = "..."
	output.Parent = scroll

	runBtn.MouseButton1Click:Connect(function()
		local code = codeBox.Text
		if code:gsub("%s", "") == "" then
			status.Text = "⚠️ مافي كود."
			return
		end
		status.Text = "⏳ جاري التنفيذ..."
		runBtn.BackgroundColor3 = Color3.fromRGB(150, 120, 40)
		RunReq:FireServer(code, target)
	end)

	clearBtn.MouseButton1Click:Connect(function()
		codeBox.Text = ""
		output.Text = ""
	end)

	RunResp.OnClientEvent:Connect(function(ok, text, where)
		output.Text = (where == "client" and "[CLIENT] " or "[SERVER] ") .. tostring(text)
		output.Size = UDim2.new(1, -12, 0, math.max(output.TextBounds.Y, 20))
		scroll.CanvasSize = UDim2.new(0, 0, 0, output.TextBounds.Y + 12)
		status.Text = ok and "✅ تم" or "❌ خطأ"
		runBtn.BackgroundColor3 = Color3.fromRGB(70, 180, 110)
	end)
end

-- السيرفر هو اللي يقرر من إدمن؛ العميل ما عنده قائمة صلاحيات
Auth.OnClientEvent:Connect(function(ok)
	if ok and not authorized then
		authorized = true
		buildUI()
		screenGui.Enabled = true
	end
end)

Ready:FireServer()

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not authorized or not screenGui then return end
	if input.KeyCode == Enum.KeyCode.F2 then
		screenGui.Enabled = not screenGui.Enabled
	end
end)
