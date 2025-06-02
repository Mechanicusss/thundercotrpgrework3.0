LinkLuaModifier("modifier_aghanim_crystal_activator", "modifiers/modifier_aghanim_crystal_activator.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
}

spawn_healing = class(ItemBaseClass)
modifier_aghanim_crystal_activator = class(spawn_healing)
-----------------
function spawn_healing:GetIntrinsicModifierName()
    return "modifier_aghanim_crystal_activator"
end

function modifier_aghanim_crystal_activator:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_ATTACKED,
        MODIFIER_EVENT_ON_DEATH,
    }
end

function modifier_aghanim_crystal_activator:GetAbsoluteNoDamagePhysical( params )
    return 1
end

function modifier_aghanim_crystal_activator:GetAbsoluteNoDamageMagical( params )
    return 1
end

function modifier_aghanim_crystal_activator:GetAbsoluteNoDamagePure( params )
    return 1
end

function modifier_aghanim_crystal_activator:OnAttacked( params )
    if IsServer() then
        if self:GetParent() == params.target then
            local nDamage = 0
            if params.attacker then
                local bDeathWard = params.attacker:FindModifierByName( "modifier_aghsfort_witch_doctor_death_ward" ) ~= nil
                local bValidAttacker = params.attacker:IsRealHero() or bDeathWard
                if not bValidAttacker then
                    return 0
                end
            
                nDamage = 1

                self:GetParent():ModifyHealth( self:GetParent():GetHealth() - nDamage, nil, true, 0 )

                EmitSoundOn( "Hero_Wisp.Spirits.Target", self:GetParent() )

                local nFXIndex = ParticleManager:CreateParticle( "particles/creatures/aghanim/aghanim_crystal_impact.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent() )
                ParticleManager:SetParticleControlEnt( nFXIndex, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), false )
                ParticleManager:ReleaseParticleIndex( nFXIndex )
            end
        end
    end

    return 0
end

function modifier_aghanim_crystal_activator:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_FLYING] = true,
    }   

    return state
end

function modifier_aghanim_crystal_activator:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local victim = event.unit
    local attacker = event.attacker

    if victim ~= parent then return end

    if _G.AghanimCrystalCount < _G.AghanimCrystalCountMax then
        _G.AghanimCrystalCount = _G.AghanimCrystalCount + 1
        GameRules:SendCustomMessage("<font color='blue'>A crystal has been destroyed and something slowly awakens...</font>", 0, 0)
    end

    if _G.AghanimCrystalCount == _G.AghanimCrystalCountMax then
        local spawn = Entities:FindByName(nil, "spawn_boss_aghanim")
        if not spawn or spawn == nil then return end

        CreateUnitByNameAsync("npc_dota_boss_aghanim", spawn:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            unit:AddNewModifier(unit, nil, "modifier_unit_boss_2", {})
        end)

        GameRules:SendCustomMessage("<font color='blue'>Aghanim has awoken to challenge you!</font>", 0, 0)
    end

    EmitSoundOn( "Hero_Wisp.Spirits.Destroy", self:GetParent() )
end