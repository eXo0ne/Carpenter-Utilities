--[[
	CharacterUtils.lua
	@TactBacon
	Created: 05/01/2023
	Version: 1.3.0

	Description:
		Provides utility functions for working with characters.  Adds callbacks
		for character spawning and provides a dumpster for cleaning up when the
		character is destroyed.

	    Any function with the keyword `Local` in it will only work on the client
		and should not be called from the server.

	Setup:
		No setup necessary.

	API:
		::GetCharacter(player: Player | string, shouldYield: boolean?): Model?
			Get the character of a player and optionally yield until it exists
			Example:
			```lua
				local character = CharacterUtils:GetCharacter(player, true)
			```

		::GetLocalCharacter(shouldYield: boolean?): Model?
			Get the character of the local player and optionally yield until it
			exists.
			Example:
			```lua
				local character = CharacterUtils:GetLocalCharacter(true)
			```

		::GetAllCharacters(): {Model}
			Get all characters in the game.
			Example:
			```lua
				local characters = CharacterUtils:GetAllCharacters()
			```

	    ::OnCharacterSpawned(player: Player, callback: (character: Model, characterDumpster: Dumpster) -> (), callbackName: string)
			Add a callback for when the player spawns that receives the character
			model and a dumpster which will clean up any connections or running functions
			when the player dies.

			This will run the callback immediately if the player is already spawned.
			Example:
			```lua
				CharacterUtils:OnCharacterSpawned(Players.OnlyTwentyCharacters, function(character: Model, characterDumpster: Dumpster)
					print("Character spawned!")

					characterDumpster:Add(function()
						print("Character died!")
					end)
				end, "MySpawnCallback")
			```

	    ::OnAnyCharacterSpawned(callback: (character: Model, characterDumpster: Dumpster) -> (), callbackName: string)
			Add a callback for any player, existing and future, that spawns.

			This will run the callback immediately for all existing players.
			Example:
			```lua
				CharacterUtils:OnAnyCharacterSpawned(function(character: Model, characterDumpster: Dumpster)
					print("Character spawned!")

					characterDumpster:Add(function()
						print("Character died!")
					end)
				end, "MySpawnCallback")
			```

	    ::OnLocalCharacterSpawned(callback: (character: Model, characterDumpster: Dumpster) -> (), callbackName: string)
			Add a callback for when the local player spawns that receives the
			character model and a dumpster which will clean up any connections or
			running functions when the player dies.

			This will run the callback immediately if the player is already spawned.
			Example:
			```lua
				CharacterUtils:OnLocalCharacterSpawned(function(character: Model, characterDumpster: Dumpster)
					print("Character spawned!")

					characterDumpster:Add(function()
						print("Character died!")
					end)
				end, "MySpawnCallback")
			```

		::RemoveOnSpawnedCallback(player: Player, callbackName: string)
			Remove a spawn callback by name from the given player.
			Example:
			```lua
	            CharacterUtils:RemoveOnSpawnedCallback(Players.OnlyTwentyCharacters, "MySpawnCallback")
			```

		::RemoveOnAnySpawnedCallback(callbackName: string)
			Remove a spawn callback by name from all players.
			Example:
			```lua
	            CharacterUtils:RemoveOnAnySpawnedCallback("MySpawnCallback")
			```

		::RemoveLocalOnSpawnedCallback(callbackName: string)
			Remove a spawn callback by name from the local player.
			Example:
			```lua
	            CharacterUtils:RemoveLocalOnSpawnedCallback("MySpawnCallback")
			```

		::RemoveAllCallbacksForPlayer(player: Player)
			Remove all spawn callbacks for the given player.
			Example:
			```lua
	            CharacterUtils:RemoveAllCallbacksForPlayer(Players.OnlyTwentyCharacters)
			```

		::RemoveAllLocalCallbacks()
			Remove all spawn callbacks for the local player.
			Example:
			```lua
	            CharacterUtils:RemoveAllLocalCallbacks()
			```

		::GetCharacterDumpster(player: Player): Dumpster
	        Get the dumpster for the given player.  This will create a new dumpster if one
	        does not already exist.
			Example:
			```lua
				local characterDumpster = CharacterUtils:GetCharacterDumpster(Players.OnlyTwentyCharacters)
			```

	    ::GetChildFromCharacter(player: Player | character: Model, childName: string, shouldYield: boolean?): Instance?
	        Get a child from the given player's character.  This will yield until
			the child exists if shouldYield is true.
			Example:
			```lua
	            local theirHumanoid = CharacterUtils:GetChildFromCharacter(otherPlayer, "Humanoid", true)
			```

		::GetChildFromLocalCharacter(childName: string, shouldYield: boolean?): Instance?
	        Get a child from the local player's character.  This will yield until
			the child exists if shouldYield is true.
			Example:
			```lua
	            local myHumanoid = CharacterUtils:GetChildFromLocalCharacter("Humanoid", true)
			```
--]]

-- Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Dependencies

local Dumpster = shared("Dumpster") ---@module Dumpster

-- Typing

type Dumpster = Dumpster.Dumpster

-- Main Module

local CharacterUtils = {}

-- Constants

local IS_CLIENT = RunService:IsClient()

-- Global Variables

local SpawnCallbacks = {} :: { [Player]: {} }
local AnySpawnCallbackConnections = {} :: { [string | number]: RBXScriptConnection }
local CharacterDumpsters = {} :: { [Player]: { Dumpster } }
local LocalPlayer = Players.LocalPlayer

-- Public Functions

---Get the character of a player and optionally yield until it exists
---@param player Player | string The player to get the character of or the name of the player
---@param shouldYield boolean? Whether or not to yield until the character exists
---@return Model Character The character of the player if it exists
function CharacterUtils:GetCharacter(player: Player | string, shouldYield: boolean?): Model?
	if typeof(player) == "string" then
		player = Players:FindFirstChild(player)
	end

	if not player then
		return
	end

	if shouldYield then
		-- Wait for the character to exist
		while player and player.Parent and not player.Character do
			task.wait()
		end

		-- Wait for the character to be parented
		while player and player.Parent and not player.Character.Parent do
			task.wait()
		end

		-- The player left the game while we were waiting
		if not player then
			return
		end

		if not player.Parent then
			return
		end
	end

	return if player.Character.Parent ~= nil then player.Character else nil :: Model?
end

---Get the character of the local player and optionally yield until it exists
---@param shouldYield boolean? Whether or not to yield until the character exists
---@return Model Character The character of the local player if it exists
function CharacterUtils:GetLocalCharacter(shouldYield: boolean?): Model?
	if IS_CLIENT then
		return self:GetCharacter(LocalPlayer, shouldYield)
	else
		warn(
			"GetLocalCharacter can only be called from the client, attempted to call from server.\n"
				.. debug.traceback()
		)
	end
end

---Get all characters of players
---@return table Characters The characters of all players
function CharacterUtils:GetAllCharacters(): { Model }
	local characters = {}

	for _, player in Players:GetPlayers() do
		table.insert(characters, CharacterUtils:GetCharacter(player))
	end

	return characters
end

---Add a callback for when the player spawns and provide a dumpster for
---cleaning up any connections or running functions when the player dies.
---
---This will run the callback immediately if the player is already spawned.
---@param player Player The player to add the callback for
---@param callback function The callback to run when the player spawns
---@param callbackName string The name of the callback to add (optional)
function CharacterUtils:OnCharacterSpawned(
	player: Player,
	callback: (character: Model, characterDumpster: Dumpster) -> (),
	callbackName: string?
)
	if not SpawnCallbacks[player] then
		SpawnCallbacks[player] = {}
	end

	if not callbackName then
		table.insert(SpawnCallbacks[player], callback)
	else
		if SpawnCallbacks[player][callbackName] then
			warn(
				`Attempt to add OnCharacterSpawned for {player} but callback with name {callbackName} already exists\n{debug.traceback()}`
			)
			return
		end
		SpawnCallbacks[player][callbackName] = callback
	end

	if player.Character and player.Character.Parent then
		local characterDumpster = CharacterUtils:GetCharacterDumpster(player)
		callback(player.Character, characterDumpster)
	end
end

---Adds a callback for any player, existing and future, that spawns.
---@param callback function (character: Model, characterDumpster: Dumpster) -> ()
---@param callbackName string? The name of the callback to add (optional)
function CharacterUtils:OnAnyCharacterSpawned(
	callback: (character: Model, characterDumpster: Dumpster) -> (),
	callbackName: string?
)
	for _, player: Player in pairs(Players:GetPlayers()) do
		self:OnCharacterSpawned(player, callback, callbackName)
	end

	if callbackName then
		AnySpawnCallbackConnections[callbackName] = Players.PlayerAdded:Connect(function(player: Player)
			self:OnCharacterSpawned(player, callback, callbackName)
		end)
	else
		table.insert(
			AnySpawnCallbackConnections,
			Players.PlayerAdded:Connect(function(player: Player)
				self:OnCharacterSpawned(player, callback, callbackName)
			end)
		)
	end
end

