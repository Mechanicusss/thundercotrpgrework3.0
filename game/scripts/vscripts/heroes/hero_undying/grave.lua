LinkLuaModifier("modifier_undying_grave_custom", "heroes/hero_undying/grave", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassResurrecting = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

undying_grave_custom = class(ItemBaseClass)
modifier_undying_grave_custom = class(undying_grave_custom)
-------------
function undying_grave_custom:GetIntrinsicModifierName()
    return "modifier_undying_grave_custom"
end

function modifier_undying_grave_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_REINCARNATION,
    }
    return funcs
end

function modifier_undying_grave_custom:ReincarnateTime()
    if IsServer() then
        if not self:GetAbility():IsCooldownReady() then return end

        self:GetAbility():UseResources(false, false, false, true)

        local parent = self:GetParent()

        CreateUnitByNameAsync("npc_dota_unit_tombstone_custom", parent:GetAbsOrigin(), true, nil, nil, parent:GetTeamNumber(), function(unit)
            EmitSoundOn("Hero_Undying.Tombstone", unit)
            
            unit:AddNewModifier(parent, nil, "modifier_invulnerable", {})

            Timers:CreateTimer(5, function()
                local tombstone = Entities:FindByModel(nil, "models/items/undying/idol_of_ruination/idol_tower.vmdl")
                if tombstone ~= nil then
                    UTIL_RemoveImmediate(tombstone)
                end
            end)
        end)
    end

    return 5.0
end