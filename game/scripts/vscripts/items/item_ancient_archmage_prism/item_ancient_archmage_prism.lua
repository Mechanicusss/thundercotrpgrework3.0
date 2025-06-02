LinkLuaModifier("modifier_item_ancient_archmage_prism", "items/item_ancient_archmage_prism/item_ancient_archmage_prism.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_archmage_prism_buff", "items/item_ancient_archmage_prism/item_ancient_archmage_prism.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_archmage_prism_thinker", "items/item_ancient_archmage_prism/item_ancient_archmage_prism.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_archmage_prism_cd", "items/item_ancient_archmage_prism/item_ancient_archmage_prism.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_archmage_prism_aura", "items/item_ancient_archmage_prism/item_ancient_archmage_prism.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_ancient_archmage_prism = class(ItemBaseClass)
item_ancient_archmage_prism_2 = item_ancient_archmage_prism
item_ancient_archmage_prism_3 = item_ancient_archmage_prism
item_ancient_archmage_prism_4 = item_ancient_archmage_prism
item_ancient_archmage_prism_5 = item_ancient_archmage_prism
modifier_item_ancient_archmage_prism = class(ItemBaseClass)
modifier_item_ancient_archmage_prism_buff = class(ItemBaseClassBuff)
modifier_item_ancient_archmage_prism_thinker = class(ItemBaseClassBuff)
modifier_item_ancient_archmage_prism_cd = class(ItemBaseClassDebuff)
modifier_item_ancient_archmage_prism_aura = class(ItemBaseClassDebuff)
-------------
function item_ancient_archmage_prism:GetIntrinsicModifierName()
    return "modifier_item_ancient_archmage_prism"
end
-------------
function modifier_item_ancient_archmage_prism:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE 
    }
end

function modifier_item_ancient_archmage_prism:GetModifierPercentageCooldown(event)
    if not IsServer() then return end 

    local ability = event.ability
    local name = ability:GetAbilityName()
    local type = ability:GetAbilityType()

    if string.match(name, "item_") or ability:IsItem() then return end -- Exclude items

    local ultCdr = self:GetAbility():GetSpecialValueFor("ultimate_cooldown_decrease")
    local basicCdi = self:GetAbility():GetSpecialValueFor("basic_cooldown_increase")

    if type == ABILITY_TYPE_ULTIMATE then
        return ultCdr
    end

    if type == ABILITY_TYPE_BASIC then
        return -basicCdi
    end
end

function modifier_item_ancient_archmage_prism:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_ancient_archmage_prism:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_damage")
end

function modifier_item_ancient_archmage_prism:GetModifierTotalPercentageManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen_pct")
end

function modifier_item_ancient_archmage_prism:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    local ability = event.inflictor 

    if not ability then return end 
    if ability:IsNull() then return end 

    if ability:GetAbilityType() ~= ABILITY_TYPE_ULTIMATE then return end

    return self:GetAbility():GetSpecialValueFor("ultimate_damage_amp")
end

function modifier_item_ancient_archmage_prism:OnAbilityFullyCast(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    local ability = event.ability 

    if not ability then return end 
    if ability:IsNull() then return end 

    if ability:GetAbilityType() ~= ABILITY_TYPE_ULTIMATE and ability:GetAbilityType() ~= ABILITY_TYPE_BASIC then return end
    if string.match(ability:GetAbilityName(), "item_") or ability:IsItem() then return end -- Exclude items

    local ultCdr = self:GetAbility():GetSpecialValueFor("ultimate_cooldown_decrease")
    local basicCdi = self:GetAbility():GetSpecialValueFor("basic_cooldown_increase")

    -- Ultimates
    if ability:GetAbilityType() == ABILITY_TYPE_ULTIMATE then
        -- Add buff 
        local buff = parent:FindModifierByName("modifier_item_ancient_archmage_prism_buff")
        if not buff then
            buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_ancient_archmage_prism_buff", {
                duration = self:GetAbility():GetSpecialValueFor("buff_duration")
            })
        end

        if buff then
            if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("buff_max_stacks") then
                buff:IncrementStackCount()
            end

            buff:ForceRefresh()
        end

        if not parent:HasModifier("modifier_item_ancient_archmage_prism_cd") and self:GetAbility():GetLevel() == 5 then
            local circleLoc = parent:GetAbsOrigin()

            if bit.band(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_POINT) ~= 0 then
                circleLoc = ability:GetCursorPosition()
            end

            if event.target then
                circleLoc = event.target:GetAbsOrigin()
            end

            self:CreateCircle(circleLoc)

            parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_ancient_archmage_prism_cd", { duration = self:GetAbility():GetSpecialValueFor("field_cooldown") })
        end
    end
