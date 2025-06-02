LinkLuaModifier("modifier_season_firestorm", "modifiers/seasons/modifier_season_firestorm", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_season_firestorm_emitter", "modifiers/seasons/modifier_season_firestorm", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_season_firestorm_debuff", "modifiers/seasons/modifier_season_firestorm", LUA_MODIFIER_MOTION_NONE)

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

modifier_season_firestorm = class(ItemBaseClass)
modifier_season_firestorm_emitter = class(ItemBaseClass)
modifier_season_firestorm_debuff = class(ItemBaseClassDebuff)

function modifier_season_firestorm:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()

    local emitter = CreateUnitByName("outpost_placeholder_unit", parent:GetAbsOrigin(), false, parent, parent, parent:GetTeam())
    emitter:AddNewModifier(emitter, nil, "modifier_season_firestorm_emitter", { 
        duration = params.duration
    })
end

function modifier_season_firestorm:OnDestroy()
    if not IsServer() then return end

    self:GetParent():ForceKill(false)
end

function modifier_season_firestorm:CheckState()
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
function modifier_season_firestorm_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_season_firestorm_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_season_firestorm_emitter:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.parent = self:GetParent()

    -- Start the thinker to drain hp/do damage --
    self:StartIntervalThink(1)

    EmitSoundOn("Hero_AbyssalUnderlord.Firestorm.Start", self.parent)
end

function modifier_season_firestorm_emitter:OnIntervalThink()
    local units = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil,
        600, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    self:PlayEffects2(self.caster)

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            ApplyDamage({
                victim = unit,
                attacker = self.parent,
                damage = unit:GetMaxHealth() * 0.10,
                damage_type = DAMAGE_TYPE_MAGICAL,
                damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION 
            })

            EmitSoundOn("Hero_AbyssalUnderlord.Firestorm.Target", unit)

            local debuff = unit:FindModifierByName("modifier_season_firestorm_debuff")
            if not debuff then
                debuff = unit:AddNewModifier(self.caster, nil, "modifier_season_firestorm_debuff", {
                    duration = 7
                })
            end

            if debuff then
                if debuff:GetStackCount() < 19 then
                    debuff:IncrementStackCount()
                end
                
                debuff:ForceRefresh()
            end
        end
    end
end

function modifier_season_firestorm_emitter:OnDestroy()
    if not IsServer() then return end


    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end

    
end

function modifier_season_firestorm_emitter:CheckState()
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

function modifier_season_firestorm_emitter:PlayEffects2(enemy)
    -- Get Resources
    local particle_cast = "particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf"
    local sound_cast = "Hero_AbyssalUnderlord.Firestorm"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, enemy:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 4, Vector( 600, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, enemy )
end
--------------
function modifier_season_firestorm_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }
end

function modifier_season_firestorm_debuff:GetModifierHealAmplify_PercentageTarget()
    return -5 * self:GetStackCount()
end

function modifier_season_firestorm_debuff:GetModifierHPRegenAmplify_Percentage()
    return -5 * self:GetStackCount()
end

function modifier_season_firestorm_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return -5 * self:GetStackCount()
end

function modifier_season_firestorm_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    return -5 * self:GetStackCount()
end

function modifier_season_firestorm_debuff:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_season_firestorm_debuff:OnIntervalThink()
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self:GetParent():GetHealth() * 0.05 * self:GetStackCount(),
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION 
    })
end

function modifier_season_firestorm_debuff:GetEffectName() return "particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave_burn.vpcf" end
function modifier_season_firestorm_debuff:GetTexture() return "abyssal_underlord_firestorm" end