
modifier_aghanim_scythe_attack_thinker = class({})

-----------------------------------------------------------------------------

function modifier_aghanim_scythe_attack_thinker:OnCreated( kv )
    if IsServer() then
        self.interval = self:GetAbility():GetSpecialValueFor( "interval" )
        self.search_radius = self:GetAbility():GetSpecialValueFor( "search_radius" )
        self.impact_radius = self:GetAbility():GetSpecialValueFor( "impact_radius" )

        self:StartIntervalThink(self.interval)
    end
end

-----------------------------------------------------------------------------

function modifier_aghanim_scythe_attack_thinker:OnIntervalThink()
    if IsServer() then
        local caster = self:GetCaster()
        local ability = self:GetAbility()

        local pos = caster:GetAbsOrigin() + RandomVector(RandomFloat(100, self.search_radius))
        
        self:SummonScythe(caster, pos)

        Timers:CreateTimer(1.5, function()
            if not caster or not ability then return end
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

function modifier_aghanim_scythe_attack_thinker:SummonScythe(caster, position)
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