LinkLuaModifier("modifier_twin_gate_portal_warp_custom", "heroes/hero_fenrir/twin_gate_portal_warp_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

twin_gate_portal_warp_custom = class(ItemBaseClass)
modifier_twin_gate_portal_warp_custom = class(twin_gate_portal_warp_custom)
-------------
function twin_gate_portal_warp_custom:OnSpellStart()
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.target = self:GetCursorTarget()

    local destinationPortalIndex = self.target:Attribute_GetIntValue("target_gate", 0)

    self.destinationPortal = Entities:FindByName(nil, tostring("npc_dota_tcot_portal"..destinationPortalIndex))

    if not self.destinationPortal or self.destinationPortal:IsNull() then return end 

    self.target:StartGesture(ACT_DOTA_CHANNEL_ABILITY_1)
    self.destinationPortal:StartGesture(ACT_DOTA_CHANNEL_ABILITY_1)
    
    self.destination = self.destinationPortal:GetAbsOrigin()

    EmitSoundOn("TwinGate.Channel", self.target)
end

function twin_gate_portal_warp_custom:OnChannelFinish(bInterrupted)
    if not IsServer() then return end

    if not self.destinationPortal or self.destinationPortal:IsNull() then return end 
    if not self.target or self.target:IsNull() then return end 

    StopSoundOn("TwinGate.Channel", self.target)

    self.target:RemoveGesture(ACT_DOTA_CHANNEL_ABILITY_1)
    self.destinationPortal:RemoveGesture(ACT_DOTA_CHANNEL_ABILITY_1)

    if bInterrupted then 
        return 
    end

    FindClearSpaceForUnit(self.caster, self.destination, false)
    CenterCameraOnUnit(self.caster:GetPlayerID(), self.caster)
    self.caster:Stop()

    EmitSoundOn("TwinGate.Teleport.Appear", self.caster)
    EmitSoundOn("TwinGate.Channel.End", self.destinationPortal)
end