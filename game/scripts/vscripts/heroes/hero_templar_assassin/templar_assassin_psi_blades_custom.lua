--[[
    Credits to this file goes to https://github.com/EarthSalamander42/dota_imba (EarthSalamander42 and all the contributors)
]]

LinkLuaModifier("modifier_templar_assassin_psi_blades_custom", "heroes/hero_templar_assassin/templar_assassin_psi_blades_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_assassin_psi_blades_custom_cd", "heroes/hero_templar_assassin/templar_assassin_psi_blades_custom", LUA_MODIFIER_MOTION_NONE)
modifier_templar_assassin_psi_blades_custom           = class({})
templar_assassin_psi_blades_custom = class({})
modifier_templar_assassin_psi_blades_custom_cd = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

function templar_assassin_psi_blades_custom:GetIntrinsicModifierName()
    return "modifier_templar_assassin_psi_blades_custom"
end

function modifier_templar_assassin_psi_blades_custom:IsHidden()   return self:GetStackCount() <= 0 end

function modifier_templar_assassin_psi_blades_custom:OnCreated()
    
end

function modifier_templar_assassin_psi_blades_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS
    }
end

function modifier_templar_assassin_psi_blades_custom:GetModifierAttackRangeBonus()
    if self:GetParent():IsRangedAttacker() then return self:GetAbility():GetSpecialValueFor("bonus_attack_range") end

    return 0
end

function modifier_templar_assassin_psi_blades_custom:OnTakeDamage(keys)
    if keys.attacker == self:GetParent() and self:GetParent():IsRangedAttacker() and self:GetAbility():IsTrained() and not self:GetParent():PassivesDisabled() and keys.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and not keys.unit:IsBuilding() and (not keys.unit:IsOther() or (keys.unit:IsOther() and keys.damage > 0)) then
        if not self.meld_ability or self.meld_ability:IsNull() then
            self.meld_ability = self:GetCaster():FindAbilityByName("templar_assassin_psi_blades_custom")
        end
        
        if self.meld_ability and self.meld_ability.meld_record and self.meld_ability.meld_record == keys.record then
            self.meld_extension             = true
            self.meld_ability.meld_record   = nil
        end

        --if not self.meld_ability:IsCooldownReady() or self:GetParent():HasModifier("modifier_templar_assassin_psi_blades_custom_cd") then return end
        
        local damage_to_use = keys.damage
        
        if self.accelerate_record == keys.record then
            if not keys.unit:IsIllusion() then
                damage_to_use = math.max(keys.original_damage, keys.damage)
            else
                damage_to_use = keys.original_damage
            end
            
            self.accelerate_record = nil
        -- This is so jank...the spill damage isn't increased through hitting illusions with higher incoming damage multipliers, so I'm going to calculate the purported damage as if it hit a non-illusion and carry that forward
        elseif keys.unit:IsIllusion() and keys.unit.GetPhysicalArmorValue and GetReductionFromArmor then
            damage_to_use = keys.original_damage * (1 - GetReductionFromArmor(keys.unit:GetPhysicalArmorValue(false)))
        end

        for _, enemy in pairs(FindUnitsInLine(self:GetCaster():GetTeamNumber(), keys.unit:GetAbsOrigin(), keys.unit:GetAbsOrigin() + ((keys.unit:GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Normalized() * self:GetAbility():GetSpecialValueFor("attack_spill_range")), nil, self:GetAbility():GetSpecialValueFor("attack_spill_width"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)) do
            if enemy ~= keys.unit then
                enemy:EmitSound("Hero_TemplarAssassin.PsiBlade")
            
                self.psi_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_psi_blade.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.unit, self:GetParent())
                ParticleManager:SetParticleControlEnt(self.psi_particle, 0, keys.unit, PATTACH_POINT_FOLLOW, "attach_hitloc", keys.unit:GetAbsOrigin(), true)
                ParticleManager:SetParticleControlEnt(self.psi_particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
                ParticleManager:ReleaseParticleIndex(self.psi_particle)
               
                ApplyDamage({
                    victim          = enemy,
                    damage          = damage_to_use * self:GetAbility():GetSpecialValueFor("attack_spill_pct") * 0.01,
                    damage_type     = self:GetAbility():GetAbilityDamageType(),
                    damage_flags    = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
                    attacker        = self:GetParent(),
                    ability         = self:GetAbility()
                })
                
                -- IMBAfication: Meld Extension
                if self.meld_extension then
                    self.meld_ability:ApplyMeld(enemy, self:GetParent())
                end
            end
        end
        
        self.meld_extension = false

        --self.meld_ability:UseResources(false, false, true)
        --self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_templar_assassin_psi_blades_custom_cd", {
        --    duration = self:GetAbility():GetEffectiveCooldown(self:GetAbility():GetLevel())
        --})
    end
end

function modifier_templar_assassin_psi_blades_custom:OnAttack(keys)
    if keys.attacker == self:GetParent() and self:GetParent():IsRangedAttacker() and self:GetAbility():IsTrained() and not self:GetParent():PassivesDisabled() and not keys.no_attack_cooldown then
        if self:GetStackCount() < self:GetAbility():GetSpecialValueFor("attacks_to_accelerate") then
            self:IncrementStackCount()
        else
            self.accelerate_record = keys.record
            self:SetStackCount(0)
        end
    end
end

function modifier_templar_assassin_psi_blades_custom:GetModifierProjectileSpeedBonus()
    if self:GetStackCount() == self:GetAbility():GetSpecialValueFor("attacks_to_accelerate") then
        return self:GetAbility():GetSpecialValueFor("accelerant_speed_bonus")
    end
end