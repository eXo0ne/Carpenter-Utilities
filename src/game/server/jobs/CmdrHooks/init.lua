--[[
    Author: Codesense, ChiefWildin
    Module: CmdrHooks.lua
    Version: 1.1.0
--]]

-- Services

-- Dependencies

local Cmdr = shared("Cmdr") ---@module Cmdr

-- Types

-- Module Declaration

local CmdrHooks = {}

-- Constants

-- Global Variables

-- Objects

-- Private Functions

-- Public Functions

-- Job Initialization

function CmdrHooks:Run()
	Cmdr:RegisterDefaultCommands()
	Cmdr:RegisterHooksIn(script)
end

return CmdrHooks
