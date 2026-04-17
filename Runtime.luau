local Library = {}

-- // Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- // Core Entities
Library.LocalPlayer = Players.LocalPlayer
Library.Character = nil
Library.Humanoid = nil
Library.HumanoidRootPart = nil
Library.Mouse = Players.LocalPlayer:GetMouse()
Library.Backpack = Players.LocalPlayer:WaitForChild("Backpack")
Library.IsAlive = false
Library.IsActive = true

Library._Connections = {}

Library.RunLoops = {
	RenderStepTable    = {},
	StepTable          = {},
	HeartTable         = {},
	PreRenderTable     = {},
	PreAnimationTable  = {},
	PreSimulationTable = {},
	PlayerAddedTable   = {},
	PlayerRemovingTable = {},
}

local RL = Library.RunLoops

function RL:BindToRenderStep(name, func)
	if not self.RenderStepTable[name] then
		self.RenderStepTable[name] = RunService.RenderStepped:Connect(func)
	end
end
function RL:UnbindFromRenderStep(name)
	if self.RenderStepTable[name] then
		self.RenderStepTable[name]:Disconnect()
		self.RenderStepTable[name] = nil
	end
end

function RL:BindToStepped(name, func)
	if not self.StepTable[name] then
		self.StepTable[name] = RunService.Stepped:Connect(func)
	end
end
function RL:UnbindFromStepped(name)
	if self.StepTable[name] then
		self.StepTable[name]:Disconnect()
		self.StepTable[name] = nil
	end
end

function RL:BindToHeartbeat(name, func)
	if not self.HeartTable[name] then
		self.HeartTable[name] = RunService.Heartbeat:Connect(func)
	end
end
function RL:UnbindFromHeartbeat(name)
	if self.HeartTable[name] then
		self.HeartTable[name]:Disconnect()
		self.HeartTable[name] = nil
	end
end

function RL:BindToPreRender(name, func)
	if not self.PreRenderTable[name] then
		self.PreRenderTable[name] = RunService.PreRender:Connect(func)
	end
end
function RL:UnbindFromPreRender(name)
	if self.PreRenderTable[name] then
		self.PreRenderTable[name]:Disconnect()
		self.PreRenderTable[name] = nil
	end
end

function RL:BindToPreAnimation(name, func)
	if not self.PreAnimationTable[name] then
		self.PreAnimationTable[name] = RunService.PreAnimation:Connect(func)
	end
end
function RL:UnbindFromPreAnimation(name)
	if self.PreAnimationTable[name] then
		self.PreAnimationTable[name]:Disconnect()
		self.PreAnimationTable[name] = nil
	end
end

function RL:BindToPreSimulation(name, func)
	if not self.PreSimulationTable[name] then
		self.PreSimulationTable[name] = RunService.PreSimulation:Connect(func)
	end
end
function RL:UnbindFromPreSimulation(name)
	if self.PreSimulationTable[name] then
		self.PreSimulationTable[name]:Disconnect()
		self.PreSimulationTable[name] = nil
	end
end

function RL:BindToPlayerAdded(name, func)
	if not self.PlayerAddedTable[name] then
		self.PlayerAddedTable[name] = Players.PlayerAdded:Connect(func)
	end
end
function RL:UnbindFromPlayerAdded(name)
	if self.PlayerAddedTable[name] then
		self.PlayerAddedTable[name]:Disconnect()
		self.PlayerAddedTable[name] = nil
	end
end

function RL:BindToPlayerRemoving(name, func)
	if not self.PlayerRemovingTable[name] then
		self.PlayerRemovingTable[name] = Players.PlayerRemoving:Connect(func)
	end
end
function RL:UnbindFromPlayerRemoving(name)
	if self.PlayerRemovingTable[name] then
		self.PlayerRemovingTable[name]:Disconnect()
		self.PlayerRemovingTable[name] = nil
	end
end

function RL:DestructAll()
	local tables = {
		self.RenderStepTable, self.StepTable, self.HeartTable,
		self.PreRenderTable, self.PreAnimationTable, self.PreSimulationTable,
		self.PlayerAddedTable, self.PlayerRemovingTable,
	}
	for _, t in ipairs(tables) do
		for name, conn in pairs(t) do
			if conn and conn.Connected then
				conn:Disconnect()
			end
			t[name] = nil
		end
	end
end

Library.Functions = {}

Library.Functions.Destruct = function(RBXScriptConnection: RBXScriptConnection)
	if RBXScriptConnection and RBXScriptConnection.Connected then
		RBXScriptConnection:Disconnect()
	end
end

Library.Functions.RefreshCharacter = function(character)
	Library.Character        = character
	Library.Humanoid         = character and character:FindFirstChildWhichIsA("Humanoid") or nil
	Library.HumanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") or nil
end

Library.Functions.Get = function()
	return {
		LocalPlayer      = Library.LocalPlayer,
		Character        = Library.Character,
		Humanoid         = Library.Humanoid,
		HumanoidRootPart = Library.HumanoidRootPart,
		Mouse            = Library.Mouse,
		Backpack         = Library.Backpack,
		IsAlive          = Library.IsAlive,
		IsActive         = Library.IsActive,
	}
end

Library.Functions.DestructAll = function()
	Library.IsActive = false

	for key, conn in pairs(Library._Connections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
		Library._Connections[key] = nil
	end

	Library.RunLoops:DestructAll()
end

if Library.LocalPlayer.Character then
	Library.Functions.RefreshCharacter(Library.LocalPlayer.Character)
end

Library._Connections.CharacterAdded = Library.LocalPlayer.CharacterAdded:Connect(function(character)
	Library.Functions.RefreshCharacter(character)
end)

Library._Connections.CharacterRemoving = Library.LocalPlayer.CharacterRemoving:Connect(function()
	Library.IsAlive          = false
	Library.Character        = nil
	Library.Humanoid         = nil
	Library.HumanoidRootPart = nil
end)

Library.RunLoops:BindToHeartbeat("__EntityUpdate", function()
	if not Library.IsActive then return end

	local character = Library.LocalPlayer.Character

	if character and Library.Character ~= character then
		Library.Functions.RefreshCharacter(character)
	end

	Library.IsAlive = Library.Humanoid ~= nil and Library.Humanoid.Health > 0
end)

return Library
