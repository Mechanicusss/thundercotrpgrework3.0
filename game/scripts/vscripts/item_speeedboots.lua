item_speeedboots=class({})

LinkLuaModifier("modifier_item_speeedboots", "item_speeedboots", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_speeedboots_buff", "item_speeedboots", LUA_MODIFIER_MOTION_NONE)

function item_speeedboots:GetIntrinsicModifierName() 
    return "modifier_item_speeedboots" 
end

function item_speeedboots:OnSpellStart()
    local caster = self:GetCaster()
    local dur = self:GetSpecialValueFor("dur")
    caster:EmitSound( "DOTA_Item.PhaseBoots.Activate" ) 
    caster:AddNewModifier( caster, self, "modifier_item_speeedboots_buff", {duration=dur} )
    -- remove debuff
    caster:Purge(false, true, false, false, false)
end

modifier_item_speeedboots=class({})

function modifier_item_speeedboots:IsBuff()             
    return true 
end

function modifier_item_speeedboots:IsDebuff()             
    return false
end

function modifier_item_speeedboots:IsHidden()           
    return true 
end

function modifier_item_speeedboots:IsPurgable()         
    return false
end

function modifier_item_speeedboots:IsPurgeException() 
    return false 
end

function modifier_item_speeedboots:RemoveOnDeath()  
    return self:GetParent():IsIllusion()
end

function modifier_item_speeedboots:IsPassive()  
    return true 
end


function modifier_item_speeedboots:DeclareFunctions() 
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, 
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, 
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, 
    } 
end

function modifier_item_speeedboots:OnCreated()
    if self:GetAbility() == nil then
        return
    end
    self.SpeedBonus=self:GetAbility():GetSpecialValueFor("SpeedBonus")
    self.Damage=self:GetAbility():GetSpecialValueFor("Damage")
    self.Armor=self:GetAbility():GetSpecialValueFor("Armor")
end

function modifier_item_speeedboots:GetModifierMoveSpeedBonus_Constant() 
    return  self.SpeedBonus 
end

function modifier_item_speeedboots:GetModifierPreAttack_BonusDamage() 
    return self.Damage
end

function modifier_item_speeedboots:GetModifierPhysicalArmorBonus() 
    return  self.Armor
end

modifier_item_speeedboots_buff=class({})


function modifier_item_speeedboots_buff:IsHidden()          
    return false 
end

function modifier_item_speeedboots_buff:IsPurgable()        
    return true
end

function modifier_item_speeedboots_buff:IsPurgeException() 
    return true 
end

function modifier_item_speeedboots_buff:GetTexture()
    return "item_speeedboots" 
end


function modifier_item_speeedboots_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW 
end

function modifier_item_speeedboots_buff:GetEffectName()
    return "particles/econ/events/ti10/phase_boots_ti10.vpcf" 
end

function modifier_item_speeedboots_buff:CheckState() 
    return 
    {
        [MODIFIER_STATE_FLYING] = true, 
    } 
end


function modifier_item_speeedboots_buff:DeclareFunctions() 
    return 
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
    } 
end

function modifier_item_speeedboots_buff:OnCreated()
    if self:GetAbility() == nil then
        return
    end
    self.active_perc_speed=self:GetAbility():GetSpecialValueFor("active_perc_speed")
end

function modifier_item_speeedboots_buff:GetModifierMoveSpeedBonus_Percentage() 
        return self.active_perc_speed
end

function modifier_item_speeedboots_buff:GetModifierIgnoreMovespeedLimit()
    return 1
end
