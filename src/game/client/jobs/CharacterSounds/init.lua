--[[
    Author: eXo0ne
    Module: CharacterSounds.lua
    Created: 09/12/2023

        Description:
        No description provided.

        ```lua
        local function renameSounds(material)
            local strToType = {
                ["Land_"] = "Landing",
                ["Footstep"] = "Running"
            }

            local soundStrings = {
                "Land_",
                "Footstep"
            }

            for _, sound in game.Selection:Get() do
                for _, soundString in soundStrings do
                    local soundType = sound.Name:match(soundString) and strToType[soundString] or nil
                    if not soundType then continue end

                    local variationNumber = sound.Name:match("_%d+")

                    sound.Name = `{soundType}_{material}{variationNumber}`
                end
            end

            local randomObj = Random.new()
            local tagList = game.ServerStorage:FindFirstChild("TagList")

            if tagList then
                local materialTag = tagList:FindFirstChild(material)

                if not materialTag then
                    materialTag = Instance.new("Configuration")

                    materialTag.Name = material
                    materialTag:SetAttribute("AlwaysOnTop", false)
                    materialTag:SetAttribute("DrawType", "Box")
                    materialTag:SetAttribute("Group", nil)
                    materialTag:SetAttribute("Icon", "tag_green")
                    materialTag:SetAttribute("Visible", true)
                    materialTag:SetAttribute("Color", Color3.new(
                        randomObj:NextNumber(0, 1),
                        randomObj:NextNumber(0, 1),
                        randomObj:NextNumber(0, 1))
                    )
                    
                    materialTag.Parent = tagList
                end
            end
        end

        local material = "CityStep"
        renameSounds(material)
        ```

        ```lua
        local runningOrLanding = true
        local material = "CityStep"
        local soundType = runningOrLanding and "Running" or "Landing"

        for _, sound in game.Selection:Get() do
            local variationNumber = sound.Name:match("_%d+")

            sound.Name = `{soundType}_{material}{variationNumber}`
        end
        ```

    Documentation:
    	Sound name setup:
        SoundType_CollectionMaterialTag_Variation
--]]

-- Services
local Debris = game:GetService("Debris")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local SoundService = game:GetService('SoundService')

-- Dependencies
local CharacterUtils = shared("CharacterUtils") ---@module CharacterUtils
local Get = shared("Get") ---@module Get
local TagGroup = shared("TagGroup") ---@module TagGroup
local RunningFunctions = shared("RunningFunctions")
local LandingFunctions = shared("LandingFunctions")
local SharedTypes = shared("SharedTypes") ---@module SharedTypes
-- local StateManager = shared("StateManager") ---@module StateManager
local SoundPlayer = shared("SoundPlayer") ---@module SoundPlayer

-- Types
type Maid = SharedTypes.Maid

-- Module Declaration
local CharacterSounds = {}

