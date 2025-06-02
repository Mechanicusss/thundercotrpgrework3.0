-- Thanks to the DOTA IMBA team for the majority of the code that this is based on!
-- https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/abilities/heroes/hero_juggernaut.lua

LinkLuaModifier("modifier_juggernaut_omni_slash_custom_caster", "heroes/hero_juggernaut/juggernaut_omni_slash_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_juggernaut_omni_slash_custom_in", "heroes/hero_juggernaut/juggernaut_omni_slash_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_juggernaut_omni_slash_custom_illusion", "heroes/hero_juggernaut/juggernaut_omni_slash_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_juggernaut_omni_slash_custom_scepter_debuff", "heroes/hero_juggernaut/juggernaut_omni_slash_custom.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
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

juggernaut_omni_slash_custom = juggernaut_omni_slash_custom or class(BaseClass)
modifier_juggernaut_omni_slash_custom_in = class(juggernaut_omni_slash_custom)
modifier_juggernaut_omni_slash_custom_illusion = class(BaseClass)
modifier_juggernaut_omni_slash_custom_scepter_debuff = class(ItemBaseClassDebuff)

function juggernaut_omni_slash_custom:IsNetherWardStealable() return false end

function juggernaut_omni_slash_custom:GetIntrinsicModifierName()
    return  "modifier_juggernaut_omni_slash_custom_in"
end

function juggernaut_omni_slash_custom:IsHiddenWhenStolen()
    return false
end

-- Grimstroke edge case (really should be cleaner than this but...yeah)
function juggernaut_omni_slash_custom:OnOwnerDied()
    if not self:IsActivated() then
        self:SetActivated(true)
    end
end

function juggernaut_omni_slash_custom:OnOwnerSpawned()
    self:OnOwnerDied()
end

function modifier_juggernaut_omni_slash_custom_in:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_juggernaut_omni_slash_custom_in:OnAttack(event)
    if not IsServer() then return end

    local unit = event.attacker
    self.caster = self:GetCaster()
    self.target = event.target

    if unit ~= self.caster then
        return
    end

    if not self.caster:IsAlive() or self.caster:PassivesDisabled() or self.caster:IsIllusion() or self.caster:HasModifier("modifier_juggernaut_omni_slash_custom_caster") then
        return
    end

    local ability = self:GetAbility()
    if not ability:GetAutoCastState() then return end
    local chance = ability:GetSpecialValueFor("chance")

    if self.caster:HasTalent("special_bonus_unique_juggernaut_1_custom") then
        local bonus = self.caster:FindAbilityByName("special_bonus_unique_juggernaut_1_custom"):GetSpecialValueFor("value")

        chance = chance + bonus
    end

    if not RollPercentage(chance) then return end

    self.previous_position = self.caster:GetAbsOrigin()
    
    self.caster:Purge(false, true, false, false, false)
    
    self.caster:AddNewModifier(self.caster, ability, "modifier_juggernaut_omni_slash_custom_caster", {
        duration = ability:GetSpecialValueFor("duration")
    })

    ability:SetActivated(false)

    -- Disable Blade Fury during Omnislash (vanilla)
    --if self.caster:HasAbility("imba_juggernaut_blade_fury") then
    --    self.caster:FindAbilityByName("imba_juggernaut_blade_fury"):SetActivated(false)
    --end

    self.caster:CenterCameraOnEntity(self.caster)

    FindClearSpaceForUnit(self.caster, self.target:GetAbsOrigin() + RandomVector(128), false)

    EmitSoundOn("Hero_Juggernaut.OmniSlash", self.caster)

    StartAnimation(self.caster, { activity = ACT_DOTA_OVERRIDE_ABILITY_4, rate = 1.0, duration = ability:GetSpecialValueFor("duration") })

    self.current_position = self.caster:GetAbsOrigin()

    -- Play particle trail when moving
    local trail_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_trail.vpcf", PATTACH_ABSORIGIN, self.caster, self.caster)
    ParticleManager:SetParticleControl(trail_pfx, 0, self.previous_position)
    ParticleManager:SetParticleControl(trail_pfx, 1, self.current_position)
    ParticleManager:ReleaseParticleIndex(trail_pfx)

    -- Create Illusion --
    local illusion = CreateIllusions(
        self.caster,
        self.caster,
        {
            outgoing_damage = 100,
            incoming_damage = 100,
            bounty_base = 0,
            bounty_growth = 0,
            outgoing_damage_structure = 100,
            outgoing_damage_roshan = 100
        },
        1,
        0,
        false,
        false
    )

    if illusion ~= nil and #illusion > 0 then
        self.juggCopy = illusion[1]
        if self.juggCopy ~= nil then
            FindClearSpaceForUnit(self.juggCopy, self.caster:GetAbsOrigin(), false)
            self.juggCopy:AddNewModifier(self.caster, ability, "modifier_juggernaut_omni_slash_custom_illusion", {
                duration = ability:GetSpecialValueFor("duration"),
            })
            self.juggCopy:MoveToPositionAggressive(self.juggCopy:GetAbsOrigin())
        end
    end
end
-----------------------------------------
modifier_juggernaut_omni_slash_custom_caster = modifier_juggernaut_omni_slash_custom_caster or class({})

function modifier_juggernaut_omni_slash_custom_caster:OnCreated(params)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.last_enemy = nil

    self.scepterDuration = self.ability:GetSpecialValueFor("corruption_duration")

    if not self:GetAbility() then
        self:Destroy()
        return nil
    end

    -- Add the first instance of Omnislash to proc the minimum damage
    self.slash = true

    -- Seriously!? Took me 2 hours to fix this. >:(
    if IsServer() then
        Timers:CreateTimer(FrameTime(), function()
            if (not self.parent:IsNull()) then
                -- Do Omnislash --
                self.bounce_range = self:GetAbility():GetSpecialValueFor("omni_slash_radius")
                
                self:GetAbility():SetRefCountsModifiers(false)

                --self.parent:AddNoDraw()

                self:BounceAndSlaughter(true)
                
                local slash_rate = (self.caster:GetAttackCapability() / (math.max(self:GetAbility():GetSpecialValueFor("attack_rate_multiplier"), 1)))
                
                self:StartIntervalThink(slash_rate)
            end
        end)
    end
end

function modifier_juggernaut_omni_slash_custom_caster:OnIntervalThink()
    -- Get the hero Agility while casting Omnislash
    self:BounceAndSlaughter()

    local slash_rate = (self.caster:GetAttackCapability() / (math.max(self:GetAbility():GetSpecialValueFor("attack_rate_multiplier"), 1)))

    self:StartIntervalThink(-1)
    self:StartIntervalThink(slash_rate)
end

function modifier_juggernaut_omni_slash_custom_caster:BounceAndSlaughter(first_slash)
    local order = FIND_ANY_ORDER
    
    if first_slash then
        order = FIND_CLOSEST
    end
    
    self.nearby_enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),
        self.parent:GetAbsOrigin(),
        nil,
        self.bounce_range,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
        order,
        false
    )
    
    for count = #self.nearby_enemies, 1, -1 do
        -- "Cannot jump on units in the Fog of War, invisible or hidden units, Tombstone Zombies and on Astral Spirits."
        if self.nearby_enemies[count] and (self.nearby_enemies[count]:GetName() == "npc_dota_unit_undying_zombie" or self.nearby_enemies[count]:GetName() == "npc_dota_elder_titan_ancestral_spirit") then
            table.remove(self.nearby_enemies, count)
        end
    end

    if #self.nearby_enemies >= 1 then
        for _,enemy in pairs(self.nearby_enemies) do
            local previous_position = self.parent:GetAbsOrigin()
            -- Used to be 128 but it seems to interrupt a lot at fast speeds if there's Lotus battles...
            FindClearSpaceForUnit(self.parent, enemy:GetAbsOrigin() + RandomVector(100), false)
            
            if not self:GetAbility() then break end

            local current_position = self.parent:GetAbsOrigin()

            -- Face the enemy every slash
            self.parent:FaceTowards(enemy:GetAbsOrigin())
            
            -- Provide vision of the target for a short duration
            AddFOWViewer(self:GetCaster():GetTeamNumber(), enemy:GetAbsOrigin(), 200, 1, false)

            -- Perform the slash
            self.slash = true
            
            if first_slash and enemy:TriggerSpellAbsorb(self:GetAbility()) then
                break
            else
                self.parent:PerformAttack(enemy, true, true, true, true, true, false, false)
            end

            -- Apply Scepter Debuff --
            if self.parent:HasScepter() then
                local scepterDebuff = enemy:FindModifierByName("modifier_juggernaut_omni_slash_custom_scepter_debuff")
                if not scepterDebuff then
                    scepterDebuff = enemy:AddNewModifier(self.parent, self.ability, "modifier_juggernaut_omni_slash_custom_scepter_debuff", {
                        duration = self.scepterDuration
                    })
                end

                if scepterDebuff then
                    scepterDebuff:IncrementStackCount()
                    -- we will not refresh the duration. this means higher attack speed = more armor removal
                end
            end

            -- Play hit sound
            EmitSoundOn("Hero_Juggernaut.OmniSlash.Damage", enemy)

            local vDirection = enemy:GetAbsOrigin() - current_position
            vDirection.z = 0

            local dash_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_dash.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
            ParticleManager:SetParticleControl(dash_pfx, 0, current_position)
            ParticleManager:SetParticleControlForward(dash_pfx, 0, -vDirection:Normalized())
            ParticleManager:SetParticleControlEnt(dash_pfx, 1, target, PATTACH_CUSTOMORIGIN_FOLLOW, nil, enemy:GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(dash_pfx, 2, target, PATTACH_CUSTOMORIGIN_FOLLOW, nil, enemy:GetAbsOrigin(), true)
            ParticleManager:ReleaseParticleIndex(dash_pfx)

            -- Play hit particle on the current target
            local hit_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_tgt.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy, self:GetCaster())
            ParticleManager:SetParticleControl(hit_pfx, 0, current_position)
            ParticleManager:SetParticleControl(hit_pfx, 1, current_position)
            ParticleManager:ReleaseParticleIndex(hit_pfx)

            -- Play particle trail when moving
            local trail_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_trail.vpcf", PATTACH_ABSORIGIN, self.parent, self:GetCaster())
            ParticleManager:SetParticleControl(trail_pfx, 0, previous_position)
            ParticleManager:SetParticleControl(trail_pfx, 1, current_position)
            ParticleManager:ReleaseParticleIndex(trail_pfx)

            if self.last_enemy ~= enemy then
                local dash_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_dash.vpcf", PATTACH_ABSORIGIN, self.parent, self:GetCaster())
                ParticleManager:SetParticleControl(dash_pfx, 0, previous_position)
                ParticleManager:SetParticleControl(dash_pfx, 2, current_position)
                ParticleManager:ReleaseParticleIndex(dash_pfx)
            end

            self.last_enemy = enemy

            break
        end
    else
        self:Destroy()
    end
