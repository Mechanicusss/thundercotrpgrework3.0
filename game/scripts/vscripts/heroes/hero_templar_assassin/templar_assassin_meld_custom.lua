LinkLuaModifier("modifier_templar_assassin_meld_custom", "heroes/hero_templar_assassin/templar_assassin_meld_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_assassin_meld_custom_crit_stacks", "heroes/hero_templar_assassin/templar_assassin_meld_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

templar_assassin_meld_custom = class(ItemBaseClass)
modifier_templar_assassin_meld_custom = class(templar_assassin_meld_custom)
modifier_templar_assassin_meld_custom_crit_stacks = class(ItemBaseClassDebuff)
-------------
function templar_assassin_meld_custom:GetIntrinsicModifierName()
    return "modifier_templar_assassin_meld_custom"
end

function modifier_templar_assassin_meld_custom:OnCreated( kv )
    -- references
    self.crit_chance = self:GetAbility():GetSpecialValueFor( "crit_chance" )
    self.crit_bonus = self:GetAbility():GetSpecialValueFor( "crit_damage" )
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
end

function modifier_templar_assassin_meld_custom:OnRefresh( kv )
    -- references
    self.crit_chance = self:GetAbility():GetSpecialValueFor( "crit_chance" )
    self.crit_bonus = self:GetAbility():GetSpecialValueFor( "crit_damage" )
end

function modifier_templar_assassin_meld_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }

    return funcs
end

function modifier_templar_assassin_meld_custom:GetModifierPreAttack_CriticalStrike( params )
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        local cc = self.crit_chance

        if RollPercentage(cc) then
            self.record = params.record

            local stacks = 0
            local debuff = params.target:FindModifierByName("modifier_templar_assassin_meld_custom_crit_stacks")
            if debuff ~= nil then
                stacks = debuff:GetStackCount()
            end

            EmitSoundOn("Hero_TemplarAssassin.Meld.Attack", params.target)

            local debuff = params.target:FindModifierByName("modifier_templar_assassin_meld_custom_crit_stacks")
            if debuff == nil then
                debuff = params.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_templar_assassin_meld_custom_crit_stacks", {
                    duration = self:GetAbility():GetSpecialValueFor("duration")
                })
            end

            if debuff ~= nil then
                if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
                    debuff:IncrementStackCount()
                end

                debuff:ForceRefresh()
            end

            return self.crit_bonus + (stacks * self:GetAbility():GetSpecialValueFor("crit_damage_stack"))
        end
    end
end

function modifier_templar_assassin_meld_custom:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end
end
----------
function modifier_templar_assassin_meld_custom_crit_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_templar_assassin_meld_custom_crit_stacks:OnCreated()
    if not IsServer() then return end

    local target = self:GetParent()

    local particle_cast = "particles/units/heroes/hero_templar_assassin/templar_assassin_meld_armor.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    self:AddParticle(self.effect_cast, false, false, -1, true, false)
end

function modifier_templar_assassin_meld_custom_crit_stacks:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_templar_assassin_meld_custom_crit_stacks:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }

    return funcs
end

function modifier_templar_assassin_meld_custom_crit_stacks:GetModifierPhysicalArmorBonus()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_templar_assassin_meld_custom_crit_stacks:OnTooltip()
    return (self:GetStackCount() * self:GetAbility():GetSpecialValueFor("crit_damage_stack")) + self:GetAbility():GetSpecialValueFor("crit_damage")
end