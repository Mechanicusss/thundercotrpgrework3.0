LinkLuaModifier("modifier_GreedyGoblin", "modules/greedy_goblin/goblin", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_max_movement_speed", "modifiers/modifier_max_movement_speed", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

GreedyGoblin = class(BaseClass)
modifier_GreedyGoblin = class(GreedyGoblin)
GreedyGoblin.canSpawn = true
-------------
function GreedyGoblin:Spawn(pos)
    if not IsServer() then return end

    if not self.canSpawn then return end

    CreateUnitByNameAsync("npc_dota_creature_greedy_goblin", pos, false, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
      unit:AddNewModifier(unit, nil, "modifier_GreedyGoblin", {
        duration = 8
      })
      self.canSpawn = false
      Timers:CreateTimer(60.0, function()
        self.canSpawn = true
      end)
    end)
end
---
function modifier_GreedyGoblin:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_ATTACKED,
        MODIFIER_PROPERTY_DISABLE_HEALING,
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_GreedyGoblin:OnAttacked( params )
    if IsServer() then
        if self:GetParent() == params.target then
            if params.attacker then
                self:GetParent():ModifyHealth( self:GetParent():GetHealth() - 1, nil, true, 0 )
            end
        end
    end

    return 0
end

function modifier_GreedyGoblin:GetDisableHealing()
    return 1
end

function modifier_GreedyGoblin:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_GreedyGoblin:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_GreedyGoblin:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_GreedyGoblin:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then return end
    if event.unit == event.attacker then return end

    if RollPercentage(12) and not _G.ItemDroppedAsanBlade2 then
        local drop = DropNeutralItemAtPositionForHero("item_asan_dagger_2", event.unit:GetAbsOrigin(), event.unit, -1, true)
        drop:GetContainedItem():SetStacksWithOtherOwners(true)
        _G.ItemDroppedAsanBlade2 = true
    end

    if RollPercentage(5) then
        local neutralDropName = NEUTRAL_ITEM_LIST_T2[RandomInt(1, #NEUTRAL_ITEM_LIST_T2)]
        local neutralDrop = DropNeutralItemAtPositionForHero(neutralDropName, event.unit:GetAbsOrigin(), event.unit, -1, true)
        neutralDrop:GetContainedItem():SetStacksWithOtherOwners(true)
    end

    local goblinPos = event.unit:GetAbsOrigin()

    -- Drops --
    for i = 1, self.goldBagDrops, 1 do
        Timers:CreateTimer((i/self.goldBagDrops)+(i/5), function()
            local items = {
                "item_gold_bag",
            }
            local chosenDrop = RandomInt(1, #items)
            DropNeutralItemAtPositionForHero(items[chosenDrop], Vector(goblinPos.x+RandomInt(-100, 100), goblinPos.y+RandomInt(-100, 100), goblinPos.z), event.unit, 1, false)
        end)
    end
end

function modifier_GreedyGoblin:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    self.goldBagDrops = RandomInt(5, 10)

    parent:AddNewModifier(parent, nil, "modifier_max_movement_speed", {})

    EmitSoundOn("soundboard.greevil_laughs", parent)

    local effect_cast = ParticleManager:CreateParticle( "particles/econ/items/effigies/status_fx_effigies/aghs_statue_destruction_gold.vpcf", PATTACH_POINT_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    self:StartIntervalThink(0.25)
end

function modifier_GreedyGoblin:OnIntervalThink()
    local parent = self:GetParent()

    local pos = parent:GetAbsOrigin()

    if RollPercentage(10) then -- Just to reduce drops a bit
        local goldBag = DropNeutralItemAtPositionForHero("item_gold_bag", parent:GetAbsOrigin(), parent, -1, true)
        goldBag:SetModelScale(1.25)
        self.goldBagDrops = self.goldBagDrops - 1
    end

    local movingDistance = 1000

    local randomPoint = Vector(pos.x+RandomInt(-movingDistance, movingDistance), pos.y+RandomInt(-movingDistance, movingDistance), pos.z)

    if not parent:IsMoving() then
        parent:MoveToPosition(randomPoint)
    end
end

function modifier_GreedyGoblin:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= nil then
        if parent:IsAlive() then
            UTIL_RemoveImmediate(parent)
        end
    end
end

function modifier_GreedyGoblin:GetEffectName()
    return "particles/econ/items/effigies/status_fx_effigies/aghs_statue_gold_ambient.vpcf"
end

function modifier_GreedyGoblin:CheckState()
    return {
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true
    }
end