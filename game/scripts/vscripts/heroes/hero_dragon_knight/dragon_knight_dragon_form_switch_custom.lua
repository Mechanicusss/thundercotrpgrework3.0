LinkLuaModifier("modifier_dragon_knight_dragon_form_switch_custom", "heroes/hero_dragon_knight/dragon_knight_dragon_form_switch_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_switch_custom_green", "heroes/hero_dragon_knight/dragon_knight_dragon_form_switch_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_switch_custom_red", "heroes/hero_dragon_knight/dragon_knight_dragon_form_switch_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_switch_custom_blue", "heroes/hero_dragon_knight/dragon_knight_dragon_form_switch_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_switch_custom_black", "heroes/hero_dragon_knight/dragon_knight_dragon_form_switch_custom", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_green_poison_debuff", "heroes/hero_dragon_knight/dragon_form/dragon_form_green", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_red_magic_debuff", "heroes/hero_dragon_knight/dragon_form/dragon_form_red", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_blue_slow_debuff", "heroes/hero_dragon_knight/dragon_form/dragon_form_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_black_armor_debuff", "heroes/hero_dragon_knight/dragon_form/dragon_form_black", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDragon = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

dragon_knight_dragon_form_switch_custom = class(ItemBaseClass)
modifier_dragon_knight_dragon_form_switch_custom = class(dragon_knight_dragon_form_switch_custom)
modifier_dragon_knight_dragon_form_switch_custom_green = class(ItemBaseClassDragon)
modifier_dragon_knight_dragon_form_switch_custom_red = class(ItemBaseClassDragon)
modifier_dragon_knight_dragon_form_switch_custom_blue = class(ItemBaseClassDragon)
modifier_dragon_knight_dragon_form_switch_custom_black = class(ItemBaseClassDragon)
-------------
function dragon_knight_dragon_form_switch_custom:GetIntrinsicModifierName()
    return "modifier_dragon_knight_dragon_form_switch_custom"
end

function dragon_knight_dragon_form_switch_custom:GetCooldown(level)
    local ab = self:GetCaster():FindAbilityByName("special_bonus_unique_dragon_knight_1_custom")
    if ab ~= nil and ab:GetLevel() > 0 then
        return self.BaseClass.GetCooldown(self, level) - ab:GetSpecialValueFor("value")
    end

    return self.BaseClass.GetCooldown(self, level) or 0
end

function dragon_knight_dragon_form_switch_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function dragon_knight_dragon_form_switch_custom:OnInventoryContentsChanged()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if not caster:HasScepter() and caster:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_black") then
        caster:RemoveModifierByName("modifier_dragon_knight_dragon_form_switch_custom_black")
        caster:AddNewModifier(caster, self, "modifier_dragon_knight_dragon_form_switch_custom_green", {})
    end
end

function dragon_knight_dragon_form_switch_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")

    local mods = {
        "modifier_dragon_knight_dragon_form_switch_custom_green",
        "modifier_dragon_knight_dragon_form_switch_custom_red",
        "modifier_dragon_knight_dragon_form_switch_custom_blue",
    }

    if caster:HasScepter() then
        table.insert(mods, "modifier_dragon_knight_dragon_form_switch_custom_black")
    end

    for i = 1, #mods, 1 do
        if caster:HasModifier(mods[i]) then
            local toAdd = mods[i+1]

            if i+1 > #mods then 
                toAdd = mods[1]
            end

            caster:RemoveModifierByName(mods[i])
            caster:AddNewModifier(caster, self, toAdd, {})

            break
        end
    end

    self.effect = ""
    
    self.isPoison = caster:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_green")
    self.isFire = caster:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_red")
    self.isIce = caster:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_blue")
    self.isBlack = caster:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_black")

    -- Green --
    if self.isPoison then
        self.effect = "particles/units/heroes/hero_brewmaster/brewmaster_void_pulse_2.vpcf"
    end

    if self.isFire then
        self.effect = "particles/units/heroes/hero_brewmaster/brewmaster_void_pulse_2_2.vpcf"
    end

    if self.isIce then
        self.effect = "particles/units/heroes/hero_brewmaster/brewmaster_void_pulse_2_2_2.vpcf"
    end

    if self.isBlack then
        self.effect = "particles/units/heroes/hero_brewmaster/brewmaster_void_pulse_2_2_2_2.vpcf"
    end

    local effect_cast = ParticleManager:CreateParticle( self.effect, PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        caster,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        caster:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, caster:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 0, Vector(radius, radius, radius) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    local ultimate = caster:FindAbilityByName("dragon_knight_dragon_form_custom")
    if ultimate == nil then return end

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        ApplyDamage({
            attacker = caster,
            victim = victim,
            damage = self:GetSpecialValueFor("damage") + (caster:GetStrength()*(self:GetSpecialValueFor("str_to_damage")/100)),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        })

        if self.isPoison then
            local debuffName = "modifier_dragon_knight_dragon_form_custom_green_poison_debuff"
            local debuff = victim:FindModifierByName(debuffName)
            if debuff == nil then
                debuff = victim:AddNewModifier(caster, ultimate, debuffName, {
                    duration = ultimate:GetSpecialValueFor("poison_drake_debuff_duration")
                })
            end

            if debuff ~= nil then
                local greenStacks = debuff:GetStackCount()+self:GetSpecialValueFor("poison_drake_stacks")
                local greenStacksMax = ultimate:GetSpecialValueFor("poison_drake_debuff_max_stacks")

                if greenStacks > greenStacksMax then
                    greenStacks = greenStacksMax
                end
                
                debuff:SetStackCount(greenStacks)
                debuff:ForceRefresh()
            end
        end

        if self.isFire then
            victim:AddNewModifier(caster, ultimate, "modifier_dragon_knight_dragon_form_custom_red_magic_debuff", {
                duration = ultimate:GetSpecialValueFor("fire_drake_debuff_duration")
            })
        end

        if self.isIce then
            victim:AddNewModifier(caster, ultimate, "modifier_dragon_knight_dragon_form_custom_blue_slow_debuff", {
                duration = ultimate:GetSpecialValueFor("ice_drake_debuff_duration")
            })
        end

        if self.isBlack then
            local debuffName = "modifier_dragon_knight_dragon_form_custom_black_armor_debuff"
            local debuff = victim:FindModifierByName(debuffName)
            if debuff == nil then
                debuff = victim:AddNewModifier(caster, ultimate, debuffName, {
                    duration = ultimate:GetSpecialValueFor("black_drake_debuff_duration")
                })
            end

            if debuff ~= nil then
                local blackStacks = debuff:GetStackCount()+self:GetSpecialValueFor("black_drake_stacks")
                local blackStacksMax = ultimate:GetSpecialValueFor("black_drake_debuff_max_stacks")
                if blackStacks > blackStacksMax then
                    blackStacks = blackStacksMax
                end
                debuff:SetStackCount(blackStacks)
                debuff:ForceRefresh()
            end
        end
    end

    EmitSoundOn("Brewmaster_Void.Pulse", caster)
end

function modifier_dragon_knight_dragon_form_switch_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:AddNewModifier(parent, ability, "modifier_dragon_knight_dragon_form_switch_custom_green", {})
end