LinkLuaModifier("modifier_windranger_powershot_custom", "heroes/hero_windrunner/powershot_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_windranger_powershot_custom_debuff", "heroes/hero_windrunner/powershot_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_windranger_powershot_custom_scepter_buff", "heroes/hero_windrunner/powershot_custom", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

local BaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

windranger_powershot_custom = class(BaseClass)
modifier_windranger_powershot_custom = class(windranger_powershot_custom)
modifier_windranger_powershot_custom_debuff = class(BaseClassDebuff)
modifier_windranger_powershot_custom_scepter_buff = class(BaseClassBuff)

function windranger_powershot_custom:GetIntrinsicModifierName()
    return "modifier_windranger_powershot_custom"
end
--------------------------------------------------------------------------------
-- Projectile
-- projectile data table
_G.windranger_powershot_custom_projectiles = {}

function windranger_powershot_custom:GetBehavior()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
    else
        return DOTA_ABILITY_BEHAVIOR_PASSIVE 
    end
end

function windranger_powershot_custom:GetManaCost()
    if self:GetCaster():HasScepter() then return self:GetSpecialValueFor("mana_cost") end

    return self.BaseClass.GetManaCost(self, -1) or 0
end

function windranger_powershot_custom:GetCooldown()
    if self:GetCaster():HasScepter() then return self:GetSpecialValueFor("cooldown") end

    return self.BaseClass.GetCooldown(self, -1) or 0
end

function windranger_powershot_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_windranger_powershot_custom_scepter_buff", {
        duration = self:GetSpecialValueFor("duration")
    })
end

function windranger_powershot_custom:OnProjectileHitHandle( target, location, handle )
    if not target then
        -- unregister projectile
        _G.windranger_powershot_custom_projectiles[handle] = nil

        -- create Vision
        local vision_radius = self:GetSpecialValueFor( "vision_radius" )
        local vision_duration = self:GetSpecialValueFor( "vision_duration" )
        AddFOWViewer( self:GetCaster():GetTeamNumber(), location, vision_radius, vision_duration, false )

        return
    end

    -- get data
    local data = _G.windranger_powershot_custom_projectiles[handle]
    local damage = data.damage

    -- damage
    local damageTable = {
        victim = target,
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }
    ApplyDamage(damageTable)

    local buff = target:FindModifierByName("modifier_windranger_powershot_custom_debuff")
    if buff == nil then
        buff = target:AddNewModifier(self:GetCaster(), self, "modifier_windranger_powershot_custom_debuff", {
            duration = self:GetSpecialValueFor("debuff_duration")
        })
    end

    if buff ~= nil then
        if buff:GetStackCount() < self:GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end
        buff:ForceRefresh()
    end

    -- reduce damage
    data.damage = damage

    -- Play effects
    local sound_cast = "Hero_Windrunner.PowershotDamage"
    EmitSoundOn( sound_cast, target )
end

function windranger_powershot_custom:OnProjectileThink( location )
    -- destroy trees
    --local tree_width = self:GetSpecialValueFor( "tree_width" )
    --GridNav:DestroyTreesAroundPoint(location, tree_width, false)    
end
----------
function modifier_windranger_powershot_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }
    return funcs
end

function modifier_windranger_powershot_custom:OnAttack(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() or caster:IsIllusion() then
        return
    end

    if event.attacker:IsIllusion() then return end

    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")

    if not ability:IsCooldownReady() then return end
    if not RollPercentage(chance) then return end

    if caster:HasModifier("modifier_windranger_powershot_custom_scepter_buff") then
        chance = 100
    end

    --if not ability:IsCooldownReady() then return end


    -- Play effects
    local sound_cast = "Hero_Windrunner.Powershot.FalconBow"
    EmitSoundOn( sound_cast, caster )

    --local point = self:GetCursorPosition()
    local point = caster:GetForwardVector()
    --local channel_pct = (GameRules:GetGameTime() - self:GetChannelStartTime())/self:GetChannelTime()

    -- load data
    local damage = ability:GetSpecialValueFor( "powershot_damage" ) + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_damage")/100))
    local vision_radius = ability:GetSpecialValueFor( "vision_radius" )
    
    local projectile_name = "particles/econ/items/windrunner/windrunner_ti6/windrunner_spell_powershot_ti6.vpcf"
    local projectile_speed = ability:GetSpecialValueFor( "arrow_speed" )
    local projectile_distance = ability:GetSpecialValueFor( "arrow_range" )
    local projectile_radius = ability:GetSpecialValueFor( "arrow_width" )
    local projectile_direction = point
    projectile_direction.z = 0
    projectile_direction = projectile_direction:Normalized()

    -- create projectile
    local info = {
        Source = caster,
        Ability = ability,
        vSpawnOrigin = caster:GetAbsOrigin(),
        
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        
        EffectName = projectile_name,
        fDistance = projectile_distance,
        fStartRadius = projectile_radius,
        fEndRadius = projectile_radius,
        vVelocity = projectile_direction * projectile_speed,
    
        bProvidesVision = true,
        iVisionRadius = vision_radius,
        iVisionTeamNumber = caster:GetTeamNumber(),
    }


    local projectile = ProjectileManager:CreateLinearProjectile(info)

    -- register projectile data
    _G.windranger_powershot_custom_projectiles[projectile] = {}
    _G.windranger_powershot_custom_projectiles[projectile].damage = damage

    if caster:HasModifier("modifier_item_aghanims_shard") then
        -- First
        local count = 3
        local fullAngle = 60
        local factor = fullAngle/(count-1)

        vDirection = RotatePosition(Vector(0,0,0), QAngle(0, 20, 0), projectile_direction)

        local shardDirection = vDirection
        shardDirection.z = 0
        shardDirection = shardDirection:Normalized()

        info.vVelocity = shardDirection * projectile_speed
        
        local projectile2 = ProjectileManager:CreateLinearProjectile(info)
        -- register projectile data
        _G.windranger_powershot_custom_projectiles[projectile2] = {}
        _G.windranger_powershot_custom_projectiles[projectile2].damage = damage

        -- Second
        vDirection = RotatePosition(Vector(0,0,0), QAngle(0, -20, 0), projectile_direction)

        local shardDirection = vDirection
        shardDirection.z = 0
        shardDirection = shardDirection:Normalized()

        info.vVelocity = shardDirection * projectile_speed
        
        local projectile3 = ProjectileManager:CreateLinearProjectile(info)
        -- register projectile data
        _G.windranger_powershot_custom_projectiles[projectile3] = {}
        _G.windranger_powershot_custom_projectiles[projectile3].damage = damage
    end
end
-----------
function modifier_windranger_powershot_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function modifier_windranger_powershot_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res_pct") * self:GetStackCount()
end

function modifier_windranger_powershot_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end