end

function modifier_juggernaut_omni_slash_custom_caster:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_juggernaut_omni_slash_custom_caster:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end

function modifier_juggernaut_omni_slash_custom_caster:GetOverrideAnimation()
    return ACT_DOTA_OVERRIDE_ABILITY_4
end

function modifier_juggernaut_omni_slash_custom_caster:GetEffectName()
    return "particles/units/heroes/hero_juggernaut/juggernaut_omnislash_light.vpcf"
end

function modifier_juggernaut_omni_slash_custom_caster:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_juggernaut_omni_slash_custom_caster:GetStatusEffectName()
    return "particles/status_fx/status_effect_omnislash.vpcf"
end

function modifier_juggernaut_omni_slash_custom_caster:StatusEffectPriority()
    return 100
end

function modifier_juggernaut_omni_slash_custom_caster:OnDestroy()
    if IsServer() then
        self:GetAbility():SetActivated(true)

        -- Re-enable Blade Fury during Omnislash (vanilla)
        --if self.caster:HasAbility("imba_juggernaut_blade_fury") then
        --    self.caster:FindAbilityByName("imba_juggernaut_blade_fury"):SetActivated(true)
        --end

        --self.parent:RemoveNoDraw()

        local parent = self:GetParent()
        if not parent:IsNull() then
            parent:RemoveGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
        
            parent:MoveToPositionAggressive(self.parent:GetAbsOrigin())
        end
    end
