LinkLuaModifier("modifier_int_scaling", "modifiers/modifier_int_scaling.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_difficulty_apocalypse_counter", "modifiers/modifier_int_scaling.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_max_movement_speed", "modifiers/modifier_max_movement_speed.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_int_scaling_int", "modifiers/modifier_int_scaling.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_int_scaling_str", "modifiers/modifier_int_scaling.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_int_scaling_agi", "modifiers/modifier_int_scaling.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local ItemBaseClassApocalypse = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

int_scaling = class(ItemBaseClass)
modifier_int_scaling = class(int_scaling)
modifier_int_scaling_int = class(ItemBaseClass)
modifier_int_scaling_str = class(ItemBaseClass)
modifier_int_scaling_agi = class(ItemBaseClass)
modifier_difficulty_apocalypse_counter = class(ItemBaseClassApocalypse)

function modifier_int_scaling_agi:GetTexture() return "agi" end
function modifier_int_scaling_int:GetTexture() return "int" end
function modifier_int_scaling_str:GetTexture() return "str" end
function modifier_difficulty_apocalypse_counter:GetTexture() return "bossshell" end
-----------------
function int_scaling:GetIntrinsicModifierName()
    return "modifier_int_scaling"
end

function modifier_difficulty_apocalypse_counter:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
-----------------
LOST_ITEMS = {
    ["item_kings_guard_7"] = true,
    ["item_mercure7"] = true,
    ["item_rebels_sword"] = true,
    ["item_octarine_core6"] = true,
    ["item_trident_custom_6"] = true,
    ["item_veil_of_discord6"] = true,
}

function IsItemException(item)
    return LOST_ITEMS[item:GetName()]
end

function modifier_int_scaling:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    
    self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_max_movement_speed", {})

    --self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_int_scaling_int", {})
    --self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_int_scaling_agi", {})
    --self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_int_scaling_str", {})

    self.bDisplayErrorDonator = true
    self.bDisplayErrorAghanim = true

    self:StartIntervalThink(FrameTime())
end

function modifier_int_scaling:OnIntervalThink()
    local npc = self:GetParent()

    -- Fuck book abusers...
    local accountID = PlayerResource:GetSteamAccountID(npc:GetPlayerID())

    local abilities = GetPlayerAbilities(npc)
    for i,ability in ipairs(abilities) do
        if i > 10 then
            local hAbility = npc:FindAbilityByName(ability)
            if hAbility ~= nil then
                if hAbility:GetToggleState() then
                    hAbility:ToggleAbility()
                end

                for z = 1, #_G.PlayerStoredAbilities[accountID], 1 do
                    if _G.PlayerStoredAbilities[accountID][z] == oldAbility then
                        table.remove(_G.PlayerStoredAbilities[accountID], z)
                    end
                end

                npc:RemoveAbilityByHandle(hAbility)
            end
        end
    end

    if npc == nil then return end 
    if npc:IsNull() then return end
    if not npc:IsAlive() then return end

    -- Automatic gold bag pickup
    local items_on_the_ground = Entities:FindAllByClassname("dota_item_drop")
    for _,item in pairs(items_on_the_ground) do
        local containedItem = item:GetContainedItem()
        if containedItem then
            local owner = containedItem:GetOwnerEntity()
            local name = containedItem:GetAbilityName()

            if name == "item_gold_bag" then
                if (item:GetAbsOrigin() - npc:GetAbsOrigin()):Length2D() <= 150 then
                    npc:AddItem(containedItem)
                    UTIL_Remove(containedItem)
                    UTIL_Remove(item)
                end
            end
        end
    end

    -- Automatic upgrade of boots
    --[[
    local boot = npc:FindItemInInventory("item_travel_boots_3")
    if boot ~= nil then
        local gameTime = math.floor(GameRules:GetGameTime() / 60)

        if gameTime <= 10 and boot:GetLevel() < 1 then
            boot:SetLevel(1)
        elseif gameTime <= 20 and gameTime > 10 and boot:GetLevel() == 1 then
            boot:SetLevel(2)
        elseif gameTime <= 30 and gameTime > 20 and boot:GetLevel() == 2 then
            boot:SetLevel(3) 
        elseif gameTime <= 40 and gameTime > 30 and boot:GetLevel() == 3 then
            boot:SetLevel(4) 
        elseif gameTime > 40 and boot:GetLevel() == 4 then
            boot:SetLevel(5)
        end

        if npc:HasModifier("modifier_item_travel_boots_3") then
            npc:FindModifierByName("modifier_item_travel_boots_3"):ForceRefresh()
        end
    end
    --]]

    ---
    local ansanTrigger = Entities:FindByName(nil, "trigger_change_hero_asan")
    local dagger = npc:FindItemInInventory("item_asan_dagger_complete")
    if ansanTrigger ~= nil then
        if IsInTrigger(npc, ansanTrigger) and dagger ~= nil then
            npc:RemoveItem(dagger)

            SwapHeroWithTCOTRPG(npc, "npc_dota_hero_elder_titan", "npc_dota_hero_arena_hero_wearable_dummy_asan")

            UTIL_RemoveImmediate(ansanTrigger)
        end
    end
    --
    local fenrirTrigger = Entities:FindByName(nil, "trigger_change_hero_fenrir")
    if fenrirTrigger ~= nil then
        if IsInTrigger(npc, fenrirTrigger) then
            SwapHeroWithTCOTRPG(npc, "npc_dota_hero_visage", "npc_dota_hero_arena_hero_wearable_dummy_fenrir")

            UTIL_RemoveImmediate(fenrirTrigger)
        end
    end
    --
    local donatorTrigger = Entities:FindByName(nil, "trigger_donator_hero")
    if donatorTrigger ~= nil then
        if IsInTrigger(npc, donatorTrigger) then
            if npc:HasModifier("modifier_effect_private") and not npc:HasModifier("modifier_stunned") then
                CustomNetTables:SetTableValue("select_custom_hero_open", "game_info", { 
                  userEntIndex = npc:GetEntityIndex(),
                  a = RandomInt(1,1000),
                  b = RandomInt(1,1000),
                  c = RandomInt(1,1000),
                })
            else
                if self.bDisplayErrorDonator then
                    DisplayError(npc:GetPlayerID(), "#donator_3_error")
                    self.bDisplayErrorDonator = false
                end
            end
        else
            if not self.bDisplayErrorDonator then
                self.bDisplayErrorDonator = true
            end
        end
    end
    --
    local aghanimTrigger = Entities:FindByName(nil, "trigger_entrance_aghanim")
    if aghanimTrigger ~= nil then
        if IsInTrigger(npc, aghanimTrigger) then
            if _G.AghanimTowers[1] and _G.AghanimTowers[2] and _G.AghanimTowers[3] and _G.AghanimTowers[4] and _G.AghanimTowers[5] then
                local point = Entities:FindByName(nil, "aghanim_tp")

                EmitSoundOn("DOTA_Item.BlinkDagger.Activate", aghanimTrigger)

                FindClearSpaceForUnit(npc, point:GetAbsOrigin(), false)
                CenterCameraOnUnit(npc:GetPlayerID(), npc)
                npc:Stop()
            end
        else
            if not self.bDisplayErrorAghanim then
                self.bDisplayErrorAghanim = true
            end
        end
    end
    --
    local uberBossesTrigger = Entities:FindByName(nil, "trigger_entrance_uber_bosses")
    if uberBossesTrigger ~= nil then
        if IsInTrigger(npc, uberBossesTrigger) then
            if _G.AghanimDefeated then
                local point = Entities:FindByName(nil, "uber_bosses_tp")

                EmitSoundOn("DOTA_Item.BlinkDagger.Activate", uberBossesTrigger)

                FindClearSpaceForUnit(npc, point:GetAbsOrigin(), false)
                CenterCameraOnUnit(npc:GetPlayerID(), npc)
                npc:Stop()
            end
        end
    end
end

function modifier_int_scaling:IsHidden() return true end

function modifier_int_scaling:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION
    }
