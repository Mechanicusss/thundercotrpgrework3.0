LinkLuaModifier("modifier_muerta_the_calling_custom", "heroes/hero_muerta/muerta_the_calling_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muerta_the_calling_custom_emitter", "heroes/hero_muerta/muerta_the_calling_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muerta_the_calling_custom_emitter_aura", "heroes/hero_muerta/muerta_the_calling_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muerta_the_calling_custom_ethereal", "heroes/hero_muerta/muerta_the_calling_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

muerta_the_calling_custom = class(ItemBaseClass)
modifier_muerta_the_calling_custom = class(muerta_the_calling_custom)
modifier_muerta_the_calling_custom_emitter = class(ItemBaseClass)
modifier_muerta_the_calling_custom_emitter_aura = class(ItemBaseAura)
modifier_muerta_the_calling_custom_ethereal = class(ItemBaseClassDebuff)
-------------
function muerta_the_calling_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function muerta_the_calling_custom:OnSpellStart()
    return "modifier_muerta_the_calling_custom"
end

function muerta_the_calling_custom:OnSpellStart()
    if not IsServer() then return end

    local point = self:GetCursorPosition()
    local caster = self:GetCaster()
    local ability = self

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNewModifier(caster, ability, "modifier_muerta_the_calling_custom_emitter", { 
        duration = duration
    })

    caster:EmitSound("Hero_Muerta.Revenants.Cast")
end
---------------
function modifier_muerta_the_calling_custom_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_muerta_the_calling_custom_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_muerta_the_calling_custom_emitter:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local duration = ability:GetSpecialValueFor("duration")
    local radius = ability:GetSpecialValueFor("radius")

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_muerta/muerta_calling_aoe.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(self.vfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 1, Vector(radius, radius, radius))
    ParticleManager:SetParticleControl(self.vfx, 2, Vector(duration, 0, 0))

    EmitSoundOn("Hero_Muerta.Revenants", parent)
end

function modifier_muerta_the_calling_custom_emitter:OnDestroy()
    if not IsServer() then return end

    EmitSoundOn("Hero_Muerta.Revenants.End", self:GetParent())

    if self:GetParent():IsAlive() then
        self:GetParent():ForceKill(false)
    end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_muerta_the_calling_custom_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end

function modifier_muerta_the_calling_custom_emitter:IsAura()
  return true
end

function modifier_muerta_the_calling_custom_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_muerta_the_calling_custom_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_muerta_the_calling_custom_emitter:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_muerta_the_calling_custom_emitter:GetModifierAura()
    return "modifier_muerta_the_calling_custom_emitter_aura"
end

function modifier_muerta_the_calling_custom_emitter:GetAuraEntityReject(ent) 
    if ent:GetTeam() == self:GetCaster():GetTeam() and self:GetCaster() ~= ent then
        return true
    end
    
    return false
end
-------------------------
function modifier_muerta_the_calling_custom_emitter_aura:IsDebuff()
    return self:GetCaster() ~= self:GetParent()
end

function modifier_muerta_the_calling_custom_emitter_aura:CheckState()
    if self:GetCaster() == self:GetParent() then return end

    return {
        [MODIFIER_STATE_SILENCED] = true,
    }
end

function modifier_muerta_the_calling_custom_emitter_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_muerta_the_calling_custom_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    if self:GetCaster() == self:GetParent() then return end
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_muerta_the_calling_custom_emitter_aura:OnCreated()
    if not IsServer() then return end
    if self:GetCaster() == self:GetParent() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    local interval = ability:GetSpecialValueFor("interval")

    EmitSoundOn("Hero_Muerta.Revenants.Silence", parent)

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_muerta/muerta_calling_impact.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(self.vfx, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(self.vfx)

    self.count = 0

    self.shardTick = 0

    self:StartIntervalThink(interval)
end

function modifier_muerta_the_calling_custom_emitter_aura:OnIntervalThink()
    if self:GetCaster() == self:GetParent() then return end
    local caster = self:GetCaster()

    EmitSoundOn("Hero_Muerta.Revenants.Damage.Creep", self:GetParent())

    local damage = self:GetAbility():GetSpecialValueFor("damage") + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100))

    if caster:HasModifier("modifier_item_aghanims_shard") and self.shardTick > 0 then
        damage = damage * (1+((self:GetAbility():GetSpecialValueFor("damage_increase_per_tick")/100) * self.shardTick))
    end

    ApplyDamage({
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })

    self.shardTick = self.shardTick + 1

    local talent = caster:FindAbilityByName("talent_muerta_2")
    if talent ~= nil and talent:GetLevel() > 0 then
        if not self:GetParent():HasModifier("modifier_muerta_the_calling_custom_ethereal") then
            self.count = self.count + 1
            if self.count >= talent:GetSpecialValueFor("time_limit") then
                self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_muerta_the_calling_custom_ethereal", {
                    duration = talent:GetSpecialValueFor("duration")
                })

                self.count = 0
            end
        end
    end
end

function modifier_muerta_the_calling_custom_emitter_aura:GetEffectName()
    if self:GetCaster() == self:GetParent() then return "particles/units/heroes/hero_muerta/muerta_calling_flames_ethereal.vpcf" end

    return "particles/units/heroes/hero_muerta/muerta_calling_debuff_slow.vpcf"
end
--------------------
function modifier_muerta_the_calling_custom_ethereal:GetEffectName()
    return "particles/units/heroes/hero_muerta/muerta_calling_flames_ethereal.vpcf"
end

function modifier_muerta_the_calling_custom_ethereal:GetStatusEffectName()
    return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_muerta_the_calling_custom_ethereal:GetEffectAttachType()
    return PATTACH_POINT_FOLLOW
end

function modifier_muerta_the_calling_custom_ethereal:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    }
end

function modifier_muerta_the_calling_custom_ethereal:GetAbsoluteNoDamagePhysical()
    if self:GetCaster() == self:GetParent() then return 1
    else return nil end
end

function modifier_muerta_the_calling_custom_ethereal:GetModifierMagicalResistanceDecrepifyUnique( params )
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_muerta_2")
    if talent ~= nil and talent:GetLevel() > 0 then
        return talent:GetSpecialValueFor("magic_amp_pct") * (-1)
    end
end

function modifier_muerta_the_calling_custom_ethereal:CheckState()
    return
        {
            [MODIFIER_STATE_DISARMED] = true,
            [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        }
end

-- IntervalThink to remove active if magic immune (so you can't stack the two)
-- Thanks to dota imba for the ethereal logic!
function modifier_muerta_the_calling_custom_ethereal:OnCreated()
    if not IsServer() then return end
    EmitSoundOn("Hero_Pugna.Decrepify", self:GetParent())
    self:StartIntervalThink(FrameTime())
end

function modifier_muerta_the_calling_custom_ethereal:OnIntervalThink()
    if not IsServer() then return end
    if self:GetParent():IsMagicImmune() then self:Destroy() end
end