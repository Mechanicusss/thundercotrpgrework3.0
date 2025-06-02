-- Credits goes to the Dota IMBA team https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/abilities/heroes/hero_tiny
LinkLuaModifier("modifier_tiny_grow_custom", "heroes/hero_tiny/tiny_grow_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

tiny_grow_custom = class(ItemBaseClass)
modifier_tiny_grow_custom = class(tiny_grow_custom)
-------------
function tiny_grow_custom:GetIntrinsicModifierName()
    return "modifier_tiny_grow_custom"
end

function tiny_grow_custom:OnOwnerSpawned()
    self:SetupModel(self:GetLevel())
end

function tiny_grow_custom:OnUpgrade()
    if not IsServer() then return end

    local reapply_craggy = false 

    local level = self:GetLevel()

    self:SetupModel(level)

    -- Effects
    self:GetCaster():StartGesture(ACT_TINY_GROWL)
    EmitSoundOn("Tiny.Grow", self:GetCaster())

    local caster = self:GetCaster()

    local transformPfxName = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_transform.vpcf"

    local grow = ParticleManager:CreateParticle(transformPfxName, PATTACH_POINT_FOLLOW, self:GetCaster()) 
    ParticleManager:SetParticleControl(grow, 0, self:GetCaster():GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(grow)

    if self.ambient_pfx then
        ParticleManager:DestroyParticle(self.ambient_pfx, true)
        ParticleManager:ReleaseParticleIndex(self.ambient_pfx)
    end

    local pfx_name = string.gsub("particles/units/heroes/hero_tiny/tiny_ambient.vpcf", "lvl1", "lvl"..level)

    self.ambient_pfx = ParticleManager:CreateParticle(pfx_name, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster()) 
end

function tiny_grow_custom:SetupModel(level)
    local caster = self:GetCaster()

    local model_path = "models/heroes/tiny_0"..level.."/tiny_0"..level

    if level < 5 then -- model bullshit
        self:GetCaster():SetOriginalModel("models/items/tiny/tiny_prestige/tiny_prestige_lvl_0"..level..".vmdl")
        self:GetCaster():SetModel("models/items/tiny/tiny_prestige/tiny_prestige_lvl_0"..level..".vmdl")
        
        --[[if 1 == 1 then
            self:GetCaster():SetOriginalModel("models/items/tiny/tiny_prestige/tiny_prestige_lvl_0"..level..".vmdl")
            self:GetCaster():SetModel("models/items/tiny/tiny_prestige/tiny_prestige_lvl_0"..level..".vmdl")
        else
            -- Set new model
            self:GetCaster():SetOriginalModel(model_path..".vmdl")
            self:GetCaster():SetModel(model_path..".vmdl")
            -- Remove old wearables
            UTIL_Remove(self.head)
            UTIL_Remove(self.rarm)
            UTIL_Remove(self.larm)
            UTIL_Remove(self.body)
            -- Set new wearables
            self.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = model_path.."_head.vmdl"})
            self.rarm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = model_path.."_right_arm.vmdl"})
            self.larm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = model_path.."_left_arm.vmdl"})
            self.body = SpawnEntityFromTableSynchronous("prop_dynamic", {model = model_path.."_body.vmdl"})
            -- lock to bone
            self.head:FollowEntity(self:GetCaster(), true)
            self.rarm:FollowEntity(self:GetCaster(), true)
            self.larm:FollowEntity(self:GetCaster(), true)
            self.body:FollowEntity(self:GetCaster(), true)
        end--]]
    end
end
-------------
function modifier_tiny_grow_custom:DeclareFunctions()
    return {
        --MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_tiny_grow_custom:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end

    local name = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_lvl"..self:GetAbility():GetLevel().."_death.vpcf"
    local death = ParticleManager:CreateParticle(name, PATTACH_POINT_FOLLOW, parent) 
    ParticleManager:SetParticleControl(death, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(death)
end

function modifier_tiny_grow_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    EmitSoundOn("Tiny.Grow", parent)
end

function modifier_tiny_grow_custom:GetModifierModelChange()
    local ability = self:GetAbility()
    return "models/heroes/tiny/tiny_0"..ability:GetLevel().."/tiny_0"..ability:GetLevel()..".vmdl"
end

function modifier_tiny_grow_custom:GetModifierPreAttack_BonusDamage()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    return parent:GetStrength() * (ability:GetSpecialValueFor("damage_from_strength")/100)
end

function modifier_tiny_grow_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed_penalty")
end

function modifier_tiny_grow_custom:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("attack_speed_penalty")
end

function modifier_tiny_grow_custom:GetModifierModelScale()
    return self:GetAbility():GetSpecialValueFor("model_scale")
end