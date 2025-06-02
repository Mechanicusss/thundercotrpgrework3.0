LinkLuaModifier("modifier_trigger_lava", "lava", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsDebuff = function(self) return true end,
}

trigger_lava = class(BaseClass)
modifier_trigger_lava = class(trigger_lava)

function trigger_lava:GetIntrinsicModifierName()
    return "modifier_trigger_lava"
end

function OnStartTouch(ent)
    local player = ent.activator
    if player == nil or player:IsNull() then return end
    if not player:IsRealHero() then return end

    if IsCreepTCOTRPG(player) or IsBossTCOTRPG(player) then return end

    if not player:HasModifier("modifier_trigger_lava") then
        player:AddNewModifier(player, nil, "modifier_trigger_lava", {})
    end
end

function OnEndTouch(ent)
    local player = ent.activator
    if player == nil then return end
    if not player:IsRealHero() then return end

    if IsCreepTCOTRPG(player) or IsBossTCOTRPG(player) then return end

    if player:HasModifier("modifier_trigger_lava") then
        player:RemoveModifierByName("modifier_trigger_lava")
    end
end
------------
function modifier_trigger_lava:DeclareFunctions()
     return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_DISABLE_HEALING 

     }
end

function modifier_trigger_lava:GetTexture()
     return "critd"
end

function modifier_trigger_lava:OnCreated()
     if not IsServer() then return end

     self:StartIntervalThink(0.1)
end

function modifier_trigger_lava:OnIntervalThink()
    local player = self:GetParent()

    if player:IsMagicImmune() or player:IsInvulnerable() then return end
    if player:HasModifier("modifier_item_apotheosis_blade") then return end
    if player:GetUnitName() == "npc_dota_necronomicon_archer_custom" then return end

     ApplyDamage({
        attacker = player,
        victim = player,
        damage = player:GetMaxHealthTCOTRPG() * 0.14 * 0.1,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
     })
end

function modifier_trigger_lava:GetModifierMoveSpeedBonus_Percentage()
    local player = self:GetParent()

    if player:IsMagicImmune() or player:IsInvulnerable() then return end
    if player:HasModifier("modifier_item_apotheosis_blade") then return end
    if player:GetUnitName() == "npc_dota_necronomicon_archer_custom" then return end
    
    return -70
end

function modifier_trigger_lava:GetDisableHealing()
    local player = self:GetParent()

    if player:IsMagicImmune() or player:IsInvulnerable() then return 0 end
    if player:HasModifier("modifier_item_apotheosis_blade") then return end
    if player:GetUnitName() == "npc_dota_necronomicon_archer_custom" then return end

    return 1
end

function modifier_trigger_lava:GetEffectName()
    if self:GetParent():HasModifier("modifier_item_apotheosis_blade") then return end
    if self:GetParent():GetUnitName() == "npc_dota_necronomicon_archer_custom" then return end
    if not self:GetParent():IsMagicImmune() then
     return "particles/econ/items/huskar/huskar_2021_immortal/huskar_2021_immortal_burning_spear_debuff.vpcf"
    end
end