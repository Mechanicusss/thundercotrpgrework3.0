--[[
Credits for the Grimstroke Ink Creature code goes to the Dota IMBA team. Big thanks to them!
https://github.com/EarthSalamander42/dota_imba
]]--
LinkLuaModifier("modifier_grimstroke_ink_creature_custom", "heroes/hero_grimstroke/grimstroke_ink_creature_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_ink_creature_custom_latched", "heroes/hero_grimstroke/grimstroke_ink_creature_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_ink_creature_custom_debuff", "heroes/hero_grimstroke/grimstroke_ink_creature_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_ink_creature_custom_ai", "heroes/hero_grimstroke/grimstroke_ink_creature_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_ink_creature_custom_cooldown", "heroes/hero_grimstroke/grimstroke_ink_creature_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
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

grimstroke_ink_creature_custom = class(ItemBaseClass)
modifier_grimstroke_ink_creature_custom = class(grimstroke_ink_creature_custom)
modifier_grimstroke_ink_creature_custom_ai = class(ItemBaseClass)
modifier_grimstroke_ink_creature_custom_cooldown = class(ItemBaseClass)
modifier_grimstroke_ink_creature_custom_debuff = class(ItemBaseClassDebuff)
modifier_grimstroke_ink_creature_custom_latched = class(ItemBaseClass)
---------------------
function grimstroke_ink_creature_custom:GetIntrinsicModifierName()
    return "modifier_grimstroke_ink_creature_custom"
end

function grimstroke_ink_creature_custom:OnProjectileThink_ExtraData(location, data)
    if not IsServer() then return end
    
    if not data.returning and data.ink_unit_entindex and EntIndexToHScript(data.ink_unit_entindex) then
        if EntIndexToHScript(data.ink_unit_entindex):IsAlive() then
            EntIndexToHScript(data.ink_unit_entindex):SetAbsOrigin(location)
            EntIndexToHScript(data.ink_unit_entindex):FaceTowards(EntIndexToHScript(data.target_entindex):GetAbsOrigin())
        else
            -- Destroy the vision particle early if the phantom is killed mid-air while moving towards target
            ParticleManager:DestroyParticle(data.phantoms_embrace_particle, false)
            ParticleManager:ReleaseParticleIndex(data.phantoms_embrace_particle)
        end
    end

    -- ChangeTrackingProjectileSpeed(arg1: handle, arg2: int): nil
end

function grimstroke_ink_creature_custom:OnProjectileHit_ExtraData(target, location, data)
    if not IsServer() then return end

    if data.phantoms_embrace_particle then
        ParticleManager:DestroyParticle(data.phantoms_embrace_particle, false)
        ParticleManager:ReleaseParticleIndex(data.phantoms_embrace_particle)
    end
    
    if target then
        if target ~= self:GetCaster() and data.ink_unit_entindex and EntIndexToHScript(data.ink_unit_entindex) and EntIndexToHScript(data.ink_unit_entindex):IsAlive() then
            if target:IsInvulnerable() or target:IsOutOfGame() or not target:IsAlive() then
                local projectile =
                {
                    Target              = self:GetCaster(),
                    Source              = EntIndexToHScript(data.ink_unit_entindex),
                    Ability             = self,
                    EffectName          = "particles/units/heroes/hero_grimstroke/grimstroke_phantom_return.vpcf",
                    iMoveSpeed          = 750,
                    vSourceLoc          = EntIndexToHScript(data.ink_unit_entindex):GetAbsOrigin(),
                    bDrawsOnMinimap     = false,
                    bDodgeable          = true,
                    bIsAttack           = false,
                    bVisibleToEnemies   = true,
                    bReplaceExisting    = false,
                    flExpireTime        = GameRules:GetGameTime() + 10.0,
                    bProvidesVision     = false,
                    
                    ExtraData = {
                        returning       = true
                    }
                }   

                ProjectileManager:CreateTrackingProjectile(projectile)

                EntIndexToHScript(data.ink_unit_entindex):ForceKill(false)
                EntIndexToHScript(data.ink_unit_entindex):AddNoDraw()
            else
                target:EmitSound("Hero_Grimstroke.InkCreature.Attach")

                -- Apply the silence modifier
                target:AddNewModifier(EntIndexToHScript(data.ink_unit_entindex), self, "modifier_grimstroke_ink_creature_custom_debuff", 
                    {
                        duration            = self:GetSpecialValueFor("duration") * (1 - target:GetStatusResistance()),
                        latched_unit_offset = 95,
                        ink_unit_entindex   = data.ink_unit_entindex
                    })
                
                -- Check the ink creature's own handler modifier
                local ink_modifier  = EntIndexToHScript(data.ink_unit_entindex):FindModifierByNameAndCaster("modifier_grimstroke_ink_creature_custom_ai", self:GetCaster())
                
                if ink_modifier then
                    -- This seems pretty sketch, but it's to switch animations while retaining a modifier (although two modifiers would have been fine I guess...)
                    ink_modifier:SetStackCount(0)
                end
            end
        else
            -- Refresh cooldown
            self:GetCaster():EmitSound("Hero_Grimstroke.InkCreature.Returned")
            
            self:EndCooldown()
        end
    else

    end
end
--------------------------
function modifier_grimstroke_ink_creature_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE, --OnTakeDamage
    }
