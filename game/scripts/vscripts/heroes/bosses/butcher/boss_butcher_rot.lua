boss_butcher_rot = class({})
modifier_boss_butcher_rot_thinker = class({})
LinkLuaModifier( "modifier_boss_butcher_rot", "heroes/bosses/butcher/boss_butcher_rot" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_butcher_rot_effect", "heroes/bosses/butcher/boss_butcher_rot" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_butcher_rot_debuff", "heroes/bosses/butcher/boss_butcher_rot" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_butcher_rot_thinker", "heroes/bosses/butcher/boss_butcher_rot" ,LUA_MODIFIER_MOTION_NONE )

function boss_butcher_rot:GetIntrinsicModifierName()
    return "modifier_boss_butcher_rot_thinker"
end

function modifier_boss_butcher_rot_thinker:IsHidden() return true end
function modifier_boss_butcher_rot_thinker:IsPurgable() return false end
function modifier_boss_butcher_rot_thinker:RemoveOnDeath() return false end

function modifier_boss_butcher_rot_thinker:OnCreated()
    if not IsServer() then return end
    local unit = self:GetParent()
    local rot = unit:FindAbilityByName("boss_butcher_rot")
    if rot and not rot:GetToggleState() then
       Timers:CreateTimer(1.0, function()
            rot:ToggleAbility()
        end)
    end
end

function boss_butcher_rot:OnToggle()
    -- Apply the rot modifier if the toggle is on
    if self:GetToggleState() then

        self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_boss_butcher_rot", nil )

        if not self:GetCaster():IsChanneling() then
            self:GetCaster():StartGesture( ACT_DOTA_CAST_ABILITY_ROT )
        end
    else
        -- Remove it if it is off
        local hRotBuff = self:GetCaster():FindModifierByName( "modifier_boss_butcher_rot" )
        if hRotBuff ~= nil then
            hRotBuff:Destroy()
        end
    end
end

local ItemBaseToggleClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local BaseClassDebuff = {
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end
}

modifier_boss_butcher_rot = class(ItemBaseToggleClass)
modifier_boss_butcher_rot_debuff = class(BaseClassDebuff)

function modifier_boss_butcher_rot:OnCreated(table)
    if self:GetParent() ~= self:GetCaster() then return end
    if IsServer() then
        local radius = self:GetAbility():GetSpecialValueFor("radius")
        self.damage = self:GetAbility():GetSpecialValueFor("damage")
        self.tick = self:GetAbility():GetSpecialValueFor("tick_rate")
        self.nfx = ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_immortal_arm/pudge_immortal_arm_rot.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
        ParticleManager:SetParticleControlEnt(self.nfx, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
        ParticleManager:SetParticleControl(self.nfx, 1, Vector(radius,radius,radius))
    end
end

function modifier_boss_butcher_rot:OnRemoved()
    if IsServer() then
        ParticleManager:DestroyParticle(self.nfx, true)
        ParticleManager:ReleaseParticleIndex(self.nfx)
    end
end

function modifier_boss_butcher_rot:IsAura()
    return true
end

function modifier_boss_butcher_rot:GetAuraDuration()
    return 0.5
end

function modifier_boss_butcher_rot:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_boss_butcher_rot:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_boss_butcher_rot:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_boss_butcher_rot:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_boss_butcher_rot:GetModifierAura()
    return "modifier_boss_butcher_rot_effect"
end

modifier_boss_butcher_rot_effect = class({})
function modifier_boss_butcher_rot_effect:OnCreated(table)
    if IsServer() then
        self.tick = self:GetAbility():GetSpecialValueFor("tick_rate")
        self:StartIntervalThink(self.tick)
    end

    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.slow = self:GetAbility():GetLevelSpecialValueFor("slow", (self:GetAbility():GetLevel() - 1))
        self.healingReduction = self:GetAbility():GetLevelSpecialValueFor("healing_reduction", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_boss_butcher_rot_effect:OnIntervalThink()
    if IsServer() then
        if self:GetCaster():FindModifierByName("modifier_boss_butcher_rot") then
            self.damage = self:GetCaster():FindModifierByName("modifier_boss_butcher_rot").damage

            local damage = {
                victim = self:GetParent(),
                attacker = self:GetCaster(),
                damage = self.damage*self.tick,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            }

            ApplyDamage(damage)

            local unit = self:GetParent()
            local caster = self:GetCaster()

            local debuff = unit:FindModifierByNameAndCaster("modifier_boss_butcher_rot_debuff", caster)
            local stacks = unit:GetModifierStackCount("modifier_boss_butcher_rot_debuff", caster)

            if not debuff then
                unit:AddNewModifier(caster, self:GetAbility(), "modifier_boss_butcher_rot_debuff", { duration = 5.0 })

                unit:SetModifierStackCount("modifier_boss_butcher_rot_debuff", caster, 1)
            else
                unit:SetModifierStackCount("modifier_boss_butcher_rot_debuff", caster, (stacks + 1))
                debuff:ForceRefresh()
            end
        end
    end
end

function modifier_boss_butcher_rot_effect:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }
    return funcs
end

function modifier_boss_butcher_rot_effect:GetModifierMoveSpeedBonus_Percentage()    
    if not self:GetAbility() or self:GetAbility():IsNull() then return end

    return self.slow or self:GetAbility():GetLevelSpecialValueFor("slow", (self:GetAbility():GetLevel() - 1))
end

function modifier_boss_butcher_rot_effect:GetModifierHealAmplify_PercentageTarget()    
    if not self:GetAbility() or self:GetAbility():IsNull() then return end

    return self.healingReduction or self:GetAbility():GetLevelSpecialValueFor("healing_reduction", (self:GetAbility():GetLevel() - 1))
end

function modifier_boss_butcher_rot_effect:GetModifierHPRegenAmplify_Percentage()    
    if not self:GetAbility() or self:GetAbility():IsNull() then return end

    return self.healingReduction or self:GetAbility():GetLevelSpecialValueFor("healing_reduction", (self:GetAbility():GetLevel() - 1))
end

function modifier_boss_butcher_rot_effect:GetModifierLifestealRegenAmplify_Percentage()    
    if not self:GetAbility() or self:GetAbility():IsNull() then return end

    return self.healingReduction or self:GetAbility():GetLevelSpecialValueFor("healing_reduction", (self:GetAbility():GetLevel() - 1))
end

function modifier_boss_butcher_rot_effect:GetModifierSpellLifestealRegenAmplify_Percentage()    
    if not self:GetAbility() or self:GetAbility():IsNull() then return end

    return self.healingReduction or self:GetAbility():GetLevelSpecialValueFor("healing_reduction", (self:GetAbility():GetLevel() - 1))
end

function modifier_boss_butcher_rot_effect:GetEffectName()
    return "particles/econ/items/pudge/pudge_immortal_arm/pudge_immortal_arm_rot_recipient.vpcf"
end

---------

function modifier_boss_butcher_rot_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }
    return funcs
end

function modifier_boss_butcher_rot_debuff:GetModifierIncomingDamage_Percentage()    
    return (self:GetStackCount() * 0.2)
end