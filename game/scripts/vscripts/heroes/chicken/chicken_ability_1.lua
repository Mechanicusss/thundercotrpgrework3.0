LinkLuaModifier("modifier_chicken_ability_1", "heroes/chicken/chicken_ability_1.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chicken_ability_1_self_transmute", "heroes/chicken/chicken_ability_1.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chicken_ability_1_target_transmute", "heroes/chicken/chicken_ability_1.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassSelfTransmute = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

chicken_ability_1 = class(ItemBaseClass)
chicken_ability_1_cancel = class(ItemBaseClass)
modifier_chicken_ability_1 = class(chicken_ability_1)
modifier_chicken_ability_1_self_transmute = class(ItemBaseClassSelfTransmute)
modifier_chicken_ability_1_target_transmute = class(ItemBaseClassSelfTransmute)
-------------
function modifier_chicken_ability_1:CheckState()
    local state = {
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_DISARMED] = true,
    }

    if _G.FinalGameWavesEnabled and not self:GetCaster():HasModifier("modifier_chicken_ability_1_self_transmute") then
        state = {
            [MODIFIER_STATE_DISARMED] = true,
        }
    end

    return state
end

function modifier_chicken_ability_1:GetEffectName()
    return "particles/econ/courier/courier_cluckles/courier_cluckles_ambient_flying.vpcf"
end

function modifier_chicken_ability_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_chicken_ability_1:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end 

    if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then return -9999 end
end

function modifier_chicken_ability_1:GetAbsoluteNoDamagePhysical(event)
    if event.attacker == self:GetParent() and event.inflictor ~= nil then return end
    if _G.FinalGameWavesEnabled and not self:GetParent():HasModifier("modifier_chicken_ability_1_self_transmute") then return 0 end
    return 1
end

function modifier_chicken_ability_1:GetAbsoluteNoDamageMagical(event)
    if event.attacker == self:GetParent() and event.inflictor ~= nil then return end
    if _G.FinalGameWavesEnabled and not self:GetParent():HasModifier("modifier_chicken_ability_1_self_transmute") then return 0 end
    return 1
end

function modifier_chicken_ability_1:GetAbsoluteNoDamagePure(event)
    if event.attacker == self:GetParent() and event.inflictor ~= nil then return end
    if _G.FinalGameWavesEnabled and not self:GetParent():HasModifier("modifier_chicken_ability_1_self_transmute") then return 0 end
    return 1
end
-------------
function chicken_ability_1_cancel:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local frenzy = caster:FindAbilityByName("chicken_ability_2")
    if frenzy ~= nil and frenzy:GetLevel() > 0 then
        if frenzy:GetToggleState() then
            frenzy:ToggleAbility()
        end
        
        frenzy:SetActivated(false)
    end

    caster:RemoveModifierByName("modifier_chicken_ability_1_self_transmute")
end

function chicken_ability_1:GetIntrinsicModifierName()
    return "modifier_chicken_ability_1"
end

function chicken_ability_1:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target or target == nil then return end
    if target == caster then return end
    if not target:IsAlive() or target:IsIllusion() or target:IsTempestDouble() then return end
    if not target:IsRealHero() then
        if not target:IsConsideredHero() or target:GetUnitName() ~= "npc_dota_necronomicon_archer_custom" then
            return
        end
    end

    if target:IsRealHero() then
        if PlayerResource:IsDisableHelpSetForPlayerID(target:GetPlayerID(), caster:GetPlayerID()) then return end
    end

    caster:AddNewModifier(target, self, "modifier_chicken_ability_1_self_transmute", {})
    target:AddNewModifier(caster, self, "modifier_chicken_ability_1_target_transmute", {})
end
-----------
function modifier_chicken_ability_1_self_transmute:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_MODEL_CHANGE 
    }

    return funcs
end

function modifier_chicken_ability_1_self_transmute:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW 
end

function modifier_chicken_ability_1_self_transmute:GetEffectName()
    return "particles/units/heroes/hero_omniknight/omniknight_shard_hammer_of_purity_overhead_debuff.vpcf"
