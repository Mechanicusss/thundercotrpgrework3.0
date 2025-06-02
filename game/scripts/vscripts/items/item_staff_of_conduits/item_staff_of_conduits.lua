LinkLuaModifier("modifier_item_staff_of_conduits", "items/item_staff_of_conduits/item_staff_of_conduits", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_staff_of_conduits_debuff", "items/item_staff_of_conduits/item_staff_of_conduits", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_staff_of_conduits_debuff_armor", "items/item_staff_of_conduits/item_staff_of_conduits", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_staff_of_conduits_debuff_damage_dealt", "items/item_staff_of_conduits/item_staff_of_conduits", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_staff_of_conduits_cooldown", "items/item_staff_of_conduits/item_staff_of_conduits", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_staff_of_conduits_shield", "items/item_staff_of_conduits/item_staff_of_conduits", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_staff_of_conduits_strength_buff_hp", "items/item_staff_of_conduits/item_staff_of_conduits", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local BaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_staff_of_conduits = class(BaseClass)
item_staff_of_conduits2 = item_staff_of_conduits
item_staff_of_conduits3 = item_staff_of_conduits
item_staff_of_conduits4 = item_staff_of_conduits
item_staff_of_conduits5 = item_staff_of_conduits
item_staff_of_conduits6 = item_staff_of_conduits
item_staff_of_conduits7 = item_staff_of_conduits
item_staff_of_conduits8 = item_staff_of_conduits
modifier_item_staff_of_conduits = class(item_staff_of_conduits)
modifier_item_staff_of_conduits_debuff = class(BaseClassDebuff)
modifier_item_staff_of_conduits_debuff_armor = class(BaseClassDebuff)
modifier_item_staff_of_conduits_debuff_damage_dealt = class(BaseClassDebuff)
modifier_item_staff_of_conduits_cooldown = class(BaseClass)
modifier_item_staff_of_conduits_shield = class(BaseClassBuff)
modifier_item_staff_of_conduits_strength_buff_hp = class(BaseClassBuff)

function item_staff_of_conduits:GetIntrinsicModifierName()
    return "modifier_item_staff_of_conduits"
end

function item_staff_of_conduits:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    target:AddNewModifier(caster, self, "modifier_item_staff_of_conduits_shield", {
        duration = self:GetSpecialValueFor("shield_duration")
    })

    EmitSoundOn("DOTA_Item.Mjollnir.Activate", target)
end
----------
function modifier_item_staff_of_conduits:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
    }
    return funcs
end

