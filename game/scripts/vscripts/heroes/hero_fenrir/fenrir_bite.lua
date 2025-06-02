LinkLuaModifier("modifier_fenrir_bite", "heroes/hero_fenrir/fenrir_bite", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

fenrir_bite = class(ItemBaseClass)
modifier_fenrir_bite = class(fenrir_bite)
-------------
function fenrir_bite:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target or target == nil then return end

    if target:HasModifier("modifier_fenrir_bite") then
        target:RemoveModifierByName("modifier_fenrir_bite")
    end

    local duration = self:GetSpecialValueFor("duration")

    target:AddNewModifier(caster, self, "modifier_fenrir_bite", {
        duration = duration
    })

    EmitSoundOn("Hero_Ancient_Apparition.ColdFeetCast", target)
end

function fenrir_bite:GetAbilityTargetTeam()
    if self:GetCaster():HasScepter() then return DOTA_UNIT_TARGET_TEAM_BOTH end

    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function fenrir_bite:CastFilterResultTarget(target)
    if self:GetCaster():HasScepter() then
        if target:GetTeamNumber() == self:GetCaster():GetTeamNumber() then
           if target:IsHero() then
                return UF_SUCCESS
            else
                return UF_FAIL_OTHER 
            end
        end

        if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
            return UF_SUCCESS
        end
    else
        if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
            return UF_SUCCESS
        else
            return UF_FAIL_FRIENDLY
        end
    end
end
------------
function modifier_fenrir_bite:DeclareFunctions()
    return {
         MODIFIER_PROPERTY_DISABLE_HEALING,
         MODIFIER_EVENT_ON_ATTACK_LANDED,
         MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
         MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE 
    }
end

function modifier_fenrir_bite:GetDisableHealing()
    return 1
end

function modifier_fenrir_bite:GetModifierMoveSpeedBonus_Percentage()
    local value = self:GetAbility():GetSpecialValueFor("slow")

    if self:GetCaster():HasScepter() then
        return math.abs(value)
    end

    return value
end

function modifier_fenrir_bite:GetModifierAttackSpeedPercentage()
    local value = self:GetAbility():GetSpecialValueFor("slow")
    
    if self:GetCaster():HasScepter() then
        return math.abs(value)
    end

    return value
end

function modifier_fenrir_bite:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if caster:GetTeamNumber() ~= parent:GetTeamNumber() then
        if event.target ~= parent then return end
    else
        if event.attacker ~= parent then return end
    end

    if event.target == event.attacker then return end
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end

    local ability = self:GetAbility()
    local damage = event.damage * (ability:GetSpecialValueFor("attack_to_magic")/100)

    ApplyDamage({
        attacker = caster,
        victim = victim,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, damage, nil)
    EmitSoundOn("Hero_Ancient_Apparition.ColdFeetTick", victim)
end

function modifier_fenrir_bite:OnCreated()
    if not IsServer() then return end
end

function modifier_fenrir_bite:OnDestroy()
    if not IsServer() then return end
end