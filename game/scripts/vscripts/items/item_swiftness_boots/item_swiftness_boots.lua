LinkLuaModifier("modifier_swiftness_boots", "items/item_swiftness_boots/item_swiftness_boots", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_swiftness_boots_teleporting", "items/item_swiftness_boots/item_swiftness_boots", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseBuffClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseStackDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return true end,
}

item_swiftness_boots = class(ItemBaseClass)
item_swiftness_boots_2 = item_swiftness_boots
item_swiftness_boots_3 = item_swiftness_boots
modifier_swiftness_boots = class(item_swiftness_boots)
modifier_swiftness_boots_teleporting = class(ItemBaseBuffClass)
-------------
function item_swiftness_boots:GetIntrinsicModifierName()
    return "modifier_swiftness_boots"
end

function item_swiftness_boots:CastFilterResultTarget(target)
    local caster = self:GetCaster()

    if not target or target:IsNull() then
        return UF_FAIL_CUSTOM
    end

    local nResult = UnitFilter(
        target,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BUILDING,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        caster:GetTeamNumber()
    )

    if nResult ~= UF_SUCCESS then
        return nResult
    end

    if target ~= nil and not target:IsNull() and not target:IsBuilding() and target.IsBaseNPC then
        if not target:IsAlive() or not caster:IsAlive() or target:IsCourier() then
            return UF_FAIL_CUSTOM
        end
    end

    return UF_SUCCESS
end

function item_swiftness_boots:GetCustomCastErrorTarget(target)
    return "#dota_hud_error_invalid_target"
end

function item_swiftness_boots:OnSpellStart()
    if not IsServer() then return end

    self.target = self:GetCursorTarget()
    local point = self:GetCursorPosition()
    local caster = self:GetCaster()

    if self.target == nil then
        local allies = FindUnitsInRadius(caster:GetTeam(), point, nil,
            900, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BUILDING), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)
        
        if #allies > 0 then
            for _,ally in ipairs(allies) do
                self.target = ally
                break
            end
        else
            self.target = caster
        end
    end

    if self.target == caster then
        local startZone = Entities:FindByName(nil, "starting_zone_emitter")
        if startZone then
            self.target = startZone
        end
    end

    self.loc = self.target:GetAbsOrigin()

    self.particle = ParticleManager:CreateParticle("particles/items2_fx/teleport_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    self.particle_destination = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target)
    
    ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle_destination, 0, self.target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.particle_destination, 1, self.target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.target:GetAbsOrigin(), true)

    self:UseResources(false, false, false, true)

    EmitSoundOn("Portal.Loop_Appear", caster)
    EmitSoundOn("Portal.Loop_Appear", self.target)

    caster:AddNewModifier(caster, self, "modifier_swiftness_boots_teleporting", {
        duration = self:GetChannelTime()
    })

    self.idFow = AddFOWViewer(DOTA_TEAM_GOODGUYS, self.loc, 300, self:GetChannelTime(), false)
end

function item_swiftness_boots:OnChannelThink(fInterval)
    if not IsServer() then return end

    if self.target ~= nil and not self.target:IsNull() then
        self.loc = self.target:GetAbsOrigin()
    end
end

function item_swiftness_boots:OnChannelFinish(interrupted)
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_swiftness_boots_teleporting")

    if self.idFow ~= nil then
        RemoveFOWViewer(DOTA_TEAM_GOODGUYS, self.idFow)
    end

    if not self.target or self.target:IsNull() then return end

    if self.target == caster then
        local startZone = Entities:FindByName(nil, "starting_zone_emitter")
        if startZone then
            self.target = startZone
        end
    end

    caster:StopSound("Portal.Loop_Appear")
    self.target:StopSound("Portal.Loop_Appear")

    if not interrupted and self.target:IsAlive() and caster:IsAlive() then
        FindClearSpaceForUnit(caster, self.loc, true)
        EmitSoundOn("Portal.Hero_Disappear", caster)
        EmitSoundOn("Portal.Hero_Appear", self.target)

        self.particle_end = ParticleManager:CreateParticle("particles/items2_fx/teleport_end_dust.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target)
        ParticleManager:SetParticleControlEnt(self.particle_end, 0, self.target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.target:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(self.particle_end)
    end

    if self.particle then
        ParticleManager:DestroyParticle(self.particle, false)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end

    if self.particle_destination then
        ParticleManager:DestroyParticle(self.particle_destination, false)
        ParticleManager:ReleaseParticleIndex(self.particle_destination)
    end
end
------------
function modifier_swiftness_boots:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Percentage
    }

    return funcs
end

function modifier_swiftness_boots:OnCreated()
    if not IsServer() then return end

    if ability and not ability:IsNull() then
        self.speed_pct = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
    end

    self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_movement_speed_uba", { speed = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1)) })
end

function modifier_swiftness_boots:OnRemoved()
    if not IsServer() then return end

    self:GetParent():RemoveModifierByName("modifier_movement_speed_uba")
end


function modifier_swiftness_boots:GetModifierMoveSpeedBonus_Constant()
    return self.speed_pct or self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end