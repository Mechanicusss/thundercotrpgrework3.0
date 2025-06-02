LinkLuaModifier("modifier_tanya_sharp_edges", "heroes/hero_tanya/tanya_sharp_edges.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tanya_sharp_edges_buff", "heroes/hero_tanya/tanya_sharp_edges.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,  -- Изменено на true
    IsDebuff = function(self) return false end,
}

tanya_sharp_edges = class(ItemBaseClass)
modifier_tanya_sharp_edges = class(tanya_sharp_edges)
modifier_tanya_sharp_edges_buff = class(ItemBaseClassBuff)

function tanya_sharp_edges:GetIntrinsicModifierName()
    return "modifier_tanya_sharp_edges"
end

function modifier_tanya_sharp_edges:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT
    }
end

function modifier_tanya_sharp_edges:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.bat = self:GetParent():GetBaseAttackTime() - self:GetAbility():GetSpecialValueFor("bat_decrease")
    self.attackCounter = 0

    self:InvokeBonus()
end

function modifier_tanya_sharp_edges:GetModifierBaseAttackTimeConstant()
    return self.fBat
end

function modifier_tanya_sharp_edges:AddCustomTransmitterData()
    return {
        bat = self.fBat
    }
end

function modifier_tanya_sharp_edges:HandleCustomTransmitterData(data)
    if data.bat ~= nil then
        self.fBat = tonumber(data.bat)
    end
end

function modifier_tanya_sharp_edges:InvokeBonus()
    if IsServer() then
        self.fBat = self.bat
        self:SendBuffRefreshToClients()
    end
end

function modifier_tanya_sharp_edges:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    self.attackCounter = self.attackCounter + 1

    if self.attackCounter == 2 then
        self.attackCounter = 0

        -- Проверяем, есть ли уже модификатор buff
        local buffModifier = parent:FindModifierByName("modifier_tanya_sharp_edges_buff")
        if buffModifier then
            -- Увеличиваем количество стаков
            buffModifier:IncrementStackCount()
        else
            -- Если модификатора нет, добавляем его
            parent:AddNewModifier(parent, ability, "modifier_tanya_sharp_edges_buff", {})
        end

        ability:UseResources(false, false, false, true)
    end
end

function modifier_tanya_sharp_edges_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }

    return funcs
end

function modifier_tanya_sharp_edges_buff:GetModifierPreAttack_CriticalStrike(params)
    local parent = self:GetParent()

    if IsServer() and (not parent:PassivesDisabled()) then
        local ability = self:GetAbility()
        local critDmg = ability:GetSpecialValueFor("crit_damage")
        local critPerAgi = ability:GetSpecialValueFor("crit_damage_per_agi")
        local totalCrit = critDmg + (parent:GetAgility() * critPerAgi)

        self.record = params.record
        return totalCrit * self:GetStackCount()  -- Умножаем на количество стаков
    end
end

function modifier_tanya_sharp_edges_buff:GetModifierProcAttack_Feedback(params)
    if IsServer() then
        if self.record then
            self.record = nil
            EmitSoundOn("DOTA_Item.Daedelus.Crit", params.target)

            -- Уменьшаем количество стаков или уничтожаем модификатор
            if self:GetStackCount() > 1 then
                self:DecrementStackCount()
            else
                self:Destroy()  -- Уничтожаем модификатор, если стаков больше нет
            end
        end
    end
end