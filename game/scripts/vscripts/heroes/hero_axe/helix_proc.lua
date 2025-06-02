axe_helix_proc_custom = class({})
LinkLuaModifier( "modifier_axe_helix_proc_custom", "heroes/hero_axe/helix_proc", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_axe_helix_proc_custom_stacks", "heroes/hero_axe/helix_proc", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function axe_helix_proc_custom:GetIntrinsicModifierName()
    return "modifier_axe_helix_proc_custom"
end

local ItemBaseClassStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

modifier_axe_helix_proc_custom = class({})
modifier_axe_helix_proc_custom_stacks = class(ItemBaseClassStacks) 

function modifier_axe_helix_proc_custom:GetTexture() return "axe_helix_proc" end

function modifier_axe_helix_proc_custom_stacks:GetTexture() return "axe_helix_proc" end

function modifier_axe_helix_proc_custom_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_axe_helix_proc_custom_stacks:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }

    return funcs
end

function modifier_axe_helix_proc_custom_stacks:GetModifierPhysicalArmorBonus()
    return self:GetStackCount()
end

--------------------------------------------------------------------------------
-- Classifications
function modifier_axe_helix_proc_custom:IsHidden()
    return true
end

function modifier_axe_helix_proc_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_axe_helix_proc_custom:OnCreated( kv )
    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

    if IsServer() then
        local damage = self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())
        local damagePure = (self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())*(self:GetAbility():GetSpecialValueFor("atk_dmg_pc")/100))

        -- precache damage
        self.damageTable = {
            -- victim = target,
            attacker = self:GetCaster(),
            damage = damage,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION),
        }

        self.damageTablePure = {
            -- victim = target,
            attacker = self:GetCaster(),
            damage = damagePure,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility(), --Optional. 
        }
    end
end

function modifier_axe_helix_proc_custom:OnRefresh( kv )
    if IsServer() then
        local damage = self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())
        local damagePure = (self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())*(self:GetAbility():GetSpecialValueFor("atk_dmg_pc")/100))

        self.damageTable.damage = damage
        self.damageTablePure.damage = damagePure
    end
end

function modifier_axe_helix_proc_custom:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_axe_helix_proc_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_axe_helix_proc_custom:OnDeath(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.attacker == event.unit then return end
    if event.inflictor == nil then return end

    if event.inflictor:GetAbilityName() ~= "axe_helix_proc_custom" and event.inflictor:GetAbilityName() ~= "axe_counter_helix" and event.inflictor:GetAbilityName() ~= "axe_battle_hunger" then return end

    local parent = self:GetParent()

    if parent:HasModifier("modifier_axe_helix_proc_custom_stacks") then
        local mod = parent:FindModifierByName("modifier_axe_helix_proc_custom_stacks")
        mod:IncrementStackCount()
    else
        local mod = parent:AddNewModifier(parent, self:GetAbility(), "modifier_axe_helix_proc_custom_stacks", {})
        mod:IncrementStackCount()
    end
end

function modifier_axe_helix_proc_custom:OnAttackLanded( params )
    if IsServer() then
        if params.attacker~=self:GetCaster() then return end
        if self:GetCaster():PassivesDisabled() then return end
        if params.attacker:GetTeamNumber()==params.target:GetTeamNumber() then return end
        if params.target:IsOther() or params.target:IsBuilding() then return end

        if params.attacker:IsIllusion() then return end

        -- roll dice
        if not RollPercentage(self:GetAbility():GetSpecialValueFor( "trigger_chance" )) then return end

        local damage = self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())
        local damagePure = (self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())*(self:GetAbility():GetSpecialValueFor("atk_dmg_pc")/100))

        -- find enemies
        local enemies = FindUnitsInRadius(
            self:GetCaster():GetTeamNumber(),   -- int, your team number
            self:GetCaster():GetOrigin(),   -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, -- int, flag filter
            0,  -- int, order filter
            false   -- bool, can grow cache
        )

        -- damage
        for _,enemy in pairs(enemies) do
            self.damageTable.victim = enemy
            self.damageTable.damage = damage
            self.damageTablePure.victim = enemy
            self.damageTablePure.damage = damagePure
            ApplyDamage( self.damageTable )
            ApplyDamage( self.damageTablePure )
            SendOverheadEventMessage(
                nil,
                OVERHEAD_ALERT_DAMAGE,
                enemy,
                self.damageTablePure.damage,
                nil
            )
        end

        -- cooldown
        --self:GetAbility():UseResources( false, false, true )

        -- effects
        self:PlayEffects()
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_axe_helix_proc_custom:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_axe/axe_counterhelix_ad.vpcf"
    local sound_cast = "Hero_Axe.CounterHelix"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
end