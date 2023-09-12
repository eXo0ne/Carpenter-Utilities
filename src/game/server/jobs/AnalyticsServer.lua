--[[
	AnalyticsServer.lua
	ChiefWildin
	Created: 05/28/2022
    Version: 1.0.2

	Description:
		Configures and initializes the GameAnalytics SDK.

	Documentation:
		No public API available at this time.
--]]

-- Main job table

local AnalyticsServer = {}

-- Dependencies

---@module gameanalytics-sdk
local GameAnalytics = shared("gameanalytics-sdk")

-- Constants

local GAME_KEY = ""
local SECRET_KEY = ""

-- Global variables

-- Objects

-- Private functions

-- Public functions

-- Framework callbacks

function AnalyticsServer:Run()
    if GAME_KEY ~= "" and SECRET_KEY ~= "" then
        GameAnalytics:setEnabledInfoLog(false)
        GameAnalytics:setEnabledVerboseLog(false)
        GameAnalytics:configureBuild(tostring(game.PlaceVersion))

        GameAnalytics:initialize({
            gameKey = GAME_KEY,
            secretKey = SECRET_KEY,
            automaticSendBusinessEvents = true,
            enableDebugLog = false,
        })
    else
        print("[AnalyticsServer]: Game and/or secret key not set. Analytics currently disabled.")
    end
end

return AnalyticsServer
