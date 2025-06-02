HeroStatsManager = HeroStatsManager or class({})

modifier_hero_stats_manager_player = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

function HeroStatsManager:Init()

end

function HeroStatsManager:LoadAllPlayers()
    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and hero:GetUnitName() ~= "outpost_placeholder_unit" then
            hero:AddNewModifier(hero, nil, "modifier_hero_stats_manager_player", {})
        end
    end
end

function HeroStatsManager:LoadPlayer(hero)
    hero:AddNewModifier(hero, nil, "modifier_hero_stats_manager_player", {})
end
-----------------
function modifier_hero_stats_manager_player:OnCreated()
    if not IsServer() then return end 

    self.parent = self:GetParent()
    self.ailments = self.parent:FindModifierByName("modifier_elemental_ailments")
    self.crit = self.parent:FindModifierByName("modifier_critical_strikes_custom")

    self.accountID = PlayerResource:GetSteamAccountID(self.parent:GetPlayerID())
    
    self:StartIntervalThink(1)
end

function modifier_hero_stats_manager_player:OnIntervalThink()
    local critChance, critDamage = self.crit:GetTotalCrit()
    local ailmentBonuses = self.ailments:GetAilmentBonusForElements()
    
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(self.parent:GetPlayerID()), "hero_stats_manager_on_update", {
        critChance = critChance,
        critDamage = critDamage,
        fireDamage = ailmentBonuses.fire,
        coldDamage = ailmentBonuses.cold,
        natureDamage = ailmentBonuses.nature,
        lightningDamage = ailmentBonuses.lightning,
        arcaneDamage = ailmentBonuses.arcane,
        necroticDamage = ailmentBonuses.necrotic,
        temporalDamage = ailmentBonuses.temporal,
        damageReduction = GetPlayerDamageReduction(self.accountID),
        bonusDropRate = self.parent:GetBonusDropRate(),
        fireResistance = self.parent:COT_GetResistanceValue("fire"),
        coldResistance = self.parent:COT_GetResistanceValue("cold"),
        natureResistance = self.parent:COT_GetResistanceValue("nature"),
        lightningResistance = self.parent:COT_GetResistanceValue("lightning"),
        necroticResistance = self.parent:COT_GetResistanceValue("necrotic"),
        arcaneResistance = self.parent:COT_GetResistanceValue("arcane"),
        temporalResistance = self.parent:COT_GetResistanceValue("temporal"),
        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
    })
end