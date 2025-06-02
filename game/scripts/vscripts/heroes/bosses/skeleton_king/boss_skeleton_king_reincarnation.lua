LinkLuaModifier("boss_skeleton_king_reincarnation_modifier", "heroes/bosses/skeleton_king/boss_skeleton_king_reincarnation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_skeleton_king_reincarnation_modifier_debuff", "heroes/bosses/skeleton_king/boss_skeleton_king_reincarnation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_skeleton_king_reincarnation_modifier_reincarnating", "heroes/bosses/skeleton_king/boss_skeleton_king_reincarnation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_skeleton_king_reincarnation_modifier_dr_buff", "heroes/bosses/skeleton_king/boss_skeleton_king_reincarnation", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local ItemSelfDeBuffBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemSelfReincBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsDebuff = function(self) return false end,
}

boss_skeleton_king_reincarnation = class(BaseClass)
boss_skeleton_king_reincarnation_modifier = class(BaseClass)
boss_skeleton_king_reincarnation_modifier_debuff = class(ItemSelfDeBuffBaseClass)
boss_skeleton_king_reincarnation_modifier_reincarnating = class(ItemSelfReincBaseClass)
boss_skeleton_king_reincarnation_modifier_dr_buff = class(ItemSelfDeBuffBaseClass)

function boss_skeleton_king_reincarnation_modifier_dr_buff:IsDebuff() return false end

function boss_skeleton_king_reincarnation:GetIntrinsicModifierName()
    return "boss_skeleton_king_reincarnation_modifier"
end
-------------
function boss_skeleton_king_reincarnation_modifier:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MIN_HEALTH 
    }
    return funcs
end

function boss_skeleton_king_reincarnation_modifier:OnCreated()
    if not IsServer() then return end
end

function boss_skeleton_king_reincarnation_modifier:GetMinHealth()
    if not IsServer() then return end

    local parent = self:GetParent()

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() or parent:HasModifier("boss_skeleton_king_reincarnation_modifier_reincarnating") then 
        return 
    end

    if parent:GetHealth() <= 1 then
        local reincarnationTime = ability:GetSpecialValueFor("reincarnate_time")

        parent:AddNewModifier(parent, ability, "boss_skeleton_king_reincarnation_modifier_reincarnating", {
            duration = reincarnationTime
        })
    end

    return 1
end
-----------------
function boss_skeleton_king_reincarnation_modifier_debuff:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

function boss_skeleton_king_reincarnation_modifier_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }
end

function boss_skeleton_king_reincarnation_modifier_debuff:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function boss_skeleton_king_reincarnation_modifier_debuff:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function boss_skeleton_king_reincarnation_modifier_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function boss_skeleton_king_reincarnation_modifier_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function boss_skeleton_king_reincarnation_modifier_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movespeed")
end
-------------------
function boss_skeleton_king_reincarnation_modifier_reincarnating:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }
end

function boss_skeleton_king_reincarnation_modifier_reincarnating:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE 
    }
end

function boss_skeleton_king_reincarnation_modifier_reincarnating:GetAbsoluteNoDamagePhysical()
    return 1
end

function boss_skeleton_king_reincarnation_modifier_reincarnating:GetAbsoluteNoDamageMagical()
    return 1
end

function boss_skeleton_king_reincarnation_modifier_reincarnating:GetAbsoluteNoDamagePure()
    return 1
end

function boss_skeleton_king_reincarnation_modifier_reincarnating:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    --[[
    self.oldModel = parent:GetModelName()

    parent:AddNoDraw()

    local children = parent:GetChildren()
    self.oldChildModels = {}

    for _,child in pairs(children) do
        if child:GetModelName() == "models/items/wraith_king/arcana/wraith_king_arcana_weapon.vmdl" or child:GetModelName() == "models/items/wraith_king/arcana/wraith_king_arcana_head.vmdl" or child:GetModelName() == "models/items/wraith_king/arcana/wraith_king_arcana_shoulder.vmdl" or child:GetModelName() == "models/items/wraith_king/blistering_shade/mesh/blistering_shade_alt.vmdl" or child:GetModelName() == "models/items/wraith_king/arcana/wraith_king_arcana_back.vmdl" or child:GetModelName() == "models/items/wraith_king/arcana/wraith_king_arcana_armor.vmdl" then
            self.oldChildModels[child:entindex()] = self.oldChildModels[child:entindex()] or child:GetModelName()

            child:SetModel("models/development/invisiblebox.vmdl")
        end
    end
    --]]

    StartAnimation(parent, {duration=2.96667, activity=ACT_DOTA_DIE})

    ability:UseResources(false, false, false, true)

    local vfx = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_reincarn.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(vfx, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfx)

    local vfxTomb = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_style2_reincarn_tombstone.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(vfxTomb, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfxTomb)

    EmitSoundOnLocationWithCaster(parent:GetAbsOrigin(), "Hero_SkeletonKing.Reincarnate.Arcana", parent)
    EmitSoundOnLocationWithCaster(parent:GetAbsOrigin(), "Hero_SkeletonKing.Reincarnate.Stinger.Arcana", parent)

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() or victim:IsInvulnerable() then break end

        local hellfireBlast = parent:FindAbilityByName("boss_skeleton_king_hellfire_blast")
        if hellfireBlast ~= nil then
            SpellCaster:Cast(hellfireBlast, victim, false)
        end

        victim:AddNewModifier(self:GetParent(), ability, "boss_skeleton_king_reincarnation_modifier_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    parent:SetHealth(parent:GetMaxHealth())
end

function boss_skeleton_king_reincarnation_modifier_reincarnating:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        900, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        if (parent:GetAbsOrigin()-victim:GetAbsOrigin()):Length2D() < 900 then
            ApplyDamage({
                victim = parent,
                attacker = victim,
                damage = 1,
                damage_type = DAMAGE_TYPE_PURE
            })
        end
    end
end

function boss_skeleton_king_reincarnation_modifier_reincarnating:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    EmitSoundOnLocationWithCaster(parent:GetAbsOrigin(), "Hero_SkeletonKing.ArcanaGesture", parent)

    parent:Purge(false, true, false, true, true)

    --[[
    parent:RemoveNoDraw()

    for index,z in pairs(self.oldChildModels) do
        local child = EntIndexToHScript(index)
        if child ~= nil then
            local oldModel = self.oldChildModels[index]
            child:SetModel(oldModel)
        end
    end
    --]]

    parent:SetHealth(parent:GetMaxHealth())

    parent:AddNewModifier(parent, ability, "boss_skeleton_king_reincarnation_modifier_dr_buff", {
        duration = ability:GetSpecialValueFor("dr_duration")
    })
end
--------------
function boss_skeleton_king_reincarnation_modifier_dr_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function boss_skeleton_king_reincarnation_modifier_dr_buff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("dr")
end