LinkLuaModifier("modifier_aghanim_tower_capture", "heroes/hero_fenrir/aghanim_tower_capture.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

aghanim_tower_capture = class(ItemBaseClass)
modifier_aghanim_tower_capture = class(aghanim_tower_capture)
-------------
function aghanim_tower_capture:OnSpellStart()
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.target = self:GetCursorTarget()
    self.targetNumber = tonumber(self.target:GetName():sub(-1))

    if self:AreAllCaptured() then
        self.caster:Stop()
    end

    EmitSoundOn("LotusPool.Channel", self.target)
end

function aghanim_tower_capture:AreAllCaptured()
    return _G.AghanimTowers[1] and _G.AghanimTowers[2] and _G.AghanimTowers[3] and _G.AghanimTowers[4] and _G.AghanimTowers[5]
end

function aghanim_tower_capture:OnChannelFinish(bInterrupted)
    if not IsServer() then return end

    StopSoundOn("LotusPool.Channel", self.target)

    if bInterrupted or self:AreAllCaptured() then return end 

    if self.targetNumber == 1 and not _G.AghanimTowers[1] and not _G.AghanimTowers[2] and not _G.AghanimTowers[3] and not _G.AghanimTowers[4] and not _G.AghanimTowers[5] then
        _G.AghanimTowers[1] = true
    elseif self.targetNumber == 2 and _G.AghanimTowers[1] then
        _G.AghanimTowers[2] = true
    elseif self.targetNumber == 3 and _G.AghanimTowers[2] then
        _G.AghanimTowers[3] = true
    elseif self.targetNumber == 4 and _G.AghanimTowers[3] then
        _G.AghanimTowers[4] = true
    elseif self.targetNumber == 5 and _G.AghanimTowers[4] then
        _G.AghanimTowers[5] = true
    else
        _G.AghanimTowers = {
            [1] = false,
            [2] = false,
            [3] = false,
            [4] = false,
            [5] = false
        }

        DisplayError(self.caster:GetPlayerID(), "#aghanim_incorrect_sequence")

        local aghanimTowers = Entities:FindAllByModel("models/props_structures/radiant_checkpoint_01.vmdl")
        for _,tower in ipairs(aghanimTowers) do
            tower:SetSkin(0)
        end

        return
    end

    if self:AreAllCaptured() then
        local spawn = Entities:FindByName(nil, "spawn_boss_aghanim")
        if not spawn or spawn == nil then return end

        local portal = _G.AghanimGateUnit
        if portal ~= nil then
            portal:SetModel("models/props_structures/dungeon_temple_portal001.vmdl")
            portal:RemoveNoDraw()

            local particle = ParticleManager:CreateParticle("particles/econ/items/underlord/underlord_2021_immortal/underlord_2021_immortal_portal_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, portal)   
            ParticleManager:SetParticleControlEnt(particle, 0, portal, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", portal:GetAbsOrigin(), false)
            ParticleManager:ReleaseParticleIndex(particle)

            EmitSoundOn("Hero_Underlord.Portal.Spawn", portal)
            AddFOWViewer(DOTA_TEAM_GOODGUYS, portal:GetAbsOrigin(), 300, 99999, false)
        end

        local aghanimUnit = CreateUnitByName("npc_dota_boss_aghanim", spawn:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
        aghanimUnit:AddNewModifier(aghanimUnit, nil, "modifier_unit_boss_2", {})

        GameRules:SendCustomMessage("<font color='lightblue'>— YOU HAVE BEEN GRANTED AN AUDIENCE WITH AGHANIM —</font>", 0, 0)
        EmitGlobalSound("TCOTRPG.Aghanim.Greetings.Intro")
    end

    local particle = ParticleManager:CreateParticle("particles/creatures/aghanim/portal_summon_a.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target)   
    ParticleManager:SetParticleControlEnt(particle, 0, self.target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.target:GetAbsOrigin(), false)
    ParticleManager:ReleaseParticleIndex(particle)

    self.target:SetSkin(1)
    EmitSoundOn("ContinuumDevice.Activate", self.target)
end