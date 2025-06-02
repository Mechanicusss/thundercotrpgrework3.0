LinkLuaModifier("modifier_meepo_megameepo_custom", "heroes/hero_meepo/meepo_megameepo_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meepo_megameepo_custom_emitter", "heroes/hero_meepo/meepo_megameepo_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meepo_megameepo_custom_clone", "heroes/hero_meepo/meepo_megameepo_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

meepo_megameepo_custom = class(ItemBaseClass)
modifier_meepo_megameepo_custom = class(meepo_megameepo_custom)
modifier_meepo_megameepo_custom_emitter = class(meepo_megameepo_custom)
modifier_meepo_megameepo_custom_clone = class(meepo_megameepo_custom)
-------------
function meepo_megameepo_custom:GetIntrinsicModifierName()
    return "modifier_meepo_megameepo_custom"
end
-------------
function modifier_meepo_megameepo_custom:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local point = parent:GetAbsOrigin()
    local ability = self:GetAbility()

    self.megameepoEmitter = CreateUnitByName("outpost_placeholder_unit", point, false, parent, parent, parent:GetTeamNumber())

    self.megameepoEmitter:FollowEntity(parent, true)

    self.emitterMod = self.megameepoEmitter:AddNewModifier(parent, ability, "modifier_meepo_megameepo_custom_emitter", {})

    self:StartIntervalThink(FrameTime())
end

function modifier_meepo_megameepo_custom:OnIntervalThink()
    local parent = self:GetParent()
    local point = parent:GetAbsOrigin()

    self.megameepoEmitter:SetAbsOrigin(point)
end

function modifier_meepo_megameepo_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS
    }
end

function modifier_meepo_megameepo_custom:GetModifierDamageOutgoing_Percentage()
    if self.lockAtk then return 0 end

    self.lockAtk = true

    local atk = self:GetStackCount()

    self.lockAtk = false

    local bonus = atk * self:GetAbility():GetSpecialValueFor("bonus_damage_pct_per_meepo")
    
    return bonus
end

function modifier_meepo_megameepo_custom:GetModifierPhysicalArmorBonus()
    if self.lockArmor then return 0 end

    self.lockArmor = true

    local armor = self:GetParent():GetPhysicalArmorValue(false) * self:GetStackCount()

    self.lockArmor = false

    local bonus = armor * (self:GetAbility():GetSpecialValueFor("bonus_armor_pct_per_meepo")/100)
    
    return bonus
end

function modifier_meepo_megameepo_custom:GetModifierBonusStats_Strength()
    if self.lockStr then return 0 end

    self.lockStr = true

    local str = self:GetParent():GetStrength() * self:GetStackCount()

    self.lockStr = false

    local bonus = str * (self:GetAbility():GetSpecialValueFor("bonus_str_pct_per_meepo")/100)
    
    return bonus
end

function modifier_meepo_megameepo_custom:GetModifierBonusStats_Intellect()
    if self.lockInt then return 0 end

    self.lockInt = true

    local int = self:GetParent():GetBaseIntellect() * self:GetStackCount()

    self.lockInt = false

    local bonus = int * (self:GetAbility():GetSpecialValueFor("bonus_int_pct_per_meepo")/100)
    
    return bonus
end

function modifier_meepo_megameepo_custom:GetModifierBonusStats_Agility()
    if self.lockAgi then return 0 end

    self.lockAgi = true

    local agi = self:GetParent():GetAgility() * self:GetStackCount()

    self.lockAgi = false

    local bonus = agi * (self:GetAbility():GetSpecialValueFor("bonus_agi_pct_per_meepo")/100)
    
    return bonus
end
--------------
function modifier_meepo_megameepo_custom_emitter:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local point = parent:GetAbsOrigin()
    local ability = self:GetAbility()

    self.numberOfClones = ability:GetSpecialValueFor("meepo_clones")
    self.threshold = ability:GetSpecialValueFor("health_threshold_pct")

    self.clones = {}
    self.hp = self.numberOfClones

    self:SetOriginalStackCount(self.numberOfClones)

    for i = 1, self.numberOfClones do
        local clone = CreateUnitByName("outpost_placeholder_unit", point, false, parent, parent, parent:GetTeamNumber())

        clone.megameepoPosition = i

        clone:AddNewModifier(caster, ability, "modifier_meepo_megameepo_custom_clone", {})

        table.insert(self.clones, clone)
    end

    self:StartIntervalThink(FrameTime())
end

function modifier_meepo_megameepo_custom_emitter:CountAliveClones()
    local i = 0
    for _,clone in ipairs(self.clones) do
        if clone.isMeepoAlive then
            i = i + 1
        end
    end
    return i
end

function modifier_meepo_megameepo_custom_emitter:SetOriginalStackCount(count)
    local caster = self:GetCaster()
    local mod = caster:FindModifierByName("modifier_meepo_megameepo_custom")
    if mod then
        mod:SetStackCount(count)
    end
end

