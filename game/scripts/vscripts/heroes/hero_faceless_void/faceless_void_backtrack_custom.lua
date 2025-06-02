LinkLuaModifier("modifier_faceless_void_backtrack_custom", "heroes/hero_faceless_void/faceless_void_backtrack_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_faceless_void_backtrack_custom_buff", "heroes/hero_faceless_void/faceless_void_backtrack_custom", LUA_MODIFIER_MOTION_NONE)

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

faceless_void_backtrack_custom = class(ItemBaseClass)
modifier_faceless_void_backtrack_custom = class(faceless_void_backtrack_custom)
modifier_faceless_void_backtrack_custom_buff = class(ItemBaseClassBuff)
-------------
function faceless_void_backtrack_custom:GetIntrinsicModifierName()
    return "modifier_faceless_void_backtrack_custom"
end
------------
function modifier_faceless_void_backtrack_custom:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
end

function modifier_faceless_void_backtrack_custom:GetModifierIncomingDamage_Percentage()
    local parent = self:GetCaster()
	
    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")

    if parent:HasModifier("modifier_faceless_void_chronosphere_custom_debuff") then
        chance = 100
    end

	if RollPercentage(chance) then
        local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_faceless_void/faceless_void_backtrack.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        
        ParticleManager:SetParticleControl(vfx, 0, parent:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(vfx)

        if ability:IsCooldownReady() then
            parent:Heal(parent:GetMaxHealthTCOTRPG()*(ability:GetSpecialValueFor("max_health_heal")/100), ability)
            ability:UseResources(false, false, false, true)
        end

        if parent:HasShard() then
            parent:RemoveModifierByName("modifier_faceless_void_backtrack_custom_buff")

            parent:AddNewModifier(parent, ability, "modifier_faceless_void_backtrack_custom_buff", {
                duration = ability:GetSpecialValueFor("shard_agility_duration")
            })
        end

        return -100
    end
end
----------
function modifier_faceless_void_backtrack_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
    }
end

function modifier_faceless_void_backtrack_custom_buff:OnCreated()
    self.agility = self:GetParent():GetBaseAgility() * (self:GetAbility():GetSpecialValueFor("shard_agility_pct")/100)
end

function modifier_faceless_void_backtrack_custom_buff:GetModifierBonusStats_Agility()
    if not IsServer() then return end 
    
    return self.agility
end