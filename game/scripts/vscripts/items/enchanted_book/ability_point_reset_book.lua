LinkLuaModifier("modifier_item_ability_point_reset_book", "items/enchanted_book/ability_point_reset_book", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_ability_point_reset_book = class(ItemBaseClass)
modifier_item_ability_point_reset_book = class(ItemBaseClass)

BANNED_ABILITIES = {
    "carl_wex",
    "carl_quas",
    "carl_exort",
    "carl_invoke",
    "carl_cold_snap",
    "carl_ghost_walk",
    "invoker_tornado",
    "carl_emp",
    "carl_alacrity",
    "carl_chaos_meteor",
    "carl_sun_strike",
    "carl_forge_spirit",
    "carl_ice_wall",
    "invoker_deafening_blast",
}

function item_ability_point_reset_book:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    
    local points = caster:GetAbilityPoints()

    if caster:GetUnitName() == "npc_dota_hero_arena_hero_carl" or caster:GetUnitName() == "npc_dota_hero_invoker" then
        local hero = PlayerResource:GetBarebonesAssignedHero(caster:GetPlayerID())
        local exort = hero:FindAbilityByName("carl_exort"):GetLevel()
        local quas = hero:FindAbilityByName("carl_quas"):GetLevel()
        local wex = hero:FindAbilityByName("carl_wex"):GetLevel()

        points = exort+quas+wex-3
        hero.points = points
    end

    for i=0, caster:GetAbilityCount()-1 do
        local abil = caster:GetAbilityByIndex(i)
        if abil ~= nil then
            local pass = true
            for _,banned in ipairs(BANNED_ABILITIES) do
                if abil:GetAbilityName() == banned then pass = false end
            end

            if pass then
                abil:SetLevel(0)
            end

            if not pass then
                abil:SetLevel(1)
            end
        end
    end

    caster:SetAbilityPoints(points)

    if self:GetCurrentCharges() > 1 then
        self:SetCurrentCharges(self:GetCurrentCharges()-1)
    else
        caster:RemoveItem(self)
    end
end