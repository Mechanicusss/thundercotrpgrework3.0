local AbilityBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ModifierBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

monkey_king_wukongs_command_custom = class(AbilityBaseClass)

LinkLuaModifier("modifier_wukongs_command_custom_buff", "heroes/hero_monkey_king/wukongs_command_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wukongs_command_custom_thinker", "heroes/hero_monkey_king/wukongs_command_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_clone_custom", "heroes/hero_monkey_king/wukongs_command_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_clone_custom_status_effect", "heroes/hero_monkey_king/wukongs_command_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_clone_custom_idle_effect", "heroes/hero_monkey_king/wukongs_command_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_clone_custom_hidden", "heroes/hero_monkey_king/wukongs_command_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wukongs_command_custom_no_lifesteal", "heroes/hero_monkey_king/wukongs_command_custom", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
  -- For Rubick OnUpgrade never happens, that's why OnStolen is needed but then it will lag
  function monkey_king_wukongs_command_custom:OnUpgrade()
    if self.clones == nil and self:GetCaster():IsRealHero() then
      local unit_name = "npc_dota_monkey_clone_custom"
      local max_number_of_rings = 2 -- Change this if Monkey King has extra ring talent
      local max_number_of_monkeys_per_ring = math.max(10, self:GetSpecialValueFor("num_third_soldiers_scepter"))
      local hidden_point = Vector(-10000, -10000, -10000)
      local caster = self:GetCaster()
      -- Initialize tables
      self.clones = {}
      self.clones[1] = {}
      self.clones[2] = {}
      self.clones[3] = {}
      -- Populate tables
      for i = 1, max_number_of_rings do
        self.clones[i]["top"] = CreateUnitByName(unit_name, hidden_point, false, caster, caster:GetOwner(), caster:GetTeam())
        self.clones[i]["top"]:SetOwner(caster)
        self.clones[i]["top"]:AddNewModifier(caster, self, "modifier_monkey_clone_custom_hidden", {})
        --print("[MONKEY KING WUKONG'S COMMAND] Creating unit: " .. unit_name .. " at: self.clones[" .. tostring(i) .. "]['top']")
        for j = 1, max_number_of_monkeys_per_ring-1 do
          self.clones[i][j] = CreateUnitByName(unit_name, hidden_point, false, caster, caster:GetOwner(), caster:GetTeam())
          self.clones[i][j]:SetOwner(caster)
          self.clones[i][j]:AddNewModifier(caster, self, "modifier_monkey_clone_custom_hidden", {})
          --print("[MONKEY KING WUKONG'S COMMAND] Creating unit: " .. unit_name .. " at: self.clones[" .. tostring(i) .. "][" .. tostring(j) .. "]")
        end
      end
      -- Update items of the clones for the first time, causes minor lag on lvl-up
      --self:OnInventoryContentsChanged()
    end
  end
--[[
  function monkey_king_wukongs_command_custom:OnInventoryContentsChanged()
    local caster = self:GetCaster()
    -- Do this only if Wukong's command is not active to prevent lag (Wukong's Command is active only if caster has a buff)
    if self.clones and (not caster:HasModifier("modifier_wukongs_command_custom_buff")) and caster:IsRealHero() then
      local max_number_of_rings = 3
      local max_number_of_monkeys_per_ring = math.max(10, self:GetSpecialValueFor("num_second_soldiers_scepter"))
      -- Update items of the clones
      for i= 1, max_number_of_rings do
        self:CopyCasterItems(self.clones[i]["top"], caster)
        for j=1, max_number_of_monkeys_per_ring-1 do
          self:CopyCasterItems(self.clones[i][j], caster)
        end
      end
    end
  end
  ]]
end

