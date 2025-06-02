LinkLuaModifier("modifier_techies_land_mines_custom", "heroes/hero_techies/techies_land_mines_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_land_mines_custom_thinker", "heroes/hero_techies/techies_land_mines_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_land_mines_custom_debuff", "heroes/hero_techies/techies_land_mines_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassThinker = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

techies_land_mines_custom = class(ItemBaseClass)
modifier_techies_land_mines_custom = class(techies_land_mines_custom)
modifier_techies_land_mines_custom_thinker = class(ItemBaseClassThinker)
modifier_techies_land_mines_custom_debuff = class(ItemBaseClassDebuff)
-------------
function techies_land_mines_custom:GetIntrinsicModifierName()
    return "modifier_techies_land_mines_custom"
end

function techies_land_mines_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function techies_land_mines_custom:OnSpellStart()
    if not IsServer() then return end

    function sortMinesTable(a, b)
        return a:GetCreationTime() < b:GetCreationTime()
    end

    self.caster = self:GetCaster()
    self.casterPos = self.caster:GetOrigin()
    self.point = self:GetCursorPosition()

    local count = self:GetSpecialValueFor("mines")
    if self.caster:HasTalent("special_bonus_unique_techies_1_custom") then
        count = count + self.caster:FindAbilityByName("special_bonus_unique_techies_1_custom"):GetSpecialValueFor("value")
    end

    local maxLimit = self:GetSpecialValueFor("max_limit")
    if self.caster:HasTalent("special_bonus_unique_techies_2_custom") then
        maxLimit = maxLimit + self.caster:FindAbilityByName("special_bonus_unique_techies_2_custom"):GetSpecialValueFor("value")
    end

    local findLandMines = FindUnitsInRadius(self.caster:GetTeamNumber(), self.point, nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
    local existingLandMines = {}
    self.existingLandMinesCount = 0

    for _,existingLandMine in ipairs(findLandMines) do
        if existingLandMine:GetUnitName() == "npc_dota_techies_land_mine_custom" then
            table.insert(existingLandMines, existingLandMine)
            table.sort(existingLandMines, sortMinesTable)

            self.existingLandMinesCount = self.existingLandMinesCount + 1
        end
    end

    for i = 1, count, 1 do
        if self.existingLandMinesCount+count > maxLimit then
            existingLandMines[i]:ForceKill(false)
            self.existingLandMinesCount = self.existingLandMinesCount - 1
        end

        local delay = (0.1*i)

        Timers:CreateTimer(delay, function()
            self:PlantBomb(i)
        end)
    end
end

function techies_land_mines_custom:PlantBomb(i)
    CreateUnitByNameAsync(
        "npc_dota_techies_land_mine_custom",
        self.casterPos,
        false,
        self.caster,
        self.caster,
        self.caster:GetTeamNumber(),

        function(unit)
            EmitSoundOn("Hero_Techies.StickyBomb.Plant", unit)

            unit:AddNewModifier(unit, nil, "modifier_max_movement_speed", {})
            unit:AddNewModifier(unit, nil, "modifier_movement_speed_uba", {
                speed = 900
            })

            unit:AddNewModifier(unit, self, "modifier_techies_land_mines_custom_thinker", {
                i = i
            })

            unit:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)

            Timers:CreateTimer(0.1*i, function()
                unit:MoveToPosition(self.point)
            end)
        end
    )
end
----
--
function modifier_techies_land_mines_custom_thinker:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
    }

    return funcs
end

function modifier_techies_land_mines_custom_thinker:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true
    }
end

function modifier_techies_land_mines_custom_thinker:OnCreated(params)
    if not IsServer() then return end

    local unit = self:GetParent()

    self.i = params.i
    self.triggered = false
    self.triggeredPriming = false

    self.radius = self:GetAbility():GetSpecialValueFor("radius")

    self:StartIntervalThink(0.1)
end

function modifier_techies_land_mines_custom_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local owner = parent:GetOwner()
    local ability = self:GetAbility()

    local enemies = FindUnitsInRadius(
        owner:GetTeamNumber(),   -- int, your team number
        parent:GetOrigin(),   -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    if #enemies > 0 and not self.triggered then
        if not self.triggeredPriming then
            EmitSoundOn("Hero_Techies.StickyBomb.Priming", parent)
            self.triggeredPriming = true
        end

        Timers:CreateTimer(2, function() 
            if parent ~= nil and not self.triggered then
                self.triggered = true

                local enemies = FindUnitsInRadius(
                    owner:GetTeamNumber(),   -- int, your team number
                    parent:GetOrigin(),   -- point, center point
                    nil,    -- handle, cacheUnit. (not known)
                    self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
                    DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
                    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
                    0,  -- int, flag filter
                    0,  -- int, order filter
                    false   -- bool, can grow cache
                )

                for _,enemy in ipairs(enemies) do
                    ApplyDamage({
                        victim = enemy,
                        attacker = owner,
                        damage = (ability:GetSpecialValueFor("damage") + (owner:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))) * self.i,
                        damage_type = DAMAGE_TYPE_MAGICAL,
                        ability = ability
                    })

                    enemy:AddNewModifier(owner, ability, "modifier_techies_land_mines_custom_debuff", {
                        duration = ability:GetSpecialValueFor("duration")
                    })
                end

                self:PlayEffects(parent)

                Timers:CreateTimer(0.1, function() 
                    parent:SetModel("models/development/invisiblebox.vmdl")
                end)

                Timers:CreateTimer(0.5, function()
                    parent:ForceKill(false)
                end)
            end
        end)
    end
end

function modifier_techies_land_mines_custom_thinker:OnDeath(event)
    if not IsServer() then return end
end

function modifier_techies_land_mines_custom_thinker:OnRemoved(event)
    if not IsServer() then return end
end

function modifier_techies_land_mines_custom_thinker:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf"
    local sound_cast = "Hero_Techies.StickyBomb.Detonate"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:SetParticleControl(effect_cast, 0, target:GetOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, target:GetOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end

function modifier_techies_land_mines_custom_thinker:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }

    return state
end
---
--
function modifier_techies_land_mines_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
    }

    return funcs
end

function modifier_techies_land_mines_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res_reduction")
end