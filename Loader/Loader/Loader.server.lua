--[[

	imskyyc
	Aspirium Loader
	11/14/2021
	
]]--

-- Script Globals --
local oldPrint = print
local oldWarn  = warn
local oldError = error
local oldDebug = debug

local print = function(...) for _, Message in pairs({...}) do oldPrint("[Aspirium : Server Loader : INFO]: " .. tostring(Message)) end end
local warn  = function(...) for _, Message in pairs({...}) do oldWarn("[Aspirium : Server Loader : WARN]: " .. tostring(Message)) end end
local error = function(...) for _, Message in pairs({...}) do oldError("[Aspirium : Server Loader : ERROR]:  " .. tostring(Message)) end end
local debug = {output = function(...) for _, Message in pairs({...}) do oldPrint("[Aspirium : Server Loader : DEBUG]:  " .. tostring(Message)) end end}

	for Index, Value in pairs(oldDebug) do
		debug[Index] = Value
	end

-- Services and Variables --
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Loader = script.Parent
local Container = Loader.Parent
local PluginsFolder = Container.Plugins
local SettingsInstance = Container.Settings

-- Data Table --
local DataTable = {
	Settings = {},
	Descriptions = {},
	Plugins = {}
}

-- Functions --
local GetPlugins = function()
	local Plugins = {}

	for _, Plugin in pairs(PluginsFolder:GetChildren()) do
		if Plugin:IsA("ModuleScript") then
			local IsRunnable, Function = pcall(require, Plugin)

			if IsRunnable then
				if type(Function) == "function" then
					Plugins[Plugin.Name] = Function
				else
					warn("Plugin " .. tostring(Plugin.Name) .. " did not return a function.")
				end
			else
				warn("Plugin " .. tostring(Plugin.Name) .. " encountered an error while loading. Error: " .. tostring(Function))
			end
		else
			warn("Object " .. tostring(Plugin.Name) .. " of class " .. tostring(Plugin.ClassName) .. " is not a module.")
		end
	end

	return Plugins
end

local GetModule = function()
	local ModuleId = DataTable.Settings.ModuleId
	local MainModule

	if ModuleId then
		MainModule = ModuleId
	else
		warn("No ModuleId was set. Attempting to find a local copy...")
		local Module = ServerStorage:FindFirstChild("MainModule")

		if Module then
			MainModule = Module
		else
			error("No MainModule was found.")
		end
	end

	local IsRunnable, Function = pcall(require, MainModule)

	if IsRunnable then
		local Metatable = getmetatable(Function)
		if Metatable == "Aspirium" then	
			return Function
		end
	else
		error("MainModule encountered an error while loading. Error: " .. tostring(Function))
	end
end

local Load = function()
	local IsValid, Settings = pcall(require, SettingsInstance)
	
	if IsValid then
		DataTable.Settings = Settings.Settings
		DataTable.Descriptions = Settings.Descriptions
		DataTable.Plugins = GetPlugins()
		
		local Aspirium = GetModule()
		print(Aspirium)
		local ServerStarted, ServerResponse, ServerErrorCount = Aspirium(DataTable)
		
		if ServerStarted then
			PluginsFolder:Destroy()
			SettingsInstance:Destroy()
			
			Container.Parent = nil
		else
			error("Aspirium server failed to start. Response: " .. tostring(ServerResponse) .. ";\nErrors: " .. tostring(ServerErrorCount))
			
			Container:Destroy()
		end
	end
end

Load()