end

function modifier_grimstroke_ink_creature_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local damageType = event.damage_type
    local ability = self:GetAbility()

    if event.attacker == event.unit then return end
    if damageType ~= DAMAGE_TYPE_MAGICAL then return end
    if event.inflictor == nil then return end
    if event.inflictor == ability then return end
    if not string.find(event.inflictor:GetAbilityName(), "grimstroke") then return end

    local victim = event.unit

    if victim:HasModifier("modifier_grimstroke_ink_creature_custom_cooldown") or victim:HasModifier("modifier_grimstroke_ink_creature_custom_debuff") or victim:HasModifier("modifier_grimstroke_ink_creature_custom_latched") then return end
    
    local caster = self:GetCaster()

    local duration = ability:GetSpecialValueFor("duration")

    local pos = caster:GetAbsOrigin() + caster:GetForwardVector() * 95

    CreateUnitByNameAsync("npc_dota_grimstroke_ink_creature", pos, false, nil, nil, caster:GetTeamNumber(), function(unit)
        unit:AddNewModifier(caster, nil, "modifier_grimstroke_ink_creature_custom_ai", {
            duration = ability:GetSpecialValueFor("duration"),
            target_entindex = victim:entindex()
        })

        unit:SetForwardVector((victim:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized())
        
        local phantoms_embrace_particle = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_grimstroke/grimstroke_phantom_marker.vpcf", PATTACH_OVERHEAD_FOLLOW, victim, caster:GetTeamNumber())
        
        local projectile =
        {
            Target              = victim,
            Source              = caster,
            Ability             = ability,
            --EffectName            = self:GetCaster():GetRangedProjectileName() or "particles/units/heroes/hero_puck/puck_base_attack.vpcf",
            iMoveSpeed          = 750,
            vSourceLoc          = caster:GetAbsOrigin() + caster:GetForwardVector() * 95,
            bDrawsOnMinimap     = false,
            bDodgeable          = false,
            bIsAttack           = false,
            bVisibleToEnemies   = true,
            bReplaceExisting    = false,
            flExpireTime        = GameRules:GetGameTime() + 10.0,
            bProvidesVision     = true,
            iVisionRadius       = 400, -- IDK if there's some number to refer to
            iVisionTeamNumber   = caster:GetTeamNumber(),
            
            ExtraData = {
                ink_unit_entindex           = unit:entindex(),
                target_entindex             = victim:entindex(),
                phantoms_embrace_particle   = phantoms_embrace_particle
            }
        }
        
        ProjectileManager:CreateTrackingProjectile(projectile)
    end)

    victim:AddNewModifier(caster, ability, "modifier_grimstroke_ink_creature_custom_latched", {
        duration = ability:GetSpecialValueFor("duration")
    })
end
--------------
function modifier_grimstroke_ink_creature_custom_debuff:OnCreated(params)
    if not IsServer() then return end
    
    local ability = self:GetAbility()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    EmitSoundOn("Hero_Grimstroke.InkCreature.Attach", parent)

    self.interval = ability:GetSpecialValueFor("interval")

    self.damageTable = {
        victim = parent,
        attacker = caster,
        ability = ability,
        damage_type = ability:GetAbilityDamageType(),
    }

    self:StartIntervalThink(self.interval)

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_grimstroke/grimstroke_cast2_ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(effect_cast)
    -------
    self.latched_unit_offset    = params.latched_unit_offset
    self.ink_unit               = EntIndexToHScript(params.ink_unit_entindex)
end

function modifier_grimstroke_ink_creature_custom_debuff:OnRemoved()
    if not IsServer() then return end
    
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local cooldown = ability:GetSpecialValueFor("cooldown")

    parent:AddNewModifier(caster, ability, "modifier_grimstroke_ink_creature_custom_cooldown", {
        duration = cooldown
    })

    EmitSoundOn("Hero_Grimstroke.InkCreature.Death", parent)
end

function modifier_grimstroke_ink_creature_custom_debuff:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

function modifier_grimstroke_ink_creature_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetAbility():GetCaster()
    local ability = self:GetAbility()

    if self.ink_unit and self.ink_unit:IsAlive() then
        if self:GetParent():IsInvulnerable() or self:GetParent():IsMagicImmune() or self:GetParent():IsOutOfGame() then
            self:Destroy()
        else
            self.ink_unit:SetAbsOrigin(self:GetParent():GetAbsOrigin() + self:GetParent():GetForwardVector() * self.latched_unit_offset)
            self.ink_unit:SetForwardVector((self:GetParent():GetAbsOrigin() - self.ink_unit:GetAbsOrigin()):Normalized())
        end
    else
        self:StartIntervalThink(-1)
    end

    local mana = parent:GetMana() * (ability:GetSpecialValueFor("mana_drain_pct")/100)

    parent:SpendMana(mana, ability)

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_MANA_LOSS,
        parent,
        mana,
        nil
    )

    caster:GiveMana(mana)
    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_MANA_ADD,
        caster,
        mana,
        nil
    )

    self.damageTable.damage = mana * (ability:GetSpecialValueFor("mana_stolen_as_damage_pct")/100)
    ApplyDamage(self.damageTable)
    --------
