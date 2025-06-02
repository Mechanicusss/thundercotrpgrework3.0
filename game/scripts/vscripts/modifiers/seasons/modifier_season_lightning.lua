LinkLuaModifier("modifier_season_lightning", "modifiers/seasons/modifier_season_lightning", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_season_lightning_emitter", "modifiers/seasons/modifier_season_lightning", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_season_lightning_debuff", "modifiers/seasons/modifier_season_lightning", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_season_lightning_aura", "modifiers/seasons/modifier_season_lightning", LUA_MODIFIER_MOTION_NONE)

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

modifier_season_lightning = class(ItemBaseClass)
modifier_season_lightning_emitter = class(ItemBaseClass)
modifier_season_lightning_debuff = class(ItemBaseClassDebuff)
modifier_season_lightning_aura = class(ItemBaseClassDebuff)

function modifier_season_lightning:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()

    local emitter = CreateUnitByName("outpost_placeholder_unit", parent:GetAbsOrigin(), false, parent, parent, parent:GetTeam())
    emitter:AddNewModifier(emitter, nil, "modifier_season_lightning_emitter", { 
        duration = params.duration
    })
end

function modifier_season_lightning:OnDestroy()
    if not IsServer() then return end

    self:GetParent():ForceKill(false)
end

function modifier_season_lightning:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end
---------
function modifier_season_lightning_emitter:IsAura()
	return true
end

function modifier_season_lightning_emitter:GetModifierAura()
	return "modifier_season_lightning_aura"
end

function modifier_season_lightning_emitter:GetAuraRadius()
	return self.radius
end

function modifier_season_lightning_emitter:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_season_lightning_emitter:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_season_lightning_emitter:GetAuraEntityReject( hEntity )
    return false
end

function modifier_season_lightning_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_season_lightning_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_season_lightning_emitter:OnCreated(params)
    self.radius = 600

    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.parent = self:GetParent()

    self.damageFromHealthPct = 0.75
    self.stunDuration = 3

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle("particles/arc_warden_magnetic_custom.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl(self.effect_cast, 0, self.parent:GetOrigin())
    ParticleManager:SetParticleControl(self.effect_cast, 1, Vector( self.radius, self.radius, self.radius ))

    -- buff particle
    self:AddParticle(
        self.effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        true, -- bHeroEffect
        false -- bOverheadEffect
    )

    -- Create Sound
    
    EmitSoundOn("Hero_ArcWarden.MagneticField", self.parent)
end

function modifier_season_lightning_emitter:OnDestroy()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    -- Find all players not inside the area
    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() then
            self:PlayEffects(hero)
            self:PlayEffects2(hero)

            EmitSoundOn("Hero_Zuus.LightningBolt", hero)

            if not hero:HasModifier("modifier_season_lightning_aura") then
                ApplyDamage({
                    victim = hero,
                    attacker = hero,
                    damage = hero:GetMaxHealthTCOTRPG() * self.damageFromHealthPct,
                    damage_type = DAMAGE_TYPE_PURE,
                    damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
                })

                debuff = hero:AddNewModifier(self.caster, nil, "modifier_season_lightning_debuff", {
                    duration = self.stunDuration
                })
            end
        end
    end

    UTIL_Remove(self.parent)
end

function modifier_season_lightning_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end

function modifier_season_lightning_emitter:PlayEffects(enemy)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, enemy:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( enemy:GetAbsOrigin().x, enemy:GetAbsOrigin().y, enemy:GetAbsOrigin().z+900) )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_season_lightning_emitter:PlayEffects2(enemy)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_zuus/zuus_lightning_bolt_aoe_ground.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, enemy:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector(150, 150, 150) )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
--------------
function modifier_season_lightning_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_HEALING 
    }
end

function modifier_season_lightning_debuff:GetDisableHealing()
    return 1
end


function modifier_season_lightning_debuff:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_season_lightning_debuff:GetEffectName() return "particles/generic_gameplay/generic_stunned.vpcf" end
function modifier_season_lightning_debuff:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_season_lightning_debuff:GetTexture() return "lightning_season_icon" end
----------
function modifier_season_lightning_aura:GetEffectName() return "particles/units/heroes/hero_faceless_void/faceless_void_chrono_speed.vpcf" end