LinkLuaModifier("modifier_asan_dagger_flurry_thinker", "heroes/hero_asan/asan_dagger_flurry", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_asan_dagger_flurry_autocast", "heroes/hero_asan/asan_dagger_flurry", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_asan_dagger_flurry", "heroes/hero_asan/asan_dagger_flurry", LUA_MODIFIER_MOTION_NONE)


asan_dagger_flurry              = class({})

modifier_asan_dagger_flurry_autocast = class({
  IsPurgable = function(self) return false end,
  RemoveOnDeath = function(self) return false end,
  IsHidden = function(self) return true end,
  IsStackable = function(self) return false end,
})

function asan_dagger_flurry:GetAOERadius() 
    return self:GetSpecialValueFor("radius")
end

function asan_dagger_flurry:GetIntrinsicModifierName()
  return "modifier_asan_dagger_flurry_autocast"
end

function asan_dagger_flurry:GetBehavior()
  local caster = self:GetCaster()
  local talent = caster:FindAbilityByName("talent_elder_titan_1")
  if talent ~= nil and talent:GetLevel() > 0 then
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AUTOCAST + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK + DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
  end
end

function asan_dagger_flurry:GetCooldown(level)
  local caster = self:GetCaster()
  local talent = caster:FindAbilityByName("talent_elder_titan_1")
  if talent ~= nil and talent:GetLevel() > 0 then
    local cd = self.BaseClass.GetCooldown( self, level ) - talent:GetSpecialValueFor("cooldown_reduction")
    if cd < 0 then
      cd = 0.1
    end 

    return cd
  end
end

function modifier_asan_dagger_flurry_autocast:OnCreated()
  if not IsServer() then return end

  self:StartIntervalThink(0.1)
end

function modifier_asan_dagger_flurry_autocast:OnIntervalThink()
  local caster = self:GetCaster()
  local talent = caster:FindAbilityByName("talent_elder_titan_1")
  if talent ~= nil and talent:GetLevel() > 0 then
    if self:GetParent():IsChanneling() then return end
    
    if self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() and self:GetAbility():IsCooldownReady() then
        SpellCaster:Cast(self:GetAbility(), self:GetParent(), true)
    end
  end
end

function asan_dagger_flurry:OnSpellStart()

  self.caster = self:GetCaster()
  self.radius         = self:GetSpecialValueFor("radius") 
  self.projectile_speed   = self:GetSpecialValueFor("projectile_speed")
  self.location = self:GetCaster():GetAbsOrigin()
  self.duration       = self.radius / self.projectile_speed
  

  if not IsServer() then return end
  self:GetCaster():EmitSound("Hero_PhantomAssassin.FanOfKnives.Cast")
  CreateModifierThinker(self.caster, self, "modifier_asan_dagger_flurry_thinker", {duration = self.duration}, self.location, self.caster:GetTeamNumber(), false)
end



modifier_asan_dagger_flurry_thinker = class({})


function modifier_asan_dagger_flurry_thinker:OnCreated()
  self.ability  = self:GetAbility()
  self.caster   = self:GetCaster()
  self.parent   = self:GetParent()
  

  self.radius         = self.ability:GetSpecialValueFor("radius")
  if not IsServer() then return end
  
  self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin_persona/pa_persona_shard_fan_of_knives.vpcf", PATTACH_ABSORIGIN, self.parent)
  ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
  ParticleManager:SetParticleControl(self.particle, 3, self:GetParent():GetAbsOrigin())
  self:AddParticle(self.particle, false, false, -1, false, false)
  
  self.hit_enemies = {}
  
  self:StartIntervalThink(FrameTime())
end

