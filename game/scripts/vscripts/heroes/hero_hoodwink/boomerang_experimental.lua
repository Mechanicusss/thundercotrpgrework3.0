LinkLuaModifier("modifier_hoodwink_hunters_boomerang_custom", "heroes/hero_hoodwink/hoodwink_hunters_boomerang_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_hunters_boomerang_custom_throwing", "heroes/hero_hoodwink/hoodwink_hunters_boomerang_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_hunters_boomerang_custom_invulnerable", "heroes/hero_hoodwink/hoodwink_hunters_boomerang_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_hunters_boomerang_custom_debuff", "heroes/hero_hoodwink/hoodwink_hunters_boomerang_custom", LUA_MODIFIER_MOTION_NONE)

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

hoodwink_hunters_boomerang_custom = class(ItemBaseClass)
modifier_hoodwink_hunters_boomerang_custom = class(hoodwink_hunters_boomerang_custom)
modifier_hoodwink_hunters_boomerang_custom_debuff = class(ItemBaseClassDebuff)
modifier_hoodwink_hunters_boomerang_custom_invulnerable = class(ItemBaseClass)
modifier_hoodwink_hunters_boomerang_custom_throwing = class(ItemBaseClass)
-------------
function hoodwink_hunters_boomerang_custom:GetIntrinsicModifierName()
    return "modifier_hoodwink_hunters_boomerang_custom"
end

function hoodwink_hunters_boomerang_custom:GetCooldown()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("special_bonus_unique_hoodwink_5_custom")
    if talent ~= nil and talent:GetLevel() > 0 then
        return 0
    end

    return self.BaseClass.GetCooldown(self, -1) or 0
end
---------------------------------
function modifier_hoodwink_hunters_boomerang_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE 
    }
end

function modifier_hoodwink_hunters_boomerang_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    local total = self:GetAbility():GetSpecialValueFor("slow_pct")
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("special_bonus_unique_hoodwink_6_custom")

    if talent ~= nil and talent:GetLevel() > 0 then
        total = total + talent:GetSpecialValueFor("value")
    end

    return total
end

function modifier_hoodwink_hunters_boomerang_custom_debuff:GetModifierIncomingPhysicalDamage_Percentage()
    local total = self:GetAbility():GetSpecialValueFor("damage_increase")
    local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_hoodwink_4_custom")
    if talent ~= nil and talent:GetLevel() > 0 then
        total = total + talent:GetSpecialValueFor("value")
    end

    return total
end

function modifier_hoodwink_hunters_boomerang_custom_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    EmitSoundOn("Hero_Hoodwink.Boomerang.Slow", parent)
end

function modifier_hoodwink_hunters_boomerang_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_hoodwink_hunters_boomerang_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_hoodwink/hoodwink_hunters_mark.vpcf"
end
-----------------
function modifier_hoodwink_hunters_boomerang_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK 
    }
    return funcs
end

function modifier_hoodwink_hunters_boomerang_custom:OnAttack(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:IsSilenced() or unit:IsIllusion() then
        return
    end

    self.hHitEntities = {}

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() or not ability:IsActivated() then return end

    caster:AddNewModifier(caster, ability, "modifier_hoodwink_hunters_boomerang_custom_throwing", {
        victim = victim:entindex(),
        duration = 2
    })

    ability:SetActivated(false)
end
----------------------------------------

function modifier_hoodwink_hunters_boomerang_custom_throwing:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()

    local victim = EntIndexToHScript(params.victim)

    local ability = self:GetAbility()

    self.hBoomerang = CreateUnitByName( "npc_dota_hoodwink_boomerang", caster:GetOrigin(), false, nil, nil, caster:GetTeamNumber() )
    if self.hBoomerang == nil then
        self:Destroy()
        return      
    end

    local specialDamage = ability:GetSpecialValueFor("damage")
    if caster:HasTalent("special_bonus_unique_hoodwink_7_custom") then
        specialDamage = specialDamage + caster:FindAbilityByName("special_bonus_unique_hoodwink_7_custom"):GetSpecialValueFor("value")
    end
    
    self.damage = specialDamage + (caster:GetAgility() * (ability:GetSpecialValueFor("agi_to_damage")/100))
    self.debuff_duration = ability:GetSpecialValueFor("mark_duration")
    self.radius = ability:GetSpecialValueFor("radius")
    self.spread = ability:GetSpecialValueFor("spread")
    self.speed = ability:GetSpecialValueFor("speed")
    self.duration = 2
    self.cast_range = caster:Script_GetAttackRange()

    if caster:HasTalent("special_bonus_unique_hoodwink_3_custom") then
        self.damage = self.damage + (caster:GetAverageTrueAttackDamage(caster) * (caster:FindAbilityByName("special_bonus_unique_hoodwink_3_custom"):GetSpecialValueFor("value")/100))
    end

    self.hBoomerang:AddEffects(EF_NODRAW)
    self.hBoomerang:AddNewModifier(caster, ability, "modifier_hoodwink_hunters_boomerang_custom_invulnerable", {})

    self.hBoomerang.hit = {}

    --0 = this is from point B to point A, where B is target and A is hoodwink (in its returning state)
    --1 = this is from point A to B, where A is hoodwink and B is the target (in it's throwing/approaching target state)
    self.nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_hoodwink/hoodwink_boomerang_2.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControlEnt( self.nFXIndex, 0, self.hBoomerang, PATTACH_POINT_FOLLOW, nil, self.hBoomerang:GetAbsOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.nFXIndex, 1, self.hBoomerang, PATTACH_POINT_FOLLOW, nil, self.hBoomerang:GetAbsOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.nFXIndex, 2, self.hBoomerang, PATTACH_POINT_FOLLOW, nil, Vector(self.speed, 0, 0), true )

    EmitSoundOn("Hero_Hoodwink.Boomerang.Cast", caster)
    
    self.casterOrigin  = self.hBoomerang:GetAbsOrigin()
    self.casterAngles  = self.hBoomerang:GetAngles()
    self.forwardDir    = self.hBoomerang:GetForwardVector()
    self.rightDir      = self.hBoomerang:GetRightVector()

    self.startTime = GameRules:GetGameTime()
    self.ellipseCenter = self.casterOrigin + self.forwardDir * ( self.spread / 2 )

    self:StartIntervalThink(0.03)
end

function modifier_hoodwink_hunters_boomerang_custom_throwing:OnIntervalThink()
    local elapsedTime = GameRules:GetGameTime() - self.startTime
    local progress = elapsedTime / self.duration
    self.progress = progress

    -- check for interrupted
    if self.progress >= 0.5 then
        -- returning
    end

    -- Calculate potision
    local theta = -2 * math.pi * progress
    local x =  math.sin( theta ) * self.spread * 0.5
    local y = -math.cos( theta ) * self.cast_range * 0.5

    local pos = self.ellipseCenter + self.rightDir * x + self.forwardDir * y
    local yaw = self.casterAngles.y + 90 + progress * -360

    pos = GetGroundPosition( pos, self.hBoomerang )
    self.hBoomerang:SetAbsOrigin( pos )
    self.hBoomerang:SetAngles( self.casterAngles.x, yaw, self.casterAngles.z )
end

function modifier_hoodwink_hunters_boomerang_custom_throwing:OnDestroy()
    if IsServer() then
        UTIL_Remove( self.hBoomerang )
        ParticleManager:DestroyParticle( self.nFXIndex, true )
        self:GetAbility():SetActivated(true)
        self:GetAbility():UseResources(false, false, false, true)
    end
end
-------------
function modifier_hoodwink_hunters_boomerang_custom_invulnerable:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true
    }
end