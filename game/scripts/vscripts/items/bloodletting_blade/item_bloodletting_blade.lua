LinkLuaModifier("modifier_bloodletting_blade", "items/bloodletting_blade/item_bloodletting_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodletting_blade_buff", "items/bloodletting_blade/item_bloodletting_blade", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_bloodletting_blade = class(ItemBaseClass)
item_bloodletting_blade_2 = item_bloodletting_blade
item_bloodletting_blade_3 = item_bloodletting_blade
item_bloodletting_blade_4 = item_bloodletting_blade
item_bloodletting_blade_5 = item_bloodletting_blade
modifier_bloodletting_blade = class(item_bloodletting_blade)
modifier_bloodletting_blade_buff = class(ItemBaseClassBuff)

function modifier_bloodletting_blade_buff:GetTexture() return "item_bloodletting_blade" end
-------------
function item_bloodletting_blade:GetIntrinsicModifierName()
    return "modifier_bloodletting_blade"
end

function item_bloodletting_blade:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("sacrifice_radius")
    local hpLoss = caster:GetHealth() * (self:GetSpecialValueFor("health_sacrifice_pct")/100)

    ApplyDamage({
        victim = caster,
        attacker = caster,
        damage = hpLoss,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
    })
  
    local effect_cast = ParticleManager:CreateParticle("particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(effect_cast, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, caster:GetAbsOrigin())

    EmitSoundOn("hero_bloodseeker.rupture", caster)

    local targets = FindUnitsInRadius(
        caster:GetTeam(),
        caster:GetAbsOrigin(),    -- point, center point
        nil,
        radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    for _,target in ipairs(targets) do
        target:AddNewModifier(caster, self, "modifier_bloodletting_blade_buff", {
            duration = self:GetSpecialValueFor("duration"),
        })
    end
end

function item_bloodletting_blade:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
------------
function modifier_bloodletting_blade:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }

    return funcs
end

function modifier_bloodletting_blade:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent:HasModifier("modifier_bloodletting_blade_buff") then
        parent:RemoveModifierByName("modifier_bloodletting_blade_buff")
    end
end

function modifier_bloodletting_blade:OnTakeDamage(event)
    if not IsServer() then return end
    
    if event.attacker ~= self:GetParent() then return end
    if event.attacker == event.unit then return end

    local attacker = event.attacker
    local ability = self:GetAbility()

    if event.unit:GetUnitName() == "npc_tcot_tormentor" then return end

    local allies = FindUnitsInRadius(attacker:GetTeam(), attacker:GetAbsOrigin(), nil,
        ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    local heal = event.damage * (ability:GetSpecialValueFor("damage_to_healing_pct")/100)

    for _,ally in ipairs(allies) do
        if not ally:IsAlive() then break end

        ally:Heal(heal, ability)

        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal, nil)
        self:PlayEffects(ally)
    end
end

function modifier_bloodletting_blade:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/bloodletting_blade/spectre_arcana_v2_dispersion.vpcf"

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
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    -- ParticleManager:SetParticleControl( effect_cast, 1, vControlVector )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
--------------

function modifier_bloodletting_blade:GetModifierHealthBonus()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_bloodletting_blade:GetModifierConstantManaRegen()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_bloodletting_blade:GetModifierPreAttack_BonusDamage()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_bloodletting_blade:GetModifierBonusStats_Strength()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_bloodletting_blade:GetModifierPhysical_ConstantBlock(event)
    local block = event.damage * (self:GetAbility():GetSpecialValueFor("damage_block_pct")/100)

    return block
end

----
function modifier_bloodletting_blade_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }

    return funcs
end

function modifier_bloodletting_blade_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    
    self.damage = ability:GetSpecialValueFor("health_sacrifice_pct")

    self.effect_cast = ParticleManager:CreateParticle("particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodrage_eztzhok.vpcf", PATTACH_CUSTOMORIGIN, parent)
    ParticleManager:SetParticleControlEnt(self.effect_cast, 0, parent, PATTACH_OVERHEAD_FOLLOW, "attach_attack1", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(self.effect_cast, 3, parent:GetAbsOrigin())

    self:InvokeBonusDamage()

    self:StartIntervalThink(0.1)
end

function modifier_bloodletting_blade_buff:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    if not caster:HasModifier("modifier_bloodletting_blade") then
        parent:RemoveModifierByName("modifier_bloodletting_blade_buff")
    end
end

function modifier_bloodletting_blade_buff:OnDestroy()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.effect_cast, true)
    ParticleManager:ReleaseParticleIndex(self.effect_cast)
end

function modifier_bloodletting_blade_buff:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.target ~= self:GetParent() then
        return self.fDamage 
    end
end

function modifier_bloodletting_blade_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_bloodletting_blade_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_bloodletting_blade_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end