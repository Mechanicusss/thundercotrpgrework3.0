LinkLuaModifier("modifier_item_ancient_rattlecage", "items/item_ancient_rattlecage/item_ancient_rattlecage.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_rattlecage_slow", "items/item_ancient_rattlecage/item_ancient_rattlecage.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_rattlecage_aura", "items/item_ancient_rattlecage/item_ancient_rattlecage.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_rattlecage_buff", "items/item_ancient_rattlecage/item_ancient_rattlecage.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_rattlecage_shield", "items/item_ancient_rattlecage/item_ancient_rattlecage.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
}

item_ancient_rattlecage = class(ItemBaseClass)
item_ancient_rattlecage_2 = item_ancient_rattlecage
item_ancient_rattlecage_3 = item_ancient_rattlecage
item_ancient_rattlecage_4 = item_ancient_rattlecage
item_ancient_rattlecage_5 = item_ancient_rattlecage
modifier_item_ancient_rattlecage = class(ItemBaseClass)
modifier_item_ancient_rattlecage_slow = class(ItemBaseClassDebuff)
modifier_item_ancient_rattlecage_aura = class(ItemBaseClassBuff)
modifier_item_ancient_rattlecage_buff = class(ItemBaseClassBuff)
modifier_item_ancient_rattlecage_shield = class(ItemBaseClassBuff)
-------------
function item_ancient_rattlecage:GetIntrinsicModifierName()
    return "modifier_item_ancient_rattlecage"
end

function item_ancient_rattlecage:OnProjectileHit(hTarget, vLoc)
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local damage = caster:GetMaxHealth() * (self:GetSpecialValueFor("max_hp_damage_pct")/100)

    ApplyDamage({
        victim = hTarget,
        attacker = caster,
        damage = damage,
        ability = self,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_REFLECTION
    })

    hTarget:AddNewModifier(caster, self, "modifier_item_ancient_rattlecage_slow", {duration=self:GetSpecialValueFor("slow_duration")})

    EmitSoundOn("Hero_Abaddon.DeathCoil.Target", hTarget)
end
-------------
function modifier_item_ancient_rattlecage:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_item_ancient_rattlecage:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res")
end

function modifier_item_ancient_rattlecage:GetModifierPhysicalArmorBonus()
    if self.lock then return 0 end

    self.lock = true

    local armor = self:GetParent():GetPhysicalArmorValue(false)

    self.lock = false

    local bonus = armor * (self:GetAbility():GetSpecialValueFor("bonus_armor_pct")/100)
    
    return bonus
end

function modifier_item_ancient_rattlecage:OnCreated()
    if not IsServer() then return end 

    self.damageTaken = 0

    local ability = self:GetAbility()
    self.interval = ability:GetSpecialValueFor("shield_regain_interval")
    
    self:StartIntervalThink(self.interval)
end

function modifier_item_ancient_rattlecage:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if ability:GetLevel() < 5 then return end

    local shield = parent:GetMaxHealth() * (ability:GetSpecialValueFor("shield_pct")/100)
    local shieldMax = shield

    parent:RemoveModifierByName("modifier_item_ancient_rattlecage_shield")

    local buff = parent:FindModifierByName("modifier_item_ancient_rattlecage_shield")
    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_item_ancient_rattlecage_shield", {
            overhealPhysical = shield,
            duration = self.interval
        })
    end

    if buff then
        local shieldToAddPhysical = buff.overhealPhysical + shield

        if shieldToAddPhysical < 0 then
            shieldToAddPhysical = 0
        end

        if shieldToAddPhysical > shieldMax then
            shieldToAddPhysical = shieldMax
        end

        buff.overhealPhysical = shieldToAddPhysical

        buff:ForceRefresh()
    end
end

function modifier_item_ancient_rattlecage:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    local attacker = event.attacker 

    if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end
    if parent:GetTeam() == attacker:GetTeam() then return end 
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= 0 then return end

    local ability = self:GetAbility()
    local count = ability:GetSpecialValueFor("enemy_count")
    local radius = ability:GetSpecialValueFor("radius")
    local threshold = ability:GetSpecialValueFor("max_hp_pct_threshold")

    local buff = parent:FindModifierByName("modifier_item_ancient_rattlecage_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_item_ancient_rattlecage_buff", { duration = ability:GetSpecialValueFor("stack_duration") })
    end

    if buff then
        if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end

    self.damageTaken = self.damageTaken + event.original_damage 

    if (self.damageTaken/parent:GetMaxHealth()) < (threshold/100) then return end

    self.damageTaken = 0

    local proj = {
        Target = attacker,
        Source = parent,
        Ability = ability,
        EffectName = "particles/items2_fx/rattlecage_projectile.vpcf",
        bDodgeable = false,
        bProvidesVision = true,
        iMoveSpeed = 2000,
        iVisionRadius = 0,
        iVisionTeamNumber = parent:GetTeamNumber(),
    }

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)
        
    victims = shuffleTable(victims)

    for i,victim in pairs(victims) do
        if i <= count then
            ProjectileManager:CreateTrackingProjectile(proj)
        end
    end

    EmitSoundOn("Hero_Abaddon.DeathCoil.Cast", parent)