---Add a callback for when the local player spawns and provide a dumpster for
---cleaning up any connections or running functions when the player dies.
---@param callback function(character: Model, characterDumpster: Dumpster) -> () The callback to run when the player spawns
---@param callbackName string? The name of the callback to add (optional)
function CharacterUtils:OnLocalCharacterSpawned(
	callback: (character: Model, characterDumpster: Dumpster) -> (),
	callbackName: string?
)
	if IS_CLIENT then
		self:OnCharacterSpawned(LocalPlayer, callback, callbackName)
	else
		warn(
			"OnLocalCharacterSpawned can only be called from the client, attempted to call from server.\n"
				.. debug.traceback()
		)
	end
end

---Remove a callback for when the player spawns
---@param player Player The player to remove the callback for
---@param callbackName string The name of the callback to remove
function CharacterUtils:RemoveOnSpawnedCallback(player: Player, callbackName: string)
	if not SpawnCallbacks[player] then
		warn(
			`Attempt to remove CharacterSpawnCallback ({callbackName}) for {player} but no callbacks exist\n{debug.traceback()}`
		)
		return
	end
	SpawnCallbacks[player][callbackName] = nil
end

---Remove a callback for when the local player spawns
---@param callbackName string The name of the callback to remove
function CharacterUtils:RemoveLocalOnSpawnedCallback(callbackName: string)
	if IS_CLIENT then
		self:RemoveOnSpawnedCallback(LocalPlayer, callbackName)
	else
		warn(
			"RemoveLocalOnSpawnedCallback can only be called from the client, attempted to call from server.\n"
				.. debug.traceback()
		)
	end
end

---Remove a callback for all players when they spawn, future and existing
---@param callbackName string The name of the callback to remove
function CharacterUtils:RemoveOnAnySpawnedCallback(callbackName: string)
	for _, player: Player in (Players:GetPlayers()) do
		self:RemoveOnSpawnedCallback(player, callbackName)
	end

	if AnySpawnCallbackConnections[callbackName] then
		AnySpawnCallbackConnections[callbackName]:Disconnect()
		AnySpawnCallbackConnections[callbackName] = nil
	end
end

---Remove all callbacks for when the player spawns
---@param player Player The player to remove the callbacks for
function CharacterUtils:RemoveAllCallbacksForPlayer(player: Player)
	SpawnCallbacks[player] = {}
end

---Remove all callbacks for when the local player spawns
function CharacterUtils:RemoveAllLocalCallbacks()
	if IS_CLIENT then
		self:RemoveAllCallbacksForPlayer(LocalPlayer)
	else
		warn(
			"RemoveAllLocalCallbacks can only be called from the client, attempted to call from server.\n"
				.. debug.traceback()
		)
	end
end

---Get the dumpster for the player's character
---@param player Player The player to get the CharacterDumpster for
---@return table Dumpster The CharacterDumpster for the player
function CharacterUtils:GetCharacterDumpster(player: Player): Dumpster
	if not player then
		return
	end

	if not CharacterDumpsters[player] then
		CharacterDumpsters[player] = Dumpster.new()
		CharacterDumpsters[player]:AttachTo(player)
	end

	return CharacterDumpsters[player]
end

---Retrieves a child from a player's character
---@param player | Model Player The player to get the child from or alternatively their character
---@param childName string The name of the child to get
---@return Instance? Instance The child if it exists
function CharacterUtils:GetChildFromCharacter(player: Player | Model, childName: string, shouldYield: boolean?): Instance?
	local character
	if typeof(player) == "Instance" and player:IsA("Model") then
		character = player
	else
		character = CharacterUtils:GetCharacter(player, shouldYield)
	end
	if not character then
		return
	end
	return if shouldYield then character:WaitForChild(childName) else character:FindFirstChild(childName)
end

---Retrieves a child from the local player's character
---@param childName string The name of the child to get
---@return Instance? Instance The child if it exists
function CharacterUtils:GetChildFromLocalCharacter(childName: string, shouldYield: boolean?): Instance?
	if IS_CLIENT then
		return CharacterUtils:GetChildFromCharacter(LocalPlayer, childName, shouldYield)
	else
		warn(
			"GetChildFromLocalCharacter can only be called from the client, attempted to call from server.\n"
				.. debug.traceback()
		)
	end
end

-- Initialization

do
    local function onPlayerAdded(player: Player)
        local characterDumpster = CharacterUtils:GetCharacterDumpster(player)

        player.CharacterAdded:Connect(function(character)
            for _, callback in SpawnCallbacks[player] do
                callback(character, characterDumpster)
            end
        end)

        player.CharacterRemoving:Connect(function(_)
            characterDumpster:Clean()
        end)

        if player.Character and SpawnCallbacks[player] then
            for _, callback in SpawnCallbacks[player] do
                callback(player.Character, characterDumpster)
            end
        end
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in Players:GetPlayers() do
        onPlayerAdded(player)
    end

	Players.PlayerRemoving:Connect(function(player)
		SpawnCallbacks[player] = nil
	end)
end

-- Return

return CharacterUtils
