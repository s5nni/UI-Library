-- Library

local Library = {
	Theme = {
		Accent = Color3.fromRGB(0, 255, 0),
		TopbarColor = Color3.fromRGB(20, 20, 20),
		SidebarColor = Color3.fromRGB(15, 15, 15),
		BackgroundColor = Color3.fromRGB(10, 10, 10),
		SectionColor = Color3.fromRGB(20, 20, 20),
		TextColor = Color3.fromRGB(255, 255, 255),
	},
	Sound = {
		ID = 89087762338808,
	},
	Notif = {
		Active = {},
		Queue = {},
		IsBusy = false,
	},
	Settings = {
		ConfigPath = nil,
		MaxNotifLines = 5,
		MaxNotifStacking = 12,
		Acrylic = false,
		AcrylicBody = Instance.new("Folder"),
	},
}

-- Services

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RDS = game:GetService("ReplicatedStorage")
local RBXAS = game:GetService("RbxAnalyticsService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local TXS = game:GetService("TextService")
local HS = game:GetService("HttpService")
local MPS = game:GetService("MarketplaceService")
local VG = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Info

local ChannelName = "Unknown"
local ChannelVersion = 0
local DeviceType = "Unknown"
local HardwareId = "Unknown"

-- Variables

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local SelfModules = {UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/s5nni/UI-Library/refs/heads/main/UI.luau"))()}
local Storage = {
	
	AuthenticationConfiguration = {IsBusy = false},
	Authentication = {},
	
	Connections = {},
	Tween = {
		Cosmetic = {},
	},
}

local ListenForInput = false
local SelectedButtonTab = nil

-- Misc Functions

local function tween(...)
	local args = {...}

	if typeof(args[2]) ~= "string" then
		table.insert(args, 2, "")
	end

	local tweenObj = TS:Create(args[1], TweenInfo.new(args[3] + 0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), args[4])

	if args[2] == "Cosmetic" then
		Storage.Tween.Cosmetic[args[1]] = tweenObj

		task.spawn(function()
			task.wait(args[3])

			if Storage.Tween.Cosmetic[args[1]] == tweenObj then
				Storage.Tween.Cosmetic[args[1]] = nil
			end
		end)
	end

	tweenObj:Play()
end

local ScreenGui = SelfModules.UI.Create("ScreenGui", {
	Name = "Mitixiu UI Library",
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 0,
	ResetOnSpawn = false,
})

-- Functions

function Library:Destroy()
	-- Clean up all stored connections
	for _, conn in pairs(Storage.Connections) do
		if type(conn) == "table" then
			for _, sub in pairs(conn) do
				if sub and sub.Disconnect then sub:Disconnect() end
			end
		elseif conn and conn.Disconnect then
			conn:Disconnect()
		end
	end
	Storage.Connections = {}
	if ScreenGui and ScreenGui.Parent then
		ScreenGui:Destroy()
	end
end

function Library:GetScreenGui()
	return ScreenGui
end

function Library:Sound(id)
	if id ~= nil then
		local newId = tostring(id):gsub("%s", "")
		local numericId = tonumber(newId)
		if numericId then
			Library.Sound.ID = numericId
		else
			warn("Invalid Sound ID: must be a number")
		end
	end
end

function Library:FormatText(text1, text2, color)
	return string.format("%s <font color='%s'><b>%s</b></font>", text1, SelfModules.UI.Color.ToFormat(color), text2)
end

function Library:Arraylist()
	local TweenService = game:GetService("TweenService")
	local TWEEN_INFO   = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local ITEM_HEIGHT  = 25
	local ITEM_SPACING = 5

	local Arraylist = {
		Type   = "Arraylist",
		List   = {},    -- [key] = entry { text, value, textcolor, valuecolor, instance }
		_order = {},    -- ordered list of keys
		_style = nil,   -- { style, sort }
	}

	Arraylist.Frame = SelfModules.UI.Create("Frame", {
		Name                 = "Arraylist",
		BackgroundTransparency = 1,
		Position             = UDim2.new(0, 10, 0, 10),
		Size                 = UDim2.new(1, -20, 1, -20),
	})
	Arraylist.Frame.Parent = ScreenGui

	-- --------------------------------------------------------
	-- Internal helpers
	-- --------------------------------------------------------

	local function buildText(entry)
		local tc = entry.textcolor
		local vc = entry.valuecolor
		return string.format(
			'<font color="rgb(%d,%d,%d)">%s</font>  <font color="rgb(%d,%d,%d)">%s</font>',
			math.round(tc.R * 255), math.round(tc.G * 255), math.round(tc.B * 255), entry.text,
			math.round(vc.R * 255), math.round(vc.G * 255), math.round(vc.B * 255), entry.value
		)
	end

	local function measureWidth(entry)
		local plain = entry.text .. "  " .. entry.value
		return TXS:GetTextSize(plain, 16, Enum.Font.SourceSans, Vector2.new(1000, 1000)).X + 15
	end

	local function slotY(index)
		return (index - 1) * (ITEM_HEIGHT + ITEM_SPACING)
	end

	local function createInstance(key, entry)
		local w = measureWidth(entry)

		local Item = Instance.new("Frame")
		Item.Name             = key
		Item.AnchorPoint      = Vector2.new(1, 0)
		Item.Size             = UDim2.new(0, w, 0, ITEM_HEIGHT)
		Item.Position         = UDim2.new(1.5, 0, 0, 0)
		Item.BackgroundColor3 = Library.Theme.TopbarColor
		Item.BorderSizePixel  = 0
		Item.Parent           = Arraylist.Frame

		local UICorner = Instance.new("UICorner")
		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent       = Item

		local UIStroke = Instance.new("UIStroke")
		UIStroke.Thickness        = 1.7
		UIStroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
		UIStroke.Transparency     = 0.8
		UIStroke.Parent           = Item

		local Holder = Instance.new("Frame")
		Holder.Name             = "Holder"
		Holder.Position         = UDim2.new(0, 1, 0, 1)
		Holder.Size             = UDim2.new(1, -2, 1, -2)
		Holder.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		Holder.BorderSizePixel  = 0
		Holder.ClipsDescendants = true
		Holder.Parent           = Item

		local UICorner2 = Instance.new("UICorner")
		UICorner2.CornerRadius = UDim.new(0, 5)
		UICorner2.Parent       = Holder

		local TextLabel = Instance.new("TextLabel")
		TextLabel.Name               = "TextLabel"
		TextLabel.Size               = UDim2.new(1, -8, 1, 0)
		TextLabel.BackgroundTransparency = 1
		TextLabel.BorderSizePixel    = 0
		TextLabel.RichText           = true
		TextLabel.Text               = buildText(entry)
		TextLabel.TextColor3         = entry.textcolor
		TextLabel.TextSize           = 16
		TextLabel.FontFace           = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		TextLabel.TextXAlignment     = Enum.TextXAlignment.Right
		TextLabel.Parent             = Holder

		local Line = Instance.new("Frame")
		Line.Name             = "Line"
		Line.Position         = UDim2.new(1, -4, 0.2, 0)
		Line.Size             = UDim2.new(0, 6, 0.6, 0)
		Line.BackgroundColor3 = entry.textcolor
		Line.BorderSizePixel  = 0
		Line.Parent           = Item

		local UICorner3 = Instance.new("UICorner")
		UICorner3.CornerRadius = UDim.new(1, 0)
		UICorner3.Parent       = Line

		local ImageLabel = Instance.new("ImageLabel")
		ImageLabel.Name                  = "ImageLabel"
		ImageLabel.Position              = UDim2.new(0, -5, 0, -5)
		ImageLabel.Size                  = UDim2.new(1, 10, 1, 10)
		ImageLabel.BackgroundTransparency = 1
		ImageLabel.BorderSizePixel       = 0
		ImageLabel.ZIndex                = -1
		ImageLabel.Image                 = "rbxassetid://10822615828"
		ImageLabel.ImageColor3           = entry.textcolor
		ImageLabel.ImageTransparency     = 0.8
		ImageLabel.ScaleType             = Enum.ScaleType.Slice
		ImageLabel.SliceCenter = Rect.new(99, 99, 99, 99)
		ImageLabel.Parent                = Line

		local Glow = Instance.new("ImageLabel")
		Glow.Name                   = "Glow"
		Glow.Position               = UDim2.new(0, -5, 0, -5)
		Glow.Size                   = UDim2.new(1, 10, 1, 10)
		Glow.BackgroundTransparency = 1
		Glow.BorderSizePixel        = 0
		Glow.ZIndex                 = -1
		Glow.Image                  = "rbxassetid://10822615828"
		Glow.ImageColor3            = Library.Theme.TopbarColor
		Glow.ImageTransparency      = 0.5
		Glow.ScaleType              = Enum.ScaleType.Slice
		Glow.SliceCenter = Rect.new(99, 99, 99, 99)
		Glow.SliceScale             = 0.1
		Glow.Parent                 = Item

		return Item
	end

	-- --------------------------------------------------------
	-- Sort & reflow
	-- --------------------------------------------------------

	local function sort(self)
		local keys = {}
		for key in pairs(self.List) do
			table.insert(keys, key)
		end

		local style = self._style and self._style.style
		local s     = self._style and self._style.sort

		if style == "alphabet" then
			if s == "increasing" then
				table.sort(keys, function(a, b)
					return self.List[a].text:lower() < self.List[b].text:lower()
				end)
			elseif s == "decreasing" then
				table.sort(keys, function(a, b)
					return self.List[a].text:lower() > self.List[b].text:lower()
				end)
			end

		elseif style == "length" then
			if s == "increasing" then
				table.sort(keys, function(a, b)
					local ia = self.List[a].instance
					local ib = self.List[b].instance
					return (ia and ia.Size.X.Offset or 0) > (ib and ib.Size.X.Offset or 0)
				end)
			elseif s == "decreasing" then
				table.sort(keys, function(a, b)
					local ia = self.List[a].instance
					local ib = self.List[b].instance
					return (ia and ia.Size.X.Offset or 0) < (ib and ib.Size.X.Offset or 0)
				end)
			end
		end

		self._order = keys
	end

	local function reflow(self)
		for i, key in ipairs(self._order) do
			local entry = self.List[key]
			if entry and entry.instance then
				TweenService:Create(entry.instance, TWEEN_INFO, {
					Position = UDim2.new(1, 0, 0, slotY(i))
				}):Play()
			end
		end
	end

	-- --------------------------------------------------------
	-- API
	-- --------------------------------------------------------

	function Arraylist:Add(key, options)
		assert(type(key) == "string", "[Arraylist] key must be a string.")
		if self.List[key] then return end

		local entry = {
			text       = options.text       or options.Text       or key,
			value      = options.value      or options.Value      or "",
			textcolor  = options.textcolor  or options.TextColor  or Library.Theme.TextColor,
			valuecolor = options.valuecolor or options.ValueColor or Library.Theme.TextColor,
			instance   = nil,
		}

		self.List[key] = entry
		sort(self)

		local index   = table.find(self._order, key)
		local targetY = slotY(index)
		local item    = createInstance(key, entry)
		entry.instance = item

		item.Position = UDim2.new(1.5, 0, 0, targetY)
		TweenService:Create(item, TWEEN_INFO, {
			Position = UDim2.new(1, 0, 0, targetY)
		}):Play()

		reflow(self)
	end

	function Arraylist:Edit(key, options)
		assert(self.List[key], "[Arraylist] key '" .. key .. "' does not exist.")

		local entry         = self.List[key]
		local structChanged = false

		local fieldMap = {
			text       = "text",       Text       = "text",
			value      = "value",      Value      = "value",
			textcolor  = "textcolor",  TextColor  = "textcolor",
			valuecolor = "valuecolor", ValueColor = "valuecolor",
		}

		for optKey, val in pairs(options) do
			local field = fieldMap[optKey]
			if field and entry[field] ~= nil then
				if (field == "text" or field == "value") and entry[field] ~= val then
					structChanged = true
				end
				entry[field] = val
			end
		end

		if entry.instance then
			local tl = entry.instance.Holder:FindFirstChild("TextLabel")
			if tl then
				tl.Text       = buildText(entry)
				tl.TextColor3 = entry.textcolor
			end

			local line = entry.instance:FindFirstChild("Line")
			if line then
				line.BackgroundColor3 = entry.textcolor
				local img = line:FindFirstChild("ImageLabel")
				if img then img.ImageColor3 = entry.textcolor end
			end

			if structChanged then
				entry.instance.Size = UDim2.new(0, measureWidth(entry), 0, ITEM_HEIGHT)
			end
		end

		if structChanged then
			sort(self)
			reflow(self)
		end
	end

	function Arraylist:Remove(key)
		if not self.List[key] then return end

		local entry    = self.List[key]
		local instance = entry.instance

		self.List[key] = nil
		sort(self)

		if instance then
			local t = TweenService:Create(instance, TWEEN_INFO, {
				Position = UDim2.new(1.5, 0, 0, instance.Position.Y.Offset)
			})
			t:Play()
			t.Completed:Once(function()
				instance:Destroy()
			end)
		end

		reflow(self)
	end

	function Arraylist:Exists(key)
		if self.List[key] then return true end
		return nil
	end

	function Arraylist:Style(config)
		assert(type(config) == "table",                                           "[Arraylist] Style expects a table.")
		assert(config.style == "alphabet" or config.style == "length",            "[Arraylist] style must be 'alphabet' or 'length'.")
		assert(config.sort  == "increasing" or config.sort  == "decreasing",      "[Arraylist] sort must be 'increasing' or 'decreasing'.")
		self._style = config
		sort(self)
		reflow(self)
	end

	function Arraylist:GetOrdered()
		local result = {}
		for _, key in ipairs(self._order) do
			result[#result + 1] = self.List[key]
		end
		return result
	end

	return Arraylist
end

function Library:Notify(options, callback)
	if Library.Notif.IsBusy == true then
		Library.Notif.Queue[#Library.Notif.Queue + 1] = { options, callback }
		return
	end	

	Library.Notif.IsBusy = true

	local Notification = {
		Type = "Notification",
		Selection = nil,
		Callback = callback,
	}

	Notification.Frame = SelfModules.UI.Create("Frame", {
		Name = "Notification",
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Position = UDim2.new(0, 10, 1, -66),
		Size = UDim2.new(0, 320, 0, 42 + Library.Settings.MaxNotifLines * 14),

		SelfModules.UI.Create("Frame", {
			Name = "Topbar",
			BackgroundColor3 = Library.Theme.TopbarColor,
			Size = UDim2.new(1, 0, 0, 28),

			SelfModules.UI.Create("Frame", {
				Name = "Filling",
				BackgroundColor3 = Library.Theme.TopbarColor,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0.5, 0),
			}),

			SelfModules.UI.Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 7, 0.5, -8),
				Size = UDim2.new(1, -54, 0, 16),
				Font = Enum.Font.SourceSansBold,
				Text = options.title or "Notification",
				TextColor3 = Library.Theme.TextColor,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			SelfModules.UI.Create("ImageButton", {
				Name = "Yes",
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -24, 0.5, -10),
				Size = UDim2.new(0, 20, 0, 20),
				Image = "http://www.roblox.com/asset/?id=7919581359",
				ImageColor3 = Library.Theme.TextColor,
			}),

			SelfModules.UI.Create("ImageButton", {
				Name = "No",
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -2, 0.5, -10),
				Size = UDim2.new(0, 20, 0, 20),
				Image = "http://www.roblox.com/asset/?id=7919583990",
				ImageColor3 = Library.Theme.TextColor,
			}),
		}, UDim.new(0,5)),

		SelfModules.UI.Create("Frame", {
			Name = "Background",
			BackgroundColor3 = Library.Theme.BackgroundColor,
			Position = UDim2.new(0, 0, 0, 28),
			Size = UDim2.new(1, 0, 1, -28),

			SelfModules.UI.Create("TextLabel", {
				Name = "Description",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 7, 0, 7),
				Size = UDim2.new(1, -14, 1, -14),
				Font = Enum.Font.SourceSans,
				Text = options.text,
				TextColor3 = Library.Theme.TextColor,
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),

			SelfModules.UI.Create("Frame", {
				Name = "Filling",
				BackgroundColor3 = Library.Theme.BackgroundColor,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 5),
			}),
		}, UDim.new(0, 5)),
	})

	if options.color ~= nil then
		local indicator = SelfModules.UI.Create("Frame", {
			Name = "Indicator",
			BackgroundColor3 = options.color,
			Size = UDim2.new(0, 4, 1, 0),

			SelfModules.UI.Create("ImageLabel", {
				Name = "Glow",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, -13, 0, -13),
				Size = UDim2.new(1, 26, 1, 26),
				Image = "rbxassetid://10822615828",
				ImageColor3 = options.color,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(99, 99, 99, 99),
				ImageTransparency = 0.9,
				SliceScale = 0.2,
				ZIndex = -1,
			}),

			SelfModules.UI.Create("Frame", {
				Name = "Filling",
				BackgroundColor3 = options.color,
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(0.5, 0, 1, 0),
			}),
		}, UDim.new(0, 3))

		Notification.Frame.Topbar.Title.Position = UDim2.new(0, 11, 0.5, -8)
		Notification.Frame.Topbar.Title.Size = UDim2.new(1, -60, 0, 16)
		Notification.Frame.Background.Description.Position = UDim2.new(0, 11, 0, 7)
		Notification.Frame.Background.Description.Size = UDim2.new(1, -18, 1, -14)
		indicator.Parent = Notification.Frame
	end

	-- Functions

	function Notification:GetHeight()
		local desc = self.Frame.Background.Description
		return 42 + math.round(TXS:GetTextSize(desc.Text, 14, Enum.Font.SourceSans, Vector2.new(desc.AbsoluteSize.X, Library.Settings.MaxNotifStacking * 14)).Y + 0.5)
	end

	function Notification:Select(bool)
		tween(self.Frame.Topbar[bool and "Yes" or "No"], 0.1, { ImageColor3 = bool and Color3.fromRGB(75, 255, 75) or Color3.fromRGB(255, 75, 75) })
		tween(self.Frame, 0.5, { Position = UDim2.new(0, -320, 0, self.Frame.AbsolutePosition.Y) })

		local notifIdx = table.find(Library.Notif.Active, self)
		if notifIdx then
			table.remove(Library.Notif.Active, notifIdx)
			task.delay(0.5, function() self.Frame:Destroy() end)
		end

		pcall(task.spawn, self.Callback, bool)
	end

	-- Scripts

	if options.sound and options.sound ~= 0 then
		local SoundInstance = Instance.new("Sound")
		SoundInstance.SoundId = "rbxassetid://" .. tostring(options.sound):gsub("%s", "")
		SoundInstance.Parent = ScreenGui
		SoundInstance:Play()
		SoundInstance.Ended:Connect(function()
			SoundInstance:Destroy()
		end)
	end

	Library.Notif.Active[#Library.Notif.Active + 1] = Notification
	Storage.Connections[Notification] = {}
	Notification.Frame.Size = UDim2.new(0, 320, 0, Notification:GetHeight())
	Notification.Frame.Position = UDim2.new(0, -320, 1, -Notification:GetHeight() - 10)
	Notification.Frame.Parent = ScreenGui

	if #Library.Notif.Active > Library.Settings.MaxNotifStacking then
		Library.Notif.Active[1]:Select(false)
	end

	for i, v in next, Library.Notif.Active do
		if v ~= Notification then
			tween(v.Frame, 0.5, { Position = v.Frame.Position - UDim2.new(0, 0, 0, Notification:GetHeight() + 10) })
		end
	end

	tween(Notification.Frame, 0.5, { Position = UDim2.new(0, 10, 1, -Notification:GetHeight() - 10) })

	task.spawn(function()
		task.wait(0.5)

		Storage.Connections[Notification].Yes = Notification.Frame.Topbar.Yes.Activated:Connect(function()
			Notification:Select(true)
		end)

		Storage.Connections[Notification].No = Notification.Frame.Topbar.No.Activated:Connect(function()
			Notification:Select(false)
		end)

		Library.Notif.IsBusy = false

		if #Library.Notif.Queue > 0 then
			local notif = Library.Notif.Queue[1]
			table.remove(Library.Notif.Queue, 1)
			Library:Notify(notif[1], notif[2])
		end
	end)

	task.spawn(function()
		task.wait(options.duration or 10)
		if Notification.Frame.Parent ~= nil then
			Notification:Select(false)
		end
	end)

	return Notification
end

function Library:AddWindow(options)
	assert(options, "No options data assigned to Window")

	local Window = {
		Name = options.title[1].. " ".. options.title[2],
		Type = "Window",
		Tabs = {},
		Sidebar = { List = {}, Toggled = false },
		Key = options.key or Enum.KeyCode.RightControl,
		ExtraKey = options.extrakey or Enum.KeyCode.LeftAlt,
		fullscreenKey = options.fullscreenKey or Enum.KeyCode.RightAlt,
		Toggled = options.default ~= false,
		Acrylic = nil,
		Transparency = options.transparency or 0.5,
	}

	-- Custom theme setup
	if options.theme ~= nil then
		for i, v in next, options.theme do
			for i2, _ in next, Library.Theme do
				if string.lower(i) == string.lower(i2) and typeof(v) == "Color3" then
					Library.Theme[i2] = v
				end
			end
		end
	end

	-- Window construction
	Window.Frame = SelfModules.UI.Create("CanvasGroup", {
		Name = "Window",
		BackgroundTransparency = 0,
		Size = UDim2.new(0, 460, 0, 497),
		Position = UDim2.new(1, -490, 1, -527),
		BackgroundColor3 = Library.Theme.TopbarColor,
		Visible = options.default ~= false,

		SelfModules.UI.Create("UIStroke", {
			Name = "Stroke",
			Thickness = 2.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Transparency = 0,
			BorderOffset = UDim.new(0, -1),
			Color = Library.Theme.BackgroundColor,
			Enabled = options.default ~= false
		}),

		SelfModules.UI.Create("CanvasGroup", {
			Name = "Topbar",
			BackgroundColor3 = Library.Theme.TopbarColor,
			Size = UDim2.new(1, 0, 0, 40),
			ZIndex = 3,
			Visible = true,
			
			SelfModules.UI.Create("ImageLabel", {
				Name = "Konata",
				Image = "rbxassetid://83694274760273",
				ScaleType = Enum.ScaleType.Crop,
				Size = UDim2.new(0, 318, 0, 144),
				Position = UDim2.new(0.553, 0, -1.325, 0),
				BackgroundTransparency = 1,
				Visible = false,
			}),

			SelfModules.UI.Create("Frame", {
				Name = "Filling",
				BackgroundColor3 = Library.Theme.TopbarColor,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0.5, 0),
				BackgroundTransparency = 1,
			}),

			SelfModules.UI.Create("Frame", {
				Name = "Titles",
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,

				SelfModules.UI.Create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				SelfModules.UI.Create("UIPadding", {
					PaddingLeft = UDim.new(0, 10)
				}),

				SelfModules.UI.Create("TextLabel", {
					Name = "Label1",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 0, 0, 22),
					Font = Enum.Font.SourceSansBold,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = options.title[1],
					RichText = true,
					TextColor3 = Library.Theme.TextColor,
					TextSize = 22,
					TextWrapped = true,
					LayoutOrder = 0,
				}),

				SelfModules.UI.Create("Frame", {
					Name = "Label2",
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,

					SelfModules.UI.Create("TextLabel", {
						Name = "Label",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 0,
						BackgroundColor3 = Library.Theme.Accent,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						Size = UDim2.new(1, 0, 1, 0),
						Font = Enum.Font.SourceSansSemibold,
						TextXAlignment = Enum.TextXAlignment.Center,
						Text = options.title[2],
						RichText = true,
						TextColor3 = Library.Theme.TextColor,
						TextSize = 20,
						TextWrapped = true,
						LayoutOrder = 1,
						ZIndex = 2,
					}, UDim.new(0, 5)),

					SelfModules.UI.Create("ImageLabel", {
						Name = "Glow",
						BackgroundTransparency = 1,
						Position = UDim2.new(0, -13, 0, -13),
						Size = UDim2.new(1, 26, 1, 26),
						Image = "rbxassetid://10822615828",
						ImageColor3 = Library.Theme.Accent,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(99, 99, 99, 99),
						ImageTransparency = 0.9,
						SliceScale = 0.2,
					}),
				}),
			}),
		}, UDim.new(0, 5)),

		SelfModules.UI.Create("Frame", {
			Name = "Background",
			BackgroundColor3 = Library.Theme.BackgroundColor,
			Position = UDim2.new(0, 30, 0, 40),
			Size = UDim2.new(1, -30, 1, -40),
			ZIndex = 3,
			Visible = false,

			SelfModules.UI.Create("Frame", {
				Name = "Filling",
				BackgroundColor3 = Library.Theme.BackgroundColor,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 5, 1, 0),
			}),

			SelfModules.UI.Create("Frame", {
				Name = "Tabs",
				BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.BackgroundColor, Color3.fromRGB(15, 15, 15)),
				Position = UDim2.new(0, 3, 0, 3),
				Size = UDim2.new(1, -6, 1, -6),

				SelfModules.UI.Create("Frame", {
					Name = "Holder",
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.BackgroundColor, Color3.fromRGB(5, 5, 5)),
					Position = UDim2.new(0, 1, 0, 1),
					Size = UDim2.new(1, -2, 1, -2),
					ClipsDescendants = true,
				}, UDim.new(0, 5)),
			}, UDim.new(0, 5)),
		}, UDim.new(0, 5)),

		SelfModules.UI.Create("Frame", {
			Name = "Sidebar",
			BackgroundColor3 = Library.Theme.SidebarColor,
			Position = UDim2.new(0, 0, 0, 40),
			Size = UDim2.new(0, 30, 1, -40),
			ZIndex = 3,
			Visible = false,
			ClipsDescendants = true,

			SelfModules.UI.Create("TextBox", {
				Name = "SearchBox",
				BackgroundTransparency = 1,
				ClearTextOnFocus = false,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 10, 0, 4),
				Size = UDim2.new(0, 88, 0, 23),
				PlaceholderColor3 = SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(10, 10, 10)),
				PlaceholderText = "Search",
				TextColor3 = Library.Theme.TextColor,
				Font = Enum.Font.SourceSansSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 16,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = "",
				ClipsDescendants = true,
				Visible = false,
			}),

			SelfModules.UI.Create("Frame", {
				Name = "Filling",
				BackgroundColor3 = Library.Theme.SidebarColor,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -5, 0, 0),
				Size = UDim2.new(0, 5, 1, 0),
			}),

			SelfModules.UI.Create("Frame", {
				Name = "Border",
				BackgroundColor3 = Library.Theme.BackgroundColor,
				BorderSizePixel = 0,
				Position = UDim2.new(1, 0, 0, 0),
				Selectable = true,
				Size = UDim2.new(0, 5, 1, 0),
				ZIndex = 2,
				BackgroundTransparency = Library.Settings.Acrylic == true and 1 or 0,
			}),

			SelfModules.UI.Create("Frame", {
				Name = "Line",
				BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(10, 10, 10)),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 5, 0, 29),
				Size = UDim2.new(1, -10, 0, 2),
				BackgroundTransparency = Library.Settings.Acrylic == true and 1 or 0,
			}),

			SelfModules.UI.Create("ScrollingFrame", {
				Name = "List",
				Active = true,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClipsDescendants = false,
				Position = UDim2.new(0, 5, 0, 35),
				Size = UDim2.new(1, -10, 1, -40),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollBarThickness = 5,

				SelfModules.UI.Create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = UDim.new(0, 5),
				}),
			}),

			SelfModules.UI.Create("ImageLabel", {
				Name = "Indicator1",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -23, 0, 8),
				Size = UDim2.new(0, 16, 0, 15),
				ScaleType = Enum.ScaleType.Crop,
				Image = "rbxassetid://11295285432",
				ImageColor3 = Library.Theme.TextColor,
			}),

			SelfModules.UI.Create("ImageLabel", {
				Name = "Indicator2",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -23, 0, 8),
				Size = UDim2.new(0, 16, 0, 15),
				ScaleType = Enum.ScaleType.Crop,
				Image = "rbxassetid://11295291707",
				ImageTransparency = 1,
				ImageColor3 = Library.Theme.Accent,
			}),
		}, UDim.new(0, 5))
	}, UDim.new(0, 5))

	-- Window Toggle Function

	RS.Heartbeat:Connect(function()
		Window.Frame.Visible = Window.Frame.GroupTransparency ~= 1
	end)

	function Window:SetKey(keycode)
		self.Key = keycode
	end

	function Window:GetKey()
		return self.Key
	end

	local function setAccent(accent)
		Library.Theme.Accent = accent
		Window.Frame.Topbar.Titles.Label2.Label.BackgroundColor3 = accent
		Window.Frame.Topbar.Titles.Label2.Glow.ImageColor3 = accent
		Window.Frame.Sidebar.Indicator2.ImageColor3 = accent

		tween(Window.Frame.Topbar.Titles.Label2.Label, 0.5, { TextColor3 = accent.R >= 0.75 and accent.G >= 0.75 and accent.B >= 0.75 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255) })

		for _, tab in next, Window.Tabs do
			
			if tab.Button.Selected then
				tween(tab.Button.Frame.Button, 0.5, { BackgroundColor3 = accent })
				tween(tab.Button.Frame, 0.5, { BackgroundColor3 = SelfModules.UI.Color.Sub(accent, Color3.fromRGB(45, 45, 45)) })
				tween(tab.Button.Frame.Glow, 0.5, { ImageColor3 = accent })
			end
			
			for _, section in next, tab.Sections do
				for _, item in next, section.List do
					local flag = item.Flag or item.Name

					if tab.Flags[flag] == true then
						local overlay
						for _, v in next, item.Frame:GetDescendants() do
							if v.Name == "Overlay" then
								overlay = v
							end
						end
						if overlay then
							local tweenObj = Storage.Tween.Cosmetic[overlay]
							if tweenObj then tweenObj:Cancel() end
							tween(overlay, 0.5, { ImageColor3 = accent.R >= 0.75 and accent.G >= 0.75 and accent.B >= 0.75 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255) })
							overlay.BackgroundColor3 = SelfModules.UI.Color.Add(accent, Color3.fromRGB(15, 15, 15))
							if overlay.Glow then
								overlay.Glow.ImageColor3 = SelfModules.UI.Color.Add(accent, Color3.fromRGB(15, 15, 15))
							end
						end
					end

					if item.Rainbow == true then
						local overlay = nil
						for _, v in next, item.Frame:GetDescendants() do
							if v.Name == "Overlay" then
								overlay = v
								break
							end
						end
						if overlay then
							tween(overlay, 0.5, { ImageColor3 = accent.R >= 0.75 and accent.G >= 0.75 and accent.B >= 0.75 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255) })
							overlay.BackgroundColor3 = SelfModules.UI.Color.Add(accent, Color3.fromRGB(15, 15, 15))
							if overlay.Glow then
								overlay.Glow.ImageColor3 = SelfModules.UI.Color.Add(accent, Color3.fromRGB(15, 15, 15))
							end
						end
					end
					if item.Type == "Graph" then
						for _, line in ipairs(item.Frame.Holder.Field.Holder.List:GetChildren()) do
							if line:IsA("Frame") then
								line.BackgroundColor3 = accent
								local glow = line:FindFirstChild("Glow")
								if glow then
									glow.ImageColor3 = SelfModules.UI.Color.Sub(accent, Color3.fromRGB(10, 10, 10))
								end
							end
						end
					end
					if item.Type == "Ranker" then
						for _, itemName in ipairs(item.Order) do
							local f = item._frameMap[itemName]
							if f then
								local num = f.Holder:FindFirstChild("Num")
								if num then num.TextColor3 = accent end
							end
						end
					end
					if item.Type == "Slider" then
						item.Frame.Holder.Slider.Bar.Fill.BackgroundColor3 = SelfModules.UI.Color.Sub(accent, Color3.fromRGB(10, 10, 10))
						item.Frame.Holder.Slider.Bar.Fill.Glow.ImageColor3 = SelfModules.UI.Color.Sub(accent, Color3.fromRGB(10, 10, 10))
						item.Frame.Holder.Slider.Point.BackgroundColor3 = accent
						local _pt2 = item.Frame.Holder.Slider:FindFirstChild("Point2")
						if _pt2 then _pt2.BackgroundColor3 = accent end
					end

					if item.Type == "SubSection" then
						for _, item2 in next, item.List do
							local flag2 = item2.Flag or item2.Name
							if tab.Flags[flag2] == true then
								local overlay = nil
								for _, v in next, item2.Frame:GetDescendants() do
									if v.Name == "Overlay" then
										overlay = v
										break
									end
								end
								if overlay then
									local tweenObj = Storage.Tween.Cosmetic[overlay]
									if tweenObj then tweenObj:Cancel() end
									tween(overlay, 0.5, { ImageColor3 = accent.R >= 0.75 and accent.G >= 0.75 and accent.B >= 0.75 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255) })
									overlay.BackgroundColor3 = SelfModules.UI.Color.Add(accent, Color3.fromRGB(15, 15, 15))
									if overlay.Glow then
										overlay.Glow.ImageColor3 = SelfModules.UI.Color.Add(accent, Color3.fromRGB(15, 15, 15))
									end
								end
							end
							if item2.Rainbow == true then
								local overlay = nil
								for _, v in next, item2.Frame:GetDescendants() do
									if v.Name == "Overlay" then
										overlay = v
										break
									end
								end
								if overlay then
									tween(overlay, 0.5, { ImageColor3 = accent.R >= 0.75 and accent.G >= 0.75 and accent.B >= 0.75 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255) })
									overlay.BackgroundColor3 = SelfModules.UI.Color.Add(accent, Color3.fromRGB(15, 15, 15))
									if overlay.Glow then
										overlay.Glow.ImageColor3 = SelfModules.UI.Color.Add(accent, Color3.fromRGB(15, 15, 15))
									end
								end
							end
							if item2.Type == "Graph" then
								for _, line in ipairs(item2.Frame.Holder.Field.Holder.List:GetChildren()) do
									if line:IsA("Frame") then
										line.BackgroundColor3 = accent
										local glow = line:FindFirstChild("Glow")
										if glow then
											glow.ImageColor3 = SelfModules.UI.Color.Sub(accent, Color3.fromRGB(10, 10, 10))
										end
									end
								end
							end

							if item2.Type == "Ranker" then
								for _, itemName in ipairs(item2.Order) do
									local f = item2._frameMap[itemName]
									if f then
										local num = f.Holder:FindFirstChild("Num")
										if num then num.TextColor3 = accent end
									end
								end
							end
							if item2.Type == "Slider" then
								item2.Frame.Holder.Slider.Bar.Fill.BackgroundColor3 = SelfModules.UI.Color.Sub(accent, Color3.fromRGB(10, 10, 10))
								item2.Frame.Holder.Slider.Bar.Fill.Glow.ImageColor3 = SelfModules.UI.Color.Sub(accent, Color3.fromRGB(10, 10, 10))
								item2.Frame.Holder.Slider.Point.BackgroundColor3 = accent
								local _pt2 = item2.Frame.Holder.Slider:FindFirstChild("Point2")
								if _pt2 then _pt2.BackgroundColor3 = accent end
							end
						end
					end
				end
			end
		end
	end

	function Window:SetAccent(accent)
		if Storage.Connections.WindowRainbow then
			Storage.Connections.WindowRainbow:Disconnect()
		end
		if typeof(accent) == "string" and string.lower(accent) == "rainbow" then
			Storage.Connections.WindowRainbow = RS.Heartbeat:Connect(function()
				setAccent(Color3.fromHSV(tick() % 5 / 5, 1, 1))
			end)
		elseif typeof(accent) == "Color3" then
			setAccent(accent)
		end
	end

	local function toggleSidebar(bool)
		Window.Sidebar.Toggled = bool
		Window.Sidebar.Frame.SearchBox.Visible = bool
		if not bool then
			Window.Sidebar.Frame.SearchBox.Text = ""
		end
		task.spawn(function()
			task.wait(bool and 0 or 0.5)
			Window.Sidebar.Frame.Border.Visible = bool
		end)
		TS:Create(Window.Sidebar.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, bool and 130 or 30, 1, -40) }):Play()
		TS:Create(Window.Frame.Background, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(1, bool and -130 or -30,1, -40), Position = UDim2.new(0, bool and 130 or 30, 0, 40) }):Play()
		tween(Window.Sidebar.Frame.Indicator1, 0.25, { ImageTransparency = bool and 1 or 0 })
		tween(Window.Sidebar.Frame.Indicator2, 0.25, { Rotation = bool and 45 or 0, ImageTransparency = bool and 0 or 1 })
		for i, v in next, Window.Sidebar.List do
			TS:Create(v.Frame.Button.Label, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextTransparency = bool and 0 or 1 }):Play()
			TS:Create(v.Frame.Button, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = bool and 0 or 1 }):Play()
			TS:Create(v.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = bool and 0 or 1 }):Play()
			TS:Create(v.Frame.Glow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { ImageTransparency = bool and 0.7 or 1 }):Play()
			-- removed wait() to animate all simultaneously
		end
	end
	
	local function loadup()
		local Sound = Instance.new("Sound", game:GetService("SoundService"))
		Sound.PlayOnRemove = true
		Sound.PlaybackSpeed = 1.25
		Sound.Volume = 1
		Sound.SoundId = "rbxassetid://89087762338808"
		Sound:Remove()
		Window.Frame.Background.Visible = true
		Window.Frame.Topbar.Visible = true
		Window.Frame.Sidebar.Visible = true
		Window.Frame.Stroke.Enabled = true
	end

	-- Scripts
	local Size1 = TXS:GetTextSize(Window.Frame.Topbar.Titles.Label1.Text, 22, Enum.Font.SourceSansBold, Vector2.new(0, 22))
	local Size2 = TXS:GetTextSize(Window.Frame.Topbar.Titles.Label2.Label.Text, 20, Enum.Font.SourceSansSemibold, Vector2.new(0, 20))
	Window.Frame.Topbar.Titles.Label1.Size = UDim2.new(0, Size1.X + 5, 0, Size1.Y)
	Window.Frame.Topbar.Titles.Label2.Size = UDim2.new(0, Size2.X + 10, 0, Size2.Y + 5)

	Window.Key = options.key or options.Key or Window.Key
	Window.FullscreenKey = options.fullscreenKey or options.FullscreenKey

	Window.Fullscreen = false
	Window.Toggled = true

	-- Base constants
	Window.BaseSize = UDim2.new(0, 460, 0, 497)
	Window.FullscreenSize = UDim2.new(1, -12, 1, -12)
	Window.FullscreenPosition = UDim2.new(0, 6, 0, 6)

	-- These always store the SHOWN windowed state
	Window.WindowedSize = Window.BaseSize
	Window.WindowedPosition = Window.Frame.Position

	function Window:Toggle(bool)
		if self.Toggled == bool then return end
		self.Toggled = bool

		local Sound = Instance.new("Sound")
		Sound.Parent = game:GetService("SoundService")
		Sound.PlayOnRemove = true
		Sound.PlaybackSpeed = bool and 1.5 or 0.75
		Sound.Volume = 1
		Sound.SoundId = "rbxassetid://89087762338808"
		Sound:Destroy()

		local targetSize, targetPos

		if self.Fullscreen then
			-- In fullscreen mode: shrink/expand relative to fullscreen bounds
			if bool then
				targetSize = self.FullscreenSize
				targetPos = self.FullscreenPosition
			else
				targetSize = self.FullscreenSize - UDim2.new(0, 10, 0, 10)
				targetPos = self.FullscreenPosition + UDim2.new(0, 5, 0, 5)
			end
		else
			-- Windowed mode: shrink/expand relative to the frame's live size/position
			local currentSize = self.Frame.Size
			local currentPos = self.Frame.Position

			if bool then
				targetSize = currentSize + UDim2.new(0, 10, 0, 10)
				targetPos = currentPos - UDim2.new(0, 5, 0, 5)
			else
				targetSize = currentSize - UDim2.new(0, 10, 0, 10)
				targetPos = currentPos + UDim2.new(0, 5, 0, 5)
			end
		end

		tween(self.Frame, 0.25, {
			Size = targetSize,
			Position = targetPos,
			GroupTransparency = bool and 0 or 1
		})

		local stroke = self.Frame:FindFirstChild("Stroke")
		if stroke then
			tween(stroke, 0.25, {
				Transparency = bool and 0 or 1
			})
		end
	end

	function Window:SetFullscreen(bool)
		if self.Fullscreen == bool then return end
		self.Fullscreen = bool

		local Sound = Instance.new("Sound")
		Sound.Parent = game:GetService("SoundService")
		Sound.PlayOnRemove = true
		Sound.PlaybackSpeed = bool and 1.75 or 1.5
		Sound.Volume = 1
		Sound.SoundId = "rbxassetid://89087762338808"
		Sound:Destroy()

		local targetSize, targetPos

		if bool then
			-- ENTER FULLSCREEN
			-- Snapshot the SHOWN windowed state so we can restore correctly later
			if self.Toggled then
				self.WindowedSize = self.Frame.Size
				self.WindowedPosition = self.Frame.Position
			else
				-- Currently hidden: reverse the toggle offset to get the true shown state
				self.WindowedSize = self.Frame.Size + UDim2.new(0, 10, 0, 10)
				self.WindowedPosition = self.Frame.Position - UDim2.new(0, 5, 0, 5)
			end

			-- If hidden, enter fullscreen in the hidden shrunken state
			if self.Toggled then
				targetSize = self.FullscreenSize
				targetPos = self.FullscreenPosition
			else
				targetSize = self.FullscreenSize - UDim2.new(0, 10, 0, 10)
				targetPos = self.FullscreenPosition + UDim2.new(0, 5, 0, 5)
			end

			SelfModules.UI.UnMakeDraggable(self.Frame.Topbar)
		else
			-- EXIT FULLSCREEN
			if self.Toggled then
				targetSize = self.WindowedSize
				targetPos = self.WindowedPosition
			else
				-- Return to the hidden windowed state
				targetSize = self.WindowedSize - UDim2.new(0, 10, 0, 10)
				targetPos = self.WindowedPosition + UDim2.new(0, 5, 0, 5)
			end

			SelfModules.UI.MakeDraggable(self.Frame, self.Frame.Topbar, 0.0975, function(bool)
				if not self.Toggled then return end
				TS:Create(self.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { GroupTransparency = bool and Window.Transparency or bool and 0.5 or 0 }):Play()
			end)
		end

		tween(self.Frame.Topbar.Konata, 0.3, {
			Position = bool and UDim2.new(0.851, 0, -1.3, 0) or UDim2.new(0.553, 0, -1.325, 0)
		})

		tween(self.Frame, 0.3, {
			Size = targetSize,
			Position = targetPos
		})
	end

	Storage.Connections[Window] = {}
	SelfModules.UI.MakeDraggable(Window.Frame, Window.Frame.Topbar, 0.0975, function(bool)
		if not Window.Toggled then return end
		TS:Create(Window.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { GroupTransparency = bool and Window.Transparency or bool and 0.5 or 0 }):Play()
	end)
	Window.Sidebar.Frame = Window.Frame.Sidebar
	Window.Frame.Parent = ScreenGui

	-- Existing toggle keybind
	UIS.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Window.Key and not ListenForInput then
			if UIS:IsKeyDown(Window.ExtraKey) == true then
				Window:SetFullscreen(not Window.Fullscreen)
			else
				Window:Toggle(not Window.Toggled)
			end
		end
	end)

	-- New fullscreen keybind
	if Window.FullscreenKey then
		UIS.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and input.KeyCode == Window.FullscreenKey and not ListenForInput then
				Window:SetFullscreen(not Window.Fullscreen)
			end
		end)
	end

	Window.Sidebar.Frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and Mouse.Y - Window.Sidebar.Frame.AbsolutePosition.Y <= 25 then
			toggleSidebar(not Window.Sidebar.Toggled)
		end
	end)
	
	-- Load up effect
	local BackgroundHandler = SelfModules.UI.Create("Frame", {
		Name = "BackgroundHandler",
		ZIndex = 100,
		BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		
		SelfModules.UI.Create("UIStroke", {
			Thickness = 1.5,
			Color = SelfModules.UI.Color.Add(Library.Theme.TopbarColor, Color3.fromRGB(15, 15, 15)),
		}),
	}, UDim.new(0, 5))
	BackgroundHandler.Parent = Window.Frame
	
	Window.Frame.GroupTransparency = 1
	Window.Frame.Rotation = math.random(-45, 45)
	Window.Frame.Position = UDim2.new(0.5, -Window.Frame.Size.X.Offset/2, -1.5, -Window.Frame.Size.Y.Offset/2)
	local LoadingTween = TS:Create(Window.Frame, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Rotation = 0, GroupTransparency = 0, Position = UDim2.new(0.5, -Window.Frame.Size.X.Offset/2, 0.5, -Window.Frame.Size.Y.Offset/2) })
	LoadingTween:Play()
	local LoadingTweenConnection
	LoadingTweenConnection = LoadingTween.Completed:Connect(function()
		LoadingTweenConnection:Disconnect()
		LoadingTweenConnection = nil
		TS:Create(BackgroundHandler.UICorner, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {CornerRadius = UDim.new(1, 0)}):Play()
		TS:Create(BackgroundHandler.UIStroke, TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		TS:Create(BackgroundHandler, TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
		local LoadingTweenConnection2
		local LoadingTween2
		LoadingTween2 = TS:Create(BackgroundHandler, TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 1.5, 0)})
		LoadingTween2:Play()
		LoadingTweenConnection2 = LoadingTween2.Completed:Connect(function()
			LoadingTweenConnection2:Disconnect()
			LoadingTweenConnection2 = nil
			BackgroundHandler:Destroy()
		end)
	end)
	
	-- Tab
	function Window:AddTab(name, options)
		options = options or {}
		local Tab = {
			Name = name,
			Type = "Tab",
			Sections = {},
			Flags = {},
			Button = {
				Name = name,
				Selected = false,
			},
		}

		if options.icon and options.icon ~= "" then
			local TabIcon = SelfModules.UI.Create("ImageLabel", {
				Name = name,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 16, 0, 16),
				Position = UDim2.new(0, 433, 0, 12),
				Image = options.icon,
				ImageColor3 = Library.Theme.Accent,
				ImageTransparency = 1,
			})
			if options.default then
				TabIcon.ImageTransparency = 0
			end
			TabIcon.Parent = Window.Frame.Topbar
		end

		Tab.Frame = SelfModules.UI.Create("ScrollingFrame", {
			Name = "Tab",
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 5, 0, 5),
			Size = UDim2.new(1, -10, 1, -10),
			ScrollBarImageColor3 = SelfModules.UI.Color.Add(Library.Theme.BackgroundColor, Color3.fromRGB(15, 15, 15)),
			ScrollBarThickness = 5,
			Visible = false,
			SelfModules.UI.Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 5),
			}),
		})

		Tab.Button.Frame = SelfModules.UI.Create("Frame", {
			Name = name,
			BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(15, 15, 15)),
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 120, 0, 32),

			SelfModules.UI.Create("ImageLabel", {
				Name = "Glow",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, -8, 0, -8),
				Size = UDim2.new(1, 16, 1, 16),
				Image = "rbxassetid://10822615828",
				ImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(15, 15, 15)),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(99, 99, 99, 99),
				ImageTransparency = 1,
				SliceScale = 0.15,
			}),

			SelfModules.UI.Create("TextButton", {
				Name = "Button",
				AutoButtonColor = false,
				BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(5, 5, 5)),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 1, 0, 1),
				Size = UDim2.new(1, -2, 1, -2),
				Text = "",
				TextTransparency = 1,
				TextSize = 0,

				SelfModules.UI.Create("TextLabel", {
					Name = "Label",
					Font = Enum.Font.SourceSansSemibold,
					Text = name,
					TextColor3 = Library.Theme.TextColor,
					TextTransparency = 1,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -4, 1, -50),
					Position = UDim2.new(0, 6, 0, 25),
				}),
			}, UDim.new(0, 5)),
		}, UDim.new(0, 5))

		function Tab:Show()
			for i, v in next, Window.Tabs do
				local bool = v == self
				v.Frame.Visible = bool
				v.Button.Selected = bool
				tween(v.Button.Frame.Button, 0.2, { BackgroundColor3 = bool and Library.Theme.Accent or SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(5, 5, 5)) })
				tween(v.Button.Frame, 0.2, { BackgroundColor3 = bool and SelfModules.UI.Color.Sub(Library.Theme.Accent, Color3.fromRGB(45, 45, 45)) or SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(15, 15, 15)) })
				tween(v.Button.Frame.Glow, 0.2, { ImageColor3 = bool and Library.Theme.Accent or SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(15, 15, 15)) })
				--[[if Window.Frame.Topbar[v.Name] then
					tween(Window.Frame.Topbar[v.Name], 0.2, { ImageTransparency = bool and 0 or 1 })
				end]]
			end
			toggleSidebar(false)
		end

		function Tab:Hide()
			self.Frame.Visible = false
		end

		function Tab:GetHeight()
			local height = 0
			for i, v in next, self.Sections do
				height = height + v:GetHeight() + (i < #self.Sections and 5 or 0)
			end
			return height
		end

		function Tab:UpdateHeight()
			Tab.Frame.CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight())
		end

		Window.Tabs[#Window.Tabs + 1] = Tab
		Window.Sidebar.List[#Window.Sidebar.List + 1] = Tab.Button
		Tab.Frame.Parent = Window.Frame.Background.Tabs.Holder
		Tab.Frame.CanvasSize = UDim2.new(0, 0, 0, Tab.Frame.AbsoluteSize.Y + 1)
		Tab.Button.Frame.Parent = Window.Frame.Sidebar.List

		Tab.Frame.ChildAdded:Connect(function(c)
			if c.ClassName == "Frame" then Tab:UpdateHeight() end
		end)
		Tab.Frame.ChildRemoved:Connect(function(c)
			if c.ClassName == "Frame" then Tab:UpdateHeight() end
		end)

		Tab.Button.Frame.Button.MouseEnter:Connect(function()
			tween(Tab.Button.Frame.Button.Label, 0.1, { Position = UDim2.new(0, 12, 0, 25) })
			if not Tab.Button.Selected then
				tween(Tab.Button.Frame.Button, 0.1, { BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(15, 15, 15)) })
				tween(Tab.Button.Frame, 0.1, { BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(25, 25, 25)) })
			end
		end)

		Tab.Button.Frame.Button.MouseLeave:Connect(function()
			tween(Tab.Button.Frame.Button.Label, 0.1, { Position = UDim2.new(0, 6, 0, 25) })
			if not Tab.Button.Selected then
				tween(Tab.Button.Frame.Button, 0.1, { BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(5, 5, 5)) })
				tween(Tab.Button.Frame, 0.1, { BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SidebarColor, Color3.fromRGB(15, 15, 15)) })
			end
		end)

		Tab.Button.Frame.Button.Activated:Connect(function()
			if not Tab.Button.Selected then Tab:Show() end
		end)

		if options.default == true then Tab:Show() end

		-- Section
		function Tab:AddSection(name, options)
			options = options or {}
			local Section = {
				Name = name,
				Type = "Section",
				Toggled = options.default == true,
				List = {},
			}

			Section.Frame = SelfModules.UI.Create("Frame", {
				Name = "Section",
				BackgroundColor3 = Library.Theme.SectionColor,
				ClipsDescendants = true,
				Size = UDim2.new(1, -10, 0, 40),

				SelfModules.UI.Create("Frame", {
					Name = "Line",
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 5, 0, 30),
					Size = UDim2.new(1, -10, 0, 2),
				}),

				SelfModules.UI.Create("TextLabel", {
					Name = "Header",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 5, 0, 8),
					Size = UDim2.new(1, -40, 0, 14),
					Font = Enum.Font.SourceSans,
					Text = name,
					TextColor3 = Library.Theme.TextColor,
					TextSize = 14,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				SelfModules.UI.Create("Frame", {
					Name = "List",
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Position = UDim2.new(0, 5, 0, 40),
					Size = UDim2.new(1, -10, 1, -40),
					SelfModules.UI.Create("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(0, 5),
					}),
					SelfModules.UI.Create("UIPadding", {
						PaddingBottom = UDim.new(0, 1),
						PaddingLeft = UDim.new(0, 1),
						PaddingRight = UDim.new(0, 1),
						PaddingTop = UDim.new(0, 1),
					}),
				}),

				SelfModules.UI.Create("TextLabel", {
					Name = "Indicator",
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -30, 0, 0),
					Size = UDim2.new(0, 30, 0, 30),
					Font = Enum.Font.SourceSansBold,
					Text = "+",
					TextColor3 = Library.Theme.TextColor,
					TextSize = 20,
				})
			}, UDim.new(0, 5))
			
			Section.Locked = false
			
			local function toggleSection(bool, forced)
				if Section.Locked == true then return end
				Section.Toggled = bool
				
				if forced == nil then
					tween(Section.Frame, 0.5, { Size = UDim2.new(1, -10, 0, Section:GetHeight()) })
					tween(Section.Frame.Indicator, 0.5, { Rotation = bool and 45 or 0 })
					tween(Tab.Frame, 0.5, { CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight()) })
				elseif forced == true then
					Section.Frame.Size = UDim2.new(1, -10, 0, Section:GetHeight())
					Section.Frame.Indicator.Rotation = bool and 45 or 0
					Tab.Frame.CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight())
				end
			end
			
			function Section:SetLock(bool)
				toggleSection(not bool, true)
				Section.Locked = bool
				tween(Section.Frame.Header, 0.5, { TextColor3 = bool == true and SelfModules.UI.Color.Sub(Library.Theme.TextColor, Color3.fromRGB(155, 155, 155)) or Library.Theme.TextColor })
				tween(Section.Frame.Indicator, 0.5, { TextColor3 = bool == true and SelfModules.UI.Color.Sub(Library.Theme.TextColor, Color3.fromRGB(155, 155, 155)) or Library.Theme.TextColor })
			end
			
			function Section:GetLock()
				return Section.Locked
			end

			function Section:GetHeight()
				local height = 40
				if Section.Toggled then
					for i, v in next, self.List do
						if v.Frame.Visible then
							height = height + (v.GetHeight and v:GetHeight() or v.Frame.AbsoluteSize.Y) + 5
						end
					end
				end
				return height
			end

			function Section:UpdateHeight()
				if Section.Toggled then
					Section.Frame.Size = UDim2.new(1, -10, 0, Section:GetHeight())
					Section.Frame.Indicator.Rotation = 45
					Tab:UpdateHeight()
				end
			end

			function Section:SetName(text)
				Section.Frame.Header.Text = text
			end

			function Section:GetName()
				return Section.Frame.Header.Text
			end

			Tab.Sections[#Tab.Sections + 1] = Section
			Section.Frame.Parent = Tab.Frame

			Section.Frame.List.ChildAdded:Connect(function(c)
				if c.ClassName == "Frame" then Section:UpdateHeight() end
			end)

			Section.Frame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and #Section.List > 0 and Window.Sidebar.Frame.AbsoluteSize.X <= 35 and Mouse.Y - Section.Frame.AbsolutePosition.Y <= 30 then
					toggleSection(not Section.Toggled)
				end
			end)
			
			-- Terminal
			function Section:AddTerminal(name, options, callback)
				local Terminal = {
					Name = name,
					Options = options or {},
					Callback = callback,
					CurrentLayoutOrder = 0,
					List = {},
				}

				-- Frame
				Terminal.Frame = SelfModules.UI.Create("Frame", {
					Name = name,
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, math.clamp(Terminal.Options.extend, 55, 1000) or 280),

					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Size = UDim2.new(1, -2, 1, -2),
						Position = UDim2.new(0, 1, 0, 1),

						SelfModules.UI.Create("TextLabel", {
							Name = "Label",
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 5, 0, 5),
							Size = UDim2.new(1, -10, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),

						SelfModules.UI.Create("Frame", {
							Name = "Field",
							BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
							Position = UDim2.new(0.5, 0, 0, 25),
							Size = UDim2.new(1, -8, 1, -30),
							AnchorPoint = Vector2.new(0.5, 0),

							SelfModules.UI.Create("Frame", {
								Name = "Holder",
								BackgroundColor3 = Library.Theme.SectionColor,
								Position = UDim2.new(0, 1, 0, 1),
								Size = UDim2.new(1, -2, 1, -2),
								ClipsDescendants = true,
							}, UDim.new(0, 5)),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))

				-- Build List (scrollable or static)
				local Holder = Terminal.Frame.Holder.Field.Holder

				if Terminal.Options.scrollable == true then
					local List = SelfModules.UI.Create("ScrollingFrame", {
						Name = "List",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -6, 1, -3),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						CanvasSize = UDim2.new(0, 0, 0, 0),
						ClipsDescendants = false,
						ScrollBarImageColor3 = SelfModules.UI.Color.Add(Library.Theme.BackgroundColor, Color3.fromRGB(25, 25, 25)),
						ScrollBarThickness = 5,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BorderSizePixel = 0,

						SelfModules.UI.Create("UIListLayout", {
							FillDirection = Enum.FillDirection.Vertical,
							SortOrder = Enum.SortOrder.LayoutOrder,
							HorizontalAlignment = Enum.HorizontalAlignment.Left,
							VerticalAlignment = Enum.VerticalAlignment.Top,
						}),

						SelfModules.UI.Create("UIPadding", {
							PaddingLeft = UDim.new(0, 4),
							PaddingRight = UDim.new(0, 4),
							PaddingTop = UDim.new(0, 2),
							PaddingBottom = UDim.new(0, 2),
						}),
					})
					List.Parent = Holder
				else
					local List = SelfModules.UI.Create("Frame", {
						Name = "List",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						ClipsDescendants = true,

						SelfModules.UI.Create("UIListLayout", {
							FillDirection = Enum.FillDirection.Vertical,
							SortOrder = Enum.SortOrder.LayoutOrder,
							HorizontalAlignment = Enum.HorizontalAlignment.Left,
							VerticalAlignment = Enum.VerticalAlignment.Top,
						}),

						SelfModules.UI.Create("UIPadding", {
							PaddingLeft = UDim.new(0, 4),
							PaddingRight = UDim.new(0, 4),
							PaddingTop = UDim.new(0, 2),
							PaddingBottom = UDim.new(0, 2),
						}),
					})
					List.Parent = Holder
				end

				-- References
				local List = Holder.List
				local Layout = List.UIListLayout

				-- Auto canvas resize for scrollable mode
				if Terminal.Options.scrollable == true then
					Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
						List.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 4)
						List.CanvasPosition = Vector2.new(0, math.max(0, Layout.AbsoluteContentSize.Y - List.AbsoluteSize.Y))
					end)
				end

				-- Colors
				local MessageColors = {
					Print   = Color3.fromRGB(255, 255, 255),
					Warn    = Color3.fromRGB(255, 170, 0),
					Feed    = Color3.fromRGB(125, 180, 255),
					Error   = Color3.fromRGB(255, 80, 80),
					Success = Color3.fromRGB(85, 255, 0),
					Info    = Color3.fromRGB(120, 200, 255),
					Debug   = Color3.fromRGB(170, 170, 170),
					System  = Color3.fromRGB(180, 140, 255),
					Command = Color3.fromRGB(255, 255, 120),
					Input   = Color3.fromRGB(255, 220, 180),
					Output  = Color3.fromRGB(180, 255, 255),
					Critical= Color3.fromRGB(255, 40, 40),
					Trace   = Color3.fromRGB(120, 120, 120),
					Network = Color3.fromRGB(100, 180, 255),
					Security= Color3.fromRGB(255, 80, 180),
					Memory  = Color3.fromRGB(255, 120, 120),
					File    = Color3.fromRGB(200, 255, 150),
					Event   = Color3.fromRGB(255, 180, 255),
					Loading = Color3.fromRGB(255, 220, 100),
					Hidden  = Color3.fromRGB(90, 90, 90),
				}

				-- Callback Helper
				local function fireCallback(state, object)
					if Terminal.Callback then
						task.spawn(function()
							Terminal.Callback(state, object)
						end)
					end
				end

				-- Bounds Check (only used in non-scrollable mode)
				local function isOutOfBounds(guiObject)
					local objectBottom = guiObject.AbsolutePosition.Y + guiObject.AbsoluteSize.Y
					local containerBottom = List.AbsolutePosition.Y + List.AbsoluteSize.Y
					return objectBottom > containerBottom
				end

				-- Remove Oldest (only used in non-scrollable mode)
				local function removeOldest()
					local labels = {}
					for _, child in ipairs(List:GetChildren()) do
						if child:IsA("TextLabel") or child:IsA("TextBox") then
							table.insert(labels, child)
						end
					end
					if #labels == 0 then return end
					table.sort(labels, function(a, b)
						return a.LayoutOrder < b.LayoutOrder
					end)
					local oldest = labels[1]
					fireCallback("Remove", oldest)
					oldest:Destroy()
				end

				-- Overflow Check (only used in non-scrollable mode)
				local function checkOverflow()
					for _, child in ipairs(List:GetChildren()) do
						if (child:IsA("TextLabel") or child:IsA("TextBox")) and isOutOfBounds(child) then
							removeOldest()
							task.defer(checkOverflow)
							break
						end
					end
				end

				-- Public Functions

				function Terminal:Add(text, config)
					config = config or {}

					local Sound = Instance.new("Sound")
					Sound.SoundId = "rbxassetid://140207837688369"
					Sound.Volume = 0.01
					Sound.PlaybackSpeed = 1
					Sound.PlayOnRemove = true
					Sound.Parent = game:GetService("SoundService")
					Sound:Remove()

					Terminal.CurrentLayoutOrder += 1

					local messageType = config.type or "Print"
					local selectable = config.Selectable or false
					local wrapped = config.Wrapped or false
					local sizeY = config.SizeY or 14

					local baseProperties = {
						Name = "Label",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -2, 0, sizeY),
						AutomaticSize = wrapped and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
						Font = Enum.Font.SourceSans,
						Text = tostring(text),
						TextSize = 14,
						TextWrapped = wrapped,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextColor3 = MessageColors[messageType] or MessageColors.Print,
						LayoutOrder = Terminal.CurrentLayoutOrder,
					}

					local Object

					if selectable then
						Object = SelfModules.UI.Create("TextBox", {
							Name = baseProperties.Name,
							BackgroundTransparency = baseProperties.BackgroundTransparency,
							Size = baseProperties.Size,
							AutomaticSize = baseProperties.AutomaticSize,
							Font = baseProperties.Font,
							Text = baseProperties.Text,
							TextSize = baseProperties.TextSize,
							TextWrapped = baseProperties.TextWrapped,
							TextXAlignment = baseProperties.TextXAlignment,
							TextYAlignment = baseProperties.TextYAlignment,
							TextColor3 = baseProperties.TextColor3,
							LayoutOrder = baseProperties.LayoutOrder,
							ClearTextOnFocus = false,
							MultiLine = wrapped,
							TextEditable = false,
							Selectable = true,
							Active = true,
						})

						local ClickDetector = SelfModules.UI.Create("TextButton", {
							Name = "Detector",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 1, 0),
							Text = "",
							ZIndex = (Object.ZIndex or 1) + 1,
						})
						ClickDetector.Parent = Object

						ClickDetector.MouseButton1Click:Connect(function()
							Object:CaptureFocus()
							task.defer(function()
								if Object.Parent then
									Object.CursorPosition = #Object.Text + 1
									Object.SelectionStart = 1
								end
							end)
						end)
					else
						Object = SelfModules.UI.Create("TextLabel", baseProperties)
					end

					Object.Parent = List
					table.insert(Terminal.List, Object)
					fireCallback("Add", Object)

					if Terminal.Options.scrollable ~= true then
						task.defer(checkOverflow)
					end

					return Object
				end

				function Terminal:Remove(object)
					if not object then return end
					if object.Parent == List then
						fireCallback("Remove", object)
						object:Destroy()
					end
				end

				function Terminal:Reset()
					for _, child in ipairs(List:GetChildren()) do
						if child:IsA("TextLabel") or child:IsA("TextBox") then
							fireCallback("Remove", child)
							child:Destroy()
						end
					end
					Terminal.List = {}
					Terminal.CurrentLayoutOrder = 0
				end

				function Terminal:GetChildren()
					local objects = {}
					for _, child in ipairs(List:GetChildren()) do
						if child:IsA("TextLabel") or child:IsA("TextBox") then
							table.insert(objects, child)
						end
					end
					return objects
				end

				function Terminal:GetCount()
					local count = 0
					for _, child in ipairs(List:GetChildren()) do
						if child:IsA("TextLabel") or child:IsA("TextBox") then
							count += 1
						end
					end
					return count
				end

				Section.List[#Section.List + 1] = Terminal
				Terminal.Frame.Parent = Section.Frame.List

				return Terminal
			end
			
			-- Graph
			function Section:AddGraph(name, options, callback)
				local Graph = {
					Name = name,
					Type = "Graph",
					Options = options,
					Callback = callback,
				}
				
				-- Frame
				Graph.Frame = SelfModules.UI.Create("Frame", {
					Name = name,
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, math.clamp(Graph.Options.extend, 55, 1000) or 280),

					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Size = UDim2.new(1, -2, 1, -2),
						Position = UDim2.new(0, 1, 0, 1),

						SelfModules.UI.Create("TextLabel", {
							Name = "Label",
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 5, 0, 5),
							Size = UDim2.new(1, -10, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),

						SelfModules.UI.Create("Frame", {
							Name = "Field",
							BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
							Position = UDim2.new(0.5, 0, 0, 25),
							Size = UDim2.new(1, -8, 1, -30),
							AnchorPoint = Vector2.new(0.5, 0),
							ClipsDescendants = true,

							SelfModules.UI.Create("Frame", {
								Name = "Holder",
								BackgroundColor3 = Library.Theme.SectionColor,
								Position = UDim2.new(0, 1, 0, 1),
								Size = UDim2.new(1, -2, 1, -2),
								ClipsDescendants = true,

								SelfModules.UI.Create("Frame", {
									Name = "List",
									BackgroundTransparency = 1,
									Size = UDim2.new(1, 0, 1, 0),
									ClipsDescendants = true,
								}),
							}, UDim.new(0, 5)),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))
				
				-- Scripts
				local points    = {}
				local linePool  = {}
				local MIN       = Graph.Options.min       or 0
				local MAX       = Graph.Options.max       or 100
				local MAX_POINTS = Graph.Options.points   or 50
				local THICKNESS = Graph.Options.thickness or 1.5

				local List = Graph.Frame.Holder.Field.Holder.List

				local function getLine(index)
					if not linePool[index] then
						local f = SelfModules.UI.Create("Frame", {
							BackgroundColor3 = Library.Theme.Accent,
							BorderSizePixel = 0,
							Visible = false,
							
							SelfModules.UI.Create("ImageLabel", {
								Name = "Glow",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, -3, 0, -3),
								Size = UDim2.new(1, 6, 1, 6),
								Image = "rbxassetid://10822615828",
								ImageColor3 = SelfModules.UI.Color.Sub(Library.Theme.Accent, Color3.fromRGB(10, 10, 10)),
								ScaleType = Enum.ScaleType.Slice,
								SliceCenter = Rect.new(99, 99, 99, 99),
								ImageTransparency = 0.98,
								SliceScale = 1,
							}),
						})
						f.Parent = List
						linePool[index] = f
					end
					return linePool[index]
				end

				local function drawLine(frame, ax, ay, bx, by)
					local dx = bx - ax
					local dy = by - ay
					local length = math.sqrt(dx * dx + dy * dy)
					local angle  = math.deg(math.atan2(dy, dx))
					local mx = (ax + bx) / 2
					local my = (ay + by) / 2

					frame.AnchorPoint = Vector2.new(0.5, 0.5)
					frame.Position    = UDim2.new(0, mx, 0, my)
					frame.Size        = UDim2.new(0, length, 0, THICKNESS)
					frame.Rotation    = angle
					frame.Visible     = true
				end

				local function hideUnused(from)
					for i = from, #linePool do
						if linePool[i] then
							linePool[i].Visible = false
						end
					end
				end

				local function redraw()
					local w     = List.AbsoluteSize.X
					local h     = List.AbsoluteSize.Y
					local count = #points

					if count < 2 then return end

					local spacing = w / (MAX_POINTS - 1)

					for i = 1, count - 1 do
						local ax = (i - 1) * spacing
						local bx = i       * spacing
						local ay = points[i]     * h
						local by = points[i + 1] * h

						drawLine(getLine(i), ax, ay, bx, by)
					end

					hideUnused(count)
				end

				-- Functions

				-- Adds a new value to the graph
				function Graph:Add(value)
					local clamped    = math.clamp(value, MIN, MAX)
					local percentage = 1 - ((clamped - MIN) / (MAX - MIN))

					table.insert(points, percentage)
					if #points > MAX_POINTS then
						table.remove(points, 1)
					end

					if Graph.Callback then
						-- Returning value
						Graph.Callback(clamped)
					end

					redraw()
				end
				
				-- Returns the average calculated value
				function Graph:GetAverage()
					if #points == 0 then return 0 end

					local sum = 0
					for _, percentage in ipairs(points) do
						-- convert percentage back to real value
						sum = sum + (MIN + ((1 - percentage) * (MAX - MIN)))
					end

					return sum / #points
				end

				-- Sets how many points fit across the graph (fewer = longer segments, more = shorter)
				function Graph:Scale(value)
					MAX_POINTS = math.clamp(math.floor(value), 2, 500)

					-- Trim existing points if new scale is smaller
					while #points > MAX_POINTS do
						table.remove(points, 1)
					end

					redraw()
				end

				-- Changes the thickness of all lines
				function Graph:Thickness(value)
					THICKNESS = math.clamp(value, 0.5, 10)
					redraw()
				end

				-- Clears all lines and resets state
				function Graph:Clear()
					points = {}

					for _, line in ipairs(linePool) do
						if line then
							line:Destroy()
						end
					end

					linePool = {}
				end
				
				function Graph:SetPoints(value)
					MAX_POINTS = math.clamp(math.floor(value), 2, 500)

					while #points > MAX_POINTS do
						table.remove(points, 1)
					end

					redraw()
				end
				
				Section.List[#Section.List + 1] = Graph
				Graph.Frame.Parent = Section.Frame.List
				
				return Graph
			end
			
			-- Priority
			function Section:AddPriority(name, list, options, callback)
				local Ranker = {
					Name     = name,
					Type     = "Ranker",
					Toggled  = false,
					Order    = {},
					Excluded = {},
					List     = {},
					Callback = callback,
					Style    = options and options.style or "numeric",
					Max      = options and options.max or math.huge,
				}

				local ITEM_HEIGHT  = 32
				local ITEM_GAP     = 4
				local ITEM_STRIDE  = ITEM_HEIGHT + ITEM_GAP
				local HAS_EXCLUDE  = options and options.exclude or false
				local MAX          = options and options.max or math.huge
				local DIVIDER_KEY  = "__DIVIDER__"

				local unified      = {}
				local frameMap     = {}
				local dividerFrame = nil
				
				Ranker._frameMap = frameMap

				local function slotY(i)
					return (i - 1) * ITEM_STRIDE
				end

				local function totalListH()
					return math.max(#unified, 1) * ITEM_STRIDE - ITEM_GAP
				end

				local function rebuildOrderExcluded()
					Ranker.Order    = {}
					Ranker.Excluded = {}
					if not HAS_EXCLUDE then
						for _, v in ipairs(unified) do
							if v ~= DIVIDER_KEY then
								Ranker.Order[#Ranker.Order + 1] = v
							end
						end
						return
					end

					local pastDivider = false
					for _, v in ipairs(unified) do
						if v == DIVIDER_KEY then
							pastDivider = true
						elseif pastDivider then
							Ranker.Excluded[#Ranker.Excluded + 1] = v
						else
							Ranker.Order[#Ranker.Order + 1] = v
						end
					end

					-- NEW: push overflow items past the divider
					if #Ranker.Order > Ranker.Max then
						local dividerIdx = table.find(unified, DIVIDER_KEY)
						while #Ranker.Order > Ranker.Max do
							local overflow = Ranker.Order[#Ranker.Order]
							table.remove(Ranker.Order, #Ranker.Order)
							Ranker.Excluded[#Ranker.Excluded + 1] = overflow

							local itemIdx = table.find(unified, overflow)
							if itemIdx then
								table.remove(unified, itemIdx)
								dividerIdx = table.find(unified, DIVIDER_KEY)
								table.insert(unified, dividerIdx + 1, overflow)
							end
						end
					end
				end

				local function refreshNumbers()
					local activeNum = 1
					for _, v in ipairs(unified) do
						if v == DIVIDER_KEY then
							activeNum = nil
						else
							local f = frameMap[v]
							if f then
								if activeNum then
									-- NEW: style-aware display
									if Ranker.Style == "plus" then
										f.Holder.Num.Text = "+"
									else
										f.Holder.Num.Text = tostring(activeNum)
									end
									f.Holder.Num.TextColor3 = Library.Theme.Accent
									activeNum = activeNum + 1
								else
									f.Holder.Num.Text = "-"
									f.Holder.Num.TextColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(55, 55, 55))
								end
							end
						end
					end
				end

				local function refreshPositions(skipName)
					for i, v in ipairs(unified) do
						if v ~= skipName then
							local f = v == DIVIDER_KEY and dividerFrame or frameMap[v]
							if f then
								tween(f, 0.18, { Position = UDim2.new(0, 0, 0, slotY(i)) })
							end
						end
					end
				end

				Ranker.Frame = SelfModules.UI.Create("Frame", {
					Name = name,
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 42),
					ClipsDescendants = true,

					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),

						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 40),

							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0, 8),
								Size = UDim2.new(1, -35, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),

							SelfModules.UI.Create("TextLabel", {
								Name = "Count",
								BackgroundTransparency = 1,
								Position = UDim2.new(0.5, 0, 0, 8),
								Size = UDim2.new(0.5, -30, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = "",
								TextColor3 = SelfModules.UI.Color.Add(Library.Theme.TextColor, Color3.fromRGB(-60, -60, -60)),
								TextSize = 12,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Right,
							}),

							SelfModules.UI.Create("ImageLabel", {
								Name = "Indicator",
								AnchorPoint = Vector2.new(1, 0),
								BackgroundTransparency = 1,
								Position = UDim2.new(1, -5, 0, 5),
								Size = UDim2.new(0, 20, 0, 20),
								Image = "rbxassetid://9243354333",
							}),

							SelfModules.UI.Create("Frame", {
								Name = "Line",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
								BorderSizePixel = 0,
								Position = UDim2.new(0, 5, 0, 30),
								Size = UDim2.new(1, -10, 0, 2),
							}),
						}, UDim.new(0, 5)),

						SelfModules.UI.Create("Frame", {
							Name = "List",
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Position = UDim2.new(0, 5, 0, 44),
							Size = UDim2.new(1, -10, 0, 0),
							ClipsDescendants = true,
						}),
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))

				if HAS_EXCLUDE then
					dividerFrame = SelfModules.UI.Create("Frame", {
						Name = DIVIDER_KEY,
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 0, 0, 0),
						Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),

						SelfModules.UI.Create("Frame", {
							Name = "LineLeft",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
							BorderSizePixel = 0,
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 0, 0.5, 0),
							Size = UDim2.new(0.28, 0, 0, 1),
						}),

						SelfModules.UI.Create("TextLabel", {
							Name = "Label",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 1, 0),
							Font = Enum.Font.SourceSansBold,
							Text = "Excluded",
							TextColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(55, 55, 55)),
							TextSize = 13,
						}),

						SelfModules.UI.Create("Frame", {
							Name = "LineRight",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
							BorderSizePixel = 0,
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.new(1, 0, 0.5, 0),
							Size = UDim2.new(0.28, 0, 0, 1),
						}),
					})
					dividerFrame.Parent = Ranker.Frame.Holder.List
					unified[1] = DIVIDER_KEY
				end

				function Ranker:GetHeight()
					if not Ranker.Toggled then return 42 end
					return 42 + totalListH() + 8
				end

				function Ranker:UpdateHeight()
					Ranker.Frame.Holder.List.Size = UDim2.new(1, -10, 0, totalListH())
					Ranker.Frame.Holder.Holder.Count.Text = #Ranker.List > 0 and (#Ranker.List .. " items") or ""
					if Ranker.Toggled then
						Ranker.Frame.Size = UDim2.new(1, 2, 0, Ranker:GetHeight())
						Section:UpdateHeight()
					end
				end

				function Ranker:Toggle(bool)
					Ranker.Toggled = bool
					Ranker.Frame.Holder.List.Size = UDim2.new(1, -10, 0, totalListH())
					tween(Ranker.Frame, 0.5, { Size = UDim2.new(1, 2, 0, Ranker:GetHeight()) })
					tween(Ranker.Frame.Holder.Holder.Indicator, 0.5, { Rotation = bool and 90 or 0 })
					tween(Section.Frame, 0.5, { Size = UDim2.new(1, -10, 0, Section:GetHeight()) })
					tween(Tab.Frame, 0.5, { CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight()) })
				end

				local dragging    = nil
				local dragFrame   = nil
				local dragOffsetY = 0

				function Ranker:Add(itemName, excluded)
					local Item = { Name = itemName }

					local insertAt
					if HAS_EXCLUDE then
						if excluded then
							insertAt = #unified + 1
						else
							local di = table.find(unified, DIVIDER_KEY)
							insertAt = di
						end
					else
						insertAt = #unified + 1
					end

					local posY = slotY(insertAt)

					Item.Frame = SelfModules.UI.Create("Frame", {
						Name = itemName,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Position = UDim2.new(0, 0, 0, posY),
						Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),

						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),

							SelfModules.UI.Create("TextLabel", {
								Name = "Num",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0, 0),
								Size = UDim2.new(0, 18, 1, 0),
								Font = Enum.Font.SourceSansBold,
								Text = "?",
								TextColor3 = Library.Theme.Accent,
								TextSize = 15,
							}),

							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 26, 0, 0),
								Size = UDim2.new(1, -46, 1, 0),
								Font = Enum.Font.SourceSans,
								Text = itemName,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 15,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),

							SelfModules.UI.Create("TextLabel", {
								Name = "Handle",
								AnchorPoint = Vector2.new(1, 0.5),
								BackgroundTransparency = 1,
								Position = UDim2.new(1, -6, 0.5, 0),
								Size = UDim2.new(0, 16, 1, 0),
								Font = Enum.Font.SourceSansBold,
								Text = "::",
								TextColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(60, 60, 60)),
								TextSize = 15,
							}),
						}, UDim.new(0, 4)),
					}, UDim.new(0, 4))

					table.insert(unified, insertAt, itemName)
					Ranker.List[#Ranker.List + 1] = itemName
					frameMap[itemName] = Item.Frame
					Item.Frame.Parent = Ranker.Frame.Holder.List

					rebuildOrderExcluded()
					refreshNumbers()
					refreshPositions(nil)
					Ranker:UpdateHeight()

					Item.Frame.InputBegan:Connect(function(input)
						if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
						if dragging then return end

						dragging    = itemName
						dragFrame   = Item.Frame
						dragOffsetY = input.Position.Y - Item.Frame.AbsolutePosition.Y

						tween(Item.Frame, 0.1, {
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(30, 30, 30)),
						})
						Item.Frame.ZIndex        = 10
						Item.Frame.Holder.ZIndex = 10
					end)

					return Item
				end
				
				function Ranker:Move(itemName, exclude, position)
					assert(type(itemName) == "string", "Move requires an item name string")
					assert(type(exclude) == "boolean", "Move requires a boolean for exclude")
					assert(frameMap[itemName], "Move: item '" .. itemName .. "' does not exist")

					local dividerIdx = HAS_EXCLUDE and table.find(unified, DIVIDER_KEY) or nil

					-- remove item from its current position
					local currentIdx = table.find(unified, itemName)
					if not currentIdx then return end
					table.remove(unified, currentIdx)

					-- recalculate divider index after removal
					if dividerIdx then
						dividerIdx = table.find(unified, DIVIDER_KEY)
					end

					if not HAS_EXCLUDE or not exclude then
						-- moving INTO active (ranked) area
						local activeStart = 1
						local activeEnd   = dividerIdx and (dividerIdx - 1) or #unified

						if position then
							-- count active slots to find the real unified index
							local activeCount = 0
							local insertAt    = activeEnd + 1

							for i, v in ipairs(unified) do
								if v ~= DIVIDER_KEY then
									activeCount += 1
									if activeCount == position then
										-- shift everything from here forward
										insertAt = i
										break
									end
								end
							end

							table.insert(unified, insertAt, itemName)
						else
							-- no position given, append just before divider (end of active area)
							local insertAt = dividerIdx or (#unified + 1)
							table.insert(unified, insertAt, itemName)
						end

						-- enforce max: if inserting into active pushed us over, bump the last active item to excluded
						if Ranker.Max ~= math.huge then
							dividerIdx = table.find(unified, DIVIDER_KEY)
							local activeItems = {}
							for i, v in ipairs(unified) do
								if v ~= DIVIDER_KEY and (not dividerIdx or i < dividerIdx) then
									activeItems[#activeItems + 1] = { name = v, idx = i }
								end
							end

							if #activeItems > Ranker.Max then
								local bump = activeItems[#activeItems]
								table.remove(unified, bump.idx)
								dividerIdx = table.find(unified, DIVIDER_KEY)
								table.insert(unified, dividerIdx + 1, bump.name)
							end
						end

					else
						-- moving INTO excluded area
						if not HAS_EXCLUDE then
							-- no exclude zone exists, just append to end
							table.insert(unified, #unified + 1, itemName)
						elseif position then
							-- find the nth slot inside excluded zone
							dividerIdx = table.find(unified, DIVIDER_KEY)
							local excludedCount = 0
							local insertAt      = #unified + 1

							for i = dividerIdx + 1, #unified do
								local v = unified[i]
								if v ~= DIVIDER_KEY then
									excludedCount += 1
									if excludedCount == position then
										insertAt = i
										break
									end
								end
							end

							table.insert(unified, insertAt, itemName)
						else
							-- no position, append to end of excluded
							table.insert(unified, #unified + 1, itemName)
						end
					end

					rebuildOrderExcluded()
					refreshNumbers()
					refreshPositions(nil)

					-- animate the moved item to its new slot
					local newIdx = table.find(unified, itemName)
					if newIdx and frameMap[itemName] then
						tween(frameMap[itemName], 0.18, { Position = UDim2.new(0, 0, 0, slotY(newIdx)) })
					end

					Ranker:UpdateHeight()
					pcall(task.spawn, Ranker.Callback, Ranker.Order, Ranker.Excluded)
				end

				function Ranker:Remove(itemName, ignoreToggle)
					local ui = table.find(unified, itemName)
					if ui then table.remove(unified, ui) end
					frameMap[itemName]:Destroy()
					frameMap[itemName] = nil
					for i, v in next, Ranker.List do
						if v == itemName then table.remove(Ranker.List, i) break end
					end
					rebuildOrderExcluded()
					refreshNumbers()
					refreshPositions(nil)
					if Ranker.Toggled and not ignoreToggle then Ranker:UpdateHeight() end
					if #Ranker.List == 0 and not ignoreToggle then Ranker:Toggle(false) end
				end

				function Ranker:ClearList()
					for _ = 1, #Ranker.List do Ranker:Remove(Ranker.List[1], true) end
				end

				function Ranker:SetList(newList)
					Ranker:ClearList()
					for _, v in next, newList do Ranker:Add(v) end
				end

				function Ranker:GetOrder()    return Ranker.Order    end
				function Ranker:GetExcluded() return Ranker.Excluded end

				-- NEW: SortStyle method
				function Ranker:SortStyle(style)
					self.Style = style or "numeric"
					refreshNumbers()
				end
				
				function Ranker:GetStyle()
					return self.Style
				end
				
				function Ranker:SetMax(number)
					assert(type(number) == "number" and number > 0, "SetMax requires a positive number")
					Ranker.Max = number
					MAX = number
					rebuildOrderExcluded()
					refreshNumbers()
					refreshPositions(nil)
					Ranker:UpdateHeight()
				end

				function Ranker:GetMax()
					return Ranker.Max
				end

				UIS.InputChanged:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
					if not dragging or not dragFrame then return end

					local mouseY   = input.Position.Y
					local listTop  = Ranker.Frame.Holder.List.AbsolutePosition.Y
					local localY   = mouseY - dragOffsetY - listTop
					local clampedY = math.clamp(localY, 0, totalListH() - ITEM_HEIGHT)

					dragFrame.Position = UDim2.new(0, 0, 0, clampedY)

					local centerY    = clampedY + ITEM_HEIGHT / 2
					local targetSlot = math.clamp(math.round(centerY / ITEM_STRIDE) + 1, 1, #unified)

					if HAS_EXCLUDE and unified[targetSlot] == DIVIDER_KEY then
						local currentSlot = table.find(unified, dragging)
						targetSlot = targetSlot + (currentSlot and currentSlot < targetSlot and 1 or -1)
						targetSlot = math.clamp(targetSlot, 1, #unified)
					end

					-- NEW: block dragging above divider if max is reached and item is currently excluded
					if HAS_EXCLUDE and Ranker.Max ~= math.huge then
						local dividerIdx  = table.find(unified, DIVIDER_KEY)
						local currentSlot = table.find(unified, dragging)
						local isExcluded  = currentSlot and currentSlot > dividerIdx
						local atMax       = #Ranker.Order >= Ranker.Max

						if isExcluded and atMax and targetSlot <= dividerIdx then
							return -- block the move
						end
					end

					local currentSlot = table.find(unified, dragging)
					if targetSlot ~= currentSlot and currentSlot then
						table.remove(unified, currentSlot)
						table.insert(unified, targetSlot, dragging)
						rebuildOrderExcluded()
						refreshNumbers()
						refreshPositions(dragging)
					end
				end)

				UIS.InputEnded:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
					if not dragging or not dragFrame then return end

					local slot  = table.find(unified, dragging)
					local snapY = slotY(slot or 1)

					tween(dragFrame, 0.2, {
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Position = UDim2.new(0, 0, 0, snapY),
					})

					dragFrame.ZIndex        = 1
					dragFrame.Holder.ZIndex = 1
					dragging  = nil
					dragFrame = nil

					pcall(task.spawn, Ranker.Callback, Ranker.Order, Ranker.Excluded)
				end)

				Ranker.Frame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						and #Ranker.List > 0
						and Mouse.Y - Ranker.Frame.AbsolutePosition.Y <= 30 then
						Ranker:Toggle(not Ranker.Toggled)
					end
				end)

				Section.List[#Section.List + 1] = Ranker
				Ranker.Frame.Parent = Section.Frame.List

				for _, v in next, list do Ranker:Add(v) end

				return Ranker
			end

			-- Button
			function Section:AddButton(name, callback)
				local Button = {
					Name = name,
					Type = "Button",
					Callback = callback,
				}

				Button.Frame = SelfModules.UI.Create("Frame", {
					Name = name,
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 32),

					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Size = UDim2.new(1, -2, 1, -2),
						Position = UDim2.new(0, 1, 0, 1),

						SelfModules.UI.Create("TextButton", {
							Name = "Button",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
							Position = UDim2.new(0, 2, 0, 2),
							Size = UDim2.new(1, -4, 1, -4),
							AutoButtonColor = false,
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))

				-- Functions

				local function buttonVisual()
					task.spawn(function()
						local Visual = SelfModules.UI.Create("Frame", {
							Name = "Visual",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 0.9,
							Position = UDim2.new(0.5, 0, 0.5, 0),
							Size = UDim2.new(0, 0, 1, 0),
						}, UDim.new(0, 5))

						Visual.Parent = Button.Frame.Holder.Button
						tween(Visual, 0.5, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
						task.wait(0.5)
						Visual:Destroy()
					end)
				end

				-- Scripts

				Section.List[#Section.List + 1] = Button
				Button.Frame.Parent = Section.Frame.List

				Button.Frame.Holder.Button.MouseButton1Down:Connect(function()
					Button.Frame.Holder.Button.TextSize = 12
				end)

				Button.Frame.Holder.Button.MouseButton1Up:Connect(function()
					Button.Frame.Holder.Button.TextSize = 14
					buttonVisual()

					pcall(task.spawn, Button.Callback)
				end)

				Button.Frame.Holder.Button.MouseLeave:Connect(function()
					Button.Frame.Holder.Button.TextSize = 14
				end)

				return Button
			end

			-- AddToggle
			function Section:AddToggle(name, options, callback)
				local Toggle = {
					Name = name,
					Type = "Toggle",
					Flag = options.flag or name,
					Callback = callback,
					Boolean = nil,
				}
				Toggle.Frame = SelfModules.UI.Create("Frame", {
					Name = name,
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 32),
					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						SelfModules.UI.Create("TextLabel", {
							Name = "Label",
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 5, 0.5, -7),
							Size = UDim2.new(1, -50, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
						SelfModules.UI.Create("Frame", {
							Name = "Indicator",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
							Position = UDim2.new(1, -42, 0, 2),
							Size = UDim2.new(0, 40, 0, 26),
							SelfModules.UI.Create("Frame", {
								Name = "Filler",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
								Position = UDim2.new(0.5, 0, 0, 0),
								Size = UDim2.new(0.5, 0, 1, 0)
							}, UDim.new(0, 5)),
							SelfModules.UI.Create("ImageLabel", {
								Name = "Overlay",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
								Position = UDim2.new(0, 2, 0, 2),
								Size = UDim2.new(0, 22, 0, 22),
								Image = "http://www.roblox.com/asset/?id=7827504335",
								ImageTransparency = 1,
								SelfModules.UI.Create("ImageLabel", {
									Name = "Glow",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, -13, 0, -13),
									Size = UDim2.new(1, 26, 1, 26),
									Image = "rbxassetid://10822615828",
									ImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
									ScaleType = Enum.ScaleType.Slice,
									SliceCenter = Rect.new(99, 99, 99, 99),
									ImageTransparency = 0.5,
									SliceScale = 0.2,
								}),
							}, UDim.new(1, 0)),
						}, UDim.new(1, 0))
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))

				function Toggle:Set(bool, instant)
					Tab.Flags[Toggle.Flag] = bool
					tween(Toggle.Frame.Holder.Indicator.Overlay.Glow, instant and 0 or 0.25, { ImageColor3 = bool and Library.Theme.Accent or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)), SliceScale = bool and 0.2 or 1, ImageTransparency = bool and 0.85 or 0.5 })
					tween(Toggle.Frame.Holder.Indicator.Overlay, instant and 0 or 0.25, { ImageTransparency = bool and 0 or 1, Position = bool and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2) })
					tween(Toggle.Frame.Holder.Indicator.Overlay.UICorner, instant and 0 or 0.25, { CornerRadius = UDim.new(bool and 0 or 1, bool and 5 or 0) })
					tween(Toggle.Frame.Holder.Indicator.Overlay, "Cosmetic", instant and 0 or 0.25, { BackgroundColor3 = bool and SelfModules.UI.Color.Add(Library.Theme.Accent, Color3.fromRGB(5, 5, 5)) or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)) })
					Toggle.Boolean = bool
					pcall(task.spawn, Toggle.Callback, bool)
				end

				function Toggle:Get()
					return Toggle.Boolean
				end

				Section.List[#Section.List + 1] = Toggle
				Tab.Flags[Toggle.Flag] = options.default == true
				Toggle.Frame.Parent = Section.Frame.List
				Toggle.Frame.Holder.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						Toggle:Set(not Tab.Flags[Toggle.Flag], false)
					end
				end)
				Toggle:Set(options.default == true, true)
				Toggle.Boolean = options.default == true or false
				return Toggle
			end

			-- AddLabel
			function Section:AddLabel(name)
				local Label = {
					Name = name,
					Type = "Label",
				}
				Label.Frame = SelfModules.UI.Create("Frame", {
					Name = name,
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 22),
					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						SelfModules.UI.Create("TextLabel", {
							Name = "Label",
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 2, 0.5, 0),
							Size = UDim2.new(1, -4, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
						}),
					}, UDim.new(0, 5))
				}, UDim.new(0, 5))

				function Label:SetName(text)
					Label.Frame.Holder.Label.Text = text
				end
				function Label:GetName()
					return Label.Frame.Holder.Label.Text
				end

				Section.List[#Section.List + 1] = Label
				Label.Label = Label.Frame.Holder.Label
				Label.Frame.Parent = Section.Frame.List
				return Label
			end

			-- AddDualLabel
			function Section:AddDualLabel(options)
				options = options or {}
				local DualLabel = {
					Name = options[1].. " ".. options[2],
					Type = "DualLabel",
				}
				DualLabel.Frame = SelfModules.UI.Create("Frame", {
					Name = options[1].. " ".. options[2],
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 22),
					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						SelfModules.UI.Create("TextLabel", {
							Name = "Label1",
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 5, 0.5, 0),
							Size = UDim2.new(0.5, -5, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = options[1],
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
						SelfModules.UI.Create("TextLabel", {
							Name = "Label2",
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.new(0.5, 0, 0.5, 0),
							Size = UDim2.new(0.5, -5, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = options[2],
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Right,
						}),
					}, UDim.new(0, 5))
				}, UDim.new(0, 5))

				function DualLabel:SetLeftText(text)
					DualLabel.Frame.Holder.Label1.Text = text
				end
				function DualLabel:GetLeftText()
					return DualLabel.Frame.Holder.Label1.Text
				end
				function DualLabel:SetRightText(text)
					DualLabel.Frame.Holder.Label2.Text = text
				end
				function DualLabel:GetRightText()
					return DualLabel.Frame.Holder.Label2.Text
				end

				Section.List[#Section.List + 1] = DualLabel
				DualLabel.Label1 = DualLabel.Frame.Holder.Label1
				DualLabel.Label2 = DualLabel.Frame.Holder.Label2
				DualLabel.Frame.Parent = Section.Frame.List
				return DualLabel
			end

			-- AddClipboardLabel
			function Section:AddClipboardLabel(name, callback)
				local ClipboardLabel = {
					Name = name,
					Type = "ClipboardLabel",
					Callback = callback,
				}
				ClipboardLabel.Frame = SelfModules.UI.Create("Frame", {
					Name = name,
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 22),
					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						SelfModules.UI.Create("TextLabel", {
							Name = "Label",
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 2, 0.5, 0),
							Size = UDim2.new(1, -22, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
						}),
						SelfModules.UI.Create("ImageLabel", {
							Name = "Icon",
							BackgroundTransparency = 1,
							Position = UDim2.new(1, -18, 0, 2),
							Size = UDim2.new(0, 16, 0, 16),
							Image = "rbxassetid://9243581053",
						}),
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))

				function ClipboardLabel:SetName(text)
					ClipboardLabel.Frame.Holder.Label.Text = text
				end
				function ClipboardLabel:GetName()
					return ClipboardLabel.Frame.Holder.Label.Text
				end

				Section.List[#Section.List + 1] = ClipboardLabel
				ClipboardLabel.Label = ClipboardLabel.Frame.Holder.Label
				ClipboardLabel.Frame.Parent = Section.Frame.List
				ClipboardLabel.Frame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local s, result = pcall(ClipboardLabel.Callback)
						if s then warn(result) end
					end
				end)
				return ClipboardLabel
			end

			-- AddBox
			function Section:AddBox(name, options, callback)
				local Box = {
					Name = name,
					Type = "Box",
					Extend = options.extend or 200,
					Callback = callback,
				}
				Box.Frame = SelfModules.UI.Create("Frame", {
					Name = name,
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 32),
					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						SelfModules.UI.Create("TextLabel", {
							Name = "Label",
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 5, 0.5, -7),
							Size = UDim2.new(1, -135, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
						SelfModules.UI.Create("Frame", {
							Name = "TextBox",
							AnchorPoint = Vector2.new(1, 0),
							BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
							Position = UDim2.new(1, -2, 0, 2),
							Size = UDim2.new(0, 140, 1, -4),
							ZIndex = 2,
							SelfModules.UI.Create("Frame", {
								Name = "Holder",
								BackgroundColor3 = Library.Theme.SectionColor,
								Position = UDim2.new(0, 1, 0, 1),
								Size = UDim2.new(1, -2, 1, -2),
								ZIndex = 2,
								SelfModules.UI.Create("TextBox", {
									Name = "Box",
									AnchorPoint = Vector2.new(0, 0.5),
									BackgroundTransparency = 1,
									ClearTextOnFocus = options.clearonfocus ~= true,
									Position = UDim2.new(0, 28, 0.5, 0),
									Size = UDim2.new(1, -30, 1, 0),
									Font = Enum.Font.SourceSans,
									PlaceholderText = "Text",
									Text = "",
									TextColor3 = Library.Theme.TextColor,
									TextSize = 14,
									TextWrapped = true,
								}),
								SelfModules.UI.Create("TextLabel", {
									Name = "Icon",
									AnchorPoint = Vector2.new(0, 0.5),
									BackgroundTransparency = 1,
									Position = UDim2.new(0, 6, 0.5, 0),
									Size = UDim2.new(0, 14, 0, 14),
									Font = Enum.Font.SourceSansBold,
									Text = "T",
									TextColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(40, 40, 40)),
									TextSize = 18,
									TextWrapped = true,
								}),
							}, UDim.new(0, 5)),
						}, UDim.new(0, 5))
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))
				
				local function extendBox(bool)
					tween(Box.Frame.Holder.TextBox, 0.25, { Size = UDim2.new(0, bool and math.clamp(math.abs(Box.Extend), 140, 386 - (Box.Frame.Holder.Label.TextBounds.X + 10)) or bool and 200 or 140, 1, -4) })
				end

				function Box:SetName(text)
					Box.Frame.Holder.Label.Text = text
				end
				function Box:GetName()
					return Box.Frame.Holder.Label.Text
				end
				function Box:SetText(text)
					Box.Frame.Holder.TextBox.Box.Text = text
				end
				function Box:GetText()
					return Box.Frame.Holder.TextBox.Box.Text
				end
				function Box:SetExtend(number)
					options.extend = number
				end
				function Box:GetExtend()
					return math.abs(options.extend)
				end
				function Box:Clear()
					Box.Frame.Holder.TextBox.Box.Text = ""
					extendBox(false)
				end

				Section.List[#Section.List + 1] = Box
				Box.Box = Box.Frame.Holder.TextBox.Holder.Box
				Box.Frame.Parent = Section.Frame.List
				Box.Frame.Holder.TextBox.Holder.MouseEnter:Connect(function()
					extendBox(true)
				end)
				Box.Frame.Holder.TextBox.Holder.MouseLeave:Connect(function()
					if not Box.Frame.Holder.TextBox.Holder.Box:IsFocused() then
						extendBox(false)
					end
				end)
				Box.Frame.Holder.TextBox.Holder.Box.FocusLost:Connect(function()
					if Box.Frame.Holder.TextBox.Holder.Box.Text == "" and options.fireonempty ~= true then
						return
					end
					extendBox(false)
					pcall(task.spawn, Box.Callback, Box.Frame.Holder.TextBox.Holder.Box.Text)
					if options.keepfocused ~= nil and options.keepfocused == true then
						Box.Frame.Holder.TextBox.Holder.Box:CaptureFocus()
					end
				end)
				Box.Frame.Holder.TextBox.Holder.Box.Focused:Connect(function()
					extendBox(true)
				end)
				Box.Frame.Holder.TextBox.Holder.Box:GetPropertyChangedSignal("Text"):Connect(function()
					if options.fireonchange ~= true then return end
					if Box.Frame.Holder.TextBox.Holder.Box.Text == "" and options.fireonempty ~= true then return end
					pcall(task.spawn, Box.Callback, Box.Frame.Holder.TextBox.Holder.Box.Text)
				end)
				return Box
			end

			-- AddBind
			function Section:AddBind(name, bind, options, callback)
				local Bind = {
					Name = name,
					Type = "Bind",
					Bind = bind,
					Flag = options.flag or name,
					Callback = callback,
					Boolean = nil,
				}
				Bind.Frame = SelfModules.UI.Create("Frame", {
					Name = name,
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 32),
					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						SelfModules.UI.Create("TextLabel", {
							Name = "Label",
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 5, 0.5, -7),
							Size = UDim2.new(1, -135, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
						SelfModules.UI.Create("Frame", {
							Name = "Bind",
							AnchorPoint = Vector2.new(1, 0),
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
							Position = UDim2.new(1, -2, 0, 2),
							Size = UDim2.new(0, 78, 0, 26),
							ZIndex = 2,
							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
								Position = UDim2.new(0, 1, 0, 1),
								Size = UDim2.new(1, -2, 1, -2),
								Font = Enum.Font.SourceSans,
								Text = "",
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
							}, UDim.new(0, 5)),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))

				local indicatorEntered = false
				local connections = {}

				local function listenForInput()
					if connections.listen then connections.listen:Disconnect() end
					Bind.Frame.Holder.Bind.Label.Text = "..."
					ListenForInput = true
					connections.listen = UIS.InputBegan:Connect(function(input, gameProcessed)
						if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
							Bind:Set(input.KeyCode)
						end
					end)
				end
				local function cancelListen()
					if connections.listen then connections.listen:Disconnect(); connections.listen = nil end
					Bind.Frame.Holder.Bind.Label.Text = Bind.Bind.Name
					task.spawn(function() RS.RenderStepped:Wait(); ListenForInput = false end)
				end

				function Bind:Set(bind)
					Bind.Bind = bind
					Bind.Frame.Holder.Bind.Label.Text = bind.Name
					Bind.Frame.Holder.Bind.Size = UDim2.new(0, math.max(12 + math.round(TXS:GetTextSize(bind.Name, 14, Enum.Font.SourceSans, Vector2.new(9e9)).X + 0.5), 42), 0, 26)
					if connections.listen then cancelListen() end
					if options.toggleable == true then
						Bind.Frame.Holder.Indicator.Position = UDim2.new(1, -(Bind.Frame.Holder.Bind.Size.X.Offset+5), 0, 2)
					end
				end
				function Bind:Get()
					return Bind.Boolean
				end
				function Bind:SetName(text)
					Bind.Frame.Holder.Label.Text = text
				end
				function Bind:GetName()
					return Bind.Frame.Holder.Label.Text
				end
				if options.toggleable == true then
					function Bind:Toggle(bool, instant)
						Tab.Flags[Bind.Flag] = bool
						tween(Bind.Frame.Holder.Indicator.Overlay.Glow, instant and 0 or 0.25, { ImageColor3 = bool and Library.Theme.Accent or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)), SliceScale = bool and 0.2 or 1, ImageTransparency = bool and 0.85 or 0.5 })
						tween(Bind.Frame.Holder.Indicator.Overlay, instant and 0 or 0.25, { ImageTransparency = bool and 0 or 1, Position = bool and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2) })
						tween(Bind.Frame.Holder.Indicator.Overlay.UICorner, instant and 0 or 0.25, { CornerRadius = UDim.new(bool and 0 or 1, bool and 5 or 0) })
						tween(Bind.Frame.Holder.Indicator.Overlay, "Cosmetic", instant and 0 or 0.25, { BackgroundColor3 = bool and SelfModules.UI.Color.Add(Library.Theme.Accent, Color3.fromRGB(5, 5, 5)) or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)) })
						Bind.Boolean = bool
						if options.fireontoggle ~= false then
							pcall(task.spawn, Bind.Callback, Bind.Bind)
						end
					end
				end

				Section.List[#Section.List + 1] = Bind
				Bind.Frame.Parent = Section.Frame.List
				Bind.Frame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if indicatorEntered == true then
							Bind:Toggle(not Tab.Flags[Bind.Flag], false)
						else
							listenForInput()
						end
					end
				end)
				UIS.InputBegan:Connect(function(input)
					if input.KeyCode == Bind.Bind then
						if (options.toggleable == true and Tab.Flags[Bind.Flag] == false) or ListenForInput then
							return
						end
						pcall(task.spawn, Bind.Callback, Bind.Bind)
					end
				end)

				if options.toggleable == true then
					local indicator = SelfModules.UI.Create("Frame", {
						Name = "Indicator",
						AnchorPoint = Vector2.new(1, 0),
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
						Position = UDim2.new(1, -(Bind.Frame.Holder.Bind.Size.X.Offset+5), 0, 2),
						Size = UDim2.new(0, 40, 0, 26),
						SelfModules.UI.Create("Frame", {
							Name = "Filler",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
							Position = UDim2.new(0.5, 0, 0, 0),
							Size = UDim2.new(0.5, 0, 1, 0)
						}, UDim.new(0, 5)),
						SelfModules.UI.Create("ImageLabel", {
							Name = "Overlay",
							ImageColor3 = Library.Theme.TextColor,
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
							Position = UDim2.new(0, 2, 0, 2),
							Size = UDim2.new(0, 22, 0, 22),
							Image = "http://www.roblox.com/asset/?id=7827504335",
							SelfModules.UI.Create("ImageLabel", {
								Name = "Glow",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, -13, 0, -13),
								Size = UDim2.new(1, 26, 1, 26),
								Image = "rbxassetid://10822615828",
								ImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
								ScaleType = Enum.ScaleType.Slice,
								SliceCenter = Rect.new(99, 99, 99, 99),
								ImageTransparency = 0.5,
								SliceScale = 0.2,
							}),
						}, UDim.new(1, 0)),
					}, UDim.new(1, 0))
					Tab.Flags[Bind.Flag] = options.default == true
					indicator.Parent = Bind.Frame.Holder
					Bind.Frame.Holder.Indicator.MouseEnter:Connect(function()
						indicatorEntered = true
					end)
					Bind.Frame.Holder.Indicator.MouseLeave:Connect(function()
						indicatorEntered = false
					end)
					Bind:Toggle(options.default == true, true)
					Bind.Boolean = options.default == true or false
				end
				Bind:Set(Bind.Bind)
				return Bind
			end

			-- AddSlider
			function Section:AddSlider(name, min, max, default, options, callback)
				local isDual = options.dual == true

				-- Resolve default values
				local defaultVal1, defaultVal2
				if isDual then
					if type(default) == "table" then
						defaultVal1 = default[1] ~= nil and default[1] or min
						defaultVal2 = default[2] ~= nil and default[2] or max
					else
						defaultVal1 = min
						defaultVal2 = max
					end
				end

				local Slider = {
					Name   = name,
					Type   = "Slider",
					Value  = isDual and defaultVal1 or default,
					Value2 = isDual and defaultVal2 or nil,
					Min    = min,
					Max    = max,
					Flag   = options.flag or name,
					Cap    = options.cap or false,
					Callback = callback,
				}

				Slider.Frame = SelfModules.UI.Create("Frame", {
					Name = name,
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 41),
					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						SelfModules.UI.Create("TextLabel", {
							Name = "Label",
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 5, 0, 5),
							Size = UDim2.new(1, -75, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
						SelfModules.UI.Create("Frame", {
							Name = "Slider",
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 5, 1, -15),
							Size = UDim2.new(1, -10, 0, 10),
							SelfModules.UI.Create("Frame", {
								Name = "Bar",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
								ClipsDescendants = false,
								Size = UDim2.new(1, 0, 1, 0),
								SelfModules.UI.Create("Frame", {
									Name = "Fill",
									BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.Accent, Color3.fromRGB(10, 10, 10)),
									Size = UDim2.new(0.5, 0, 1, 0),
									SelfModules.UI.Create("ImageLabel", {
										Name = "Glow",
										BackgroundTransparency = 1,
										Position = UDim2.new(0, -12, 0, -12),
										Size = UDim2.new(1, 30, 1, 24),
										Image = "rbxassetid://10822615828",
										ImageColor3 = SelfModules.UI.Color.Sub(Library.Theme.Accent, Color3.fromRGB(10, 10, 10)),
										ScaleType = Enum.ScaleType.Slice,
										SliceCenter = Rect.new(99, 99, 99, 99),
										ImageTransparency = 0.9,
										SliceScale = 1,
									}),
								}, UDim.new(0, 5)),
							}, UDim.new(0, 5)),
							SelfModules.UI.Create("Frame", {
								Name = "Point",
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundColor3 = Library.Theme.Accent,
								Position = UDim2.new(0.5, 0, 0.5, 0),
								Size = UDim2.new(0, 12, 0, 12),
							}, UDim.new(0, 5)),
						}),
						SelfModules.UI.Create("TextBox", {
							Name = "Input",
							AnchorPoint = Vector2.new(1, 0),
							BackgroundTransparency = 1,
							PlaceholderText = "...",
							Position = UDim2.new(1, -5, 0, 5),
							Size = UDim2.new(0, 60, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = "",
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Right,
						}),
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))

				-- Dual-mode extras: second point + wider input label room
				if isDual then
					local Point2 = SelfModules.UI.Create("Frame", {
						Name = "Point2",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Library.Theme.Accent,
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.new(0, 12, 0, 12),
					}, UDim.new(0, 5))
					Point2.Parent = Slider.Frame.Holder.Slider
					-- Widen the input display and shrink label to avoid overlap
					Slider.Frame.Holder.Input.Size  = UDim2.new(0, 90, 0, 14)
					Slider.Frame.Holder.Label.Size  = UDim2.new(1, -100, 0, 14)
				end

				local connections    = {}
				local draggingPoint  = nil  -- 1 = left handle, 2 = right handle (dual only)

				local function getSliderValue(val)
					if options.cap == true then
						val = math.clamp(val, Slider.Min, Slider.Max)
					else
						val = math.clamp(val, -math.huge, math.huge)
					end
					if options.rounded == true then
						val = math.floor(val)
					end
					return val
				end

				local function sliderVisual(v1, v2)
					local sliderW    = math.max(Slider.Frame.Holder.Slider.AbsoluteSize.X, 1)
					local pointPad   = 1 / sliderW * 5
					if isDual then
						v1 = getSliderValue(v1)
						v2 = getSliderValue(v2)
						Slider.Frame.Holder.Input.Text = v1 .. " — " .. v2
						local p1 = math.clamp((v1 - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
						local p2 = math.clamp((v2 - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
						-- Fill spans between the two points
						tween(Slider.Frame.Holder.Slider.Bar.Fill, 0.25, {
							Position = UDim2.new(p1, 0, 0, 0),
							Size     = UDim2.new(p2 - p1, 0, 1, 0),
						})
						tween(Slider.Frame.Holder.Slider.Point, 0.25, {
							Position = UDim2.fromScale(math.clamp(p1, pointPad, 1 - pointPad), 0.5),
						})
						local pt2 = Slider.Frame.Holder.Slider:FindFirstChild("Point2")
						if pt2 then
							tween(pt2, 0.25, {
								Position = UDim2.fromScale(math.clamp(p2, pointPad, 1 - pointPad), 0.5),
							})
						end
					else
						v1 = getSliderValue(v1)
						Slider.Frame.Holder.Input.Text = v1
						local pct = 1 - ((Slider.Max - v1) / (Slider.Max - Slider.Min))
						tween(Slider.Frame.Holder.Slider.Bar.Fill, 0.25, { Size = UDim2.new(pct, 0, 1, 0) })
						tween(Slider.Frame.Holder.Slider.Point, 0.25, {
							Position = UDim2.fromScale(math.clamp(pct, pointPad, 1 - pointPad), 0.5),
						})
					end
				end

				function Slider:Set(v1, v2)
					if isDual then
						v1 = getSliderValue(v1 ~= nil and v1 or Slider.Value)
						v2 = getSliderValue(v2 ~= nil and v2 or Slider.Value2)
						if v1 > v2 then v1, v2 = v2, v1 end
						Slider.Value  = v1
						Slider.Value2 = v2
						sliderVisual(v1, v2)
						if options.toggleable == true and Tab.Flags[Slider.Flag] == false then return end
						pcall(task.spawn, Slider.Callback, v1, v2, Tab.Flags[Slider.Flag] or nil)
					else
						v1 = getSliderValue(v1)
						Slider.Value = v1
						sliderVisual(v1)
						if options.toggleable == true and Tab.Flags[Slider.Flag] == false then return end
						pcall(task.spawn, Slider.Callback, v1, Tab.Flags[Slider.Flag] or nil)
					end
				end

				function Slider:Get()
					if isDual then
						return Slider.Value, Slider.Value2
					end
					return Slider.Value
				end

				function Slider:Change(newMin, newMax)
					Slider.Min = newMin
					Slider.Max = newMax
					if isDual then
						Slider:Set(getSliderValue(Slider.Value), getSliderValue(Slider.Value2))
					else
						Slider:Set(getSliderValue(Slider.Value))
					end
				end

				function Slider:SetName(text)
					Slider.Frame.Holder.Label.Text = text
				end
				function Slider:GetName()
					return Slider.Frame.Holder.Label.Text
				end

				if options.toggleable == true then
					function Slider:Toggle(bool, instant)
						Tab.Flags[Slider.Flag] = bool
						tween(Slider.Frame.Holder.Indicator.Overlay.Glow, instant and 0 or 0.25, {
							ImageColor3    = bool and Library.Theme.Accent or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
							SliceScale     = bool and 0.2 or 1,
							ImageTransparency = bool and 0.85 or 0.5,
						})
						tween(Slider.Frame.Holder.Indicator.Overlay, instant and 0 or 0.25, {
							ImageTransparency = bool and 0 or 1,
							Position          = bool and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2),
						})
						tween(Slider.Frame.Holder.Indicator.Overlay.UICorner, instant and 0 or 0.25, {
							CornerRadius = UDim.new(bool and 0 or 1, bool and 5 or 0),
						})
						tween(Slider.Frame.Holder.Indicator.Overlay, "Cosmetic", instant and 0 or 0.25, {
							BackgroundColor3 = bool
								and SelfModules.UI.Color.Add(Library.Theme.Accent, Color3.fromRGB(5, 5, 5))
								or  SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
						})
						if options.fireontoggle ~= false then
							if isDual then
								pcall(task.spawn, Slider.Callback, Slider.Value, Slider.Value2, bool)
							else
								pcall(task.spawn, Slider.Callback, Slider.Value, bool)
							end
						end
					end
				end

				Section.List[#Section.List + 1] = Slider
				Slider.Frame.Parent = Section.Frame.List

				-- Drag start: pick closest point in dual mode
				Slider.Frame.Holder.Slider.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if isDual then
							local sliderX = Slider.Frame.Holder.Slider.AbsolutePosition.X
							local sliderW = math.max(Slider.Frame.Holder.Slider.AbsoluteSize.X, 1)
							local mPct    = math.clamp((Mouse.X - sliderX) / sliderW, 0, 1)
							local p1      = math.clamp((Slider.Value  - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
							local p2      = math.clamp((Slider.Value2 - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
							draggingPoint = math.abs(mPct - p1) <= math.abs(mPct - p2) and 1 or 2
						end
						connections.move = Mouse.Move:Connect(function()
							local sliderPercent = math.clamp(
								(Mouse.X - Slider.Frame.Holder.Slider.AbsolutePosition.X)
									/ math.max(Slider.Frame.Holder.Slider.AbsoluteSize.X, 1),
								0, 1
							)
							local sv = math.floor((Slider.Min + sliderPercent * (Slider.Max - Slider.Min)) * 10) / 10
							if isDual then
								if draggingPoint == 1 then
									local nv1 = math.min(sv, Slider.Value2)
									if options.fireondrag ~= false then Slider:Set(nv1, Slider.Value2)
									else sliderVisual(nv1, Slider.Value2) end
								else
									local nv2 = math.max(sv, Slider.Value)
									if options.fireondrag ~= false then Slider:Set(Slider.Value, nv2)
									else sliderVisual(Slider.Value, nv2) end
								end
							else
								if options.fireondrag ~= false then Slider:Set(sv)
								else sliderVisual(sv) end
							end
						end)
					end
				end)

				-- Drag end: commit final value
				Slider.Frame.Holder.Slider.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if connections.move then connections.move:Disconnect(); connections.move = nil end
						local sliderPercent = math.clamp(
							(Mouse.X - Slider.Frame.Holder.Slider.AbsolutePosition.X)
								/ math.max(Slider.Frame.Holder.Slider.AbsoluteSize.X, 1),
							0, 1
						)
						local sv = math.floor((Slider.Min + sliderPercent * (Slider.Max - Slider.Min)) * 10) / 10
						if isDual then
							if options.fireondrag ~= true then
								if draggingPoint == 1 then
									Slider:Set(math.min(sv, Slider.Value2), Slider.Value2)
								else
									Slider:Set(Slider.Value, math.max(sv, Slider.Value))
								end
							end
							draggingPoint = nil
						else
							if options.fireondrag ~= true then
								Slider:Set(sv)
							end
						end
					end
				end)

				-- Manual text input (single mode only; dual uses display-only)
				Slider.Frame.Holder.Input.FocusLost:Connect(function()
					if isDual then return end
					Slider.Frame.Holder.Input.Text = string.sub(Slider.Frame.Holder.Input.Text, 1, 10)
					if tonumber(Slider.Frame.Holder.Input.Text) then
						Slider:Set(Slider.Frame.Holder.Input.Text)
					end
				end)

				if options.toggleable == true then
					local indicator = SelfModules.UI.Create("Frame", {
						Name = "Indicator",
						AnchorPoint = Vector2.new(1, 1),
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
						Position = UDim2.new(1, -2, 1, -2),
						Size = UDim2.new(0, 40, 0, 26),
						SelfModules.UI.Create("Frame", {
							Name = "Filler",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
							Position = UDim2.new(0.5, 0, 0, 0),
							Size = UDim2.new(0.5, 0, 1, 0)
						}, UDim.new(0, 5)),
						SelfModules.UI.Create("ImageLabel", {
							Name = "Overlay",
							ImageColor3 = Library.Theme.TextColor,
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
							Position = UDim2.new(0, 2, 0, 2),
							Size = UDim2.new(0, 22, 0, 22),
							Image = "http://www.roblox.com/asset/?id=7827504335",
							SelfModules.UI.Create("ImageLabel", {
								Name = "Glow",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, -13, 0, -13),
								Size = UDim2.new(1, 26, 1, 26),
								Image = "rbxassetid://10822615828",
								ImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
								ScaleType = Enum.ScaleType.Slice,
								SliceCenter = Rect.new(99, 99, 99, 99),
								ImageTransparency = 0.5,
								SliceScale = 0.2,
							}),
						}, UDim.new(1, 0)),
					}, UDim.new(1, 0))
					Tab.Flags[Slider.Flag] = options.default == true
					Slider.Frame.Size = UDim2.new(1, 2, 0, 54)
					Slider.Frame.Holder.Slider.Size = UDim2.new(1, -50, 0, 10)
					indicator.Parent = Slider.Frame.Holder
					Slider.Frame.Holder.Indicator.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							Slider:Toggle(not Tab.Flags[Slider.Flag], false)
						end
					end)
					Slider:Toggle(options.default == true, true)
				end

				if isDual then
					Slider:Set(defaultVal1, defaultVal2)
				else
					Slider:Set(Slider.Value)
				end

				return Slider
			end

			-- AddDropdown
			function Section:AddDropdown(name, list, options, callback)
				local Dropdown = {
					Name = name,
					Type = "Dropdown",
					Toggled = false,
					Selected = options and options.multi == true and {} or "",
					List = {},
					Callback = callback,
				}
				local ListObjects = {}

				Dropdown.Frame = SelfModules.UI.Create("Frame", {
					Name = "Dropdown",
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 42),
					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 40),
							SelfModules.UI.Create("Frame", {
								Name = "Displays",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0, 8),
								Size = UDim2.new(1, -35, 0, 14),
								SelfModules.UI.Create("TextBox", {
									Name = "SearchBox",
									ClearTextOnFocus = false,
									TextTransparency = 1,
									BackgroundTransparency = 1,
									PlaceholderText = "Search",
									PlaceholderColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
									Font = Enum.Font.SourceSansBold,
									Text = "",
									TextSize = 14,
									TextWrapped = false,
									TextTruncate = Enum.TextTruncate.SplitWord,
									TextColor3 = Library.Theme.TextColor,
									TextXAlignment = Enum.TextXAlignment.Left,
									Size = UDim2.new(0, 0, 1, 0),
								}),
								SelfModules.UI.Create("TextLabel", {
									Name = "Label",
									BackgroundTransparency = 1,
									Size = UDim2.new(0.5, 0, 1, 0),
									Font = Enum.Font.SourceSans,
									Text = name,
									TextColor3 = Library.Theme.TextColor,
									TextSize = 14,
									TextWrapped = true,
									TextXAlignment = Enum.TextXAlignment.Left,
								}),
								SelfModules.UI.Create("TextLabel", {
									Name = "Selected",
									BackgroundTransparency = 1,
									Position = UDim2.new(0.5, 0, 0, 0),
									Size = UDim2.new(0.5, 0, 1, 0),
									Font = Enum.Font.SourceSans,
									Text = "",
									TextColor3 = Library.Theme.TextColor,
									TextSize = 14,
									TextWrapped = true,
									TextXAlignment = Enum.TextXAlignment.Right,
								}),
							}),
							SelfModules.UI.Create("ImageLabel", {
								Name = "Indicator",
								AnchorPoint = Vector2.new(1, 0),
								BackgroundTransparency = 1,
								Position = UDim2.new(1, -5, 0, 5),
								Size = UDim2.new(0, 20, 0, 20),
								Image = "rbxassetid://9243354333",
							}),
							SelfModules.UI.Create("Frame", {
								Name = "Line",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
								BorderSizePixel = 0,
								Position = UDim2.new(0, 5, 0, 30),
								Size = UDim2.new(1, -10, 0, 2),
							}),
						}, UDim.new(0, 5)),
						SelfModules.UI.Create("ScrollingFrame", {
							Name = "List",
							Active = true,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Position = UDim2.new(0, 5, 0, 40),
							Size = UDim2.new(1, -10, 1, -40),
							CanvasSize = UDim2.new(0, 0, 0, 0),
							ScrollBarImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
							ScrollBarThickness = 5,
							SelfModules.UI.Create("UIListLayout", {
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 5),
							}),
						}),
					}, UDim.new(0,5)),
				}, UDim.new(0, 5))

				function Dropdown:GetHeight()
					return 42 + (Dropdown.Toggled == true and math.min(#Dropdown.List, 5) * 27 or 0)
				end
				function Dropdown:UpdateHeight()
					Dropdown.Frame.Holder.List.CanvasSize = UDim2.new(0, 0, 0, #Dropdown.List * 27 - 5)
					if Dropdown.Toggled == true then
						Dropdown.Frame.Size = UDim2.new(1, 2, 0, Dropdown:GetHeight())
						Section:UpdateHeight()
					end
				end
				function Dropdown:Add(name, options, callback)
					local Item = {
						Name = name,
						Callback = callback,
					}
					Item.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, -10, 0, 22),
						SelfModules.UI.Create("TextButton", {
							Name = "Button",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))
					function Dropdown:SetName(text)
						Dropdown.Frame.Holder.Holder.Displays.Label = text
					end
					function Dropdown:GetName()
						return Dropdown.Frame.Holder.Holder.Displays.Label
					end
					Dropdown.List[#Dropdown.List + 1] = name
					ListObjects[#ListObjects + 1] = Item
					Item.Frame.Parent = Dropdown.Frame.Holder.List
					if Dropdown.Toggled == true then Dropdown:UpdateHeight() end
					Item.Frame.Button.Activated:Connect(function()
						if typeof(Item.Callback) == "function" then
							pcall(task.spawn, Item.Callback)
						else
							Dropdown:Select(Item.Name)
						end
					end)
					Dropdown.Frame.Holder.Holder.Displays.SearchBox.Size = UDim2.new(0, Dropdown.Frame.Holder.Holder.Displays.Label.TextBounds.X, 1, 0)
					Dropdown.Frame.Holder.Holder.Displays.SearchBox.Focused:Connect(function()
						Dropdown:Toggle(true)
						tween(Dropdown.Frame.Holder.Holder.Displays.SearchBox, 2, { Size = UDim2.new(1, -(Dropdown.Frame.Holder.Holder.Displays.Selected.TextBounds.X-1), 1, 0), TextTransparency = 0 })
						tween(Dropdown.Frame.Holder.Holder.Displays.Label, 0.5, { TextTransparency = 1 })
					end)
					Dropdown.Frame.Holder.Holder.Displays.SearchBox.FocusLost:Connect(function()
						tween(Dropdown.Frame.Holder.Holder.Displays.SearchBox, 0.5, { Size = UDim2.new(0, Dropdown.Frame.Holder.Holder.Displays.Label.TextBounds.X, 1, 0) })
						tween(Dropdown.Frame.Holder.Holder.Displays.Label, 0.5, { TextTransparency = 0 })
						Dropdown.Frame.Holder.Holder.Displays.SearchBox.Text = ""
					end)
					Dropdown.Frame.Holder.Holder.Displays.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
						local searchText = Dropdown.Frame.Holder.Holder.Displays.SearchBox.Text:lower()
						for _, item in pairs(Dropdown.Frame.Holder.List:GetChildren()) do
							if item:IsA("Frame") then
								item.Visible = item.Name:lower():find(searchText) ~= nil
							end
						end
					end)
					return Item
				end
				function Dropdown:Remove(name, ignoreToggle)
					for i, v in next, Dropdown.List do
						if v == name then
							local item = ListObjects[i]
							if item then
								item.Frame:Destroy()
								table.remove(Dropdown.List, i)
								table.remove(ListObjects, i)
								if Dropdown.Toggled then Dropdown:UpdateHeight() end
								if #Dropdown.List == 0 and not ignoreToggle then Dropdown:Toggle(false) end
							end
							break
						end
					end
				end
				function Dropdown:ClearList()
					for _ = 1, #Dropdown.List do
						Dropdown:Remove(Dropdown.List[1], true)
					end
				end
				function Dropdown:SetList(list)
					Dropdown:ClearList()
					for _, v in next, list do Dropdown:Add(v) end
				end
				function Dropdown:Select(itemName)
					if options and options.multi == true then
						if table.find(Dropdown.Selected, itemName) then
							for i, v in ipairs(Dropdown.Selected) do
								if v == itemName then
									table.remove(Dropdown.Selected, i)
									break
								end
							end
						else
							table.insert(Dropdown.Selected, itemName)
						end
						Dropdown.Frame.Holder.Holder.Displays.Selected.Text = table.concat(Dropdown.Selected, ", ")
						pcall(task.spawn, Dropdown.Callback, Dropdown.Selected)
					else
						Dropdown.Selected = itemName
						Dropdown.Frame.Holder.Holder.Displays.Selected.Text = itemName
						Dropdown:Toggle(false)
						pcall(task.spawn, Dropdown.Callback, itemName)
					end
				end
				function Dropdown:Toggle(bool)
					Dropdown.Toggled = bool
					tween(Dropdown.Frame, 0.5, { Size = UDim2.new(1, 2, 0, Dropdown:GetHeight()) })
					tween(Dropdown.Frame.Holder.Holder.Indicator, 0.5, { Rotation = bool and 90 or 0 })
					tween(Section.Frame, 0.5, { Size = UDim2.new(1, -10, 0, Section:GetHeight()) })
					tween(Tab.Frame, 0.5, { CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight()) })
				end

				Section.List[#Section.List + 1] = Dropdown
				Dropdown.Frame.Parent = Section.Frame.List
				Dropdown.Frame.Holder.List.ChildAdded:Connect(function(c)
					if c.ClassName == "Frame" then Dropdown:UpdateHeight() end
				end)
				Dropdown.Frame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and #Dropdown.List > 0 and Mouse.Y - Dropdown.Frame.AbsolutePosition.Y <= 30 then
						Dropdown:Toggle(not Dropdown.Toggled)
					end
				end)
				for i, v in next, list do Dropdown:Add(v) end
				if options and typeof(options.default) == "string" then
					Dropdown:Select(options.default)
				end
				return Dropdown
			end

			-- AddPicker
			function Section:AddPicker(name, options, callback)
				local Picker = {
					Name = name,
					Type = "Picker",
					Toggled = false,
					Rainbow = false,
					RainbowSpeed = 1,
					Callback = callback,
				}
				local h, s, v = (options.color or Library.Theme.Accent):ToHSV()
				Picker.Color = { R = h, G = s, B = v }

				Picker.Frame = SelfModules.UI.Create("Frame", {
					Name = "ColorPicker",
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					ClipsDescendants = true,
					Size = UDim2.new(1, 2, 0, 42),
					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						ClipsDescendants = true,
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						SelfModules.UI.Create("Frame", {
							Name = "Top",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 40),
							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0, 8),
								Size = UDim2.new(0.5, -15, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
							SelfModules.UI.Create("Frame", {
								Name = "Selected",
								AnchorPoint = Vector2.new(1, 0),
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
								Position = UDim2.new(1, -29, 0, 2),
								Size = UDim2.new(0, 100, 0, 26),
								SelfModules.UI.Create("Frame", {
									Name = "Preview",
									BackgroundColor3 = Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B),
									Position = UDim2.new(0, 1, 0, 1),
									Size = UDim2.new(1, -2, 1, -2),
									SelfModules.UI.Create("ImageLabel", {
										Name = "Glow",
										BackgroundTransparency = 1,
										Position = UDim2.new(0, -12, 0, -12),
										Size = UDim2.new(1, 24, 1, 24),
										Image = "rbxassetid://10822615828",
										ImageColor3 = Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B),
										ScaleType = Enum.ScaleType.Slice,
										SliceCenter = Rect.new(99, 99, 99, 99),
										ImageTransparency = 0.75,
										SliceScale = 0.2,
									}),
								}, UDim.new(0, 5)),
								SelfModules.UI.Create("TextLabel", {
									Name = "Display",
									AnchorPoint = Vector2.new(0, 0.5),
									BackgroundTransparency = 1,
									Position = UDim2.new(0, 0, 0.5, 0),
									Size = UDim2.new(1, 0, 0, 16),
									Font = Enum.Font.SourceSans,
									Text = "",
									TextColor3 = Library.Theme.TextColor,
									TextSize = 16,
									TextStrokeColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
									TextStrokeTransparency = 0.5,
								}),
							}, UDim.new(0, 5)),
							SelfModules.UI.Create("ImageLabel", {
								Name = "Indicator",
								AnchorPoint = Vector2.new(1, 0),
								BackgroundTransparency = 1,
								Position = UDim2.new(1, -5, 0, 5),
								Size = UDim2.new(0, 20, 0, 20),
								Image = "rbxassetid://9243354333",
							}),
							SelfModules.UI.Create("Frame", {
								Name = "Line",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
								BorderSizePixel = 0,
								Position = UDim2.new(0, 5, 0, 30),
								Size = UDim2.new(1, -10, 0, 2),
							}),
						}),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							Active = true,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Position = UDim2.new(0, 0, 0, 40),
							Size = UDim2.new(1, 0, 1, -40),
							SelfModules.UI.Create("Frame", {
								Name = "Palette",
								BackgroundTransparency = 1,
								BorderSizePixel = 0,
								Position = UDim2.new(0, 5, 0, 5),
								Size = UDim2.new(1, -196, 0, 110),
								SelfModules.UI.Create("Frame", {
									Name = "Point",
									AnchorPoint = Vector2.new(0.5, 0.5),
									BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
									Position = UDim2.new(1, 0, 0, 0),
									Size = UDim2.new(0, 7, 0, 7),
									ZIndex = 2,
									SelfModules.UI.Create("Frame", {
										Name = "Inner",
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										Position = UDim2.new(0, 1, 0, 1),
										Size = UDim2.new(1, -2, 1, -2),
										ZIndex = 2,
									}, UDim.new(1, 0)),
								}, UDim.new(1, 0)),
								SelfModules.UI.Create("Frame", {
									Name = "Hue",
									BackgroundColor3 = Color3.fromRGB(255, 255, 255),
									BorderSizePixel = 0,
									Size = UDim2.new(1, 0, 1, 0),
									SelfModules.UI.Create("UIGradient", {
										Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B))},
									}),
									SelfModules.UI.Create("ImageLabel", {
										Name = "Glow",
										BackgroundTransparency = 1,
										ScaleType = Enum.ScaleType.Slice,
										SliceCenter = Rect.new(99, 99, 99, 99),
										SliceScale = 0.2,
										Size = UDim2.new(1, 24, 1, 24),
										Position = UDim2.new(0, -12, 0, -12),
										Image = "rbxassetid://10822615828",
										ImageTransparency = 0.75,
										SelfModules.UI.Create("UIGradient", {
											Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B))},
											Rotation = -45,
											Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.90, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)}
										}),
									}),
								}, UDim.new(0, 5)),
								SelfModules.UI.Create("Frame", {
									Name = "SatVal",
									BackgroundColor3 = Color3.fromRGB(255, 255, 255),
									BorderSizePixel = 0,
									Size = UDim2.new(1, 0, 1, 0),
									ZIndex = 2,
									SelfModules.UI.Create("UIGradient", {
										Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))},
										Rotation = 90,
										Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)},
									}),
								}, UDim.new(0, 5)),
							}),
							SelfModules.UI.Create("Frame", {
								Name = "HueSlider",
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BorderSizePixel = 0,
								Position = UDim2.new(0, 5, 0, 125),
								Size = UDim2.new(1, -10, 0, 20),
								SelfModules.UI.Create("ImageLabel", {
									Name = "Glow",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, -12, 0, -12),
									Size = UDim2.new(1, 24, 1, 24),
									Image = "rbxassetid://10822615828",
									ImageColor3 = Color3.fromRGB(255, 255, 255),
									ScaleType = Enum.ScaleType.Slice,
									SliceCenter = Rect.new(99, 99, 99, 99),
									ImageTransparency = 0.75,
									SliceScale = 0.2,
									SelfModules.UI.Create("UIGradient", {
										Color = ColorSequence.new{
											ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
											ColorSequenceKeypoint.new(0.16666, Color3.fromRGB(255, 255, 0)),
											ColorSequenceKeypoint.new(0.33333, Color3.fromRGB(0, 255, 0)),
											ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
											ColorSequenceKeypoint.new(0.66667, Color3.fromRGB(0, 0, 255)),
											ColorSequenceKeypoint.new(0.83333, Color3.fromRGB(255, 0, 255)),
											ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
										},
									}),
								}),
								SelfModules.UI.Create("UIGradient", {
									Color = ColorSequence.new{
										ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
										ColorSequenceKeypoint.new(0.16666, Color3.fromRGB(255, 255, 0)),
										ColorSequenceKeypoint.new(0.33333, Color3.fromRGB(0, 255, 0)),
										ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
										ColorSequenceKeypoint.new(0.66667, Color3.fromRGB(0, 0, 255)),
										ColorSequenceKeypoint.new(0.83333, Color3.fromRGB(255, 0, 255)),
										ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
									},
								}),
								SelfModules.UI.Create("Frame", {
									Name = "Bar",
									AnchorPoint = Vector2.new(0.5, 0.5),
									BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
									Position = UDim2.new(0.5, 0, 0, 0),
									Size = UDim2.new(0, 6, 1, 6),
									SelfModules.UI.Create("Frame", {
										Name = "Inner",
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										Position = UDim2.new(0, 1, 0, 1),
										Size = UDim2.new(1, -2, 1, -2),
									}, UDim.new(0, 5)),
								}, UDim.new(0, 5)),
							}, UDim.new(0, 5)),
							SelfModules.UI.Create("Frame", {
								Name = "RGB",
								BackgroundTransparency = 1,
								Position = UDim2.new(1, -180, 0, 5),
								Size = UDim2.new(0, 75, 0, 110),
								SelfModules.UI.Create("Frame", {
									Name = "Red",
									BackgroundTransparency = 1,
									Size = UDim2.new(1, 0, 0, 30),
									SelfModules.UI.Create("TextBox", {
										Name = "Box",
										BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
										Size = UDim2.new(1, 0, 1, 0),
										Font = Enum.Font.SourceSans,
										PlaceholderText = "R",
										Text = 255,
										TextColor3 = Library.Theme.TextColor,
										TextSize = 16,
										TextWrapped = true,
									}, UDim.new(0, 5)),
								}, UDim.new(0, 5)),
								SelfModules.UI.Create("Frame", {
									Name = "Green",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, 0, 0, 40),
									Size = UDim2.new(1, 0, 0, 30),
									SelfModules.UI.Create("TextBox", {
										Name = "Box",
										BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
										Size = UDim2.new(1, 0, 1, 0),
										Font = Enum.Font.SourceSans,
										PlaceholderText = "G",
										Text = 0,
										TextColor3 = Library.Theme.TextColor,
										TextSize = 16,
										TextWrapped = true,
									}, UDim.new(0, 5)),
								}, UDim.new(0, 5)),
								SelfModules.UI.Create("Frame", {
									Name = "Blue",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, 0, 0, 80),
									Size = UDim2.new(1, 0, 0, 30),
									SelfModules.UI.Create("TextBox", {
										Name = "Box",
										BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
										Size = UDim2.new(1, 0, 1, 0),
										Font = Enum.Font.SourceSans,
										PlaceholderText = "B",
										Text = 0,
										TextColor3 = Library.Theme.TextColor,
										TextSize = 16,
										TextWrapped = true,
									}, UDim.new(0, 5)),
								}, UDim.new(0, 5)),
							}),
							SelfModules.UI.Create("Frame", {
								Name = "Rainbow",
								AnchorPoint = Vector2.new(1, 0),
								BackgroundTransparency = 1,
								Position = UDim2.new(1, -5, 0, 87),
								Size = UDim2.new(0, 90, 0, 26),
								SelfModules.UI.Create("Frame", {
									Name = "Indicator",
									BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
									Size = UDim2.new(0, 80, 0, 26),
									SelfModules.UI.Create("TextLabel", {
										Name = "Label",
										BackgroundTransparency = 1,
										Position = UDim2.new(0, 0, 0, 0),
										Size = UDim2.new(1, 0, 1, 0),
										Font = Enum.Font.SourceSansBold,
										Text = "Rainbow",
										TextColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
										TextSize = 14,
										TextWrapped = true,
										TextXAlignment = Enum.TextXAlignment.Center,
										ZIndex = -1,
									}),
									SelfModules.UI.Create("ImageLabel", {
										Name = "Overlay",
										BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
										Position = UDim2.new(0, 2, 0, 2),
										Size = UDim2.new(0, 22, 0, 22),
										Image = "http://www.roblox.com/asset/?id=7827504335",
										ImageTransparency = 1,
										SelfModules.UI.Create("ImageLabel", {
											Name = "Glow",
											BackgroundTransparency = 1,
											Position = UDim2.new(0, -13, 0, -13),
											Size = UDim2.new(1, 26, 1, 26),
											Image = "rbxassetid://10822615828",
											ImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
											ScaleType = Enum.ScaleType.Slice,
											SliceCenter = Rect.new(99, 99, 99, 99),
											ImageTransparency = 0.5,
											SliceScale = 0.2,
										}),
									}, UDim.new(1, 0)),
								}, UDim.new(1, 0)),
							})
						}),
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))

				local hueDragging, satDragging = false, false

				function Picker:GetHeight()
					return Picker.Toggled == true and 192 or 42
				end
				function Picker:Toggle(bool)
					Picker.Toggled = bool
					tween(Picker.Frame, 0.5, { Size = UDim2.new(1, 2, 0, Picker:GetHeight()) })
					tween(Picker.Frame.Holder.Top.Indicator, 0.5, { Rotation = bool and 90 or 0 })
					tween(Section.Frame, 0.5, { Size = UDim2.new(1, -10, 0, Section:GetHeight()) })
					tween(Tab.Frame, 0.5, { CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight()) })
				end
				function Picker:ToggleRainbow(bool)
					Picker.Rainbow = bool
					tween(Picker.Frame.Holder.Holder.Rainbow.Indicator.Overlay.Glow, 0.25, {ImageColor3 = bool and Library.Theme.Accent or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)), SliceScale = bool and 0.2 or 1, ImageTransparency = bool and 0.85 or 0.5})
					tween(Picker.Frame.Holder.Holder.Rainbow.Indicator.Overlay, 0.25, {ImageTransparency = bool and 0 or 1, Position = bool and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2) })
					tween(Picker.Frame.Holder.Holder.Rainbow.Indicator.Overlay, 0.25, {ImageTransparency = bool and 0 or 1, Position = bool and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2) })
					tween(Picker.Frame.Holder.Holder.Rainbow.Indicator.Overlay, "Cosmetic", 0.25, { BackgroundColor3 = bool and SelfModules.UI.Color.Add(Library.Theme.Accent, Color3.fromRGB(15, 15, 15)) or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)) })
					if bool then
						if not Storage.Connections[Picker] then Storage.Connections[Picker] = {} end
						Storage.Connections[Picker].Rainbow = RS.Heartbeat:Connect(function()
							Picker:Set(tick() % Picker.RainbowSpeed / Picker.RainbowSpeed, Picker.Color.G, Picker.Color.B)
						end)
					elseif Storage.Connections[Picker] and Storage.Connections[Picker].Rainbow then
						Storage.Connections[Picker].Rainbow:Disconnect()
						Storage.Connections[Picker].Rainbow = nil
					end
				end
				function Picker:Speed(value)
					Picker.RainbowSpeed = tonumber(value)
				end
				function Picker:Set(h, s, v)
					Picker.Color.R, Picker.Color.G, Picker.Color.B = h, s, v
					local color = Color3.fromHSV(h, s, v)
					Picker.Frame.Holder.Holder.Palette.Hue.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
					Picker.Frame.Holder.Top.Selected.Preview.BackgroundColor3 = color
					Picker.Frame.Holder.Top.Selected.Preview.Glow.ImageColor3 = color
					Picker.Frame.Holder.Top.Selected.Display.Text = string.format("%d, %d, %d", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
					Picker.Frame.Holder.Top.Selected.Size = UDim2.new(0, math.round(TXS:GetTextSize(Picker.Frame.Holder.Top.Selected.Display.Text, 16, Enum.Font.SourceSans, Vector2.new(9e9)).X + 0.5) + 20, 0, 26)
					Picker.Frame.Holder.Holder.RGB.Red.Box.Text = math.floor(color.R * 255 + 0.5)
					Picker.Frame.Holder.Holder.RGB.Green.Box.Text = math.floor(color.G * 255 + 0.5)
					Picker.Frame.Holder.Holder.RGB.Blue.Box.Text = math.floor(color.B * 255 + 0.5)
					Picker.Frame.Holder.Holder.Palette.Hue.Glow.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
					tween(Picker.Frame.Holder.Holder.HueSlider.Bar, 0.1, { Position = UDim2.new(h, 0, 0.5, 0) })
					tween(Picker.Frame.Holder.Holder.Palette.Point, 0.1, { Position = UDim2.new(s, 0, 1 - v, 0) })
					pcall(task.spawn, Picker.Callback, color)
				end
				function Picker:Get()
					return Picker.Color.R, Picker.Color.G, Picker.Color.B
				end
				function Picker:SetName(text)
					Picker.Frame.Holder.Top.Label.Text = text
				end
				function Picker:GetName()
					return Picker.Frame.Holder.Top.Label
				end

				Section.List[#Section.List + 1] = Picker
				Picker.Frame.Parent = Section.Frame.List
				Picker.Frame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and Mouse.Y - Picker.Frame.AbsolutePosition.Y <= 30 then
						Picker:Toggle(not Picker.Toggled)
					end
				end)
				Picker.Frame.Holder.Holder.HueSlider.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = true end
				end)
				Picker.Frame.Holder.Holder.HueSlider.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
				end)
				Picker.Frame.Holder.Holder.Palette.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then satDragging = true end
				end)
				Picker.Frame.Holder.Holder.Palette.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then satDragging = false end
				end)
				Mouse.Move:Connect(function()
					if hueDragging and not Picker.Rainbow then
						Picker:Set(math.clamp((Mouse.X - Picker.Frame.Holder.Holder.HueSlider.AbsolutePosition.X) / Picker.Frame.Holder.Holder.HueSlider.AbsoluteSize.X, 0, 1), Picker.Color.G, Picker.Color.B)
					elseif satDragging then
						Picker:Set(Picker.Color.R, math.clamp((Mouse.X - Picker.Frame.Holder.Holder.Palette.AbsolutePosition.X) / Picker.Frame.Holder.Holder.Palette.AbsoluteSize.X, 0, 1), 1 - math.clamp((Mouse.Y - Picker.Frame.Holder.Holder.Palette.AbsolutePosition.Y) / Picker.Frame.Holder.Holder.Palette.AbsoluteSize.Y, 0, 1))
					end
				end)
				Picker.Frame.Holder.Holder.RGB.Red.Box.FocusLost:Connect(function()
					local num = tonumber(Picker.Frame.Holder.Holder.RGB.Red.Box.Text)
					local color = Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B)
					if num then
						Picker:Set(Color3.new(math.clamp(math.floor(num), 0, 255) / 255, color.G, color.B):ToHSV())
					else
						Picker.Frame.Holder.Holder.RGB.Red.Box.Text = math.floor(color.R * 255 + 0.5)
					end
				end)
				Picker.Frame.Holder.Holder.RGB.Green.Box.FocusLost:Connect(function()
					local num = tonumber(Picker.Frame.Holder.Holder.RGB.Green.Box.Text)
					local color = Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B)
					if num then
						Picker:Set(Color3.new(color.R, math.clamp(math.floor(num), 0, 255) / 255, color.B):ToHSV())
					else
						Picker.Frame.Holder.Holder.RGB.Green.Box.Text = math.floor(color.G * 255 + 0.5)
					end
				end)
				Picker.Frame.Holder.Holder.RGB.Blue.Box.FocusLost:Connect(function()
					local num = tonumber(Picker.Frame.Holder.Holder.RGB.Blue.Box.Text)
					local color = Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B)
					if num then
						Picker:Set(Color3.new(color.R, color.G, math.clamp(math.floor(num), 0, 255) / 255):ToHSV())
					else
						Picker.Frame.Holder.Holder.RGB.Blue.Box.Text = math.floor(color.B * 255 + 0.5)
					end
				end)
				Picker.Frame.Holder.Holder.Rainbow.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						Picker:ToggleRainbow(not Picker.Rainbow)
					end
				end)
				Picker:Set(Picker.Color.R, Picker.Color.G, Picker.Color.B)
				return Picker
			end

			-- AddSubSection
			function Section:AddSubSection(name, options)
				options = options or {}
				local SubSection = {
					Name = name,
					Type = "SubSection",
					Toggled = options.default or false,
					List = {},
				}
				SubSection.Frame = SelfModules.UI.Create("Frame", {
					Name = "SubSection",
					BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
					Size = UDim2.new(1, 2, 0, 42),
					SelfModules.UI.Create("Frame", {
						Name = "Holder",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						SelfModules.UI.Create("TextLabel", {
							Name = "Header",
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 5, 0, 8),
							Size = UDim2.new(1, -40, 0, 14),
							Font = Enum.Font.SourceSans,
							Text = name,
							TextColor3 = Library.Theme.TextColor,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
						SelfModules.UI.Create("TextLabel", {
							Name = "Indicator",
							AnchorPoint = Vector2.new(1, 0),
							BackgroundTransparency = 1,
							Position = UDim2.new(1, -5, 0, 5),
							Size = UDim2.new(0, 20, 0, 20),
							Font = Enum.Font.SourceSansBold,
							Text = "+",
							TextColor3 = Library.Theme.TextColor,
							TextSize = 20,
						}),
						SelfModules.UI.Create("Frame", {
							Name = "Line",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
							BorderSizePixel = 0,
							Position = UDim2.new(0, 5, 0, 30),
							Size = UDim2.new(1, -10, 0, 2),
						}),
						SelfModules.UI.Create("Frame", {
							Name = "List",
							BackgroundTransparency = 1,
							ClipsDescendants = true,
							Position = UDim2.new(0, 5, 0, 40),
							Size = UDim2.new(1, -10, 1, -40),
							SelfModules.UI.Create("UIListLayout", {
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 5),
							}),
							SelfModules.UI.Create("UIPadding", {
								PaddingBottom = UDim.new(0, 1),
								PaddingLeft = UDim.new(0, 1),
								PaddingRight = UDim.new(0, 1),
								PaddingTop = UDim.new(0, 1),
							}),
						}),
					}, UDim.new(0, 5)),
				}, UDim.new(0, 5))
				
				SubSection.Locked = false

				local function toggleSubSection(bool, forced)
					if SubSection.Locked == true then return end
					SubSection.Toggled = bool
					
					if forced == nil then
						tween(SubSection.Frame, 0.5, { Size = UDim2.new(1, 2, 0, SubSection:GetHeight()) })
						tween(SubSection.Frame.Holder.Indicator, 0.5, { Rotation = bool and 45 or 0 })
						tween(Section.Frame, 0.5, { Size = UDim2.new(1, -10, 0, Section:GetHeight()) })
						tween(Tab.Frame, 0.5, { CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight()) })
					elseif forced == true then
						SubSection.Frame.Size = UDim2.new(1, 2, 0, SubSection:GetHeight())
						SubSection.Frame.Holder.Indicator.Rotation = bool and 45 or 0
						Section.Frame.Size = UDim2.new(1, -10, 0, Section:GetHeight())
						Tab.Frame.CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight())
					end
				end
				
				function SubSection:SetLock(bool)
					toggleSubSection(not bool, true)
					SubSection.Locked = bool
					tween(SubSection.Frame.Holder.Header, 0.5, { TextColor3 = bool == true and SelfModules.UI.Color.Sub(Library.Theme.TextColor, Color3.fromRGB(155, 155, 155)) or Library.Theme.TextColor })
					tween(SubSection.Frame.Holder.Indicator, 0.5, { TextColor3 = bool == true and SelfModules.UI.Color.Sub(Library.Theme.TextColor, Color3.fromRGB(155, 155, 155)) or Library.Theme.TextColor })
				end

				function SubSection:GetLock()
					return SubSection.Locked
				end

				function SubSection:GetHeight()
					local height = 42
					if SubSection.Toggled then
						for i, v in next, self.List do
							if v.Frame.Visible then
								height = height + (v.GetHeight and v:GetHeight() or v.Frame.AbsoluteSize.Y) + 6
							end
						end
					end
					return height
				end

				function SubSection:UpdateHeight()
					if SubSection.Toggled then
						SubSection.Frame.Size = UDim2.new(1, 2, 0, SubSection:GetHeight())
						SubSection.Frame.Holder.Indicator.Rotation = 45
						Section:UpdateHeight()
					end
				end

				function SubSection:SetName(text)
					SubSection.Frame.Holder.Header.Text = text
				end
				function SubSection:GetName()
					return SubSection.Frame.Holder.Header.Text
				end
				
				-- Terminal
				function SubSection:AddTerminal(name, options, callback)
					local Terminal = {
						Name = name,
						Options = options or {},
						Callback = callback,
						CurrentLayoutOrder = 0,
						List = {},
					}

					-- Frame
					Terminal.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, math.clamp(Terminal.Options.extend, 55, 1000) or 280),

						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Size = UDim2.new(1, -2, 1, -2),
							Position = UDim2.new(0, 1, 0, 1),

							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0, 5),
								Size = UDim2.new(1, -10, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),

							SelfModules.UI.Create("Frame", {
								Name = "Field",
								BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
								Position = UDim2.new(0.5, 0, 0, 25),
								Size = UDim2.new(1, -8, 1, -30),
								AnchorPoint = Vector2.new(0.5, 0),

								SelfModules.UI.Create("Frame", {
									Name = "Holder",
									BackgroundColor3 = Library.Theme.SectionColor,
									Position = UDim2.new(0, 1, 0, 1),
									Size = UDim2.new(1, -2, 1, -2),
									ClipsDescendants = true,
								}, UDim.new(0, 5)),
							}, UDim.new(0, 5)),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))

					-- Build List (scrollable or static)
					local Holder = Terminal.Frame.Holder.Field.Holder

					if Terminal.Options.scrollable == true then
						local List = SelfModules.UI.Create("ScrollingFrame", {
							Name = "List",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, -6, 1, -3),
							Position = UDim2.new(0.5, 0, 0.5, 0),
							CanvasSize = UDim2.new(0, 0, 0, 0),
							ClipsDescendants = false,
							ScrollBarImageColor3 = SelfModules.UI.Color.Add(Library.Theme.BackgroundColor, Color3.fromRGB(25, 25, 25)),
							ScrollBarThickness = 5,
							AnchorPoint = Vector2.new(0.5, 0.5),
							BorderSizePixel = 0,

							SelfModules.UI.Create("UIListLayout", {
								FillDirection = Enum.FillDirection.Vertical,
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Left,
								VerticalAlignment = Enum.VerticalAlignment.Top,
							}),

							SelfModules.UI.Create("UIPadding", {
								PaddingLeft = UDim.new(0, 4),
								PaddingRight = UDim.new(0, 4),
								PaddingTop = UDim.new(0, 2),
								PaddingBottom = UDim.new(0, 2),
							}),
						})
						List.Parent = Holder
					else
						local List = SelfModules.UI.Create("Frame", {
							Name = "List",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 1, 0),
							ClipsDescendants = true,

							SelfModules.UI.Create("UIListLayout", {
								FillDirection = Enum.FillDirection.Vertical,
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Left,
								VerticalAlignment = Enum.VerticalAlignment.Top,
							}),

							SelfModules.UI.Create("UIPadding", {
								PaddingLeft = UDim.new(0, 4),
								PaddingRight = UDim.new(0, 4),
								PaddingTop = UDim.new(0, 2),
								PaddingBottom = UDim.new(0, 2),
							}),
						})
						List.Parent = Holder
					end

					-- References
					local List = Holder.List
					local Layout = List.UIListLayout

					-- Auto canvas resize for scrollable mode
					if Terminal.Options.scrollable == true then
						Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
							List.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 4)
							List.CanvasPosition = Vector2.new(0, math.max(0, Layout.AbsoluteContentSize.Y - List.AbsoluteSize.Y))
						end)
					end

					-- Colors
					local MessageColors = {
						Print    = Color3.fromRGB(255, 255, 255),
						Warn     = Color3.fromRGB(255, 170, 0),
						Feed     = Color3.fromRGB(125, 180, 255),
						Error    = Color3.fromRGB(255, 80, 80),
						Success  = Color3.fromRGB(85, 255, 0),
						Info     = Color3.fromRGB(120, 200, 255),
						Debug    = Color3.fromRGB(170, 170, 170),
						System   = Color3.fromRGB(180, 140, 255),
						Command  = Color3.fromRGB(255, 255, 120),
						Input    = Color3.fromRGB(255, 220, 180),
						Output   = Color3.fromRGB(180, 255, 255),
						Critical = Color3.fromRGB(255, 40, 40),
						Trace    = Color3.fromRGB(120, 120, 120),
						Network  = Color3.fromRGB(100, 180, 255),
						Security = Color3.fromRGB(255, 80, 180),
						Memory   = Color3.fromRGB(255, 120, 120),
						File     = Color3.fromRGB(200, 255, 150),
						Event    = Color3.fromRGB(255, 180, 255),
						Loading  = Color3.fromRGB(255, 220, 100),
						Hidden   = Color3.fromRGB(90, 90, 90),
					}

					-- Callback Helper
					local function fireCallback(state, object)
						if Terminal.Callback then
							task.spawn(function()
								Terminal.Callback(state, object)
							end)
						end
					end

					-- Bounds Check (non-scrollable only)
					local function isOutOfBounds(guiObject)
						local objectBottom = guiObject.AbsolutePosition.Y + guiObject.AbsoluteSize.Y
						local containerBottom = List.AbsolutePosition.Y + List.AbsoluteSize.Y
						return objectBottom > containerBottom
					end

					-- Remove Oldest (non-scrollable only)
					local function removeOldest()
						local labels = {}
						for _, child in ipairs(List:GetChildren()) do
							if child:IsA("TextLabel") or child:IsA("TextBox") then
								table.insert(labels, child)
							end
						end
						if #labels == 0 then return end
						table.sort(labels, function(a, b)
							return a.LayoutOrder < b.LayoutOrder
						end)
						local oldest = labels[1]
						fireCallback("Remove", oldest)
						oldest:Destroy()
					end

					-- Overflow Check (non-scrollable only)
					local function checkOverflow()
						for _, child in ipairs(List:GetChildren()) do
							if (child:IsA("TextLabel") or child:IsA("TextBox")) and isOutOfBounds(child) then
								removeOldest()
								task.defer(checkOverflow)
								break
							end
						end
					end

					-- Public Functions

					function Terminal:Add(text, config)
						config = config or {}

						local Sound = Instance.new("Sound")
						Sound.SoundId = "rbxassetid://140207837688369"
						Sound.Volume = 0.01
						Sound.PlaybackSpeed = 1
						Sound.PlayOnRemove = true
						Sound.Parent = game:GetService("SoundService")
						Sound:Remove()

						Terminal.CurrentLayoutOrder += 1

						local messageType = config.type or "Print"
						local selectable = config.Selectable or false
						local wrapped = config.Wrapped or false
						local sizeY = config.SizeY or 14

						local baseProperties = {
							Name = "Label",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, -2, 0, sizeY),
							AutomaticSize = wrapped and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
							Font = Enum.Font.SourceSans,
							Text = tostring(text),
							TextSize = 14,
							TextWrapped = wrapped,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Top,
							TextColor3 = MessageColors[messageType] or MessageColors.Print,
							LayoutOrder = Terminal.CurrentLayoutOrder,
						}

						local Object

						if selectable then
							Object = SelfModules.UI.Create("TextBox", {
								Name = baseProperties.Name,
								BackgroundTransparency = baseProperties.BackgroundTransparency,
								Size = baseProperties.Size,
								AutomaticSize = baseProperties.AutomaticSize,
								Font = baseProperties.Font,
								Text = baseProperties.Text,
								TextSize = baseProperties.TextSize,
								TextWrapped = baseProperties.TextWrapped,
								TextXAlignment = baseProperties.TextXAlignment,
								TextYAlignment = baseProperties.TextYAlignment,
								TextColor3 = baseProperties.TextColor3,
								LayoutOrder = baseProperties.LayoutOrder,
								ClearTextOnFocus = false,
								MultiLine = wrapped,
								TextEditable = false,
								Selectable = true,
								Active = true,
							})

							local ClickDetector = SelfModules.UI.Create("TextButton", {
								Name = "Detector",
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 1, 0),
								Text = "",
								ZIndex = (Object.ZIndex or 1) + 1,
							})
							ClickDetector.Parent = Object

							ClickDetector.MouseButton1Click:Connect(function()
								Object:CaptureFocus()
								task.defer(function()
									if Object.Parent then
										Object.CursorPosition = #Object.Text + 1
										Object.SelectionStart = 1
									end
								end)
							end)
						else
							Object = SelfModules.UI.Create("TextLabel", baseProperties)
						end

						Object.Parent = List
						table.insert(Terminal.List, Object)
						fireCallback("Add", Object)

						if Terminal.Options.scrollable ~= true then
							task.defer(checkOverflow)
						end

						return Object
					end

					function Terminal:Remove(object)
						if not object then return end
						if object.Parent == List then
							fireCallback("Remove", object)
							object:Destroy()
						end
					end

					function Terminal:Reset()
						for _, child in ipairs(List:GetChildren()) do
							if child:IsA("TextLabel") or child:IsA("TextBox") then
								fireCallback("Remove", child)
								child:Destroy()
							end
						end
						Terminal.List = {}
						Terminal.CurrentLayoutOrder = 0
					end

					function Terminal:GetChildren()
						local objects = {}
						for _, child in ipairs(List:GetChildren()) do
							if child:IsA("TextLabel") or child:IsA("TextBox") then
								table.insert(objects, child)
							end
						end
						return objects
					end

					function Terminal:GetCount()
						local count = 0
						for _, child in ipairs(List:GetChildren()) do
							if child:IsA("TextLabel") or child:IsA("TextBox") then
								count += 1
							end
						end
						return count
					end

					SubSection.List[#SubSection.List + 1] = Terminal
					Terminal.Frame.Parent = SubSection.Frame.Holder.List

					return Terminal
				end
				
				-- Graph
				function SubSection:AddGraph(name, options, callback)
					local Graph = {
						Name = name,
						Type = "Graph",
						Options = options,
						Callback = callback,
					}

					-- Frame
					Graph.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, math.clamp(Graph.Options.extend, 55, 1000) or 280),

						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Size = UDim2.new(1, -2, 1, -2),
							Position = UDim2.new(0, 1, 0, 1),

							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0, 5),
								Size = UDim2.new(1, -10, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),

							SelfModules.UI.Create("Frame", {
								Name = "Field",
								BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
								Position = UDim2.new(0.5, 0, 0, 25),
								Size = UDim2.new(1, -8, 1, -30),
								AnchorPoint = Vector2.new(0.5, 0),
								ClipsDescendants = true,

								SelfModules.UI.Create("Frame", {
									Name = "Holder",
									BackgroundColor3 = Library.Theme.SectionColor,
									Position = UDim2.new(0, 1, 0, 1),
									Size = UDim2.new(1, -2, 1, -2),
									ClipsDescendants = true,

									SelfModules.UI.Create("Frame", {
										Name = "List",
										BackgroundTransparency = 1,
										Size = UDim2.new(1, 0, 1, 0),
										ClipsDescendants = true,
									}),
								}, UDim.new(0, 5)),
							}, UDim.new(0, 5)),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))

					-- Scripts
					local points    = {}
					local linePool  = {}
					local MIN       = Graph.Options.min       or 0
					local MAX       = Graph.Options.max       or 100
					local MAX_POINTS = Graph.Options.points   or 50
					local THICKNESS = Graph.Options.thickness or 1.5

					local List = Graph.Frame.Holder.Field.Holder.List

					local function getLine(index)
						if not linePool[index] then
							local f = SelfModules.UI.Create("Frame", {
								BackgroundColor3 = Library.Theme.Accent,
								BorderSizePixel = 0,
								Visible = false,

								SelfModules.UI.Create("ImageLabel", {
									Name = "Glow",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, -3, 0, -3),
									Size = UDim2.new(1, 6, 1, 6),
									Image = "rbxassetid://10822615828",
									ImageColor3 = SelfModules.UI.Color.Sub(Library.Theme.Accent, Color3.fromRGB(10, 10, 10)),
									ScaleType = Enum.ScaleType.Slice,
									SliceCenter = Rect.new(99, 99, 99, 99),
									ImageTransparency = 0.98,
									SliceScale = 1,
								}),
							})
							f.Parent = List
							linePool[index] = f
						end
						return linePool[index]
					end

					local function drawLine(frame, ax, ay, bx, by)
						local dx = bx - ax
						local dy = by - ay
						local length = math.sqrt(dx * dx + dy * dy)
						local angle  = math.deg(math.atan2(dy, dx))
						local mx = (ax + bx) / 2
						local my = (ay + by) / 2

						frame.AnchorPoint = Vector2.new(0.5, 0.5)
						frame.Position    = UDim2.new(0, mx, 0, my)
						frame.Size        = UDim2.new(0, length, 0, THICKNESS)
						frame.Rotation    = angle
						frame.Visible     = true
					end

					local function hideUnused(from)
						for i = from, #linePool do
							if linePool[i] then
								linePool[i].Visible = false
							end
						end
					end

					local function redraw()
						local w     = List.AbsoluteSize.X
						local h     = List.AbsoluteSize.Y
						local count = #points

						if count < 2 then return end

						local spacing = w / (MAX_POINTS - 1)

						for i = 1, count - 1 do
							local ax = (i - 1) * spacing
							local bx = i       * spacing
							local ay = points[i]     * h
							local by = points[i + 1] * h

							drawLine(getLine(i), ax, ay, bx, by)
						end

						hideUnused(count)
					end

					-- Functions

					-- Adds a new value to the graph
					function Graph:Add(value)
						local clamped    = math.clamp(value, MIN, MAX)
						local percentage = 1 - ((clamped - MIN) / (MAX - MIN))

						table.insert(points, percentage)
						if #points > MAX_POINTS then
							table.remove(points, 1)
						end

						if Graph.Callback then
							-- Returning value
							Graph.Callback(clamped)
						end

						redraw()
					end

					-- Returns the average calculated value
					function Graph:GetAverage()
						if #points == 0 then return 0 end

						local sum = 0
						for _, percentage in ipairs(points) do
							-- convert percentage back to real value
							sum = sum + (MIN + ((1 - percentage) * (MAX - MIN)))
						end

						return sum / #points
					end

					-- Sets how many points fit across the graph (fewer = longer segments, more = shorter)
					function Graph:Scale(value)
						MAX_POINTS = math.clamp(math.floor(value), 2, 500)

						-- Trim existing points if new scale is smaller
						while #points > MAX_POINTS do
							table.remove(points, 1)
						end

						redraw()
					end

					-- Changes the thickness of all lines
					function Graph:Thickness(value)
						THICKNESS = math.clamp(value, 0.5, 10)
						redraw()
					end

					-- Clears all lines and resets state
					function Graph:Clear()
						points = {}

						for _, line in ipairs(linePool) do
							if line then
								line:Destroy()
							end
						end

						linePool = {}
					end

					function Graph:SetPoints(value)
						MAX_POINTS = math.clamp(math.floor(value), 2, 500)

						while #points > MAX_POINTS do
							table.remove(points, 1)
						end

						redraw()
					end

					SubSection.List[#SubSection.List + 1] = Graph
					Graph.Frame.Parent = SubSection.Frame.Holder.List

					return Graph
				end

				-- Priority
				function SubSection:AddPriority(name, list, options, callback)
					local Ranker = {
						Name     = name,
						Type     = "Ranker",
						Toggled  = false,
						Order    = {},
						Excluded = {},
						List     = {},
						Callback = callback,
						Style    = options and options.style or "numeric",
						Max      = options and options.max or math.huge,
					}

					local ITEM_HEIGHT  = 32
					local ITEM_GAP     = 4
					local ITEM_STRIDE  = ITEM_HEIGHT + ITEM_GAP
					local HAS_EXCLUDE  = options and options.exclude or false
					local MAX          = options and options.max or math.huge
					local DIVIDER_KEY  = "__DIVIDER__"

					local unified      = {}
					local frameMap     = {}
					local dividerFrame = nil
					
					Ranker._frameMap = frameMap

					local function slotY(i)
						return (i - 1) * ITEM_STRIDE
					end

					local function totalListH()
						return math.max(#unified, 1) * ITEM_STRIDE - ITEM_GAP
					end

					local function rebuildOrderExcluded()
						Ranker.Order    = {}
						Ranker.Excluded = {}
						if not HAS_EXCLUDE then
							for _, v in ipairs(unified) do
								if v ~= DIVIDER_KEY then
									Ranker.Order[#Ranker.Order + 1] = v
								end
							end
							return
						end

						local pastDivider = false
						for _, v in ipairs(unified) do
							if v == DIVIDER_KEY then
								pastDivider = true
							elseif pastDivider then
								Ranker.Excluded[#Ranker.Excluded + 1] = v
							else
								Ranker.Order[#Ranker.Order + 1] = v
							end
						end

						-- NEW: push overflow items past the divider
						if #Ranker.Order > Ranker.Max then
							local dividerIdx = table.find(unified, DIVIDER_KEY)
							while #Ranker.Order > Ranker.Max do
								local overflow = Ranker.Order[#Ranker.Order]
								table.remove(Ranker.Order, #Ranker.Order)
								Ranker.Excluded[#Ranker.Excluded + 1] = overflow

								local itemIdx = table.find(unified, overflow)
								if itemIdx then
									table.remove(unified, itemIdx)
									dividerIdx = table.find(unified, DIVIDER_KEY)
									table.insert(unified, dividerIdx + 1, overflow)
								end
							end
						end
					end

					local function refreshNumbers()
						local activeNum = 1
						for _, v in ipairs(unified) do
							if v == DIVIDER_KEY then
								activeNum = nil
							else
								local f = frameMap[v]
								if f then
									if activeNum then
										-- NEW: style-aware display
										if Ranker.Style == "plus" then
											f.Holder.Num.Text = "+"
										else
											f.Holder.Num.Text = tostring(activeNum)
										end
										f.Holder.Num.TextColor3 = Library.Theme.Accent
										activeNum = activeNum + 1
									else
										f.Holder.Num.Text = "-"
										f.Holder.Num.TextColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(55, 55, 55))
									end
								end
							end
						end
					end

					local function refreshPositions(skipName)
						for i, v in ipairs(unified) do
							if v ~= skipName then
								local f = v == DIVIDER_KEY and dividerFrame or frameMap[v]
								if f then
									tween(f, 0.18, { Position = UDim2.new(0, 0, 0, slotY(i)) })
								end
							end
						end
					end

					Ranker.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, 42),
						ClipsDescendants = true,

						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),

							SelfModules.UI.Create("Frame", {
								Name = "Holder",
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 0, 40),

								SelfModules.UI.Create("TextLabel", {
									Name = "Label",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, 5, 0, 8),
									Size = UDim2.new(1, -35, 0, 14),
									Font = Enum.Font.SourceSans,
									Text = name,
									TextColor3 = Library.Theme.TextColor,
									TextSize = 14,
									TextWrapped = true,
									TextXAlignment = Enum.TextXAlignment.Left,
								}),

								SelfModules.UI.Create("TextLabel", {
									Name = "Count",
									BackgroundTransparency = 1,
									Position = UDim2.new(0.5, 0, 0, 8),
									Size = UDim2.new(0.5, -30, 0, 14),
									Font = Enum.Font.SourceSans,
									Text = "",
									TextColor3 = SelfModules.UI.Color.Add(Library.Theme.TextColor, Color3.fromRGB(-60, -60, -60)),
									TextSize = 12,
									TextWrapped = true,
									TextXAlignment = Enum.TextXAlignment.Right,
								}),

								SelfModules.UI.Create("ImageLabel", {
									Name = "Indicator",
									AnchorPoint = Vector2.new(1, 0),
									BackgroundTransparency = 1,
									Position = UDim2.new(1, -5, 0, 5),
									Size = UDim2.new(0, 20, 0, 20),
									Image = "rbxassetid://9243354333",
								}),

								SelfModules.UI.Create("Frame", {
									Name = "Line",
									BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
									BorderSizePixel = 0,
									Position = UDim2.new(0, 5, 0, 30),
									Size = UDim2.new(1, -10, 0, 2),
								}),
							}, UDim.new(0, 5)),

							SelfModules.UI.Create("Frame", {
								Name = "List",
								BackgroundTransparency = 1,
								BorderSizePixel = 0,
								Position = UDim2.new(0, 5, 0, 44),
								Size = UDim2.new(1, -10, 0, 0),
								ClipsDescendants = true,
							}),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))

					if HAS_EXCLUDE then
						dividerFrame = SelfModules.UI.Create("Frame", {
							Name = DIVIDER_KEY,
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 0, 0, 0),
							Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),

							SelfModules.UI.Create("Frame", {
								Name = "LineLeft",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
								BorderSizePixel = 0,
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.new(0, 0, 0.5, 0),
								Size = UDim2.new(0.28, 0, 0, 1),
							}),

							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 1, 0),
								Font = Enum.Font.SourceSansBold,
								Text = "Excluded",
								TextColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(55, 55, 55)),
								TextSize = 13,
							}),

							SelfModules.UI.Create("Frame", {
								Name = "LineRight",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
								BorderSizePixel = 0,
								AnchorPoint = Vector2.new(1, 0.5),
								Position = UDim2.new(1, 0, 0.5, 0),
								Size = UDim2.new(0.28, 0, 0, 1),
							}),
						})
						dividerFrame.Parent = Ranker.Frame.Holder.List
						unified[1] = DIVIDER_KEY
					end

					function Ranker:GetHeight()
						if not Ranker.Toggled then return 42 end
						return 42 + totalListH() + 8
					end

					function Ranker:UpdateHeight()
						Ranker.Frame.Holder.List.Size = UDim2.new(1, -10, 0, totalListH())
						Ranker.Frame.Holder.Holder.Count.Text = #Ranker.List > 0 and (#Ranker.List .. " items") or ""
						if Ranker.Toggled then
							Ranker.Frame.Size = UDim2.new(1, 2, 0, Ranker:GetHeight())
							SubSection:UpdateHeight()
						end
					end

					function Ranker:Toggle(bool)
						Ranker.Toggled = bool
						Ranker.Frame.Holder.List.Size = UDim2.new(1, -10, 0, totalListH())
						tween(Ranker.Frame, 0.5, { Size = UDim2.new(1, 2, 0, Ranker:GetHeight()) })
						tween(Ranker.Frame.Holder.Holder.Indicator, 0.5, { Rotation = bool and 90 or 0 })
						tween(SubSection.Frame, 0.5, { Size = UDim2.new(1, 2, 0, SubSection:GetHeight()) })
						tween(Section.Frame, 0.5, { Size = UDim2.new(1, -10, 0, Section:GetHeight()) })
						tween(Tab.Frame, 0.5, { CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight()) })
					end

					local dragging    = nil
					local dragFrame   = nil
					local dragOffsetY = 0

					function Ranker:Add(itemName, excluded)
						local Item = { Name = itemName }

						local insertAt
						if HAS_EXCLUDE then
							if excluded then
								insertAt = #unified + 1
							else
								local di = table.find(unified, DIVIDER_KEY)
								insertAt = di
							end
						else
							insertAt = #unified + 1
						end

						local posY = slotY(insertAt)

						Item.Frame = SelfModules.UI.Create("Frame", {
							Name = itemName,
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
							Position = UDim2.new(0, 0, 0, posY),
							Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),

							SelfModules.UI.Create("Frame", {
								Name = "Holder",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
								Position = UDim2.new(0, 1, 0, 1),
								Size = UDim2.new(1, -2, 1, -2),

								SelfModules.UI.Create("TextLabel", {
									Name = "Num",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, 5, 0, 0),
									Size = UDim2.new(0, 18, 1, 0),
									Font = Enum.Font.SourceSansBold,
									Text = "?",
									TextColor3 = Library.Theme.Accent,
									TextSize = 15,
								}),

								SelfModules.UI.Create("TextLabel", {
									Name = "Label",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, 26, 0, 0),
									Size = UDim2.new(1, -46, 1, 0),
									Font = Enum.Font.SourceSans,
									Text = itemName,
									TextColor3 = Library.Theme.TextColor,
									TextSize = 15,
									TextXAlignment = Enum.TextXAlignment.Left,
								}),

								SelfModules.UI.Create("TextLabel", {
									Name = "Handle",
									AnchorPoint = Vector2.new(1, 0.5),
									BackgroundTransparency = 1,
									Position = UDim2.new(1, -6, 0.5, 0),
									Size = UDim2.new(0, 16, 1, 0),
									Font = Enum.Font.SourceSansBold,
									Text = "::",
									TextColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(60, 60, 60)),
									TextSize = 15,
								}),
							}, UDim.new(0, 4)),
						}, UDim.new(0, 4))

						table.insert(unified, insertAt, itemName)
						Ranker.List[#Ranker.List + 1] = itemName
						frameMap[itemName] = Item.Frame
						Item.Frame.Parent = Ranker.Frame.Holder.List

						rebuildOrderExcluded()
						refreshNumbers()
						refreshPositions(nil)
						Ranker:UpdateHeight()

						Item.Frame.InputBegan:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
							if dragging then return end

							dragging    = itemName
							dragFrame   = Item.Frame
							dragOffsetY = input.Position.Y - Item.Frame.AbsolutePosition.Y

							tween(Item.Frame, 0.1, {
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(30, 30, 30)),
							})
							Item.Frame.ZIndex        = 10
							Item.Frame.Holder.ZIndex = 10
						end)

						return Item
					end
					
					function Ranker:Move(itemName, exclude, position)
						assert(type(itemName) == "string", "Move requires an item name string")
						assert(type(exclude) == "boolean", "Move requires a boolean for exclude")
						assert(frameMap[itemName], "Move: item '" .. itemName .. "' does not exist")

						local dividerIdx = HAS_EXCLUDE and table.find(unified, DIVIDER_KEY) or nil

						-- remove item from its current position
						local currentIdx = table.find(unified, itemName)
						if not currentIdx then return end
						table.remove(unified, currentIdx)

						-- recalculate divider index after removal
						if dividerIdx then
							dividerIdx = table.find(unified, DIVIDER_KEY)
						end

						if not HAS_EXCLUDE or not exclude then
							-- moving INTO active (ranked) area
							local activeStart = 1
							local activeEnd   = dividerIdx and (dividerIdx - 1) or #unified

							if position then
								-- count active slots to find the real unified index
								local activeCount = 0
								local insertAt    = activeEnd + 1

								for i, v in ipairs(unified) do
									if v ~= DIVIDER_KEY then
										activeCount += 1
										if activeCount == position then
											-- shift everything from here forward
											insertAt = i
											break
										end
									end
								end

								table.insert(unified, insertAt, itemName)
							else
								-- no position given, append just before divider (end of active area)
								local insertAt = dividerIdx or (#unified + 1)
								table.insert(unified, insertAt, itemName)
							end

							-- enforce max: if inserting into active pushed us over, bump the last active item to excluded
							if Ranker.Max ~= math.huge then
								dividerIdx = table.find(unified, DIVIDER_KEY)
								local activeItems = {}
								for i, v in ipairs(unified) do
									if v ~= DIVIDER_KEY and (not dividerIdx or i < dividerIdx) then
										activeItems[#activeItems + 1] = { name = v, idx = i }
									end
								end

								if #activeItems > Ranker.Max then
									local bump = activeItems[#activeItems]
									table.remove(unified, bump.idx)
									dividerIdx = table.find(unified, DIVIDER_KEY)
									table.insert(unified, dividerIdx + 1, bump.name)
								end
							end

						else
							-- moving INTO excluded area
							if not HAS_EXCLUDE then
								-- no exclude zone exists, just append to end
								table.insert(unified, #unified + 1, itemName)
							elseif position then
								-- find the nth slot inside excluded zone
								dividerIdx = table.find(unified, DIVIDER_KEY)
								local excludedCount = 0
								local insertAt      = #unified + 1

								for i = dividerIdx + 1, #unified do
									local v = unified[i]
									if v ~= DIVIDER_KEY then
										excludedCount += 1
										if excludedCount == position then
											insertAt = i
											break
										end
									end
								end

								table.insert(unified, insertAt, itemName)
							else
								-- no position, append to end of excluded
								table.insert(unified, #unified + 1, itemName)
							end
						end

						rebuildOrderExcluded()
						refreshNumbers()
						refreshPositions(nil)

						-- animate the moved item to its new slot
						local newIdx = table.find(unified, itemName)
						if newIdx and frameMap[itemName] then
							tween(frameMap[itemName], 0.18, { Position = UDim2.new(0, 0, 0, slotY(newIdx)) })
						end

						Ranker:UpdateHeight()
						pcall(task.spawn, Ranker.Callback, Ranker.Order, Ranker.Excluded)
					end

					function Ranker:Remove(itemName, ignoreToggle)
						local ui = table.find(unified, itemName)
						if ui then table.remove(unified, ui) end
						frameMap[itemName]:Destroy()
						frameMap[itemName] = nil
						for i, v in next, Ranker.List do
							if v == itemName then table.remove(Ranker.List, i) break end
						end
						rebuildOrderExcluded()
						refreshNumbers()
						refreshPositions(nil)
						if Ranker.Toggled and not ignoreToggle then Ranker:UpdateHeight() end
						if #Ranker.List == 0 and not ignoreToggle then Ranker:Toggle(false) end
					end

					function Ranker:ClearList()
						for _ = 1, #Ranker.List do Ranker:Remove(Ranker.List[1], true) end
					end

					function Ranker:SetList(newList)
						Ranker:ClearList()
						for _, v in next, newList do Ranker:Add(v) end
					end

					function Ranker:GetOrder()    return Ranker.Order    end
					function Ranker:GetExcluded() return Ranker.Excluded end

					-- NEW: SortStyle method
					function Ranker:SortStyle(style)
						self.Style = style or "numeric"
						refreshNumbers()
					end
					
					function Ranker:GetStyle()
						return self.Style
					end
					
					function Ranker:SetMax(number)
						assert(type(number) == "number" and number > 0, "SetMax requires a positive number")
						Ranker.Max = number
						MAX = number
						rebuildOrderExcluded()
						refreshNumbers()
						refreshPositions(nil)
						Ranker:UpdateHeight()
					end

					function Ranker:GetMax()
						return Ranker.Max
					end

					UIS.InputChanged:Connect(function(input)
						if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
						if not dragging or not dragFrame then return end

						local mouseY   = input.Position.Y
						local listTop  = Ranker.Frame.Holder.List.AbsolutePosition.Y
						local localY   = mouseY - dragOffsetY - listTop
						local clampedY = math.clamp(localY, 0, totalListH() - ITEM_HEIGHT)

						dragFrame.Position = UDim2.new(0, 0, 0, clampedY)

						local centerY    = clampedY + ITEM_HEIGHT / 2
						local targetSlot = math.clamp(math.round(centerY / ITEM_STRIDE) + 1, 1, #unified)

						if HAS_EXCLUDE and unified[targetSlot] == DIVIDER_KEY then
							local currentSlot = table.find(unified, dragging)
							targetSlot = targetSlot + (currentSlot and currentSlot < targetSlot and 1 or -1)
							targetSlot = math.clamp(targetSlot, 1, #unified)
						end

						-- NEW: block dragging above divider if max is reached and item is currently excluded
						if HAS_EXCLUDE and Ranker.Max ~= math.huge then
							local dividerIdx  = table.find(unified, DIVIDER_KEY)
							local currentSlot = table.find(unified, dragging)
							local isExcluded  = currentSlot and currentSlot > dividerIdx
							local atMax       = #Ranker.Order >= Ranker.Max

							if isExcluded and atMax and targetSlot <= dividerIdx then
								return -- block the move
							end
						end

						local currentSlot = table.find(unified, dragging)
						if targetSlot ~= currentSlot and currentSlot then
							table.remove(unified, currentSlot)
							table.insert(unified, targetSlot, dragging)
							rebuildOrderExcluded()
							refreshNumbers()
							refreshPositions(dragging)
						end
					end)

					UIS.InputEnded:Connect(function(input)
						if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
						if not dragging or not dragFrame then return end

						local slot  = table.find(unified, dragging)
						local snapY = slotY(slot or 1)

						tween(dragFrame, 0.2, {
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
							Position = UDim2.new(0, 0, 0, snapY),
						})

						dragFrame.ZIndex        = 1
						dragFrame.Holder.ZIndex = 1
						dragging  = nil
						dragFrame = nil

						pcall(task.spawn, Ranker.Callback, Ranker.Order, Ranker.Excluded)
					end)

					Ranker.Frame.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1
							and #Ranker.List > 0
							and Mouse.Y - Ranker.Frame.AbsolutePosition.Y <= 30 then
							Ranker:Toggle(not Ranker.Toggled)
						end
					end)

					SubSection.List[#SubSection.List + 1] = Ranker
					Ranker.Frame.Parent = SubSection.Frame.Holder.List

					for _, v in next, list do Ranker:Add(v) end

					return Ranker
				end

				-- Button
				function SubSection:AddButton(name, callback)
					local Button = {
						Name = name,
						Type = "Button",
						Callback = callback,
					}

					Button.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, 32),

						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
							Size = UDim2.new(1, -2, 1, -2),
							Position = UDim2.new(0, 1, 0, 1),

							SelfModules.UI.Create("TextButton", {
								Name = "Button",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
								Position = UDim2.new(0, 2, 0, 2),
								Size = UDim2.new(1, -4, 1, -4),
								AutoButtonColor = false,
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
							}, UDim.new(0, 5)),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))

					-- Functions

					local function buttonVisual()
						task.spawn(function()
							local Visual = SelfModules.UI.Create("Frame", {
								Name = "Visual",
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 0.9,
								Position = UDim2.new(0.5, 0, 0.5, 0),
								Size = UDim2.new(0, 0, 1, 0),
							}, UDim.new(0, 5))

							Visual.Parent = Button.Frame.Holder.Button
							tween(Visual, 0.5, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
							task.wait(0.5)
							Visual:Destroy()
						end)
					end

					-- Scripts

					SubSection.List[#SubSection.List + 1] = Button
					Button.Frame.Parent = SubSection.Frame.Holder.List

					Button.Frame.Holder.Button.MouseButton1Down:Connect(function()
						Button.Frame.Holder.Button.TextSize = 12
					end)

					Button.Frame.Holder.Button.MouseButton1Up:Connect(function()
						Button.Frame.Holder.Button.TextSize = 14
						buttonVisual()

						pcall(task.spawn, Button.Callback)
					end)

					Button.Frame.Holder.Button.MouseLeave:Connect(function()
						Button.Frame.Holder.Button.TextSize = 14
					end)

					return Button
				end

				-- Toggle
				function SubSection:AddToggle(name, options, callback)
					local Toggle = {
						Name = name,
						Type = "Toggle",
						Flag = options and options.flag or name,
						Callback = callback,
						Boolean = nil,
					}
					Toggle.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, 32),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0.5, -7),
								Size = UDim2.new(1, -50, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
							SelfModules.UI.Create("Frame", {
								Name = "Indicator",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
								Position = UDim2.new(1, -42, 0, 2),
								Size = UDim2.new(0, 40, 0, 26),
								SelfModules.UI.Create("Frame", {
									Name = "Filler",
									BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
									Position = UDim2.new(0.5, 0, 0, 0),
									Size = UDim2.new(0.5, 0, 1, 0)
								}, UDim.new(0, 5)),
								SelfModules.UI.Create("ImageLabel", {
									Name = "Overlay",
									BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
									Position = UDim2.new(0, 2, 0, 2),
									Size = UDim2.new(0, 22, 0, 22),
									Image = "http://www.roblox.com/asset/?id=7827504335",
									ImageTransparency = 1,
									SelfModules.UI.Create("ImageLabel", {
										Name = "Glow",
										BackgroundTransparency = 1,
										Position = UDim2.new(0, -13, 0, -13),
										Size = UDim2.new(1, 26, 1, 26),
										Image = "rbxassetid://10822615828",
										ImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
										ScaleType = Enum.ScaleType.Slice,
										SliceCenter = Rect.new(99, 99, 99, 99),
										ImageTransparency = 0.5,
										SliceScale = 0.2,
									}),
								}, UDim.new(1, 0)),
							}, UDim.new(1, 0))
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))

					function Toggle:Set(bool, instant)
						Tab.Flags[Toggle.Flag] = bool
						tween(Toggle.Frame.Holder.Indicator.Overlay.Glow, instant and 0 or 0.25, { ImageColor3 = bool and Library.Theme.Accent or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)), SliceScale = bool and 0.2 or 1, ImageTransparency = bool and 0.85 or 0.5 })
						tween(Toggle.Frame.Holder.Indicator.Overlay, instant and 0 or 0.25, { ImageTransparency = bool and 0 or 1, Position = bool and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2) })
						tween(Toggle.Frame.Holder.Indicator.Overlay.UICorner, instant and 0 or 0.25, { CornerRadius = UDim.new(bool and 0 or 1, bool and 5 or 0) })
						tween(Toggle.Frame.Holder.Indicator.Overlay, "Cosmetic", instant and 0 or 0.25, { BackgroundColor3 = bool and SelfModules.UI.Color.Add(Library.Theme.Accent, Color3.fromRGB(5, 5, 5)) or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)) })
						Toggle.Boolean = bool
						pcall(task.spawn, Toggle.Callback, bool)
					end
					function Toggle:Get()
						return Toggle.Boolean
					end
					SubSection.List[#SubSection.List + 1] = Toggle
					Tab.Flags[Toggle.Flag] = options.default == true
					Toggle.Frame.Parent = SubSection.Frame.Holder.List
					Toggle.Frame.Holder.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							Toggle:Set(not Tab.Flags[Toggle.Flag], false)
						end
					end)
					Toggle:Set(options.default == true, true)
					Toggle.Boolean = options.default == true or false
					return Toggle
				end

				-- Label
				function SubSection:AddLabel(name)
					local Label = {
						Name = name,
						Type = "Label",
					}
					Label.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, 22),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								AnchorPoint = Vector2.new(0, 0.5),
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 2, 0.5, 0),
								Size = UDim2.new(1, -4, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
							}),
						}, UDim.new(0, 5))
					}, UDim.new(0, 5))
					function Label:SetName(text)
						Label.Frame.Holder.Label.Text = text
					end
					function Label:GetName()
						return Label.Frame.Holder.Label.Text
					end
					SubSection.List[#SubSection.List + 1] = Label
					Label.Label = Label.Frame.Holder.Label
					Label.Frame.Parent = SubSection.Frame.Holder.List
					return Label
				end

				-- DualLabel
				function SubSection:AddDualLabel(options)
					options = options or {}
					local DualLabel = {
						Name = options[1].. " ".. options[2],
						Type = "DualLabel",
					}
					DualLabel.Frame = SelfModules.UI.Create("Frame", {
						Name = options[1].. " ".. options[2],
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, 22),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							SelfModules.UI.Create("TextLabel", {
								Name = "Label1",
								AnchorPoint = Vector2.new(0, 0.5),
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0.5, 0),
								Size = UDim2.new(0.5, -5, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = options[1],
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
							SelfModules.UI.Create("TextLabel", {
								Name = "Label2",
								AnchorPoint = Vector2.new(0, 0.5),
								BackgroundTransparency = 1,
								Position = UDim2.new(0.5, 0, 0.5, 0),
								Size = UDim2.new(0.5, -5, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = options[2],
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Right,
							}),
						}, UDim.new(0, 5))
					}, UDim.new(0, 5))
					function DualLabel:SetLeftText(text)
						DualLabel.Frame.Holder.Label1.Text = text
					end
					function DualLabel:GetLeftText()
						return DualLabel.Frame.Holder.Label1.Text
					end
					function DualLabel:SetRightText(text)
						DualLabel.Frame.Holder.Label2.Text = text
					end
					function DualLabel:GetRightText()
						return DualLabel.Frame.Holder.Label2.Text
					end
					SubSection.List[#SubSection.List + 1] = DualLabel
					DualLabel.Label1 = DualLabel.Frame.Holder.Label1
					DualLabel.Label2 = DualLabel.Frame.Holder.Label2
					DualLabel.Frame.Parent = SubSection.Frame.Holder.List
					return DualLabel
				end

				-- ClipboardLabel
				function SubSection:AddClipboardLabel(name, callback)
					local ClipboardLabel = {
						Name = name,
						Type = "ClipboardLabel",
						Callback = callback,
					}
					ClipboardLabel.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, 22),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								AnchorPoint = Vector2.new(0, 0.5),
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 2, 0.5, 0),
								Size = UDim2.new(1, -22, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
							}),
							SelfModules.UI.Create("ImageLabel", {
								Name = "Icon",
								BackgroundTransparency = 1,
								Position = UDim2.new(1, -18, 0, 2),
								Size = UDim2.new(0, 16, 0, 16),
								Image = "rbxassetid://9243581053",
							}),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))
					function ClipboardLabel:SetName(text)
						ClipboardLabel.Frame.Holder.Label.Text = text
					end
					function ClipboardLabel:GetName()
						return ClipboardLabel.Frame.Holder.Label.Text
					end
					SubSection.List[#SubSection.List + 1] = ClipboardLabel
					ClipboardLabel.Label = ClipboardLabel.Frame.Holder.Label
					ClipboardLabel.Frame.Parent = SubSection.Frame.Holder.List
					ClipboardLabel.Frame.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							local s, result = pcall(ClipboardLabel.Callback)
							if s then warn(result) end
						end
					end)
					return ClipboardLabel
				end

				-- Box
				function SubSection:AddBox(name, options, callback)
					local Box = {
						Name = name,
						Type = "Box",
						Extend = options.extend or 200,
						Callback = callback,
					}
					Box.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, 32),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0.5, -7),
								Size = UDim2.new(1, -135, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
							SelfModules.UI.Create("Frame", {
								Name = "TextBox",
								AnchorPoint = Vector2.new(1, 0),
								BackgroundColor3 = Library.Theme.SectionColor,
								Position = UDim2.new(1, -2, 0, 2),
								Size = UDim2.new(0, 140, 1, -4),
								ZIndex = 2,
								SelfModules.UI.Create("Frame", {
									Name = "Holder",
									BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(5, 5, 5)),
									Position = UDim2.new(0, 1, 0, 1),
									Size = UDim2.new(1, -2, 1, -2),
									ZIndex = 2,
									SelfModules.UI.Create("TextBox", {
										Name = "Box",
										AnchorPoint = Vector2.new(0, 0.5),
										BackgroundTransparency = 1,
										ClearTextOnFocus = options.clearonfocus ~= true,
										Position = UDim2.new(0, 28, 0.5, 0),
										Size = UDim2.new(1, -30, 1, 0),
										Font = Enum.Font.SourceSans,
										PlaceholderText = "Text",
										Text = "",
										TextColor3 = Library.Theme.TextColor,
										TextSize = 14,
										TextWrapped = true,
									}),
									SelfModules.UI.Create("TextLabel", {
										Name = "Icon",
										AnchorPoint = Vector2.new(0, 0.5),
										BackgroundTransparency = 1,
										Position = UDim2.new(0, 6, 0.5, 0),
										Size = UDim2.new(0, 14, 0, 14),
										Font = Enum.Font.SourceSansBold,
										Text = "T",
										TextColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(40, 40, 40)),
										TextSize = 18,
										TextWrapped = true,
									}),
								}, UDim.new(0, 5)),
							}, UDim.new(0, 5))
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))

					local function extendBox(bool)
						tween(Box.Frame.Holder.TextBox, 0.25, { Size = UDim2.new(0, bool and math.clamp(math.abs(Box.Extend), 140, 386 - (Box.Frame.Holder.Label.TextBounds.X + 20)) or bool and 200 or 140, 1, -4) })
					end
					function Box:SetName(text)
						Box.Frame.Holder.Label.Text = text
					end
					function Box:GetName()
						return Box.Frame.Holder.Label.Text
					end
					function Box:SetText(text)
						Box.Frame.Holder.TextBox.Holder.Box.Text = text
					end
					function Box:GetText()
						return Box.Frame.Holder.TextBox.Holder.Box.Text
					end
					function Box:SetExtend(number)
						options.extend = number
					end
					function Box:GetExtend()
						return math.abs(options.extend)
					end
					function Box:Clear()
						Box.Frame.Holder.TextBox.Holder.Box.Text = ""
						extendBox(false)
					end
					
					SubSection.List[#SubSection.List + 1] = Box
					Box.Box = Box.Frame.Holder.TextBox.Holder.Box
					Box.Frame.Parent = SubSection.Frame.Holder.List
					Box.Frame.Holder.TextBox.Holder.MouseEnter:Connect(function()
						extendBox(true)
					end)
					Box.Frame.Holder.TextBox.Holder.MouseLeave:Connect(function()
						if not Box.Frame.Holder.TextBox.Holder.Box:IsFocused() then
							extendBox(false)
						end
					end)
					Box.Frame.Holder.TextBox.Holder.Box.FocusLost:Connect(function()
						if Box.Frame.Holder.TextBox.Holder.Box.Text == "" and options.fireonempty ~= true then
							return
						end
						extendBox(false)
						pcall(task.spawn, Box.Callback, Box.Frame.Holder.TextBox.Holder.Box.Text)
						if options.keepfocused ~= nil and options.keepfocused == true then
							Box.Frame.Holder.TextBox.Holder.Box:CaptureFocus()
						end
					end)
					Box.Frame.Holder.TextBox.Holder.Box.Focused:Connect(function()
						extendBox(true)
					end)
					Box.Frame.Holder.TextBox.Holder.Box:GetPropertyChangedSignal("Text"):Connect(function()
						if options.fireonchange ~= true then return end
						if Box.Frame.Holder.TextBox.Holder.Box.Text == "" and options.fireonempty ~= true then return end
						pcall(task.spawn, Box.Callback, Box.Frame.Holder.TextBox.Holder.Box.Text)
					end)
					return Box
				end

				-- Bind
				function SubSection:AddBind(name, bind, options, callback)
					local Bind = {
						Name = name,
						Type = "Bind",
						Bind = bind,
						Flag = options.flag or name,
						Callback = callback,
						Boolean = nil,
					}
					Bind.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, 32),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0.5, -7),
								Size = UDim2.new(1, -135, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
							SelfModules.UI.Create("Frame", {
								Name = "Bind",
								AnchorPoint = Vector2.new(1, 0),
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
								Position = UDim2.new(1, -2, 0, 2),
								Size = UDim2.new(0, 78, 0, 26),
								ZIndex = 2,
								SelfModules.UI.Create("TextLabel", {
									Name = "Label",
									BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
									Position = UDim2.new(0, 1, 0, 1),
									Size = UDim2.new(1, -2, 1, -2),
									Font = Enum.Font.SourceSans,
									Text = "",
									TextColor3 = Library.Theme.TextColor,
									TextSize = 14,
								}, UDim.new(0, 5)),
							}, UDim.new(0, 5)),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))

					local indicatorEntered = false
					local connections = {}
					local function listenForInput()
						if connections.listen then connections.listen:Disconnect() end
						Bind.Frame.Holder.Bind.Label.Text = "..."
						ListenForInput = true
						connections.listen = UIS.InputBegan:Connect(function(input, gameProcessed)
							if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
								Bind:Set(input.KeyCode)
							end
						end)
					end
					local function cancelListen()
						if connections.listen then connections.listen:Disconnect(); connections.listen = nil end
						Bind.Frame.Holder.Bind.Label.Text = Bind.Bind.Name
						task.spawn(function() RS.RenderStepped:Wait(); ListenForInput = false end)
					end
					function Bind:Set(bind)
						Bind.Bind = bind
						Bind.Frame.Holder.Bind.Label.Text = bind.Name
						Bind.Frame.Holder.Bind.Size = UDim2.new(0, math.max(12 + math.round(TXS:GetTextSize(bind.Name, 14, Enum.Font.SourceSans, Vector2.new(9e9)).X + 0.5), 42), 0, 26)
						if connections.listen then cancelListen() end
						if options.toggleable == true then
							Bind.Frame.Holder.Indicator.Position = UDim2.new(1, -(Bind.Frame.Holder.Bind.Size.X.Offset+5), 0, 2)
						end
					end
					function Bind:Get()
						return Bind.Boolean
					end
					function Bind:SetName(text)
						Bind.Frame.Holder.Label.Text = text
					end
					function Bind:GetName()
						return Bind.Frame.Holder.Label.Text
					end
					if options.toggleable == true then
						function Bind:Toggle(bool, instant)
							Tab.Flags[Bind.Flag] = bool
							tween(Bind.Frame.Holder.Indicator.Overlay.Glow, instant and 0 or 0.25, { ImageColor3 = bool and Library.Theme.Accent or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)), SliceScale = bool and 0.2 or 1, ImageTransparency = bool and 0.85 or 0.5 })
							tween(Bind.Frame.Holder.Indicator.Overlay, instant and 0 or 0.25, { ImageTransparency = bool and 0 or 1, Position = bool and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2) })
							tween(Bind.Frame.Holder.Indicator.Overlay.UICorner, instant and 0 or 0.25, { CornerRadius = UDim.new(bool and 0 or 1, bool and 5 or 0) })
							tween(Bind.Frame.Holder.Indicator.Overlay, "Cosmetic", instant and 0 or 0.25, { BackgroundColor3 = bool and SelfModules.UI.Color.Add(Library.Theme.Accent, Color3.fromRGB(5, 5, 5)) or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)) })
							Bind.Boolean = bool
							if options.fireontoggle ~= false then
								pcall(task.spawn, Bind.Callback, Bind.Bind)
							end
						end
					end
					SubSection.List[#SubSection.List + 1] = Bind
					Bind.Frame.Parent = SubSection.Frame.Holder.List
					Bind.Frame.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							if indicatorEntered == true then
								Bind:Toggle(not Tab.Flags[Bind.Flag], false)
							else
								listenForInput()
							end
						end
					end)
					UIS.InputBegan:Connect(function(input)
						if input.KeyCode == Bind.Bind then
							if (options.toggleable == true and Tab.Flags[Bind.Flag] == false) or ListenForInput then
								return
							end
							pcall(task.spawn, Bind.Callback, Bind.Bind)
						end
					end)
					if options.toggleable == true then
						local indicator = SelfModules.UI.Create("Frame", {
							Name = "Indicator",
							AnchorPoint = Vector2.new(1, 0),
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
							Position = UDim2.new(1, -(Bind.Frame.Holder.Bind.Size.X.Offset+5), 0, 2),
							Size = UDim2.new(0, 40, 0, 26),
							SelfModules.UI.Create("Frame", {
								Name = "Filler",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
								Position = UDim2.new(0.5, 0, 0, 0),
								Size = UDim2.new(0.5, 0, 1, 0)
							}, UDim.new(0, 5)),
							SelfModules.UI.Create("ImageLabel", {
								Name = "Overlay",
								ImageColor3 = Library.Theme.TextColor,
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
								Position = UDim2.new(0, 2, 0, 2),
								Size = UDim2.new(0, 22, 0, 22),
								Image = "http://www.roblox.com/asset/?id=7827504335",
								SelfModules.UI.Create("ImageLabel", {
									Name = "Glow",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, -13, 0, -13),
									Size = UDim2.new(1, 26, 1, 26),
									Image = "rbxassetid://10822615828",
									ImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
									ScaleType = Enum.ScaleType.Slice,
									SliceCenter = Rect.new(99, 99, 99, 99),
									ImageTransparency = 0.5,
									SliceScale = 0.2,
								}),
							}, UDim.new(1, 0)),
						}, UDim.new(1, 0))
						Tab.Flags[Bind.Flag] = options.default == true
						indicator.Parent = Bind.Frame.Holder
						Bind.Frame.Holder.Indicator.MouseEnter:Connect(function()
							indicatorEntered = true
						end)
						Bind.Frame.Holder.Indicator.MouseLeave:Connect(function()
							indicatorEntered = false
						end)
						Bind:Toggle(options.default == true, true)
						Bind.Boolean = options.default == true or false
					end
					Bind:Set(Bind.Bind)
					return Bind
				end

				-- Slider
				function SubSection:AddSlider(name, min, max, default, options, callback)
					local isDual = options.dual == true

					local defaultVal1, defaultVal2
					if isDual then
						if type(default) == "table" then
							defaultVal1 = default[1] ~= nil and default[1] or min
							defaultVal2 = default[2] ~= nil and default[2] or max
						else
							defaultVal1 = min
							defaultVal2 = max
						end
					end

					local Slider = {
						Name   = name,
						Type   = "Slider",
						Value  = isDual and defaultVal1 or default,
						Value2 = isDual and defaultVal2 or nil,
						Min    = min,
						Max    = max,
						Flag   = options.flag or name,
						Cap    = options.cap or false,
						Callback = callback,
					}

					Slider.Frame = SelfModules.UI.Create("Frame", {
						Name = name,
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, 41),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 0, 5),
								Size = UDim2.new(1, -75, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
							SelfModules.UI.Create("Frame", {
								Name = "Slider",
								BackgroundTransparency = 1,
								Position = UDim2.new(0, 5, 1, -15),
								Size = UDim2.new(1, -10, 0, 10),
								SelfModules.UI.Create("Frame", {
									Name = "Bar",
									BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
									ClipsDescendants = false,
									Size = UDim2.new(1, 0, 1, 0),
									SelfModules.UI.Create("Frame", {
										Name = "Fill",
										BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.Accent, Color3.fromRGB(10, 10, 10)),
										Size = UDim2.new(0.5, 0, 1, 0),
										SelfModules.UI.Create("ImageLabel", {
											Name = "Glow",
											BackgroundTransparency = 1,
											Position = UDim2.new(0, -12, 0, -12),
											Size = UDim2.new(1, 30, 1, 24),
											Image = "rbxassetid://10822615828",
											ImageColor3 = SelfModules.UI.Color.Sub(Library.Theme.Accent, Color3.fromRGB(10, 10, 10)),
											ScaleType = Enum.ScaleType.Slice,
											SliceCenter = Rect.new(99, 99, 99, 99),
											ImageTransparency = 0.9,
											SliceScale = 1,
										}),
									}, UDim.new(0, 5)),
								}, UDim.new(0, 5)),
								SelfModules.UI.Create("Frame", {
									Name = "Point",
									AnchorPoint = Vector2.new(0.5, 0.5),
									BackgroundColor3 = Library.Theme.Accent,
									Position = UDim2.new(0.5, 0, 0.5, 0),
									Size = UDim2.new(0, 12, 0, 12),
								}, UDim.new(0, 5)),
							}),
							SelfModules.UI.Create("TextBox", {
								Name = "Input",
								AnchorPoint = Vector2.new(1, 0),
								BackgroundTransparency = 1,
								PlaceholderText = "...",
								Position = UDim2.new(1, -5, 0, 5),
								Size = UDim2.new(0, 60, 0, 14),
								Font = Enum.Font.SourceSans,
								Text = "",
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Right,
							}),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))

					if isDual then
						local Point2 = SelfModules.UI.Create("Frame", {
							Name = "Point2",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Library.Theme.Accent,
							Position = UDim2.new(1, 0, 0.5, 0),
							Size = UDim2.new(0, 12, 0, 12),
						}, UDim.new(0, 5))
						Point2.Parent = Slider.Frame.Holder.Slider
						Slider.Frame.Holder.Input.Size  = UDim2.new(0, 90, 0, 14)
						Slider.Frame.Holder.Label.Size  = UDim2.new(1, -100, 0, 14)
					end

					local connections   = {}
					local draggingPoint = nil

					local function getSliderValue(val)
						if options.cap == true then
							val = math.clamp(val, Slider.Min, Slider.Max)
						else
							val = math.clamp(val, -math.huge, math.huge)
						end
						if options.rounded == true then
							val = math.floor(val)
						end
						return val
					end

					local function sliderVisual(v1, v2)
						local sliderW  = math.max(Slider.Frame.Holder.Slider.AbsoluteSize.X, 1)
						local pointPad = 1 / sliderW * 5
						if isDual then
							v1 = getSliderValue(v1)
							v2 = getSliderValue(v2)
							Slider.Frame.Holder.Input.Text = v1 .. " — " .. v2
							local p1 = math.clamp((v1 - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
							local p2 = math.clamp((v2 - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
							tween(Slider.Frame.Holder.Slider.Bar.Fill, 0.25, {
								Position = UDim2.new(p1, 0, 0, 0),
								Size     = UDim2.new(p2 - p1, 0, 1, 0),
							})
							tween(Slider.Frame.Holder.Slider.Point, 0.25, {
								Position = UDim2.fromScale(math.clamp(p1, pointPad, 1 - pointPad), 0.5),
							})
							local pt2 = Slider.Frame.Holder.Slider:FindFirstChild("Point2")
							if pt2 then
								tween(pt2, 0.25, {
									Position = UDim2.fromScale(math.clamp(p2, pointPad, 1 - pointPad), 0.5),
								})
							end
						else
							v1 = getSliderValue(v1)
							Slider.Frame.Holder.Input.Text = v1
							local pct = 1 - ((Slider.Max - v1) / (Slider.Max - Slider.Min))
							tween(Slider.Frame.Holder.Slider.Bar.Fill, 0.25, { Size = UDim2.new(pct, 0, 1, 0) })
							tween(Slider.Frame.Holder.Slider.Point, 0.25, {
								Position = UDim2.fromScale(math.clamp(pct, pointPad, 1 - pointPad), 0.5),
							})
						end
					end

					function Slider:Set(v1, v2)
						if isDual then
							v1 = getSliderValue(v1 ~= nil and v1 or Slider.Value)
							v2 = getSliderValue(v2 ~= nil and v2 or Slider.Value2)
							if v1 > v2 then v1, v2 = v2, v1 end
							Slider.Value  = v1
							Slider.Value2 = v2
							sliderVisual(v1, v2)
							if options.toggleable == true and Tab.Flags[Slider.Flag] == false then return end
							pcall(task.spawn, Slider.Callback, v1, v2, Tab.Flags[Slider.Flag] or nil)
						else
							v1 = getSliderValue(v1)
							Slider.Value = v1
							sliderVisual(v1)
							if options.toggleable == true and Tab.Flags[Slider.Flag] == false then return end
							pcall(task.spawn, Slider.Callback, v1, Tab.Flags[Slider.Flag] or nil)
						end
					end

					function Slider:Get()
						if isDual then
							return Slider.Value, Slider.Value2
						end
						return Slider.Value
					end

					function Slider:Change(newMin, newMax)
						Slider.Min = newMin
						Slider.Max = newMax
						if isDual then
							Slider:Set(getSliderValue(Slider.Value), getSliderValue(Slider.Value2))
						else
							Slider:Set(getSliderValue(Slider.Value))
						end
					end

					function Slider:SetName(text)
						Slider.Frame.Holder.Label.Text = text
					end
					function Slider:GetName()
						return Slider.Frame.Holder.Label.Text
					end

					if options.toggleable == true then
						function Slider:Toggle(bool, instant)
							Tab.Flags[Slider.Flag] = bool
							tween(Slider.Frame.Holder.Indicator.Overlay.Glow, instant and 0 or 0.25, {
								ImageColor3       = bool and Library.Theme.Accent or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
								SliceScale        = bool and 0.2 or 1,
								ImageTransparency = bool and 0.85 or 0.5,
							})
							tween(Slider.Frame.Holder.Indicator.Overlay, instant and 0 or 0.25, {
								ImageTransparency = bool and 0 or 1,
								Position          = bool and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2),
							})
							tween(Slider.Frame.Holder.Indicator.Overlay.UICorner, instant and 0 or 0.25, {
								CornerRadius = UDim.new(bool and 0 or 1, bool and 5 or 0),
							})
							tween(Slider.Frame.Holder.Indicator.Overlay, "Cosmetic", instant and 0 or 0.25, {
								BackgroundColor3 = bool
									and SelfModules.UI.Color.Add(Library.Theme.Accent, Color3.fromRGB(5, 5, 5))
									or  SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
							})
							if options.fireontoggle ~= false then
								if isDual then
									pcall(task.spawn, Slider.Callback, Slider.Value, Slider.Value2, bool)
								else
									pcall(task.spawn, Slider.Callback, Slider.Value, bool)
								end
							end
						end
					end

					SubSection.List[#SubSection.List + 1] = Slider
					Slider.Frame.Parent = SubSection.Frame.Holder.List

					Slider.Frame.Holder.Slider.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							if isDual then
								local sliderX = Slider.Frame.Holder.Slider.AbsolutePosition.X
								local sliderW = math.max(Slider.Frame.Holder.Slider.AbsoluteSize.X, 1)
								local mPct    = math.clamp((Mouse.X - sliderX) / sliderW, 0, 1)
								local p1      = math.clamp((Slider.Value  - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
								local p2      = math.clamp((Slider.Value2 - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
								draggingPoint = math.abs(mPct - p1) <= math.abs(mPct - p2) and 1 or 2
							end
							connections.move = Mouse.Move:Connect(function()
								local sliderPercent = math.clamp(
									(Mouse.X - Slider.Frame.Holder.Slider.AbsolutePosition.X)
										/ math.max(Slider.Frame.Holder.Slider.AbsoluteSize.X, 1),
									0, 1
								)
								local sv = math.floor((Slider.Min + sliderPercent * (Slider.Max - Slider.Min)) * 10) / 10
								if isDual then
									if draggingPoint == 1 then
										local nv1 = math.min(sv, Slider.Value2)
										if options.fireondrag ~= false then Slider:Set(nv1, Slider.Value2)
										else sliderVisual(nv1, Slider.Value2) end
									else
										local nv2 = math.max(sv, Slider.Value)
										if options.fireondrag ~= false then Slider:Set(Slider.Value, nv2)
										else sliderVisual(Slider.Value, nv2) end
									end
								else
									if options.fireondrag ~= false then Slider:Set(sv)
									else sliderVisual(sv) end
								end
							end)
						end
					end)

					Slider.Frame.Holder.Slider.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							if connections.move then connections.move:Disconnect(); connections.move = nil end
							local sliderPercent = math.clamp(
								(Mouse.X - Slider.Frame.Holder.Slider.AbsolutePosition.X)
									/ math.max(Slider.Frame.Holder.Slider.AbsoluteSize.X, 1),
								0, 1
							)
							local sv = math.floor((Slider.Min + sliderPercent * (Slider.Max - Slider.Min)) * 10) / 10
							if isDual then
								if options.fireondrag ~= true then
									if draggingPoint == 1 then
										Slider:Set(math.min(sv, Slider.Value2), Slider.Value2)
									else
										Slider:Set(Slider.Value, math.max(sv, Slider.Value))
									end
								end
								draggingPoint = nil
							else
								if options.fireondrag ~= true then
									Slider:Set(sv)
								end
							end
						end
					end)

					Slider.Frame.Holder.Input.FocusLost:Connect(function()
						if isDual then return end
						Slider.Frame.Holder.Input.Text = string.sub(Slider.Frame.Holder.Input.Text, 1, 10)
						if tonumber(Slider.Frame.Holder.Input.Text) then
							Slider:Set(Slider.Frame.Holder.Input.Text)
						end
					end)

					if options.toggleable == true then
						local indicator = SelfModules.UI.Create("Frame", {
							Name = "Indicator",
							AnchorPoint = Vector2.new(1, 1),
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
							Position = UDim2.new(1, -2, 1, -2),
							Size = UDim2.new(0, 40, 0, 26),
							SelfModules.UI.Create("Frame", {
								Name = "Filler",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
								Position = UDim2.new(0.5, 0, 0, 0),
								Size = UDim2.new(0.5, 0, 1, 0)
							}, UDim.new(0, 5)),
							SelfModules.UI.Create("ImageLabel", {
								Name = "Overlay",
								ImageColor3 = Library.Theme.TextColor,
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
								Position = UDim2.new(0, 2, 0, 2),
								Size = UDim2.new(0, 22, 0, 22),
								Image = "http://www.roblox.com/asset/?id=7827504335",
								SelfModules.UI.Create("ImageLabel", {
									Name = "Glow",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, -13, 0, -13),
									Size = UDim2.new(1, 26, 1, 26),
									Image = "rbxassetid://10822615828",
									ImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
									ScaleType = Enum.ScaleType.Slice,
									SliceCenter = Rect.new(99, 99, 99, 99),
									ImageTransparency = 0.5,
									SliceScale = 0.2,
								}),
							}, UDim.new(1, 0)),
						}, UDim.new(1, 0))
						Tab.Flags[Slider.Flag] = options.default == true
						Slider.Frame.Size = UDim2.new(1, 2, 0, 54)
						Slider.Frame.Holder.Slider.Size = UDim2.new(1, -50, 0, 10)
						indicator.Parent = Slider.Frame.Holder
						Slider.Frame.Holder.Indicator.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								Slider:Toggle(not Tab.Flags[Slider.Flag], false)
							end
						end)
						Slider:Toggle(options.default == true, true)
					end

					if isDual then
						Slider:Set(defaultVal1, defaultVal2)
					else
						Slider:Set(Slider.Value)
					end

					return Slider
				end

				-- Dropdown
				function SubSection:AddDropdown(name, list, options, callback)
					local Dropdown = {
						Name = name,
						Type = "Dropdown",
						Toggled = false,
						Selected = options and options.multi == true and {} or "",
						List = {},
						Callback = callback,
					}
					local ListObjects = {}
					Dropdown.Frame = SelfModules.UI.Create("Frame", {
						Name = "Dropdown",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						Size = UDim2.new(1, 2, 0, 42),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							SelfModules.UI.Create("Frame", {
								Name = "Holder",
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 0, 40),
								SelfModules.UI.Create("Frame", {
									Name = "Displays",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, 5, 0, 8),
									Size = UDim2.new(1, -35, 0, 14),
									SelfModules.UI.Create("TextBox", {
										Name = "SearchBox",
										ClearTextOnFocus = false,
										TextTransparency = 1,
										BackgroundTransparency = 1,
										PlaceholderText = "Search",
										PlaceholderColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
										Font = Enum.Font.SourceSansBold,
										Text = "",
										TextSize = 14,
										TextWrapped = false,
										TextTruncate = Enum.TextTruncate.SplitWord,
										TextColor3 = Library.Theme.TextColor,
										TextXAlignment = Enum.TextXAlignment.Left,
										Size = UDim2.new(0, 0, 1, 0),
									}),
									SelfModules.UI.Create("TextLabel", {
										Name = "Label",
										BackgroundTransparency = 1,
										Size = UDim2.new(0.5, 0, 1, 0),
										Font = Enum.Font.SourceSans,
										Text = name,
										TextColor3 = Library.Theme.TextColor,
										TextSize = 14,
										TextWrapped = true,
										TextXAlignment = Enum.TextXAlignment.Left,
									}),
									SelfModules.UI.Create("TextLabel", {
										Name = "Selected",
										BackgroundTransparency = 1,
										Position = UDim2.new(0.5, 0, 0, 0),
										Size = UDim2.new(0.5, 0, 1, 0),
										Font = Enum.Font.SourceSans,
										Text = "",
										TextColor3 = Library.Theme.TextColor,
										TextSize = 14,
										TextWrapped = true,
										TextXAlignment = Enum.TextXAlignment.Right,
									}),
								}),
								SelfModules.UI.Create("ImageLabel", {
									Name = "Indicator",
									AnchorPoint = Vector2.new(1, 0),
									BackgroundTransparency = 1,
									Position = UDim2.new(1, -5, 0, 5),
									Size = UDim2.new(0, 20, 0, 20),
									Image = "rbxassetid://9243354333",
								}),
								SelfModules.UI.Create("Frame", {
									Name = "Line",
									BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
									BorderSizePixel = 0,
									Position = UDim2.new(0, 5, 0, 30),
									Size = UDim2.new(1, -10, 0, 2),
								}),
							}, UDim.new(0, 5)),
							SelfModules.UI.Create("ScrollingFrame", {
								Name = "List",
								Active = true,
								BackgroundTransparency = 1,
								BorderSizePixel = 0,
								Position = UDim2.new(0, 5, 0, 40),
								Size = UDim2.new(1, -10, 1, -40),
								CanvasSize = UDim2.new(0, 0, 0, 0),
								ScrollBarImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
								ScrollBarThickness = 5,
								SelfModules.UI.Create("UIListLayout", {
									SortOrder = Enum.SortOrder.LayoutOrder,
									Padding = UDim.new(0, 5),
								}),
							}),
						}, UDim.new(0,5)),
					}, UDim.new(0, 5))

					function Dropdown:GetHeight()
						return 42 + (Dropdown.Toggled == true and math.min(#Dropdown.List, 5) * 27 or 0)
					end
					function Dropdown:UpdateHeight()
						Dropdown.Frame.Holder.List.CanvasSize = UDim2.new(0, 0, 0, #Dropdown.List * 27 - 5)
						if Dropdown.Toggled == true then
							Dropdown.Frame.Size = UDim2.new(1, 2, 0, Dropdown:GetHeight())
							SubSection:UpdateHeight()
						end
					end
					function Dropdown:Add(name, options, callback)
						local Item = {
							Name = name,
							Callback = callback,
						}
						Item.Frame = SelfModules.UI.Create("Frame", {
							Name = name,
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
							Size = UDim2.new(1, -10, 0, 22),
							SelfModules.UI.Create("TextButton", {
								Name = "Button",
								BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
								Position = UDim2.new(0, 1, 0, 1),
								Size = UDim2.new(1, -2, 1, -2),
								Font = Enum.Font.SourceSans,
								Text = name,
								TextColor3 = Library.Theme.TextColor,
								TextSize = 14,
								TextWrapped = true,
							}, UDim.new(0, 5)),
						}, UDim.new(0, 5))
						function Dropdown:SetName(text)
							Dropdown.Frame.Holder.Holder.Displays.Label = text
						end
						function Dropdown:GetName()
							return Dropdown.Frame.Holder.Holder.Displays.Label
						end
						Dropdown.List[#Dropdown.List + 1] = name
						ListObjects[#ListObjects + 1] = Item
						Item.Frame.Parent = Dropdown.Frame.Holder.List
						if Dropdown.Toggled == true then Dropdown:UpdateHeight() end
						Item.Frame.Button.Activated:Connect(function()
							if typeof(Item.Callback) == "function" then
								pcall(task.spawn, Item.Callback)
							else
								Dropdown:Select(Item.Name)
							end
						end)
						Dropdown.Frame.Holder.Holder.Displays.SearchBox.Size = UDim2.new(0, Dropdown.Frame.Holder.Holder.Displays.Label.TextBounds.X, 1, 0)
						Dropdown.Frame.Holder.Holder.Displays.SearchBox.Focused:Connect(function()
							Dropdown:Toggle(true)
							tween(Dropdown.Frame.Holder.Holder.Displays.SearchBox, 2, { Size = UDim2.new(1, -(Dropdown.Frame.Holder.Holder.Displays.Selected.TextBounds.X-1), 1, 0), TextTransparency = 0 })
							tween(Dropdown.Frame.Holder.Holder.Displays.Label, 0.5, { TextTransparency = 1 })
						end)
						Dropdown.Frame.Holder.Holder.Displays.SearchBox.FocusLost:Connect(function()
							tween(Dropdown.Frame.Holder.Holder.Displays.SearchBox, 0.5, { Size = UDim2.new(0, Dropdown.Frame.Holder.Holder.Displays.Label.TextBounds.X, 1, 0) })
							tween(Dropdown.Frame.Holder.Holder.Displays.Label, 0.5, { TextTransparency = 0 })
							Dropdown.Frame.Holder.Holder.Displays.SearchBox.Text = ""
						end)
						Dropdown.Frame.Holder.Holder.Displays.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
							local searchText = Dropdown.Frame.Holder.Holder.Displays.SearchBox.Text:lower()
							for _, item in pairs(Dropdown.Frame.Holder.List:GetChildren()) do
								if item:IsA("Frame") then
									item.Visible = item.Name:lower():find(searchText) ~= nil
								end
							end
						end)
						return Item
					end
					function Dropdown:Remove(name, ignoreToggle)
						for i, v in next, Dropdown.List do
							if v == name then
								local item = ListObjects[i]
								if item then
									item.Frame:Destroy()
									table.remove(Dropdown.List, i)
									table.remove(ListObjects, i)
									if Dropdown.Toggled then Dropdown:UpdateHeight() end
									if #Dropdown.List == 0 and not ignoreToggle then Dropdown:Toggle(false) end
								end
								break
							end
						end
					end
					function Dropdown:ClearList()
						for _ = 1, #Dropdown.List do
							Dropdown:Remove(Dropdown.List[1], true)
						end
					end
					function Dropdown:SetList(list)
						Dropdown:ClearList()
						for _, v in next, list do Dropdown:Add(v) end
					end
					function Dropdown:Select(itemName)
						if options and options.multi == true then
							if table.find(Dropdown.Selected, itemName) then
								for i, v in ipairs(Dropdown.Selected) do
									if v == itemName then
										table.remove(Dropdown.Selected, i)
										break
									end
								end
							else
								table.insert(Dropdown.Selected, itemName)
							end
							Dropdown.Frame.Holder.Holder.Displays.Selected.Text = table.concat(Dropdown.Selected, ", ")
							pcall(task.spawn, Dropdown.Callback, Dropdown.Selected)
						else
							Dropdown.Selected = itemName
							Dropdown.Frame.Holder.Holder.Displays.Selected.Text = itemName
							Dropdown:Toggle(false)
							pcall(task.spawn, Dropdown.Callback, itemName)
						end
					end
					function Dropdown:Toggle(bool)
						Dropdown.Toggled = bool
						tween(Dropdown.Frame, 0.5, { Size = UDim2.new(1, 2, 0, Dropdown:GetHeight()) })
						tween(Dropdown.Frame.Holder.Holder.Indicator, 0.5, { Rotation = bool and 90 or 0 })
						tween(SubSection.Frame, 0.5, { Size = UDim2.new(1, 2, 0, SubSection:GetHeight()) })
						tween(Section.Frame, 0.5, { Size = UDim2.new(1, -10, 0, Section:GetHeight()) })
						tween(Tab.Frame, 0.5, { CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight()) })
					end

					SubSection.List[#SubSection.List + 1] = Dropdown
					Dropdown.Frame.Parent = SubSection.Frame.Holder.List
					Dropdown.Frame.Holder.List.ChildAdded:Connect(function(c)
						if c.ClassName == "Frame" then Dropdown:UpdateHeight() end
					end)
					Dropdown.Frame.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and #Dropdown.List > 0 and Mouse.Y - Dropdown.Frame.AbsolutePosition.Y <= 30 then
							Dropdown:Toggle(not Dropdown.Toggled)
						end
					end)
					for i, v in next, list do Dropdown:Add(v) end
					if options and typeof(options.default) == "string" then
						Dropdown:Select(options.default)
					end
					return Dropdown
				end

				-- Picker
				function SubSection:AddPicker(name, options, callback)
					local Picker = {
						Name = name,
						Type = "Picker",
						Toggled = false,
						Rainbow = false,
						RainbowSpeed = 1,
						Callback = callback,
					}
					local h, s, v = (options.color or Library.Theme.Accent):ToHSV()
					Picker.Color = { R = h, G = s, B = v }

					Picker.Frame = SelfModules.UI.Create("Frame", {
						Name = "ColorPicker",
						BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
						ClipsDescendants = true,
						Size = UDim2.new(1, 2, 0, 42),
						SelfModules.UI.Create("Frame", {
							Name = "Holder",
							BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
							ClipsDescendants = true,
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							SelfModules.UI.Create("Frame", {
								Name = "Top",
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 0, 40),
								SelfModules.UI.Create("TextLabel", {
									Name = "Label",
									BackgroundTransparency = 1,
									Position = UDim2.new(0, 5, 0, 8),
									Size = UDim2.new(0.5, -15, 0, 14),
									Font = Enum.Font.SourceSans,
									Text = name,
									TextColor3 = Library.Theme.TextColor,
									TextSize = 14,
									TextWrapped = true,
									TextXAlignment = Enum.TextXAlignment.Left,
								}),
								SelfModules.UI.Create("Frame", {
									Name = "Selected",
									AnchorPoint = Vector2.new(1, 0),
									BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
									Position = UDim2.new(1, -29, 0, 2),
									Size = UDim2.new(0, 100, 0, 26),
									SelfModules.UI.Create("Frame", {
										Name = "Preview",
										BackgroundColor3 = Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B),
										Position = UDim2.new(0, 1, 0, 1),
										Size = UDim2.new(1, -2, 1, -2),
										SelfModules.UI.Create("ImageLabel", {
											Name = "Glow",
											BackgroundTransparency = 1,
											Position = UDim2.new(0, -12, 0, -12),
											Size = UDim2.new(1, 24, 1, 24),
											Image = "rbxassetid://10822615828",
											ImageColor3 = Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B),
											ScaleType = Enum.ScaleType.Slice,
											SliceCenter = Rect.new(99, 99, 99, 99),
											ImageTransparency = 0.75,
											SliceScale = 0.2,
										}),
									}, UDim.new(0, 5)),
									SelfModules.UI.Create("TextLabel", {
										Name = "Display",
										AnchorPoint = Vector2.new(0, 0.5),
										BackgroundTransparency = 1,
										Position = UDim2.new(0, 0, 0.5, 0),
										Size = UDim2.new(1, 0, 0, 16),
										Font = Enum.Font.SourceSans,
										Text = "",
										TextColor3 = Library.Theme.TextColor,
										TextSize = 16,
										TextStrokeColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
										TextStrokeTransparency = 0.5,
									}),
								}, UDim.new(0, 5)),
								SelfModules.UI.Create("ImageLabel", {
									Name = "Indicator",
									AnchorPoint = Vector2.new(1, 0),
									BackgroundTransparency = 1,
									Position = UDim2.new(1, -5, 0, 5),
									Size = UDim2.new(0, 20, 0, 20),
									Image = "rbxassetid://9243354333",
								}),
								SelfModules.UI.Create("Frame", {
									Name = "Line",
									BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
									BorderSizePixel = 0,
									Position = UDim2.new(0, 5, 0, 30),
									Size = UDim2.new(1, -10, 0, 2),
								}),
							}),
							SelfModules.UI.Create("Frame", {
								Name = "Holder",
								Active = true,
								BackgroundTransparency = 1,
								BorderSizePixel = 0,
								Position = UDim2.new(0, 0, 0, 40),
								Size = UDim2.new(1, 0, 1, -40),
								SelfModules.UI.Create("Frame", {
									Name = "Palette",
									BackgroundTransparency = 1,
									BorderSizePixel = 0,
									Position = UDim2.new(0, 5, 0, 5),
									Size = UDim2.new(1, -196, 0, 110),
									SelfModules.UI.Create("Frame", {
										Name = "Point",
										AnchorPoint = Vector2.new(0.5, 0.5),
										BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
										Position = UDim2.new(1, 0, 0, 0),
										Size = UDim2.new(0, 7, 0, 7),
										ZIndex = 2,
										SelfModules.UI.Create("Frame", {
											Name = "Inner",
											BackgroundColor3 = Color3.fromRGB(255, 255, 255),
											Position = UDim2.new(0, 1, 0, 1),
											Size = UDim2.new(1, -2, 1, -2),
											ZIndex = 2,
										}, UDim.new(1, 0)),
									}, UDim.new(1, 0)),
									SelfModules.UI.Create("Frame", {
										Name = "Hue",
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										BorderSizePixel = 0,
										Size = UDim2.new(1, 0, 1, 0),
										SelfModules.UI.Create("UIGradient", {
											Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B))},
										}),
										SelfModules.UI.Create("ImageLabel", {
											Name = "Glow",
											BackgroundTransparency = 1,
											ScaleType = Enum.ScaleType.Slice,
											SliceCenter = Rect.new(99, 99, 99, 99),
											SliceScale = 0.2,
											Size = UDim2.new(1, 24, 1, 24),
											Position = UDim2.new(0, -12, 0, -12),
											Image = "rbxassetid://10822615828",
											ImageTransparency = 0.75,
											SelfModules.UI.Create("UIGradient", {
												Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B))},
												Rotation = -45,
												Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.90, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)}
											}),
										}),
									}, UDim.new(0, 5)),
									SelfModules.UI.Create("Frame", {
										Name = "SatVal",
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										BorderSizePixel = 0,
										Size = UDim2.new(1, 0, 1, 0),
										ZIndex = 2,
										SelfModules.UI.Create("UIGradient", {
											Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))},
											Rotation = 90,
											Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)},
										}),
									}, UDim.new(0, 5)),
								}),
								SelfModules.UI.Create("Frame", {
									Name = "HueSlider",
									BackgroundColor3 = Color3.fromRGB(255, 255, 255),
									BorderSizePixel = 0,
									Position = UDim2.new(0, 5, 0, 125),
									Size = UDim2.new(1, -10, 0, 20),
									SelfModules.UI.Create("ImageLabel", {
										Name = "Glow",
										BackgroundTransparency = 1,
										Position = UDim2.new(0, -12, 0, -12),
										Size = UDim2.new(1, 24, 1, 24),
										Image = "rbxassetid://10822615828",
										ImageColor3 = Color3.fromRGB(255, 255, 255),
										ScaleType = Enum.ScaleType.Slice,
										SliceCenter = Rect.new(99, 99, 99, 99),
										ImageTransparency = 0.75,
										SliceScale = 0.2,
										SelfModules.UI.Create("UIGradient", {
											Color = ColorSequence.new{
												ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
												ColorSequenceKeypoint.new(0.16666, Color3.fromRGB(255, 255, 0)),
												ColorSequenceKeypoint.new(0.33333, Color3.fromRGB(0, 255, 0)),
												ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
												ColorSequenceKeypoint.new(0.66667, Color3.fromRGB(0, 0, 255)),
												ColorSequenceKeypoint.new(0.83333, Color3.fromRGB(255, 0, 255)),
												ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
											},
										}),
									}),
									SelfModules.UI.Create("UIGradient", {
										Color = ColorSequence.new{
											ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
											ColorSequenceKeypoint.new(0.16666, Color3.fromRGB(255, 255, 0)),
											ColorSequenceKeypoint.new(0.33333, Color3.fromRGB(0, 255, 0)),
											ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
											ColorSequenceKeypoint.new(0.66667, Color3.fromRGB(0, 0, 255)),
											ColorSequenceKeypoint.new(0.83333, Color3.fromRGB(255, 0, 255)),
											ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
										},
									}),
									SelfModules.UI.Create("Frame", {
										Name = "Bar",
										AnchorPoint = Vector2.new(0.5, 0.5),
										BackgroundColor3 = SelfModules.UI.Color.Sub(Library.Theme.SectionColor, Color3.fromRGB(10, 10, 10)),
										Position = UDim2.new(0.5, 0, 0, 0),
										Size = UDim2.new(0, 6, 1, 6),
										SelfModules.UI.Create("Frame", {
											Name = "Inner",
											BackgroundColor3 = Color3.fromRGB(255, 255, 255),
											Position = UDim2.new(0, 1, 0, 1),
											Size = UDim2.new(1, -2, 1, -2),
										}, UDim.new(0, 5)),
									}, UDim.new(0, 5)),
								}, UDim.new(0, 5)),
								SelfModules.UI.Create("Frame", {
									Name = "RGB",
									BackgroundTransparency = 1,
									Position = UDim2.new(1, -180, 0, 5),
									Size = UDim2.new(0, 75, 0, 110),
									SelfModules.UI.Create("Frame", {
										Name = "Red",
										BackgroundTransparency = 1,
										Size = UDim2.new(1, 0, 0, 30),
										SelfModules.UI.Create("TextBox", {
											Name = "Box",
											BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
											Size = UDim2.new(1, 0, 1, 0),
											Font = Enum.Font.SourceSans,
											PlaceholderText = "R",
											Text = 255,
											TextColor3 = Library.Theme.TextColor,
											TextSize = 16,
											TextWrapped = true,
										}, UDim.new(0, 5)),
									}, UDim.new(0, 5)),
									SelfModules.UI.Create("Frame", {
										Name = "Green",
										BackgroundTransparency = 1,
										Position = UDim2.new(0, 0, 0, 40),
										Size = UDim2.new(1, 0, 0, 30),
										SelfModules.UI.Create("TextBox", {
											Name = "Box",
											BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
											Size = UDim2.new(1, 0, 1, 0),
											Font = Enum.Font.SourceSans,
											PlaceholderText = "G",
											Text = 0,
											TextColor3 = Library.Theme.TextColor,
											TextSize = 16,
											TextWrapped = true,
										}, UDim.new(0, 5)),
									}, UDim.new(0, 5)),
									SelfModules.UI.Create("Frame", {
										Name = "Blue",
										BackgroundTransparency = 1,
										Position = UDim2.new(0, 0, 0, 80),
										Size = UDim2.new(1, 0, 0, 30),
										SelfModules.UI.Create("TextBox", {
											Name = "Box",
											BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(15, 15, 15)),
											Size = UDim2.new(1, 0, 1, 0),
											Font = Enum.Font.SourceSans,
											PlaceholderText = "B",
											Text = 0,
											TextColor3 = Library.Theme.TextColor,
											TextSize = 16,
											TextWrapped = true,
										}, UDim.new(0, 5)),
									}, UDim.new(0, 5)),
								}),
								SelfModules.UI.Create("Frame", {
									Name = "Rainbow",
									AnchorPoint = Vector2.new(1, 0),
									BackgroundTransparency = 1,
									Position = UDim2.new(1, -5, 0, 87),
									Size = UDim2.new(0, 90, 0, 26),
									SelfModules.UI.Create("Frame", {
										Name = "Indicator",
										BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(20, 20, 20)),
										Size = UDim2.new(0, 80, 0, 26),
										SelfModules.UI.Create("TextLabel", {
											Name = "Label",
											BackgroundTransparency = 1,
											Position = UDim2.new(0, 0, 0, 0),
											Size = UDim2.new(1, 0, 1, 0),
											Font = Enum.Font.SourceSansBold,
											Text = "Rainbow",
											TextColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
											TextSize = 14,
											TextWrapped = true,
											TextXAlignment = Enum.TextXAlignment.Center,
											ZIndex = -1,
										}),
										SelfModules.UI.Create("ImageLabel", {
											Name = "Overlay",
											BackgroundColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
											Position = UDim2.new(0, 2, 0, 2),
											Size = UDim2.new(0, 22, 0, 22),
											Image = "http://www.roblox.com/asset/?id=7827504335",
											ImageTransparency = 1,
											SelfModules.UI.Create("ImageLabel", {
												Name = "Glow",
												BackgroundTransparency = 1,
												Position = UDim2.new(0, -13, 0, -13),
												Size = UDim2.new(1, 26, 1, 26),
												Image = "rbxassetid://10822615828",
												ImageColor3 = SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)),
												ScaleType = Enum.ScaleType.Slice,
												SliceCenter = Rect.new(99, 99, 99, 99),
												ImageTransparency = 0.5,
												SliceScale = 0.2,
											}),
										}, UDim.new(1, 0)),
									}, UDim.new(1, 0)),
								})
							}),
						}, UDim.new(0, 5)),
					}, UDim.new(0, 5))

					local hueDragging, satDragging = false, false

					function Picker:GetHeight()
						return Picker.Toggled == true and 192 or 42
					end
					function Picker:Toggle(bool)
						Picker.Toggled = bool
						tween(Picker.Frame, 0.5, { Size = UDim2.new(1, 2, 0, Picker:GetHeight()) })
						tween(Picker.Frame.Holder.Top.Indicator, 0.5, { Rotation = bool and 90 or 0 })
						tween(SubSection.Frame, 0.5, { Size = UDim2.new(1, 2, 0, SubSection:GetHeight()) })
						tween(Section.Frame, 0.5, { Size = UDim2.new(1, -10, 0, Section:GetHeight()) })
						tween(Tab.Frame, 0.5, { CanvasSize = UDim2.new(0, 0, 0, Tab:GetHeight()) })
					end
					function Picker:ToggleRainbow(bool)
						Picker.Rainbow = bool
						tween(Picker.Frame.Holder.Holder.Rainbow.Indicator.Overlay.Glow, 0.25, {ImageColor3 = bool and Library.Theme.Accent or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)), SliceScale = bool and 0.2 or 1, ImageTransparency = bool and 0.85 or 0.5})
						tween(Picker.Frame.Holder.Holder.Rainbow.Indicator.Overlay, 0.25, {ImageTransparency = bool and 0 or 1, Position = bool and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 2, 0, 2) })
						tween(Picker.Frame.Holder.Holder.Rainbow.Indicator.Overlay, "Cosmetic", 0.25, { BackgroundColor3 = bool and SelfModules.UI.Color.Add(Library.Theme.Accent, Color3.fromRGB(15, 15, 15)) or SelfModules.UI.Color.Add(Library.Theme.SectionColor, Color3.fromRGB(25, 25, 25)) })
						if bool then
							if not Storage.Connections[Picker] then Storage.Connections[Picker] = {} end
							Storage.Connections[Picker].Rainbow = RS.Heartbeat:Connect(function()
								Picker:Set(tick() % Picker.RainbowSpeed / Picker.RainbowSpeed, Picker.Color.G, Picker.Color.B)
							end)
						elseif Storage.Connections[Picker] and Storage.Connections[Picker].Rainbow then
							Storage.Connections[Picker].Rainbow:Disconnect()
							Storage.Connections[Picker].Rainbow = nil
						end
					end
					function Picker:Speed(value)
						Picker.RainbowSpeed = tonumber(value)
					end
					function Picker:Set(h, s, v)
						Picker.Color.R, Picker.Color.G, Picker.Color.B = h, s, v
						local color = Color3.fromHSV(h, s, v)
						Picker.Frame.Holder.Holder.Palette.Hue.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
						Picker.Frame.Holder.Top.Selected.Preview.BackgroundColor3 = color
						Picker.Frame.Holder.Top.Selected.Preview.Glow.ImageColor3 = color
						Picker.Frame.Holder.Top.Selected.Display.Text = string.format("%d, %d, %d", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
						Picker.Frame.Holder.Top.Selected.Size = UDim2.new(0, math.round(TXS:GetTextSize(Picker.Frame.Holder.Top.Selected.Display.Text, 16, Enum.Font.SourceSans, Vector2.new(9e9)).X + 0.5) + 20, 0, 26)
						Picker.Frame.Holder.Holder.RGB.Red.Box.Text = math.floor(color.R * 255 + 0.5)
						Picker.Frame.Holder.Holder.RGB.Green.Box.Text = math.floor(color.G * 255 + 0.5)
						Picker.Frame.Holder.Holder.RGB.Blue.Box.Text = math.floor(color.B * 255 + 0.5)
						Picker.Frame.Holder.Holder.Palette.Hue.Glow.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
						tween(Picker.Frame.Holder.Holder.HueSlider.Bar, 0.1, { Position = UDim2.new(h, 0, 0.5, 0) })
						tween(Picker.Frame.Holder.Holder.Palette.Point, 0.1, { Position = UDim2.new(s, 0, 1 - v, 0) })
						pcall(task.spawn, Picker.Callback, color)
					end
					function Picker:Get()
						return Picker.Color.R, Picker.Color.G, Picker.Color.B
					end
					function Picker:SetName(text)
						Picker.Frame.Holder.Top.Label.Text = text
					end
					function Picker:GetName()
						return Picker.Frame.Holder.Top.Label
					end

					SubSection.List[#SubSection.List + 1] = Picker
					Picker.Frame.Parent = SubSection.Frame.Holder.List
					Picker.Frame.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 and Mouse.Y - Picker.Frame.AbsolutePosition.Y <= 30 then
							Picker:Toggle(not Picker.Toggled)
						end
					end)
					Picker.Frame.Holder.Holder.HueSlider.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = true end
					end)
					Picker.Frame.Holder.Holder.HueSlider.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
					end)
					Picker.Frame.Holder.Holder.Palette.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then satDragging = true end
					end)
					Picker.Frame.Holder.Holder.Palette.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then satDragging = false end
					end)
					Mouse.Move:Connect(function()
						if hueDragging and not Picker.Rainbow then
							Picker:Set(math.clamp((Mouse.X - Picker.Frame.Holder.Holder.HueSlider.AbsolutePosition.X) / Picker.Frame.Holder.Holder.HueSlider.AbsoluteSize.X, 0, 1), Picker.Color.G, Picker.Color.B)
						elseif satDragging then
							Picker:Set(Picker.Color.R, math.clamp((Mouse.X - Picker.Frame.Holder.Holder.Palette.AbsolutePosition.X) / Picker.Frame.Holder.Holder.Palette.AbsoluteSize.X, 0, 1), 1 - math.clamp((Mouse.Y - Picker.Frame.Holder.Holder.Palette.AbsolutePosition.Y) / Picker.Frame.Holder.Holder.Palette.AbsoluteSize.Y, 0, 1))
						end
					end)
					Picker.Frame.Holder.Holder.RGB.Red.Box.FocusLost:Connect(function()
						local num = tonumber(Picker.Frame.Holder.Holder.RGB.Red.Box.Text)
						local color = Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B)
						if num then
							Picker:Set(Color3.new(math.clamp(math.floor(num), 0, 255) / 255, color.G, color.B):ToHSV())
						else
							Picker.Frame.Holder.Holder.RGB.Red.Box.Text = math.floor(color.R * 255 + 0.5)
						end
					end)
					Picker.Frame.Holder.Holder.RGB.Green.Box.FocusLost:Connect(function()
						local num = tonumber(Picker.Frame.Holder.Holder.RGB.Green.Box.Text)
						local color = Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B)
						if num then
							Picker:Set(Color3.new(color.R, math.clamp(math.floor(num), 0, 255) / 255, color.B):ToHSV())
						else
							Picker.Frame.Holder.Holder.RGB.Green.Box.Text = math.floor(color.G * 255 + 0.5)
						end
					end)
					Picker.Frame.Holder.Holder.RGB.Blue.Box.FocusLost:Connect(function()
						local num = tonumber(Picker.Frame.Holder.Holder.RGB.Blue.Box.Text)
						local color = Color3.fromHSV(Picker.Color.R, Picker.Color.G, Picker.Color.B)
						if num then
							Picker:Set(Color3.new(color.R, color.G, math.clamp(math.floor(num), 0, 255) / 255):ToHSV())
						else
							Picker.Frame.Holder.Holder.RGB.Blue.Box.Text = math.floor(color.B * 255 + 0.5)
						end
					end)
					Picker.Frame.Holder.Holder.Rainbow.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							Picker:ToggleRainbow(not Picker.Rainbow)
						end
					end)
					Picker:Set(Picker.Color.R, Picker.Color.G, Picker.Color.B)
					return Picker
				end

				SubSection.Frame.Holder.List.ChildAdded:Connect(function(c)
					if c.ClassName == "Frame" then SubSection:UpdateHeight() end
				end)
				SubSection.Frame.Holder.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and #SubSection.List > 0 and Window.Sidebar.Frame.AbsoluteSize.X <= 35 and Mouse.Y - SubSection.Frame.AbsolutePosition.Y <= 30 then
						toggleSubSection(not SubSection.Toggled)
					end
				end)

				Section.List[#Section.List + 1] = SubSection
				SubSection.Frame.Parent = Section.Frame.List
				return SubSection
			end

			return Section
		end

		return Tab
	end

	loadup()
	return Window
end

function Library:AddAuthentication(options)
	assert(type(options) == "table", "Authentication requires an options table")
	if options.Key == nil and options.Method == "KEY" and options.Lock == false then error("Key is required on unlocked non-token method") return end
	assert(options.Method == "Key" or options.Method == "Token", 'Authentication requires options.Method to be "Key" or "Token"')

	local Verification = {
		Type = "Authentication Menu",
		_secretKey = options.Key,
		_activeMethod = options.Method,
		_LockMethod = options.Lock,
		_isAuthenticated = false,
		_lastInput = nil,
		_onSubmit = nil,
		_onClose = nil,
	}

	repeat wait() until Storage.AuthenticationConfiguration.IsBusy == false
	Storage.AuthenticationConfiguration.IsBusy = true

	local icon, hasIcon do
		local raw = options.Icon
		if type(raw) == "string" and raw ~= "" then
			icon = raw:find("rbxassetid://", 1, true) and raw or ("rbxassetid://" .. raw)
			hasIcon = true
		else
			icon = nil
			hasIcon = false
		end
	end

	Verification.Frame = SelfModules.UI.Create("CanvasGroup", {
		Name = "Window",
		Size = UDim2.new(0, 324, 0, 330),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		Position = UDim2.new(0.5, 0, -1.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = math.random(-45, 45),

		hasIcon and SelfModules.UI.Create("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Size = UDim2.new(0.5, 0, 1, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			ScaleType = Enum.ScaleType.Crop,
			Image = icon,
			ImageTransparency = 1,
		}) or nil,

		SelfModules.UI.Create("Frame", {
			Name = "PositionHandler",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),

			SelfModules.UI.Create("Frame", {
				Name = "Handler",
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				BorderSizePixel = 0,

				SelfModules.UI.Create("TextButton", {
					Name = "Close",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 5, 0, 5),
					Size = UDim2.new(0, 20, 0, 20),
					Font = Enum.Font.SourceSansBold,
					Text = "+",
					TextColor3 = Color3.fromRGB(65, 65, 65),
					TextSize = 20,
					AutoButtonColor = false,
					Rotation = 45,
					ZIndex = 4,
				}, UDim.new(0, 6)),

				SelfModules.UI.Create("UICorner", {
					CornerRadius = UDim.new(0, 12),
				}),

				SelfModules.UI.Create("Frame", {
					Name = "InputField",
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 260, 0, 51),
					Position = UDim2.new(0.097, 0, 0.282, 0),
					BorderSizePixel = 0,

					SelfModules.UI.Create("TextBox", {
						Name = "Box",
						BackgroundTransparency = 1,
						Size = UDim2.new(0, options.Method == "Token" and 113 or 226, 0, 20),
						Position = UDim2.new(0.0242, 0, 0.4706, 0),
						Font = Enum.Font.SourceSans,
						PlaceholderColor3 = Color3.fromRGB(200, 200, 200),
						PlaceholderText = options.Method == "Token" and "Username" or "Key",
						Text = "",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						ClearTextOnFocus = false,
						TextSize = 15,
						TextXAlignment = Enum.TextXAlignment.Left,
						BorderSizePixel = 0,
						TextTruncate = Enum.TextTruncate.AtEnd,
					}),

					SelfModules.UI.Create("TextBox", {
						Name = "Box2",
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 113, 0, 20),
						Position = UDim2.new(0.459, 0, 0.4706, 0),
						Font = Enum.Font.SourceSans,
						PlaceholderColor3 = Color3.fromRGB(200, 200, 200),
						PlaceholderText = "Password",
						Text = "",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						ClearTextOnFocus = false,
						TextSize = 15,
						TextXAlignment = Enum.TextXAlignment.Left,
						BorderSizePixel = 0,
						Visible = options.Method == "Token" and true or false,
						TextTruncate = Enum.TextTruncate.AtEnd,

						SelfModules.UI.Create("TextLabel", {
							Name = "Label",
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 0, 0, 0),
							Size = UDim2.new(1, 0, 1, 0),
							Font = Enum.Font.SourceSans,
							Text = "",
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Top,
							TextSize = 18,
							ZIndex = 2,
							BorderSizePixel = 0,
							TextTruncate = Enum.TextTruncate.AtEnd,
							SelfModules.UI.Create("UIStroke", {
								Thickness = 0.8,
								Color = Color3.fromRGB(35, 35, 35),
							}),
						}),
					}),

					SelfModules.UI.Create("Frame", {
						Name = "Fill",
						BackgroundColor3 = Color3.fromRGB(35, 35, 35),
						Position = UDim2.new(0, 0, 0.9412, 0),
						Size = UDim2.new(1, 0, 0, 2),
						BorderSizePixel = 0,

						SelfModules.UI.Create("Frame", {
							Name = "ActiveFill",
							BackgroundColor3 = Color3.fromRGB(70, 70, 70),
							Size = UDim2.new(0, 0, 0, 2),
							BorderSizePixel = 0,
							SelfModules.UI.Create("UICorner", {
								CornerRadius = UDim.new(1, 0),
							}),
						}),
					}),

					SelfModules.UI.Create("ImageButton", {
						Name = "SubmitButton",
						Image = "rbxassetid://9243354333",
						BackgroundTransparency = 1,
						Position = UDim2.new(0.903, 0, 0.471, 0),
						Rotation = 270,
						Size = UDim2.new(0, 20, 0, 20),
						BorderSizePixel = 0,
					}),
				}),

				SelfModules.UI.Create("Frame", {
					Name = "Footer",
					BackgroundColor3 = Color3.fromRGB(35, 35, 35),
					Position = UDim2.new(0.096, 0, 0.604, 0),
					Size = UDim2.new(0, 260, 0, 62),
					BorderSizePixel = 0,

					SelfModules.UI.Create("Frame", {
						Name = "DiscordButton",
						BackgroundColor3 = Color3.fromRGB(98, 111, 252),
						Position = UDim2.new(0.065, 0, 0.226, 0),
						Size = UDim2.new(0, options.Lock == true and 227 or 111, 0, 34),
						ZIndex = 2,

						SelfModules.UI.Create("TextButton", {
							Name = "TextButton",
							BackgroundColor3 = Color3.fromRGB(88, 101, 242),
							BorderSizePixel = 0,
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							Font = Enum.Font.SourceSansBold,
							Text = options.Lock == true and "Join Discord Server" or "Discord Server",
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = 15,
							AutoButtonColor = false,
							ZIndex = 3,
							SelfModules.UI.Create("UICorner", {
								CornerRadius = UDim.new(0, 6),
							}),
						}),

						SelfModules.UI.Create("UICorner", {
							CornerRadius = UDim.new(0, 6),
						}),
					}),

					SelfModules.UI.Create("Frame", {
						Name = "ToggleMethodButton",
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						Position = UDim2.new(0.52, 0, 0.226, 0),
						Size = UDim2.new(0, 111, 0, 34),
						ZIndex = 2,
						Visible = not options.Lock,

						SelfModules.UI.Create("TextButton", {
							Name = "TextButton",
							BackgroundColor3 = Color3.fromRGB(35, 35, 35),
							BorderSizePixel = 0,
							Position = UDim2.new(0, 1, 0, 1),
							Size = UDim2.new(1, -2, 1, -2),
							Font = Enum.Font.SourceSansBold,
							Text = options.Method == "Token" and "Use Key" or "Sign In",
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = 15,
							AutoButtonColor = false,
							ZIndex = 3,
						}, UDim.new(0, 6)),
					}, UDim.new(0, 6)),

					SelfModules.UI.Create("Frame", {
						Name = "View",
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						Position = UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(1, -2, 1, -2),
						BorderSizePixel = 0,

						SelfModules.UI.Create("Frame", {
							Name = "Liner",
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							Position = UDim2.new(0.2364, 0, -0.04, 0),
							Size = UDim2.new(0, 130, 0, 2),
							BorderSizePixel = 0,
							SelfModules.UI.Create("UIStroke", {
								Color = Color3.fromRGB(30, 30, 30),
							}),

							SelfModules.UI.Create("TextLabel", {
								Name = "Label",
								BackgroundTransparency = 1,
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.new(0.5, 0, 0.5, 0),
								Size = UDim2.new(0, 115, 0, 20),
								Font = Enum.Font.SourceSans,
								Text = "Looking for something?",
								TextColor3 = Color3.fromRGB(255, 255, 255),
								TextSize = 14,
								ZIndex = 2,
								BorderSizePixel = 0,
								SelfModules.UI.Create("UIStroke", {
									Thickness = 0.8,
									Color = Color3.fromRGB(35, 35, 35),
								}),
							}),
						}),

						SelfModules.UI.Create("UICorner", {
							CornerRadius = UDim.new(0, 14),
						}),
					}),

					SelfModules.UI.Create("UICorner", {
						CornerRadius = UDim.new(0, 14),
					}),
					SelfModules.UI.Create("UIStroke", {
						Thickness = 0.8,
						Color = Color3.fromRGB(35, 35, 35),
					}),
				}),
			}),
		}),
	}, UDim.new(0, 12))

	Verification.Frame.Parent = ScreenGui

	local handler = Verification.Frame.PositionHandler.Handler
	local Close = handler.Close
	local inputField = handler.InputField
	local box = inputField.Box
	local box2 = inputField.Box2
	local box2Label = inputField.Box2.Label
	local activeFill = inputField.Fill.ActiveFill
	local toggleBtn = handler.Footer.ToggleMethodButton.TextButton

	local COLORS = {
		correct = Color3.fromRGB(125, 255, 125),
		incorrect = Color3.fromRGB(255, 125, 125),
		neutral = Color3.fromRGB(70, 70, 70),
		expanded = UDim2.new(1, 0, 0, 2),
		collapsed = UDim2.new(0, 0, 0, 2),
	}

	local Tinfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local Tinfo2 = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local Tinfo3 = TweenInfo.new(2.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

	function Verification:OnSubmit(callback)
		assert(type(callback) == "function", "OnSubmit requires a function")
		self._onSubmit = callback
	end
	
	function Verification:OnClose(callback)
		assert(type(callback) == "function", "OnSubmit requires a function")
		self._onClose = callback
	end

	function Verification:GetActiveMethod()
		return self._activeMethod
	end

	function Verification:IsAuthenticated()
		return self._isAuthenticated
	end

	function Verification:GetInput()
		return self._lastInput
	end

	function Verification:Close()
		for _, conn in pairs(Storage.Authentication) do
			if typeof(conn) == "RBXScriptConnection" then
				conn:Disconnect()
			end
		end

		Storage.AuthenticationConfiguration.IsBusy = false

		TS:Create(Verification.Frame, Tinfo3, {
			GroupTransparency = 1,
			Rotation = math.random(-15, 15),
			Position = UDim2.new(0.5, 0, 2, 0),
		}):Play()

		task.delay(1.5, function()
			if Verification.Frame and Verification.Frame.Parent then
				Verification.Frame:Destroy()
			end
		end)
	end

	TS:Create(Verification.Frame, Tinfo, {Rotation = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()

	if hasIcon then
		local iconLabel = Verification.Frame.Icon

		task.spawn(function()
			game:GetService("ContentProvider"):PreloadAsync({iconLabel})

			local elapsed = 0
			repeat
				elapsed += task.wait()
			until elapsed >= 0.5 or Verification._isAuthenticated

			if Verification._isAuthenticated then return end

			local expandInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

			TS:Create(Verification.Frame, expandInfo, {
				Size = UDim2.new(0, 648, 0, 330),
			}):Play()

			TS:Create(Verification.Frame.PositionHandler, expandInfo, {
				Size = UDim2.new(0, 324, 0, 330),
			}):Play()

			task.wait(0.2)
			TS:Create(iconLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				ImageTransparency = 0,
			}):Play()
		end)
	end

	local function setFillColor(color)
		TS:Create(activeFill, Tinfo2, {BackgroundColor3 = color}):Play()
	end

	local discordBusy = false
	local function onDiscordClicked()
		if not discordBusy then
			discordBusy = true
			handler.Footer.DiscordButton.TextButton.Text = RS:IsStudio() and "Retry Later"
			wait(1.5)
			handler.Footer.DiscordButton.TextButton.Text = RS:IsStudio() and "Discord Server"
			discordBusy = false
		end
	end

	Storage.Authentication.DiscordButton = handler.Footer.DiscordButton.TextButton.MouseButton1Click:Connect(onDiscordClicked)

	local function onToggleMethod()
		if options.Lock == true then return end
		Verification._activeMethod = Verification._activeMethod == "Key" and "Token" or "Key"
		toggleBtn.Text = Verification._activeMethod == "Token" and "Use Key" or "Sign In"
		box.PlaceholderText = Verification._activeMethod == "Token" and "Username" or "Key"
		box.Size = UDim2.new(0, Verification._activeMethod == "Token" and 113 or 226, 0, 20)
		box.Text = ""
		box2.Text = ""
		box2.Visible = Verification._activeMethod == "Token"
		setFillColor(COLORS.neutral)
	end

	Storage.Authentication.ToggleMethodButton = toggleBtn.MouseButton1Click:Connect(onToggleMethod)

	local submitted = false
	local function onSubmitPressed()
		if submitted then return end

		if Verification._activeMethod == "Key" then
			if box.Text == "" then return end
			Verification._lastInput = box.Text
			Verification._isAuthenticated = Verification._lastInput == Verification._secretKey
			if not Verification._isAuthenticated then return end
			submitted = true

			if Verification._onSubmit then
				Verification._onSubmit()
			end

			Verification:Close()

		elseif Verification._activeMethod == "Token" then
			if box.Text == "" or box2.Text == "" then return end
			Verification._lastInput = { Username = box.Text, Password = box2.Text }
			Verification._isAuthenticated = false

			if Verification._onSubmit then
				Verification._onSubmit()
			end
		end
	end
	
	local function onClosePressed()
		if Verification._onClose then
			Verification._onClose()
		end
	end

	Storage.Authentication.Close = Close.MouseButton1Click:Connect(onClosePressed)
	Storage.Authentication.SubmitButton = inputField.SubmitButton.MouseButton1Click:Connect(onSubmitPressed)

	-- Box (username/key) connections
	Storage.Authentication.InputFocused = box.Focused:Connect(function()
		TS:Create(activeFill, Tinfo2, {Size = COLORS.expanded}):Play()
	end)

	Storage.Authentication.InputFocusLost = box.FocusLost:Connect(function(enterPressed)
		if box.Text == "" and box2.Text == "" then
			TS:Create(activeFill, Tinfo2, {Size = COLORS.collapsed}):Play()
		end
		if enterPressed then
			onSubmitPressed()
		end
	end)

	-- Box2 (password) connections
	Storage.Authentication.Input2Focused = box2.Focused:Connect(function()
		TS:Create(activeFill, Tinfo2, {Size = COLORS.expanded}):Play()
	end)

	Storage.Authentication.Input2FocusLost = box2.FocusLost:Connect(function(enterPressed)
		if box.Text == "" and box2.Text == "" then
			TS:Create(activeFill, Tinfo2, {Size = COLORS.collapsed}):Play()
		end
		if enterPressed then
			onSubmitPressed()
		end
	end)

	-- Password masking: show dots in label, hide real text
	Storage.Authentication.Input2Changed = box2:GetPropertyChangedSignal("Text"):Connect(function()
		local text = box2.Text
		if text ~= "" then
			box2.TextTransparency = 1
			box2Label.Text = string.rep("•", #text)
		else
			box2.TextTransparency = 0
			box2Label.Text = ""
		end
	end)

	-- When box2 loses focus, keep the real text hidden if filled
	Storage.Authentication.Input2TextSync = box2.Focused:Connect(function()
		if box2.Text ~= "" then
			box2.TextTransparency = 1
		end
	end)

	-- Fill color feedback (Key mode only)
	Storage.Authentication.InputChanged = box:GetPropertyChangedSignal("Text"):Connect(function()
		if Verification._activeMethod == "Token" then return end
		local text = box.Text
		if text == Verification._secretKey then
			setFillColor(COLORS.correct)
		elseif text ~= "" then
			setFillColor(COLORS.incorrect)
		else
			setFillColor(COLORS.neutral)
		end
	end)

	return Verification
end

ScreenGui.Parent = VG
return Library
