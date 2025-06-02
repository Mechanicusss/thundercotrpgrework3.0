LinkLuaModifier("modifier_season_shock", "modifiers/seasons/modifier_season_shock", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_season_shock_emitter", "modifiers/seasons/modifier_season_shock", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_season_shock_debuff", "modifiers/seasons/modifier_season_shock", LUA_MODIFIER_MOTION_NONE)

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

modifier_season_shock = class(ItemBaseClass)
modifier_season_shock_emitter = class(ItemBaseClass)
modifier_season_shock_debuff = class(ItemBaseClassDebuff)

function modifier_season_shock:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(10.0)
end

function modifier_season_shock:OnIntervalThink()
    local parent = self:GetParent()

    local emitter = CreateUnitByName("outpost_placeholder_unit", parent:GetAbsOrigin(), false, parent, parent, parent:GetTeam())
    emitter:AddNewModifier(emitter, nil, "modifier_season_shock_emitter", { 
        duration = 7
    })
end
---------
function modifier_season_shock_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_season_shock_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_season_shock_emitter:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.parent = self:GetParent()

    -- Start the thinker to drain hp/do damage --
    self:StartIntervalThink(1)

    EmitSoundOn("Hero_Razor.Storm.Cast", self.parent)
    EmitSoundOn("Hero_Razor.Storm.Loop", self.parent)

    self.vfx = ParticleManager:CreateParticle("particles/econ/items/razor/razor_arcana/razor_arcana_eye_of_the_storm_rain.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
end

function modifier_season_shock_emitter:OnIntervalThink()
    local units = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil,
        500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)


    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            ApplyDamage({
                victim = unit,
                attacker = self.parent,
                damage = unit:GetHealth() * 0.15,
                damage_type = DAMAGE_TYPE_MAGICAL,
                damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION 
            })

            self:PlayEffects2(unit)

            local debuff = unit:FindModifierByName("modifier_season_shock_debuff")
            if not debuff then
                debuff = unit:AddNewModifier(self.caster, nil, "modifier_season_shock_debuff", {
                    duration = 7
                })
            end

            if debuff then
                debuff:IncrementStackCount()
                debuff:ForceRefresh()
            end
        end
    end
end

function modifier_season_shock_emitter:OnDestroy()
    if not IsServer() then return end

    local sound_loop = "Hero_Razor.Storm.Loop"
    local sound_end = "Hero_Razor.StormEnd"
    StopSoundOn( sound_loop, self:GetParent() )
    EmitSoundOn( sound_end, self:GetParent() )

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end

    
end

function modifier_season_shock_emitter:CheckState()
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

function modifier_season_shock_emitter:PlayEffects2( enemy )
    -- Get Resources
    local particle_cast = "particles/econ/items/razor/razor_arcana/razor_arcana_eye_of_the_storm.vpcf"
    local sound_cast = "Hero_razor.lightning"

    -- Create Particle
    -- NOTE: Don't know what is the proper effect
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, self.parent )
    ParticleManager:SetParticleControl( effect_cast, 0, self.parent:GetOrigin() + Vector(0,0,500) )
    -- ParticleManager:SetParticleControlEnt(
    --  effect_cast,
    --  0,
    --  self.parent,
    --  PATTACH_CUSTOMORIGIN,
    --  "",
    --  self.parent:GetOrigin() + Vector(0,0,300), -- unknown
    --  false -- unknown, true
    -- )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        enemy,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, enemy )
end
--------------
function modifier_season_shock_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_season_shock_debuff:GetModifierMagicalResistanceBonus()
    return -5 * self:GetStackCount()
end

function modifier_season_shock_debuff:GetModifierPhysicalArmorBonus()
    return -10 * self:GetStackCount()
end

function modifier_season_shock_debuff:GetTexture() return "voidshock" end