-- Constants
local PATH_TO_RIGHT_FOOT = {"HumanoidRootPart", "LowerTorso", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
local PATH_TO_LEFT_FOOT = {"HumanoidRootPart", "LowerTorso", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"}
local EFFECT_DISTANCE = 60
local LANDED_DEBOUNCE = 0.1

-- Global Variables
local animationCache = {}
local sounds = {}
local materialTypes = {}
local runningState = Enum.HumanoidStateType.Running
local runningNoPhysicsState = Enum.HumanoidStateType.RunningNoPhysics

-- Objects
local applyPosesInPath

-- Private Functions

-- Only mute default charater movement sounds so it does not break "RbxCharacterSounds"
-- SoundType refers to default character sound names
local function muteDefaultSounds(character)
    for soundType, _ in sounds do
        local soundInstance = character.HumanoidRootPart:FindFirstChild(soundType)
        if soundInstance then
            soundInstance.Volume = 0
        end
    end
end

-- Check if the target character is whithin the distance of the effect
local function isLocalCharacterWithinDistanceTo(player: Player)
    local targetCharacter = CharacterUtils:GetCharacter(player)
    local localCharacter = CharacterUtils:GetLocalCharacter()

    if not targetCharacter or not localCharacter then return false end
    if targetCharacter == localCharacter then return true end

    return (localCharacter:GetPivot().Position - targetCharacter:GetPivot().Position).Magnitude <= EFFECT_DISTANCE
end

-- Fisher-Yates shuffle
local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    
    return tbl
end

-- Public Functions
function CharacterSounds:BindSoundsTo(character: Model, characterMaid: Maid): nil
    local targetPlayer = Players:GetPlayerFromCharacter(character)
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    print("Binding sounds to", targetPlayer.Name)

    muteDefaultSounds(character)

    local currentStep = nil
    local currentFloorMaterial = nil
    local rootPartHalfHeight = rootPart.Size.Y / 2
    local humanoidHipHeight = humanoid.HipHeight * 1.1
	local rayLengthMod = 1
	local lastLanded = 0
    local recentlyLanded = false
    local maidCleaned = false
    local soundPlaylists = {}

    local isCharacterWhithinDistance = isLocalCharacterWithinDistanceTo()

    -- Setup playlist for shuffling
    for soundType, materials in sounds do
        for material, _ in materials do
            if not soundPlaylists[soundType] then
                soundPlaylists[soundType] = {}
            end

            if not soundPlaylists[soundType][material] then
                soundPlaylists[soundType][material] = { Current = 1, List = { } }

                for i = 1, sounds[soundType][material] do
                    table.insert(soundPlaylists[soundType][material].List, i)
                end
            end
        end
    end

    -- Create a new playlist for a material if it has been played through
    local function createUniquePlaylist(soundType: string, materialTag: string)
        soundPlaylists[soundType][materialTag].Current = 1
        shuffle(soundPlaylists[soundType][materialTag].List)
    end

    local function getSoundFromPlaylist(soundType: string, materialTag: string)
        if not soundPlaylists[soundType]
        or not soundPlaylists[soundType][materialTag]
        or soundPlaylists[soundType][materialTag].Current >
            #soundPlaylists[soundType][materialTag].List
        then
            createUniquePlaylist(soundType, materialTag)
        end

        local soundListData = soundPlaylists[soundType][materialTag]
        local playlist = soundListData.List
        local variationNum = playlist[soundListData.Current]

        soundListData.Current += 1

        return SoundPlayer:GetSound(`{soundType}_{materialTag}_{variationNum}`):Clone()
    end

    local function runDistanceCheck()
        while not maidCleaned do
            task.wait(0.5)
            isCharacterWhithinDistance = isLocalCharacterWithinDistanceTo(targetPlayer)
        end
    end

    -- Find the current floor material
    characterMaid:Add(RunService.Heartbeat:Connect(function()
        if not character:FindFirstChild("HumanoidRootPart") then return end
        if not isCharacterWhithinDistance then return end

		local rayResult = workspace:Raycast(rootPart.Position + Vector3.new(0, -rootPartHalfHeight, 0), Vector3.new(0, -humanoidHipHeight * rayLengthMod, 0), self.raycastParams)

        if rayResult then
            local floorMaterial = rayResult.Instance:GetAttribute("FloorMaterial")

            if floorMaterial and currentFloorMaterial ~= floorMaterial then
                currentFloorMaterial = floorMaterial
                
            -- If floor material isnt found, check for terrain materials
            elseif not floorMaterial then
                if rayResult.Instance == workspace.Terrain then
                    if table.find(materialTypes, humanoid.FloorMaterial.Name)  then
                        currentFloorMaterial = humanoid.FloorMaterial.Name
                    else
                        currentFloorMaterial = nil
                    end
                end
            end
        else
            currentFloorMaterial = nil
        end
	end))

    -- Landing sounds/functions player
	characterMaid:Add(humanoid.FreeFalling:Connect(function(active)
        if not isCharacterWhithinDistance then return end

		if active then
            -- Cast longer ray to catch a floor material
			rayLengthMod = 3

		elseif os.clock() - lastLanded > LANDED_DEBOUNCE then
            lastLanded = os.clock()
            rayLengthMod = 1

            recentlyLanded = true

            task.delay(LANDED_DEBOUNCE * 1.5, function()
                recentlyLanded = false
            end)

            if currentFloorMaterial then
                -- Find the landing sound and play it
                local sound = getSoundFromPlaylist("Landing", currentFloorMaterial)
                sound.Parent = rootPart
                sound:Play()
                sound.Ended:Once(function()
                    sound:Destroy()
                end)

                -- Run the OnLand function if it exists
                if LandingFunctions.OnLand then
                    LandingFunctions.OnLand(character, self.raycastParams)
                end
            end
		end
	end))

    local averages = {}

    -- Footstep sounds/functions player
    characterMaid:Add(RunService.Heartbeat:Connect(function()
        local start = os.clock()
        if not character:FindFirstChild("HumanoidRootPart") then return end
        if not isCharacterWhithinDistance then return end
        -- if StateManager:IsStateActive("Roll") then return end
        if recentlyLanded then return end

        -- Check if the character is moving/running
        local currentState = humanoid:GetState()
        local moveDirMag = humanoid.MoveDirection.Magnitude
        local running = (currentState == runningState or currentState == runningNoPhysicsState) and moveDirMag > 0

        if running then
            local playingAnims = humanoid.Animator:GetPlayingAnimationTracks()

            local runningTrack
            local walkingTrack

            -- Find the playing animation tracks for running and walking
            for _, animTrack in playingAnims do
                local animation = animTrack.Animation
                local animationData = animationCache[animation.AnimationId]

                if animationData then
                    if animationData.Name == "RunAnim" then
                        runningTrack = animTrack
                    elseif animationData.Name == "WalkAnim" then
                        walkingTrack = animTrack
                    end
                end
            end

            if not runningTrack or not walkingTrack then return end

            local step = false
            local referenceAnimTrack = walkingTrack.Speed <= 1 and walkingTrack or runningTrack
            local referenceTimePos = referenceAnimTrack.TimePosition
            local animationData = animationCache[referenceAnimTrack.Animation.AnimationId]

            -- Check for the correct step timing
            if not animationData.SwitchedTimes then
				if referenceTimePos >= animationData.Left and referenceTimePos < animationData.Right and currentStep ~= "Right" then
					currentStep = "Right"
	                step = true
				elseif (referenceTimePos < animationData.Left or referenceTimePos >= animationData.Right) and currentStep ~= "Left" then
					currentStep = "Left"
	                step = true
				end
			else
				if referenceTimePos >= animationData.Left and referenceTimePos < animationData.Right and currentStep ~= "Left" then
					currentStep = "Left"
					step = true
				elseif (referenceTimePos < animationData.Left or referenceTimePos >= animationData.Right) and currentStep ~= "Right" then
					currentStep = "Right"
					step = true
				end
			end

            -- If there was a step on this frame
            -- and the character is on tagged ground
            if step and currentFloorMaterial then
                local currentStep = currentStep == "Right" and "Left" or "Right"
                local currentFoot = character[`{ currentStep }Foot`]

                -- Find the footstep sound and play it
                local start = os.clock()
                local sound = getSoundFromPlaylist("Running", currentFloorMaterial)
                sound.Parent = currentFoot
                sound:Play()
                sound.Ended:Once(function()
                    sound:Destroy()
                end)

                table.insert(averages, os.clock() - start)

                if #averages > 50 then
                    print("hit limit")
                    table.remove(averages, 1)
                end

                local total = 0
                for _, value in ipairs(averages) do
                    total = total + value
                end

                -- warn(total / #averages)

                -- Run the OnStep function if it exists
                if RunningFunctions.OnStep then
                    RunningFunctions.OnStep(currentStep, character, self.raycastParams)
                end

                -- Run the current floor material's function if it exists
                if RunningFunctions[currentFloorMaterial] then
                    RunningFunctions[currentFloorMaterial](currentStep, character)
                end
            end
            warn(os.clock() - start)
        else
            currentStep = nil
        end
	end))

    characterMaid:Add(function()
        maidCleaned = true
    end)

    runDistanceCheck()
end

-- Job Initialization
function CharacterSounds:Run()
    CharacterUtils:OnAnyCharacterSpawned(function(character, characterDumpster)
        local rootPart = character:WaitForChild("HumanoidRootPart", 1)
        if not rootPart then return end

        local targetAnims = {
            RunAnim = Get(character, "Animate", "run", "RunAnim"),
            WalkAnim = Get(character, "Animate", "walk", "WalkAnim")
        }

        for animationName, animation in targetAnims do
            if animationCache[animation.AnimationId] then continue end

            local keyframeSequence = KeyframeSequenceProvider:GetKeyframeSequenceAsync(animation.AnimationId)
            if not keyframeSequence then return end

            -- Create a dummy to apply the animation to
            local dummy = Get(ReplicatedStorage, "Assets", "CharacterSounds", "Dummy"):Clone()
            dummy:PivotTo(CFrame.new(0, 10000, 0))
            dummy.Parent = workspace

            Debris:AddItem(dummy, 10)

            -- Applies pose CFrame data to the target bodypart
            -- to find foot position in space
            applyPosesInPath = function(path: {}, poses: {}, pathIndex: number?)
                local pathIndex = pathIndex or 1
                local nextPoseName = path[pathIndex]
                local foundPose

                for _, subPose in poses do
                    if subPose.Name == nextPoseName then
                        foundPose = subPose
                        poses = foundPose
                        break
                    end
                end

                if foundPose then
                    local poseName = foundPose.Name
                    local bodyPart = dummy:FindFirstChild(poseName)
                    local motor6d = bodyPart:FindFirstChildOfClass("Motor6D")

                    if motor6d then
                        motor6d.Transform = foundPose.CFrame
                    end

                    if foundPose.Name:find("Foot") then
                        task.wait()
                        return bodyPart.Position, bodyPart.CFrame.UpVector
                    end

                    return applyPosesInPath(path, foundPose:GetSubPoses(), pathIndex + 1)
                else
                    return nil
                end
            end

            local footPositionData = { }

            -- Iterate through every keyframe in the animation
            -- to record data about their foot positioning
            for _, keyframe in keyframeSequence:GetKeyframes() do
                local poses = keyframe:GetPoses()

                local rightFootPosition, rightFootUpVector = applyPosesInPath(PATH_TO_RIGHT_FOOT, poses)
                local leftFootPosition, leftFootUpVector = applyPosesInPath(PATH_TO_LEFT_FOOT, poses)

                if rightFootPosition and leftFootPosition then
                    table.insert(footPositionData, {
                        Time = keyframe.Time,
                        Feet = {
                            Right = { pos = rightFootPosition.Y, direction = rightFootUpVector },
                            Left = { pos = leftFootPosition.Y, direction = leftFootUpVector }
                        }
                    })
                end
            end

            local rightFootstepTime
            local leftFootstepTime

            local currentFootData = {
                Right = { lowestY = math.huge, timePosition = 0, direction = Vector3.new(0, 1, 0) },
                Left = { lowestY = math.huge, timePosition = 0, direction = Vector3.new(0, 1, 0) }
            }

            -- Find the lowest Y position of each foot for each keyframe
            -- which indicates a step
            for _, data in footPositionData do
                local timePosition = data.Time

                for foot, footData in data.Feet do
                    local currentFootValues = currentFootData[foot]

                    if footData.pos < currentFootValues.lowestY then
                        -- Find the dot product between the last keyframe's foot direction
                        -- and the current keyframe's foot direction to find the first
                        -- flat step and filter out the rest flat-foot keyframes after
                        if currentFootValues.direction:Dot(footData.direction) < 0.99 then
                            currentFootValues.lowestY = footData.pos
                            currentFootValues.timePosition = timePosition
                            currentFootValues.direction = footData.direction
                        end
                    end

                    if foot == "Right" then
                        rightFootstepTime = currentFootValues.timePosition
                    else
                        leftFootstepTime = currentFootValues.timePosition
                    end
                end
            end

            local switchedFootTimes = false

            if not leftFootstepTime or not rightFootstepTime then
                continue
            end

            if leftFootstepTime > rightFootstepTime then
                switchedFootTimes = true

                local tempLeftFootTime = leftFootstepTime
                leftFootstepTime = rightFootstepTime
                rightFootstepTime = tempLeftFootTime
            end

            animationCache[animation.AnimationId] = {
                Name = animationName,
                Right = rightFootstepTime,
                Left = leftFootstepTime,
                SwitchedTimes = switchedFootTimes
            }
        end

        self:BindSoundsTo(character, characterDumpster)
    end)
end

function CharacterSounds:Init()
    self.raycastParams = RaycastParams.new()
    self.raycastParams.FilterType = Enum.RaycastFilterType.Include

    -- Setup & cache all sounds and their number of variations
    for _, sound in SoundService.Master.Character:GetChildren() do
        local soundType, materialTag, variation = sound.Name:match("(%a+)_(%a+)_(%d+)")

        if not soundType or not materialTag or not variation then
            continue
        end

        sound.RollOffMode = Enum.RollOffMode.LinearSquare
        sound.RollOffMinDistance = 1
        sound.RollOffMaxDistance = EFFECT_DISTANCE

        -- -- Set a PlaybackRegion to account of "empty" sound before the step
        -- task.delay(0.5, function()
        --     if not sound.Loaded then
        --         sound.Loaded:Wait()
        --     end

        --     sound.Volume = 0
        --     sound.PlaybackSpeed = 0.05
        --     sound:Play()

        --     local lastLoudness = 0
        --     local timePosition = 0
        --     local loudnessConnection
        --     loudnessConnection = RunService.Heartbeat:Connect(function()
        --         if not sound.Playing then
        --             loudnessConnection:Disconnect()

        --             timePosition = math.clamp(timePosition - 0.033, 0, 100)

        --             sound.Volume = sound:GetAttribute("OriginalVolume")
        --             sound.PlaybackRegionsEnabled = true
        --             sound.PlaybackRegion = NumberRange.new(timePosition, 100)
        --             sound.PlaybackSpeed = 1
        --             return
        --         end
                
        --         if sound.PlaybackLoudness > lastLoudness then
        --             lastLoudness = sound.PlaybackLoudness
        --             timePosition = sound.TimePosition
        --         end
        --     end)
        -- end)

        if not sounds[soundType] then
            sounds[soundType] = {}
        end

        sounds[soundType][materialTag] = not sounds[soundType][materialTag] and variation or
        (sounds[soundType][materialTag] and sounds[soundType][materialTag] < variation) and variation or
        sounds[soundType][materialTag]
    end

    -- Set material attribute to all tagged meterial parts
    for _, materials in sounds do
        for material, _ in materials do
            if not table.find(materialTypes, material) then
                table.insert(materialTypes, material)
            end
        end
    end

    local function setupFloor()
        local taggedFloor = { workspace.Terrain }

        for _, material in materialTypes do
            local tagList = CollectionService:GetTagged(material)

            for _, part in tagList do
                part:SetAttribute("FloorMaterial", material)
                table.insert(taggedFloor, part)
            end
        end

        self.raycastParams.FilterDescendantsInstances = taggedFloor
    end

    for _, material in materialTypes do
        local materialTagGroup = TagGroup.new(material)

        materialTagGroup:StreamedIn(function()
            setupFloor()
        end)
    end

    task.spawn(setupFloor)
end

return CharacterSounds