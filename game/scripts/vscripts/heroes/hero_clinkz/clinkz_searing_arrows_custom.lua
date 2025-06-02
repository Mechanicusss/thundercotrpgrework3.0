LinkLuaModifier("modifier_clinkz_searing_arrows_custom", "heroes/hero_clinkz/clinkz_searing_arrows_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_searing_arrows_custom_counter", "heroes/hero_clinkz/clinkz_searing_arrows_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_searing_arrows_custom_burning", "heroes/hero_clinkz/clinkz_searing_arrows_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassCounter = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

clinkz_searing_arrows_custom = class(ItemBaseClass)
modifier_clinkz_searing_arrows_custom = class(clinkz_searing_arrows_custom)
modifier_clinkz_searing_arrows_custom_counter = class(ItemBaseClassCounter)
modifier_clinkz_searing_arrows_custom_burning = class(ItemBaseClassDebuff)
-------------
function clinkz_searing_arrows_custom:GetIntrinsicModifierName()
    return "modifier_clinkz_searing_arrows_custom"
end

function clinkz_searing_arrows_custom:OnProjectileHit(target, location)
    if not target then return end

    -- perform attack
    self.split_shot_attack = true
    self:GetCaster():PerformAttack(
        target, -- hTarget
        false, -- bUseCastAttackOrb
        false, -- bProcessProcs
        true, -- bSkipCooldown
        false, -- bIgnoreInvis
        false, -- bUseProjectile
        false, -- bFakeAttack
        false -- bNeverMiss
    )
    self.split_shot_attack = false
end
------------
function modifier_clinkz_searing_arrows_custom:GetPriority()
    return MODIFIER_PRIORITY_HIGH
end

function modifier_clinkz_searing_arrows_custom:OnCreated( kv )
    -- references
    self.reduction = self:GetAbility():GetSpecialValueFor( "damage_modifier" )
    self.count = self:GetAbility():GetSpecialValueFor( "arrow_count" )
    self.bonus_range = self:GetAbility():GetSpecialValueFor( "split_shot_bonus_range" )

    self.parent = self:GetParent()

    -- will be changed dynamically for talents
    self.use_modifier = false

    if not IsServer() then return end
    self.projectile_name = self.parent:GetRangedProjectileName()
    self.projectile_speed = self.parent:GetProjectileSpeed()
end

function modifier_clinkz_searing_arrows_custom:OnRefresh( kv )
    -- references
    self.reduction = self:GetAbility():GetSpecialValueFor( "damage_modifier" )
    self.count = self:GetAbility():GetSpecialValueFor( "arrow_count" )
    self.bonus_range = self:GetAbility():GetSpecialValueFor( "split_shot_bonus_range" )
end

function modifier_clinkz_searing_arrows_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        --MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
    }
    return funcs
end

function modifier_clinkz_searing_arrows_custom:OnAttack(params)
    if not IsServer() then return end

    if params.attacker ~= self:GetParent() then return end

    EmitSoundOn("Hero_Clinkz.SearingArrows", self:GetParent())

    if not params.attacker:HasModifier("modifier_item_aghanims_shard") then return end
    
    -- not proc for instant attacks
    if params.no_attack_cooldown then return end

    -- not proc for attacking allies
    if params.target:GetTeamNumber()==params.attacker:GetTeamNumber() then return end

    -- not proc if break
    if self.parent:PassivesDisabled() then return end

    -- not proc if attack can't use attack modifiers
    if not params.process_procs then return end

    -- not proc on split shot attacks, even if it can use attack modifier, to avoid endless recursive call and crash
    if self.split_shot then return end

    -- split shot
    if self.use_modifier then
        self:SplitShotModifier( params.target )
    else
        self:SplitShotNoModifier( params.target )
    end
end

function modifier_clinkz_searing_arrows_custom:GetModifierDamageOutgoing_Percentage()
    if not IsServer() then return end
    
    -- if uses modifier
    if self.split_shot then
        return self.reduction
    end

    -- if not use modifier
    if self:GetAbility().split_shot_attack then
        return self.reduction
    end
end