end

-- Valve added MR per int and you can't remove this with derived values yet so here we go...
function modifier_int_scaling:GetModifierMagicalResistanceDirectModification()
    return self:GetParent():GetIntellect() * -0.1
end

function modifier_int_scaling:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local mode = KILL_VOTE_RESULT:upper()

    if mode ~= "APOCALYPSE" then return end

    if event.target ~= self:GetParent() then return end

    local counter = parent:FindModifierByName("modifier_difficulty_apocalypse_counter")
    if counter == nil then
        counter = parent:AddNewModifier(parent, nil, "modifier_difficulty_apocalypse_counter", {
            duration = 10
        })
    end

    counter:SetStackCount(counter:GetStackCount() + 1)
    counter:ForceRefresh()
end

function modifier_int_scaling:CheckState()
    local state = {
        --[MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
    return state
end
--
function modifier_int_scaling_int:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    if not IsServer() then return end



    self:StartIntervalThink(1)
end

function modifier_int_scaling_int:OnIntervalThink()
    self:OnRefresh()
end

function modifier_int_scaling_int:OnRefresh()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local bonusSpellAmp = caster:GetBaseIntellect() * 0.3

    if bonusSpellAmp > 300 then
        bonusSpellAmp = 300
    end

    self.stats = bonusSpellAmp

    self:InvokeAttributeBonus()
end

function modifier_int_scaling_int:AddCustomTransmitterData()
    return
    {
        stats = self.fStats,
    }
end

function modifier_int_scaling_int:HandleCustomTransmitterData(data)
    if data.stats ~= nil then
        self.fStats = tonumber(data.stats)
    end
end

function modifier_int_scaling_int:InvokeAttributeBonus()
    if IsServer() == true then
        self.fStats = self.stats

        self:SendBuffRefreshToClients()
    end
end

function modifier_int_scaling_int:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
    }

    return funcs
end

function modifier_int_scaling_int:GetModifierSpellAmplify_Percentage()
    return self.fStats
end

---------------------------------
function modifier_int_scaling_str:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_int_scaling_str:OnIntervalThink()
    self:OnRefresh()
end

function modifier_int_scaling_str:OnRefresh()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local bonusArmor = caster:GetBaseStrength() * 0.24
    if bonusArmor > 2500 then
        bonusArmor = 2500
    end

    self.stats = bonusArmor

    self:InvokeAttributeBonus()
end

function modifier_int_scaling_str:AddCustomTransmitterData()
    return
    {
        stats = self.fStats,
    }
end

function modifier_int_scaling_str:HandleCustomTransmitterData(data)
    if data.stats ~= nil then
        self.fStats = tonumber(data.stats)
    end
end

function modifier_int_scaling_str:InvokeAttributeBonus()
    if IsServer() == true then
        self.fStats = self.stats

        self:SendBuffRefreshToClients()
    end
end

function modifier_int_scaling_str:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus (flat)
    }

    return funcs