end

function modifier_juggernaut_omni_slash_custom_caster:CheckState()
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_CANNOT_MISS] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }

    return state
end
---------------------------
function modifier_juggernaut_omni_slash_custom_illusion:RemoveOnDeath() return true end

function modifier_juggernaut_omni_slash_custom_illusion:OnCreated()
    if not IsServer() then return end

    self.target = nil

    self:OnIntervalThink()
    self:StartIntervalThink(FrameTime())
end

function modifier_juggernaut_omni_slash_custom_illusion:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    if not caster:HasModifier("modifier_juggernaut_omni_slash_custom_caster") then
        self:Destroy()
        return
    end

    local hits = ability:GetSpecialValueFor("decoy_hits")

    parent:SetBaseMaxHealth(hits)
    parent:SetMaxHealth(hits)

    if parent:GetAggroTarget() == nil or (parent:GetAggroTarget() ~= nil and not parent:GetAggroTarget():IsAlive()) then
        self.target = nil
    end

    if self.target ~= nil then return end

    local targets = FindUnitsInRadius(
        parent:GetTeamNumber(),
        parent:GetAbsOrigin(),
        nil,
        600,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_CLOSEST,
        false
    )

    for _,target in ipairs(targets) do
        if target:IsAlive() and not target:IsInvulnerable() then
            self.target = target
            parent:SetForceAttackTarget(self.target)
        end
    end
