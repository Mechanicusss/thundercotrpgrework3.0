LinkLuaModifier("modifier_duel", "duel", LUA_MODIFIER_MOTION_NONE)

if modifier_duel == nil then modifier_duel = class({}) end

DUEL_ACTIVE = false

function InitDuel()
    CustomNetTables:SetTableValue("duel", "game_info", { active = false }) -- Start at false

    for i=1, 8 do
    local door = Entities:FindByName(nil, "duel_door_1_" .. i)
        door:SetAbsOrigin(Vector(door:GetAbsOrigin().x, door:GetAbsOrigin().y, (door:GetAbsOrigin().z-500)))
        door:SetEnabled(false, true)
      end

    -- Duels --
    local duelTime = 300

    local direPoint = Entities:FindByName(nil, "duel_dire_tp_point")
    local radiantPoint = Entities:FindByName(nil, "duel_radiant_tp_point")

    Timers:CreateTimer(0.5, function()
        if not DUEL_ACTIVE then return 1.0 end

        local watchForDuel = CustomNetTables:GetTableValue("duel", "game_info")
        if watchForDuel ~= nil then
            if watchForDuel.active == 0 then 
                DUEL_ACTIVE = false

                local allheroes = HeroList:GetAllHeroes()
                for _, hero in ipairs(allheroes) do
                    hero:RemoveModifierByNameAndCaster("modifier_duel", hero)
                    
                    if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
                        FindClearSpaceForUnit(hero, Entities:FindByName(nil, "ent_dota_fountain_good"):GetAbsOrigin(), true)
                    else
                        FindClearSpaceForUnit(hero, Entities:FindByName(nil, "ent_dota_fountain_bad"):GetAbsOrigin(), true)
                    end
                end

                for i=1, 8 do
                    local door = Entities:FindByName(nil, "duel_door_1_" .. i)
                    door:SetAbsOrigin(Vector(door:GetAbsOrigin().x, door:GetAbsOrigin().y, (door:GetAbsOrigin().z-500)))
                    door:SetEnabled(false, true)
                end
            end
        end

        return 0.5
    end)

    Timers:CreateTimer(duelTime, function()
        if DUEL_ACTIVE then return duelTime end -- If duel is running we restart the timer

        local allheroes = HeroList:GetAllHeroes()
        if GetRealHeroCount() < 2 then return duelTime end -- Not enough players found, just in case...

        GameRules:SendCustomMessage("<font color='red'>Duel starts in 10 seconds!</font>", 0, 0)

        Timers:CreateTimer(10.0, function()
            for _, hero in ipairs(allheroes) do
                if not hero:IsRealHero() or not UnitIsNotMonkeyClone(hero) then break end

                if not hero:IsAlive() then
                    hero:RespawnUnit()
                end

                hero:Heal(hero:GetMaxHealth(), nil)
                hero:SetMana(hero:GetMaxMana())

                if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
                    FindClearSpaceForUnit(hero, radiantPoint:GetAbsOrigin(), true)
                    hero:AddNewModifier(hero, nil, "modifier_duel", {})
                else
                    FindClearSpaceForUnit(hero, direPoint:GetAbsOrigin(), true)
                    hero:AddNewModifier(hero, nil, "modifier_duel", {})
                end
            end

            CustomNetTables:SetTableValue("duel", "game_info", { active = true })
            DUEL_ACTIVE = true

            GameRules:SendCustomMessage("<font color='red'>Duel ends automatically after 2 minutes!</font>", 0, 0)

            for i=1, 8 do
                local door = Entities:FindByName(nil, "duel_door_1_" .. i)
                door:SetAbsOrigin(Vector(door:GetAbsOrigin().x, door:GetAbsOrigin().y, (door:GetAbsOrigin().z+500)))
                door:SetEnabled(true, true)
            end

            Timers:CreateTimer(120.0, function()
                if not DUEL_ACTIVE then return end

                for _, hero in ipairs(allheroes) do
                    if not hero:IsRealHero() or not UnitIsNotMonkeyClone(hero) then break end

                    if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
                        hero:RemoveModifierByNameAndCaster("modifier_duel", hero)
                        FindClearSpaceForUnit(hero, Entities:FindByName(nil, "ent_dota_fountain_good"):GetAbsOrigin(), true)
                    else
                        hero:RemoveModifierByNameAndCaster("modifier_duel", hero)
                        FindClearSpaceForUnit(hero, Entities:FindByName(nil, "ent_dota_fountain_bad"):GetAbsOrigin(), true)
                    end

                    hero:RespawnUnit()
                end

                CustomNetTables:SetTableValue("duel", "game_info", { active = false })
            end)
        end)

        return duelTime
    end)
end
--------
function modifier_duel:IsHidden() return true end
function modifier_duel:IsPurgable() return false end
function modifier_duel:RemoveOnDeath() return true end

function modifier_duel:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.boundary = Entities:FindByName(nil, "duel_boundary_trigger")
    self.lastPosition = parent:GetAbsOrigin()

    self:StartIntervalThink(0.5)
end

function modifier_duel:OnIntervalThink()
    local parent = self:GetParent()

    if not IsInTrigger(parent, self.boundary) and parent:IsAlive() then
        if parent:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
            FindClearSpaceForUnit(parent, Entities:FindByName(nil, "duel_radiant_tp_point"):GetAbsOrigin(), true)
        else
            FindClearSpaceForUnit(parent, Entities:FindByName(nil, "duel_dire_tp_point"):GetAbsOrigin(), true)
        end
    end
end

function modifier_duel:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_duel:OnDeath(event)
    if not IsServer() then return end

    local unit = event.unit
    if unit ~= self:GetParent() then
        return
    end

    if unit:WillReincarnate() or unit:IsReincarnating() then return end

    GameRules:SendCustomMessage("<font color='red'>"..PlayerResource:GetPlayerName(unit:GetPlayerID()).."</font> died first and has lost the duel!", 0, 0)

    CustomNetTables:SetTableValue("duel", "game_info", { active = false }) -- Start at false
end