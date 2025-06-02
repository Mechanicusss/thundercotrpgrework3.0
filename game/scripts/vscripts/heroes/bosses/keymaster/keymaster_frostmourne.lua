LinkLuaModifier("modifier_keymaster_frostmourne", "heroes/bosses/keymaster/keymaster_frostmourne", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_keymaster_frostmourne_debuff", "heroes/bosses/keymaster/keymaster_frostmourne", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_keymaster_frostmourne_silenced", "heroes/bosses/keymaster/keymaster_frostmourne", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_keymaster_frostmourne_buff", "heroes/bosses/keymaster/keymaster_frostmourne", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

keymaster_frostmourne = class(ItemBaseClass)
modifier_keymaster_frostmourne = class(keymaster_frostmourne)
modifier_keymaster_frostmourne_debuff = class(ItemBaseClassDebuff)
modifier_keymaster_frostmourne_silenced = class(ItemBaseClassDebuff)
modifier_keymaster_frostmourne_buff = class(ItemBaseClassBuff)
-------------
function keymaster_frostmourne:GetIntrinsicModifierName()
    return "modifier_keymaster_frostmourne"
end

function modifier_keymaster_frostmourne:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_keymaster_frostmourne:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    local target = event.unit 

    local debuff = target:FindModifierByName("modifier_keymaster_frostmourne_debuff")
    if not debuff then
        debuff = target:AddNewModifier(parent, self:GetAbility(), "modifier_keymaster_frostmourne_debuff", {
            duration = self:GetAbility():GetSpecialValueFor("duration")
        })
    end 

    if debuff then
        if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        if debuff:GetStackCount() >= self:GetAbility():GetSpecialValueFor("max_stacks") and not target:HasModifier("modifier_keymaster_frostmourne_silenced") then
            EmitSoundOn("Hero_Abaddon.Curse.Proc", target)
            target:AddNewModifier(parent, self:GetAbility(), "modifier_keymaster_frostmourne_silenced", {
                duration = self:GetAbility():GetSpecialValueFor("silence_duration")
            })
        end

        debuff:ForceRefresh()
    end

    if target:HasModifier("modifier_keymaster_frostmourne_debuff") then
        local buff = parent:FindModifierByName("modifier_keymaster_frostmourne_buff")
        if not buff then
            buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_keymaster_frostmourne_buff", {
                duration = self:GetAbility():GetSpecialValueFor("duration")
            })
        end 

        if buff then
            if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
                buff:IncrementStackCount()
            end

            buff:ForceRefresh()
        end
    end
end
--------------
function modifier_keymaster_frostmourne_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }
end

function modifier_keymaster_frostmourne_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_slow_per_stack") * self:GetStackCount()
end

function modifier_keymaster_frostmourne_debuff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_slow_per_stack") * self:GetStackCount()
end

function modifier_keymaster_frostmourne_debuff:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    self.counter = ParticleManager:CreateParticle( "particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, parent )
    ParticleManager:SetParticleControl( self.counter, 0, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.counter, 1, Vector(0, 1, 0) )
end

function modifier_keymaster_frostmourne_debuff:OnRefresh()
    if not IsServer() then return end 

    ParticleManager:SetParticleControl( self.counter, 1, Vector(0, self:GetStackCount(), 0) )
end

function modifier_keymaster_frostmourne_debuff:OnRemoved()
    if not IsServer() then return end 

    if self.counter ~= nil then
        ParticleManager:DestroyParticle(self.counter, true)
        ParticleManager:ReleaseParticleIndex(self.counter)
    end
end
-----------------
function modifier_keymaster_frostmourne_silenced:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

function modifier_keymaster_frostmourne_silenced:GetEffectName()
    return "particles/units/heroes/hero_abaddon/abaddon_curse_frostmourne_debuff.vpcf"
end

function modifier_keymaster_frostmourne_silenced:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
--------------
function modifier_keymaster_frostmourne_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }
end

function modifier_keymaster_frostmourne_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed_per_stack") * self:GetStackCount()
end