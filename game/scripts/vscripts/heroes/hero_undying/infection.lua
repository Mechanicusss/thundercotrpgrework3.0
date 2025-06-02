LinkLuaModifier("modifier_undying_infection_custom", "heroes/hero_undying/infection", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_undying_infection_custom_debuff", "heroes/hero_undying/infection", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_undying_infection_custom_debuff_threshold", "heroes/hero_undying/infection", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}
local ItemBaseClassDeBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

undying_infection_custom = class(ItemBaseClass)
modifier_undying_infection_custom = class(undying_infection_custom)
modifier_undying_infection_custom_debuff = class(ItemBaseClassDeBuff)
modifier_undying_infection_custom_debuff_threshold = class(ItemBaseClassDeBuff)
-------------
function modifier_undying_infection_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_undying_infection_custom_debuff:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then return end
    if not self:GetCaster():HasScepter() then return end

    local victims = FindUnitsInRadius(self:GetCaster():GetTeam(), self:GetParent():GetAbsOrigin(), nil,
        self:GetAbility():GetSpecialValueFor("explosion_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if 
            victim:IsAlive() and 
            not victim:IsMagicImmune()
        then
            local dmg = self:GetAbility():GetSpecialValueFor("explosion_damage") + (self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("explosion_damage_str_conversion")/100))

            ApplyDamage({
                victim = victim,
                attacker = self:GetCaster(),
                damage = dmg,
                damage_type = DAMAGE_TYPE_MAGICAL,
                damage_flags = DOTA_DAMAGE_FLAG_FORCE_SPELL_AMPLIFICATION,
                ability = self:GetAbility(),
            })

            SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, victim, dmg, nil)
        end
    end

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_clean_low.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    --EmitSoundOn( "Hero_LifeStealer.Consume", self:GetParent() )
end

function modifier_undying_infection_custom_debuff:OnRemoved(event)
    if not IsServer() then return end

    if not self:GetCaster():HasScepter() then return end

    local victims = FindUnitsInRadius(self:GetCaster():GetTeam(), self:GetParent():GetAbsOrigin(), nil,
        self:GetAbility():GetSpecialValueFor("explosion_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if 
            victim:IsAlive() and 
            not victim:IsMagicImmune()
        then
            local dmg = self:GetAbility():GetSpecialValueFor("explosion_damage") + (self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("explosion_damage_str_conversion")/100))

            ApplyDamage({
                victim = victim,
                attacker = self:GetCaster(),
                damage = dmg,
                damage_type = DAMAGE_TYPE_MAGICAL,
                damage_flags = DOTA_DAMAGE_FLAG_FORCE_SPELL_AMPLIFICATION,
                ability = self:GetAbility(),
            })

            SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, victim, dmg, nil)
        end
    end

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_clean_low.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    --EmitSoundOn( "Hero_LifeStealer.Consume", self:GetParent() )
end

function modifier_undying_infection_custom_debuff:GetEffectName()
    return "particles/econ/items/pugna/pugna_ti9_immortal/pugna_ti9_immortal_ambient_maggots.vpcf"
end

function modifier_undying_infection_custom_debuff:GetStatusEffectName()
    return "particles/neutral_fx/gnoll_poison_debuff.vpcf"
end

function modifier_undying_infection_custom_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_undying_infection_custom_debuff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("reduced_damage")
end

function modifier_undying_infection_custom_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("reduced_attack_speed")
end

function modifier_undying_infection_custom_debuff:OnCreated()
    if not IsServer() then return end

    self.ability = self:GetAbility()

    self:StartIntervalThink(self.ability:GetSpecialValueFor("tick_interval"))
end

function modifier_undying_infection_custom_debuff:OnIntervalThink()
    if not self:GetCaster():IsAlive() then self:StartIntervalThink(-1) end
    -- Small damage tick --
    local dmg = (self:GetParent():GetMaxHealth() * (self.ability:GetSpecialValueFor("dot_max_hp_pct")/100)) * self.ability:GetSpecialValueFor("tick_interval")
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = dmg,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
        ability = self.ability,
    })

    local baseDmg = self.ability:GetSpecialValueFor("base_damage") + (self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("str_to_damage")/100))

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = baseDmg,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability,
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), dmg+baseDmg, nil)

    -- Threshold tick --
    if self:GetParent():GetHealthPercent() <= self.ability:GetSpecialValueFor("hp_threshold_pct") then
        if not self:GetParent():HasModifier("modifier_undying_infection_custom_debuff_threshold") then
            self:GetParent():AddNewModifier(self:GetCaster(), self.ability, "modifier_undying_infection_custom_debuff_threshold", { duration = self.ability:GetSpecialValueFor("threshold_duration") })
        end
    end

    -- Spread mechanic --
    local victims = FindUnitsInRadius(self:GetCaster():GetTeam(), self:GetParent():GetAbsOrigin(), nil,
        self:GetAbility():GetSpecialValueFor("spread_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if 
            victim:IsAlive() and 
            victim ~= self:GetParent() and 
            not victim:IsMagicImmune() and 
            not IsBossTCOTRPG(victim) and 
            RollPercentage(self:GetAbility():GetSpecialValueFor("spread_chance")) and 
            not victim:HasModifier("modifier_undying_infection_custom_debuff") 
        then
            victim:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_undying_infection_custom_debuff", { duration = self:GetAbility():GetSpecialValueFor("spread_duration")})
        end
    end
end
-------------
function modifier_undying_infection_custom_debuff_threshold:OnCreated()
    if not IsServer() then return end

    self.ability = self:GetAbility()

    local effect_cast = ParticleManager:CreateParticle( "particles/abilities/rupture_burst.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 1, self:GetParent():GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn( "hero_bloodseeker.rupture_FP", self:GetParent() )

    self:StartIntervalThink(self.ability:GetSpecialValueFor("tick_interval"))
end

function modifier_undying_infection_custom_debuff_threshold:OnIntervalThink()
    if not self:GetCaster():IsAlive() then self:StartIntervalThink(-1) end
    -- Small damage tick --
    local dmg = (self:GetParent():GetMaxHealth() * (self.ability:GetSpecialValueFor("threshold_dot_max_hp_pct")/100)) * self.ability:GetSpecialValueFor("tick_interval")
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = dmg,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
        ability = self.ability,
    })
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), dmg, nil)
end

function modifier_undying_infection_custom_debuff_threshold:OnDestroy()
    StopSoundOn("hero_bloodseeker.rupture_FP", self:GetParent())
end

function modifier_undying_infection_custom_debuff_threshold:GetEffectName()
    return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end
-------------
function undying_infection_custom:GetIntrinsicModifierName()
    return "modifier_undying_infection_custom"
end


function modifier_undying_infection_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_undying_infection_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_undying_infection_custom:OnAttackLanded(event)
    local attacker = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if attacker ~= parent then return end
    if event.inflictor ~= nil then
        if event.inflictor == self:GetAbility() then return end
    end
    
    if not IsBossTCOTRPG(victim) and not IsCreepTCOTRPG(victim) then return end

    local ability = self:GetAbility()

    local modName = "modifier_undying_infection_custom_debuff"
    if not victim:HasModifier(modName) then
        victim:AddNewModifier(attacker, ability, modName, { duration = ability:GetSpecialValueFor("duration") })
    else
        victim:FindModifierByNameAndCaster(modName, attacker):ForceRefresh()
    end
end