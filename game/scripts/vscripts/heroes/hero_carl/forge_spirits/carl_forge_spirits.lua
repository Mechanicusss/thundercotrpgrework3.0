LinkLuaModifier("modifier_carl_forge_spirits", "heroes/hero_carl/forge_spirits/carl_forge_spirits", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_carl_forge_spirits_armor_debuff", "heroes/hero_carl/forge_spirits/carl_forge_spirits", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

carl_forge_spirits = class(ItemBaseClass)
modifier_carl_forge_spirits = class(carl_forge_spirits)
modifier_carl_forge_spirits_armor_debuff = class(ItemBaseClassDebuff)
-------------
function carl_forge_spirits:OnStolen( hAbility )
    self.orbs = hAbility.orbs
end

function carl_forge_spirits:GetOrbSpecialValueFor( key_name, orb_name )
    if not IsServer() then return 0 end
    if not self.orbs[orb_name] then return 0 end
    return self:GetLevelSpecialValueFor( key_name, self.orbs[orb_name] )
end

function carl_forge_spirits:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local casterPos = caster:GetAbsOrigin()

    -- Delete Old Golems --
    local existing = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,ex in ipairs(existing) do
        if ex:GetUnitName() == "npc_dota_carl_forged_spirit" then
            if ex:IsAlive() then
                ex:ForceKill(false)
            end
        end
    end
    --
    
    local spiritCount = self:GetOrbSpecialValueFor("spirit_count", "q")

    for i=1,spiritCount,1 do
        CreateUnitByNameAsync(
            "npc_dota_carl_forged_spirit",
            Vector(casterPos.x+RandomInt(-200, 200), casterPos.y+RandomInt(-200, 200), casterPos.z),
            true,
            caster,
            caster,
            caster:GetTeamNumber(),

            function(unit)
                unit:SetOwner(caster)
                unit:SetControllableByPlayer(caster:GetPlayerID(), false)

                unit:AddNewModifier(unit, nil, "modifier_max_movement_speed", {})
                unit:AddNewModifier(unit, self, "modifier_carl_forge_spirits", {
                    duration = self:GetOrbSpecialValueFor("spirit_duration", "q")
                })

                local spiritDamage = caster:GetAverageTrueAttackDamage(caster) * (self:GetOrbSpecialValueFor("spirit_damage", "e")/100)
                local spiritArmor = caster:GetPhysicalArmorValue(false) * (self:GetOrbSpecialValueFor("spirit_armor", "e")/100)
                local spiritHp = caster:GetMaxHealth() * (self:GetOrbSpecialValueFor("spirit_hp", "q")/100)

                unit:SetBaseAttackTime(self:GetSpecialValueFor("spirit_bat"))

                unit:SetBaseDamageMin(spiritDamage)
                unit:SetBaseDamageMax(spiritDamage)

                unit:SetPhysicalArmorBaseValue(spiritArmor)

                unit:SetBaseMaxHealth(spiritHp)
                unit:SetMaxHealth(spiritHp)
                unit:SetHealth(spiritHp)

                unit:SetBaseMoveSpeed(caster:GetIdealSpeedNoSlows())
            end
        )
    end

    EmitSoundOn("Hero_Invoker.ForgeSpirit", caster)
end
------------
function modifier_carl_forge_spirits:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= nil then
        if parent:IsAlive() then
            parent:ForceKill(false)
        end
    end
end


function modifier_carl_forge_spirits:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_carl_forge_spirits:OnAttackLanded(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()

    -------------

    local duration = self:GetAbility():GetOrbSpecialValueFor("debuff_duration", "q")

    local buff = victim:FindModifierByName("modifier_carl_forge_spirits_armor_debuff")
    if buff == nil then
        buff = victim:AddNewModifier(caster, ability, "modifier_carl_forge_spirits_armor_debuff", {
            duration = duration
        })
    end

    if buff ~= nil then
        buff:IncrementStackCount()
        buff:ForceRefresh()
    end
end

function modifier_carl_forge_spirits:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
end

function modifier_carl_forge_spirits:GetEffectName()
    return "particles/units/heroes/hero_invoker_kid/invoker_kid_forge_spirit_ambient.vpcf"
end
-----------
function modifier_carl_forge_spirits_armor_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_carl_forge_spirits_armor_debuff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.armor = self:GetAbility():GetOrbSpecialValueFor("armor_per_attack", "e")

    self:InvokeBonusDamage()
end

function modifier_carl_forge_spirits_armor_debuff:OnRefresh()
    if not IsServer() then return end

    self.armor = self:GetAbility():GetOrbSpecialValueFor("armor_per_attack", "e")

    self:InvokeBonusDamage()
end

function modifier_carl_forge_spirits_armor_debuff:GetModifierPhysicalArmorBonus()
    return self.fArmor * self:GetStackCount()
end

function modifier_carl_forge_spirits_armor_debuff:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
    }
end

function modifier_carl_forge_spirits_armor_debuff:HandleCustomTransmitterData(data)
    if data.armor ~= nil then
        self.fArmor = tonumber(data.armor)
    end
end

function modifier_carl_forge_spirits_armor_debuff:InvokeBonusDamage()
    if IsServer() == true then
        self.fArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end