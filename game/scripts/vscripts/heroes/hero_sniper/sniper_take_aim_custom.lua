LinkLuaModifier("modifier_sniper_take_aim_custom", "heroes/hero_sniper/sniper_take_aim_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_take_aim_custom_casting", "heroes/hero_sniper/sniper_take_aim_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_take_aim_custom_shield", "heroes/hero_sniper/sniper_take_aim_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_take_aim_custom_crosshair", "heroes/hero_sniper/sniper_take_aim_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_take_aim_custom_scepter_buff", "heroes/hero_sniper/sniper_take_aim_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_take_aim_custom_scepter_cd", "heroes/hero_sniper/sniper_take_aim_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassCasting = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassbuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

sniper_take_aim_custom = class(ItemBaseClass)
modifier_sniper_take_aim_custom = class(sniper_take_aim_custom)
modifier_sniper_take_aim_custom_casting = class(ItemBaseClassCasting)
modifier_sniper_take_aim_custom_shield = class(ItemBaseClassbuff)
modifier_sniper_take_aim_custom_crosshair = class(ItemBaseClassDebuff)
modifier_sniper_take_aim_custom_scepter_buff = class(ItemBaseClassbuff)
modifier_sniper_take_aim_custom_scepter_cd = class(ItemBaseClassbuff)

function modifier_sniper_take_aim_custom_scepter_cd:IsHidden() return true end
-------------
function sniper_take_aim_custom:GetIntrinsicModifierName()
    return "modifier_sniper_take_aim_custom"
end

function sniper_take_aim_custom:GetAOERadius()
    return self:GetCaster():Script_GetAttackRange()
end

function sniper_take_aim_custom:GetChannelTime()
    return 6
end

function sniper_take_aim_custom:GetCastRange()
    return self:GetCaster():Script_GetAttackRange()
end

function sniper_take_aim_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    caster:AddNewModifier(target, self, "modifier_sniper_take_aim_custom_casting", {})
    caster:AddNewModifier(caster, self, "modifier_sniper_take_aim_custom_shield", {
        duration = 6
    })
    target:AddNewModifier(caster, self, "modifier_sniper_take_aim_custom_crosshair", {
        duration = 6
    })
end

function sniper_take_aim_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_sniper_take_aim_custom_casting")
end

function sniper_take_aim_custom:OnProjectileThink(vLocation)
    if not IsServer() then return end
end

function sniper_take_aim_custom:OnProjectileHit(hTarget, vLoc)
    if not IsServer() then return end

    if not hTarget then return end

    local caster = self:GetCaster()
    local ability = self

    EmitSoundOn("Hero_Sniper.AssassinateDamage", hTarget)

    if caster:HasScepter() then
        caster:AddNewModifier(caster, self, "modifier_sniper_take_aim_custom_scepter_cd", {})
    end

    caster:PerformAttack(
        hTarget,
        true,
        true,
        true,
        true,
        false,
        false,
        true
    )
end
-----------
function modifier_sniper_take_aim_custom_scepter_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK, 
    }
end

function modifier_sniper_take_aim_custom_scepter_buff:GetModifierPreAttack_CriticalStrike(params)
    if IsServer() then
        self.record = params.record

        return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
    end
end

function modifier_sniper_take_aim_custom_scepter_buff:GetModifierProcAttack_Feedback(params)
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end
end
-----------
function modifier_sniper_take_aim_custom_scepter_cd:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY
    }
end

function modifier_sniper_take_aim_custom_scepter_cd:OnAttackRecordDestroy(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end
    if not IsCreepTCOTRPG(event.target) and not IsBossTCOTRPG(event.target) then return end

    self:Destroy()
end
------------------
function modifier_sniper_take_aim_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK 
    }
end

function modifier_sniper_take_aim_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end
    if not IsCreepTCOTRPG(event.target) and not IsBossTCOTRPG(event.target) then return end
    if not parent:HasModifier("modifier_gun_joe_rifle") then return end

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("scepter_chance")
    if parent:HasModifier("modifier_sniper_take_aim_custom_scepter_cd") then return end
    if not parent:HasScepter() then return end
    if not RollPercentage(chance) then return end

    parent:AddNewModifier(parent, ability, "modifier_sniper_take_aim_custom_scepter_buff", {
        duration = ability:GetSpecialValueFor("scepter_buff_duration")
    })

    local projectileSpeed = ability:GetSpecialValueFor("projectile_speed")
    
    self.proj = {
        Target              = event.target,
        Source              = parent,
        Ability             = self:GetAbility(),
        EffectName          = "particles/econ/items/sniper/sniper_charlie/sniper_assassinate_charlie.vpcf",
        bDodgeable          = true,
        bProvidesVision     = false,
        iMoveSpeed          = projectileSpeed,
        iSourceAttachment   = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
    }

    ProjectileManager:CreateTrackingProjectile(self.proj)
    EmitSoundOn("Ability.Assassinate", parent)
