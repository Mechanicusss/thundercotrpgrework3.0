LinkLuaModifier("modifier_boss_omniknight_purification", "heroes/bosses/divine/boss_omniknight_purification", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

boss_omniknight_purification = class(ItemBaseClass)
modifier_boss_omniknight_purification = class(boss_omniknight_purification)
-------------
function boss_omniknight_purification:GetIntrinsicModifierName()
    return "modifier_boss_omniknight_purification"
end
-------------
function modifier_boss_omniknight_purification:OnCreated()
    if not IsServer() then return end 

    self.ability = self:GetAbility()

    self.damageCount = 0

    self.pctDivider = self.ability:GetSpecialValueFor("max_hp_threshold")
    self.maxHpHealPct = self.ability:GetSpecialValueFor("max_hp_heal_pct")
    self.radius = self.ability:GetSpecialValueFor("radius")
end

function modifier_boss_omniknight_purification:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

function modifier_boss_omniknight_purification:GetModifierIncomingDamage_Percentage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    local target = event.target 
    local attacker = event.attacker

    if target ~= parent or attacker:GetTeam() ~= DOTA_TEAM_GOODGUYS then return end 
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
    if parent:PassivesDisabled() then return end

    self.damageCount = self.damageCount + event.damage

    if self.damageCount >= (parent:GetMaxHealth() * (self.pctDivider/100)) then
        local amount = parent:GetMaxHealth() * (self.maxHpHealPct/100)

        SendOverheadEventMessage(parent, OVERHEAD_ALERT_HEAL, parent, amount, nil)

        EmitSoundOn("Hero_Omniknight.Purification", parent)

        local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)

        ParticleManager:SetParticleControl(effect_cast, 0, parent:GetAbsOrigin())
        ParticleManager:SetParticleControl(effect_cast, 1, Vector(self.radius, self.radius, self.radius))
        ParticleManager:ReleaseParticleIndex(effect_cast)

        local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
                self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            if victim:IsMagicImmune() or victim:IsInvulnerable() then break end

            ApplyDamage({
                attacker = parent,
                victim = victim,
                damage = amount,
                damage_type = DAMAGE_TYPE_PURE,
                ability = self.ability
            })
        end

        self.damageCount = 0
    end
end