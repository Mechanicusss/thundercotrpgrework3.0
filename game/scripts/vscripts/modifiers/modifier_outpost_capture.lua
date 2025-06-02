LinkLuaModifier("modifier_outpost_capture", "modifiers/modifier_outpost_capture.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

outpost_capture = class(ItemBaseClass)
modifier_outpost_capture = class(outpost_capture)

-----------------
function outpost_capture:GetIntrinsicModifierName()
    return "modifier_outpost_capture"
end
-----------------
function modifier_outpost_capture:OnCreated()
    if not IsServer() or IsPvP() then return end

    local parent = self:GetParent()

    local ability = parent:FindAbilityByName("ability_capture")
    if ability == nil then
        ability = parent:AddAbility("ability_capture")
    end

    ability:SetLevel(1)

    self:StartIntervalThink(0.5)
end

function modifier_outpost_capture:OnIntervalThink()
    if IsPvP() then return end

    local hero = self:GetParent()
    local heroLevel = hero:GetLevel()
    local towers = FindUnitsInRadius(
        hero:GetTeam(), 
        hero:GetAbsOrigin(), 
        nil, 
        800, 
        DOTA_UNIT_TARGET_TEAM_ENEMY, 
        DOTA_UNIT_TARGET_BUILDING, 
        bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE), 
        FIND_CLOSEST, 
        false
    )

    if towers[1] then
        --if self.hTarget == towers[1] or hero:IsCommandRestricted() then heroLevel = hero:GetLevel() return end
        self.hTarget = towers[1]
        self.hTarget:RemoveModifierByName("modifier_invulnerable")

        local outpostName = self.hTarget:GetName()

        if string.find(self.hTarget:GetName(), "outpost") then
            if outpostName == "outpost_zone_skafian" and heroLevel < 15 then
                return
            elseif outpostName == "outpost_zone_spider" and heroLevel < 30 then
                return
            elseif outpostName == "outpost_zone_reef" and heroLevel < 50 then
                return
            elseif outpostName == "outpost_zone_mine" and heroLevel < 75 then
                return
            elseif outpostName == "outpost_zone_zeus" and heroLevel < 100 then
                return
            end

            local tOrder = 
                {
                    UnitIndex = hero:entindex(),
                    OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
                    AbilityIndex = hero:FindAbilityByName("ability_capture"):entindex(),
                    TargetIndex = self.hTarget:entindex()
                }
            ExecuteOrderFromTable(tOrder)
            
            self.bSentCommand = true
        elseif FindUnitsInRadius(towers[1]:GetTeam(), towers[1]:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)[1]  then
            if outpostName == "outpost_zone_skafian" and heroLevel < 15 then
                return
            elseif outpostName == "outpost_zone_spider" and heroLevel < 30 then
                return
            elseif outpostName == "outpost_zone_reef" and heroLevel < 50 then
                return
            elseif outpostName == "outpost_zone_mine" and heroLevel < 75 then
                return
            elseif outpostName == "outpost_zone_zeus" and heroLevel < 100 then
                return
            end

            local tOrder = 
                {
                    UnitIndex = hero:entindex(),
                    OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
                    TargetIndex = self.hTarget:entindex()
                }
            hero:SetForceAttackTarget(nil)
            ExecuteOrderFromTable(tOrder)
            self.bSentCommand = true
            hero:SetForceAttackTarget(self.hTarget)
        end
    elseif self.bSentCommand then 
        local outpostName = self.hTarget:GetName()

        self.hTarget:SetTeam(DOTA_TEAM_GOODGUYS)

        hero:SetForceAttackTarget(nil)

        CustomNetTables:SetTableValue("zone_outpost_capture", "game_info", { 
          zone = outpostName,
          r = RandomInt(1, 9999), 
          z = RandomInt(1, 9999),
          y = RandomInt(1, 9999),
          x = RandomInt(1, 9999),
          u = RandomInt(1, 9999),
        })

        self.bSentCommand = false
        self.hTarget = nil
    end
end