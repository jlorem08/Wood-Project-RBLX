--!strict

--------------
-- SERVICES --
--------------
local StarterPlayer = game:GetService("StarterPlayer")

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
local STARTER_PLAYER_SCRIPTS = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local CLIENT: Folder = STARTER_PLAYER_SCRIPTS:FindFirstChild("Client") :: Folder
local MODULES: Folder = CLIENT:FindFirstChild("ServerModules") :: Folder

---------------
-- VARIABLES --
---------------
local initializedModules = {} :: { [string]: requiredModule } -- used to avoid having to require a module twice

---------------
-- FUNCTIONS --
---------------

-- initialize all modules in the modules folder
local function startInit(): ()
	local countToExpect = 0 -- number of modules that should be waited for until thread resumes

	for _, module in ipairs(MODULES:GetChildren()) do
		if not module:IsA("ModuleScript") then -- verify instance is a module script
			error("Non-ModuleScript item found in expected modules folder: " .. module.Name)
			return
		end

		local requiredModule = require(module) :: requiredModule

		task.spawn(function() -- allow for asynchronous initializations
			local success = pcall(function()
				requiredModule.init()
			end)

			if not success then
				warn("[CLIENT]: There was an issue initializing module " .. module.Name)
				return
			else
				print("[CLIENT]: Successfully initialized module" .. module.Name)
			end

			countToExpect += 1
			initializedModules[module.Name] = requiredModule -- add to initialized modules dictionary
		end)
	end

	repeat
		task.wait() -- pause the thread until all modules are initialized
	until countToExpect == #MODULES:GetChildren()
end

-- run all modules in the modules folder that were able to be initialized
local function startRun(): ()
	for moduleName, module in pairs(initializedModules) do
		task.spawn(function() -- allow for asynchronous running
			local success = pcall(function()
				module.run()
			end)

			if not success then
				warn("[CLIENT]: There was an issue starting module " .. moduleName)
			else
				print("[CLIENT]: Successfully started module" .. moduleName)
			end
		end)
	end
end

-- start the main process of initializing and running
local function startup()
	if not MODULES then
		error("[CLIENT]: Could not find modules folder in StarterPlayerScripts.")
		return
	end

	startInit()
	startRun()
end

---------------
-- EXECUTION --
---------------
startup()
