LinkLuaModifier("modifier_item_moon_shard_custom", "items/item_moon_shard_custom/item_moon_shard_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_moon_shard_custom_stacks", "items/item_moon_shard_custom/item_moon_shard_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

item_moon_shard_custom = class(ItemBaseClass)
modifier_item_moon_shard_custom = class(item_moon_shard_custom)
modifier_item_moon_shard_custom_stacks = class(ItemBaseClassStacks)

function item_moon_shard_custom:GetIntrinsicModifierName()
    return "modifier_item_moon_shard_custom"
end

function item_moon_shard_custom:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local buff = target:FindModifierByName("modifier_item_moon_shard_custom_stacks")
    if buff == nil then
        buff = target:AddNewModifier(caster, self, "modifier_item_moon_shard_custom_stacks", {
            attack_speed = self:GetSpecialValueFor("attack_speed")
        })
    end

    if buff then 
        buff:IncrementStackCount()
    end

    EmitSoundOn("Item.MoonShard.Consume", target)

    caster:TakeItem(self)
end

function modifier_item_moon_shard_custom_stacks:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
    return funcs
end

function modifier_item_moon_shard_custom_stacks:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.attack_speed = params.attack_speed
    self:UpdateAttackSpeed()
end

function modifier_item_moon_shard_custom_stacks:OnStackCountChanged()
    if not IsServer() then return end 
    self:UpdateAttackSpeed()
end

function modifier_item_moon_shard_custom_stacks:GetModifierAttackSpeedBonus_Constant()
    return self.fAttack_Speed 
end

function modifier_item_moon_shard_custom_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_moon_shard_custom_stacks:AddCustomTransmitterData()
    return
    {
        attack_speed = self.fAttack_Speed,
    }
end

function modifier_item_moon_shard_custom_stacks:HandleCustomTransmitterData(data)
    if data.attack_speed ~= nil then
        self.fAttack_Speed = tonumber(data.attack_speed)
    end
end

function modifier_item_moon_shard_custom_stacks:UpdateAttackSpeed()
    if IsServer() then
        self.fAttack_Speed = self.attack_speed * self:GetStackCount() -- Увеличиваем скорость атаки в зависимости от количества стаков
        self:SendBuffRefreshToClients()
    end
end