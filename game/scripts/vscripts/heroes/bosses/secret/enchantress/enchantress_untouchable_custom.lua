enchantress_untouchable_custom = class({})
LinkLuaModifier( "modifier_enchantress_untouchable_custom", "heroes/bosses/secret/enchantress/enchantress_untouchable_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_enchantress_untouchable_custom_debuff", "heroes/bosses/secret/enchantress/enchantress_untouchable_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function enchantress_untouchable_custom:GetIntrinsicModifierName()
    return "modifier_enchantress_untouchable_custom"
end

modifier_enchantress_untouchable_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_enchantress_untouchable_custom:IsHidden()
    return true
end

function modifier_enchantress_untouchable_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_enchantress_untouchable_custom:OnCreated( kv )

end

function modifier_enchantress_untouchable_custom:OnRefresh( kv )
    
end

function modifier_enchantress_untouchable_custom:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_enchantress_untouchable_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_START,
    }

    return funcs
end

function modifier_enchantress_untouchable_custom:OnAttackStart( params )
    if IsServer() then
        if params.target~=self:GetParent() then return end

        -- cancel if immune
        if params.attacker:IsMagicImmune() then return end

        -- cancel if break
        if self:GetParent():PassivesDisabled() then return end

        -- add modifier
        params.attacker:AddNewModifier(
            self:GetParent(), -- player source
            self:GetAbility(), -- ability source
            "modifier_enchantress_untouchable_custom_debuff", -- modifier name
            {  } -- kv
        )
    end
end

modifier_enchantress_untouchable_custom_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_enchantress_untouchable_custom_debuff:IsHidden()
    return false
end

function modifier_enchantress_untouchable_custom_debuff:IsDebuff()
    return true
end

function modifier_enchantress_untouchable_custom_debuff:IsStunDebuff()
    return false
end

function modifier_enchantress_untouchable_custom_debuff:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_enchantress_untouchable_custom_debuff:OnCreated( kv )
    -- references
    self.slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed" ) -- special value
    self.duration = self:GetAbility():GetSpecialValueFor( "slow_duration" ) -- special value
end

function modifier_enchantress_untouchable_custom_debuff:OnRefresh( kv )
    -- references
    self.slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed" ) -- special value
    self.duration = self:GetAbility():GetSpecialValueFor( "slow_duration" ) -- special value
end

function modifier_enchantress_untouchable_custom_debuff:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_enchantress_untouchable_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PRE_ATTACK,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_FINISHED,

        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }

    return funcs
end

function modifier_enchantress_untouchable_custom_debuff:GetModifierPreAttack( params )
    if IsServer() then
        -- record the attack that causes slow
        if not self.HasAttacked then
            self.record = params.record
        end

        -- check if start attacking another
        if params.target~=self:GetCaster() then
            self.attackOther = true
        end
    end
end

function modifier_enchantress_untouchable_custom_debuff:OnAttack( params )
    if IsServer() then
        if params.record~=self.record then return end

        -- let the debuff persists
        self:SetDuration(self.duration, true)
        self.HasAttacked = true
    end
end

function modifier_enchantress_untouchable_custom_debuff:OnAttackFinished( params )
    if IsServer() then
        if params.attacker~=self:GetParent() then return end
        
        -- destroy if cancel before attacks
        if not self.HasAttacked then
            self:Destroy()
        end

        -- destroy if finished attacking other units
        if self.attackOther then
            self:Destroy()
        end
    end
end

function modifier_enchantress_untouchable_custom_debuff:GetModifierAttackSpeedBonus_Constant()
    if IsServer() then
        if self:GetParent():GetAggroTarget()==self:GetCaster() then
            return self.slow
        else
            return 0
        end
    end

    return self.slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_enchantress_untouchable_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_enchantress/enchantress_untouchable.vpcf"
end

function modifier_enchantress_untouchable_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end