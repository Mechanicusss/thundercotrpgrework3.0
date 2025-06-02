LinkLuaModifier("modifier_boss_destruction_lord_soul_towers", "heroes/bosses/destruction_lord/boss_destruction_lord_soul_towers", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_destruction_lord_soul_towers_tower", "heroes/bosses/destruction_lord/boss_destruction_lord_soul_towers", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_destruction_lord_soul_towers_boss_buff", "heroes/bosses/destruction_lord/boss_destruction_lord_soul_towers", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

boss_destruction_lord_soul_towers = class(ItemBaseClass)
modifier_boss_destruction_lord_soul_towers = class(boss_destruction_lord_soul_towers)
modifier_boss_destruction_lord_soul_towers_tower = class(ItemBaseClass)
modifier_boss_destruction_lord_soul_towers_boss_buff = class(ItemBaseClassBuff)

boss_destruction_lord_soul_towers.towersAlive = {
    [1] = true,
    [2] = true,
    [3] = true,
}
-------------
function boss_destruction_lord_soul_towers:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    self.towersAlive = {
        [1] = true,
        [2] = true,
        [3] = true,
    }

    -- Delete old towers
    local towers = Entities:FindAllByModel("models/items/undying/idol_of_ruination/idol_tower.vmdl")
    for _,tower in ipairs(towers) do
        if tower ~= nil and not tower:IsNull() then
            if tower:HasModifier("modifier_boss_destruction_lord_soul_towers_tower") then
                tower:ForceKill(false)
            end
        end
    end

    local location1 = Entities:FindByName(nil, "boss_destruction_lord_mechanic_1_tombstone_1")
    local location2 = Entities:FindByName(nil, "boss_destruction_lord_mechanic_1_tombstone_2")
    local location3 = Entities:FindByName(nil, "boss_destruction_lord_mechanic_1_tombstone_3")

    local tower1 = CreateUnitByName("boss_destruction_lord_mechanic_tower_1", location1:GetAbsOrigin(), true, nil, nil, caster:GetTeam())
    local tower2 = CreateUnitByName("boss_destruction_lord_mechanic_tower_2", location2:GetAbsOrigin(), true, nil, nil, caster:GetTeam())
    local tower3 = CreateUnitByName("boss_destruction_lord_mechanic_tower_3", location3:GetAbsOrigin(), true, nil, nil, caster:GetTeam())

    tower1:AddNewModifier(caster, self, "modifier_boss_destruction_lord_soul_towers_tower", { duration = self:GetSpecialValueFor("duration") })
    tower2:AddNewModifier(caster, self, "modifier_boss_destruction_lord_soul_towers_tower", { duration = self:GetSpecialValueFor("duration") })
    tower3:AddNewModifier(caster, self, "modifier_boss_destruction_lord_soul_towers_tower", { duration = self:GetSpecialValueFor("duration") })

    tower1:SetForwardVector(-tower1:GetForwardVector())
    tower2:SetForwardVector(-tower2:GetForwardVector())
end
-------------
function modifier_boss_destruction_lord_soul_towers_tower:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    self.lifeDrain = parent:FindAbilityByName("boss_destruction_tower_drain")

    self.dead = false

    self:StartIntervalThink(0.1)

    EmitSoundOn("Hero_Undying.Tombstone", parent)
end

function modifier_boss_destruction_lord_soul_towers_tower:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent:IsAlive() then
        parent:ForceKill(false)
    end

    EmitSoundOn("Hero_Undying.Tombstone.Destruction", parent)
end

function modifier_boss_destruction_lord_soul_towers_tower:OnIntervalThink()
    local parent = self:GetParent()

    if not parent:IsChanneling() and not parent:HasModifier("modifier_black_king_bar_immune") then
        local units = FindUnitsInRadius(self:GetCaster():GetTeam(), parent:GetAbsOrigin(), nil,
            900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,unit in ipairs(units) do
            if unit:IsAlive() and unit ~= parent and not unit:HasModifier("modifier_boss_destruction_tower_drain_debuff_thinker") then
                parent:CastAbilityOnTarget(unit, self.lifeDrain, -1)
                break
            end
        end
    end
end

function modifier_boss_destruction_lord_soul_towers_tower:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_DISABLE_TURNING,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_boss_destruction_lord_soul_towers_tower:GetAbsoluteNoDamagePhysical( params )
    return 1
end

function modifier_boss_destruction_lord_soul_towers_tower:GetAbsoluteNoDamageMagical( params )
    return 1
end

function modifier_boss_destruction_lord_soul_towers_tower:GetAbsoluteNoDamagePure( params )
    return 1
end

function modifier_boss_destruction_lord_soul_towers_tower:OnTakeDamage(params)
    if IsServer() then
        if self:GetParent() == params.unit then
            local nDamage = 0
            if params.attacker and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and params.damage_type == DAMAGE_TYPE_PHYSICAL and not self:GetParent():HasModifier("modifier_boss_zombie_tombstone_follower_recharging") then
                local bDeathWard = params.attacker:FindModifierByName( "modifier_aghsfort_witch_doctor_death_ward" ) ~= nil
                local bValidAttacker = params.attacker:IsRealHero() or bDeathWard
                if not bValidAttacker then
                    return 0
                end
            
                nDamage = 1

                self:GetParent():ModifyHealth( self:GetParent():GetHealth() - nDamage, nil, true, 0 )
            end
        end
    end

    return 0
end

function modifier_boss_destruction_lord_soul_towers_tower:GetModifierDisableTurning()
    return 1
end

function modifier_boss_destruction_lord_soul_towers_tower:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.unit ~= parent then return end 

    local caster = self:GetCaster()

    local name = parent:GetUnitName()

    local ability = self:GetAbility()

    if self.dead then return end

    self.dead = true

    if name == "boss_destruction_lord_mechanic_tower_1" and ability.towersAlive[1] and ability.towersAlive[2] and ability.towersAlive[3] then
        ability.towersAlive[1] = false
    elseif name == "boss_destruction_lord_mechanic_tower_2" and not ability.towersAlive[1] and ability.towersAlive[2] and ability.towersAlive[3] then
        ability.towersAlive[2] = false
    elseif name == "boss_destruction_lord_mechanic_tower_3" and not ability.towersAlive[1] and not ability.towersAlive[2] and ability.towersAlive[3] then
        ability.towersAlive[3] = false
    else
        -- Mechanic failed
        local towers = Entities:FindAllByModel("models/items/undying/idol_of_ruination/idol_tower.vmdl")
        for _,tower in ipairs(towers) do
            if tower ~= nil and not tower:IsNull() then
                if tower:HasModifier("modifier_boss_destruction_lord_soul_towers_tower") then
                    tower:ForceKill(false)
                end
            end
        end

        caster:AddNewModifier(caster, ability, "modifier_boss_destruction_lord_soul_towers_boss_buff", { duration = ability:GetSpecialValueFor("buff_duration") })
        caster:RemoveModifierByName("boss_destruction_lord_ai_frozen")

        EmitSoundOn("Hero_Terrorblade.Sunder.Cast", caster)
    end

    if not ability.towersAlive[1] and not ability.towersAlive[2] and not ability.towersAlive[3] then
        caster:RemoveModifierByName("boss_destruction_lord_ai_frozen")
    end
end

function modifier_boss_destruction_lord_soul_towers_tower:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }   

    return state
end
--------------------
function modifier_boss_destruction_lord_soul_towers_boss_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_boss_destruction_lord_soul_towers_boss_buff:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("buff_regen_pct")
end

function modifier_boss_destruction_lord_soul_towers_boss_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("buff_dmg_pct")
end