--[[
function monkey_king_wukongs_command_custom:CopyCasterItems(parent, caster)
  local banned_items = {
    -- prevent nutty passive gpm shenanigans
    "item_arcane_origin",
    "item_greater_arcane_boots",
    "item_greater_arcane_boots_2",
    "item_greater_arcane_boots_3",
    "item_greater_arcane_boots_4",
    "item_greater_guardian_greaves",
    "item_greater_guardian_greaves_2",
    "item_greater_guardian_greaves_3",
    "item_greater_guardian_greaves_4",
    -- prevent other fools gold boots causing lag
    "item_tranquil_origin",
    "item_greater_tranquil_boots",
    "item_greater_tranquil_boots_2",
    "item_greater_tranquil_boots_3",
    "item_greater_tranquil_boots_4",
    "item_travel_origin",
    "item_greater_travel_boots",
    "item_greater_travel_boots_2",
    "item_greater_travel_boots_3",
    "item_greater_travel_boots_4",
    "item_abyssal_blade",
    "item_abyssal_blade_2",
    "item_abyssal_blade_3",
    "item_abyssal_blade_4",
    "item_abyssal_blade_5",
    "item_rapier",
    "item_gem",
    "item_courier",
    "item_upgrade_core",
    "item_upgrade_core_2",
    "item_upgrade_core_3",
    "item_upgrade_core_4",
    -- prevent other custom items causing lag
    "item_bloodstone_1",
    "item_bloodstone_2",
    "item_bloodstone_3",
    "item_bloodstone_4",
    "item_ward_stack",
    "item_ward_stack_2",
    "item_ward_stack_3",
    "item_ward_stack_4",
    "item_ward_stack_5",
    "item_infinite_bottle"
  }
  -- Recreate items of the caster (ignore backpack and stash)
  for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = caster:GetItemInSlot(item_slot)
    local clone_item = parent:GetItemInSlot(item_slot)
    if item == nil and clone_item then parent:RemoveItem(clone_item) end
    if item then
      local item_name = item:GetName()
      local skip = false
      if clone_item then
        if clone_item:GetName() == item_name then
          skip = true
        else
          parent:RemoveItem(clone_item)
        end
      end
      -- Don't add certain items like Abyssal Blade
      for i= 1, #banned_items do
        if item_name == banned_items[i] then
          skip = true
        end
      end

      -- Dont add items with charges to avoid weird bugs
      if item:RequiresCharges() then
        skip = true
      end

      -- Create new Item
      if not skip then
        local new_item = CreateItem(item_name, parent, parent)
        --print("copy item: " .. item_name)
        parent:AddItem(new_item)

        -- Set correct inventory position
        if parent:GetItemInSlot(item_slot) ~= new_item then
          for slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
            if parent:GetItemInSlot(slot) == new_item then
              parent:SwapItems(slot, item_slot)
              break
            end
          end
        end

        new_item:SetStacksWithOtherOwners(true)
        new_item:SetPurchaser(nil)

        if new_item:IsToggle() and item:GetToggleState() then
          new_item:ToggleAbility()
        end
      end
    end
  end
end
]]

function monkey_king_wukongs_command_custom:GetCooldown(level)
  local cooldown = self.BaseClass.GetCooldown(self, level)
  local caster = self:GetCaster()

  if caster:HasScepter() then
    cooldown = self:GetSpecialValueFor("cooldown_scepter")
  end

  return cooldown
end

function monkey_king_wukongs_command_custom:OnAbilityPhaseStart()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()

  -- Sound during casting
  caster:EmitSound("Hero_MonkeyKing.FurArmy.Channel")

  -- Particle during casting
  self.castHandle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_fur_army_cast.vpcf", PATTACH_ABSORIGIN, caster)

  return true
end

function monkey_king_wukongs_command_custom:OnAbilityPhaseInterrupted()
  if not IsServer() then
    return
  end

  -- Interrupt casting sound
  self:GetCaster():StopSound("Hero_MonkeyKing.FurArmy.Channel")

  -- Remove casting particle
  if self.castHandle then
    ParticleManager:DestroyParticle(self.castHandle, true)
    ParticleManager:ReleaseParticleIndex(self.castHandle)
    self.castHandle = nil
  end
end

-- GetAOERadius is not called on a Server at all?
function monkey_king_wukongs_command_custom:GetAOERadius()
  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("second_radius")
  local clone_attack_range = caster:Script_GetAttackRange()
  local talent_radius = 0
  local talent = caster:FindAbilityByName("special_bonus_unique_monkey_king_6_custom")
  if talent and talent:GetLevel() > 0 then
    talent_radius = talent:GetSpecialValueFor("value")
  end

  return math.max(talent_radius + clone_attack_range, radius + clone_attack_range)