end
--------------
function modifier_grimstroke_ink_creature_custom_ai:IsHidden()   return true end
function modifier_grimstroke_ink_creature_custom_ai:IsPurgable() return false end

function modifier_grimstroke_ink_creature_custom_ai:OnCreated(params)
    if not IsServer() then return end

    self.target                     = EntIndexToHScript(params.target_entindex)

    -- Calculate health chunks that the unit will lose on getting attacked
    self.health_increments      = 100

    if self:GetAbility() and self:GetCaster():FindAbilityByName(self:GetAbility():GetName()):GetAutoCastState() then
        self:SetStackCount(2)
    else
        self:SetStackCount(1)
    end
    
    local phantoms_embrace_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_grimstroke/grimstroke_phantom_ambient.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt(phantoms_embrace_particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    self:AddParticle(phantoms_embrace_particle, false, false, -1, false, false)

    self:StartIntervalThink(0.1)
end

function modifier_grimstroke_ink_creature_custom_ai:OnIntervalThink()
    if not self.target or not self.target:IsAlive() or self.target:IsInvulnerable() or self.target:IsOutOfGame() then self:Destroy() end
end

function modifier_grimstroke_ink_creature_custom_ai:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    if parent ~= nil then
        if parent:IsAlive() then parent:ForceKill(false) end
    end
    
    if self.target and self.target:FindModifierByNameAndCaster("modifier_grimstroke_ink_creature_custom_debuff", self:GetParent()) then
        self.target:RemoveModifierByNameAndCaster("modifier_grimstroke_ink_creature_custom_debuff", self:GetParent())
    end
end

function modifier_grimstroke_ink_creature_custom_ai:DeclareFunctions()
    local decFuncs = {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
        
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    }

    return decFuncs
end

function modifier_grimstroke_ink_creature_custom_ai:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
end

-- These aren't working right now
function modifier_grimstroke_ink_creature_custom_ai:GetOverrideAnimation()
    if self:GetStackCount() == 0 then
        return ACT_DOTA_ATTACK
    else
        return ACT_DOTA_RUN
    end
end

function modifier_grimstroke_ink_creature_custom_ai:GetActivityTranslationModifiers()
    if self:GetStackCount() == 0 then
        return "ink_creature_latched"
    end
end

function modifier_grimstroke_ink_creature_custom_ai:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_grimstroke_ink_creature_custom_ai:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_grimstroke_ink_creature_custom_ai:GetAbsoluteNoDamagePure()
    return 1
end