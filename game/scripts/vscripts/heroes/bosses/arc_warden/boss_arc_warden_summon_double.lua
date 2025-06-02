LinkLuaModifier("modifier_boss_arc_warden_summon_double", "heroes/bosses/arc_warden/boss_arc_warden_summon_double", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_arc_warden_summon_double_damage_reduction", "heroes/bosses/arc_warden/boss_arc_warden_summon_double", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_arc_warden_summon_double = class(ItemBaseClass)
modifier_boss_arc_warden_summon_double = class(boss_arc_warden_summon_double)
modifier_boss_arc_warden_summon_double_damage_reduction = class(boss_arc_warden_summon_double)
-------------
function boss_arc_warden_summon_double:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local point = caster:GetAbsOrigin() 
    local duration = self:GetSpecialValueFor("duration")
    local health = self:GetSpecialValueFor("health_percent")

    local clone = CreateUnitByName("boss_arc_warden", point, true, caster, caster, caster:GetTeam())
    local hp = caster:GetMaxHealth() * (health/100)
    clone:SetBaseMaxHealth(hp)
    clone:SetMaxHealth(hp)
    clone:SetHealth(hp)

    caster:AddNewModifier(caster, self, "modifier_boss_arc_warden_summon_double_damage_reduction", { duration = duration })
    clone:AddNewModifier(caster, self, "modifier_boss_arc_warden_summon_double_damage_reduction", { duration = duration })

    clone:AddNewModifier(caster, self, "modifier_boss_arc_warden_summon_double", {}) -- No duration here

    local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_tempest_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(vfx, 0, caster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfx)

    EmitSoundOn("Hero_ArcWarden.TempestDouble", caster)

    local vo = {
        "arc_warden_arcwar_tempest_double_01",
        "arc_warden_arcwar_tempest_double_02",
        "arc_warden_arcwar_tempest_double_03",
        "arc_warden_arcwar_tempest_double_04",
        "arc_warden_arcwar_tempest_double_05",
        "arc_warden_arcwar_tempest_double_06",
    }

    EmitSoundOn(vo[RandomInt(1, #vo)], caster)
end
--------------
function modifier_boss_arc_warden_summon_double_damage_reduction:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT  
    }
end

function modifier_boss_arc_warden_summon_double_damage_reduction:GetModifierIncomingDamageConstant(event)
    if IsServer() then
        return event.damage * (self:GetAbility():GetSpecialValueFor("damage_reduction")/100)
    end
end
-------------
function modifier_boss_arc_warden_summon_double:OnCreated(props)
    if not IsServer() then return end 

    local parent = self:GetParent()

    local caster = self:GetCaster()

    local ability = self:GetAbility()

    local duration = ability:GetSpecialValueFor("duration")

    Timers:CreateTimer(duration, function()
        if parent ~= nil and not parent:IsNull() and parent:IsAlive() then
            parent:ForceKill(false)

            if caster ~= nil and not caster:IsNull() and caster:IsAlive() then
                caster:SetHealth(caster:GetMaxHealth())
                SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, caster:GetMaxHealth(), nil)
            end
        end
    end)

    EmitSoundOn("Hero_ArcWarden.TempestDouble.FP", parent)
end

function modifier_boss_arc_warden_summon_double:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local caster = self:GetCaster()

    StopSoundOn("Hero_ArcWarden.TempestDouble.FP", parent)

    if caster ~= nil and not caster:IsNull() then
        caster:RemoveModifierByName("modifier_boss_arc_warden_summon_double_damage_reduction")

        local vo = {
            "arc_warden_arcwar_tempest_double_end_01",
            "arc_warden_arcwar_tempest_double_end_02",
            "arc_warden_arcwar_tempest_double_end_03",
            "arc_warden_arcwar_tempest_double_end_04",
            "arc_warden_arcwar_tempest_double_end_05",
            "arc_warden_arcwar_tempest_double_end_06",
            "arc_warden_arcwar_tempest_double_end_07",
            "arc_warden_arcwar_tempest_double_end_08",
            "arc_warden_arcwar_tempest_double_end_09",
        }
    
        EmitSoundOn(vo[RandomInt(1, #vo)], caster)
    end
end

function modifier_boss_arc_warden_summon_double:CheckState()
    local state = {
        [MODIFIER_STATE_SILENCED] = true,
    }

    return state
end

function modifier_boss_arc_warden_summon_double:GetEffectName()
    return "particles/units/heroes/hero_arc_warden/arc_warden_tempest_buff.vpcf"
end

function modifier_boss_arc_warden_summon_double:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_boss_arc_warden_summon_double:GetStatusEffectName()
    return "particles/status_fx/status_effect_arc_warden_tempest.vpcf"
end

function modifier_boss_arc_warden_summon_double:StatusEffectPriority()
    return 10001
end