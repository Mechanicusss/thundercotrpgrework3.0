LinkLuaModifier("modifier_nevermore_shadow_raze_custom", "heroes/hero_nevermore/nevermore_shadow_raze_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nevermore_shadow_raze_custom_thinker", "heroes/hero_nevermore/nevermore_shadow_raze_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nevermore_shadow_raze_custom_debuff", "heroes/hero_nevermore/nevermore_shadow_raze_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

nevermore_shadow_raze_custom = class(ItemBaseClass)
modifier_nevermore_shadow_raze_custom = class(nevermore_shadow_raze_custom)
modifier_nevermore_shadow_raze_custom_thinker = class(nevermore_shadow_raze_custom)
modifier_nevermore_shadow_raze_custom_debuff = class(ItemBaseClassAura)

function nevermore_shadow_raze_custom:GetIntrinsicModifierName()
    return "modifier_nevermore_shadow_raze_custom"
end

function nevermore_shadow_raze_custom:GetManaCost(level)
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return 0 -- Устанавливаем стоимость маны в 0 при наличии шарда
    else
        local baseCost = self.BaseClass.GetManaCost(self, level)
        return baseCost
    end
end

function nevermore_shadow_raze_custom:GetCooldown(level)
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return 0.1 -- Устанавливаем время перезарядки в 0.1 секунды при наличии шарда
    else
        local baseCooldown = self.BaseClass.GetCooldown(self, level)
        return baseCooldown
    end
end

function nevermore_shadow_raze_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local pos1 = caster:GetAbsOrigin() + 200 * caster:GetForwardVector()
    local pos2 = caster:GetAbsOrigin() + 450 * caster:GetForwardVector()
    local pos3 = caster:GetAbsOrigin() + 700 * caster:GetForwardVector()

    local shardTime = 1

    if caster:HasModifier("modifier_item_aghanims_shard") then
        shardTime = 2
    end

    CreateModifierThinker(
        caster,
        self,
        "modifier_nevermore_shadow_raze_custom_thinker",
        { duration = 0.5 },
        pos1,
        caster:GetTeam(),
        false
    )

    Timers:CreateTimer(0.33/shardTime, function()
        CreateModifierThinker(
            caster,
            self,
            "modifier_nevermore_shadow_raze_custom_thinker",
            { duration = 0.5 },
            pos2,
            caster:GetTeam(),
            false
        )
    end)

    Timers:CreateTimer(0.66/shardTime, function()
        CreateModifierThinker(
            caster,
            self,
            "modifier_nevermore_shadow_raze_custom_thinker",
            { duration = 0.5 },
            pos3,
            caster:GetTeam(),
            false
        )
    end)

    if caster:HasModifier("modifier_item_aghanims_shard") then
        Timers:CreateTimer(0.99/shardTime, function()
            CreateModifierThinker(
                caster,
                self,
                "modifier_nevermore_shadow_raze_custom_thinker",
                { duration = 0.5 },
                pos3,
                caster:GetTeam(),
                false
            )
        end)

        Timers:CreateTimer(1.32/shardTime, function()
            CreateModifierThinker(
                caster,
                self,
                "modifier_nevermore_shadow_raze_custom_thinker",
                { duration = 0.5 },
                pos2,
                caster:GetTeam(),
                false
            )
        end)

        Timers:CreateTimer(1.65/shardTime, function()
            CreateModifierThinker(
                caster,
                self,
                "modifier_nevermore_shadow_raze_custom_thinker",
                { duration = 0.5 },
                pos1,
                caster:GetTeam(),
                false
            )
        end)
    end
end
-------------
function modifier_nevermore_shadow_raze_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK,
    }
end

function modifier_nevermore_shadow_raze_custom:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent() 

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() or ability:GetManaCost(-1) > parent:GetMana() or not ability:GetAutoCastState() then return end 
    if parent:IsSilenced() then return end

    SpellCaster:Cast(ability, target, true)
end 
-------------
function modifier_nevermore_shadow_raze_custom_thinker:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local radius = ability:GetSpecialValueFor("radius")
    local damage = (caster:GetAllAttributes() + (ability:GetSpecialValueFor("attribute_pct") / 100))
    local duration = ability:GetSpecialValueFor("duration")

    local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_POINT, parent)
    ParticleManager:SetParticleControl(effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)

    EmitSoundOn("Hero_Nevermore.Shadowraze", parent)

    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),   -- int, your team number
        parent:GetOrigin(),       -- point, center point
        nil,                      -- handle, cacheUnit. (not known)
        radius,                   -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, -- int, flag filter
        0,                        -- int, order filter
        false                     -- bool, can grow cache
    )

    for _, enemy in ipairs(enemies) do
        if not enemy:IsAlive() or enemy:IsMagicImmune() or enemy:IsInvulnerable() then break end 

        local debuff = enemy:FindModifierByName("modifier_nevermore_shadow_raze_custom_debuff")
        if not debuff then
            -- Если модификатор не существует, добавляем его
            debuff = enemy:AddNewModifier(caster, ability, "modifier_nevermore_shadow_raze_custom_debuff", {
                duration = duration
            })
        end 

        -- Увеличиваем количество стеков
        if debuff then
            debuff:IncrementStackCount()
        end 
        
        if debuff then
            debuff:ForceRefresh()
        end

        ApplyDamage({
            attacker = caster,
            victim = enemy,
            damage_type = ability:GetAbilityDamageType(),
            damage = damage,
            ability = ability
        })
    end
end

function modifier_nevermore_shadow_raze_custom_thinker:OnDestroy()
    if not IsServer() then return end

    UTIL_Remove(self:GetParent())
end
-------------
function modifier_nevermore_shadow_raze_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_nevermore_shadow_raze_custom_debuff:GetModifierIncomingDamage_Percentage(event)
    if event.inflictor == self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("stack_bonus_damage") * self:GetStackCount()
    end
end

function modifier_nevermore_shadow_raze_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_resistance_reduction")
end