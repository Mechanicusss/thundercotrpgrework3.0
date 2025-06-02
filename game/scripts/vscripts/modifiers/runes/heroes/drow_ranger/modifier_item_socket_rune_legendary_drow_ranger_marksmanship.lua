LinkLuaModifier("modifier_item_socket_rune_legendary_drow_ranger_marksmanship", "modifiers/runes/heroes/drow_ranger/modifier_item_socket_rune_legendary_drow_ranger_marksmanship", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_drow_ranger_marksmanship = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_drow_ranger_marksmanship:OnCreated()
    self.arrowCount = 2
    self.interval = 0.65
    self.multishotChance = 70
    self.critChance = 60
    self.critDamage = 450

    if not IsServer() then return end 

    self:StartIntervalThink(self.interval)
end

function modifier_item_socket_rune_legendary_drow_ranger_marksmanship:OnIntervalThink()
    local caster = self:GetCaster()

    if not caster:IsAlive() then return end 
    
    local maxUnits = self.arrowCount
    local radius = caster:Script_GetAttackRange()
    local i = 0

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_CLOSEST, false)

    victims = shuffleTable(victims)

    for _,enemy in ipairs(victims) do
        if enemy:IsAlive() and not enemy:IsInvulnerable() and not enemy:IsAttackImmune() and i < maxUnits then
            i = i + 1
            caster:PerformAttack(
                enemy,
                true,
                true,
                true,
                false,
                true,
                false,
                false
            )
        end
    end
end