end

function monkey_king_wukongs_command_custom:OnSpellStart()
  local caster = self:GetCaster()
  local center = self:GetCursorPosition()
  local clone_attack_range = caster:Script_GetAttackRange()

  local first_ring_radius = self:GetSpecialValueFor("first_radius")
  local second_ring_radius = self:GetSpecialValueFor("second_radius")
  local third_ring_radius = 0
  self.active_radius = second_ring_radius + clone_attack_range

  -- How many monkeys on each ring
  local first_ring = self:GetSpecialValueFor("num_first_soldiers")
  local second_ring = self:GetSpecialValueFor("num_second_soldiers")
  local third_ring = 0

  -- Extra ring talent
  local talent = caster:FindAbilityByName("special_bonus_unique_monkey_king_6_custom")
  if talent and talent:GetLevel() > 0 then
    third_ring_radius = talent:GetSpecialValueFor("value")
    third_ring = talent:GetSpecialValueFor("value2")
    self.active_radius = third_ring_radius + clone_attack_range
    if caster:HasScepter() then
      third_ring = self:GetSpecialValueFor("num_third_soldiers_scepter")
    end
  end

  -- Scepter extra monkeys
  if caster:HasScepter() then
    first_ring = self:GetSpecialValueFor("num_first_soldiers_scepter")
    second_ring = self:GetSpecialValueFor("num_second_soldiers_scepter")
  end

  -- Sound (EmitSoundOn doesn't respect fog of war)
  caster:EmitSound("Hero_MonkeyKing.FurArmy")

  local unit_name = "npc_dota_monkey_clone_custom"
  local spawn_interval = self:GetSpecialValueFor("ring_spawn_interval")
  local base_damage_percent = self:GetSpecialValueFor("base_damage_percent")

  -- Remove ability phase (cast) particle
  if self.castHandle then
    ParticleManager:DestroyParticle(self.castHandle, false)
    ParticleManager:ReleaseParticleIndex(self.castHandle)
    self.castHandle = nil
  end

  -- Remove previos instance of Wukongs Command
  if caster.monkeys_thinker and not caster.monkeys_thinker:IsNull() then
    caster.monkeys_thinker:Destroy()
  end

  -- Thinker
  CreateModifierThinker(caster, self, "modifier_wukongs_command_custom_thinker", {duration = self:GetSpecialValueFor("duration")}, center, caster:GetTeamNumber(), false)

  if self.clones == nil then
    print("[MONKEY KING WUKONG'S COMMAND] Clones/Soldiers were not created when Monkey King leveled up the spell for the first time!")
    self.clones = {}
    self.clones[1] = {}
    self.clones[2] = {}
    self.clones[3] = {}
  end

  -- Inner Ring:
  self:CreateMonkeyRing(unit_name, first_ring, caster, center, first_ring_radius, 1, base_damage_percent)
  -- Outer Ring:
  Timers:CreateTimer(spawn_interval, function()
    self:CreateMonkeyRing(unit_name, second_ring, caster, center, second_ring_radius, 2, base_damage_percent)
  end)
  -- Extra Ring with the talent:
  if talent and talent:GetLevel() > 0 then
    Timers:CreateTimer(2*spawn_interval, function()
      self:CreateMonkeyRing(unit_name, third_ring, caster, center, third_ring_radius, 3, base_damage_percent)
    end)
  end

  -- Remove monkeys if they were created while caster was dead or out of the circle
  local check_delay = spawn_interval + 1/30-- Change this if Monkey King has extra ring talent
  Timers:CreateTimer(check_delay, function()
    if not caster:IsAlive() or not caster:HasModifier("modifier_wukongs_command_custom_buff") then
      self:RemoveMonkeys(caster)
    end
  end)
end

function monkey_king_wukongs_command_custom:CreateMonkeyRing(unit_name, number, caster, center, radius, ringNumber, damage_pct)
  if number == 0 or radius <= 0 then
    return
  end

  if ringNumber ~= 1 and ((not caster:HasModifier("modifier_wukongs_command_custom_buff")) or (not caster:IsAlive())) then
    return
  end

  local damage_percent = damage_pct/100
  local top_direction = Vector(0,1,0)
  local top_point = center + top_direction*radius

  if self.clones[ringNumber]["top"] == nil or self.clones[ringNumber]["top"]:IsNull() or not self.clones[ringNumber]["top"]:IsAlive() then
    print("[MONKEY KING WUKONG'S COMMAND] Monkey on the top point doesn't exist for some reason!")
    self.clones[ringNumber]["top"] = CreateUnitByName(unit_name, top_point, false, caster, caster:GetOwner(), caster:GetTeam())
    self.clones[ringNumber]["top"]:SetOwner(caster)
  end
  local top_monkey = self.clones[ringNumber]["top"]
  -- setting the origin is causing a wierd visual glitch I could not fix
  top_monkey:SetAbsOrigin(GetGroundPosition(top_point, top_monkey))
  top_monkey:FaceTowards(center)
  top_monkey:RemoveNoDraw()
  top_monkey:SetBaseDamageMax(damage_percent*caster:GetAverageTrueAttackDamage(caster))
  top_monkey:SetBaseDamageMin(damage_percent*caster:GetAverageTrueAttackDamage(caster))
  top_monkey:AddNewModifier(caster, self, "modifier_monkey_clone_custom", {})
  top_monkey:RemoveModifierByName("modifier_monkey_clone_custom_hidden")
  
  local caster_boundless = caster:FindAbilityByName("monkey_king_boundless_strike_custom")
  if caster_boundless ~= nil and caster_boundless:GetLevel() > 0 then
    local caster_boundless_stacks = caster:FindAbilityByName("monkey_king_boundless_strike_stack_custom")
    if caster_boundless_stacks ~= nil and caster_boundless_stacks:GetLevel() > 0 then
      local top_monkey_boundless_stacks = top_monkey:AddAbility("monkey_king_boundless_strike_stack_custom")
      top_monkey_boundless_stacks:SetLevel(caster_boundless_stacks:GetLevel())
      top_monkey_boundless_stacks:SetHidden(true)
      local top_monkey_boundless_modifier = top_monkey:FindModifierByName("modifier_monkey_king_boundless_strike_stack_custom_buff_permanent")
      if top_monkey_boundless_modifier ~= nil then
        local caster_boundless_modifier = caster:FindModifierByName("modifier_monkey_king_boundless_strike_stack_custom_buff_permanent")
        if caster_boundless_modifier ~= nil then
          top_monkey_boundless_modifier:SetStackCount(caster_boundless_modifier:GetStackCount())
        end
      end
    end

    local top_monkey_boundless = top_monkey:AddAbility("monkey_king_boundless_strike_custom")
    top_monkey_boundless:SetLevel(caster_boundless:GetLevel())
    top_monkey_boundless:SetHidden(true)
  end

  -- Create remaining monkeys
  local angle_degrees = 360/number
  for i = 1, number-1 do
    -- Rotate a point around center for angle_degrees to get a new point
    local point = RotatePosition(center, QAngle(0,i*angle_degrees,0), top_point)
    if self.clones[ringNumber][i] == nil or self.clones[ringNumber][i]:IsNull() or not self.clones[ringNumber][i]:IsAlive() then
      print("[MONKEY KING WUKONG'S COMMAND] Monkey number "..i.."in ring "..ringNumber.." doesn't exist for some reason!")
      self.clones[ringNumber][i] = CreateUnitByName(unit_name, point, false, caster, caster:GetOwner(), caster:GetTeam())
      self.clones[ringNumber][i]:SetOwner(caster)
    end
    local monkey = self.clones[ringNumber][i]
    -- setting the origin is causing a wierd visual glitch I could not fix
    monkey:SetAbsOrigin(GetGroundPosition(point, monkey))
    monkey:FaceTowards(center)
    monkey:RemoveNoDraw()
    monkey:SetBaseDamageMax(damage_percent*caster:GetAverageTrueAttackDamage(caster))
    monkey:SetBaseDamageMin(damage_percent*caster:GetAverageTrueAttackDamage(caster))
    monkey:AddNewModifier(caster, self, "modifier_monkey_clone_custom", {})
    monkey:RemoveModifierByName("modifier_monkey_clone_custom_hidden")
    
    local caster_boundless = caster:FindAbilityByName("monkey_king_boundless_strike_custom")
    if caster_boundless ~= nil and caster_boundless:GetLevel() > 0 then
      local caster_boundless_stacks = caster:FindAbilityByName("monkey_king_boundless_strike_stack_custom")
      if caster_boundless_stacks ~= nil and caster_boundless_stacks:GetLevel() > 0 then
        local monkey_boundless_stacks = monkey:AddAbility("monkey_king_boundless_strike_stack_custom")
        monkey_boundless_stacks:SetLevel(caster_boundless_stacks:GetLevel())
        monkey_boundless_stacks:SetHidden(true)
        local monkey_boundless_modifier = monkey:FindModifierByName("modifier_monkey_king_boundless_strike_stack_custom_buff_permanent")
        if monkey_boundless_modifier ~= nil then
          local caster_boundless_modifier = caster:FindModifierByName("modifier_monkey_king_boundless_strike_stack_custom_buff_permanent")
          if caster_boundless_modifier ~= nil then
            monkey_boundless_modifier:SetStackCount(caster_boundless_modifier:GetStackCount())
          end
        end
      end

      local monkey_boundless = monkey:AddAbility("monkey_king_boundless_strike_custom")
      monkey_boundless:SetLevel(caster_boundless:GetLevel())
      monkey_boundless:SetHidden(true)
    end

  end
end

function monkey_king_wukongs_command_custom:RemoveMonkeys(caster)
  local unit_name = "npc_dota_monkey_clone_custom"
  -- Find all monkeys belonging to the caster on the map and hide them
  local allied_units = FindUnitsInRadius(
    caster:GetTeamNumber(),
    Vector(0, 0, 0),
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_BASIC,
    bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_ANY_ORDER,
    false
  )
  for _, unit in pairs(allied_units) do
    if unit and unit:GetUnitName() == unit_name then
      local handle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_fur_army_destroy.vpcf", PATTACH_ABSORIGIN, caster)
      ParticleManager:SetParticleControl(handle, 0, unit:GetAbsOrigin())
      Timers:CreateTimer(3, function()
        if handle then
          ParticleManager:DestroyParticle(handle, false)
          ParticleManager:ReleaseParticleIndex(handle)
        end
      end)
      unit:AddNoDraw()
      unit:SetAbsOrigin(Vector(-10000, -10000, -10000))
      unit:AddNewModifier(caster, self, "modifier_monkey_clone_custom_hidden", {})
      unit:RemoveAbility("monkey_king_boundless_strike_custom")
      unit:RemoveAbility("monkey_king_boundless_strike_stack_custom")
      unit:RemoveModifierByName("modifier_monkey_king_boundless_strike_stack_custom_buff_permanent")
      unit:RemoveModifierByName("modifier_monkey_clone_custom")
    end
  end

  -- Sounds
  caster:StopSound("Hero_MonkeyKing.FurArmy")
  caster:EmitSound("Hero_MonkeyKing.FurArmy.End")
end

function monkey_king_wukongs_command_custom:ProcsMagicStick()
  return true
end

-- Rubick creates lag when he steals and casts a spell
function monkey_king_wukongs_command_custom:IsStealable()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_wukongs_command_custom_thinker = class(ModifierBaseClass)

function modifier_wukongs_command_custom_thinker:IsHidden()
  return true
end

function modifier_wukongs_command_custom_thinker:IsDebuff()
  return false
end

function modifier_wukongs_command_custom_thinker:IsPurgable()
  return false
end

function modifier_wukongs_command_custom_thinker:IsAura()
  return true
end

function modifier_wukongs_command_custom_thinker:GetModifierAura()
  return "modifier_wukongs_command_custom_buff"
end

function modifier_wukongs_command_custom_thinker:GetAuraRadius()
  local ability = self:GetAbility()
  return ability.active_radius or ability:GetAOERadius()
end

function modifier_wukongs_command_custom_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_wukongs_command_custom_thinker:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_wukongs_command_custom_thinker:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_wukongs_command_custom_thinker:GetAuraEntityReject(hEntity)
  if hEntity ~= self:GetCaster() then
    return true
  end
  return false
end

function modifier_wukongs_command_custom_thinker:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
    }
