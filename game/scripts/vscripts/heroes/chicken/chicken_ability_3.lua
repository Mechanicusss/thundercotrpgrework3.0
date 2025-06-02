LinkLuaModifier("modifier_chicken_ability_3", "heroes/chicken/chicken_ability_3.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chicken_ability_3_buff", "heroes/chicken/chicken_ability_3.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

chicken_ability_3 = class(ItemBaseClass)
modifier_chicken_ability_3 = class(chicken_ability_3)
modifier_chicken_ability_3_buff = class(ItemBaseClassBuff)
-------------
function chicken_ability_3:GetIntrinsicModifierName()
    return "modifier_chicken_ability_3"
end

function chicken_ability_3:GetBehavior()
    local talent = self:GetCaster():FindAbilityByName("talent_wisp_2")
    if talent and talent:GetLevel() > 0 then
        return DOTA_ABILITY_BEHAVIOR_PASSIVE
    end
    
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AUTOCAST + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

function chicken_ability_3:GetManaCost()
    local talent = self:GetCaster():FindAbilityByName("talent_wisp_2")
    if talent and talent:GetLevel() > 0 then
        return 0
    end
    
    return self.BaseClass.GetManaCost(self, -1) or 0
end

function chicken_ability_3:OnSpellStart()
    if not IsServer() then return end

    local parent = self:GetCaster()
    local ability = self

    EmitSoundOn("TCOTRPG.Chicken.Cuckle", parent)

    local transmute = parent:FindModifierByName("modifier_chicken_ability_1_self_transmute")
    if not transmute then 
        return 
    end

    self.host = transmute:GetCaster()

    local buff = self.host:FindModifierByName("modifier_chicken_ability_3_buff")
    if not buff then
        buff = self.host:AddNewModifier(parent, ability, "modifier_chicken_ability_3_buff", {
            duration = self:GetSpecialValueFor("duration")
        })
    end

    if buff then
        buff:ForceRefresh()
    end
end
--------------
function modifier_chicken_ability_3:OnCreated()
    if not IsServer() then return end

    self.host = nil
    
    self:StartIntervalThink(FrameTime())
end

function modifier_chicken_ability_3:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if ability:GetAutoCastState() and not parent:IsSilenced() and ability:GetManaCost(-1) <= parent:GetMana() and ability:IsCooldownReady() then 
        SpellCaster:Cast(ability, self:GetParent(), true)
    end

    local talent = self:GetCaster():FindAbilityByName("talent_wisp_2")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then return end

    local transmute = parent:FindModifierByName("modifier_chicken_ability_1_self_transmute")
    if not transmute then 
        return 
    end

    self.host = transmute:GetCaster()

    local buff = self.host:FindModifierByName("modifier_chicken_ability_3_buff")
    if not buff then
        buff = self.host:AddNewModifier(parent, ability, "modifier_chicken_ability_3_buff", {})
    end
end
----------------
function modifier_chicken_ability_3_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.host = nil
    
    self:StartIntervalThink(0.1)
end

function modifier_chicken_ability_3_buff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if bit.band(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_PASSIVE) ~= 0 then
        local talent = self:GetCaster():FindAbilityByName("talent_wisp_2")
        if not talent or (talent ~= nil and talent:GetLevel() < 1) then 
            self:Destroy()
            return 
        end
    end

    if not caster:FindAbilityByName("chicken_ability_3") then 
        self:Destroy()
        return
    end

    self:OnRefresh()

    local transmute = caster:FindModifierByName("modifier_chicken_ability_1_self_transmute")
    if not transmute then
        self:Destroy()
        return
    end
end

function modifier_chicken_ability_3_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
    }
    return funcs
end

function modifier_chicken_ability_3_buff:GetModifierConstantHealthRegen()
    return self.fHpRegen
end

function modifier_chicken_ability_3_buff:GetModifierConstantManaRegen()
    return self.fManaRegen
end

function modifier_chicken_ability_3_buff:OnRefresh()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.hpRegen = caster:GetHealthRegen() * (ability:GetSpecialValueFor("shared_regen") / 100)
    self.manaRegen = caster:GetManaRegen() * (ability:GetSpecialValueFor("shared_regen") / 100)

    self:InvokeBonusRegen()
end

function modifier_chicken_ability_3_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
        hpRegen = self.fHpRegen,
        manaRegen = self.fManaRegen,
        spellAmp = self.fSpellAmp
    }
end

function modifier_chicken_ability_3_buff:HandleCustomTransmitterData(data)
    if data.hpRegen ~= nil and data.manaRegen ~= nil then
        self.fHpRegen = tonumber(data.hpRegen)
        self.fManaRegen = tonumber(data.manaRegen)
    end
end

function modifier_chicken_ability_3_buff:InvokeBonusRegen()
    if IsServer() == true then
        self.fHpRegen = self.hpRegen
        self.fManaRegen = self.manaRegen

        self:SendBuffRefreshToClients()
    end
end