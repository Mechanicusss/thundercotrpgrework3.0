silencer_glaives_of_wisdom_custom = class({})

LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_silencer_glaives_of_wisdom_custom", "heroes/hero_silencer/glaives", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_silencer_glaives_of_wisdom_custom_buff", "heroes/hero_silencer/glaives", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_silencer_glaives_of_wisdom_custom_debuff_shard", "heroes/hero_silencer/glaives", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

modifier_silencer_glaives_of_wisdom_custom_buff = class(ItemBaseClassBuff)
modifier_silencer_glaives_of_wisdom_custom_debuff_shard = class(ItemBaseClassDebuff)

modifier_silencer_glaives_of_wisdom_custom_debuff_shard.damage = 0
--------------------------------------------------------------------------------
-- Passive Modifier
function silencer_glaives_of_wisdom_custom:OnProjectileHit(hTarget, hLoc)
    if not IsServer() then return end 

    local caster = self:GetCaster()

    caster:PerformAttack(hTarget, true, true, true, false, false, false, false)
end

function silencer_glaives_of_wisdom_custom:GetIntrinsicModifierName()
    return "modifier_silencer_glaives_of_wisdom_custom"
end
--------------------------------------------------------------------------------
-- Ability Cast Filter
function silencer_glaives_of_wisdom_custom:CastFilterResultTarget( hTarget )
    local flag = 0
    local nResult = UnitFilter(
        hTarget,
        DOTA_UNIT_TARGET_TEAM_BOTH,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
        flag,
        self:GetCaster():GetTeamNumber()
    )
    if nResult ~= UF_SUCCESS then
        return nResult
    end

    return UF_SUCCESS
end

--------------------------------------------------------------------------------
-- Ability Start
function silencer_glaives_of_wisdom_custom:OnSpellStart()
end

--------------------------------------------------------------------------------
-- Orb Effects
function silencer_glaives_of_wisdom_custom:GetProjectileName()
    return "particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf"
end

function silencer_glaives_of_wisdom_custom:OnOrbFire( params )
    -- play effects
    local sound_cast = "Hero_Silencer.GlaivesOfWisdom"
    EmitSoundOn( sound_cast, self:GetCaster() )
end