function modifier_asan_dagger_flurry_thinker:OnIntervalThink()
  if not IsServer() then return end

  local caster = self:GetCaster()

  local radius_pct = math.min((self:GetDuration() - self:GetRemainingTime()) / self:GetDuration(), 1)
  
  local enemies = FindUnitsInRadius(self.parent:GetTeamNumber(), self.parent:GetAbsOrigin(), nil, self.radius * radius_pct, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
  
  for _, enemy in pairs(enemies) do
  
    local hit_already = false
  
    for _, hit_enemy in pairs(self.hit_enemies) do
      if hit_enemy == enemy then
        hit_already = true
        break
      end
    end

    if not hit_already and not enemy:IsMagicImmune() then
      local strikeDamage = self:GetAbility():GetSpecialValueFor("strike_damage")

      local talent = self.caster:FindAbilityByName("special_bonus_unique_asan_2_custom")
    
      if talent ~= nil and talent:GetLevel() > 0 then
          strikeDamage = strikeDamage + talent:GetSpecialValueFor("value")
      end

      local damage = strikeDamage + (self.caster:GetAgility() * (self.ability:GetSpecialValueFor("agi_to_damage")/100))

      local damageTable = {
        victim      = enemy,
        damage      = damage,
        damage_type   = DAMAGE_TYPE_PHYSICAL,
        damage_flags  = DOTA_DAMAGE_FLAG_NONE,
        attacker    = self.caster,
        ability     = self.ability
      }
                  
      ApplyDamage(damageTable)
      
      SendOverheadEventMessage(enemy, 4, enemy, damage, nil)

      local talent = self.caster:FindAbilityByName("talent_elder_titan_1")

      enemy:EmitSound("Hero_PhantomAssassin.Attack")
      local duration = self:GetAbility():GetSpecialValueFor("duration")

      if talent ~= nil and talent:GetLevel() > 1 then
        duration = duration * 2
      end

      local debuff = enemy:FindModifierByName("modifier_asan_dagger_flurry")
      if not debuff then
        debuff = enemy:AddNewModifier(self.caster, self.ability, "modifier_asan_dagger_flurry", {
            duration = duration
        })
      end

      if debuff then
        
        if talent ~= nil and talent:GetLevel() > 1 then
          local maxStacks = talent:GetSpecialValueFor("max_stacks")
          if debuff:GetStackCount() < maxStacks then
            debuff:IncrementStackCount()
          end
        end

        debuff:ForceRefresh()
      end

      table.insert(self.hit_enemies, enemy)
      

    end

  end

end



modifier_asan_dagger_flurry = class({})
function modifier_asan_dagger_flurry:IsHidden() return false end
function modifier_asan_dagger_flurry:IsPurgable() return false end
function modifier_asan_dagger_flurry:GetEffectName() return "particles/units/heroes/hero_phantom_assassin_persona/pa_persona_shard_fan_of_knives_debuff.vpcf" end

function modifier_asan_dagger_flurry:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_asan_dagger_flurry:GetModifierTotalDamageOutgoing_Percentage(event)
  local caster = self:GetCaster()
  local talent = caster:FindAbilityByName("talent_elder_titan_1")
  if talent ~= nil and talent:GetLevel() > 2 then
    return talent:GetSpecialValueFor("damage_reduction_pct")
  end
end

function modifier_asan_dagger_flurry:OnDeath(event)
  if not IsServer() then return end

  local parent = self:GetParent()

  if parent ~= event.unit then return end 
  if not IsCreepTCOTRPG(parent) and not IsBossTCOTRPG(parent) then return end 

  local caster = self:GetCaster()
  local ability = self:GetAbility()

  local talent = caster:FindAbilityByName("talent_elder_titan_1")
  if not talent or (talent ~= nil and talent:GetLevel() < 3) then return end

  local radius         = ability:GetSpecialValueFor("radius") 
  local projectile_speed   = ability:GetSpecialValueFor("projectile_speed")
  local location = parent:GetAbsOrigin()
  local duration       = radius / projectile_speed
  

  if not IsServer() then return end
  parent:EmitSound("Hero_PhantomAssassin.FanOfKnives.Cast")

  CreateModifierThinker(caster, ability, "modifier_asan_dagger_flurry_thinker", {duration = duration}, location, caster:GetTeamNumber(), false)
end

function modifier_asan_dagger_flurry:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetCaster() then return end

    self:ForceRefresh()
end

function modifier_asan_dagger_flurry:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.interval = ability:GetSpecialValueFor("interval")

    self.damageFlat = ability:GetSpecialValueFor("attack_bleed_damage")
    self.damage = self.damageFlat + (caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("attack_bleed_damage_pct")/100))

    self:StartIntervalThink(self.interval)
end

function modifier_asan_dagger_flurry:OnIntervalThink()
    local victim = self:GetParent()

    local damage = self.damage

    if self:GetStackCount() > 0 then
      damage = damage * self:GetStackCount()
    end

    local damageTable = {
        victim      = self:GetParent(),
        damage      = damage,
        damage_type   = DAMAGE_TYPE_PHYSICAL,
        attacker    = self:GetCaster(),
        ability     = self:GetAbility()
      }
                  
      ApplyDamage(damageTable)
end