function modifier_item_staff_of_conduits:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_staff_of_conduits:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_staff_of_conduits:OnAttack(event)
    if not IsServer() then return end
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    self.caster = caster

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() or caster:IsIllusion() then
        return
    end

    if event.attacker:IsIllusion() then return end

    self.ability = self:GetAbility()
    local chance = self.ability:GetSpecialValueFor("chance")

    if not RollPercentage(chance) then return end
    if caster:HasModifier("modifier_item_staff_of_conduits_cooldown") then return end

    local bonusFromStats
    if caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
        bonusFromStats = (self.caster:GetBaseIntellect()*(self.ability:GetSpecialValueFor("int_damage")/100))
    elseif caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
        bonusFromStats = (self.caster:GetAgility()*(self.ability:GetSpecialValueFor("agi_damage")/100))
    elseif caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
        bonusFromStats = (self.caster:GetStrength()*(self.ability:GetSpecialValueFor("str_damage")/100)) + (self.caster:GetMaxHealth() * (self.ability:GetSpecialValueFor("str_damage_from_hp_pct")/100))
    else 
        -- They're universal
        bonusFromStats = (self.caster:GetBaseIntellect()*(self.ability:GetSpecialValueFor("int_damage")/100)) + (self.caster:GetAgility()*(self.ability:GetSpecialValueFor("agi_damage")/100)) + (self.caster:GetStrength()*(self.ability:GetSpecialValueFor("str_damage")/100)) + (self.caster:GetMaxHealth() * (self.ability:GetSpecialValueFor("str_damage_from_hp_pct")/100))
    end

    self.jump_count = self.ability:GetSpecialValueFor("jump_count")
    self.jump_delay = self.ability:GetSpecialValueFor("jump_delay")
    self.damage = self.ability:GetSpecialValueFor("damage") + bonusFromStats
    self.radius = self.ability:GetSpecialValueFor("radius")

    -- load data
    local radius = self.radius
    local bounces = self.jump_count

    -- find units in inital radius around target
    local targets = FindUnitsInRadius(
        caster:GetTeam(),
        victim:GetAbsOrigin(),    -- point, center point
        nil,
        radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    -- change table form to (unit,bool)
    local targets_tbl = {}
    for _,unit in pairs(targets) do
        targets_tbl[unit] = false
    end

    self:CreateVFX(self.caster, victim)

    -- recursive bounce
    self:bounce( caster, victim, targets_tbl, radius, bounces )

    EmitSoundOn("Item.Maelstrom.Chain_Lightning", caster)

    caster:AddNewModifier(caster, self.ability, "modifier_item_staff_of_conduits_cooldown", {
        duration = self.ability:GetSpecialValueFor("jump_cooldown")
    })
end

function modifier_item_staff_of_conduits:bounce( caster, current, init_targets, radius, bounce )
    local debuffName
    local damageType
    local isUniversal = false
    if caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
        damageType = DAMAGE_TYPE_MAGICAL
        debuffName = "modifier_item_staff_of_conduits_debuff"
    elseif caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
        damageType = DAMAGE_TYPE_PHYSICAL
        debuffName = "modifier_item_staff_of_conduits_debuff_armor"
    elseif caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
        damageType = DAMAGE_TYPE_MAGICAL
        debuffName = "modifier_item_staff_of_conduits_debuff_damage_dealt"
    else 
        isUniversal = true
    end

    if not isUniversal then
        local debuff = current:FindModifierByName(debuffName)
        if debuff == nil then
            debuff = current:AddNewModifier(caster, self.ability, debuffName, {
                duration = self.ability:GetSpecialValueFor("debuff_duration")
            })
        end

        if debuff then
            debuff:ForceRefresh()
        end
    else
        --1
        local debuff1 = current:FindModifierByName("modifier_item_staff_of_conduits_debuff")
        if debuff1 == nil then
            debuff1 = current:AddNewModifier(caster, self.ability, "modifier_item_staff_of_conduits_debuff", {
                duration = self.ability:GetSpecialValueFor("debuff_duration")
            })
        end

        if debuff1 then
            debuff1:ForceRefresh()
        end

         --2
         local debuff2 = current:FindModifierByName("modifier_item_staff_of_conduits_debuff_armor")
         if debuff2 == nil then
             debuff2 = current:AddNewModifier(caster, self.ability, "modifier_item_staff_of_conduits_debuff_armor", {
                 duration = self.ability:GetSpecialValueFor("debuff_duration")
             })
         end
 
         if debuff2 then
             debuff2:ForceRefresh()
         end

          --3
        local debuff3 = current:FindModifierByName("modifier_item_staff_of_conduits_debuff_damage_dealt")
        if debuff3 == nil then
            debuff3 = current:AddNewModifier(caster, self.ability, "modifier_item_staff_of_conduits_debuff_damage_dealt", {
                duration = self.ability:GetSpecialValueFor("debuff_duration")
            })
        end

        if debuff3 then
            debuff3:ForceRefresh()
        end
    end

    if not isUniversal then
        ApplyDamage({
            victim = current, 
            attacker = caster, 
            damage = self.damage, 
            damage_type = damageType,
            ability = self.ability
        })
    else 
        ApplyDamage({
            victim = current, 
            attacker = caster, 
            damage = self.damage, 
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self.ability
        })

        ApplyDamage({
            victim = current, 
            attacker = caster, 
            damage = self.damage, 
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = self.ability
        })
    end

    -- find next target in double radius, in case the current target is on the edge from first target
    local targets = FindUnitsInRadius(
        caster:GetTeam(),
        current:GetOrigin(),    -- point, center point
        nil,
        radius,
        --radius*2,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    -- check bounce num
    bounce = bounce-1
    if bounce<=0 then return end

    local nexttgt = nil
    for i,unit in ipairs(targets) do
        -- not bounce unto itself
        -- check if the next target is within the initial radius of initial target
        if unit~=current and (init_targets[unit] == nil or init_targets[unit] == false) and self.caster:CanEntityBeSeenByMyTeam(unit) then
            nexttgt = unit
            break
        end
    end

    init_targets[current] = true

    if nexttgt then
        Timers:CreateTimer(self.jump_delay, function()
            if bounce<=0 then return end
            self:CreateVFX(current, nexttgt)
            self:bounce( caster, nexttgt, init_targets, radius, bounce )
        end)
    end
end

function modifier_item_staff_of_conduits:CreateVFX(caster, target)
    local particle_cast = "particles/econ/events/fall_2022/maelstrom/maelstrom_fall2022.vpcf"
    local sound_cast = "Item.Maelstrom.Chain_Lightning.Jump"

    local originalPos = caster:GetAbsOrigin()
    local pos = target:GetAbsOrigin()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(effect_cast, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", originalPos, true)
    ParticleManager:SetParticleControlEnt(effect_cast, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", pos, true)
    ParticleManager:SetParticleControl(effect_cast, 2, Vector(1, 1, 1))
    ParticleManager:ReleaseParticleIndex(effect_cast)

    --ParticleManager:SetParticleControl(effect_cast, 0, pos) -- Who it bounces to
    --ParticleManager:SetParticleControl(effect_cast, 1, originalPos) -- Where it bounces from

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end
----
function modifier_item_staff_of_conduits_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_item_staff_of_conduits_debuff:GetModifierIncomingDamage_Percentage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.target ~= parent or event.attacker == parent then return end
    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end

    local ability = self:GetAbility()

    return ability:GetSpecialValueFor("debuff_magic_increase")
end
----
function modifier_item_staff_of_conduits_debuff_damage_dealt:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE  
    }
end

function modifier_item_staff_of_conduits_debuff_damage_dealt:OnCreated()
    if not IsServer() then return end
end

function modifier_item_staff_of_conduits_debuff_damage_dealt:OnRefresh()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    local buff = caster:FindModifierByName("modifier_item_staff_of_conduits_strength_buff_hp")
    if buff == nil then
        buff = caster:AddNewModifier(caster, ability, "modifier_item_staff_of_conduits_strength_buff_hp", {
            duration = ability:GetSpecialValueFor("str_buff_duration")
        })
    end

    if buff then
        if buff:GetStackCount() < ability:GetSpecialValueFor("str_buff_max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end

function modifier_item_staff_of_conduits_debuff_damage_dealt:GetModifierTotalDamageOutgoing_Percentage(event)
    return self:GetAbility():GetSpecialValueFor("debuff_damage_reduction")
end
-------------
function modifier_item_staff_of_conduits_strength_buff_hp:IsStackable()
    return true
end

function modifier_item_staff_of_conduits_strength_buff_hp:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_staff_of_conduits_strength_buff_hp:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_BONUS   
    }
end

function modifier_item_staff_of_conduits_strength_buff_hp:AddCustomTransmitterData()
    return
    {
        hp = self.fHp,
    }
end

function modifier_item_staff_of_conduits_strength_buff_hp:HandleCustomTransmitterData(data)
    if data.hp ~= nil then
        self.fHp = tonumber(data.hp)
    end
end

function modifier_item_staff_of_conduits_strength_buff_hp:InvokeBonusHealth()
    if IsServer() == true then
        self.fHp = self.hp

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_staff_of_conduits_strength_buff_hp:OnCreated( kv )
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    -- We only get their max health once when the buff is created
    -- otherwise it stacks infinitely.
    self.basehp = self:GetParent():GetMaxHealth()

    self:OnRefresh()
end

function modifier_item_staff_of_conduits_strength_buff_hp:OnRefresh( kv )
    if not IsServer() then return end
    
    self.hp = self.basehp * (self:GetAbility():GetSpecialValueFor("str_buff_hp_increase_per_target_pct")/100) * self:GetStackCount()
    self:InvokeBonusHealth()
end

function modifier_item_staff_of_conduits_strength_buff_hp:GetModifierHealthBonus()
    return self.fHp
end
----
function modifier_item_staff_of_conduits_debuff_armor:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
    }
end

function modifier_item_staff_of_conduits_debuff_armor:HandleCustomTransmitterData(data)
    if data.armor ~= nil then
        self.fArmor = tonumber(data.armor)
    end
end

function modifier_item_staff_of_conduits_debuff_armor:InvokeArmor()
    if IsServer() == true then
        self.fArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_staff_of_conduits_debuff_armor:OnCreated( kv )
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self:OnRefresh()
end

function modifier_item_staff_of_conduits_debuff_armor:OnRefresh( kv )
    self.armor = self:GetParent():GetPhysicalArmorValue(false) * (self:GetAbility():GetSpecialValueFor("debuff_armor_pct")/100)
    self:InvokeArmor()
end

function modifier_item_staff_of_conduits_debuff_armor:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_item_staff_of_conduits_debuff_armor:GetModifierPhysicalArmorBonus()
    return self.fArmor
end
--------------------
function modifier_item_staff_of_conduits_shield:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_item_staff_of_conduits_shield:OnAttackLanded(event)
    if not IsServer() then return end
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    self.caster = caster

    if victim ~= parent then
        return
    end

    if not parent:IsAlive() or not victim:IsAlive() then
        return
    end

    if event.attacker:IsIllusion() then return end

    self.ability = self:GetAbility()

    if parent:HasModifier("modifier_item_staff_of_conduits_cooldown") then return end

    local bonusFromStats
    if caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
        bonusFromStats = (self.caster:GetBaseIntellect()*(self.ability:GetSpecialValueFor("int_damage")/100))
    elseif caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
        bonusFromStats = (self.caster:GetAgility()*(self.ability:GetSpecialValueFor("agi_damage")/100))
    elseif caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
        bonusFromStats = (self.caster:GetStrength()*(self.ability:GetSpecialValueFor("str_damage")/100)) + (self.caster:GetMaxHealth() * (self.ability:GetSpecialValueFor("str_damage_from_hp_pct")/100))
    else 
        -- They're universal
        bonusFromStats = (self.caster:GetBaseIntellect()*(self.ability:GetSpecialValueFor("int_damage")/100)) + (self.caster:GetAgility()*(self.ability:GetSpecialValueFor("agi_damage")/100)) + (self.caster:GetStrength()*(self.ability:GetSpecialValueFor("str_damage")/100)) + (self.caster:GetMaxHealth() * (self.ability:GetSpecialValueFor("str_damage_from_hp_pct")/100))
    end

    self.jump_count = self.ability:GetSpecialValueFor("jump_count")
    self.jump_delay = self.ability:GetSpecialValueFor("jump_delay")
    self.damage = self.ability:GetSpecialValueFor("damage") + bonusFromStats
    self.radius = self.ability:GetSpecialValueFor("radius")

    -- load data
    local radius = self.radius
    local bounces = self.jump_count

    -- find units in inital radius around target
    local targets = FindUnitsInRadius(
        caster:GetTeam(),
        unit:GetAbsOrigin(),    -- point, center point
        nil,
        radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    -- change table form to (unit,bool)
    local targets_tbl = {}
    for _,unit in pairs(targets) do
        targets_tbl[unit] = false
    end

    self:CreateVFX(parent, unit)

    -- recursive bounce
    self:bounce( parent, unit, targets_tbl, radius, bounces )

    EmitSoundOn("Item.Maelstrom.Chain_Lightning", parent)

    parent:AddNewModifier(caster, self.ability, "modifier_item_staff_of_conduits_cooldown", {
        duration = self.ability:GetSpecialValueFor("jump_cooldown")
    })
end

function modifier_item_staff_of_conduits_shield:bounce( caster, current, init_targets, radius, bounce )
    local debuffName
    local damageType
    if self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
        damageType = DAMAGE_TYPE_MAGICAL
        debuffName = "modifier_item_staff_of_conduits_debuff"
    elseif self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
        damageType = DAMAGE_TYPE_PHYSICAL
        debuffName = "modifier_item_staff_of_conduits_debuff_armor"
    elseif self.caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
        damageType = DAMAGE_TYPE_MAGICAL
        debuffName = "modifier_item_staff_of_conduits_debuff_damage_dealt"
    end

    local debuff = current:FindModifierByName(debuffName)
    if debuff == nil then
        debuff = current:AddNewModifier(self.caster, self.ability, debuffName, {
            duration = self.ability:GetSpecialValueFor("debuff_duration")
        })
    end

    if debuff then
        debuff:ForceRefresh()
    end

    ApplyDamage({
        victim = current, 
        attacker = self.caster, 
        damage = self.damage, 
        damage_type = damageType,
        ability = self.ability
    })

    -- find next target in double radius, in case the current target is on the edge from first target
    local targets = FindUnitsInRadius(
        self.caster:GetTeam(),
        current:GetOrigin(),    -- point, center point
        nil,
        radius,
        --radius*2,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    -- check bounce num
    bounce = bounce-1
    if bounce<=0 then return end

    local nexttgt = nil
    for i,unit in ipairs(targets) do
        -- not bounce unto itself
        -- check if the next target is within the initial radius of initial target
        if unit~=current and (init_targets[unit] == nil or init_targets[unit] == false) and self.caster:CanEntityBeSeenByMyTeam(unit) then
            nexttgt = unit
            break
        end
    end

    init_targets[current] = true

    if nexttgt then
        Timers:CreateTimer(self.jump_delay, function()
            if bounce<=0 then return end
            self:CreateVFX(current, nexttgt)
            self:bounce( self.caster, nexttgt, init_targets, radius, bounce )
        end)
    end
end

function modifier_item_staff_of_conduits_shield:CreateVFX(caster, target)
    local particle_cast = "particles/econ/events/fall_2022/maelstrom/maelstrom_fall2022.vpcf"
    local sound_cast = "Item.Maelstrom.Chain_Lightning.Jump"

    local originalPos = caster:GetAbsOrigin()
    local pos = target:GetAbsOrigin()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(effect_cast, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", originalPos, true)
    ParticleManager:SetParticleControlEnt(effect_cast, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", pos, true)
    ParticleManager:SetParticleControl(effect_cast, 2, Vector(1, 1, 1))
    ParticleManager:ReleaseParticleIndex(effect_cast)

    --ParticleManager:SetParticleControl(effect_cast, 0, pos) -- Who it bounces to
    --ParticleManager:SetParticleControl(effect_cast, 1, originalPos) -- Where it bounces from

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end

function modifier_item_staff_of_conduits_shield:GetEffectName()
    return "particles/econ/events/fall_2022/mjollnir/mjollnir_shield_fall2022.vpcf"
end

function modifier_item_staff_of_conduits_shield:OnRemoved()
    if not IsServer() then return end

    EmitSoundOn("DOTA_Item.Mjollnir.DeActivate", self:GetParent())
end