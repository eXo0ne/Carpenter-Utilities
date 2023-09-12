--[[
	Author: ChiefWildin
	Module: SystemMessages.lua
	Created: 02/22/2023
--]]

-- Services

local TextChatService = game:GetService("TextChatService")

-- Dependencies

local Get = shared("Get") ---@module Get
local GetRemote = shared("GetRemote") ---@module GetRemote

-- Module Declaration

local SystemMessages = {}

-- Constants

-- Global Variables

-- Objects

-- Private Functions

-- Public Functions

-- Job Initialization

function SystemMessages:Run()
	local systemChannel: TextChannel = Get(TextChatService, "TextChannels", "RBXSystem")
	local systemRemote = GetRemote("SystemMessage")

	systemRemote:OnEvent(function(message)
		systemChannel:DisplaySystemMessage(message)
	end)
end

return SystemMessages
