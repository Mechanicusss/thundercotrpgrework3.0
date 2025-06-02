LinkLuaModifier("boss_keymaster_ai", "heroes/bosses/keymaster/ai", LUA_MODIFIER_MOTION_NONE)

boss_keymaster_ai = class({
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
})

function boss_keymaster_ai:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function boss_keymaster_ai:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    local unitName = parent:GetUnitName()

    local blockers = nil 
    local obstructions = {}
    local doors = 6

    if unitName == "npc_dota_boss_keymaster_1" then
        blockers = "keymaster_zone_blocker_1"
        _G.KeyMasterDeath1 = false
    end

    if unitName == "npc_dota_boss_keymaster_2" then
        blockers = "keymaster_zone_blocker_2"
        _G.KeyMasterDeath2 = false
    end

    if unitName == "npc_dota_boss_keymaster_3" then
        blockers = "keymaster_zone_blocker_3"
        _G.KeyMasterDeath3 = false
    end

    for i = 1, doors, 1 do
        local temp = Entities:FindByName(nil, blockers.."_"..i)
        table.insert(obstructions, temp)
    end

    for _,obstruction in ipairs(obstructions) do
        obstruction:SetEnabled(true, true)
    end
end

function boss_keymaster_ai:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    local unitName = parent:GetUnitName()

    local blockers = nil 
    local obstructions = {}
    local gates = nil
    local doors = 6

    if unitName == "npc_dota_boss_keymaster_1" then
        blockers = "keymaster_zone_blocker_1"
        gates = Entities:FindAllByName("keymaster_gate_blocker_1")
        Timers:CreateTimer(60, function()
            _G.KeyMasterDeath1 = true
        end)
    end

    if unitName == "npc_dota_boss_keymaster_2" then
        blockers = "keymaster_zone_blocker_2"
        gates = Entities:FindAllByName("keymaster_gate_blocker_2")
        Timers:CreateTimer(60, function()
            _G.KeyMasterDeath2 = true
        end)
    end

    if unitName == "npc_dota_boss_keymaster_3" then
        blockers = "keymaster_zone_blocker_3"
        gates = Entities:FindAllByName("keymaster_gate_blocker_3")
        Timers:CreateTimer(60, function()
            _G.KeyMasterDeath3 = true
        end)
    end

    for i = 1, doors, 1 do
        local temp = Entities:FindByName(nil, blockers.."_"..i)
        table.insert(obstructions, temp)
    end

    for _,obstruction in ipairs(obstructions) do
        local origin = obstruction:GetAbsOrigin()

        obstruction:SetAbsOrigin(Vector(origin.x, origin.y, (origin.z-500)))
        obstruction:SetEnabled(false, true)
    end

    -- Find the gate prop 
    if gates ~= nil then
        for _,gate in ipairs(gates) do
            gate:SetModel("models/props_generic/gate_wooden_destruction_02.vmdl")
            EmitSoundOn("TCOTRPG.Gate.Destroy", gate)
        end
    end

    PlayerBuffs:OpenBuffWindow()
end

-- We have to let people have time to pick a buff before we let another keymaster die
function boss_keymaster_ai:CheckState()
    local unitName = self:GetParent():GetUnitName()

    local states = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }

    if unitName == "npc_dota_boss_keymaster_2" and not _G.KeyMasterDeath1 then
        return {
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
            [MODIFIER_STATE_INVULNERABLE] = true
        }
    end

    if unitName == "npc_dota_boss_keymaster_3" and not _G.KeyMasterDeath2 then
        return {
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
            [MODIFIER_STATE_INVULNERABLE] = true
        }
    end

    return states
end