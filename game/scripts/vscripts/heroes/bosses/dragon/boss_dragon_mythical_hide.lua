LinkLuaModifier("modifier_boss_dragon_mythical_hide", "heroes/bosses/dragon/boss_dragon_mythical_hide", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_dragon_mythical_hide_buff", "heroes/bosses/dragon/boss_dragon_mythical_hide", LUA_MODIFIER_MOTION_NONE)

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

boss_dragon_mythical_hide = class(ItemBaseClass)
modifier_boss_dragon_mythical_hide = class(boss_dragon_mythical_hide)
modifier_boss_dragon_mythical_hide_buff = class(ItemBaseClassBuff)
-------------
function boss_dragon_mythical_hide:GetIntrinsicModifierName()
    return "modifier_boss_dragon_mythical_hide"
end
-------------
function modifier_boss_dragon_mythical_hide:OnCreated()
    if not IsServer() then return end 

    self.ability = self:GetAbility()

    self.damageCount = 0

    self.pctDivider = self.ability:GetSpecialValueFor("pct_hp_to_damage")
    self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_boss_dragon_mythical_hide:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_boss_dragon_mythical_hide:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    EmitSoundOn("Hero_DragonKnight.ElderDragonShoot1.Attack", parent)
end

function modifier_boss_dragon_mythical_hide:GetModifierIncomingDamage_Percentage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    local target = event.target 
    local attacker = event.attacker

    if target ~= parent or attacker:GetTeam() ~= DOTA_TEAM_GOODGUYS then return end 
    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end

    self.damageCount = self.damageCount + event.damage

    if self.damageCount >= (parent:GetMaxHealth() * (self.pctDivider/100)) then
        local pctOfMaxHpTakenAsDamage = ((self.damageCount / parent:GetMaxHealth()) * 100) / self.pctDivider

        local buff = parent:FindModifierByName("modifier_boss_dragon_mythical_hide_buff")
        if not buff then
            buff = parent:AddNewModifier(parent, self.ability, "modifier_boss_dragon_mythical_hide_buff", { duration = self.duration })
        end

        if buff then
            buff:ForceRefresh()
            buff:SetStackCount(buff:GetStackCount()+math.floor(pctOfMaxHpTakenAsDamage))
        end

        self.damageCount = 0
    end
end
----------
function modifier_boss_dragon_mythical_hide_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_boss_dragon_mythical_hide_buff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct") * self:GetStackCount()
end