end

if IsServer() then
  function modifier_wukongs_command_custom_thinker:OnCreated()
    local caster = self:GetCaster()

    -- Store this modifier on the caster
    caster.monkeys_thinker = self

    -- Ring particle
    self.particleHandler = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_furarmy_ring.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(self.particleHandler, 0, self:GetParent():GetOrigin())
    ParticleManager:SetParticleControl(self.particleHandler, 1, Vector(self:GetAuraRadius(), 0, 0))

    -- Start checking caster for the buff
    self:StartIntervalThink(0.1)
  end

  function modifier_wukongs_command_custom_thinker:OnIntervalThink()
    local caster = self:GetCaster()
    if not caster:HasModifier("modifier_wukongs_command_custom_buff") then
      self:StartIntervalThink(-1)
      self:SetDuration(0.01, false)
    end
  end

  function modifier_wukongs_command_custom_thinker:OnDeath(event)
    if event.unit == self:GetCaster() then
      self:StartIntervalThink(-1)
      self:SetDuration(0.01, false)
    end
  end

  function modifier_wukongs_command_custom_thinker:OnDestroy()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    ability:RemoveMonkeys(caster)

    if self.particleHandler then
      ParticleManager:DestroyParticle(self.particleHandler, false)
      ParticleManager:ReleaseParticleIndex(self.particleHandler)
    end

    -- Kill the thinker entity if it exists
    if parent and not parent:IsNull() then
      parent:ForceKill(false)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_wukongs_command_custom_buff = class(ModifierBaseClass)

