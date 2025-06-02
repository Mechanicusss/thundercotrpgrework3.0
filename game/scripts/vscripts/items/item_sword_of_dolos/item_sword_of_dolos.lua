LinkLuaModifier("modifier_item_sword_of_dolos", "items/item_sword_of_dolos/item_sword_of_dolos", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sword_of_dolos_debuff", "items/item_sword_of_dolos/item_sword_of_dolos", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sword_of_dolos_active", "items/item_sword_of_dolos/item_sword_of_dolos", LUA_MODIFIER_MOTION_NONE)

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

item_sword_of_dolos = class(ItemBaseClass)
item_sword_of_dolos2 = item_sword_of_dolos
item_sword_of_dolos3 = item_sword_of_dolos
item_sword_of_dolos4 = item_sword_of_dolos
item_sword_of_dolos5 = item_sword_of_dolos
item_sword_of_dolos6 = item_sword_of_dolos
item_sword_of_dolos7 = item_sword_of_dolos
item_sword_of_dolos8 = item_sword_of_dolos
item_sword_of_dolos9 = item_sword_of_dolos
modifier_item_sword_of_dolos = class(item_sword_of_dolos)
modifier_item_sword_of_dolos_debuff = class(ItemBaseClassDebuff)
modifier_item_sword_of_dolos_active = class(ItemBaseClassDebuff)
-------------
function item_sword_of_dolos:GetIntrinsicModifierName()
    return "modifier_item_sword_of_dolos"
end

function modifier_item_sword_of_dolos:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_item_sword_of_dolos:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_sword_of_dolos:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_hp")
end

function modifier_item_sword_of_dolos:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_sword_of_dolos:GetModifierTotalDamageOutgoing_Percentage(event)
    if IsServer() then
        if event.inflictor or event.damage_type ~= DAMAGE_TYPE_PHYSICAL or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end

        local parent = self:GetParent()
        local ability = self:GetAbility()
        local victim = event.target

        -- Find targets back
        -- Thanks to DOTA IMBA for the code (https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/abilities/heroes/hero_riki#L1193)
        local victim_angle = victim:GetAnglesAsVector().y
        local origin_difference = victim:GetAbsOrigin() - parent:GetAbsOrigin()
        local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)
        origin_difference_radian = origin_difference_radian * 180

        local attacker_angle = origin_difference_radian / math.pi

        -- For some reason Dota mechanics read the result as 30 degrees anticlockwise, need to adjust it down to appropriate angles for backstabbing.
        attacker_angle = attacker_angle + 180.0 + 30.0

        local result_angle = attacker_angle - victim_angle
        result_angle = math.abs(result_angle)

        local backstabAngle = 105 -- Same as riki's backstab angle

        if result_angle >= (180 - (backstabAngle / 2)) and result_angle <= (180 + (backstabAngle / 2)) then
            local multiplier = ability:GetSpecialValueFor("backstab_damage_multiplier")
            
            -- Play sound and particle
            local particle = ParticleManager:CreateParticle("particles/econ/items/riki/riki_immortal_ti6/riki_immortal_ti6_blinkstrike__2stab.vpcf", PATTACH_ABSORIGIN_FOLLOW, victim)
            ParticleManager:SetParticleControlEnt(particle, 1, victim, PATTACH_POINT_FOLLOW, "attach_hitloc", victim:GetAbsOrigin(), true)
            ParticleManager:ReleaseParticleIndex(particle)
            EmitSoundOn("Hero_Riki.Backstab", victim)

            return multiplier * 100
        end
    end
end

function modifier_item_sword_of_dolos:OnAttackLanded(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    --local rikiBackstab = caster:FindAbilityByName("riki_backstab")
    --if rikiBackstab ~= nil and rikiBackstab:GetLevel() > 0 then return end

    local ability = self:GetAbility()
    
    local debuff = victim:FindModifierByName("modifier_item_sword_of_dolos_debuff")
    if not debuff then
        debuff = victim:AddNewModifier(unit, ability, "modifier_item_sword_of_dolos_debuff", {
            duration = ability:GetSpecialValueFor("poison_duration"),
            damage = event.damage
        })
    end

    if debuff then
        debuff:ForceRefresh()
    end
end
----------------------------
function modifier_item_sword_of_dolos_debuff:OnCreated(params)
    if not IsServer() then return end

    self.damage = params.damage

    local interval = self:GetAbility():GetSpecialValueFor("poison_interval")

    self:StartIntervalThink(interval)
end

function modifier_item_sword_of_dolos_debuff:OnIntervalThink()
    local damage = self.damage * (self:GetAbility():GetSpecialValueFor("poison_atk_dmg_pct")/100)

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = damage,
        ability = self:GetAbility(),
        damage_type = DAMAGE_TYPE_PHYSICAL
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), damage, nil)
end
--------------------------
function modifier_item_sword_of_dolos_active:IsDebuff() return false end 

function modifier_item_sword_of_dolos_active:CheckState()
    return {
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
    }
end

function modifier_item_sword_of_dolos_active:GetEffectName()
    return "particles/econ/items/phantom_assassin/pa_fall20_immortal_shoulders/pa_fall20_blur_ambient_2.vpcf"
end

function modifier_item_sword_of_dolos_active:GetStatusEffectName()
    return "particles/status_fx/status_effect_phantom_assassin_active_blur.vpcf"
end

function modifier_item_sword_of_dolos_active:OnRemoved()
    if not IsServer() then return end

    EmitSoundOn("Hero_PhantomAssassin.Blur.Break", self:GetParent())
end
-------------------------
function item_sword_of_dolos:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOn("Hero_PhantomAssassin.Blur", caster)

    caster:AddNewModifier(caster, self, "modifier_item_sword_of_dolos_active", {
        duration = self:GetDuration()
    })
end