--[[
	File: Carpenter.lua
	Author(s): Eric Karolchyk, Michael Dougal, Harrison Lewis
	Created: 11/04/2022
	Version: 1.1.0

	Sawhorse Proprietary Framework

	DOCUMENTATION PENDING
--]]

debug.setmemorycategory("Carpenter.Framework")

-- Root

local Carpenter = {}

-- Settings File

local Settings = require(script:WaitForChild("Settings"))

-- Roblox Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants

local VERBOSE_OUTPUT = Settings.VerboseOutput
local INIT_SLOW_TIMEOUT = Settings.SlowInitTimeout
local OUTPUT_PREFIX = "[Carpenter]"
local VERSION = "1.2.0"
local MESSAGES = {
	MATCHING_PRIORITY = "Jobs %q and %q share matching priorities (%d) - %s's priority has been bumped. Project stability may be affected.",
	PRIORITY_RESOLVED = "Resolved priority match between %q and %q - %s's new priority is %d.",
	JOB_ERROR = "[ERROR] %s::%s() experienced an error during execution. Stack Trace:\n%s",
	INIT_TOO_SLOW = "%s::Init() took more than %.2fs to run. Move yielding operations to ::Run() for better stability.",
	JOB_START = "Executing %s::%s() (priority %d)...",
	STARTUP_TIME = "Successfully executed %d jobs in ~%.5f seconds!",
}

-- Types

type Job = {
	Priority: number?,
	Init: () -> ()?,
	Run: () -> ()?,
}

-- Variables

-- A dictionary of known module aliases and the ModuleScripts they point to
local Modules: { [string]: ModuleScript } = {}
-- A dictionary of loaded ModuleScripts and the values they returned
local LoadedModules: { [ModuleScript]: any } = {}
-- The set of all currently loading modules
local ModulesLoading: { [ModuleScript]: boolean } = {}
-- An array that contains all currently loaded job module data
local Jobs: { Job } = {}
local JobNames: { [Job]: string } = {}
-- The current number of ancestry levels that have been indexed
local AncestorLevelsExpanded = 0

-- Private Functions

local standardPrint = print
local function print(...)
	standardPrint(OUTPUT_PREFIX, ...)
end

local standardWarn = warn
local function warn(...)
	standardWarn(OUTPUT_PREFIX, ...)
end

local function verbosePrint(template: string, ...: any)
	if VERBOSE_OUTPUT then
		print(template:format(...))
	end
end

-- Loads the given ModuleScript with error handling. Returns the loaded data.
local function load(module: ModuleScript): any?
	local moduleData: any?

	local loadSuccess, loadMessage = pcall(function()
		moduleData = require(module)
	end)
	if not loadSuccess then
		warn("Failed to load module", module.Name, "-", loadMessage)
	end

	-- This part has to be done in pcall because sometimes developers set their
	-- modules to be read-only through metatables
	if typeof(moduleData) == "table" and (moduleData.Init or moduleData.Run) then
		JobNames[moduleData] = module.Name
	end

	return moduleData
end

-- Returns a table of all of the provided Instance's ancestors in ascending
-- order
local function getAncestors(descendant: Instance): { Instance }
	local ancestors = {}
	local current = descendant.Parent
	while current do
		table.insert(ancestors, current)
		current = current.Parent
	end
	return ancestors
end

-- Adds all available aliases for a ModuleScript to the internal index registry,
-- up to the specified number of ancestors (0 refers to the script itself,
-- indexes all ancestors if no cap specified)
local function indexNames(child: ModuleScript, levelCap: number?)
	if typeof(child) ~= "Instance" then
		return
	end

	local function indexName(index: string)
		if Modules[index] and Modules[index] ~= child then
			local existing = Modules[index]
			if typeof(existing) == "table" and not table.find(existing, child) then
				table.insert(existing, child)
			else
				Modules[index] = { existing, child }
			end
		else
			Modules[index] = child
		end
	end

	indexName(child.Name)

	local ancestors = getAncestors(child)
	local currentIndex = child.Name
	for level: number, ancestor: Instance in pairs(ancestors) do
		if levelCap and level > levelCap then
			break
		end
		currentIndex = ancestor.Name .. "/" .. currentIndex
		indexName(currentIndex)
		if
			ancestor.Name == "ServerScriptService"
			or ancestor.Name == "PlayerScripts"
			or ancestor.Name == "ReplicatedStorage"
		then
			break
		end
	end
