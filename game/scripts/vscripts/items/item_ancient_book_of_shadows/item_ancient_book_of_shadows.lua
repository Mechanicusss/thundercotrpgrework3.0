LinkLuaModifier("modifier_item_ancient_book_of_shadows", "items/item_ancient_book_of_shadows/item_ancient_book_of_shadows.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_book_of_shadows_burn_debuff", "items/item_ancient_book_of_shadows/item_ancient_book_of_shadows.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_book_of_shadows_aura", "items/item_ancient_book_of_shadows/item_ancient_book_of_shadows.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_book_of_shadows_curse", "items/item_ancient_book_of_shadows/item_ancient_book_of_shadows.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_book_of_shadows_sap_slow", "items/item_ancient_book_of_shadows/item_ancient_book_of_shadows.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_ancient_book_of_shadows = class(ItemBaseClass)
item_ancient_book_of_shadows_2 = item_ancient_book_of_shadows
item_ancient_book_of_shadows_3 = item_ancient_book_of_shadows
item_ancient_book_of_shadows_4 = item_ancient_book_of_shadows
item_ancient_book_of_shadows_5 = item_ancient_book_of_shadows
modifier_item_ancient_book_of_shadows = class(ItemBaseClass)
modifier_item_ancient_book_of_shadows_burn_debuff = class(ItemBaseClassDebuff)
modifier_item_ancient_book_of_shadows_aura = class(ItemBaseClassDebuff)
modifier_item_ancient_book_of_shadows_sap_slow = class(ItemBaseClassDebuff)
modifier_item_ancient_book_of_shadows_curse = class(ItemBaseClassBuff)
-------------
function item_ancient_book_of_shadows:GetIntrinsicModifierName()
    return "modifier_item_ancient_book_of_shadows"
end
-------------
function modifier_item_ancient_book_of_shadows:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_EXTRA_MANA_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST 
    }
end

function modifier_item_ancient_book_of_shadows:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_ancient_book_of_shadows:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_damage")
end

function modifier_item_ancient_book_of_shadows:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_ancient_book_of_shadows:GetModifierExtraManaPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_pct")
end

function modifier_item_ancient_book_of_shadows:OnTakeDamage(event)
    if not IsServer() then return end
    
    local damageType = event.damage_type

    if event.attacker ~= self:GetParent() or event.attacker == event.unit then return end
    if damageType ~= DAMAGE_TYPE_MAGICAL then return end
    if event.inflictor ~= nil then
        if event.inflictor == self:GetAbility() or string.find(event.inflictor:GetAbilityName(), "diabolic_edict") then return end
        if string.match(event.inflictor:GetAbilityName(), "item_") then return end
    end

    local victim = event.unit

    if not self:GetAbility():IsCooldownReady() then return end

    self:GetAbility():UseResources(false, false, false, true)

    --- Burn
    local debuff = victim:FindModifierByName("modifier_item_ancient_book_of_shadows_burn_debuff")
    if debuff == nil then
        debuff = victim:AddNewModifier(event.attacker, self:GetAbility(), "modifier_item_ancient_book_of_shadows_burn_debuff", {
            duration = self:GetAbility():GetSpecialValueFor("burn_duration")
        })
    end

    if debuff ~= nil then
        if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("burn_max_stacks") then
            debuff:IncrementStackCount()
        end
        debuff:ForceRefresh()
    end
end

function modifier_item_ancient_book_of_shadows:IsAura()
    return true
end

function modifier_item_ancient_book_of_shadows:GetAuraSearchType()
    return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_CREEP)
end

function modifier_item_ancient_book_of_shadows:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_ancient_book_of_shadows:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_ancient_book_of_shadows:GetModifierAura()
    return "modifier_item_ancient_book_of_shadows_aura"
end

function modifier_item_ancient_book_of_shadows:GetAuraEntityReject(target)
    return false
end

function modifier_item_ancient_book_of_shadows:OnAbilityFullyCast(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    local inflictor = event.ability 

    if string.match(inflictor:GetAbilityName(), "item_") then return end 

    local buff = parent:FindModifierByName("modifier_item_ancient_book_of_shadows_curse")
    if buff == nil then
        buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_ancient_book_of_shadows_curse", {
            duration = self:GetAbility():GetSpecialValueFor("curse_duration")
        })
    end

    if buff ~= nil then
        if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("curse_max_stacks") then
            buff:IncrementStackCount()
        end
        buff:ForceRefresh()
    end

    if self:GetAbility():GetLevel() == 5 then
        local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            self:GetAbility():GetSpecialValueFor("sap_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)
        
        victims = shuffleTable(victims)

        for _,victim in pairs(victims) do
            ApplyDamage({
                attacker = parent,
                victim = victim,
                damage = (self:GetAbility():GetSpecialValueFor("sap_int_damage_mult") * parent:GetIntellect()) + (self:GetAbility():GetSpecialValueFor("sap_mana_damage_mult") * parent:GetMaxMana()),
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            })
            victim:AddNewModifier(parent, self:GetAbility(), "modifier_item_ancient_book_of_shadows_sap_slow", {duration=self:GetAbility():GetSpecialValueFor("sap_slow_duration")})
            self:PlayEffects(victim)
            break
        end
    end
end

function modifier_item_ancient_book_of_shadows:PlayEffects( target )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_bane/bane_sap.vpcf"
	local sound_cast = "Hero_Bane.BrainSap"
	local sound_target = "Hero_Bane.BrainSap.Target"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		self:GetCaster():GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		target:GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
	EmitSoundOn( sound_target, target )
end
---------------
function modifier_item_ancient_book_of_shadows_burn_debuff:GetEffectName()
    return "particles/units/heroes/hero_bane/bane_enfeeble.vpcf"
end

function modifier_item_ancient_book_of_shadows_burn_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_item_ancient_book_of_shadows_burn_debuff:OnCreated()
    if not IsServer() then return end 

    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    self.damageTable = {
        attacker = self.caster,
        victim = self.parent,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability
    }

    self:StartIntervalThink(1)
end

function modifier_item_ancient_book_of_shadows_burn_debuff:OnIntervalThink()
    local damage = self.ability:GetSpecialValueFor("burn_damage")
    local damageInt = self.ability:GetSpecialValueFor("burn_int_to_damage")
    local damageMana = self.ability:GetSpecialValueFor("burn_max_mana_pct")

    local nDamage = (damage + (self.caster:GetIntellect() * (damageInt/100)) + (self.caster:GetMaxMana() * (damageMana/100))) * self:GetStackCount()

    self.damageTable.damage = nDamage

    ApplyDamage(self.damageTable)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, self.parent, nDamage, nil)
end
-------
function modifier_item_ancient_book_of_shadows_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_item_ancient_book_of_shadows_aura:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("aura_magical_res")
end

function modifier_item_ancient_book_of_shadows_aura:GetModifierIncomingDamage_Percentage(event)
    if event.damage_type == DAMAGE_TYPE_MAGICAL then
        return self:GetAbility():GetSpecialValueFor("aura_magical_amp")
    end
end
-------
function modifier_item_ancient_book_of_shadows_curse:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }
end

function modifier_item_ancient_book_of_shadows_curse:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("curse_spell_damage") * self:GetStackCount()
end

function modifier_item_ancient_book_of_shadows_curse:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("curse_self_damage_amp") 
end
------------
function modifier_item_ancient_book_of_shadows_sap_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_item_ancient_book_of_shadows_sap_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("sap_slow")
end