function modifier_wukongs_command_custom_buff:IsHidden()
  return false
end

function modifier_wukongs_command_custom_buff:IsDebuff()
  return false
end

function modifier_wukongs_command_custom_buff:IsPurgable()
  return false
end

function modifier_wukongs_command_custom_buff:OnCreated()
  local caster = self:GetCaster()
  local armor = self:GetAbility():GetSpecialValueFor("bonus_armor")

  -- Talent that increases armor
  local talent = caster:FindAbilityByName("special_bonus_unique_monkey_king_4_custom")
  if talent and talent:GetLevel() > 0 then
    armor = armor + talent:GetSpecialValueFor("value")
  end

  self.armor = armor
end

function modifier_wukongs_command_custom_buff:OnRefresh()
  self:OnCreated()
end

function modifier_wukongs_command_custom_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_wukongs_command_custom_buff:GetModifierPhysicalArmorBonus()
  return self.armor
end

---------------------------------------------------------------------------------------------------

modifier_monkey_clone_custom = class(ModifierBaseClass)

function modifier_monkey_clone_custom:IsHidden()
  return true
end

function modifier_monkey_clone_custom:IsDebuff()
  return false
end

function modifier_monkey_clone_custom:IsPurgable()
  return false
end

function modifier_monkey_clone_custom:OnCreated()
  local parent = self:GetParent()

  if IsServer() then
    -- Don't unstuck to weird places
    parent:SetNeverMoveToClearSpace(true)

    -- Stop auto attacking everything
    parent:SetIdleAcquire(false)
    parent:SetAcquisitionRange(0)

    -- animation stances
    parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_monkey_clone_custom_idle_effect", {})
    --AddAnimationTranslate(parent, ACT_DOTA_ATTACK)

    self.cloneAPS = 1 / self:GetCaster():GetAttackCapability()

    if self.cloneAPS < 0.3 then
        self.cloneAPS = 0.3
    end

    if self.cloneAPS > 1 then
        self.cloneAPS = 1
    end

    -- Start attacking AI (which targets are allowed to be attacked)
    self:StartIntervalThink(0.1)
  end
