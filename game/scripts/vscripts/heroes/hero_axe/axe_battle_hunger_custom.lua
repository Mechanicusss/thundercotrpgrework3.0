LinkLuaModifier("modifier_axe_battle_hunger_custom", "heroes/hero_axe/axe_battle_hunger_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_battle_hunger_custom_active_debuff", "heroes/hero_axe/axe_battle_hunger_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_battle_hunger_custom_cooldown", "heroes/hero_axe/axe_battle_hunger_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassCd = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

axe_battle_hunger_custom = class(ItemBaseClass)
modifier_axe_battle_hunger_custom = class(axe_battle_hunger_custom)
modifier_axe_battle_hunger_custom_active_debuff = class(ItemBaseClassDebuff)
modifier_axe_battle_hunger_custom_cooldown = class(ItemBaseClassCd)
-------------
function axe_battle_hunger_custom:GetIntrinsicModifierName()
    return "modifier_axe_battle_hunger_custom"
end

function modifier_axe_battle_hunger_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_axe_battle_hunger_custom:OnTakeDamage( params )
    if IsServer() then
        if params.attacker ~= self:GetCaster() then return end
        if self:GetCaster():PassivesDisabled() then return end
        if params.attacker:GetTeamNumber()==params.unit:GetTeamNumber() then return end
        if params.unit:IsOther() or params.unit:IsBuilding() then return end
        if not IsCreepTCOTRPG(params.unit) and not IsBossTCOTRPG(params.unit) then return end
        if params.attacker:IsIllusion() then return end

        -- roll dice
        local ability = self:GetAbility()

        if params.inflictor == ability then return end 
        
        local caster = self:GetCaster()
        local victim = params.unit

        if not ability:IsCooldownReady() or victim:HasModifier("modifier_axe_battle_hunger_custom_active_debuff") then return end

        local debuff = victim:FindModifierByName("modifier_axe_battle_hunger_custom_active_debuff")
        if not debuff then
            debuff = victim:AddNewModifier(caster, ability, "modifier_axe_battle_hunger_custom_active_debuff", {
                duration = ability:GetSpecialValueFor("duration")
            })
            EmitSoundOn("Hero_Axe.Battle_Hunger", victim)
        end

        if debuff then
            debuff:ForceRefresh()
        end

        ability:UseResources(false, false, false, true)
    end
end
------------
function modifier_axe_battle_hunger_custom_active_debuff:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    self.damageTable = {
        victim = parent,
        attacker = caster,
        ability = ability,
        damage_type = ability:GetAbilityDamageType()
    }

    self:StartIntervalThink(0.5)
end

function modifier_axe_battle_hunger_custom_active_debuff:OnIntervalThink()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    local damage = parent:GetHealth() * (ability:GetSpecialValueFor("current_hp_damage")/100)

    self.damageTable.damage = damage*0.5

    ApplyDamage(self.damageTable)
end

function modifier_axe_battle_hunger_custom_active_debuff:GetEffectName()
    return "particles/units/heroes/hero_axe/axe_battle_hunger.vpcf"
end

function modifier_axe_battle_hunger_custom_active_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_axe_battle_hunger_custom_active_debuff:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_axe_battle_hunger_custom_active_debuff:OnTakeDamage( params )
    if IsServer() then
        if params.attacker ~= self:GetCaster() then return end
        if self:GetCaster():PassivesDisabled() then return end
        if params.attacker:GetTeamNumber()==params.unit:GetTeamNumber() then return end
        if params.unit:IsOther() or params.unit:IsBuilding() then return end
        if not IsCreepTCOTRPG(params.unit) and not IsBossTCOTRPG(params.unit) then return end
        if params.attacker:IsIllusion() then return end

        -- roll dice
        local ability = self:GetAbility()
        local caster = self:GetCaster()
        
        local healing = params.damage * (ability:GetSpecialValueFor("heal_pct")/100)
        caster:Heal(healing, ability)

        SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,caster,healing,nil)
    end
end

function modifier_axe_battle_hunger_custom_active_debuff:GetModifierIncomingDamage_Percentage( params )
    if params.attacker ~= self:GetCaster() then return end

    return self:GetAbility():GetSpecialValueFor("dmg_pct")
end