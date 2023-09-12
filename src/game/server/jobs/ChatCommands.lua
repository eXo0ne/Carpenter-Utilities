--[[
	Author: TactBacon & ChiefWildin
	Module: ChatCommands.lua
	Created: 11/03/2022
--]]

--=| Services |=--

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")

--=| Main Job Declaration |=--

local ChatCommands = {}

--=| Dependencies |=--

local rcall = shared("rcall") ---@module rcall
local GetRemote = shared("GetRemote") ---@module GetRemote

--=| Constants |=--

-- A list of groups whose members above a certain rank are allowed to use these
-- commands. `[GroupId] = MinimumRank`
local PERMISSIONS: { [number]: number } = {
	[12722816] = 253, -- Sawhorse
	[32601682] = 252, -- Just Some Island Boys
}
-- The PlaceId of the starter place for this universe
local STARTER_PLACEID = 13830826236
-- A dictionary of branch command keywords to their respective PlaceIds
local BRANCHES = {
	["test"] = 13882183199,
	["art"] = 13831344526,
	["michael"] = 13882191415,
	["daniel"] = 13882192356,
}

--=| Variables |=--

local PlayerAuthStatuses: { [Player]: boolean } = {}

--=| Objects |=--

local SystemRemote = GetRemote("SystemMessage")

--=| Functions |=--

local function checkPlayerAuthorization(player: Player)
	if PlayerAuthStatuses[player] == nil then
		for groupId, minRank in pairs(PERMISSIONS) do
			local playerRank = rcall({ retryDelay = 0.5 }, player.GetRankInGroup, player, groupId)
			if playerRank and playerRank >= minRank then
				PlayerAuthStatuses[player] = true
				return true
			else return true
			end
		end
		PlayerAuthStatuses[player] = false
	end
	return PlayerAuthStatuses[player]
end

--=| API |=--

-- Creates a new text chat command with the given name, aliases, and function.
-- You must have at least one alias, but you can have up to two.
function ChatCommands:CreateCommand(
	commandName: string,
	commandAliases: { string },
	commandFunction: (commander: Player, originTextSource: TextSource, unfilteredText: string) -> ()
)
	local command: TextChatCommand = Instance.new("TextChatCommand")
	command.Name = commandName
	command.PrimaryAlias = commandAliases[1]
	if commandAliases[2] then
		command.SecondaryAlias = commandAliases[2]
	end
	command.Triggered:Connect(function(originTextSource, unfilteredText)
		local userId: number = originTextSource.UserId
		local player: Player = Players:GetPlayerByUserId(userId)
		if player and checkPlayerAuthorization(player) then
			commandFunction(player, originTextSource, unfilteredText)
		end
	end)
	command.Parent = TextChatService
end

--=| Initialization |=--

function ChatCommands:Run()
	ChatCommands:CreateCommand("StartCommand", { "/start", "/main" }, function(player)
		SystemRemote:FireClient(player, "Teleporting...")
		rcall({ retryDelay = 4 }, TeleportService.TeleportAsync, TeleportService, STARTER_PLACEID, { player })
	end)

	ChatCommands:CreateCommand("BranchCommand", { "/branch" }, function(player, _: TextSource, unfilteredText: string)
		local branchName = string.sub(unfilteredText, 9)
		if tonumber(branchName) then
			SystemRemote:FireClient(player, "Teleporting...")
			rcall({ retryDelay = 4 }, TeleportService.TeleportAsync, TeleportService, branchName, { player })
		elseif BRANCHES[branchName] then
			SystemRemote:FireClient(player, "Teleporting...")
			rcall({ retryDelay = 4 }, TeleportService.TeleportAsync, TeleportService, BRANCHES[branchName], { player })
		else
			SystemRemote:FireClient(player, "Cannot teleport - unknown branch '" .. branchName .. "'")
		end
	end)

	ChatCommands:CreateCommand("TeleportToPlayer", { "/tp", "/teleport" }, function(commander, _, unfilteredText)
		local function findPlayersByQuery(query: string): {Player}
			query = string.lower(query)

			if query == "me" then
				return {commander}
			end

			local players = {}
			for _, player in Players:GetPlayers() do
				if string.find(string.lower(player.Name), query, 1, true) then
					table.insert(players, player)
				end
			end
			return players
		end

		local components = string.split(unfilteredText, " ")

		if not components[2] or not components[3] then
			SystemRemote:FireClient(commander, "Cannot teleport - please specify two players")
			return
		end

		local targetPlayers = findPlayersByQuery(components[2])
		local destinationPlayers = findPlayersByQuery(components[3])

		if #targetPlayers ~= 1 or #destinationPlayers ~= 1 then
			SystemRemote:FireClient(commander, "Cannot teleport - multiple or no players found for names given")
		else
			SystemRemote:FireClient(commander, "Teleporting player...")
			targetPlayers[1].Character:PivotTo(destinationPlayers[1].Character:GetPivot())
		end
	end)
end

return ChatCommands
