--!strict

--------------
-- SERVICES --
--------------
local ServerScriptService = game:GetService("ServerScriptService")

-----------
-- TYPES --
-----------
type requiredModule = {
	["init"]: () -> (),
	["run"]: () -> (),

	[any]: any,
}

---------------
-- CONSTANTS --
---------------
local SERVER: Folder = ServerScriptService:FindFirstChild("Server") :: Folder
local MODULES: Folder = SERVER:FindFirstChild("ServerModules") :: Folder

---------------
-- VARIABLES --
---------------
local initializedModules = {} :: { [string]: requiredModule }

---------------
-- FUNCTIONS --
---------------
local function startInit(): ()
	local countToExpect = 0

	for _, module in ipairs(MODULES:GetChildren()) do
		if not module:IsA("ModuleScript") then
			error("Non-ModuleScript item found in expected modules folder: " .. module.Name)
			return
		end

		countToExpect += 1

		local requiredModule = require(module) :: requiredModule

		task.spawn(function()
			requiredModule.init()
			initializedModules[module.Name] = requiredModule
		end)
	end

	repeat
		task.wait()
	until countToExpect == #MODULES:GetChildren()
end

local function startRun(): ()
	for moduleName, module in pairs(initializedModules) do
		task.spawn(function()
			local success, err = pcall(function()
				module.run()
			end)

			if not success then
				warn("There was an issue starting module " .. moduleName .. ": " .. err)
			else
				print("[SERVER]: Successfully started module" .. moduleName)
			end
		end)
	end
end

local function startup()
	if not MODULES then
		error("Could not find modules folder in ServerScriptService.")
		return
	end

	startInit()
	startRun()
end

---------------
-- EXECUTION --
---------------
startup()
