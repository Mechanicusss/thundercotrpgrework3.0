modifier_walking_animation_fix = class({})

function modifier_walking_animation_fix:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS 
    }

    return funcs
end

function modifier_walking_animation_fix:GetActivityTranslationModifiers()
    return "run"
end

function modifier_walking_animation_fix:IsHidden() return true end
function modifier_walking_animation_fix:IsDebuff() return false end
function modifier_walking_animation_fix:RemoveOnDeath() return false end
function modifier_walking_animation_fix:IsPurgable() return false end
function modifier_walking_animation_fix:IsPurgeException() return false end