end

-- Expand the number of name aliases for known modules to include number of
-- ancestry levels up to the given levelCap
local function expandNameIndex(levelCap: number)
	if levelCap <= AncestorLevelsExpanded then
		return
	end

	if VERBOSE_OUTPUT then
		print("Expanding ancestry name index to level", levelCap)
	end

	for _, moduleData in pairs(Modules) do
		if typeof(moduleData) == "table" then
			for _, module in pairs(moduleData) do
				indexNames(module, levelCap)
			end
		elseif typeof(moduleData) == "Instance" then
			indexNames(moduleData, levelCap)
		end
	end

	AncestorLevelsExpanded = levelCap
end

-- Indexes any ModuleScript children of the specified Instance
local function indexModulesOf(location: Instance)
	if VERBOSE_OUTPUT then
		print("Indexing modules -", location:GetFullName())
	end

	local discovered = 0
	for _: number, child: Instance in ipairs(location:GetDescendants()) do
		if child:IsA("ModuleScript") and child ~= script then
			discovered += 1
			indexNames(child, 0)
		end
	end

	if VERBOSE_OUTPUT and discovered > 0 then
		print("\tDiscovered", discovered, if discovered == 1 then "module" else "modules")
	end
end

-- Asynchronously loads all ModuleScript children of the specified job Folder,
-- and queues them for initialization. Recursively loads all children of any
-- discovered Folders as well.
local function loadJobs(location: Folder)
	if VERBOSE_OUTPUT then
		print("Loading jobs -", location:GetFullName())
	end

	for _: number, child: ModuleScript | Folder in ipairs(location:GetChildren()) do
		if child:IsA("ModuleScript") then
			if table.find(Settings.IgnoredJobNames, child.Name) ~= nil then
				warn(`Ignoring disabled job {child.Name}`)
				continue
			end

			-- Jobs might have duplicates, so we find its shortest unique
			-- path name
			local jobName = child.Name
			local nextParent = child.Parent
			while Modules[jobName] and typeof(Modules[jobName]) == "table" do
				jobName = nextParent.Name .. "/" .. jobName
				nextParent = nextParent.Parent
			end

			local jobData = Carpenter:__call(jobName)
			if jobData then
				table.insert(Jobs, jobData)
			else
				warn(child, "failed to load")
			end
		elseif child:IsA("Folder") then
			loadJobs(child)
		end
	end
end

---Safely attempts to execute all known jobs.
local function executeJobs()
	local executionStartTime = os.clock()
	local totalJobs = 0

	verbosePrint("Initializing jobs...")

	table.sort(Jobs, function(a, b)
		local aPriority = a.Priority or 0
		local bPriority = b.Priority or 0
		return aPriority > bPriority
	end)

	if VERBOSE_OUTPUT then
		print("\tCurrent initialization order:")
		for index: number, job: {} in pairs(Jobs) do
			print("\t\t" .. index .. ")", JobNames[job] or "Unknown Job")
		end
	end

	local function initialize(job: Job)
		local startTime = os.clock()
		local finished = false
		local name = JobNames[job] or "Unknown Job"
		task.spawn(function()
			while not finished do
				task.wait()
				if os.clock() - startTime > INIT_SLOW_TIMEOUT then
					warn(
						"Slow job detected -",
						name,
						"has been initializing for more than",
						INIT_SLOW_TIMEOUT,
						"seconds. Move yielding operations to ::Run() for better stability."
					)
					break
				end
			end
		end)

		verbosePrint(MESSAGES.JOB_START, name, "Init", job.Priority or 0)
		debug.setmemorycategory("Carpenter." .. name .. "::Init()")

		local success, message = pcall(function()
			job:Init()
		end)

		finished = true

		if not success then
			warn("Failed to initialize", name, "-", message)
		else
			verbosePrint("\tInitialized", name)
		end
	end

	local function run(job: Job)
		local name = JobNames[job] or "Unknown Job"
		verbosePrint(MESSAGES.JOB_START, name, "Run", job.Priority or 0)
		debug.setmemorycategory("Carpenter." .. name .. "::Run()")
		local success, message = pcall(function()
			job:Run()
		end)
		if not success then
			warn("Module", name, " experienced an error while running -", message)
		end
	end

	for _: number, job: Job in pairs(Jobs) do
		totalJobs += 1
		if job.Init then
			initialize(job)
		end
	end

	verbosePrint("All jobs initialized.")
	verbosePrint("Running jobs...")

	local jobsRunning = 0
	for _: number, job: Job in pairs(Jobs) do
		if job.Run then
			jobsRunning += 1
			task.spawn(function()
				run(job)
				jobsRunning -= 1
			end)
		end
	end

	verbosePrint("All jobs running.")

	table.clear(Jobs)

	verbosePrint(MESSAGES.STARTUP_TIME, totalJobs, os.clock() - executionStartTime)
