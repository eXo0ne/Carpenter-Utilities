--[[
    Author: eXo0ne
    Module: SoundPlayer.lua
    Created: 09/16/2023
--]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Dependencies
local AnimNation = shared("AnimNation") ---@module AnimNation

-- Module Declaration
local SoundPlayer = {}

-- Constants
local YIELD_TIMEOUT = 5

-- Global Variables
local soundCache = {}

-- Objects

-- Private Functions
local function setupSound(sound: Sound)
    if sound:IsA("Sound") then
        sound:SetAttribute("OriginalVolume", sound.Volume)
        soundCache[sound.Name] = sound
    end
end

-- Public Functions
function SoundPlayer:GetSound(soundName: string, shouldYield: boolean?)
    local sound = soundCache[soundName]

    if sound then
        return sound

    elseif shouldYield then
        local timerStart = os.clock()

        while os.clock() - timerStart < YIELD_TIMEOUT do
            task.wait()

            sound = soundCache[soundName]

            if sound then
                break
            end
        end

        return sound
    end
end

function SoundPlayer:PlaySound(soundName: string, fadeIn: number?, shouldYield: boolean?)
    local sound = self:GetSound(soundName, shouldYield)

    if not sound then
        warn(`Sound named {soundName or ""} not found`)
        return
    end

    if not sound.Loaded then
        warn(`Sound named {soundName} not loaded`)
        return
    end

    if fadeIn then
        sound.Volume = 0
        AnimNation.tween(sound, TweenInfo.new(fadeIn), { Volume = sound:GetAttribute("OriginalVolume") })
    else
        sound.Volume = sound:GetAttribute("OriginalVolume")
    end

    sound:Play()

    return sound
end

function SoundPlayer:PlaySoundClone(soundName: string, fadeIn: number?, position: Vector3?, shouldYield: boolean?, properties: {}?)
    local sound = self:GetSound(soundName, shouldYield)

    if not sound then
        warn(`Sound named {soundName or ""} not found`)
        return
    end

    if not sound.Loaded then
        warn(`Sound named {soundName} not loaded`)
        return
    end

    sound = sound:Clone()
    
    properties = properties or {}

    for property, value in pairs(properties) do
        sound[property] = value
    end

    if fadeIn then
        sound.Volume = 0
        AnimNation.tween(sound, TweenInfo.new(fadeIn), { Volume = properties.Volume or sound:GetAttribute("OriginalVolume") })
    else
        sound.Volume = properties.Volume or sound:GetAttribute("OriginalVolume")
    end

    if position then
        local soundAttachment = Instance.new("Attachment", workspace.Terrain)
        soundAttachment.Position = position
        sound.Parent = soundAttachment
    else
        sound.Parent = ReplicatedStorage
    end

    sound:Play()

    return sound
end

function SoundPlayer:StopSound(soundName: string, fadeOut: number?)
    local sound = self:GetSound(soundName)

    if not sound then
        warn(`Sound named {soundName or ""} not found`)
        return
    end

    if not sound.Playing then
        return
    end

    if fadeOut then
        AnimNation.tween(sound, TweenInfo.new(fadeOut), { Volume = 0 }):AndThen(function()
            sound:Stop()
            sound.Volume = sound:GetAttribute("OriginalVolume")
        end)
        
        return
    end

    sound:Stop()

    return sound
end

function SoundPlayer:AdjustVolume(soundName: string, volume: number?, fade: number?, shouldYield: boolean?)
    local sound = self:GetSound(soundName, shouldYield)

    if not sound then
        warn(`Sound named {soundName} not found`)
        return
    end

    if fade then
        AnimNation.tween(sound, TweenInfo.new(fade), { Volume = volume or sound:GetAttribute("OriginalVolume") })
    else
        sound.Volume = volume or sound:GetAttribute("OriginalVolume")
    end
end

-- Job Initialization
function SoundPlayer:Run()
    for _, sound in SoundService:GetDescendants() do
        setupSound(sound)
    end

    SoundService.DescendantAdded:Connect(setupSound)
end

return SoundPlayer