function modifier_meepo_megameepo_custom_emitter:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if not caster:IsAlive() then return end

    for i,clone in ipairs(self.clones) do
        local pos = parent:GetAttachmentOrigin(parent:ScriptLookupAttachment("attach_megameepo_"..i))

        clone:SetAbsOrigin(pos)
    end

    local ability = self:GetAbility()

    local shouldRestore = false

    local aliveMeepos = self:CountAliveClones()

    if ability:IsCooldownReady() and (aliveMeepos < self.numberOfClones) then
        local meeposMissing = self.numberOfClones - aliveMeepos

        for i = 1, self.numberOfClones do
            if meeposMissing == i and (caster:GetHealthPercent() >= (100-(self.threshold*i))) then
                shouldRestore = true
                break
            end
        end

        if shouldRestore then
            -- Restore one meepo
            local cloneToRestore = self.clones[aliveMeepos + 1]
            if cloneToRestore ~= nil then
                cloneToRestore:RemoveNoDraw()
                cloneToRestore:ClearActivityModifiers()
                cloneToRestore:AddActivityModifier("megameepo_top")
                cloneToRestore.isMeepoAlive = true
            end

            local currentClone = self.clones[aliveMeepos]
            if currentClone ~= nil then
                currentClone:RemoveNoDraw()
                currentClone:ClearActivityModifiers()
                currentClone:AddActivityModifier("megameepo")
                currentClone.isMeepoAlive = true
            end

            self.hp = self.hp + 1
            if self.hp > self.numberOfClones then
                self.hp = self.numberOfClones
            end

            if self:CountAliveClones() < self.numberOfClones then
                ability:UseResources(false, false, false, true)
            end

            self:SetOriginalStackCount(self:CountAliveClones())
            caster:CalculateStatBonus(true)
        end
    end

    local meeposToRemove = math.floor((100-caster:GetHealthPercent()) / self.threshold)

    if meeposToRemove < 1 then return end 

    self.hp = self.numberOfClones - meeposToRemove

    if self.hp < 0 then
        self.hp = 0
    end

    for i,clone in ipairs(self.clones) do
        -- Get the meepos which must be removed and remove them
        if i > self.hp and clone.isMeepoAlive then
            clone:AddNoDraw()
            clone.isMeepoAlive = false
        end

        -- Set the new top most meepo
        if i == self.hp and clone.isMeepoAlive then
            clone:ClearActivityModifiers()
            clone:AddActivityModifier("megameepo_top")
        end

        -- Find all meepos beneath the new top most meepo and make sure they use the correct animation
        if i < self.hp and clone.isMeepoAlive then
            clone:ClearActivityModifiers()
            clone:AddActivityModifier("megameepo")
        end
    end

    self:SetOriginalStackCount(self:CountAliveClones())
    caster:CalculateStatBonus(true)
end

function modifier_meepo_megameepo_custom_emitter:CheckState()
    return {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   
end

function modifier_meepo_megameepo_custom_emitter:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
    }
end

function modifier_meepo_megameepo_custom_emitter:GetModifierModelChange()
    return "models/heroes/meepo/megameepo.vmdl"
end
------------------
function modifier_meepo_megameepo_custom_clone:CheckState()
    return {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   
end

function modifier_meepo_megameepo_custom_clone:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local numberOfClones = ability:GetSpecialValueFor("meepo_clones")

    parent.isMeepoAlive = true

    parent:SetModel(caster:GetModelName())
    parent:SetOriginalModel(caster:GetModelName())
    parent:SetModelScale(caster:GetModelScale())

    parent:FollowEntity(caster, false)

    if parent.megameepoPosition == numberOfClones then
        parent:AddActivityModifier("megameepo_top")
    else
        parent:AddActivityModifier("megameepo")
    end

    parent:StartGesture(ACT_DOTA_IDLE_RARE)

    -- Check wearables 
    self.wearables = {}
    local model = caster:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() == "dota_item_wearable" then
            table.insert(self.wearables, model)
        end

        model = model:NextMovePeer()
    end

    self.cloneWearables = {}
    for _,wearable in ipairs(self.wearables) do
        local name = wearable:GetModelName()
        
        if #name > 0 then
            local modelEntity = SpawnEntityFromTableSynchronous("prop_dynamic", {model = name})
            modelEntity:FollowEntity(parent, true)

            table.insert(self.cloneWearables, modelEntity)
        end
    end

    self:StartIntervalThink(FrameTime())
end

function modifier_meepo_megameepo_custom_clone:OnIntervalThink()
    local parent = self:GetParent()

    for _,wearable in ipairs(self.cloneWearables) do
        if not parent.isMeepoAlive then
            wearable:AddEffects(EF_NODRAW)
        else
            wearable:RemoveEffects(EF_NODRAW)
        end
    end

    parent:StartGesture(ACT_DOTA_IDLE_RARE)
end

function modifier_meepo_megameepo_custom_clone:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION 
    }
end

function modifier_meepo_megameepo_custom_clone:GetModifierModelChange()
    return "models/heroes/meepo/meepo.vmdl"
end

function modifier_meepo_megameepo_custom_clone:GetOverrideAnimation()
    return ACT_DOTA_IDLE
end

