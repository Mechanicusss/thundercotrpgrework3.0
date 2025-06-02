LinkLuaModifier("modifier_obsidian_essence_flux", "heroes/hero_obsidian/obsidian_essence_flux", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_obsidian_essence_flux_buff", "heroes/hero_obsidian/obsidian_essence_flux", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

obsidian_essence_flux = class(ItemBaseClass)
modifier_obsidian_essence_flux = class(obsidian_essence_flux)
modifier_obsidian_essence_flux_buff = class(ItemBaseClassBuff)
-------------
function obsidian_essence_flux:GetIntrinsicModifierName()
    return "modifier_obsidian_essence_flux"
end

function modifier_obsidian_essence_flux:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
    }
    return funcs
end

function modifier_obsidian_essence_flux:OnAbilityFullyCast(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if string.match(event.ability:GetAbilityName(), "item_") then return end

    self:ProcEssenceFlux(parent, ability)
end

function modifier_obsidian_essence_flux:ProcEssenceFlux(parent, ability)
    if not RollPercentage(ability:GetSpecialValueFor("chance")) then return end
    
    local mana = parent:GetMaxMana() * (ability:GetSpecialValueFor("max_mana_restore")/100)

    parent:GiveMana(mana)
    
    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_MANA_ADD,
        parent,
        mana,
        nil
    )

    self:PlayEffects(parent)

    local buff = parent:FindModifierByName("modifier_obsidian_essence_flux_buff")
    if buff == nil then
        buff = parent:AddNewModifier(parent, ability, "modifier_obsidian_essence_flux_buff", {
            duration = ability:GetSpecialValueFor("stack_duration")
        })
    end

    if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
        buff:IncrementStackCount()
    end

    buff:ForceRefresh()
end

function modifier_obsidian_essence_flux:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_essence_effect.vpcf"
    local sound_cast = "Hero_ObsidianDestroyer.EssenceFlux.Cast"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

function modifier_obsidian_essence_flux_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_obsidian_essence_flux_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }

    return funcs
end

function modifier_obsidian_essence_flux_buff:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("spell_amp") * self:GetStackCount()
end