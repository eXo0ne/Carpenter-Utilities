--[[
    File: CmdrStarter.lua
    Author(s): Codesense
    Created: 07/05/2023 @ 11:44:05
    Version: 1.0.0

    Description:
       Starts up cmdr

    Dependencies:
        CmdrClient
--]]

--[ Roblox Services ]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[ Root ]--

local CmdrStarter = {}

--[ Exports & Types & Defaults ]--

--[ Classes & Jobs ]--

--[ Dependencies ]--

local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient")) ---@module CmdrClient

--[ Object References ]--

--[ Constants ]--

--[ Variables ]--

--[ Shorthands ]--

--[ Local Functions ]--

--[ Public Functions ]--

--[ Initializers ]--

-- setup the cmdr client
function CmdrStarter:Run()
	-- setup cmdr
	CmdrClient:SetActivationKeys({Enum.KeyCode.F2})
end

--[ Return Job ]--
return CmdrStarter
