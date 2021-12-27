--[[

    imskyyc
    Aspirium Service Library (Based on the Service module by Sceleratis / Davey_Bones)
    12/22/2021 @ 10:21 PM PST

--]]

return function(Environment, ErrorHandler, FenceSpecific)
    -- Script Globals --
    local print = Environment.print
    local warn  = Environment.warn
    local error = Environment.error
    local debug = Environment.debug

    -- Variables --
    local Main = Environment.Server or Environment.Client
    local Server = Environment.Server
    local Client = Environment.Client

    -- Method Caching --
    local RealMethods = {}
    local Methods = setmetatable({}, {
        __index = function(Self, Index)
            return function(Object, ...)
                local Ran, ClassName = pcall(function() return Object.ClassName end)

                if Ran and ClassName and Object[Index] and type(Object[Index]) == "function" then
                    if not RealMethods[ClassName] then
                        RealMethods[ClassName] = {}
                    end

                    if not RealMethods[ClassName][Index] then
                        RealMethods[ClassName][Index] = Object[Index]
                    end

                    if RealMethods[ClassName][Index] ~= Object[Index] or pcall(function() return coroutine.create(Object[Index]) end) then
                        ErrorHandler("MethodError", debug.traceback(), "Cached method does not match found method: " .. tostring(Index),
                            "Method: " .. tostring(Index), Index)
                    end

                    return RealMethods[ClassName][Index](Object, ...)
                end

                return Object[Index](Object, ...)
            end
        end,

        __metatable = "Methods"
    })

    -- Tables --
    local Service = {}
    local WaitingEvents = {}
	local HookedEvents = {}
	local Debounces = {}
	local Queues = {}
	local RbxEvents = {}
	local LoopQueue = {}
	local TrackedTasks = {}
	local RunningLoops = {}
	local TaskSchedulers = {}
	local ServiceVariables = {}

    local CreatedItems = setmetatable({}, {__mode = "v"})
	local Wrappers = setmetatable({}, {__mode = "kv"})

    local EventService = Instance.new("Folder")
    local ThreadService = Instance.new("Folder")
    local WrapService = Instance.new("Folder")
    local HelperService = Instance.new("Folder")

    local oldInstanceNew = Instance.new

    -- Functions --
    local Instance = {
        new = function(Object, Parent)
            local Object = oldInstanceNew(Object)

            if Parent then
                Object.Parent = Service.UnWrap(Parent)
            end

            return Service and Client and Service.Wrap(Object, true) or Object
        end
    }

    --// Credit to Ice Scripter for the random function
    local RandomSeed = 0
    local Random = function(Min, Max)
        RandomSeed = RandomSeed + math.floor(math.random(0, 9999999999))

        if Min ~= nil and Max ~= nil then
            return math.floor(Min +(math.random(math.randomseed(os.time()+Max))*999999 %Max))
        else
            return math.floor((math.random(math.randomseed(os.time() + RandomSeed)) * 100))
        end
    end

    local Routine = function(Function, ...)
        return coroutine.wrap(Function)(...)
    end

    local Events, Threads, Wrapper, Helpers = {
        TrackTask = function(Name, Function, ...)
            local Index = (Main and Main.Functions and Main.Functions.RandomString()) or Random()
            local IsThread = string.sub(Name, 1, 7) == "Thread: "

            local Task = {
                Name = Name,
                Status = "Waiting",
                Function = Function,
                IsThread = IsThread,
                Created = os.time(),
                Index = Index
            }

            local TaskFunction = function(...)
                TrackedTasks[Index] = Task
                Task.Status = "Running"
                Task.Returns = {pcall(Function, ...)}

                if not Task.Returns[1] then
                    Task.Status = "Errored"
                else
                    Task.Status = "Finished"
                end

                TrackedTasks[Index] = nil
                return unpack(Task.Returns)
            end

            if IsThread then
                Task.Thread = coroutine.wrap(TaskFunction)
                return Task.Thread(...)
            else
                return TaskFunction(...)
            end
        end,

        EventTask = function(Name, Function)
            local NewTask = Service.TrackTask
            local TaskFunction = function(...)
                return NewTask(Name, Function, ...)
            end

            return TaskFunction
        end,

        GetTasks = function()
            return TrackedTasks
        end,

        TaskScheduler = function(TaskName, Properties)
            local Properties = Properties or {}
            if not Properties.Temporary and TaskSchedulers[TaskName] then return TaskSchedulers[TaskName] end

            local Task = {
                Name = TaskName,
                Running = true,
                Properties = Properties,
                LinkedTasks = {},
                RunnerEvent = Service.New("BindableEvent")
            }

            function Task:Trigger(...)
                self.Event:Fire(...)
            end

            function Task:Delete()
                if not Properties.Temporary then
                    TaskSchedulers[TaskName] = nil
                end

                Task.Running = false
                Task.Event:Disconnect()
            end

            Task.Event = Task.RunnerEvent.Event:Connect(function(...)
                for Index, Task in pairs(Task.LinkedTasks) do
                    local _, Result = pcall(Task)

                    if Result then
                        table.remove(Task.LinkedTasks, Index)
                    end
                end
            end)

            if Properties.Interval then
                while task.wait(Properties.Interval) and Task.Running do
                    Task:Trigger(os.time())
                end
            end

            if not Properties.Temporary then
                TaskSchedulers[TaskName] = Task
            end

            return Task
        end,

        Events = setmetatable({}, {
            __index = function(_, Index)
                return Service.GetEvent(Index)
            end
        }),

        WrapEventArguments = function(Table)
            local Wrap = Service.Wrap

            for Index, Value in pairs(Table) do
                if type(Value) == "table" and Value.__ISWRAPPED and Value.__OBJECT then
                    Table[Index] = Wrap(Value.__OBJECT)
                end
            end

            return Table
        end,

        UnWrapEventArguments = function(Arguments)
            local UnWrap = Service.UnWrap
            local Wrapped = Service.Wrapped

            for Index, Argument in pairs(Arguments) do
                if Wrapped(Argument) then
                    Argument[Index] = {
                        __ISWRAPPED = true,
                        __OBJECT = UnWrap(Argument)
                    }
                end
            end

            return Arguments
        end,

        GetEvent = function(Name)
            if not HookedEvents[Name] then
                local Wrap = Service.Wrap
                local UnWrap = Service.UnWrap
                local WrapArguments = Service.WrapEventArguments
                local UnWrapArguments = Service.UnWrapEventArguments
                local Event = Wrap(Service.New("BindableEvent"), Client)
                local Hooks = {}

                Event.Event:Connect(function(...)
                    for _, Hook in pairs(Hooks) do
                        return Hook.Function(...)
                    end
                end)

                Event:SetSpecial("Wait", function(_, Timeout)
                    local Special = math.random()
                    local Done = false
                    local Return

                    if Timeout and type(Timeout) == "number" and Timeout > 0 then
                        Routine(function()
                            task.wait(Timeout)
                            if not Done then
                                UnWrap(Event):Fire(Special)
                            end
                        end)
                    end

                    repeat
                        Return = {UnWrap(Event.Event):Wait()}
                    until Return[1] == 2 or Return[1] == Special

                    Done = true

                    if Return[1] == Special then
                        warn("Event Waiter timed out [" .. tostring(Timeout) .. "]")
                        return nil
                    else
                        return unpack(WrapArguments(Return), 2)
                    end
                end)

                Event:SetSpecial("Fire", function(_, ...)
                    local PackedResult = table.pack(...)
                    UnWrap(Event):Fire(2, unpack(UnWrapArguments(PackedResult), 1, PackedResult.n))
                end)

                Event:SetSpecial("ConnectOnce", function(_, Function)
                    local Connection; Connection = Event:Connect(function(...)
                        Connection:Disconnect()
                        Function(...)
                    end)

                    return Connection
                end)

                Event:SetSpecial("Connect", function(_, Function)
                    local Special = math.random()
                    local Connection = Wrap(UnWrap(Event.Event):Connect(function(Connection, ...)
                        local PackedResult = table.pack(...)
                        if Connection == 2 or Connection == Special then
                            Function(unpack(WrapArguments(PackedResult), 1, PackedResult.n))
                        end
                    end), Client)

                    Connection:SetSpecial("Fire", function(_, ...)
                        local PackedResult = table.pack(...)
                        UnWrap(Event):Fire(Special, unpack(UnWrapArguments(PackedResult), 1, PackedResult.n))
                    end)

                    Connection:SetSpecial("Wait", function(_, Timeout)
                        local Return
    
                        repeat
                            Return = {UnWrap(Event.Event):Wait(Timeout)}
                        until Return[1] == 2 or Return[1] == Special

                        return unpack(WrapArguments(Return), 2)
                    end)

                    return Connection
                end)

                Event:SetSpecial("Event", Service.Wrap(Event.Event, Client))
                Event.Event:SetSpecial("Wait", Event.Wait)
                Event.Event:SetSpecial("Connect", Event.Connect)

                HookedEvents[Name] = Event

                return Event
            else
                return HookedEvents[Name]
            end
        end,

        HookEvent = function(Name, Function)
            if type(Name) == "string" or type(Function) ~= "function" then
                warn("Invalid argument supplied; HookEvent(string, function)")
            else
                return Service.GetEvent(Name):Connect(Function)
            end
        end,

        FireEvent = function(Name, ...)
            local Event = HookedEvents[Name]
            return Event and Event:Fire(...)
        end,

        RemoveEvents = function(Name)
            local Event = HookedEvents[Name]

            if Event then
                HookedEvents[Name] = nil
                Event:Destroy()
            end
        end
    }, 
    {
        Tasks = {},
        Threads = {},

        CheckTasks = function()
            for _, Task in pairs(Service.Threads.Tasks) do
                if not Task.Thread or Task:Status() == "dead" then
                    Task:Remove()
                end
            end
        end,

        NewTask = function(Name, Function, Timeout)
            local PID = math.random() * os.time() / 1000
            local Index = PID .. ":" .. tostring(Function)
            local NewTask; NewTask = {
                PID = PID,
                Name = Name,
                Index = Index,
                Created = os.time(),
                Changed = {},
                Timeout = Timeout or 0,
                Running = false,
                Status = "Idle",
                Finished = {},
                Function = function(...)
                    NewTask.Status = "Running"
                    NewTask.Running = true
                    
                    local Return = {Function(...)}
                    NewTask.Status = "Finished"
                    NewTask.Running = false
                    NewTask.Remove()

                    return unpack(Return)
                end,

                Remove = function()
                    NewTask.Status = "Removed"
                    NewTask.Running = false

                    for Index, Task in pairs(Service.Threads.Tasks) do
                        if Task == NewTask then
                            table.remove(Service.Threads.Tasks, Index)
                        end
                    end

                    NewTask.Changed:Fire("Removed")
                    NewTask.Finished:Fire()
                    
                    Service.RemoveEvents(Index .. "_TASKCHANGED")
                    Service.RemoveEvents(Index .. "_TASKFINISHED")

                    NewTask.Thread = nil
                end,

                Thread = Service.Threads.Create(function(...)
                    return NewTask.Function(...)
                end),

                Resume = function(...)
                    NewTask.Status = "Resumed"
                    NewTask.Running = true

                    NewTask.Changed:Fire("Resumed")
                    local Returns = {Service.Threads.Resume(NewTask.Thread, ...)}
                    if not Returns[1] then
                        ErrorHandler("TaskError", Returns[2])
                        NewTask.Changed:Fire("Errored", Returns[2])
                        NewTask.Remove()
                    end

                    return unpack(Returns)
                end,

                GetStatus = function()
                    if NewTask.Timeout ~= 0 and ((os.time() - NewTask.Created) > NewTask.Timeout) then
                        NewTask:Stop()
                        return "timeout"
                    else
                        return Service.Threads.Status(NewTask.Thread)
                    end
                end,

                Pause = function()
                    NewTask.Status = "Paused"
                    NewTask.Running = false

                    Service.Threads.Pause(NewTask.Thread)
                    NewTask.Changed:Fire("Paused")
                end,

                Stop = function()
                    NewTask.Status = "Stopping"
                    
                    Service.Threads.Stop(NewTask.Thread)
                    NewTask.Changed:Fire("Stopped")

                    NewTask.Remove()
                end,

                Kill = function()
                    NewTask.Status = "Killing"

                    Service.Threads.End(NewTask.Thread)

                    NewTask.Changed:Fire("Killed")
                    NewTask.Remove()
                end
            }

            function NewTask.Changed:Connect(Function)
                return Service.Events[Index .. "_TASKCHANGED"]:Connect(Function)
            end

            function NewTask.Changed:Fire(...)
                Service.Events[Index .. "_TASKCHANGED"]:Fire(...)
            end

            function NewTask.Finished:Connect(Function)
                return Service.Events[Index .. "_TASKFINISHED"]:Connect(Function)
            end

            function NewTask.Finished:Wait()
                Service.Events[Index .. "_TASKFINISHED"]:Wait(0)
            end

            function NewTask.Finished:Fire(...)
                Service.Events[Index .. "_TASKFINISHED"]:Fire(...)
            end

            NewTask.End = NewTask.Stop

            table.insert(Service.Threads.Tasks, NewTask)

            Service.Threads.CheckTasks()

            return NewTask.Resume, NewTask
        end,

        RunTask = function(Name, Function, ...)
            local Function, Task = Service.Threads.NewTask(Name, Function)
            return Task, Function(...)
        end,

        TimeoutRunTask = function(Name, Function, Timeout, ...)
            local Function, Task =  Service.Threads.NewTask(Name, Function, Timeout)
            return Task, Function(...)
        end,

        WaitTask = function(Name, Function, ...)
            local Function, Task = Service.Threads.NewTask(Name,Function)
            local Returns = {Function(...)}
            Task.Finished:Wait()
            return Task, unpack(Returns)
        end,

        NewEventTask = function(Name, Function, Timeout)
            return function(...)
                if Service.Running then
                    return Service.Threads.NewEventTask(Name, Function, Timeout)(...)
                else
                    return function() end
                end
            end
        end,
        
        Stop = coroutine.yield,
		Wait = coroutine.yield,
		Pause = coroutine.yield,
		Yield = coroutine.yield,
		Status = coroutine.status,
		Running = coroutine.running,
		Create = coroutine.create,
		Start = coroutine.resume,
        Get = coroutine.running,

        New = function(Function)
            local New = coroutine.create(Function)
            table.insert(Service.Threads.Threads, New)

            return New
        end,

        End = function(Thread)
            repeat
                if Thread and Service.Threads.GetStatus(Thread) ~= "dead" then
                    Service.Threads.Stop(Thread)
                    Service.Threads.Resume(Thread)
                else
                    Thread = false
                    break
                end
            until not Thread or Service.Threads.GetStatus(Thread) == "dead"
        end,

        Wrap = function(Function, ...)
            local New = Service.Threads.New(Function)
            Service.Threads.Resume(Function, ...)

            return New 
        end,

        Resume = function(Thread, ...)
            if Thread and coroutine.status(Thread) == "suspended" then
                return coroutine.resume(Thread, ...)
            end
        end,

        Remove = function(Thread)
            Service.Threads.Stop(Thread)

            for Index, CachedThread in pairs(Service.Threads.Threads) do
                if CachedThread == Thread then
                    table.remove(Service.Threads.Threads, Index)
                end
            end
        end,

        StopAll = function()
            for Index, Thread in pairs(Service.Threads.Threads) do
                Service.Threads.Stop(Thread)

                table.remove(Service.Threads.Threads, Index)
            end
        end,

        ResumeAll = function() 
            for _, Thread in pairs(Service.Threads.Threads) do
                Service.Threads.Resume(Thread)
            end
        end,

        GetAll = function()
            return Service.Threads.Threads
        end
    }, 
    {
        WrapImage = function(Table)
            return setmetatable(Table, {
                __metatable = "Ignore"
            })
        end,

        CheckWrappers = function()
            for Object in pairs(Wrappers) do
                if Service.IsDestroyed(Object) then
                    Wrappers[Object] = nil
                end
            end
        end,

        Wrapped = function(Object)
            return getmetatable(Object) == "Aspirium_Proxy"
        end,

        UnWrap = function(Object)
            local ObjectType = typeof(Object)

            if ObjectType == "Instance" then
                return Object
            elseif ObjectType == "table" then
                local UnWrap = Service.UnWrap
                local Table = {}

                for Index, Value in pairs(Object) do
                    Table[Index] = UnWrap(Value)
                end

                return Table
            elseif Service.Wrapped(Object) then
                return Object:GetObject()
            else
                return Object
            end
        end,

        Wrap = function(Object, FullWrap)
            FullWrap = FullWrap or (FullWrap == nil and Client ~= nil)

            if getmetatable(Object) == "Ignore" or getmetatable(Object) == "ReadOnly_Table" then
                return Object
            elseif Wrappers[Object] then
                return Wrappers[Object]
            elseif type(Object) == "table" then
                local Wrap = Service.Wrap
                local Table = setmetatable({}, {
                    __eq = function()
                        return Object
                    end
                })

                for Index, Value in pairs(Object) do
                    Table[Index] = Wrap(Value, FullWrap)
                end

                return Table
            elseif (typeof(Object) == "Instance" or typeof(Object) == "RBXScriptSignal" or typeof(Object) == "RBXScriptConnection") and not Service.Wrapped(Object) then
                local UnWrap = Service.UnWrap
                local sWrap = Service.Wrap

                local Wrap = (not FullWrap and function(...)
                    return ...
                end) or function(Object)
                    return sWrap(Object, FullWrap)
                end

                local NewObject = newproxy(true)
                local NewMetatable = getmetatable(NewObject)

                local CustomObject; CustomObject = {
                    GetMetatable = function()
                        return NewMetatable
                    end,

                    AddToCache = function()
                        Wrappers[Object] = NewObject
                    end,

                    RemoveFromCache = function()
                        Wrappers[Object] = nil
                    end,

                    GetObject = function()
                        return Object
                    end,

                    SetSpecial = function(_, Name, Value)
                        CustomObject[Name] = Value
                        return CustomObject
                    end,

                    Clone = function(_, NoAdd)
                        local NewObject = Object:Clone()

                        if not NoAdd then
                            table.insert(CreatedItems, NewObject)
                        end
                    end,

                    Connect = function(_, Function)
                        return Wrap(Object:Connect(function(...)
                            local PackedResult = table.pack(...)
                            return Function(unpack(sWrap(PackedResult), 1, PackedResult.n))
                        end))
                    end,

                    Wait = function(_, ...)
                        return Wrap(Object.Wait)(Object, ...)
                    end
                }

                NewMetatable.__index = function(_, Index)
                    local Target = CustomObject[Index] or Object[Index]

                    if CustomObject[Index] then
                        return CustomObject[Index]
                    elseif type(Target) == "function" then
                        return function(_, ...)
                            local PackedResult = table.pack(...)
                            return unpack(Wrap({
                                Methods[Index](Object, unpack(UnWrap(PackedResult), 1, PackedResult.n))
                            }))
                        end
                    else
                        return Wrap(Target)
                    end
                end

                NewMetatable.__newindex = function(_, Index, Value)
                    Object[Index] = UnWrap(Value)
                end

                NewMetatable.__eq = Service.RawEqual
                NewMetatable.__tostring = function()
                    return CustomObject.ToString or tostring(Object)
                end
                NewMetatable.__metatable = "Aspirium_Proxy"

                CustomObject:AddToCache()

                return NewObject
            else
                return Object
            end
        end
    }, 
    {
        CloneTable = function(Table)
            local NewTable = (getmetatable(Table) ~= nil and setmetatable({}, {
                __index = function(_, Index)
                    return Table[Index]
                end
            })) or {}

            for Index, Value in pairs(Table) do
                NewTable[Index] = Value
            end

            return NewTable
        end,

        IsLocked = function(Object)
            return not pcall(function()
                Object.Name = Object.Name
                return Object.Name
            end)
        end,

        Timer = function(Time, Function, Check)
            local Start = time()
            local Event; Event = Service.RunService.RenderStepped:Connect(function()
                if Time() - Start > Time or (Check and Check()) then
                    Function()
                    Event:Disconnect()
                end
            end)
        end,

        UnPack = function(Table, Index, Limit)
            if (not Limit and Table[Index or 1] ~= nil) or (Limit and (Index or 1) <= Limit) then
                return Table[Index or 1], Service.UnPack(Table, (Index or 1) + 1, Limit)
            end
        end,

        AltUnPack = function(Arguments, Shift)
            if Shift then
                Shift = Shift - 1
            end
            
            return Arguments[1+(Shift or 0)],Arguments[2+(Shift or 0)],Arguments[3+(Shift or 0)],Arguments[4+(Shift or 0)],Arguments[5+(Shift or 0)],Arguments[6+(Shift or 0)],Arguments[7+(Shift or 0)],Arguments[8+(Shift or 0)],Arguments[9+(Shift or 0)],Arguments[10+(Shift or 0)]
        end,

        ExtractLines = function(String)
            local Strings = {}
            local NewString = ""

            for Index = 1, #String + 1 do
                if string.byte(string.sub(String, Index, Index)) == 10 or Index == #String + 1 then
                    table.insert(Strings, NewString)
                    NewString = ""
                else
                    local Character = string.sub(String, Index, Index)

                    if string.byte(Character) < 32 then
                        Character = ""
                    end

                    NewString = NewString .. Character
                end
            end

            return Strings
        end,

        Filter = function(String, From, To)
            if not utf8.len(String) then
                return "Filter Error"
            end

            local NewString = ""
            local Lines = Service.ExtractLines(String)

            for Index = 1, #Lines do
                local Ran, NewLine = pcall(function()
                    return Service.TextService:FilterStringAsync(Lines[Index], From.UserId):GetChatForUserAsync(To.UserId)
                end)

                NewLine = (Ran and NewLine) or Lines[Index] or ""

                if Index > 1 then
                    NewString = NewString .. "\n" .. NewLine
                else
                    NewString = NewLine
                end
            end

            return NewString or "Filter Error"
        end,

        LaxFilter = function(String, From, Command)
            if tonumber(String) then
                return String
            elseif type(String) == "string" then
                if not utf8.len(String) then
                    return "Filter Error"
                end

                if Command and #Service.GetPlayers(From, String, {
                    NoError = true,
                }) > 0 then
                    return String
                else
                    return Service.Filter(String, From, From)
                end
            else
                return String
            end
        end,

        BroadcastFilter = function(String, From)
            if not utf8.len(String) then
                return "Filter Error"
            end

            local NewString = ""
            local Lines = Service.ExtractLines(String)
            for Index = 1, #Lines do
                local Ran, NewLine = pcall(function()
                    return Service.TextService:FilterStringAsync(Lines[Index],From.UserId):GetNonChatStringForBroadcastAsync()
                end)

                NewLine = (Ran and NewLine) or Lines[Index] or ""

                if Index > 1 then
                    NewString = NewString.."\n"..NewLine
                else
                    NewString = NewLine
                end
            end

            return NewString or "Filter Error"
        end,

        EscapeSpecialCharacters = function(String)
            return String:gsub("([^%w])", "%%%1")
        end,

        MetaFunction = function(Function)
            return Service.NewProxy({
                __call = function(_, ...)
                    local Arguments = {pcall(Function, ...)}
                    local Success = Arguments[1]

                    if not Success then
                        warn(Arguments[2])
                    else
                        return unpack(Arguments, 2)
                    end
                end
            })
        end,

        NewProxy = function(Meta)
            local NewProxy = newproxy(true)
            local Metatable = getmetatable(NewProxy)
            Metatable.__metatable = false
            for Index, Value in pairs(Meta) do
                Metatable[Index] = Value
            end

            return NewProxy
        end,

        GetUserType = function(Object)
            local Ran, Error = pcall(function()
                local Temp = Object[math.random()]
            end)

            if Ran then
                return "Unknown"
            else
                return Error:match("%S+%")
            end
        end,

        New = function(Class, Data, NoWrap, NoAdd)
            local NewObject = NoWrap and oldInstanceNew(Class) or Instance.new(Class)
            if Data then
                if type(Data) == "table" then
                    local Parent = Data.Parent
                    if Service.Wrapped(Parent) then
                        Parent = Parent:GetObject()
                    end

                    Data.Parent = nil

                    for Property, Value in pairs(Data) do
                        NewObject[Property] = Value
                    end

                    if Parent then
                        NewObject.Parent = Parent
                    end
                elseif type(Data) == "userdata" then
                    if Service.Wrapped(Data) then
                        NewObject.Parent = Data:GetObject()
                    else
                        NewObject.Parent = Data
                    end
                end
            end

            if NewObject and not NoAdd then
                table.insert(CreatedItems, NewObject)
            end

            return NewObject
        end,

        ForEach = function(Table, Function)
            for Index, Value in pairs(Table) do
                Function(Table, Index, Value)
            end
        end,

        Iterate = function(Table, Function)
            if Table and type(Table) == "table" then
                for Index, Value in pairs(Table) do
                    local Return = Function(Index, Value)

                    if Return ~= nil then
                        return Return
                    end
                end
            elseif Table and type(Table) == "userdata" then
                for Index, Value in ipairs(Table:GetChildren()) do
                    local Return = Function(Value, Index)

                    if Return ~= nil then
                        return Return
                    end
                end
            else
                error("Invalid table")
            end
        end,

        GetTime = function()
            return os.time()
        end,

        FormatTime = function(OptTime, WithDate)
            local FormatString = WithDate and "L LT" or "LT"
            local Time = DateTime.fromUnixTimestamp(OptTime or Service.GetTime())

            if Service.RunService:IsServer() then
                Time:FormatUniversalTime(FormatString, "en-gb")
            else
                local Locale = Service.Players.LocalPlayer.LocaleId

                local _, Error = pcall(function()
                    return Time:FormatLocalTime(FormatString, Locale)
                end)

                if Error then
                    return Time:FormatLocalTime(FormatString, "en-gb")
                end
            end
        end,

        OwnsAsset = function(Player, AssetId)
            return Service.MarketplaceService:PlayerOwnsAsset(Player, AssetId)
        end,

        MaxLength = function(Message, Length)
            if #Message > Length then
                return string.sub(Message, 1, Length) .. "..."
            else
                return Message
            end
        end,

        Yield = function()
            local Event = Service.New("BindableEvent")
            return {
                Release = function(...) Event:Fire(...) end,
                Wait = function(...) return Event.Event:Wait(...) end,
                Destroy = function() Event:Destroy() end,
                Event = Event
            }
        end,

        StartLoop = function(Name, Delay, Function, NoYield)
            local Index = tostring(Name) .. " - " .. (Main.Functions and Main.Functions.RandomString()) or Random()
            local Loop; Loop = {
                Name = Name,
                Index = Index,
                Delay = Delay,
                Function = Function,
                Running = true,

                Kill = function()
                    Loop.Running = true
                    if RunningLoops[Index] then
                        RunningLoops[Index] = nil
                    end
                end
            }

            local Loop = function()
                if tonumber(Delay) then
                    repeat
                        Function()
                        task.wait(tonumber(Delay))
                    until RunningLoops[Index] ~= Loop or not Loop.Running

                    Loop.Kill()
                elseif Delay == "Heartbeat" then
                    repeat
                        Function()
                        Service.RunService.Heartbeat:Wait()
                    until RunningLoops[Index] ~= Loop or not Loop.Running

                    Loop.Kill()
                elseif Delay == "RenderStepped" then
                    repeat
                        Function()
                        Service.RunService.RenderStepped:Wait()
                    until RunningLoops[Index] ~= Loop or not Loop.Running

                    Loop.Kill()
                elseif Delay == "Stepped" then
                    repeat
                        Function()
                        Service.RunService.Stepped:Wait()
                    until RunningLoops[Index] ~= Loop or not Loop.Running

                    Loop.Kill()
                else
                    Loop.Running = false
                end
            end

            RunningLoops[Index] = Loop

            if NoYield then
                Service.TrackTask("Thread: Loop: " .. Name, Loop)
            else
                Service.TrackTask("Loop: " .. Name, Loop)
            end

            return Loop
        end,

        StopLoop = function(Name)
            for _, Loop in pairs(RunningLoops) do
                if Name == Loop.Function or Name == Loop.Name or Name == Loop.Index then
                    Loop.Running = false
                end
            end
        end,

        Immutable = function(...)
            local Thread = coroutine.wrap(function(...)
                while true do
                    coroutine.yield(...)
                end
            end)

            Thread(...)

            return Thread
        end,

        ReadOnly = function(Table, Excluded, KillOnError, NoChecks)
            local DoChecks = (not NoChecks) and Service.RunService:IsClient()
            local Player = DoChecks and Service.Players.LocalPlayer
            local Settings, GetMetatable, GetEnv, PCall = getfenv().settings, getmetatable, getfenv, pcall
            local Unique = DoChecks and getmetatable(getfenv())

            return Service.NewProxy({
                __index = function(_, Index)
                    local TopEnv = DoChecks and getfenv() and getfenv(2)
                    local SetRan = DoChecks and pcall(settings)
                    if DoChecks and (SetRan or (GetEnv ~= getfenv or GetMetatable ~= getmetatable or PCall ~= pcall) or (not TopEnv or type(TopEnv) ~= "table" or GetMetatable(TopEnv) ~= Unique)) then
                        ErrorHandler("ReadError", "Tampering with Client [read rt0001]", "["..tostring(Index).. " " .. tostring(TopEnv) .. " " .. tostring(TopEnv and GetMetatable(TopEnv)).."]\n".. tostring(debug.traceback()))
                    elseif Table[Index] ~= nil and type(Table[Index]) == "table" and not(Excluded and (Excluded[Index] or Excluded[Table[Index]])) then
                        return Service.ReadOnly(Table[Index], Excluded, KillOnError, NoChecks)
                    else
                        return Table[Index]
                    end
                end,

                __newindex = function(_, Index, Value)
                    local TopEnv = DoChecks and getfenv() and getfenv(2)
                    local SetRan = DoChecks and pcall(settings)
                    if DoChecks and (SetRan or (GetEnv ~= getfenv or GetMetatable ~= getmetatable or PCall ~= pcall) or (not TopEnv or type(TopEnv) ~= "table" or GetMetatable(TopEnv) ~= Unique)) then
                        ErrorHandler("ReadError", "Tampering with Client [write wt0003]", "["..tostring(Index).. " " .. tostring(TopEnv) .. " " .. tostring(TopEnv and GetMetatable(TopEnv)).."]\n".. tostring(debug.traceback()))
                    elseif not(Excluded and (Excluded[Index] or Excluded[Table[Index]])) then
                        if KillOnError then
                            ErrorHandler("ReadError", "Tampering with Client [write wt0005]", "["..tostring(Index).. " " .. tostring(TopEnv) .. " " .. tostring(TopEnv and GetMetatable(TopEnv)).."]\n".. tostring(debug.traceback()))
                        end

                        warn("Something attempted to set index " .. tostring(Index) .. " in a read-only table.")
                    else
                        rawset(Table, Index, Value)
                    end
                end,

                __metatable = "ReadOnly_Table"
            })
        end,

        Wait = function(Mode)
            if not Mode or Mode == "Stepped" then
				Service.RunService.Stepped:wait()
			elseif Mode == "Heartbeat" then
				Service.RunService.Heartbeat:wait()
			elseif Mode and tonumber(Mode) then
				task.wait(tonumber(Mode))
			end
        end,

        OrigRawEqual = rawequal,

        HasItem = function(Object, Property)
            return pcall(function()
                return Object[Property]
            end)
        end,

        IsDestroyed = function(Object)
            if type(Object) == "userdata" and Service.HasItem(Object, "Parent") then
                if Object.Parent == nil then
                    local Ran, Error = pcall(function()
                        Object.Parent = game
                        Object.Parent = nil
                    end)

                    if not Ran then
                        if Error and string.match(Error, "^The Parent property of (.*) is locked, current parent: NULL,") then
							return true
						else
							return false
						end
                    end
                end
            end

            return false
        end,

        Insert = function(Id, RawModel)
            local Model = Service.InsertService:LoadAsset(Id)
            if not RawModel and Model:IsA("Model") and Model.Name == "Model" then
                local Asset = Model:GetChildren()[1]
                Asset.Parent = Model.Parent
                Model:Destroy()

                return Asset
            end

            return Model
        end,

        GetPlayers = function()

        end,

        IsAspiriumObject = function(Object)
            for _, Item in pairs(CreatedItems) do
                if Item == Object then
                    return true
                end
            end
        end,

        GetAspiriumObjects = function()
            return CreatedItems
        end
    }

    Service = setmetatable({
        Variables = function() return ServiceVariables end,
        Routine = Routine,
        Running = true,
        PCall = Environment.PCall,
        CPCall = Environment.CPCall,
        Threads = Threads,
        DataModel = game,
        EventService = EventService,
        ThreadService = ThreadService,
        WrapService = WrapService,
        HelperService = HelperService,
        Delete = function(Object, Time)
            Service.Debris:AddItem(Object, (Time or 0))
            pcall(Object.Destroy, Object)
        end,

        RbxEvent = function(Signal, Function)
            local Event = Signal:Connect(Function)

            table.insert(RbxEvents, Event)

            return Event
        end,

        SanitizeString = function(String) 
            String = Service.Trim(String) 
            local NewString = "" 
            for Index = 1,#String do 
                if string.sub(String, Index, Index) ~= "\n" and string.sub(String, Index, Index) ~= "\0" then
                    NewString = NewString .. string.sub(String, Index, Index) 
                end
            end 
            return NewString 
        end,

		Trim = function(String) 
            return string.match(String, "^%s*(.-)%s*$") 
        end,

		Round = function(Number) 
            return math.floor(Number + 0.5) 
        end,

		Localize = function(Object, ReadOnly) 
            local Localize = Service.Localize 
            local ReadOnly = Service.ReadOnly 
            if type(Object) == "table" then 
                local newTab = {} 
                for Index in pairs(Object) do 
                    newTab[Index] = Localize(Object[Index], ReadOnly) 
                end 
                return (ReadOnly and ReadOnly(newTab)) or newTab 
            else 
                return Object 
            end 
        end,

		RawEqual = function(Object1, Object2) 
            return Service.UnWrap(Object1) == Service.UnWrap(Object2) 
        end
    }, {
        __index = function(_, Index)
            local Found = (FenceSpecific and FenceSpecific[Index]) or Wrapper[Index] or Events[Index] or Helpers[Index]

            if Found then
                return Found
            else
                local Ran, Service = pcall(function()
                    local Service = game:GetService(Index)
                    return (Client ~= nil and Service.Wrap(Service, true)) or Service
                end)

                if Ran and Service then
                    Service[Index] = Service
                    return Service
                end
            end
        end,

        __tostring = function()
            return "Service"
        end,

        __metatable = "Service"
    })

    EventService = Wrapper.Wrap(EventService)
    ThreadService = Wrapper.Wrap(ThreadService)
    WrapService = Wrapper.Wrap(WrapService)
    HelperService = Wrapper.Wrap(HelperService)

    Service.EventService = EventService
    Service.ThreadService = ThreadService
    Service.WrapService = WrapService
    Service.HelperService = HelperService

    if Client ~= nil then
        for Index, Value in pairs(Service) do
            if type(Value) == "userdata" then
                Service[Index] = Service.Wrap(Value, true)
            end
        end
    end

    for Index, Value in pairs(Events) do
        if type(Value) == "function" then
            EventService:SetSpecial(Index, function(_, ...)
                return Value(...)
            end)
        else
            EventService:SetSpecial(Index, Value)
        end
    end

    for Index, Value in pairs(Threads) do
        if type(Value) == "function" then
            ThreadService:SetSpecial(Index, function(_, ...)
                return Value(...)
            end)
        else
            ThreadService:SetSpecial(Index, Value)
        end
    end

    for Index, Value in pairs(Wrapper) do
        if type(Value) == "function" then
            WrapService:SetSpecial(Index, function(_, ...)
                return Value(...)
            end)
        else
            WrapService:SetSpecial(Index, Value)
        end
    end

    for Index, Value in pairs(Helpers) do
        if type(Value) == "function" then
            HelperService:SetSpecial(Index, function(_, ...)
                return Value(...)
            end)
        else
            HelperService:SetSpecial(Index, Value)
        end
    end

    for Name, Service in pairs({EventService = EventService, ThreadService = ThreadService, WrapService = WrapService, HelperService = HelperService}) do
        Service:SetSpecial("ClassName", Name)
        Service:SetSpecial("ToString", Name)
        Service:SetSpecial("IsA", function(_, Check)
            return Check == Name
        end)
    end

    return Service
end