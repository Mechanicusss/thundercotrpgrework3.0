LinkLuaModifier("modifier_weaver_time_lapse_custom", "heroes/hero_weaver/weaver_time_lapse_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

weaver_time_lapse_custom = class(ItemBaseClass)
modifier_weaver_time_lapse_custom = class(weaver_time_lapse_custom)
-------------
function weaver_time_lapse_custom:GetIntrinsicModifierName()
    return "modifier_weaver_time_lapse_custom"
end
-------------
function modifier_weaver_time_lapse_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MIN_HEALTH 
    }
end

function modifier_weaver_time_lapse_custom:GetMinHealth()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()
    
    if not parent:IsIllusion() and self.preventDeath and self.check then
        if parent:GetHealth() <= 1 then
            local particlePath = "particles/units/heroes/hero_weaver/weaver_timelapse.vpcf"
    
            self.effect = ParticleManager:CreateParticle(particlePath, PATTACH_ABSORIGIN, parent)
            ParticleManager:SetParticleControl(self.effect, 2, parent:GetOrigin())
            ParticleManager:ReleaseParticleIndex(self.effect)
    
            ProjectileManager:ProjectileDodge(parent)
            parent:Purge(false, true, false, true, true)
    
            EmitSoundOn("Hero_Weaver.TimeLapse", parent)

            self.check = false
    
            self.preventDeath = false 
            
            local deathCooldown = ability:GetSpecialValueFor("death_cooldown")

            ability:StartCooldown(deathCooldown)

            -- Failsafe because otherwise this will crash since we change hp too soon and it causes an infinite loop
            Timers:CreateTimer(0.1, function()
                parent:SetHealth(parent:GetMaxHealth())
                self.check = true
            end)
        end

        return 1
    end
end

function modifier_weaver_time_lapse_custom:OnCreated()
    self.preventDeath = true 

    self.check = true

    if not IsServer() then return end 

    self:StartIntervalThink(FrameTime())
end

function modifier_weaver_time_lapse_custom:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    if not self.preventDeath and parent:GetHealth() > 1 then
        self.preventDeath = true
    end
    
    local reduction = ability:GetSpecialValueFor("cooldown_reduction")

    for i=0, parent:GetAbilityCount()-1 do
        local abil = parent:GetAbilityByIndex(i)
        if abil ~= nil and abil ~= ability then
            local timeRemaining = abil:GetCooldownTimeRemaining()

            if timeRemaining > 0 then
                local cooldown = timeRemaining - reduction

                if cooldown < 0.1 then
                    cooldown = 0.1
                end
                
                abil:EndCooldown()

                abil:StartCooldown(cooldown)
            end
        end
    end

    ability:UseResources(false, false, false, true)
end