function modifier_clinkz_searing_arrows_custom:SplitShotModifier( target )
    -- get radius
    local radius = self.parent:Script_GetAttackRange() + self.bonus_range

    -- find other target units
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),    -- int, your team number
        self.parent:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_COURIER,  -- int, type filter
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,    -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    -- get targets
    local count = 0
    for _,enemy in pairs(enemies) do
        -- not target itself
        if enemy~=target then

            -- perform attack
            self.split_shot = true
            self.parent:PerformAttack(
                enemy, -- hTarget
                false, -- bUseCastAttackOrb
                self.use_modifier, -- bProcessProcs
                true, -- bSkipCooldown
                false, -- bIgnoreInvis
                true, -- bUseProjectile
                false, -- bFakeAttack
                false -- bNeverMiss
            )
            self.split_shot = false

            count = count + 1
            if count>=self.count then break end
        end
    end

    -- play effects if splitshot
    if count>0 then
        local sound_cast = "Hero_Medusa.AttackSplit"
        EmitSoundOn( sound_cast, self.parent )
    end
end

function modifier_clinkz_searing_arrows_custom:SplitShotNoModifier( target )
    -- get radius
    local radius = self.parent:Script_GetAttackRange() + self.bonus_range

    -- find other target units
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),    -- int, your team number
        self.parent:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_COURIER,  -- int, type filter
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,    -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    -- get targets
    local count = 0
    for _,enemy in pairs(enemies) do
        -- not target itself
        if enemy~=target then
            -- launch projectile
            local info = {
                Target = enemy,
                Source = self.parent,
                Ability = self:GetAbility(),    
                
                EffectName = self.projectile_name,
                iMoveSpeed = self.projectile_speed,
                bDodgeable = true,                           -- Optional
                -- bIsAttack = true,                                -- Optional
            }
            ProjectileManager:CreateTrackingProjectile(info)

            count = count + 1
            if count>=self.count then break end
        end
    end

    -- play effects if splitshot
    if count>0 then
        local sound_cast = "Hero_Medusa.AttackSplit"
        EmitSoundOn( sound_cast, self.parent )
    end
end

function modifier_clinkz_searing_arrows_custom:GetModifierProjectileName()
    return "particles/units/heroes/hero_clinkz/clinkz_searing_arrow.vpcf"
end

function modifier_clinkz_searing_arrows_custom:OnAttackLanded(params)
    if IsServer() then
        -- get target
        local parent = self:GetParent()

        if params.attacker ~= parent or params.target == parent then return end

        local target = params.target

        local bonus = self:GetAbility():GetSpecialValueFor("agility_damage_bonus")

        local buff = parent:FindModifierByName("modifier_clinkz_searing_arrows_custom_counter")
        if not buff then
            buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_clinkz_searing_arrows_custom_counter", { duration = self:GetAbility():GetSpecialValueFor("stack_duration") })
        end

        if buff then
            if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
                buff:IncrementStackCount()
            end

            buff:ForceRefresh()

            bonus = bonus + (buff:GetStackCount() * self:GetAbility():GetSpecialValueFor("stack_agility_increase"))
        end

        local total = parent:GetAgility() * (bonus/100)

        EmitSoundOn("Hero_Clinkz.SearingArrows.Impact", parent)

        local burning = target:FindModifierByName("modifier_clinkz_searing_arrows_custom_burning")
        if not burning then
            burning = target:AddNewModifier(parent, self:GetAbility(), "modifier_clinkz_searing_arrows_custom_burning", {
                duration = self:GetAbility():GetSpecialValueFor("burn_duration")
            })
        end

        if burning then
            burning:ForceRefresh()
        end
        
        ApplyDamage({
            attacker = parent,
            victim = params.target,
            damage = total,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = self:GetAbility()
        })
    end
end

-----
function modifier_clinkz_searing_arrows_custom_counter:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("agility_damage_bonus") + (self:GetAbility():GetSpecialValueFor("stack_agility_increase") * self:GetStackCount())
end

function modifier_clinkz_searing_arrows_custom_counter:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOOLTIP 
    }
    return funcs
end
------------------------------
function modifier_clinkz_searing_arrows_custom_burning:OnCreated()
    if not IsServer() then return end

    self:OnIntervalThink()
    self:StartIntervalThink(0.5)
end

function modifier_clinkz_searing_arrows_custom_burning:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local damageMultiplier = ability:GetSpecialValueFor("agility_damage_bonus")
    local counter = caster:FindModifierByName("modifier_clinkz_searing_arrows_custom_counter")
    if counter then
        damageMultiplier = damageMultiplier + (ability:GetSpecialValueFor("stack_agility_increase") * counter:GetStackCount())
    end

    local damage = caster:GetAgility() * (damageMultiplier/100)

    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = ability
    })
end

function modifier_clinkz_searing_arrows_custom_burning:GetEffectName()
    return "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf"
end