end

function modifier_chicken_ability_1_self_transmute:GetModifierModelChange()
    --return "models/heroes/monkey_king/transform_invisiblebox.vmdl"
end

function modifier_chicken_ability_1_self_transmute:OnCreated(params)
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.target = self:GetCaster() -- The target he's inside of

    self.parent:SetAbsOrigin(Vector(self.target:GetAbsOrigin().x, self.target:GetAbsOrigin().y, self.target:GetAbsOrigin().z+300))
    self.parent:SetForwardVector(self.target:GetForwardVector())

    self.chickenification = self.parent:FindAbilityByName("chicken_ability_1")
    self.chickenificationLevel = params.chickenificationLevel

    local cancel = self.parent:AddAbility("chicken_ability_1_cancel")

    self.parent:SwapAbilities(
        "chicken_ability_1",
        "chicken_ability_1_cancel",
        false,
        true
    )

    cancel:SetHidden(false)
    cancel:SetLevel(1)

    local frenzy = self.parent:FindAbilityByName("chicken_ability_2")
    if frenzy ~= nil and frenzy:GetLevel() > 0 then
        frenzy:SetActivated(true)
    end

    self:StartIntervalThink(0.03)
end

function modifier_chicken_ability_1_self_transmute:OnIntervalThink()
    self:GetParent():SetAbsOrigin(Vector(self.target:GetAbsOrigin().x, self.target:GetAbsOrigin().y, self.target:GetAbsOrigin().z+300))
    self.parent:SetForwardVector(self.target:GetForwardVector())
end

function modifier_chicken_ability_1_self_transmute:OnDestroy()
    if not IsServer() then return end

    if not self.target or self.target:IsNull() then return end

    self.target:RemoveModifierByNameAndCaster("modifier_chicken_ability_1_target_transmute", self.parent)

    local cancel = self.parent:FindAbilityByName("chicken_ability_1_cancel")
    if cancel == nil then return end

    cancel:SetLevel(0)
    cancel:SetHidden(true)

    self.parent:SwapAbilities(
        "chicken_ability_1",
        "chicken_ability_1_cancel",
        true,
        false
    )

    self.parent:RemoveAbility("chicken_ability_1_cancel")
end

function modifier_chicken_ability_1_self_transmute:CheckState()
    local state = {
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
        [MODIFIER_STATE_IGNORING_STOP_ORDERS] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }

    return state
end
----------
function modifier_chicken_ability_1_target_transmute:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()
    
    if not IsServer() then return end

    self:StartIntervalThink(1.0)
end

function modifier_chicken_ability_1_target_transmute:OnIntervalThink()
    self:OnRefresh()
end

function modifier_chicken_ability_1_target_transmute:OnRefresh()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.damage = caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("damage_inherit") / 100)
    self.spellAmp = (caster:GetSpellAmplification(false) * (ability:GetSpecialValueFor("spell_amp_inherit") / 100)) * 100

    self.magicRes = 0
    self.armor = 0

    local talent = self:GetCaster():FindAbilityByName("talent_wisp_2")
    if talent and talent:GetLevel() > 0 then
        self.damage = 0
        self.spellAmp = 0

        if talent:GetLevel() > 1 then
            self.armor = caster:GetPhysicalArmorValue(false) * (talent:GetSpecialValueFor("shared_armor") / 100)
        end

        if talent:GetLevel() > 2 then
            self.magicRes = caster:Script_GetMagicalArmorValue(false, nil) * 100 * (talent:GetSpecialValueFor("shared_magic_res") / 100)
        end
    end

    self:InvokeBonusDamage()
end

function modifier_chicken_ability_1_target_transmute:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_EVENT_ON_DEATH,
    }

    return funcs
end

