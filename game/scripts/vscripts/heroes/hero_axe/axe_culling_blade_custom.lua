axe_culling_blade_custom = class({})
LinkLuaModifier( "modifier_axe_culling_blade_custom", "heroes/hero_axe/axe_culling_blade_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_axe_culling_blade_custom_stacks", "heroes/hero_axe/axe_culling_blade_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_axe_culling_blade_custom_buff", "heroes/hero_axe/axe_culling_blade_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function axe_culling_blade_custom:GetIntrinsicModifierName()
    return "modifier_axe_culling_blade_custom"
end

local ItemBaseClassStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

modifier_axe_culling_blade_custom = class({})
modifier_axe_culling_blade_custom_stacks = class(ItemBaseClassStacks) 
modifier_axe_culling_blade_custom_buff = class(ItemBaseClassBuff)

function modifier_axe_culling_blade_custom_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_axe_culling_blade_custom_stacks:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE   
    }

    return funcs
end

function modifier_axe_culling_blade_custom_stacks:GetModifierExtraHealthPercentage()
    local caster = self:GetCaster()
    local runeCullingBlade = caster:HasModifier("modifier_item_socket_rune_legendary_axe_culling_blade")
    
    if not runeCullingBlade then return end
    
    local count = self:GetStackCount()

    return count * 0.25
end

function modifier_axe_culling_blade_custom_stacks:IsHidden()
    local caster = self:GetCaster()

    local runeCullingBlade = caster:HasModifier("modifier_item_socket_rune_legendary_axe_culling_blade")
    
    if not runeCullingBlade then return true end

    return false
end

--------------------------------------------------------------------------------
-- Classifications
function modifier_axe_culling_blade_custom:IsHidden()
    return true
end

function modifier_axe_culling_blade_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations


function modifier_axe_culling_blade_custom:OnCreated()

    if not IsServer() then return end 

    self.attack = true
    self.timer = nil
end

function modifier_axe_culling_blade_custom:OnRefresh()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_axe_culling_blade_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_axe_culling_blade_custom:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    local unit = event.unit 

    if not IsCreepTCOTRPG(unit) and not IsBossTCOTRPG(unit) then return end 

    if not event.inflictor then return end 

    local ability = self:GetAbility()

    if event.inflictor ~= ability then return end 

    -- Apply speed buff
    parent:AddNewModifier(parent, ability, "modifier_axe_culling_blade_custom_buff", {
        duration = ability:GetSpecialValueFor("speed_duration")
    })

    local talent = parent:FindAbilityByName("talent_axe_2")
    local runeCullingBlade = parent:FindModifierByName("modifier_item_socket_rune_legendary_axe_culling_blade")
    
    if not runeCullingBlade then return end

    -- Perma stacks
    local armor = parent:FindModifierByName("modifier_axe_culling_blade_custom_stacks")
    if not armor then
        armor = parent:AddNewModifier(parent, ability, "modifier_axe_culling_blade_custom_stacks", {})
    end

    if armor and armor:GetStackCount() < 200 then
        armor:IncrementStackCount()
        parent:CalculateStatBonus(true)
    end
end

function modifier_axe_culling_blade_custom:OnAttackStart( params )
    if IsServer() then
        if params.attacker ~= self:GetCaster() then return end
        if self:GetCaster():PassivesDisabled() then return end
        if params.attacker:GetTeamNumber()==params.target:GetTeamNumber() then return end
        if params.target:IsOther() or params.target:IsBuilding() then return end
        if not IsCreepTCOTRPG(params.target) and not IsBossTCOTRPG(params.target) then return end
        if params.attacker:IsIllusion() then return end

        -- roll dice
        local ability = self:GetAbility()
        local caster = self:GetCaster()
        
        local damage = ability:GetSpecialValueFor("damage_from_max_hp_pct")
        local totalDamage = caster:GetMaxHealth() * (damage/100)
        local victim = params.target

        local talent = caster:FindAbilityByName("talent_axe_2")
        local runeCullingBlade = caster:FindModifierByName("modifier_item_socket_rune_legendary_axe_culling_blade")

        if not ability:IsCooldownReady() then return end
        if not RollPercentage(self:GetAbility():GetSpecialValueFor("chance")) then 
            return 
        end

        if not self.attack then return end 
        if self.timer ~= nil then return end
        
        if runeCullingBlade then
            local executeThreshold = runeCullingBlade.executeThreshold
            local executeChance = runeCullingBlade.executeChance

            local enemies = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
            runeCullingBlade.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

                for _,enemy in ipairs(enemies) do
                    if not enemy:IsAlive() then break end
    
                    -- chance to execute them with the talent
                    if enemy:GetHealthPercent() <= executeThreshold and RollPercentage(executeChance) then
                        totaldamage = enemy:GetMaxHealth()
                    end
    
                    -- Deal damage 
                    ApplyDamage({
                        attacker = caster,
                        victim = enemy,
                        damage = totalDamage,
                        damage_type = DAMAGE_TYPE_PURE,
                        ability = ability
                    })
    
                    -- effects
                    self:PlayEffects(enemy)
                end
            else
                -- Deal damage 
                ApplyDamage({
                    attacker = caster,
                    victim = victim,
                    damage = totalDamage,
                    damage_type = DAMAGE_TYPE_PURE,
                    ability = ability
                })
    
                -- effects
                self:PlayEffects(victim)
            end
    
            caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)
    
            self.attack = false 
    
            -- We have to set a timer here to prevent being able to spam the attack/cancel command for infinite procs 
            -- It's necessary to execute this in OnAttackStart because Axe is a melee hero and we need to deal the damage before his attack lands
            -- WARNING: Would behave weirdly on Ranged
            self.timer = Timers:CreateTimer(caster:GetSecondsPerAttack(false), function()
                self.attack = true
                self.timer = nil
            end)
    
            ability:UseResources(false, false, false, true)
        end
    end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_axe_culling_blade_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf"
    local sound_cast = "Hero_Axe.Culling_Blade_Success"

    --- load data
    local direction = (target:GetOrigin()-self:GetCaster():GetOrigin()):Normalized()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 4, target:GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 3, direction )
    ParticleManager:SetParticleControlForward( effect_cast, 4, direction )
    -- assert(loadfile("lua_abilities/rubick_spell_steal_lua/rubick_spell_steal_lua_color"))(self,effect_target)
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
-------
function modifier_axe_culling_blade_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
    }
end

function modifier_axe_culling_blade_custom_buff:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("speed_bonus")
end

function modifier_axe_culling_blade_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("atk_speed_bonus")
end

function modifier_axe_culling_blade_custom_buff:GetEffectName()
    return "particles/units/heroes/hero_axe/axe_cullingblade_sprint.vpcf"
end

function modifier_axe_culling_blade_custom_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end