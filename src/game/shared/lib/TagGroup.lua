--[[ File Info

	Author: ChiefWildin
	Module: TagGroup.lua
	Created: 02/22/2023
	Version: 1.3.0

	TagGroup is a module that allows you to easily manage a group of instances
	with a specific tag.

--]]

--[[ API
	.Instances: { [Instance]: true }
	    The set of all instances with the given tag. Can be iterated on with the
		following loop structure:
		```lua
			for instance in TagGroup.Instances do
				-- ...
			end
		```

	.new(tag: string): TagGroup
		Creates a new TagGroup object based on the given tag.

	:GiveSetup(callback: (instance: Instance) -> ())
		Assigns a callback function to be called on all instances in the group
	    as they are added to the group. Also applies retroactively to all
	    instances already in the group.

	:GiveCleanup(callback: (instance: Instance) -> ())
	    Assigns a callback function to be called on any instance removed from
	    the group.

	:RemoveSetup(callback: (instance: Instance) -> ())
	    Removes the given setup callback from the group.

	:RemoveCleanup(callback: (instance: Instance) -> ())
	    Removes the given cleanup callback from the group.

	:GetCount(): number
		Returns the number of instances in the group.

	:GetArray(): { Instance }
	    Returns an array of all instances in the group, as opposed to .Instances
	    which is a set.
--]]

-- Services

local CollectionService = game:GetService("CollectionService")

-- Types

export type TagGroup = {
	Instances: { [Instance]: true },
	GiveSetup: (self: TagGroup, callback: (instance: Instance) -> ()) -> (),
	GiveCleanup: (self: TagGroup, callback: (instance: Instance) -> ()) -> (),
	RemoveSetup: (self: TagGroup, callback: (instance: Instance) -> ()) -> (),
	RemoveCleanup: (self: TagGroup, callback: (instance: Instance) -> ()) -> (),
	GetCount: (self: TagGroup) -> number,
	GetArray: (self: TagGroup) -> { Instance },
	new: (tag: string) -> TagGroup,
}

-- Module Declaration

local TagGroup: TagGroup = {}
TagGroup.__index = TagGroup

-- Public Functions

-- Assigns a callback function to be called on all instances in the group
-- as they are added to the group. Also applies retroactively to all
-- instances already in the group.
function TagGroup:GiveSetup(callback: (instance: Instance) -> ())
	for instance in self.Instances do
		task.spawn(callback, instance)
	end
	self._setup[callback] = true
end

-- Removes the given setup callback from the group.
function TagGroup:RemoveSetup(callback: (instance: Instance) -> ())
	self._setup[callback] = nil
end

-- Assigns a callback function to be called on any instance removed from
-- the group.
function TagGroup:GiveCleanup(callback: (instance: Instance) -> ())
	self._cleanup[callback] = true
end

-- Removes the given cleanup callback from the group.
function TagGroup:RemoveCleanup(callback: (instance: Instance) -> ())
	self._cleanup[callback] = nil
end

-- Returns the number of instances in the group.
function TagGroup:GetCount(): number
	local count = 0
	for _ in self.Instances do
		count += 1
	end
	return count
end

-- Returns an array of all instances in the group, as opposed to .Instances
-- which is a set.
function TagGroup:GetArray(): { Instance }
	local array = {}
	for instance in self.Instances do
		table.insert(array, instance)
	end
	return array
end

-- Creates a new TagGroup object based on the given tag.
function TagGroup.new(tag: string): TagGroup
	local self = setmetatable({
		Instances = {},
		_setup = {},
		_cleanup = {},
	}, TagGroup)

	if typeof(tag) ~= "string" then
		warn("Attempt to create TagGroup with invalid tag:", tag, "\n" .. debug.traceback())
		return self
	end

	local function setupInstance(instance: Instance)
		self.Instances[instance] = true
		for callback in pairs(self._setup) do
			task.spawn(callback, instance)
		end
	end

	local function cleanupInstance(instance: Instance)
		self.Instances[instance] = nil
		for callback in pairs(self._cleanup) do
			task.spawn(callback, instance)
		end
	end

	CollectionService:GetInstanceAddedSignal(tag):Connect(setupInstance)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(cleanupInstance)

	for _, instance in pairs(CollectionService:GetTagged(tag)) do
		setupInstance(instance)
	end

	return self
end

-- Aliases

TagGroup.AssignSetup = TagGroup.GiveSetup
TagGroup.StreamedIn = TagGroup.GiveSetup
TagGroup.AssignCleanup = TagGroup.GiveCleanup
TagGroup.StreamedOut = TagGroup.GiveCleanup

return TagGroup :: TagGroup
