LinkLuaModifier("modifier_item_apotheosis_blade", "items/item_apotheosis_blade/item_apotheosis_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_apotheosis_blade_pool_debuff", "items/item_apotheosis_blade/item_apotheosis_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_apotheosis_blade_pool_thinker", "items/item_apotheosis_blade/item_apotheosis_blade", LUA_MODIFIER_MOTION_NONE)

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

item_apotheosis_blade = class(ItemBaseClass)
item_apotheosis_blade_2 = item_apotheosis_blade
item_apotheosis_blade_3 = item_apotheosis_blade
item_apotheosis_blade_4 = item_apotheosis_blade
item_apotheosis_blade_5 = item_apotheosis_blade
item_apotheosis_blade_6 = item_apotheosis_blade
item_apotheosis_blade_7 = item_apotheosis_blade
item_apotheosis_blade_8 = item_apotheosis_blade
item_apotheosis_blade_9 = item_apotheosis_blade
modifier_item_apotheosis_blade = class(item_apotheosis_blade)
modifier_item_apotheosis_blade_pool_debuff = class(ItemBaseClassDebuff)
modifier_item_apotheosis_blade_pool_thinker = class(ItemBaseClassDebuff)

modifier_item_apotheosis_blade.burn_damage = {}
-------------
function item_apotheosis_blade:GetIntrinsicModifierName()
    return "modifier_item_apotheosis_blade"
end
-------------
function modifier_item_apotheosis_blade:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_apotheosis_blade:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_apotheosis_blade:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_apotheosis_blade:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_item_apotheosis_blade:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_item_apotheosis_blade:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    if parent:IsIllusion() or not parent:IsRealHero() then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    local duration = ability:GetSpecialValueFor("duration")
    local radius = ability:GetSpecialValueFor("radius")
    local position = target:GetAbsOrigin()

    CreateModifierThinker(
        parent,
        ability,
        "modifier_item_apotheosis_blade_pool_thinker",
        { duration = duration, damage = event.original_damage },
        position,
        parent:GetTeam(),
        false
    )

    -- create vision
    AddFOWViewer(parent:GetTeam(), position, radius, duration, false )

    ability:UseResources(false, false, false, true)
end

function modifier_item_apotheosis_blade:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    self:StartIntervalThink(0.1)
end

function modifier_item_apotheosis_blade:OnIntervalThink()
    self:OnRefresh()
end

function modifier_item_apotheosis_blade:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()
    local strength = parent:GetStrength()
    local intellect = parent:GetBaseIntellect()

    local ability = self:GetAbility()

    self.damage = math.abs((strength - intellect) * (ability:GetSpecialValueFor("attribute_difference_damage_pct")/100)) + ability:GetSpecialValueFor("bonus_damage")

    self:InvokeBonusDamage()
end

function modifier_item_apotheosis_blade:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_item_apotheosis_blade:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_item_apotheosis_blade:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
-------------
function modifier_item_apotheosis_blade_pool_thinker:OnCreated(params)
    if not IsServer() then return end

    self.damage = params.damage
    self.caster = self:GetCaster()

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local mod = caster:FindModifierByName("modifier_item_apotheosis_blade")

    self.radius = self:GetAbility():GetSpecialValueFor("radius")

    mod.burn_damage[caster:entindex()] = mod.burn_damage[caster:entindex()] or self.damage 
    mod.burn_damage[caster:entindex()] = self.damage

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_doom_aura.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl( self.vfx, 0, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.vfx, 3, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.vfx, 4, parent:GetAbsOrigin() )
    self:AddParticle(self.vfx,false,false,-1,false,false)

    EmitSoundOn("Hero_DoomBringer.Doom", parent)

    self:StartIntervalThink(0.1)
end

function modifier_item_apotheosis_blade_pool_thinker:OnIntervalThink()
    if not self.caster:HasModifier("modifier_item_apotheosis_blade") then
        self:Destroy()
        return
    end
end

function modifier_item_apotheosis_blade_pool_thinker:OnDestroy()
    if not IsServer() then return end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    StopSoundOn("Hero_DoomBringer.Doom", self:GetParent())

    UTIL_Remove(self:GetParent())
end

function modifier_item_apotheosis_blade_pool_thinker:GetModifierAura()
    return "modifier_item_apotheosis_blade_pool_debuff"
end

function modifier_item_apotheosis_blade_pool_thinker:GetAuraRadius()
    return self.radius
end

function modifier_item_apotheosis_blade_pool_thinker:IsAura()
    return true
end

function modifier_item_apotheosis_blade_pool_thinker:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_apotheosis_blade_pool_thinker:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_item_apotheosis_blade_pool_thinker:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end
---------
function modifier_item_apotheosis_blade_pool_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS  
    }
end

function modifier_item_apotheosis_blade_pool_debuff:GetModifierMagicalResistanceBonus()
    return self.res
end

function modifier_item_apotheosis_blade_pool_debuff:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_item_apotheosis_blade_pool_debuff:OnCreated(params)
    self.res = self:GetAbility():GetSpecialValueFor("magic_res")
    self.dmg = self:GetAbility():GetSpecialValueFor("attack_as_damage")

    if not IsServer() then return end

    local caster = self:GetCaster()
    local mod = caster:FindModifierByName("modifier_item_apotheosis_blade")
    self.damage = mod.burn_damage[caster:entindex()]

    local particle_cast = "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 4, self:GetParent():GetAbsOrigin() )

    self:StartIntervalThink(1)
end

function modifier_item_apotheosis_blade_pool_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    ApplyDamage({
        victim = parent, 
        attacker = caster, 
        damage = self.damage * (self.dmg/100), 
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })

    EmitSoundOn("n_black_dragon.Fireball.Target", parent)
end

function modifier_item_apotheosis_blade_pool_debuff:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end