end

function modifier_int_scaling_str:GetModifierPhysicalArmorBonus(event)
    return self.fStats
end

-----------------
function modifier_int_scaling_agi:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()
    
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_int_scaling_agi:OnIntervalThink()
    self:OnRefresh()
end

function modifier_int_scaling_agi:OnRefresh()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local bonusOutgoing = caster:GetBaseAgility() * 2.5
    if bonusOutgoing > 100000 then
        bonusOutgoing = 100000
    end

    self.stats = bonusOutgoing

    self:InvokeAttributeBonus()
end

function modifier_int_scaling_agi:AddCustomTransmitterData()
    return
    {
        stats = self.fStats,
    }
end

function modifier_int_scaling_agi:HandleCustomTransmitterData(data)
    if data.stats ~= nil then
        self.fStats = tonumber(data.stats)
    end
end

function modifier_int_scaling_agi:InvokeAttributeBonus()
    if IsServer() == true then
        self.fStats = self.stats

        self:SendBuffRefreshToClients()
    end
end

function modifier_int_scaling_agi:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE, --GetModifierBaseAttack_BonusDamage
        
    }

    return funcs
end


function modifier_int_scaling_agi:GetModifierBaseAttack_BonusDamage()
    return self.fStats
end

function modifier_difficulty_apocalypse_counter:OnCreated()
    if not IsServer() then return end
end

function modifier_difficulty_apocalypse_counter:OnStackCountChanged(old)
    if self:GetStackCount() >= 10 then
        self:GetParent():SetMaxHealth(1)
        self:GetParent():ForceKill(false)
    end
end