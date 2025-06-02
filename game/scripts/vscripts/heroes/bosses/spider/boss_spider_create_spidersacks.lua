LinkLuaModifier("modifier_boss_spider_create_spidersacks_debuff", "heroes/bosses/spider/boss_spider_create_spidersacks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spider_follower_web_ai", "bosses/spider", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

boss_spider_create_spidersacks = class(ItemBaseClass)
modifier_boss_spider_create_spidersacks_debuff = class(boss_spider_create_spidersacks)
-------------
function boss_spider_create_spidersacks:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    local duration = self:GetSpecialValueFor("duration")

    local number = self:GetSpecialValueFor("count")

    for i = 1, number, 1 do
        local pos = caster:GetAbsOrigin() + RandomVector(RandomFloat(100, radius))

        Timers:CreateTimer(i/3, function()
            if not caster:IsAlive() then return end

            CreateUnitByNameAsync("npc_dota_creature_40_crip_2", pos, true, nil, nil, caster:GetTeamNumber(), function(unit)
                unit:RemoveAbility("Respawn")
                unit:AddNewModifier(unit, self, "modifier_boss_spider_follower_web_ai", {
                    duration = duration
                })
            end)
        end)
    end
end