end

function modifier_monkey_clone_custom:OnIntervalThink()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local caster = self:GetCaster()

  local function StopAttacking(unit)
    unit.target = nil
    unit:SetForceAttackTarget(nil)
    unit:SetIdleAcquire(false)
    unit:SetAcquisitionRange(0)
    unit:Interrupt()
    unit:Stop()
    unit:Hold()
  end

  if parent and not parent:IsNull() and parent:IsAlive() then
    local parent_position = parent:GetAbsOrigin()
    local search_radius = caster:Script_GetAttackRange() + parent:GetPaddedCollisionRadius() + 16  -- DOTA_HULL_SIZE_HERO is 24; DOTA_HULL_SIZE_SMALL is 8;

    -- Set monkey vision if it's better than 600 (possible only with massive attack range bonuses)
    if search_radius > parent:GetDayTimeVisionRange() then
      parent:SetDayTimeVisionRange(search_radius)
    end
    if search_radius > parent:GetNightTimeVisionRange() then
      parent:SetNightTimeVisionRange(search_radius)
    end

    if not parent.target or parent.target:IsNull() or not parent.target:IsAlive() then
      StopAttacking(parent)
    end

    if parent.target then
      local target_position = parent.target:GetAbsOrigin()
      local distance = (parent_position - target_position):Length2D()
      local real_target = parent:GetAttackTarget() or parent.target  -- GetAttackTarget is nil sometimes
      if parent.target:IsAttackImmune() or parent.target:IsInvulnerable() or (not real_target:IsHero()) or distance > search_radius or not caster:CanEntityBeSeenByMyTeam(real_target) then
        StopAttacking(parent)
      end
    else
      local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
      --if caster:HasScepter() then
        --target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
      --end
      local target_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE)
      local enemies = FindUnitsInRadius(caster:GetTeamNumber(), parent_position, nil, search_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, target_flags, FIND_CLOSEST, false)

      for _, enemy in ipairs(enemies) do
        if caster:CanEntityBeSeenByMyTeam(enemy) then
          parent.target = enemy
          break
        end
      end

      -- If target is found, enable auto-attacking of the parent and force him to attack found target
      -- SetAttacking doesn't work; SetAttackTarget doesn't exist; SetAggroTarget probably doesn't work too
      if parent.target then
        parent:SetIdleAcquire(false)
        parent:SetAcquisitionRange(0)

        ApplyDamage({
          victim = parent.target,
          attacker = self:GetCaster(),
          damage = 1,
          damage_type = DAMAGE_TYPE_PHYSICAL,
          damage_flags = DOTA_DAMAGE_FLAG_DONT_DISPLAY_DAMAGE_IF_SOURCE_HIDDEN,
        })

        local boundlessStrike = parent:FindAbilityByName("monkey_king_boundless_strike_custom")
        if boundlessStrike ~= nil and boundlessStrike:GetLevel() > 0 then
          if boundlessStrike:IsCooldownReady() then
            parent:SetForwardVector((parent.target:GetAbsOrigin() - parent:GetAbsOrigin()):Normalized())
            parent:StartGesture(ACT_DOTA_MK_STRIKE)
            Timers:CreateTimer(boundlessStrike:GetCastPoint(), function()
              if boundlessStrike ~= nil and not boundlessStrike:IsNull() then
                SpellCaster:Cast(boundlessStrike, parent.target)
              end
            end)
            boundlessStrike:StartCooldown(self.cloneAPS)
          end
        else
          parent:SetIdleAcquire(true)
          parent:SetAcquisitionRange(search_radius)
          parent:SetForceAttackTarget(parent.target)
        end
      end
    end
  end