end

--[ Module Loader ]--

---Safely requires a ModuleScript from the Rojo project path (if applicable)
---or a regular module script.
---
---This function can also be accessed globally as `shared()`, provided Carpenter
---has been initialized beforehand.
---@param module string | ModuleScript The path or ModuleScript instance to require.
function Carpenter.__call(_: {}, module: string | ModuleScript): any?
	if typeof(module) == "Instance" then
		return require(module)
	end

	-- Backwards compatibility for Infinity modules using the prefix for shared
	-- modules.
	if module:find("$") == 1 then
		module = module:sub(2)
	end

	if Modules[module] and LoadedModules[Modules[module]] then
		return LoadedModules[Modules[module]]
	end

	if Modules[module] then
		if not ModulesLoading[Modules[module]] then
			-- If we find a table here, it's a list of all the modules that
			-- query could be pointing to (duplicates), otherwise it's what
			-- we're looking for.
			if typeof(Modules[module]) == "table" then
				local trace = debug.traceback()
				local trim = string.sub(trace, string.find(trace, "__call") + 7, string.len(trace) - 1)
				local warning = trim .. ": Multiple modules found for '" .. module .. "' - please be more specific:\n"
				local numDuplicates = #Modules[module]
				for index, duplicate in ipairs(Modules[module]) do
					if typeof(duplicate) == "table" then
						continue
					end
					local formattedName = string.gsub(duplicate:GetFullName(), "[.]", "/")
					warning ..= "\t\t\t\t\t\t\t- " .. formattedName .. if index ~= numDuplicates then "\n" else ""
				end
				warn(warning)
				return
			end
			ModulesLoading[Modules[module]] = true
			local moduleData = load(Modules[module])
			LoadedModules[Modules[module]] = moduleData
			ModulesLoading[Modules[module]] = nil
		else
			warn("Cyclic dependency detected when loading", module, "- modules involved:")
			for moduleScript: ModuleScript in pairs(ModulesLoading) do
				warn("\t-", moduleScript:GetFullName())
			end
		end
	else
		if VERBOSE_OUTPUT then
			print("Cache miss for", module)
		end
		local _, ancestorLevels = string.gsub(module, "/", "")
		if ancestorLevels > AncestorLevelsExpanded then
			-- Expand the number of name aliases for known modules to
			-- include number of levels potentially referenced and retry
			expandNameIndex(ancestorLevels)
			return Carpenter:__call(module)
		else
			-- Ancestor index expansion has already reached all possibly
			-- referenced levels, so we just don't know where the module is
			local trace = debug.traceback()
			local trim = string.sub(trace, string.find(trace, "__call") + 7, string.len(trace) - 1)
			warn(trim .. ": Attempt to require unknown module '" .. module .. "'")
			return
		end
	end

	return LoadedModules[Modules[module]]
end

function Carpenter.execute(target: Folder | ModuleScript)
	indexModulesOf(target)
	loadJobs(target)
	executeJobs()
end

-- Framework initialization

do
	workspace:SetAttribute("CarpenterVersion", VERSION)

	-- calling this module as a function will act as the module loader
	setmetatable(Carpenter, Carpenter)

	-- shared() support
	setmetatable(shared, Carpenter)

	local localContext
	if RunService:IsClient() then
		local localPlayer = game:GetService("Players").LocalPlayer
		if localPlayer and RunService:IsRunning() then
			localContext = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
		else
			localContext = game:GetService("StarterPlayer").StarterPlayerScripts.Client
		end
	else
		localContext = game:GetService("ServerScriptService"):WaitForChild("Server")
	end
	local sharedContext = ReplicatedStorage:WaitForChild("Shared")

	indexModulesOf(localContext)
	indexModulesOf(sharedContext)

	if RunService:IsRunning() then
		loadJobs(localContext:WaitForChild("jobs"))
		loadJobs(sharedContext:WaitForChild("jobs"))

		executeJobs()
	end
end

return Carpenter
