LinkLuaModifier("modifier_chicken_ability_4", "heroes/chicken/chicken_ability_4.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chicken_ability_4_burn", "heroes/chicken/chicken_ability_4.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

chicken_ability_4 = class(ItemBaseClass)
modifier_chicken_ability_4 = class(chicken_ability_4)
modifier_chicken_ability_4_burn = class(ItemBaseClassDebuff)
-------------
function chicken_ability_4:GetIntrinsicModifierName()
    return "modifier_chicken_ability_4"
end

function chicken_ability_4:GetCooldown()
    local caster = self:GetCaster()

    local talent = self:GetCaster():FindAbilityByName("talent_wisp_1")
    if talent and talent:GetLevel() > 0 then
        return talent:GetSpecialValueFor("cooldown")
    end

    return 0
end

function chicken_ability_4:OnProjectileHit_ExtraData(hTarget, hLoc, extraData)
    if not hTarget then return end

    self.particle = ParticleManager:CreateParticle("particles/econ/items/ogre_magi/ogre_ti10_taunt/ogre_magi_arcana_taunt_egg_egg_run.vpcf", PATTACH_ABSORIGIN, hTarget)
    ParticleManager:SetParticleControl(self.particle, 0, hTarget:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(self.particle)

    local caster = self:GetCaster()

    local talent = self:GetCaster():FindAbilityByName("talent_wisp_1")
    if talent and talent:GetLevel() > 0 and extraData.big == 1 then
        local boom = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_ABSORIGIN, hTarget)
        ParticleManager:SetParticleControl(boom, 0, hTarget:GetAbsOrigin())
        ParticleManager:SetParticleControl(boom, 1, Vector(talent:GetSpecialValueFor("radius"), talent:GetSpecialValueFor("radius"), talent:GetSpecialValueFor("radius")))
        ParticleManager:ReleaseParticleIndex(boom)

        EmitSoundOn("Hero_Techies.StickyBomb.Detonate", hTarget)

        local victims = FindUnitsInRadius(self:GetCaster():GetTeam(), hTarget:GetAbsOrigin(), nil,
            talent:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,enemy in ipairs(victims) do
            if not enemy:IsAlive() or enemy:IsMagicImmune() then break end

            caster:PerformAttack(
                enemy,
                true,
                true,
                false,
                true,
                false,
                true,
                false
            )

            local damage = caster:GetAverageTrueAttackDamage(caster) * (talent:GetSpecialValueFor("damage_from_attack")/100)

            ApplyDamage({
                victim = enemy,
                attacker = self:GetCaster(),
                damage = damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self 
            })

            if talent:GetLevel() > 2 then
                enemy:AddNewModifier(enemy, nil, "modifier_stunned", {
                    duration = talent:GetSpecialValueFor("stun_duration")
                })

                enemy:AddNewModifier(enemy, self, "modifier_chicken_ability_4_burn", {
                    duration = talent:GetSpecialValueFor("burn_duration"),
                    damage = damage
                })
            end
        end

        if caster:HasScepter() and talent:GetLevel() > 1 then
            local scepterModifier = caster:FindModifierByName("modifier_chicken_ability_5")
            if scepterModifier then
                local scepter = scepterModifier:GetAbility()
                if scepter and scepter:GetLevel() > 0 then
                    victims = shuffleTable(victims)
                    for i,victim in ipairs(victims) do
                        if i <= talent:GetSpecialValueFor("chicken_count") then
                            scepterModifier:SummonChicken(victim:GetAbsOrigin())
                        else
                            break
                        end
                    end
                end
            end
        end
    end

    caster:PerformAttack(
        hTarget,
        true,
        true,
        false,
        true,
        false,
        false,
        false
    )
end
-------------
function modifier_chicken_ability_4:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK_CANCELLED,
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_chicken_ability_4:OnCreated()
    if not IsServer() then return end

    self.host = nil
    self.attack = false
    self.bigAttack = false
    
    self:StartIntervalThink(FrameTime())
end

function modifier_chicken_ability_4:OnIntervalThink()
    local parent = self:GetParent()

    local ability = self:GetAbility()

    local transmute = parent:FindModifierByName("modifier_chicken_ability_1_self_transmute")
    if not transmute then return end

    self.host = transmute:GetCaster()
end

function modifier_chicken_ability_4:OnAttackStart(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if not parent:HasModifier("modifier_chicken_ability_1_self_transmute") then return end

    if not self.host then return end 

    if self.host ~= event.attacker or self.host == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")

    local talent = self:GetCaster():FindAbilityByName("talent_wisp_1")
    
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then
        if not RollPercentage(chance) then return end
    end

    self.attack = true

    if not ability:IsCooldownReady() then return end

    self.bigAttack = true
end

function modifier_chicken_ability_4:OnAttackCancelled(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if not parent:HasModifier("modifier_chicken_ability_1_self_transmute") then return end

    if not self.host then return end 

    if self.host ~= event.attacker or self.host == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    self.attack = false
    self.bigAttack = false
end

function modifier_chicken_ability_4:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if not parent:HasModifier("modifier_chicken_ability_1_self_transmute") then return end

    if not self.host then return end 

    if self.host ~= event.attacker or self.host == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if not self.attack then return end

    local talent = self:GetCaster():FindAbilityByName("talent_wisp_1")

    -- load data
    local projectile_name = "particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_2_tracking.vpcf"
    local projectile_speed = 1200

    if talent and talent:GetLevel() > 0 and self.bigAttack then
        local info = {
            Target = target,
            Source = self:GetCaster(),
            --vSourceLoc = Vector(self.host:GetAbsOrigin().x, self.host:GetAbsOrigin().y, self.host:GetAbsOrigin().z+300),
            Ability = self:GetAbility(), 
            
            EffectName = "particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_2_2_tracking.vpcf",
            iMoveSpeed = projectile_speed,
            bDodgeable = false,                           -- Optional
            ExtraData = {
                big = 1
            }
        }
    
        ProjectileManager:CreateTrackingProjectile(info)

        self:GetAbility():UseResources(false, false, false, true)
    end

    -- create projectile
    local info = {
        Target = target,
        Source = self:GetCaster(),
        --vSourceLoc = Vector(self.host:GetAbsOrigin().x, self.host:GetAbsOrigin().y, self.host:GetAbsOrigin().z+300),
        Ability = self:GetAbility(), 
        
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bDodgeable = false,                           -- Optional
        ExtraData = {
            big = 0
        }
    }

    ProjectileManager:CreateTrackingProjectile(info)
    
    self.attack = false
    self.bigAttack = false
end
-------------------
function modifier_chicken_ability_4_burn:OnCreated(params)
    if not IsServer() then return end 

    self.damage = params.damage

    self:StartIntervalThink(0.5)
end

function modifier_chicken_ability_4_burn:OnIntervalThink()
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })
end

function modifier_chicken_ability_4_burn:GetEffectName() return "particles/units/heroes/hero_snapfire/hero_snapfire_burn_debuff.vpcf" end