end

function modifier_monkey_clone_custom:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_FIXED_ATTACK_RATE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_START,
  }
end

if IsServer() then
  -- Trying to match attack range of clones with caster's attack range
  function modifier_monkey_clone_custom:GetModifierAttackRangeBonus()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    if parent == caster then
      return 0
    end
    local caster_attack_range = caster:Script_GetAttackRange()
    if self.check_attack_range then
      return 0
    else
      self.check_attack_range = true
      local parent_attack_range = parent:Script_GetAttackRange()
      self.check_attack_range = false
      if caster_attack_range > parent_attack_range then
        return caster_attack_range - parent_attack_range
      end
    end
    return 0
  end
end

function modifier_monkey_clone_custom:GetStatusEffectName()
  return "particles/status_fx/status_effect_monkey_king_fur_army.vpcf"
end

function modifier_monkey_clone_custom:GetModifierFixedAttackRate(params)
  local ability = self:GetAbility()
  return ability:GetSpecialValueFor("attack_interval")
end

if IsServer() then
  function modifier_monkey_clone_custom:OnAttackStart(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    local ability = self:GetAbility()
    local attack_interval = ability:GetSpecialValueFor("attack_interval")
    local attack_backswing = 0.2 -- same as the Monkey King hero
    parent:AddNewModifier(self:GetCaster(), ability, "modifier_monkey_clone_custom_status_effect", {duration = attack_backswing + attack_interval})
    parent:RemoveModifierByName("modifier_monkey_clone_custom_idle_effect")
  end

  function modifier_monkey_clone_custom:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Attack particle
    local castHandle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_fur_army_attack.vpcf", PATTACH_ABSORIGIN, parent)

    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("proc_chance")

    -- Talent that increases proc chance
    local talent = caster:FindAbilityByName("special_bonus_unique_monkey_king_1_custom")
    if talent and talent:GetLevel() > 0 then
      chance = chance + talent:GetSpecialValueFor("value")
    end

    chance = chance / 100

    if not parent.failure_count then
      parent.failure_count = 0
    end

    -- Proccing caster's attack on a clone
    --[[local pseudo_rng_mult = parent.failure_count + 1
    if RandomFloat( 0.0, 1.0 ) <= ( PrdCFinder:GetCForP(chance) * pseudo_rng_mult ) then
      -- Reset failure count
      parent.failure_count = 0
      -- Apply no-lifesteal modifier
      local mod = caster:AddNewModifier(caster, ability, "modifier_wukongs_command_custom_no_lifesteal", {})
      -- Apply caster's attack that cannot miss
      caster:PerformAttack(target, true, true, true, false, false, false, true)
      -- Remove no-lifesteal modifier
      mod:Destroy()
    else
      -- Increment failure count
      parent.failure_count = pseudo_rng_mult
    end
    --]]

    Timers:CreateTimer(1.5, function()
      if castHandle then
        ParticleManager:DestroyParticle(castHandle, false)
        ParticleManager:ReleaseParticleIndex(castHandle)
      end
    end)
  end
end

function modifier_monkey_clone_custom:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_SILENCED] = true,
    [MODIFIER_STATE_MUTED] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_monkey_clone_custom_status_effect = class(ModifierBaseClass)

