local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

auto_pickup = class(ItemBaseClass)
modifier_auto_pickup = class(auto_pickup)

-----------------
function auto_pickup:GetIntrinsicModifierName()
    return "modifier_auto_pickup"
end
-----------------
function modifier_auto_pickup:DeclareFunctions()
    return {}
end

function modifier_auto_pickup:OnCreated(params)
    if not IsServer() then return end

    self.player = self:GetParent()

    self:StartIntervalThink(1.0)

    CustomGameEventManager:RegisterListener("autopickup_toggle", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        if event.state == 1 then
            _G.autoPickup[id] = AUTOLOOT_ON
        else
            _G.autoPickup[id] = AUTOLOOT_OFF
        end
    end)

    local ppid = self.player:GetPlayerID()
    local pid = PlayerResource:GetPlayer(ppid)
    
    Timers:CreateTimer(3, function()
        CustomGameEventManager:Send_ServerToPlayer(pid, "autopickup_register", {
            autoloot = _G.autoPickup[ppid],
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)
end

--bug: doesn't disable if you turn it off

function modifier_auto_pickup:OnIntervalThink()
    if not self:GetParent():IsAlive() then return end
    if self:GetParent():IsTempestDouble() then return end
    if self:GetParent():IsIllusion() or not self:GetParent():IsRealHero() then return end
    
    local npc = self:GetParent()

    if npc:HasModifier("modifier_gold_bank") then
        local searchRadius = 600
        if not self.player:IsRangedAttacker() then
            searchRadius = searchRadius + 150
        end

        function LootItem(itemName)
            local item = self.player:AddItemByName(itemName)
            if not item then return end
            item:SetPurchaseTime(0)

            if string.find(item:GetAbilityName(), "item_tome") then
                item:OnSpellStart()
            end
        end

        function GetDistanceToItem(player, item)
            return (player:GetOrigin() - item:GetOrigin()):Length2D()
        end

        function IsSelfNearest(item)
            local playersAroundMe = FindUnitsInRadius(self.player:GetTeam(), self.player:GetAbsOrigin(), nil,
                searchRadius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

            local isNearest = true

            for _,otherPlayer in ipairs(playersAroundMe) do
                if not otherPlayer:IsAlive() or _G.autoPickup[otherPlayer:GetPlayerID()] == AUTOLOOT_OFF or otherPlayer:GetOwner() ~= nil then break end

                if GetDistanceToItem(otherPlayer, item) < GetDistanceToItem(self.player, item) then
                    isNearest = false
                    break
                end
            end

            return isNearest
        end

        if _G.autoPickup[self:GetParent():GetPlayerID()] ~= AUTOLOOT_OFF then
            local items_on_the_ground = Entities:FindAllByClassname("dota_item_drop")
            for _,item in pairs(items_on_the_ground) do
                local containedItem = item:GetContainedItem()
                if containedItem then
                    local owner = containedItem:GetOwnerEntity()
                    local name = containedItem:GetAbilityName()

                    if not string.find(name, "item_socket_rune") and not string.find(name, "soul") and not string.find(name, "item_gold_bag") and not string.find(name, "asan") and not string.find(name, "item_piece") then
                        --todo:make sure the other player earound also has it toggled on
                        if owner == nil then
                            if self.player:HasAnyAvailableInventorySpace() and (GetDistanceToItem(self.player, item) <= searchRadius) and IsSelfNearest(item) then
                                local purchaser = containedItem:GetPurchaser()

                                if purchaser ~= nil then break end

                                UTIL_RemoveImmediate(item)
                                UTIL_RemoveImmediate(containedItem)

                                LootItem(name)
                            end
                        end
                    end
                end

                --[[if owner == nil then
                    if IsSelfNearest(item) then
                        UTIL_RemoveImmediate(item)
                        LootItem(name)
                    end
                end--]]
            end
        end
    end
end
