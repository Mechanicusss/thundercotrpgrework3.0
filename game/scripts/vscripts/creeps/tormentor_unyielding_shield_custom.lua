LinkLuaModifier("modifier_tormentor_unyielding_shield_custom", "creeps/tormentor_unyielding_shield_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tormentor_unyielding_shield_custom_pedestal_model", "creeps/tormentor_unyielding_shield_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

tormentor_unyielding_shield_custom = class(ItemBaseClass)
modifier_tormentor_unyielding_shield_custom = class(tormentor_unyielding_shield_custom)
modifier_tormentor_unyielding_shield_custom_pedestal_model = class(ItemBaseClass)
-------------
function tormentor_unyielding_shield_custom:GetIntrinsicModifierName()
    return "modifier_tormentor_unyielding_shield_custom"
end
------------
function modifier_tormentor_unyielding_shield_custom:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true
    }   

    return state
end

function modifier_tormentor_unyielding_shield_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetCaster()

    local gameTime = math.floor(GameRules:GetGameTime() / 60)

    self.maxShield = ability:GetSpecialValueFor("damage_absorb") + (gameTime * (ability:GetSpecialValueFor("damage_absorb_per_minute")))
    self.regenPerSecond = ability:GetSpecialValueFor("regen_per_second_pct")
    self.shield = self.maxShield

    self.cShield = self.shield

    self:InvokeShield()

    self.shield_pfx = ParticleManager:CreateParticle("particles/neutral_fx/miniboss_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    
    self:StartIntervalThink(0.1)

    self.pedestal_model = Entities:FindByModel(nil, "models/props_gameplay/divine_sentinel/divine_sentinel.vmdl") 
    if self.pedestal_model == nil then
        self.pedestal_model = CreateUnitByName("outpost_placeholder_unit", parent:GetAbsOrigin(), false, nil, nil, parent:GetTeam())
    end

    self.pedestal_model:RemoveNoDraw()
    self.pedestal_model:SetOriginalModel("models/props_gameplay/divine_sentinel/divine_sentinel.vmdl")
    self.pedestal_model:SetModel("models/props_gameplay/divine_sentinel/divine_sentinel.vmdl")
    self.pedestal_model:SetModelScale(0.5)
    self.pedestal_model:AddNewModifier(parent, ability, "modifier_tormentor_unyielding_shield_custom_pedestal_model", {})
end

function modifier_tormentor_unyielding_shield_custom:OnDeath(event)
    if not IsServer() then return end 

    if event.unit ~= self:GetParent() then return end

    local parent = self:GetParent()

    if self.shield_pfx ~= nil then
        ParticleManager:DestroyParticle(self.shield_pfx, true)
	    ParticleManager:ReleaseParticleIndex(self.shield_pfx)
    end

    local pfx = ParticleManager:CreateParticle("particles/neutral_fx/miniboss_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(pfx, 0, parent:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(pfx)

    local items = {
        "item_aghanims_shard",
        "item_ultimate_scepter_roshan"
    }

    DropNeutralItemAtPositionForHero(items[RandomInt(1, #items)], parent:GetAbsOrigin(), parent, 1, false)
end

function modifier_tormentor_unyielding_shield_custom:AddCustomTransmitterData()
    return
    {
        cShield = self.fcShield,
    }
end

function modifier_tormentor_unyielding_shield_custom:HandleCustomTransmitterData(data)
    if data.cShield ~= nil then
        self.fcShield = tonumber(data.cShield)
    end
end

function modifier_tormentor_unyielding_shield_custom:InvokeShield()
    if IsServer() == true then
        self.fcShield = self.cShield

        self:SendBuffRefreshToClients()
    end
end

function modifier_tormentor_unyielding_shield_custom:OnIntervalThink()
    self.shield = self.shield + ((self.maxShield * (self.regenPerSecond/100))*0.1)

    if self.shield >= self.maxShield then 
        self.shield = self.maxShield
    end 

    self.cShield = self.shield
    self:InvokeShield()
end

function modifier_tormentor_unyielding_shield_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
        MODIFIER_EVENT_ON_DEATH  
    }
end

function modifier_tormentor_unyielding_shield_custom:GetModifierIncomingDamageConstant(event)
    if not IsServer() then
        return self.fcShield
    end

    local parent = self:GetParent()

    if event.target ~= parent then print("1") return end
    if event.attacker:GetTeam() == parent:GetTeam() then print("2") return 0 end
    if self.shield <= 0 then print("3") return end

    local block = 0
    local negated = self.shield - event.damage 

    if negated <= 0 then
        block = self.shield
    else
        block = event.damage
    end

    self.shield = negated

    if self.shield <= 0 then
        self.shield = 0
        self.cShield = 0

        self:InvokeShield()
        print("4")
        return
    else
        self.cShield = self.shield
    end

    self:InvokeShield()

    return -block
end

function modifier_tormentor_unyielding_shield_custom:RemoveOnDeath() return true end
----------
function modifier_tormentor_unyielding_shield_custom_pedestal_model:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(FrameTime())
end

function modifier_tormentor_unyielding_shield_custom_pedestal_model:OnIntervalThink()
    if not self:GetCaster() or self:GetCaster():IsNull() then return end 
    if not self:GetCaster():IsAlive() then return end 

    local origin = self:GetCaster():GetAbsOrigin()
    self:GetParent():SetAbsOrigin(Vector(origin.x, origin.y, origin.z+10))
end

function modifier_tormentor_unyielding_shield_custom_pedestal_model:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true
    }   

    return state
end

function modifier_tormentor_unyielding_shield_custom_pedestal_model:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION 
    }
end

function modifier_tormentor_unyielding_shield_custom_pedestal_model:GetModifierProvidesFOWVision()
    return 1
end