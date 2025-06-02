modifier_aghanim_portal = class({})

function modifier_aghanim_portal:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:AddNoDraw()

    local model = "models/props_gameplay/temple_portal001.vmdl"

    parent:SetOriginalModel(model)
    parent:SetModel(model)

    local currentAngles = parent:GetAngles()
    local newAngles = QAngle(currentAngles.x, currentAngles.y, currentAngles.z)

    -- Set the new rotation angle for the entity
    parent:SetAngles(newAngles.x, newAngles.y, newAngles.z)
    
    self:StartIntervalThink(0.1)
end

function modifier_aghanim_portal:OnIntervalThink()
    local parent = self:GetParent()

    if _G.AghanimTowers[1] and _G.AghanimTowers[2] and _G.AghanimTowers[3] and _G.AghanimTowers[4] and _G.AghanimTowers[5] then
        parent:RemoveNoDraw()
        self:StartIntervalThink(-1)
    end
end

function modifier_aghanim_portal:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE 
    }
end

function modifier_aghanim_portal:GetModifierModelChange()
    return "models/props_gameplay/temple_portal001.vmdl"
end

function modifier_aghanim_portal:CheckState()
    return {
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_CANNOT_TARGET_ENEMIES] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_PROVIDES_VISION] = false,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end