end

function modifier_item_ancient_archmage_prism:CreateCircle(point)
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local duration = ability:GetSpecialValueFor("field_duration")
    local radius = ability:GetSpecialValueFor("field_radius")

    self.thinker = CreateModifierThinker(
        caster, -- player source
        ability, -- ability source
        "modifier_item_ancient_archmage_prism_thinker", -- modifier name
        { duration = duration, radius = radius }, -- kv
        point,
        caster:GetTeamNumber(),
        false
    )

    -- create fov
    AddFOWViewer(caster:GetTeamNumber(), point, radius, duration, false)
end
--------
function modifier_item_ancient_archmage_prism_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.intellect = self:GetParent():GetIntellect() * (self:GetAbility():GetSpecialValueFor("buff_int_increase_per_cast")/100)

    self:InvokeBonus()
end

function modifier_item_ancient_archmage_prism_buff:AddCustomTransmitterData()
    return
    {
        intellect = self.fIntellect,
    }
end

function modifier_item_ancient_archmage_prism_buff:HandleCustomTransmitterData(data)
    if data.intellect ~= nil then
        self.fIntellect = tonumber(data.intellect)
    end
end

function modifier_item_ancient_archmage_prism_buff:InvokeBonus()
    if IsServer() == true then
        self.fIntellect = self.intellect

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_ancient_archmage_prism_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    }
end

function modifier_item_ancient_archmage_prism_buff:GetModifierBonusStats_Intellect()
    if self.fIntellect then
        return self.fIntellect * self:GetStackCount()
    end
end
---------------
function modifier_item_ancient_archmage_prism_thinker:OnCreated()
    if not IsServer() then return end 

    local interval = self:GetAbility():GetSpecialValueFor("field_damage_interval")

    self.damageInt = self:GetAbility():GetSpecialValueFor("field_damage_int_mult")

    self.caster = self:GetCaster()

    local parent = self:GetParent()

    self.damageTable = {
        attacker = self.caster,
        victim = parent,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    }

    self:StartIntervalThink(interval)

    self:PlayEffects()
end

function modifier_item_ancient_archmage_prism_thinker:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/items4_fx/seer_stone_2.vpcf"
    local sound_cast = "Item.SeerStone"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, self:GetParent() )

    local radius = self:GetAbility():GetSpecialValueFor("field_radius")

    ParticleManager:SetParticleControl(self.effect_cast, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.effect_cast, 1, Vector( radius, radius, radius ))
    ParticleManager:SetParticleControl(self.effect_cast, 2, self:GetParent():GetAbsOrigin())

    -- buff particle
    self:AddParticle(
        self.effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_item_ancient_archmage_prism_thinker:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    UTIL_Remove(parent)
end

function modifier_item_ancient_archmage_prism_thinker:IsAura()
    return true
end

function modifier_item_ancient_archmage_prism_thinker:GetModifierAura()
    return "modifier_item_ancient_archmage_prism_aura"
end

function modifier_item_ancient_archmage_prism_thinker:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("field_radius")
end

function modifier_item_ancient_archmage_prism_thinker:GetAuraDuration()
    return self:GetAbility():GetSpecialValueFor("field_damage_interval")
end

function modifier_item_ancient_archmage_prism_thinker:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_ancient_archmage_prism_thinker:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_CREEP
end
-------------
function modifier_item_ancient_archmage_prism_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MISS_PERCENTAGE 
    }
end

function modifier_item_ancient_archmage_prism_aura:GetModifierMiss_Percentage()
    return self:GetAbility():GetSpecialValueFor("field_blind")
end

function modifier_item_ancient_archmage_prism_aura:OnCreated()
    if not IsServer() then return end 

    local interval = self:GetAbility():GetSpecialValueFor("field_damage_interval")

    self.damageInt = self:GetAbility():GetSpecialValueFor("field_damage_int_mult")

    self.caster = self:GetCaster()

    local parent = self:GetParent()

    self.damageTable = {
        attacker = self.caster,
        victim = parent,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    }

    self:StartIntervalThink(interval)
end

function modifier_item_ancient_archmage_prism_aura:OnIntervalThink()
    self.damageTable.damage = self.caster:GetIntellect() * self.damageInt

    ApplyDamage(self.damageTable)
end