end
-----------
function modifier_sniper_take_aim_custom_casting:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK, 
    }
end

function modifier_sniper_take_aim_custom_casting:GetModifierPreAttack_CriticalStrike(params)
    if IsServer() and not self:GetParent():HasModifier("modifier_sniper_take_aim_custom_scepter_buff") then
        self.record = params.record

        return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
    end
end

function modifier_sniper_take_aim_custom_casting:GetModifierProcAttack_Feedback(params)
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end
end

function modifier_sniper_take_aim_custom_casting:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("interval")

    if parent:HasModifier("modifier_item_aghanims_shard") then
        interval = ability:GetSpecialValueFor("shard_interval")
    end

    local projectileSpeed = ability:GetSpecialValueFor("projectile_speed")
    
    self.proj = {
        Target              = self:GetCaster(),
        Source              = parent,
        Ability             = self:GetAbility(),
        EffectName          = "particles/econ/items/sniper/sniper_charlie/sniper_assassinate_charlie.vpcf",
        bDodgeable          = true,
        bProvidesVision     = false,
        iMoveSpeed          = projectileSpeed,
        iSourceAttachment   = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
    }

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_sniper_take_aim_custom_casting:OnIntervalThink()
    EmitSoundOn("Ability.MKG_AssassinateLoad", self:GetParent())

    self:FireProj()
end

function modifier_sniper_take_aim_custom_casting:FireProj()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local pos = parent:GetAbsOrigin()
    local team = parent:GetTeamNumber()

    Timers:CreateTimer(1.37, function()
        if not parent:HasModifier("modifier_sniper_take_aim_custom_casting") then return end

        parent:StartGesture(ACT_DOTA_CAST_ABILITY_4)
        ProjectileManager:CreateTrackingProjectile(self.proj)
        EmitSoundOn("Ability.Assassinate", parent)
    end)
end

function modifier_sniper_take_aim_custom_casting:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_sniper_take_aim_custom_crosshair")
    parent:RemoveModifierByName("modifier_sniper_take_aim_custom_shield")

    parent:RemoveGesture(ACT_DOTA_CAST_ABILITY_4)
end
--------
function modifier_sniper_take_aim_custom_shield:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self:OnRefresh()

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_flame_cloak_shield_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControl( self.effect_cast, 1, parent:GetOrigin() )
end

function modifier_sniper_take_aim_custom_shield:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_sniper_take_aim_custom_shield:OnRefresh()
    if not IsServer() then return end

    local shieldAmount = self:GetParent():GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("shield_block_pct")/100)

    self.shield = shieldAmount
end

function modifier_sniper_take_aim_custom_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK, 
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK 
    }
end

function modifier_sniper_take_aim_custom_shield:GetModifierMagical_ConstantBlock(event)
    if self.shield <= 0 then return end

    local block = 0
    local negated = self.shield - event.damage 

    if negated <= 0 then
        block = self.shield
    else
        block = event.damage
    end

    self.shield = negated

    return block
end

function modifier_sniper_take_aim_custom_shield:GetModifierPhysical_ConstantBlock(event)
    if self.shield <= 0 then return end
    
    local block = 0
    local negated = self.shield - event.damage 

    if negated <= 0 then
        block = self.shield
    else
        block = event.damage
    end

    self.shield = negated

    return block
end
-----------
function modifier_sniper_take_aim_custom_crosshair:GetEffectName()
    return "particles/econ/items/sniper/sniper_charlie/sniper_crosshair__2charlie.vpcf"
end

function modifier_sniper_take_aim_custom_crosshair:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_sniper_take_aim_custom_crosshair:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()

    self.fow = AddFOWViewer(caster:GetTeam(), parent:GetAbsOrigin(), 600, self:GetRemainingTime(), true)
end

function modifier_sniper_take_aim_custom_crosshair:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()

    RemoveFOWViewer(caster:GetTeam(), self.fow)
end

function modifier_sniper_take_aim_custom_crosshair:IsDebuff() return false end
function modifier_sniper_take_aim_custom_crosshair:IsHidden() return true end