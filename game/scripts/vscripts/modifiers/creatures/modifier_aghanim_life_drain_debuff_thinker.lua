
modifier_aghanim_life_drain_debuff_thinker = class({})

function modifier_aghanim_life_drain_debuff_thinker:IsDebuff() return true end
function modifier_aghanim_life_drain_debuff_thinker:RemoveOnDeath() return true end
-----------------------------------------------------------------------------

function modifier_aghanim_life_drain_debuff_thinker:OnCreated( kv )
    if IsServer() then
        local parent = self:GetParent()
        local caster = self:GetCaster()

        local szAttachment = "attach_hand_R"
        if RandomInt(0, 1) == 1 then
            szAttachment = "attach_lower_hand_R"
        end

        self.vfx =  ParticleManager:CreateParticle( "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", PATTACH_POINT_FOLLOW, parent )
        ParticleManager:SetParticleControlEnt(
            self.vfx,
            0,
            caster,
            PATTACH_POINT_FOLLOW,
            szAttachment,
            caster:GetAbsOrigin(), -- unknown
            true -- unknown, true
        )
        ParticleManager:SetParticleControlEnt(
            self.vfx,
            1,
            parent,
            PATTACH_POINT_FOLLOW,
            "attach_hitloc",
            parent:GetAbsOrigin(), -- unknown
            true -- unknown, true
        )

        local ability = self:GetAbility()

        self.interval = ability:GetSpecialValueFor("interval")
        self.drain = ability:GetSpecialValueFor("hp_drain_pct")
        self.search_radius = ability:GetSpecialValueFor("search_radius")

        self.damageTable = {
            attacker = caster,
            victim = parent,
            damage_type = ability:GetAbilityDamageType(),
            ability = ability,
        }

        self:StartIntervalThink(self.interval)
    end
end

-----------------------------------------------------------------------------

function modifier_aghanim_life_drain_debuff_thinker:OnDestroy( kv )
    if IsServer() then
        if self.vfx ~= nil then
            ParticleManager:DestroyParticle(self.vfx, true)
            ParticleManager:ReleaseParticleIndex(self.vfx)
        end
    end
end

---------------------------------------------------------------------------------
function modifier_aghanim_life_drain_debuff_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    local distance = (caster:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
    if distance > self.search_radius then
        self:Destroy()
        return
    end

    local damage = parent:GetMaxHealth() * (self.drain/100) * self.interval

    self.damageTable.damage = damage

    ApplyDamage(self.damageTable)

    caster:Heal(damage, self:GetAbility())
end
---------------------------------------------------------------------------------
function modifier_aghanim_life_drain_debuff_thinker:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_HEALING 
    }
end

function modifier_aghanim_life_drain_debuff_thinker:GetDisableHealing()
    return 1
end