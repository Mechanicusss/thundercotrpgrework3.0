LinkLuaModifier("modifier_ancient_apparition_ice_blast_custom", "heroes/hero_ancient_apparition/ancient_apparition_ice_blast_custom", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_ancient_apparition_ice_blast_custom_debuff", "heroes/hero_ancient_apparition/ancient_apparition_ice_blast_custom", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_ancient_apparition_ice_blast_custom_frozen", "heroes/hero_ancient_apparition/ancient_apparition_ice_blast_custom", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_ancient_apparition_ice_blast_custom_slowed", "heroes/hero_ancient_apparition/ancient_apparition_ice_blast_custom", LUA_MODIFIER_MOTION_BOTH)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

ancient_apparition_ice_blast_custom = class(ItemBaseClass)
ancient_apparition_ice_blast_stop_custom = class(ItemBaseClass)
modifier_ancient_apparition_ice_blast_custom = class(ItemBaseClassBuff)
modifier_ancient_apparition_ice_blast_custom_debuff = class(ItemBaseClassDebuff)
modifier_ancient_apparition_ice_blast_custom_frozen = class(ItemBaseClassDebuff)
modifier_ancient_apparition_ice_blast_custom_slowed = class(ItemBaseClassDebuff)
-------------
function ancient_apparition_ice_blast_stop_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_ancient_apparition_ice_blast_custom")
end
-------------
function ancient_apparition_ice_blast_custom:OnProjectileHit(target, loc)
    if target:IsMagicImmune() or target:IsInvulnerable() then return end
    
    local caster = self:GetCaster()
    local ability = caster:FindAbilityByName("ancient_apparition_chilling_touch_custom")

    if not ability or (ability ~= nil and ability:GetLevel() < 1) then return end

    local intellectDamage = 0

    if caster:IsRealHero() then
        intellectDamage = caster:GetBaseIntellect()
    end

    local damage = ability:GetSpecialValueFor("damage") + (intellectDamage * (ability:GetSpecialValueFor("int_to_damage")/100))
    local damageTable = {
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_MAGIC_AUTO_ATTACK,
        ability = ability
    }

    ApplyDamage(damageTable)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, damage, nil)
    
    target:AddNewModifier(caster, ability, "modifier_ancient_apparition_ice_blast_custom_slowed", { duration = ability:GetSpecialValueFor("duration") })
    
    if caster:HasModifier("modifier_item_aghanims_shard") then
        local radius = ability:GetSpecialValueFor("radius")

        local victims = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil,
                radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
                FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            if victim:IsAlive() and not victim:IsMagicImmune() and not victim:IsInvulnerable() and victim ~= target then
                damageTable.victim = victim

                ApplyDamage(damageTable)

                SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, damage, nil)
                victim:AddNewModifier(caster, ability, "modifier_ancient_apparition_ice_blast_custom_slowed", { duration = ability:GetSpecialValueFor("duration") })
            end
        end
    end

    EmitSoundOn("Hero_Ancient_Apparition.ChillingTouch.Target", target)
end

function ancient_apparition_ice_blast_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_ancient_apparition_ice_blast_custom", {
        duration = self:GetSpecialValueFor("duration")
    })

    EmitSoundOn("Hero_Ancient_Apparition.IceBlastRelease.Cast.Self", caster)
end
------------
function modifier_ancient_apparition_ice_blast_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ORDER,
        MODIFIER_PROPERTY_DISABLE_TURNING,
    }
end

