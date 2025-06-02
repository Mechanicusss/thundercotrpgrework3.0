
modifier_boss_destruction_tower_drain_debuff_thinker = class({})

function modifier_boss_destruction_tower_drain_debuff_thinker:IsDebuff() return true end
function modifier_boss_destruction_tower_drain_debuff_thinker:RemoveOnDeath() return true end
-----------------------------------------------------------------------------

function modifier_boss_destruction_tower_drain_debuff_thinker:OnCreated( kv )
    if IsServer() then
        local parent = self:GetParent()
        local caster = self:GetCaster()

        self.vfx =  ParticleManager:CreateParticle( "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", PATTACH_POINT_FOLLOW, parent )
        ParticleManager:SetParticleControlEnt(
            self.vfx,
            0,
            caster,
            PATTACH_POINT_FOLLOW,
            "attach_hitloc",
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

function modifier_boss_destruction_tower_drain_debuff_thinker:OnDestroy( kv )
    if IsServer() then
        if self.vfx ~= nil then
            ParticleManager:DestroyParticle(self.vfx, true)
            ParticleManager:ReleaseParticleIndex(self.vfx)
        end
    end
end

---------------------------------------------------------------------------------
function modifier_boss_destruction_tower_drain_debuff_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if not caster or caster:IsNull() then caster:Stop() self:Destroy() return end
    if not caster:IsAlive() then caster:Stop() self:Destroy() return end

    local distance = (caster:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
    if distance > self.search_radius then
        self:Destroy()
        return
    end

    local damage = parent:GetMaxHealth() * (self.drain/100) * self.interval

    self.damageTable.damage = damage

    ApplyDamage(self.damageTable)
end
---------------------------------------------------------------------------------
function modifier_boss_destruction_tower_drain_debuff_thinker:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_HEALING 
    }
end

function modifier_boss_destruction_tower_drain_debuff_thinker:GetDisableHealing()
    return 1
end


modifier_boss_destruction_tower_drain_thinker = class({})

-----------------------------------------------------------------------------

function modifier_boss_destruction_tower_drain_thinker:OnCreated( kv )
    if IsServer() then
        EmitSoundOn("Hero_Pugna.LifeDrain.Cast", self:GetCaster())
        EmitSoundOn("Hero_Pugna.LifeDrain.Loop", self:GetCaster())
    end
end

function modifier_boss_destruction_tower_drain_thinker:OnDestroy( kv )
    if IsServer() then
        StopSoundOn("Hero_Pugna.LifeDrain.Loop", self:GetCaster())
    end
end
-----------------------------------------------------------------------------

function modifier_boss_destruction_tower_drain_thinker:IsAura()
    return true
end

function modifier_boss_destruction_tower_drain_thinker:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_boss_destruction_tower_drain_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_boss_destruction_tower_drain_thinker:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("search_radius")
end

function modifier_boss_destruction_tower_drain_thinker:GetModifierAura()
    return "modifier_boss_destruction_tower_drain_debuff_thinker"
end

function modifier_boss_destruction_tower_drain_thinker:GetAuraEntityReject(target)
    return target:IsMagicImmune()
end
-----------------------------------------------------------------------------
boss_destruction_tower_drain = class({})

LinkLuaModifier( "modifier_boss_destruction_tower_drain_thinker", "heroes/bosses/destruction_lord/boss_destruction_tower_drain", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_destruction_tower_drain_debuff_thinker", "heroes/bosses/destruction_lord/boss_destruction_tower_drain", LUA_MODIFIER_MOTION_NONE )

----------------------------------------------------------------------------------------

function boss_destruction_tower_drain:Precache( context )
    PrecacheResource( "particle", "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_pugna.vsndevts", context ) 
end
--------------------------------------------------------------------------------

function boss_destruction_tower_drain:OnAbilityPhaseStart()
    if IsServer() then
        self:GetCaster():AddNewModifier(
            self:GetCaster(),
            self,
            "modifier_black_king_bar_immune",
            {duration = self:GetChannelTime() + 1.25}
        )
    end
    return true
end
--------------------------------------------------------------------------------

function boss_destruction_tower_drain:OnSpellStart()
    if IsServer() then
       local caster = self:GetCaster()

       local target = self:GetCursorTarget()

       --self.mod = CreateModifierThinker( caster, self, "modifier_boss_destruction_tower_drain_thinker", { duration = self:GetChannelTime() }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false )

       if target:HasModifier("modifier_boss_destruction_tower_drain_debuff_thinker") then
        target:FindModifierByName("modifier_boss_destruction_tower_drain_debuff_thinker"):Destroy()
       end

       self.mod = target:AddNewModifier(caster, self, "modifier_boss_destruction_tower_drain_debuff_thinker", { duration = self:GetChannelTime() })
       EmitSoundOn("Hero_Pugna.LifeDrain.Cast", self:GetCaster())
       EmitSoundOn("Hero_Pugna.LifeDrain.Loop", self:GetCaster())
    end
end

--------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function boss_destruction_tower_drain:OnChannelThink( flInterval )
    if IsServer() then

    end
end

-------------------------------------------------------------------------------

function boss_destruction_tower_drain:OnChannelFinish( bInterrupted )
    if IsServer() then
        StopSoundOn("Hero_Pugna.LifeDrain.Loop", self:GetCaster())

        if self.mod ~= nil and not self.mod:IsNull() then
            self.mod:Destroy()
        end

        self:GetCaster():Stop()
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------