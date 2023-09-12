--[[
	Author(s): Codesense, ChiefWildin
	Module: Permissions.lua
	Version: 1.1.0

	Determines who is allowed to run commands with cmdr.
--]]

-- Module Declaration

local Permissions = {}

-- Constants

-- Developer and up
local DEVELOPER_RANK: number = 253
-- Sawhorse group
local GROUP_ID: number = 12722816

-- Public Functions

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
        local hasPermission: number = context.Executor:GetRankInGroup(GROUP_ID) >= DEVELOPER_RANK
        
		if not hasPermission then
			return "You don't have permission to run this command"
		end
	end)
end
