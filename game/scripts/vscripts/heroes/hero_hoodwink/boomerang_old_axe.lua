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
        victim = victim:entindex()
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
    self.cast_range = caster:Script_GetAttackRange()+50

    if caster:HasTalent("special_bonus_unique_hoodwink_3_custom") then
        self.damage = self.damage + (caster:GetAverageTrueAttackDamage(caster) * (caster:FindAbilityByName("special_bonus_unique_hoodwink_3_custom"):GetSpecialValueFor("value")/100))
    end

    self.hBoomerang:AddEffects(EF_NODRAW)
    self.hBoomerang:AddNewModifier(caster, ability, "modifier_hoodwink_hunters_boomerang_custom_invulnerable", {})

    self.hBoomerang.hit = {}
    self.hBoomerang.rotation = self.speed * 0.001

    local diff = caster:GetForwardVector()
    local diffNormalized = diff:Normalized()

    Timers:CreateTimer(0,function()
        self.hBoomerang:SetAbsOrigin(caster:GetAbsOrigin())
        self.hBoomerang:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,0,0), diffNormalized))
    end)

    Timers:CreateTimer(self.cast_range/self.speed,function()
        self.hBoomerang.retreat = true
    end)

    self.nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_hoodwink/hoodwink_boomerang.vpcf", PATTACH_CUSTOMORIGIN, nil )
    --ParticleManager:SetParticleControlEnt( self.nFXIndex, 0, self.hBoomerang, PATTACH_ABSORIGIN_FOLLOW, nil, self.hBoomerang:GetOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.nFXIndex, 1, self.hBoomerang, PATTACH_ABSORIGIN_FOLLOW, nil, victim:GetAbsOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.nFXIndex, 2, self.hBoomerang, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(self.spread, 0, 0), true )

    EmitSoundOn("Hero_Hoodwink.Boomerang.Cast", caster)

    self:StartIntervalThink(0.03)
end

function modifier_hoodwink_hunters_boomerang_custom_throwing:OnIntervalThink()
    local caster = self:GetCaster()
    local axe = self.hBoomerang
    local ability = self:GetAbility()

    local speed = self.speed/30

    local axePos = axe:GetAbsOrigin()
    local axeFv = axe:GetForwardVector()

    local rotation_gain = self.speed * 0.007

    local units = FindUnitsInRadius(caster:GetTeam() , axePos , nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

    for k,v in pairs(units) do
        if axe.hit[v] == nil then
            axe.hit[v] = true
            EmitSoundOn("Hero_Hoodwink.Boomerang.Target", v)
            local vf = ParticleManager:CreateParticle("particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_impact.vpcf", PATTACH_ABSORIGIN, v)
            ParticleManager:SetParticleControl(vf, 0, v:GetAbsOrigin())
            ParticleManager:ReleaseParticleIndex(vf)
            ApplyDamage({victim = v, attacker = caster, damage_type = ability:GetAbilityDamageType(), damage = self.damage,ability=ability,damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
            v:AddNewModifier(caster, ability, "modifier_hoodwink_hunters_boomerang_custom_debuff", {
                duration = ability:GetSpecialValueFor("mark_duration")
            })
        end
    end

    if axe.retreat == true then
        ParticleManager:SetParticleControlEnt( self.nFXIndex, 1, self.hBoomerang, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0, 0, 0), true )
        ParticleManager:SetParticleControlEnt( self.nFXIndex, 0, self.hBoomerang, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true )

        local destFv = (caster:GetAbsOrigin() - axePos):Normalized()
        local rotDiff = RotationDelta(VectorToAngles(axeFv), VectorToAngles(destFv))
        local rotation = axe.rotation
    
        if rotDiff.y<0 then
            if rotDiff.y < rotation then
                rotation = -rotation
            else
                rotation = rotDiff.y
            end
        elseif rotDiff.y>0 then
            if rotDiff.y > rotation then
                rotation = rotation
            else
                rotation = rotDiff.y
            end
        else
            rotation = 0
        end
    
        local newFv = RotatePosition(destFv, QAngle(0,rotation,0), axeFv)
        axe:SetForwardVector(newFv)
        axe:SetAbsOrigin(axePos + axeFv * speed)

        axe.rotation = axe.rotation + rotation_gain

        if (axe:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() < 75 then
            EmitSoundOn("Hero_Hoodwink.Boomerang.Return", caster)
            self:Destroy()
        end
    else
        axe:SetAbsOrigin(axePos + axeFv * speed)
    end
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