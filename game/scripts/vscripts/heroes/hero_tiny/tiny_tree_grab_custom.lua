-- Credits goes to the Dota IMBA team https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/abilities/heroes/hero_tiny
LinkLuaModifier("modifier_tiny_tree_grab_custom", "heroes/hero_tiny/tiny_tree_grab_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tiny_tree_grab_custom_tree", "heroes/hero_tiny/tiny_tree_grab_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

tiny_tree_grab_custom = class(ItemBaseClass)
modifier_tiny_tree_grab_custom = class(tiny_tree_grab_custom)
modifier_tiny_tree_grab_custom_tree = class(ItemBaseClass)
-------------
function tiny_tree_grab_custom:GetIntrinsicModifierName()
    return "modifier_tiny_tree_grab_custom"
end

function tiny_tree_grab_custom:OnProjectileHit_ExtraData(hTarget, hLocation, extraData)
    if not hTarget or hTarget:IsNull() then return end

    local caster = self:GetCaster()

    local victims = FindUnitsInRadius(caster:GetTeam(), hTarget:GetAbsOrigin(), nil,
            extraData.splashRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() then
            ApplyDamage({
                attacker = caster,
                victim = victim,
                damage = extraData.damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self
            })
        end
    end

    local effect_cast = ParticleManager:CreateParticle( "particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree_impact.vpcf", PATTACH_POINT_FOLLOW, hTarget )
    ParticleManager:SetParticleControl( effect_cast, 3, hTarget:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_Tiny.Prestige.Target", hTarget)

    return true
end

function tiny_tree_grab_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_tiny_tree_grab_custom_tree") then
        caster:RemoveModifierByName("modifier_tiny_tree_grab_custom_tree")
    end

    local duration = self:GetSpecialValueFor("duration")

    caster:AddNewModifier(caster, self, "modifier_tiny_tree_grab_custom_tree", {
        duration = duration
    })

    EmitSoundOn("Hero_Tiny.Tree.Grab", caster)
end
------------
function modifier_tiny_tree_grab_custom:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_tiny_tree_grab_custom:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if ability:GetAutoCastState() and ability:IsCooldownReady() and ability:GetManaCost(-1) <= parent:GetMana() and not parent:IsSilenced() and not parent:IsHexed() then
        SpellCaster:Cast(ability, parent, true)
    end
end
------------
function modifier_tiny_tree_grab_custom_tree:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local grow = caster:FindAbilityByName("tiny_grow_custom")
    local grow_lvl = grow:GetLevel()

    self.stored = 0

    -- If we allrdy have a tree... destroy it and create new. 
    if caster.tree ~= nil then
        caster.tree:AddEffects(EF_NODRAW)
        UTIL_Remove(caster.tree)
        caster.tree = nil
    end

    self.treeModel = "models/items/tiny/tiny_prestige/tiny_prestige_sword.vmdl"

    -- Create the tree model
    self.tree = SpawnEntityFromTableSynchronous("prop_dynamic", {model = self.treeModel })
    -- Bind it to caster bone 
    self.tree:FollowEntity(self:GetCaster(), true)
    -- Find the Coordinates for model position on left hand
    local origin = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack2"))
    -- Forward Vector!
    local fv = caster:GetForwardVector()
    
    -- Apply diffrent positions of the tree depending on growth model...
    if grow_lvl == 3 then
        --Adjust poition to match grow lvl 3
        local pos = origin + (fv * 50)
        self.tree:SetAbsOrigin(Vector(pos.x + 10, pos.y, (origin.z + 25)))
    
    elseif grow_lvl == 2 then
        -- Adjust poition to match grow lvl 2
        local pos = origin + (fv * 35)
        self.tree:SetAbsOrigin(Vector(pos.x, pos.y, (origin.z + 25)))

    elseif grow_lvl == 1 then
        -- Adjust poition to match grow lvl 1
        local pos = origin + (fv * 35) 
        self.tree:SetAbsOrigin(Vector(pos.x, pos.y + 20, (origin.z + 25)))

    elseif grow_lvl == 0 then
        -- Adjust poition to match original no grow model
        local pos = origin - (fv * 25) 
        self.tree:SetAbsOrigin(Vector(pos.x - 20, pos.y - 30 , origin.z))
        self.tree:SetAngles(60, 60, -60)
    end

    -- Save model to caster
    caster.tree = self.tree

    local tree_pfx = ParticleManager:CreateParticle("particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.tree)
    ParticleManager:ReleaseParticleIndex(tree_pfx)

    -- Change animation now that we have a huge ass tree in our hand.
    StartAnimation(caster, { duration = -1, activity = ACT_DOTA_ATTACK_EVENT , rate = 2, translate = "tree" })
end

function modifier_tiny_tree_grab_custom_tree:OnRemoved()
    if IsServer() then
        local caster = self:GetCaster()

        local talent = caster:FindAbilityByName("talent_tiny_1")
        -- Talent 
        if talent ~= nil and talent:GetLevel() > 0 then
            local ability = self:GetAbility()

            local radius = talent:GetSpecialValueFor("radius")

            local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
                    radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                    FIND_CLOSEST, false)

            local target = nil 

            for _,victim in ipairs(victims) do
                if victim:IsAlive() then
                    target = victim 
                    break
                end
            end

            if target == nil then return end

            local damage = self.stored

            local grow = caster:FindAbilityByName("tiny_grow_custom")
            if grow ~= nil and grow:GetLevel() > 0 then
                damage = damage * (grow:GetSpecialValueFor("tree_bonus_damage_pct")/100)
            end

            -- Get skill stats
            local travel_distance       = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
            local travel_speed          = talent:GetSpecialValueFor("speed")
            local radius_start          = 275
            local radius_end            = 300

            local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
            direction.z     = 0

            -- Create projectile
            local deafening_blast_projectile_table = 
            {
                EffectName          = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree_linear_proj.vpcf",
                Ability             = ability,
                vSpawnOrigin        = caster:GetAbsOrigin(),
                vVelocity           = direction * travel_speed,
                fDistance           = travel_distance,
                fStartRadius        = radius_start,
                fEndRadius          = radius_end,
                Source              = caster,
                bHasFrontalCone     = true,
                bReplaceExisting    = false,
                iUnitTargetTeam     = DOTA_UNIT_TARGET_TEAM_ENEMY,
                iUnitTargetFlags    = DOTA_UNIT_TARGET_FLAG_NONE,
                iUnitTargetType     = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                ExtraData = {
                    damage              = damage, 
                    splashRadius = talent:GetSpecialValueFor("splash_radius")
                }
            }

            EmitSoundOn("Hero_Tiny.Prestige.Throw", caster)

            ProjectileManager:CreateLinearProjectile(deafening_blast_projectile_table)

            self.stored = 0
        end

        -- stop tree animation
        EndAnimation(caster)
        if caster.tree ~= nil and not caster.tree:IsNull() then
            caster.tree:AddEffects(EF_NODRAW)
        end
    end
end

function modifier_tiny_tree_grab_custom_tree:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL, 
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_tiny_tree_grab_custom_tree:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end
    
    local talent = parent:FindAbilityByName("talent_tiny_1")
    if talent == nil then return end
    if talent:GetLevel() < 1 then return end

    local update = self.stored + (event.original_damage * (talent:GetSpecialValueFor("tree_stored_pct")/100))
    if update >= INT_MAX_LIMIT then
        update = INT_MAX_LIMIT
    end

    self.stored = update

    self:SetStackCount(self.stored)
end

function modifier_tiny_tree_grab_custom_tree:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_range") 
end

function modifier_tiny_tree_grab_custom_tree:GetModifierProcAttack_BonusDamage_Physical(event)
    local parent = self:GetParent()
    if parent ~= event.attacker or not event.target then return end

    local damage = self:GetAbility():GetSpecialValueFor("bonus_damage")

    local ability = self:GetAbility()
    local grow = parent:FindAbilityByName("tiny_grow_custom")
    if grow ~= nil and grow:GetLevel() > 0 then
        damage = damage * (grow:GetSpecialValueFor("tree_bonus_damage_pct")/100)
    end

    return damage
end

function modifier_tiny_tree_grab_custom_tree:OnAttackLanded(keys)
    local caster = self:GetCaster()
    if IsServer() then 
        -- Checking for keys.no_attack_cooldown == false is to prevent Tree Volley (aghs ability) from consuming tree charges
        if caster == keys.attacker and not keys.no_attack_cooldown then
            if keys.target ~= nil then
                -- Splash is centered around a point abit intfron of tiny, tweeked by "splash_distance"
                local splash_distance = caster:GetForwardVector() * self:GetAbility():GetSpecialValueFor("splash_distance")
                local splash_radius = self:GetAbility():GetSpecialValueFor("splash_radius")
                local splash_damage = self:GetAbility():GetSpecialValueFor("splash_damage")
                splash_distance.z = 0

                -- Initiate splash damage_table
                local damage_table = {}
                damage_table.attacker = caster
                damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
                damage_table.damage = caster:GetAttackDamage() * (splash_damage / 100)

                local enemies = FindUnitsInRadius(
                    caster:GetTeam(), 
                    keys.target:GetAbsOrigin(), 
                    nil, 
                    splash_radius,
                    DOTA_UNIT_TARGET_TEAM_ENEMY, 
                    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                    0,
                    0,
                    false) 

                for _,enemy in pairs(enemies) do
                    -- Dont deal damage to main target twice
                    EmitSoundOn("Hero_Tiny.Tree.Target", caster)
                    
                    if enemy ~= keys.target then
                        damage_table.victim = enemy
                        ApplyDamage(damage_table)
                    end

                    -- credits: Boss Hunters (Sidearms92)
                    local pfxName = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree_melee_hit.vpcf"

                    local nfx = ParticleManager:CreateParticle(pfxName, PATTACH_POINT, caster)
                    ParticleManager:SetParticleControl(nfx, 0, enemy:GetAbsOrigin())
                    ParticleManager:SetParticleControl(nfx, 1, enemy:GetAbsOrigin())
                    ParticleManager:SetParticleControlForward(nfx, 2, caster:GetForwardVector())
                    ParticleManager:ReleaseParticleIndex(nfx)
                end
            end
        end
    end
end

function modifier_tiny_tree_grab_custom_tree:IsHidden() return false end
function modifier_tiny_tree_grab_custom_tree:RemoveOnDeath() return true end