function modifier_chicken_ability_1_target_transmute:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local chicken = self:GetCaster()

    if parent == event.attacker then
        local bloodstone = chicken:FindModifierByName("modifier_bloodstone_strygwyr")
        if bloodstone ~= nil then
            local item = bloodstone:GetAbility()
            if item ~= nil then
                local maxCharges = item:GetSpecialValueFor("max_charges")
                local maxStacks = item:GetSpecialValueFor("max_stacks")

                local buff = chicken:FindModifierByName("modifier_bloodstone_strygwyr_kill_counter")
                if not buff then
                    buff = chicken:AddNewModifier(chicken, item, "modifier_bloodstone_strygwyr_kill_counter", {})
                end

                if buff then
                    if buff:GetStackCount() < maxCharges then
                        buff:IncrementStackCount()
                    end
                    
                    if buff:GetStackCount() >= maxCharges then
                        buff:SetStackCount(0)

                        if _G.BloodstoneCharges[chicken:entindex()] < maxStacks then
                            _G.BloodstoneCharges[chicken:entindex()] = item:GetCurrentCharges() + item:GetSpecialValueFor("kill_charges")

                            item:SetCurrentCharges(_G.BloodstoneCharges[chicken:entindex()])
                            item:OnHeroCalculateStatBonus()
                        end
                    end

                    buff:ForceRefresh()
                end
            end
        end
    end

    if parent ~= event.unit then return end
    if parent:GetUnitName() == "npc_dota_necronomicon_archer_custom" then return end

    local lives = chicken:FindModifierByName("modifier_limited_lives")
    if lives ~= nil then
        if lives:GetStackCount() > 1 then
            chicken:SetTimeUntilRespawn(MAX_RESPAWN_TIME)
            lives:DecrementStackCount()
        else
            chicken:SetRespawnsDisabled(true)
            chicken:RemoveModifierByName("modifier_limited_lives")
        end
    end

    if not lives then
        chicken:SetTimeUntilRespawn(MAX_RESPAWN_TIME)
    end

    chicken:ForceKill(false)

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_WORLDORIGIN, chicken )
    ParticleManager:SetParticleControl( effect_cast, 0, chicken:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )
    EmitSoundOn("Hero_Techies.StickyBomb.Detonate", chicken)
end

function modifier_chicken_ability_1_target_transmute:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()

    if caster:HasModifier("modifier_chicken_ability_1_self_transmute") then
        caster:RemoveModifierByNameAndCaster("modifier_chicken_ability_1_self_transmute", parent)
    end

    local frenzy = caster:FindAbilityByName("chicken_ability_2")
    if frenzy ~= nil and frenzy:GetLevel() > 0 then
        if frenzy:GetToggleState() then
            frenzy:ToggleAbility()
        end
        
        frenzy:SetActivated(false)
    end
end

function modifier_chicken_ability_1_target_transmute:GetModifierMagicalResistanceBonus()
    return self.fMagicRes
end

function modifier_chicken_ability_1_target_transmute:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_chicken_ability_1_target_transmute:GetModifierSpellAmplify_Percentage()
    return self.fSpellAmp
end

function modifier_chicken_ability_1_target_transmute:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_chicken_ability_1_target_transmute:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
        spellAmp = self.fSpellAmp,
        magicRes = self.fMagicRes,
        armor = self.fArmor
    }
end

function modifier_chicken_ability_1_target_transmute:HandleCustomTransmitterData(data)
    if data.damage ~= nil and data.spellAmp ~= nil and data.magicRes ~= nil and data.armor ~= nil then
        self.fDamage = tonumber(data.damage)
        self.fSpellAmp = tonumber(data.spellAmp)
        self.fMagicRes = tonumber(data.magicRes)
        self.fArmor = tonumber(data.armor)
    end
end

function modifier_chicken_ability_1_target_transmute:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage
        self.fSpellAmp = self.spellAmp
        self.fMagicRes = self.magicRes
        self.fArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end

function modifier_chicken_ability_1_target_transmute:GetEffectName()
    return "particles/units/heroes/hero_omniknight/omniknight_shard_hammer_of_purity_overhead_debuff.vpcf"
end

function modifier_chicken_ability_1_target_transmute:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW   
end