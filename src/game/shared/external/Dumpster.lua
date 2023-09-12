--[[[
	Author(s): KinqAndi
	Version: 0.4.0
		Base update date: 3/21/23
		Sawhorse update date: 8/25/23
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SharedTypes = shared("SharedTypes") ---@module SharedTypes

export type Dumpster = SharedTypes.Dumpster

local Dumpster: Dumpster = {}
Dumpster.__index = Dumpster

--[[
    Returns: Dumpster
    Description: Constructor for Dumpster.
]]
function Dumpster.new(): Dumpster
	local self: Dumpster = setmetatable({
		_objects = {},
		_identifierObjects = {},
		_bindedNames = {},

		_functionCleanUp = newproxy(),
		_threadCleanUp = newproxy(),

        _dumpsterProxy = newproxy()
	}, Dumpster)

	return self
end

--[[
    Returns: any?
    Description: Takes any object as a paremeter and adds it to the dumpster for
    cleanup. Includes Promise support.
    Paremeters
        - object: any,
        - cleanUpIdentifier: string?
        - customCleanupMethod: string?
]]
function Dumpster:Add(object: any, cleanUpIdentifier: string?, customCleanupMethod: string?): any?
	-- Special handling for Promises
	if self:_isAPromise(object) then
		self:_initPromise(object)

		local cleanUpMethod = "cancel"

		if cleanUpIdentifier then
			if not self:_cleanUpIdentifierAvailable(cleanUpIdentifier) then
				return
			end

			self._identifierObjects[cleanUpIdentifier] = {object = object, method = cleanUpMethod}
			return
		end

		table.insert(self._objects, {object = object, method = cleanUpMethod})

		return
	end

	if self._isCleaning then
		self:_sendWarn("Cannot add item for cleanup when dumpster is being cleaned up/destroyed")
		return
	end

	local cleanUpMethod = self:_getCleanUpMethod(object, customCleanupMethod)

	if not cleanUpMethod then
		self:_sendWarn(object, "was not added for cleanup, could not find a cleanup method!")
		return
	end

	if cleanUpIdentifier then
		if not self:_cleanUpIdentifierAvailable(cleanUpIdentifier) then
			return
		end

		self._identifierObjects[cleanUpIdentifier] = {object = object, method = cleanUpMethod}

		return object
	end

	table.insert(self._objects, {object = object, method = cleanUpMethod})

	return object
end

--[[
    Returns: Dumpster
    Description: Creates a sub dumpster and then adds it to the parent Dumpster for cleanup.
]]
function Dumpster:Extend(): Dumpster
	local subDumpster = self.new()
    subDumpster._dumpsterProxy = self._dumpsterProxy

	self:Add(subDumpster)

	return subDumpster
end

--[[
    Returns: any?
    Description: Construct an Instance/Class/Function with tuple arguments
    Paremeters
        - object: string | table | function,
        - ... (optional arguments to be passed on to the constructed object.)
]]
function Dumpster:Construct(base: string | table | () -> (), ...)
	local baseType = typeof(base)

	if baseType == "string" then
		local instance = Instance.new(base)
		self:Add(instance, ...)

		return instance
	elseif baseType == "table" then
		local object = base.new(...)
		self:Add(object)

		return object
	elseif baseType == "function" then
        local item = base(...)
		self:Add(item)

		return item
	else
		self:_sendWarn(`Object could not be constructed - invalid type {baseType}`)
	end
end

--[[
    Returns: Instance
    Description: Creates a clone of an instance and adds it to the dumpster.
    Paremeters
        - item: Instance,
]]
function Dumpster:Clone(item: Instance)
	if typeof(item) ~= "Instance" then
		self:_sendWarn("Only instances can be cloned")
		return
	end

	item = item:Clone()
	self:Add(item)

	return item
end

--[[
    Returns: ()
    Description: Connects a callback to render stepped. Will automatically Unbind once Dumpster is destroyed.
    Paremeters
        - name: string,
        - priority: string,
        - func: (deltaTime: number)->(),
]]
function Dumpster:BindToRenderStep(name: string, priority: number, callback: (deltaTime: number) -> (any)): ()
	assert(name ~= nil and typeof(name) == "string", "Name must be a string!")
	assert(priority ~= nil and typeof(priority) == "number", "Priority must be a number!")
	assert(callback ~= nil and typeof(callback) == "function", "Must have a callback function!")

	if self._isCleaning then
		self:_sendWarn("Cannot bind function to render step when dumpster is being cleaned up/destroyed")
		return
	end

	if table.find(self._bindedNames, name) then
		self:_sendWarn("The name you're trying to bind the function to render stepped to already exists, please use a unique name!")
		return
	end

	RunService:BindToRenderStep(name, priority, callback)

	table.insert(self._bindedNames, name)
end

--[[
    Returns: ()
    Description: This will unbind a function from renderstepped.
    Paremeters
        - name: string,
]]
function Dumpster:UnbindFromRenderStep(name: string)
	local foundAt: number? = table.find(self._bindedNames, name)

	if not foundAt then
		self:_sendWarn("No Bind to render step was found with name:", name)
		return
	end

	table.remove(self._bindedNames, foundAt)
	RunService:UnbindFromRenderStep(name)
end

--[[
    Returns: any?
    Description: Wraps a signal with a function and adds it to the dumpster.
    Paremeters
        - signal: RBXScriptSignal,
        - callback: (...any) -> ()
]]
function Dumpster:Connect(signal: RBXScriptSignal, callback: (...any) -> ())
	if typeof(signal) ~= "RBXScriptSignal" then
		self:_sendWarn("Attempted to Connect with object not being of type RBXScriptSignal")
		return
	end

	if typeof(callback) ~= "function" then
		self:_sendWarn("attempted to Connect, argument 2 expects function but got", typeof(callback))
		return
	end

	if self._isCleaning then
		self:_sendWarn("Cannot call method when dumpster is being cleaned up/destroyed")
		return
	end

	return self:Add(signal:Connect(callback))
end

--[[
    Returns: ()
    Description: This will attach the dumpster to provided object. Once that object is destroyed, dumpster will be too.
    Paremeters
        - item: any,
]]
function Dumpster:AttachTo(item: Instance)
	if not typeof(item) == "Instance" then
		self:_sendWarn(`Attempt to attach dumpster to non-Instance object {item} ({typeof(item)})`)
		return
	end

	if self._isCleaning then
		self:_sendWarn("Cannot call :AttachTo() while dumpster is cleaning")
		return
	end

	if item:IsA("TweenBase") then
		if item.TweenInfo.RepeatCount < 0 then
			self:Add(item.Destroying:Connect(function()
				self:Destroy()
			end))
		else
			self:Add(item.Completed:Connect(function()
				self:Destroy()
			end))
		end

		return
	elseif item:IsA("AnimationTrack") then
		if item.Looped then
			self:_sendWarn("Dumpster attached to looping AnimationTrack - cleaning on .Destroying instead of .Stopped")

			self:Add(item.Destroying:Connect(function()
				self:Destroy()
			end))
		else
			self:Add(item.Stopped:Connect(function()
				self:Destroy()
			end))
		end

		return
	elseif item:IsA("Player") then
		if not item:IsDescendantOf(game) then
			self:Destroy()
			return
		end

		self:Add(Players.PlayerRemoving:Connect(function(player: Player)
			if player == item then
				self:Destroy()
			end
		end))
	elseif item:IsA("Sound") then
		if not item:IsDescendantOf(game) then
			self:_sendError(`Cannot attach dumpster to Sound {item} - does not have a valid parent`)
			return
		end

		if item.Looped then
			self:_sendWarn(item, "is looped, therefore attaching to .Destroying event instead of .Ended event")

			self:Add(item.Destroying:Connect(function()
				self:Destroy()
			end))

			return
		end

		if item.TimeLength == 0 then
			warn(item, "TimeLength is 0, so attaching to .Destroying event instead of .Ended event")

			self:Add(item.Destroying:Connect(function()
				self:Destroy()
			end))

			return
		end

		self:Add(item.Ended:Connect(function()
			self:Destroy()
		end))
	else
		if not item:IsDescendantOf(game) then
			self:_sendError("Instance is not a child of the game hiearchy, cannot be attached!")
			return
		end

		self:Add(item.Destroying:Connect(function()
			self:Destroy()
		end))

		return
	end
end

--[[
    Returns: any?
    Description: Will remove an object/string reference from the Dumpster.
        - If removed object is a function, and you don't want that function to run,
          you can pass in the "skipCleaning" parameter as true.
    Paremeters
        - objectToRemove: any,
        - skipCleaning: boolean?
]]
function Dumpster:Remove(objectToRemove: any, skipCleaning: boolean?): any?
	if self._isCleaning then
		self:_sendWarn("Cannot remove item when dumpster is being cleaned up/destroyed")
		return
	end

	if typeof(objectToRemove) == "string" then
		if not self._identifierObjects[objectToRemove] then
			if table.find(self._bindedNames, objectToRemove) then
				self:UnbindFromRenderStep(objectToRemove)
				return
			end

			self:_sendWarn("Could find an object to clean with ID:", objectToRemove)
			return
		end

		local object = self._identifierObjects[objectToRemove].object
		local method = self._identifierObjects[objectToRemove].method

		if skipCleaning then
			self._identifierObjects[objectToRemove] = nil
			return object
		else
			self:_cleanObject(object, method, true)
		end

		return
	end

	return self:_removeObject(objectToRemove, skipCleaning)
end

--[[
    Returns: boolean - whether or not cleaning was successful
    Description: Cleans items in the dumpster.
]]
function Dumpster:Clean(): boolean
	if self._isCleaning then
		self:_sendWarn("Tried to Destroy dumpster when its currently being cleaned up!")
		return false
	end

	self:_destroy()

	table.clear(self._objects)
	table.clear(self._identifierObjects)
	table.clear(self._bindedNames)

	return true
end

--[[
    Returns: ()
    Description: Cleans items in the dumpster and prevents further use.
]]
function Dumpster:Destroy()
	if self:Clean() then
		self._functionCleanUp = nil
		self._threadCleanUp = nil
	end
end

--Private methods

function Dumpster:_getCleanUpMethod(object: any, customCleanupMethod: string?): string?
	local objectType = typeof(object)

	if (objectType ~= "thread" and objectType ~= "function") and customCleanupMethod then
		return customCleanupMethod
	end

	if objectType == "thread" then
		return self._threadCleanUp
	elseif objectType == "function" then -- clean up functions to run once Destroy | Clean is called
		return self._functionCleanUp
	elseif objectType == "Instance" then
		return "Destroy"
	elseif objectType == "table" then
		if typeof(object.Destroy) == "function" then
			return "Destroy"
		elseif typeof(object.Clean) == "function" then
			return "Clean"
		elseif typeof(object.Disconnect) == "function" then
			return "Disconnect"
		end

		return
	elseif objectType == "RBXScriptConnection" then
		return "Disconnect"
	end
end

function Dumpster:_cleanUpIdentifierAvailable(cleanupIdentifier: string): boolean
	if self._identifierObjects[cleanupIdentifier] then
		self:_sendError("A cleanup identifier with ID: " .. cleanupIdentifier .. " already exists")
		return false
	end

	return true
end

function Dumpster:_removeObject(objectToRemove: any, skipCleanMethod: boolean?)
	local infoTable: {[number | string]: {[string]: any}}
	local index: (number | string)?

	for i, item in ipairs(self._objects) do
		if item.object == objectToRemove then
			infoTable = self._objects
			index = i
			break
		end
	end

	if not infoTable then
		for key, item in pairs(self._identifierObjects) do
			if item.object == objectToRemove then
				infoTable = self._identifierObjects
				index = key
				break
			end
		end
	end

	if not infoTable then
		self:_sendWarn("Could not find object to remove!")
		return
	end

	local object = infoTable[index].object
	local method = infoTable[index].method

	if skipCleanMethod then
		local reference = object
		infoTable[index] = nil

		return reference
	end

	if self:_cleanObject(object, method, true) then
		infoTable[index] = nil
	end

	return
end

function Dumpster:_destroy()
	self._isCleaning = true

	local functionsToRunOnceCleaned = {}

	local function cleanObject(item, cleanUpMethod)
		if cleanUpMethod == self._functionCleanUp then
			table.insert(functionsToRunOnceCleaned, item)
			return
		end

		self:_cleanObject(item, cleanUpMethod)
	end

	for _, item in ipairs(self._objects) do
		cleanObject(item.object, item.method)
	end

	for _, item in pairs(self._identifierObjects) do
		cleanObject(item.object, item.method)
	end

	for _, bindName in ipairs(self._bindedNames) do
		RunService:UnbindFromRenderStep(bindName)
	end

	for _, func in ipairs(functionsToRunOnceCleaned) do
		task.spawn(func)
	end

	self._isCleaning = false
end

function Dumpster:_cleanObject(item, cleanUpMethod, callFunction: boolean?): boolean?
	if cleanUpMethod == self._threadCleanUp then
		if coroutine.status(item) ~= "dead" then
			coroutine.close(item)
		end
		return
	end

	if cleanUpMethod == self._functionCleanUp and callFunction then
		item()
		return
	end

	if not item then
		return
	end

	if self._isAPromise(item) then
		pcall(item[cleanUpMethod], item)
		return true
	end

	item[cleanUpMethod](item)

	return true
end

function Dumpster:_sendError(message: string): ()
	error(message .. "\n" .. debug.traceback())
end

function Dumpster:_sendWarn(...): ()
	warn(...)
	warn(debug.traceback())
end

function Dumpster:_isAPromise(object): boolean
	if typeof(object) == "table" and object.cancel and object.getStatus and object.finally and object.andThen then
		return type(object.cancel) == "function"
			and type(object.getStatus) == "function"
			and type(object.finally) == "function"
			and type(object.andThen) == "function"
	end

	return false
end

function Dumpster:_initPromise(promise)
	if promise:getStatus() == "Started" then
		promise:finally(function()
			if self._isCleaning then
				return
			end

			self:Remove(promise, true)
		end)
	end

	return true
end

return Dumpster