function silencer_glaives_of_wisdom_custom:OnOrbImpact( params )
    local caster = self:GetCaster()

    -- int buff 
    -- we are applying it before the damage is dealt
    local buff = caster:FindModifierByName("modifier_silencer_glaives_of_wisdom_custom_buff")
    if not buff then
        buff = caster:AddNewModifier(caster, self, "modifier_silencer_glaives_of_wisdom_custom_buff", {
            duration = self:GetSpecialValueFor("int_gain_duration")
        })
    end

    if buff then
        if buff:GetStackCount() < self:GetSpecialValueFor("int_gain_max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end

    -- get damage
    local int_mult = self:GetSpecialValueFor( "intellect_damage_pct" )
    local damage = caster:GetBaseIntellect() * int_mult/100

    -- apply damage
    local damageTable = {
        victim = params.target,
        attacker = caster,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }
    ApplyDamage(damageTable)

    -- overhead message
    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
        params.target,
        damage,
        nil
    )

    -- play effects
    local sound_cast = "Hero_Silencer.GlaivesOfWisdom.Damage"
    EmitSoundOn( sound_cast, params.target )

    -- Shard debuff --
    if not caster:HasScepter() then return end

    if not params.no_attack_cooldown then
        local info = {
            iMoveSpeed = caster:GetProjectileSpeed(),
            EffectName = "particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf",
            Ability = self,
            Source = params.target
        }

        local victims = FindUnitsInRadius(caster:GetTeam(), params.target:GetAbsOrigin(), nil,
                self:GetSpecialValueFor("shard_bounce_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            if IsValidEntity(victim) and victim:IsAlive() and victim ~= params.target then
                info.Target = victim

                ProjectileManager:CreateTrackingProjectile(info)
                break
            end
        end
    end

    local shardDebuff = params.target:FindModifierByName("modifier_silencer_glaives_of_wisdom_custom_debuff_shard")
    if not shardDebuff then
        shardDebuff = params.target:AddNewModifier(caster, self, "modifier_silencer_glaives_of_wisdom_custom_debuff_shard", {
            duration = self:GetSpecialValueFor("shard_duration")
        })
    end

    if shardDebuff then
        if shardDebuff:GetStackCount() < self:GetSpecialValueFor("shard_max_stacks") then
            shardDebuff:IncrementStackCount()

            shardDebuff.damage = shardDebuff.damage + damage 
        end

        shardDebuff:ForceRefresh()
    end
end

modifier_silencer_glaives_of_wisdom_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_silencer_glaives_of_wisdom_custom:IsHidden()
    return true
end

function modifier_silencer_glaives_of_wisdom_custom:IsDebuff()
    return false
end

function modifier_silencer_glaives_of_wisdom_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_silencer_glaives_of_wisdom_custom:OnCreated( kv )
    self.steal = 2

    if not IsServer() then return end

    -- create generic orb effect
    self:GetParent():AddNewModifier(
        self:GetCaster(), -- player source
        self:GetAbility(), -- ability source
        "modifier_generic_orb_effect_lua", -- modifier name
        {  } -- kv
    )
end

function modifier_silencer_glaives_of_wisdom_custom:OnRefresh( kv )
    self.steal = 2

    if not IsServer() then return end
end

function modifier_silencer_glaives_of_wisdom_custom:OnRemoved()
end

function modifier_silencer_glaives_of_wisdom_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects


--------------------------------------------------------------------------------
-- Helper
function modifier_silencer_glaives_of_wisdom_custom:Steal( target )
    -- get steal number
    local steal = self.steal
    local target_int = target:GetBaseIntellect()
    if target_int<=1 then
        steal = 0
    elseif target_int-steal<1 then
        steal = target_int-1
    end

    -- steal
    self:GetParent():SetBaseIntellect( self:GetParent():GetBaseIntellect() + steal )
    target:SetBaseIntellect( target_int - steal )

    -- increment count
    self:SetStackCount( self:GetStackCount() + steal )

    -- overhead event
    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_MANA_ADD,
        self:GetParent(),
        steal,
        nil
    )
    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_MANA_LOSS,
        target,
        steal,
        nil
    )
end
---------------------
function modifier_silencer_glaives_of_wisdom_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS 
    }
end

function modifier_silencer_glaives_of_wisdom_custom_buff:GetModifierBonusStats_Intellect()
    return self.fTotal
end

function modifier_silencer_glaives_of_wisdom_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.total = 0

    self:StartIntervalThink(0.1)
end

function modifier_silencer_glaives_of_wisdom_custom_buff:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    --self.total = ((parent:GetBaseIntellect()-self.total) * (ability:GetSpecialValueFor("int_gain_pct")/100)) * self:GetStackCount()
    self.total = (parent:GetBaseIntellect() * (ability:GetSpecialValueFor("int_gain_pct")/100)) * self:GetStackCount()

    self:InvokeBonus()
end

function modifier_silencer_glaives_of_wisdom_custom_buff:OnIntervalThink()
    self:OnRefresh()
end

function modifier_silencer_glaives_of_wisdom_custom_buff:AddCustomTransmitterData()
    return
    {
        total = self.fTotal,
    }
end

function modifier_silencer_glaives_of_wisdom_custom_buff:HandleCustomTransmitterData(data)
    if data.total ~= nil then
        self.fTotal = tonumber(data.total)
    end
end

function modifier_silencer_glaives_of_wisdom_custom_buff:InvokeBonus()
    if IsServer() == true then
        self.fTotal = self.total

        self:SendBuffRefreshToClients()
    end
end
---------------
function modifier_silencer_glaives_of_wisdom_custom_debuff_shard:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self:StartIntervalThink(1.0)
end

function modifier_silencer_glaives_of_wisdom_custom_debuff_shard:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    local damage = self.damage

    ApplyDamage({
        victim = parent,
        attacker = caster,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    })

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
        parent,
        damage,
        nil
    )
end

function modifier_silencer_glaives_of_wisdom_custom_debuff_shard:OnRemoved()
    if not IsServer() then return end

    self.damage = 0
end