function modifier_ancient_apparition_ice_blast_custom:OnCreated()
    if not IsServer() then return end 

    self.parent = self:GetParent()

    -- turning data
    self.turn_speed = self:GetAbility():GetSpecialValueFor( "turn_rate" )
    self.target_angle = self.parent:GetAnglesAsVector().y
    self.current_angle = self.target_angle
    self.face_target = true
    self.touched_wall = false

    self.vfx = ParticleManager:CreateParticle("particles/econ/items/ancient_apparition/aa_blast_ti_5/ancient_apparition_ice_blast__2final_ti5.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(self.vfx, 0, self.parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 5, Vector(9999, 1, 1)) -- The first parameter is how long until it explodes in seconds

    self.parent:AddNoDraw()

    self.speed = self:GetAbility():GetSpecialValueFor("speed")

    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
        return
    end

    self:SetPriority(DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST)

    self:StartIntervalThink(0.2)

    local sub = self.parent:AddAbility("ancient_apparition_ice_blast_stop_custom")
    sub:SetLevel(1)

    self.parent:SwapAbilities(
        "ancient_apparition_ice_blast_stop_custom",
        "ancient_apparition_ice_blast_custom",
        true,
        false
    )
end

function modifier_ancient_apparition_ice_blast_custom:FireChillingTouch(target)
    local parent = self:GetParent()

    local info = {
        Target = target,
        Source = parent,
        EffectName = "particles/units/heroes/hero_ancient_apparition/ancient_apparition_chilling_touch_projectile.vpcf",
        bDodgeable = false,
        bProvidesVision = true,
        iMoveSpeed = parent:GetProjectileSpeed(),
        iVisionRadius = 150,
        iVisionTeamNumber = parent:GetTeamNumber(),
        Ability = self:GetAbility()
    }

    ProjectileManager:CreateTrackingProjectile(info)
end

function modifier_ancient_apparition_ice_blast_custom:OnIntervalThink()
    ParticleManager:SetParticleControl(self.vfx, 0, self.parent:GetAbsOrigin())

    self:TurnLogic(FrameTime())

    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("frostbite_radius")

    local units = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            unit:AddNewModifier(self.parent, ability, "modifier_ancient_apparition_ice_blast_custom_debuff", {
                duration = ability:GetSpecialValueFor("frostbite_duration")
            })
        end
    end

    if not self.parent:HasScepter() then return end 
    if #units < 1 then return end

    local chillingTouch = self.parent:FindAbilityByName("ancient_apparition_chilling_touch_custom")

    if chillingTouch ~= nil and chillingTouch:GetLevel() > 0 then
        EmitSoundOn("Hero_Ancient_Apparition.ChillingTouch.Cast", self.parent)
        self:FireChillingTouch(units[RandomInt(1, #units)])
    end
end

function modifier_ancient_apparition_ice_blast_custom:OnRemoved()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")
    local damage = ability:GetSpecialValueFor("damage") + (self.parent:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    damage = damage * (1+((self:GetElapsedTime() * ability:GetSpecialValueFor("damage_increase_per_sec_pct"))/100))

    self.parent:RemoveNoDraw()

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    local explosionVfx = ParticleManager:CreateParticle("particles/econ/items/ancient_apparition/aa_blast_ti_5/ancient_apparition_ice_blast_explode_ti5.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(explosionVfx, 0, self.parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(explosionVfx, 3, self.parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(explosionVfx)

    EmitSoundOn("Hero_Ancient_Apparition.IceBlast.Target", self.parent)

    local units = FindUnitsInRadius(self.parent:GetTeam(), self.parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            ApplyDamage({
                victim = unit,
                attacker = self.parent,
                damage = damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = ability
            })

            unit:AddNewModifier(self.parent, ability, "modifier_ancient_apparition_ice_blast_custom_frozen", {
                duration = ability:GetSpecialValueFor("frozen_duration")
            })

            EmitSoundOn("Hero_Ancient_Apparition.ColdFeetFreeze", unit)
        end
    end

    self.parent:RemoveHorizontalMotionController(self)

    self.parent:SwapAbilities(
        "ancient_apparition_ice_blast_stop_custom",
        "ancient_apparition_ice_blast_custom",
        false,
        true
    )

    self.parent:RemoveAbility("ancient_apparition_ice_blast_stop_custom")
end

function modifier_ancient_apparition_ice_blast_custom:CheckState()
    return {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_PROVIDES_VISION] = true
    }
end

function modifier_ancient_apparition_ice_blast_custom:UpdateHorizontalMotion( me, dt )
    local currentPosition = me:GetOrigin()
    local forwardVector = me:GetForwardVector()

    local nextPos = currentPosition + forwardVector * self.speed * dt

    if not GridNav:IsTraversable(nextPos) and self.touched_wall then
        self.touched_wall = false
    elseif not GridNav:IsTraversable(nextPos) and not self.touched_wall then
        self.touched_wall = true
    end

    if self.touched_wall then
        -- Calculate the new direction by reversing and reflecting the current direction vector
        local reverseDirection = -forwardVector
        local newDirection = reverseDirection + Vector(0, 0, 0) -- Reflecting the direction
        nextPos = currentPosition + newDirection * self.speed * dt
    end

    ParticleManager:SetParticleControl(self.vfx, 0, nextPos)

    self:TurnLogic(dt)

    me:SetOrigin(nextPos)
end

function modifier_ancient_apparition_ice_blast_custom:OnHorizontalMotionInterrupted()
    self:Destroy()
end

function modifier_ancient_apparition_ice_blast_custom:TurnLogic(dt)
    -- only rotate when target changed
    if self.face_target then return end

    local angle_diff = AngleDiff( self.current_angle, self.target_angle )
    local turn_speed = self.turn_speed*dt

    local sign = -1
    if angle_diff<0 then sign = 1 end

    if math.abs( angle_diff )<1.1*turn_speed then
        -- end rotating
        self.current_angle = self.target_angle
        self.face_target = true
    else
        -- rotate current angle
        if self.touched_wall then
            self.current_angle = self.current_angle - sign*turn_speed
        else
            self.current_angle = self.current_angle + sign*turn_speed
        end
    end

    -- turn the unit
    local angles = self.parent:GetAnglesAsVector()

    self.parent:SetLocalAngles( angles.x, self.current_angle, angles.z )
end

function modifier_ancient_apparition_ice_blast_custom:GetPriority()
    return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_ancient_apparition_ice_blast_custom:GetMotionPriority()
    return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_ancient_apparition_ice_blast_custom:OnOrder( params )
    if params.unit~=self:GetParent() then return end

    -- point right click
    if  params.order_type==DOTA_UNIT_ORDER_MOVE_TO_POSITION then
        ExecuteOrderFromTable({
            UnitIndex = self.parent:entindex(),
            OrderType = DOTA_UNIT_ORDER_MOVE_TO_DIRECTION,
            Position = params.new_pos,
        })
    elseif
        params.order_type==DOTA_UNIT_ORDER_MOVE_TO_DIRECTION
    then
        -- set facing
        self:SetDirection( params.new_pos )

    -- targetted right click
    elseif 
        params.order_type==DOTA_UNIT_ORDER_MOVE_TO_TARGET or
        params.order_type==DOTA_UNIT_ORDER_ATTACK_TARGET
    then
        -- set facing
        self:SetDirection( params.target:GetOrigin() )
    
    elseif
        params.order_type==DOTA_UNIT_ORDER_STOP or 
        params.order_type==DOTA_UNIT_ORDER_HOLD_POSITION
    then
        self:Destroy()
    end 
end

function modifier_ancient_apparition_ice_blast_custom:GetModifierDisableTurning()
    return 1
end

function modifier_ancient_apparition_ice_blast_custom:SetDirection( location )
    local dir = ((location-self.parent:GetOrigin())*Vector(1,1,0)):Normalized()
    self.target_angle = VectorToAngles( dir ).y
    self.face_target = false
end
-----------------
function modifier_ancient_apparition_ice_blast_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_debuff.vpcf"
end

function modifier_ancient_apparition_ice_blast_custom_debuff:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(1.0)
end

function modifier_ancient_apparition_ice_blast_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_HEALING 
    }
end

function modifier_ancient_apparition_ice_blast_custom_debuff:GetDisableHealing()
    return 1
end

function modifier_ancient_apparition_ice_blast_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local damage = parent:GetMaxHealth() * (ability:GetSpecialValueFor("max_hp_damage_pct")/100)

    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })

    if parent:GetHealthPercent() <= ability:GetSpecialValueFor("execution_threshold") then
        ApplyDamage({
            attacker = caster,
            victim = parent,
            damage = parent:GetMaxHealth(),
            damage_type = DAMAGE_TYPE_PURE
        })
    end

    EmitSoundOn("Hero_Ancient_Apparition.IceBlastRelease.Tick", parent)
end
-----------------
function modifier_ancient_apparition_ice_blast_custom_frozen:GetEffectName()
    return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_cold_feet_frozen.vpcf"
end

function modifier_ancient_apparition_ice_blast_custom_frozen:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true
    }
end
-----
function modifier_ancient_apparition_ice_blast_custom_slowed:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function modifier_ancient_apparition_ice_blast_custom_slowed:GetModifierMoveSpeedBonus_Percentage()
    return -100
end

function modifier_ancient_apparition_ice_blast_custom_slowed:GetEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end