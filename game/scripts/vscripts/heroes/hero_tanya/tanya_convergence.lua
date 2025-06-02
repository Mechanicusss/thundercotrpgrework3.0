LinkLuaModifier("modifier_tanya_convergence", "heroes/hero_tanya/tanya_convergence.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tanya_convergence_slow", "heroes/hero_tanya/tanya_convergence.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

tanya_convergence = class(ItemBaseClass)
modifier_tanya_convergence = class(ItemBaseClassBuff)
modifier_tanya_convergence_slow = class(ItemBaseClassDebuff)
-------------
function tanya_convergence:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_tanya_convergence", { duration = self:GetSpecialValueFor("duration") })

    EmitSoundOn("Hero_Antimage.Counterspell.Cast", caster)
end
-------------
function modifier_tanya_convergence:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    local parent = self:GetParent()

    self.ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self.ability:GetSpecialValueFor("damage_reduction")

    self.vfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_antimage/antimage_counter.vpcf", PATTACH_POINT_FOLLOW, parent )
	ParticleManager:SetParticleControlEnt(
		self.vfx,
		0,
		parent,
		PATTACH_ROOTBONE_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControl( self.vfx, 1, Vector( 90, 80, 0 ) )

	-- buff particle
	self:AddParticle(
		self.vfx,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)

    local agility = parent:GetAgility()

    self.agility = agility * (self.ability:GetSpecialValueFor("bonus_agility_pct")/100)
    self.amount = (agility + self.agility) * (self.ability:GetSpecialValueFor("shield_from_agility_pct")/100)

    self.attacks = self.ability:GetSpecialValueFor("number_of_hits")
    self.healthDiff = self.ability:GetSpecialValueFor("hp_damage_diff")
    self.radius = self.ability:GetSpecialValueFor("radius")
    self.slowDuration = self.ability:GetSpecialValueFor("slow_duration")
    self.count = 0

    self.shieldPhysical = self.amount 

    self:InvokeShield()
end

function modifier_tanya_convergence:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_tanya_convergence:OnDestroy()
    if not IsServer() then return end 

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_tanya_convergence:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
    }
end

function modifier_tanya_convergence:GetModifierBonusStats_Agility()
    return self.fAgility
end

function modifier_tanya_convergence:AddCustomTransmitterData()
    return
    {
        agility = self.fAgility,
        shieldPhysical = self.fShieldPhysical,
    }
end

function modifier_tanya_convergence:HandleCustomTransmitterData(data)
    if data.shieldPhysical ~= nil and data.agility ~= nil then
        self.fAgility = tonumber(data.agility)
        self.fShieldPhysical = tonumber(data.shieldPhysical)
    end
end

function modifier_tanya_convergence:InvokeShield()
    if IsServer() == true then
        self.fAgility = self.agility
        self.fShieldPhysical = self.shieldPhysical

        self:SendBuffRefreshToClients()
    end
end

function modifier_tanya_convergence:GetModifierIncomingDamageConstant(event)
    if not IsServer() then
        return self.fShieldPhysical
    end

    if event.target ~= self:GetParent() or bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return end
    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end
    if self.amount <= 0 then return end

    local block = 0
    local negated = self.amount - event.damage 

    if negated <= 0 then
        block = self.amount
    else
        block = event.damage
    end

    self.amount = negated

    if self.amount <= 0 then
        self.amount = 0
        self.shieldPhysical = 0

        self:InvokeShield()

        if self.vfx ~= nil then
            ParticleManager:DestroyParticle(self.vfx, true)
            ParticleManager:ReleaseParticleIndex(self.vfx)
        end

        return
    else
        self.shieldPhysical = self.amount
    end

    self:InvokeShield()

    return -block
end

function modifier_tanya_convergence:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    if not IsCreepTCOTRPG(event.target) and not IsBossTCOTRPG(event.target) then return end 

    if not parent:HasScepter() then return end

    if self.count < self.attacks then
        self.count = self.count + 1

        local effect_cast = ParticleManager:CreateParticle( "particles/econ/items/antimage/antimage_weapon_basher_ti5/am_manaburn_basher_ti_5.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.target )
        ParticleManager:SetParticleControl( effect_cast, 0, event.target:GetAbsOrigin() )
        ParticleManager:ReleaseParticleIndex( effect_cast )
    
        EmitSoundOn("Hero_Antimage.ManaBreak", event.target)
    
        event.target:AddNewModifier(parent, self:GetAbility(), "modifier_tanya_convergence_slow", { duration = self.slowDuration })

        ApplyDamage({
            attacker = parent,
            victim = event.target,
            damage = event.damage * (self:GetAbility():GetSpecialValueFor("damage_to_pure")/100),
            damage_type = DAMAGE_TYPE_PURE,
            ability = self:GetAbility()
        })

        if self.count == 2 then
            local effect_cast = ParticleManager:CreateParticle( "particles/econ/items/antimage/antimage_weapon_basher_ti5/antimage_manavoid_ti_5.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.target )
            ParticleManager:SetParticleControl( effect_cast, 0, event.target:GetAbsOrigin() )
            ParticleManager:SetParticleControl( effect_cast, 1, Vector(self.radius, self.radius, self.radius) )
            ParticleManager:ReleaseParticleIndex( effect_cast )
            EmitSoundOn("Hero_Antimage.ManaVoid", event.target)
        
            local damage = ((event.target:GetMaxHealth() - event.target:GetHealth()) * (self.healthDiff/100)) 
        
            local enemies = FindUnitsInRadius(
                parent:GetTeam(),
                event.target:GetAbsOrigin(),
                nil,
                self.radius,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_BASIC,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST,
                false
            )
        
            for _,enemy in ipairs(enemies) do
                if not enemy:IsAlive() or enemy:IsMagicImmune() then break end
        
                ApplyDamage({
                    attacker = parent,
                    victim = enemy,
                    damage = damage,
                    damage_type = DAMAGE_TYPE_MAGICAL,
                    ability = self:GetAbility()
                })
            end

            self.count = 0
        end
    end
end
----------------
function modifier_tanya_convergence_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }
end

function modifier_tanya_convergence_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_slow_pct")
end

function modifier_tanya_convergence_slow:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_slow")
end