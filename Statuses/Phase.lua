--[[--------------------------------------------------------------------
    Grid
    Compact party and raid unit frames.
    Copyright (c) 2006-2009 Kyle Smith (Pastamancer)
    Copyright (c) 2009-2018 Phanx <addons@phanx.net>
    All rights reserved. See the accompanying LICENSE file for details.
    https://github.com/Phanx/Grid
    https://www.curseforge.com/wow/addons/grid
    https://www.wowinterface.com/downloads/info5747-Grid.html
------------------------------------------------------------------------
    Phase.lua
    Grid status module for Phase status.
----------------------------------------------------------------------]]

local _, Grid = ...
local L = Grid.L

local GridRoster = Grid:GetModule("GridRoster")

local GridStatusPhase = Grid:NewStatusModule("GridStatusPhase", "AceTimer-3.0")
GridStatusPhase.menuName = L["Phase Status"]

local PHASE_STATUS_IN = 0
local PHASE_STATUS_OUT = 1

--local UnitInPhase = UnitInPhase(unit)
--local UnitIsConnected = UnitIsConnected(unit)
--if(not isInSamePhase and UnitIsPlayer(unit) and UnitIsConnected(unit))

GridStatusSummon.defaultDB = {
    summon_status = {
        text = L["Phase Status"],
        enable = true,
        color = { r = 1, g = 1, b = 1, a = 1 },
        priority = 95,
        delay = 5,
        range = false,
        colors = {
            PHASE_STATUS_IN = { r = 0, g = 0, b = 0, a = 0, ignore = true },
            PHASE_STATUS_OUT = { r = 0, g = 255, b = 0, a = 1, ignore = true },
        },
    },
}

GridStatusSummon.options = false

local summonstatus = {
    PHASE_STATUS_IN = {
        text = "",
        icon = ""
    },
    PHASE_STATUS_OUT = {
        text = L["?"],
        icon = READY_CHECK_WAITING_TEXTURE
    },
}

local function getstatuscolor(key)
    local color = GridStatusSummon.db.profile.summon_status.colors[key]
    return color.r, color.g, color.b, color.a
end

local function setstatuscolor(key, r, g, b, a)
    local color = GridStatusSummon.db.profile.summon_status.colors[key]
    color.r = r
    color.g = g
    color.b = b
    color.a = a or 1
    color.ignore = true
end

local summonStatusOptions = {
    color = false,
    ["summon_colors"] = {
        type = "group",
        dialogInline = true,
        name = L["Color"],
        order = 86,
        args = {
            PHASE_STATUS_IN = {
                name = L["In Phase"],
                order = 100,
                type = "color",
                hasAlpha = true,
                get = function() return getstatuscolor("PHASE_STATUS_IN") end,
                set = function(_, r, g, b, a) setstatuscolor("PHASE_STATUS_IN", r, g, b, a) end,
            },
            PHASE_STATUS_OUT = {
                name = L["Out of Phase"],
                order = 100,
                type = "color",
                hasAlpha = true,
                get = function() return getstatuscolor("PHASE_STATUS_OUT") end,
                set = function(_, r, g, b, a) setstatuscolor("PHASE_STATUS_OUT", r, g, b, a) end,
            },
        },
    },
    delay = {
        name = L["Delay"],
        desc = L["Set the delay until summon results are cleared."],
        width = "double",
        type = "range", min = 0, max = 5, step = 1,
        get = function()
            return GridStatusPhase.db.profile.phase_status.delay
        end,
        set = function(_, v)
            GridStatusPhase.db.profile.phase_status.delay = v
        end,
    },
}

function GridStatusPhase:PostInitialize()
    self:RegisterStatus("phase_status", L["Phase Status"], phaseStatusOptions, true)
end

function GridStatusPhase:OnStatusEnable(status)
    if status ~= "phase_status" then return end

    self:RegisterEvent("PARTY_LEADER_CHANGED", "GroupChanged")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "GroupChanged")
    self:RegisterMessage("Grid_PartyTransition", "GroupChanged")
    self:RegisterMessage("Grid_UnitJoined")
end

function GridStatusPhase:OnStatusDisable(status)
    if sratus ~= "phase_status" then return end

    self:UnregisterEvent("PARTY_LEADER_CHANGED")
    self:UnregisterEvent("GROUP_ROSTER_UPDATE")
    self:UnregisterMessage("Grid_PartyTransition")
    self:UnregisterMessage("Grid_UnitJoined")

    self:StopTimer("ClearStatus")
    self.core:SendStatusLostAllUnits("summon_status")
end

function GridStatusPhase:GainStatus(guid, key, settings)
    local phase = phasestatus[key]
    self.core:SendStatusGained(guid, "phase_status",
        settings.priority,
        nil,
        settings.colors[key],
        phase.text,
        nil,
        nil,
        phase.icon)
end

function GridStatusPhase:UpdateAllUnits(event)
    if event then
        for guid, unitid in GridRoster:IterateRoster() do
            self:UpdateUnit(unitid)
        end
    else
        self:StopTimer("ClearStatus")
        self.core:SendStatusLostAllUnits("summon_status")
    end
end

function GridStatusPhase:UpdateUnit(unitid)
    local guid = UnitGUID(unitid)
    local UnitInPhase = UnitInPhase(unit)
    local UnitIsConnected = UnitIsConnected(unit)
    if UnitInPhase or UnitIsConnected then
        local key = PHASE_STATUS_IN
    else
        local key = PHASE_STATUS_OUT
    end
    if key then
        local settings = self.db.profile.summon_status
        self:GainStatus(guid, key, settings)
    else
        self.core:SendStatusLost(guid, "phase_status")
    end
end

function GridStatusPhase:PHASE_CHANGED()
    if self.db.profile.phase_status.enable then
        self:StopTimer("ClearStatus")
        self:UpdateAllUnits()
    end
end

function GridStatusPhase:PHASE_CHANGED(event, unitid)
    if unitid and self.db.profile.phase_status.enable then
        self:UpdateUnit(unitid)
    end
end

function GridStatusPhase:GroupChanged()
    if self.db.profile.phase_status.enable then
        self:UpdateAllUnits()
    end
end

function GridStatusPhase:Grid_UnitJoined(event, guid, unitid)
    if unitid and self.db.profile.phase_status.enable then
        self:UpdateUnit(unitid)
    end
end

function GridStatusPhase:ClearStatus()
    self.core:SendStatusLostAllUnits("phase_status")
end