end

function modifier_juggernaut_omni_slash_custom_illusion:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_ATTACKED,
        MODIFIER_PROPERTY_DISABLE_HEALING,
    }
end

function modifier_juggernaut_omni_slash_custom_illusion:OnAttacked( params )
    if IsServer() then
        if self:GetParent() == params.target then
            if params.attacker then
                self:GetParent():ModifyHealth( self:GetParent():GetHealth() - 1, nil, true, 0 )
            end
        end
    end

    return 0
end

function modifier_juggernaut_omni_slash_custom_illusion:GetDisableHealing()
    return 1
end

function modifier_juggernaut_omni_slash_custom_illusion:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_juggernaut_omni_slash_custom_illusion:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_juggernaut_omni_slash_custom_illusion:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_juggernaut_omni_slash_custom_illusion:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:ForceKill(false)
end

function modifier_juggernaut_omni_slash_custom_illusion:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    if event.unit ~= parent then return end

    local caster = self:GetCaster()

    caster:RemoveGesture(ACT_DOTA_OVERRIDE_ABILITY_4)

    local omnislash = caster:FindModifierByName("modifier_juggernaut_omni_slash_custom_caster")
    if omnislash then
        omnislash:Destroy()
    end
end

function modifier_juggernaut_omni_slash_custom_illusion:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }

    return state
end

function modifier_juggernaut_omni_slash_custom_illusion:GetEffectName()
    return "particles/units/heroes/hero_juggernaut/juggernaut_omnislash_light.vpcf"
end

function modifier_juggernaut_omni_slash_custom_illusion:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_juggernaut_omni_slash_custom_illusion:GetStatusEffectName()
    return "particles/status_fx/status_effect_omnislash.vpcf"
end

function modifier_juggernaut_omni_slash_custom_illusion:StatusEffectPriority()
    return 10001
end
----------------
function modifier_juggernaut_omni_slash_custom_scepter_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_juggernaut_omni_slash_custom_scepter_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("corruption") * self:GetStackCount()
end