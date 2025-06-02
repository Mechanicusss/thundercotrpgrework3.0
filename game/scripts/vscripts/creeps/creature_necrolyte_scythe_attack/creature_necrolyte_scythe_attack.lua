creature_necrolyte_scythe_attack = class({})

LinkLuaModifier( "modifier_creature_necrolyte_scythe_attack_thinker", "creeps/creature_necrolyte_scythe_attack/creature_necrolyte_scythe_attack", LUA_MODIFIER_MOTION_NONE )

----------------------------------------------------------------------------------------

function creature_necrolyte_scythe_attack:Precache( context )
    PrecacheResource( "particle", "particles/econ/items/necrolyte/necro_sullen_harvest/necro_ti7_immortal_scythe_start.vpcf", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_necrolyte.vsndevts", context ) 
end

--------------------------------------------------------------------------------

function creature_necrolyte_scythe_attack:OnSpellStart()
    if IsServer() then
       local caster = self:GetCaster()

       self.mod = CreateModifierThinker( caster, self, "modifier_creature_necrolyte_scythe_attack_thinker", { duration = self:GetChannelTime() }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false )
    end
end

--------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function creature_necrolyte_scythe_attack:OnChannelThink( flInterval )
    if IsServer() then
    end
end

-------------------------------------------------------------------------------

function creature_necrolyte_scythe_attack:OnChannelFinish( bInterrupted )
    if IsServer() then
        if self.mod ~= nil then
            self.mod:Destroy()
        end
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


modifier_creature_necrolyte_scythe_attack_thinker = class({})

-----------------------------------------------------------------------------

function modifier_creature_necrolyte_scythe_attack_thinker:OnCreated( kv )
    if IsServer() then
        self.interval = self:GetAbility():GetSpecialValueFor( "interval" )
        self.search_radius = self:GetAbility():GetSpecialValueFor( "search_radius" )
        self.impact_radius = self:GetAbility():GetSpecialValueFor( "impact_radius" )

        self:StartIntervalThink(self.interval)
    end
end

function modifier_creature_necrolyte_scythe_attack_thinker:OnDestroy( kv )
    if IsServer() then
        UTIL_Remove(self:GetParent())
    end
end

-----------------------------------------------------------------------------

function modifier_creature_necrolyte_scythe_attack_thinker:OnIntervalThink()
    if IsServer() then
        local caster = self:GetCaster()
        local ability = self:GetAbility()

        if caster:IsNull() then self:Destroy() return end
        if not caster:IsAlive() then self:Destroy() return end

        local pos = caster:GetAbsOrigin() + RandomVector(RandomFloat(0, self.search_radius))
        
        self:SummonScythe(caster, pos)

        Timers:CreateTimer(1.5, function()
            if not caster or not ability then return end
            if caster:IsNull() then return end
            if not caster:IsAlive() then return end
            if not self then return end

            local enemies = FindUnitsInRadius(caster:GetTeam(), pos, nil,
                self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

            for _,enemy in ipairs(enemies) do
                enemy:Kill(ability, caster)
            end

            EmitSoundOnLocationWithCaster(pos, "Hero_Necrolyte.ReapersScythe.Target", caster)
        end)
    end
end

function modifier_creature_necrolyte_scythe_attack_thinker:SummonScythe(caster, position)
    DrawWarningCircle(caster, position, self.impact_radius, 1.5)

    local particle_cast = "particles/econ/items/necrolyte/necro_sullen_harvest/necro_ti7_immortal_scythe_start.vpcf"

    EmitSoundOnLocationWithCaster(position, "Hero_Necrolyte.ReapersScythe.Cast.ti7", caster)

    -- Create Particle
    local effect = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect, 0, position )
    ParticleManager:SetParticleControl( effect, 1, position )
    ParticleManager:SetParticleControl( effect, 4, position )
    ParticleManager:ReleaseParticleIndex(effect)
end

-----------------------------------------------------------------------------