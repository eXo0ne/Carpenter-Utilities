--[[ File Info

	Author: ChiefWildin
	Module: Get.lua
	Created: 12/05/2022
	Version: 1.0.0

	A utility function that provides a safe and simple way to get one or more
	instances from the DataModel.

--]]

--[[
	Takes an `Instance` value followed by any number of strings that represent
	child `Instance` names and returns the final child. If the last argument is a
	table, it will return a tuple of the children specified by that table.

	Examples:
	```lua
	--- Single instance
	local keystone = Get(workspace, "Arch", "Keystone")
	--- Multiple children
	local keystone, door = Get(workspace, "Arch", { "Keystone", "Door" })
	```
]]
---@param initialObject Instance The instance to start navigating from.
return function(initialObject: Instance, ...): ...Instance
	local object = initialObject
	local args: { string | { string } } = { ... }

	if typeof(args[#args]) == "table" then
		local namesToFind: { string } = table.remove(args, #args)
		local foundObjects: { Instance } = table.create(#namesToFind)

		-- Traverse to the target object
		for _, childName in ipairs(args) do
			object = object:WaitForChild(childName)
		end

		-- Wait for specified children
		for _, childName in ipairs(namesToFind) do
			table.insert(foundObjects, object:WaitForChild(childName))
		end

		return table.unpack(foundObjects)
	else
		-- Traverse to the target object
		for _, childName in ipairs(args) do
			object = object:WaitForChild(childName)
		end

		return object
	end
end
