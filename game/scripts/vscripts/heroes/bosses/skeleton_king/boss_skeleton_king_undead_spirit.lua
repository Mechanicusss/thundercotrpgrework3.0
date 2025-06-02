LinkLuaModifier("boss_skeleton_king_undead_spirit_modifier", "heroes/bosses/skeleton_king/boss_skeleton_king_undead_spirit", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

boss_skeleton_king_undead_spirit = class(BaseClass)
boss_skeleton_king_undead_spirit_modifier = class(BaseClass)

function boss_skeleton_king_undead_spirit:GetIntrinsicModifierName()
    return "boss_skeleton_king_undead_spirit_modifier"
end
----------------------------------------------------
function boss_skeleton_king_undead_spirit_modifier:IsHidden() return self:GetStackCount() < 1 end

function boss_skeleton_king_undead_spirit_modifier:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_EVENT_ON_DEATH
    }
end

function boss_skeleton_king_undead_spirit_modifier:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function boss_skeleton_king_undead_spirit_modifier:OnIntervalThink()
    self:OnRefresh()
end

function boss_skeleton_king_undead_spirit_modifier:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    local speed = ability:GetSpecialValueFor("attack_speed_bonus")
    local missing = ability:GetSpecialValueFor("missing_hp_pct")

    local bonus = ((100-parent:GetHealthPercent()) / missing) * speed

    self.attackSpeed = bonus

    self:InvokeBonus()
end

function boss_skeleton_king_undead_spirit_modifier:GetModifierAttackSpeedBonus_Constant()
    return self.fAttackSpeed
end

function boss_skeleton_king_undead_spirit_modifier:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct") * self:GetStackCount()
end

function boss_skeleton_king_undead_spirit_modifier:AddCustomTransmitterData()
    return
    {
        attackSpeed = self.fAttackSpeed,
    }
end

function boss_skeleton_king_undead_spirit_modifier:HandleCustomTransmitterData(data)
    if data.attackSpeed ~= nil then
        self.fAttackSpeed = tonumber(data.attackSpeed)
    end
end

function boss_skeleton_king_undead_spirit_modifier:InvokeBonus()
    if IsServer() == true then
        self.fAttackSpeed = self.attackSpeed

        self:SendBuffRefreshToClients()
    end
end


function boss_skeleton_king_undead_spirit_modifier:OnDeath(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end

    local vfx = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_toast.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(vfx, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfx)

    self:IncrementStackCount()

    EmitSoundOn("Hero_SkeletonKing.ArcanaProgressHud", self:GetParent())
end

function boss_skeleton_king_undead_spirit_modifier:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end

    local target = event.target
    local attacker = event.attacker
    local ability = self:GetAbility()

    ---------------------------
    local lifestealAmount = self:GetAbility():GetSpecialValueFor("base_lifesteal") + (self:GetAbility():GetSpecialValueFor("lifesteal_increase") * self:GetStackCount())

    if lifestealAmount < 1 or not attacker:IsAlive() or attacker:GetHealth() < 1 or event.target:IsOther() or event.target:IsBuilding() then
        return
    end

    local heal = event.damage * (lifestealAmount/100)

    --local heal = attacker:GetLevel() + self.lifestealAmount

    if attacker:IsIllusion() then -- Illusions only heal for 10% of the value
        heal = heal * 0.1
    end
    
    --attacker:SetHealth(attacker:GetHealth() + heal) DO NOT USE! Ignores regen reduction
    if heal < 0 or heal > INT_MAX_LIMIT then
        heal = self:GetParent():GetMaxHealth()
    end
    attacker:Heal(heal, nil)

    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
end