LinkLuaModifier("modifier_keymaster_borrowed_time", "heroes/bosses/keymaster/keymaster_borrowed_time", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_keymaster_borrowed_time_buff", "heroes/bosses/keymaster/keymaster_borrowed_time", LUA_MODIFIER_MOTION_NONE)

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

keymaster_borrowed_time = class(ItemBaseClass)
modifier_keymaster_borrowed_time = class(keymaster_borrowed_time)
modifier_keymaster_borrowed_time_buff = class(ItemBaseClassBuff)
-------------
function keymaster_borrowed_time:GetIntrinsicModifierName()
    return "modifier_keymaster_borrowed_time"
end

function modifier_keymaster_borrowed_time:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MIN_HEALTH 
    }
end

function modifier_keymaster_borrowed_time:OnCreated()
    if not IsServer() then return end 

    self:OnIntervalThink()
    self:StartIntervalThink(FrameTime())
end

function modifier_keymaster_borrowed_time:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local threshold = ability:GetSpecialValueFor("hp_threshold_pct")

    if not ability:IsCooldownReady() then return end 
    if parent:HasModifier("modifier_keymaster_borrowed_time_buff") then return end 

    if parent:GetHealthPercent() <= threshold then
        EmitSoundOn("Hero_Abaddon.BorrowedTime", parent)
        parent:AddNewModifier(parent, ability, "modifier_keymaster_borrowed_time_buff", {
            duration = ability:GetSpecialValueFor("duration")
        })
        ability:UseResources(false,false,false,true)
    end
end

function modifier_keymaster_borrowed_time:GetMinHealth()
    if not IsServer() then return end 

    if self:GetAbility():IsCooldownReady() then return 1 end
end
----------------
function modifier_keymaster_borrowed_time_buff:GetEffectName()
    return "particles/units/heroes/hero_abaddon/abaddon_borrowed_time.vpcf"
end

function modifier_keymaster_borrowed_time_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_keymaster_borrowed_time_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MIN_HEALTH,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE 
    }
end

function modifier_keymaster_borrowed_time_buff:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_keymaster_borrowed_time_buff:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_keymaster_borrowed_time_buff:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_keymaster_borrowed_time_buff:GetMinHealth()
    return 1
end

function modifier_keymaster_borrowed_time_buff:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit or parent == event.attacker then return end

    parent:Heal(event.original_damage, self:GetAbility())
end