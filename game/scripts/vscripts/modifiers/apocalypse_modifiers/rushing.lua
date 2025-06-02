LinkLuaModifier("modifier_apocalypse_rushing", "modifiers/apocalypse_modifiers/rushing", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_apocalypse_rushing_buff", "modifiers/apocalypse_modifiers/rushing", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_apocalypse_rushing_cooldown", "modifiers/apocalypse_modifiers/rushing", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_max_movement_speed", "modifiers/modifier_max_movement_speed", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_rushing = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_rushing_buff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_rushing_cooldown = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_rushing = class(ItemBaseClass)

function modifier_apocalypse_rushing:GetIntrinsicModifierName()
    return "modifier_apocalypse_rushing"
end

function modifier_apocalypse_rushing:GetTexture() return "rushing" end
-------------
function modifier_apocalypse_rushing:OnCreated()
   if not IsServer() then return end

   self:StartIntervalThink(0.1)
end

function modifier_apocalypse_rushing:OnIntervalThink()
    local parent = self:GetParent()
    local target = parent:GetAggroTarget()

    if target ~= nil and target:IsAlive() then
        if (parent:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() > 825 then return end

        if not parent:HasModifier("modifier_apocalypse_rushing_buff") and not parent:HasModifier("modifier_apocalypse_rushing_cooldown") then
            parent:AddNewModifier(target, nil, "modifier_apocalypse_rushing_buff", {
                duration = 5.0
            })
        end
    end
end
----------
function modifier_apocalypse_rushing_buff:DeclareFunctions()
   return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT 
   }
end


function modifier_apocalypse_rushing_buff:CheckState()
   return {
        [MODIFIER_STATE_UNSLOWABLE] = true 
   }
end

function modifier_apocalypse_rushing_buff:GetModifierMoveSpeedBonus_Constant()
   return 800
end

function modifier_apocalypse_rushing_buff:OnRemoved()
   if not IsServer() then return end

   local parent = self:GetParent()
   
   parent:RemoveModifierByName("modifier_movement_speed_uba")
   parent:RemoveModifierByName("modifier_max_movement_speed")
end

function modifier_apocalypse_rushing_buff:OnCreated()
   if not IsServer() then return end

   EmitSoundOn("Hero_PhantomLancer.PhantomEdge", self:GetParent())

   local parent = self:GetParent()

   self.defaultSpeed = parent:GetBaseMoveSpeed()

   parent:AddNewModifier(parent, nil, "modifier_movement_speed_uba", { speed = 1000 })
   parent:AddNewModifier(parent, nil, "modifier_max_movement_speed", {})

   self:StartIntervalThink(0.1)
end

function modifier_apocalypse_rushing_buff:OnIntervalThink()
    local parent = self:GetParent()
    local target = self:GetCaster()

    if target ~= nil and target:IsAlive() then
        local distance = (parent:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
        if distance > 825 or (distance <= parent:Script_GetAttackRange()+100) then 
            if not parent:HasModifier("modifier_apocalypse_rushing_cooldown") then
                parent:AddNewModifier(parent, nil, "modifier_apocalypse_rushing_cooldown", {
                    duration = 5.0
                })
            end

            self:Destroy() 
        end
    else
        if not parent:HasModifier("modifier_apocalypse_rushing_cooldown") then
            parent:AddNewModifier(parent, nil, "modifier_apocalypse_rushing_cooldown", {
                duration = 5.0
            })
        end

        self:Destroy()
    end
end

function modifier_apocalypse_rushing_buff:GetEffectName()
    return "particles/units/heroes/hero_phantom_lancer/phantomlancer_edge_boost.vpcf"
end