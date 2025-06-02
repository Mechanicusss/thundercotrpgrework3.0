LinkLuaModifier("modifier_boss_arc_warden_ai", "heroes/bosses/arc_warden/ai", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

modifier_boss_arc_warden_ai = class(BaseClass)
-------------------------
function modifier_boss_arc_warden_ai:OnCreated()
    if not IsServer() then return end 

    self.parent = self:GetParent()

    self.tempestDouble = self.parent:FindAbilityByName("boss_arc_warden_summon_double")
    self.magneticFieldCollapse = self.parent:FindAbilityByName("boss_arc_warden_magnetic_field_collapse")

    self.damageTakenTD = 0
    self.damageTakenMFC = 0

    -- Making sure they get leveled up properly --
    Timers:CreateTimer(1.0, function()
        for i = 0, self.parent:GetAbilityCount() - 1 do
            local abil = self.parent:GetAbilityByIndex(i)
            if abil ~= nil then
                abil:SetLevel(1)
            end
        end
    end)

    self:StartIntervalThink(FrameTime())
end

function modifier_boss_arc_warden_ai:OnIntervalThink()
    if self.parent:IsStunned() or self.parent:IsSilenced() or self.parent:IsHexed() then return end 

    if self.tempestDouble:IsCooldownReady() and self.damageTakenTD >= (self.parent:GetMaxHealth() * 0.20) then
        SpellCaster:Cast(self.tempestDouble, self.parent, true)
        self.damageTakenTD = 0
    end

    if self.magneticFieldCollapse:IsCooldownReady() and self.damageTakenMFC >= (self.parent:GetMaxHealth() * 0.1) then
        SpellCaster:Cast(self.magneticFieldCollapse, self.parent, true)
        self.damageTakenMFC = 0
    end
end

function modifier_boss_arc_warden_ai:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_boss_arc_warden_ai:GetActivityTranslationModifiers()
    return "run"
end

function modifier_boss_arc_warden_ai:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()
    local attacker = event.attacker 
    local victim = event.unit 

    if parent ~= victim then return end 

    self.damageTakenTD = self.damageTakenTD + event.damage
    self.damageTakenMFC = self.damageTakenMFC + event.damage
end

function modifier_boss_arc_warden_ai:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()
    local attacker = event.attacker 
    local victim = event.unit 

    if parent ~= victim then return end 

    DropNeutralItemAtPositionForHero("item_cursed_blade_piece_1", parent:GetAbsOrigin(), parent, -1, true)
end

function modifier_boss_arc_warden_ai:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_MISS] = true
    }
end