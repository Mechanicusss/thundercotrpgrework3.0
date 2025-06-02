LinkLuaModifier("modifier_limited_lives", "modifiers/modifier_limited_lives", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

limited_lives = class(BaseClass)
modifier_limited_lives = class(limited_lives)
-------------
function limited_lives:GetIntrinsicModifierName()
    return "modifier_limited_lives"
end

function modifier_limited_lives:GetTexture()
    return "item_aegis"
end

function modifier_limited_lives:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    parent:SetModifierStackCount("modifier_limited_lives", parent, params.count)
end

function modifier_limited_lives:DeclareFunctions()
    local funcs = {
        --MODIFIER_EVENT_ON_DEATH 
    }

    return funcs
end

function modifier_limited_lives:OnDeath(event)
    if event.unit ~= self:GetParent() then return end

    local heroes = HeroList:GetAllHeroes()
    local amount = 0
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and hero:GetUnitName() ~= "outpost_placeholder_unit" and not hero:IsReincarnating() and not hero:WillReincarnate() and hero:UnitCanRespawn() and hero:IsAlive() then
            amount = amount + 1
        end
    end

    if amount <= 0 then
        GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
    end
end

function modifier_limited_lives:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end