function modifier_monkey_clone_custom_status_effect:IsHidden()
  return true
end

function modifier_monkey_clone_custom_status_effect:IsPurgable()
  return false
end

function modifier_monkey_clone_custom_status_effect:GetStatusEffectName()
  return "particles/status_fx/status_effect_monkey_king_spring_slow.vpcf"
end

function modifier_monkey_clone_custom_status_effect:StatusEffectPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

if IsServer() then
  function modifier_monkey_clone_custom_status_effect:OnDestroy()
    self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_monkey_clone_custom_idle_effect", {})
  end
end

---------------------------------------------------------------------------------------------------

modifier_monkey_clone_custom_idle_effect = class(ModifierBaseClass)

function modifier_monkey_clone_custom_idle_effect:IsHidden()
  return true
end

function modifier_monkey_clone_custom_idle_effect:IsPurgable()
  return false
end

function modifier_monkey_clone_custom_idle_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
  }
end

function modifier_monkey_clone_custom_idle_effect:GetActivityTranslationModifiers()
  return "fur_army_soldier"
end

---------------------------------------------------------------------------------------------------

modifier_monkey_clone_custom_hidden = class(ModifierBaseClass)

function modifier_monkey_clone_custom_hidden:IsHidden()
  return true
end

function modifier_monkey_clone_custom_hidden:IsDebuff()
  return false
end

function modifier_monkey_clone_custom_hidden:IsPurgable()
  return false
end

function modifier_monkey_clone_custom_hidden:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_SILENCED] = true,
    [MODIFIER_STATE_MUTED] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_BLIND] = true,
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_wukongs_command_custom_no_lifesteal = class(ModifierBaseClass)

function modifier_wukongs_command_custom_no_lifesteal:IsHidden()
  return true
end

function modifier_wukongs_command_custom_no_lifesteal:IsDebuff()
  return false
end

function modifier_wukongs_command_custom_no_lifesteal:IsPurgable()
  return false
end

function modifier_wukongs_command_custom_no_lifesteal:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_wukongs_command_custom_no_lifesteal:GetModifierLifestealRegenAmplify_Percentage()
  return -200
end
