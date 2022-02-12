--[[

    imskyyc
    Aspirium Server
    12/23/2021 @ 12:04 PM PST

]]--

-- Script Globals --
local oldPrint = print
local oldWarn  = warn
local oldError = error
local oldDebug = debug

local print = function(...)
    local Stack = debug.info(2, "s")
    for _, Message in pairs({...}) do 
        oldPrint("[Aspirium : " .. tostring(Stack) .. " : INFO]: " .. tostring(Message)) 
    end 
end

local warn  = function(...)
    local Stack = debug.info(2, "s")
    for _, Message in pairs({...}) do 
        oldWarn("[Aspirium : " .. tostring(Stack) .. " : WARN]: " .. tostring(Message)) 
    end 
end

local error = function(...)
    local Stack = debug.info(2, "s")
    for _, Message in pairs({...}) do 
        oldWarn("[Aspirium : " .. tostring(Stack) .. " : ERROR]: " .. tostring(Message)) 
    end 
end

local debug = {
    enabled = false,
    output = function(...)
        local Stack = debug.info(2, "s")
        for _, Message in pairs({...}) do 
            if debug.enabled then
                oldWarn("[Aspirium : " .. tostring(Stack) .. " : DEBUG]: " .. tostring(Message))  
            end
        end 
    end
}

	for Index, Value in pairs(oldDebug) do
		debug[Index] = Value
	end

-- Variables --
local Folder = script.Parent
local MainModule = Folder.Parent
local Client = MainModule.Client
local Shared = MainModule.Shared
local Server = {}
local Service = {}
local ServiceSpecific = {}

-- Server-Specific Functions and Tables --
local PCall = function(Function, Critical, ...)
    local Ran, Return = pcall(Function, ...)

    if Ran then
        return Ran, Return
    else
        if Critical then
            error("CRITICAL: " .. tostring(Return))

            if Server.HTTP then
                Server.HTTP.Sentry.Push()
            end
        else
            error(Return)

            if Server.HTTP then
                Server.HTTP.Sentry.Push()
            end
        end
    end
end

local CPCall = function(Function, Critical, ...)
    return coroutine.wrap(PCall)(Function, Critical, ...)
end

local Environment = {
    Server = Server,
    Service = Service,
    Shared = Shared,

    print = print,
    warn  = warn,
    error = error,
    debug = debug,

    oldPrint = oldPrint,
    oldWarn  = oldWarn,
    oldError = oldError,
    oldDebug = oldDebug,

    PCall = PCall,
    CPCall = CPCall
}

-- Service Initialization --
local Service = require(Shared.Service)(Environment, function(Type, Traceback, Error)
    if Server.Logs then
        Server.Logs.AddLog("Script", {
            Type = Type,
            Stack = debug.info(2, "s"),
            Traceback = Traceback,
            Error = Error
        })
    end
end, ServiceSpecific); Environment.Service = Service

return Service.NewProxy({
    __metatable = "Aspirium",
    __tostring = function()
        return "Aspirium"
    end,
    __call = function(_, Data)
        --// no idea why it's called "mutex", but eh, going with it
        if _G.Aspirium_Mutex then
            warn("\n-----------------------------------------------"
                .."\nAspirium server is already running! Aborting..."
                .."\n-----------------------------------------------")
            
            return false, "SYSTEM_RUNNING"
        else
            _G.Aspirium_Mutex = true
        end

        if not Data then
            warn("Aspirium was ran without loader data present. Starting with default settings...")
        end

        Data = Service.Wrap(Data or {})

        --// Server Variables
        local DefaultSettings = require(Server.Dependencies.DefaultSettings)
        Server.DefaultSettings = DefaultSettings
        
        Server.Settings = Data.Settings or DefaultSettings.Settings or {}
        Server.Descriptions = Data.Descriptions or DefaultSettings.Descriptions or {}
        Server.Order = Data.Order or DefaultSettings.Order or {}

        Server.LoaderData = Data or {}

        debug.enabled = Server.Settings.Debug

        --// Clone shared resources to the server and client dependencies folder
        debug.output("Clone Shared Resources")

        for _, Resource in pairs(Shared:GetChildren()) do
            local Clone = Resource:Clone()
            Resource.Parent = Server.Dependencies
            Clone.Parent = Client.Dependencies
        end
    end
})