end

function modifier_item_ancient_rattlecage:IsAura()
    return true
end

function modifier_item_ancient_rattlecage:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_item_ancient_rattlecage:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_ancient_rattlecage:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_ancient_rattlecage:GetModifierAura()
    return "modifier_item_ancient_rattlecage_aura"
end

function modifier_item_ancient_rattlecage:GetAuraEntityReject(target)
    return target == self:GetCaster()
end
----------
function modifier_item_ancient_rattlecage_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_item_ancient_rattlecage_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_slow")
end
-----------
function modifier_item_ancient_rattlecage_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
        MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT 
    }
end

function modifier_item_ancient_rattlecage_aura:GetModifierIncomingPhysicalDamageConstant(event)
    if not IsServer() then return end 

    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end 

    local ability = self:GetAbility()
    local redirect = ability:GetSpecialValueFor("damage_redirection")/100
    
    local damage = event.damage * redirect

    if IsServer() then
        ApplyDamage({
            victim = self:GetCaster(),
            attacker = event.attacker,
            damage = damage,
            damage_type = event.damage_type,
            ability = ability
        })
    end

    return -damage
end

function modifier_item_ancient_rattlecage_aura:GetModifierIncomingSpellDamageConstant(event)
    if not IsServer() then return end 

    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end 

    local ability = self:GetAbility()
    local redirect = ability:GetSpecialValueFor("damage_redirection")/100

    local damage = event.damage * redirect

    if IsServer() then
        ApplyDamage({
            victim = self:GetCaster(),
            attacker = event.attacker,
            damage = damage,
            damage_type = event.damage_type,
            ability = ability
        })
    end

    return -damage
end
-----------
function modifier_item_ancient_rattlecage_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_ancient_rattlecage_buff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_outgoing_damage_pct") * self:GetStackCount()
end
---------
function modifier_item_ancient_rattlecage_shield:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.overhealPhysical = params.overhealPhysical

    self.shieldPhysical = self.overhealPhysical
    self:InvokeShield()

    self.parent = self:GetParent()

    self.interval = (self:GetAbility():GetSpecialValueFor("shield_regain_interval")/100)

    self:StartIntervalThink(self.interval)
end

function modifier_item_ancient_rattlecage_shield:OnIntervalThink()
    self.overhealPhysical = self.overhealPhysical - (self.overhealPhysical * (self.interval/10) * self:GetElapsedTime())
    self.overhealPhysical = math.max(0, self.overhealPhysical)
    self.shieldPhysical = self.overhealPhysical
    self:InvokeShield()
end

function modifier_item_ancient_rattlecage_shield:OnRemoved()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("explosion_radius")

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_shredder/shredder_scepter_explode.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self.parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(effect_cast)

    local victims = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)
        
    for _,victim in pairs(victims) do
        ApplyDamage({
            victim = victim,
            attacker = self.parent,
            damage = self.parent:GetMaxHealth(),
            ability = ability,
            damage_type = DAMAGE_TYPE_PURE,
            damage_flags = DOTA_DAMAGE_FLAG_REFLECTION
        })
    end

    EmitSoundOn("Hero_Shredder.Bomb", parent)
end

function modifier_item_ancient_rattlecage_shield:OnRefresh()
    if not IsServer() then return end 

    self.shieldPhysical = self.overhealPhysical

    self:InvokeShield()
end

function modifier_item_ancient_rattlecage_shield:AddCustomTransmitterData()
    return
    {
        shieldPhysical = self.fShieldPhysical,
    }
end

function modifier_item_ancient_rattlecage_shield:HandleCustomTransmitterData(data)
    if data.shieldPhysical ~= nil then
        self.fShieldPhysical = tonumber(data.shieldPhysical)
    end
end

function modifier_item_ancient_rattlecage_shield:InvokeShield()
    if IsServer() == true then
        self.fShieldPhysical = self.shieldPhysical

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_ancient_rattlecage_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT  
    }
end

function modifier_item_ancient_rattlecage_shield:GetModifierIncomingDamageConstant(event)
    if not IsServer() then
        return self.fShieldPhysical
    end

    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end
    if self.overhealPhysical <= 0 then return end

    local block = 0
    local negated = self.overhealPhysical - event.damage 

    if negated <= 0 then
        block = self.overhealPhysical
    else
        block = event.damage
    end

    self.overhealPhysical = negated

    if self.overhealPhysical <= 0 then
        self.overhealPhysical = 0
        self.shieldPhysical = 0
        self:Destroy()
        return
    else
        self.shieldPhysical = self.overhealPhysical
    end

    self:InvokeShield()

    return -block
end