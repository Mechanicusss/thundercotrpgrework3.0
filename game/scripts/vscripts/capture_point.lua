--[[
    Licensed under MIT by https://github.com/OpenAngelArena/oaa
    All thanks and credits for code and particle effects go to the developers of OAA at https://github.com/OpenAngelArena/oaa
    Thank you!
]]--
capture_point = capture_point or class({})

LinkLuaModifier("modifier_capture_point", "capture_point.lua", LUA_MODIFIER_MOTION_NONE)

modifier_capture_point = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

function capture_point:Init()
    local CPEntity = Entities:FindByName(nil, "capture_point")
    if CPEntity == nil then
        print("[ERROR] Could not find capture point entity.")
        return
    end

    local pos = CPEntity:GetOrigin()

    CreateUnitByNameAsync("outpost_placeholder_unit", pos, false, CPEntity, CPEntity, DOTA_TEAM_NEUTRALS, function(emitter)
        emitter:AddNewModifier(emitter, nil, "modifier_capture_point", {})
    end)
end
--------------
function modifier_capture_point:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }   

    return state
end

function modifier_capture_point:OnCreated()
    if not IsServer() then return end

    self.capturingTeam = nil
    self.captureProgress = 0
    self.captureTime = PVP_CP_CAPTURE_TIME -- Time to capture
    self.radius = 400
    self.thinkInterval = 0.02
    self.gracePeriod = PVP_CP_HOLD_TIME -- How long the CP can't be captured when it has been captured
    self.allowCapture = true
    self.resetTimer = nil
    self.playCaptureSound = true
    self.captureSoundTimer = nil

    self:OnRefresh()

    self:StartIntervalThink(self.thinkInterval)
end

function modifier_capture_point:OnRefresh()
    if not IsServer() then return end

    self.captureRingEffect = ParticleManager:CreateParticle("particles/capture_point_ring/capture_point_ring.vpcf", PATTACH_ABSORIGIN, self:GetParent())
        
    -- Particle colour
    ParticleManager:SetParticleControl(self.captureRingEffect, 3, self:GetColor())

    -- Ring radius
    ParticleManager:SetParticleControl(self.captureRingEffect, 9, Vector(self.radius, 0, 0))

    EmitSoundOn("Outpost.Captured.Notification", self:GetParent())
end

function modifier_capture_point:GetColor()
  local neutralColor = Vector(160, 240, 160)
  local radiantColor = Vector(0, 148, 190)
  local direColor = Vector(225, 40, 0)
  local endColor
  if self.capturingTeam == DOTA_TEAM_GOODGUYS then
    endColor = radiantColor
  elseif self.capturingTeam == DOTA_TEAM_BADGUYS then
    endColor = direColor
  else
    endColor = neutralColor
  end
  return SplineVectors(neutralColor, endColor, (self.captureProgress / self.captureTime) ^ (1/5))
end

function modifier_capture_point:OnIntervalThink()
  if not self.allowCapture then return end

  local parent = self:GetParent()
  local radiantUnits = FindUnitsInRadius(
    DOTA_TEAM_GOODGUYS,
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO),
    FIND_ANY_ORDER,
    false
  )
  local direUnits = FindUnitsInRadius(
    DOTA_TEAM_BADGUYS,
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO),
    FIND_ANY_ORDER,
    false
  )

  -- Remove heroes with Wraith King buff, Meepo Clones and Arc Warden Tempest Doubles
  local function filter_heroes(heroes)
    for k, v in pairs(heroes) do
      local hero_to_test = heroes[k]
      if hero_to_test then
        if hero_to_test:HasModifier("modifier_skeleton_king_reincarnation_scepter_active") or hero_to_test:IsClone() or hero_to_test:IsTempestDouble() then
          table.remove(heroes, k)
        end
      end
    end
  end

  filter_heroes(radiantUnits)
  filter_heroes(direUnits)

  local captureTick
  local heroMultiplierTable = {
    1,
    1.11,
    1.25,
    1.42,
    1.66
  }
  local numHeroes = 1

  -- Start capturing from neutral
  if radiantUnits[1] and self.capturingTeam == nil then
    self.capturingTeam = DOTA_TEAM_GOODGUYS
  elseif direUnits[1] and self.capturingTeam == nil then
    self.capturingTeam = DOTA_TEAM_BADGUYS
  end

  if radiantUnits[1] and direUnits[1] then
    -- Point is being contested, halt progress
    captureTick = 0
  elseif not radiantUnits[1] and not direUnits[1] then
    -- Point is empty, reverse progress at half speed
    captureTick = -self.thinkInterval / 2
  elseif (radiantUnits[1] and self.capturingTeam ~= DOTA_TEAM_GOODGUYS) or (direUnits[1] and self.capturingTeam ~= DOTA_TEAM_BADGUYS) then
    -- Point has switched capturing team, reverse progress at 1.5 times speed
    captureTick = -self.thinkInterval * 1.5
    if self.capturingTeam == DOTA_TEAM_GOODGUYS then
      numHeroes = #direUnits
    elseif self.capturingTeam == DOTA_TEAM_BADGUYS then
      numHeroes = #radiantUnits
    end
  else
    -- Point is being captured by a team
    captureTick = self.thinkInterval
    if self.capturingTeam == DOTA_TEAM_GOODGUYS then
      numHeroes = #radiantUnits
    elseif self.capturingTeam == DOTA_TEAM_BADGUYS then
      numHeroes = #direUnits
    end
  end
  captureTick = captureTick * heroMultiplierTable[math.min(#heroMultiplierTable, numHeroes)]
  self.captureProgress = min(self.captureTime, max(0, self.captureProgress + captureTick))

  if self.playCaptureSound == true and self.capturingTeam ~= nil then
    EmitSoundOn("Conquest.capture_point_timer", self:GetParent())
    self.playCaptureSound = false

    if self.captureSoundTimer == nil then
        self.captureSoundTimer = Timers:CreateTimer(1.0, function()
            self.playCaptureSound = true
            self.captureSoundTimer = nil
            return 1.0
        end)
    end
  end

  if self.captureProgress == 0 then
    self.capturingTeam = nil
  end

  if captureTick > 0 then
    self:StartInProgressParticle()
  else
    self:DestroyParticleByName("captureInProgressEffect")
  end

  if self.capturingTeam then
    self:StartClockParticle()
    -- Set the orientation of the clock hand based on progress
    local theta = self.captureProgress / self.captureTime * 2 * math.pi
    ParticleManager:SetParticleControlForward(self.captureClockEffect, 1, Vector(math.cos(theta), math.sin(theta), 0))
  else
    self:DestroyParticleByName("captureClockEffect")
  end
  -- Update ring color
  ParticleManager:SetParticleControl(self.captureRingEffect, 3, self:GetColor())

  if self.captureProgress == self.captureTime then
    -- Point has been captured
    -- Give essence reward to the ones capturing --
    _G.CPCaptures = _G.CPCaptures + 1

    if _G.CPCaptures >= PVP_CP_AKASHA_CAPTURES then
      boss_queen_of_pain:Spawn("boss_queen_of_pain")
      self:StartIntervalThink(-1) -- Stop thinking first so that we don't accidentally finish twice
      self:DestroyParticleByName("captureRingEffect")
      self:DestroyParticleByName("captureInProgressEffect")
      self:DestroyParticleByName("captureClockEffect")
      self:Destroy()
      return
    end

    local itemPoolHeroes
    if self.capturingTeam == DOTA_TEAM_GOODGUYS then
      itemPoolHeroes = radiantUnits
    elseif self.capturingTeam == DOTA_TEAM_BADGUYS then
      itemPoolHeroes = direUnits
    end

    for _,hero in ipairs(itemPoolHeroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsTempestDouble() and PlayerResource:GetConnectionState(hero:GetPlayerID()) ~= DOTA_CONNECTION_STATE_ABANDONED then
            hero:AddItemByName("item_charged_essence")
            if RollPercentage(20) then
              if RollPercentage(50) then
                hero:AddItemByName("item_enchanted_book")
              else
                hero:AddItemByName("item_blessed_book")
              end
            end
        end
    end
    --

    self.capturingTeam = nil
    self.captureProgress = 0
    self.allowCapture = false

    self:DestroyParticleByName("captureRingEffect")
    self:DestroyParticleByName("captureInProgressEffect")
    self:DestroyParticleByName("captureClockEffect")

    EmitSoundOn("Outpost.Captured", self:GetParent())
    
    if self.resetTimer == nil then
        self.resetTimer = Timers:CreateTimer(self.gracePeriod, function()
            self:OnRefresh() -- This creates the ring effect again

            self.allowCapture = true
            self.resetTimer = nil
        end)
    end
  end
end

function modifier_capture_point:DestroyParticleByName(particleName)
  local particleIndex = self[particleName]
  if particleIndex then
    ParticleManager:DestroyParticle(particleIndex, false)
    ParticleManager:ReleaseParticleIndex(particleIndex)
    self[particleName] = nil
  end
end

function modifier_capture_point:StartInProgressParticle()
  if not self.captureInProgressEffect then
    self.captureInProgressEffect = ParticleManager:CreateParticle("particles/capture_point_ring/capture_point_ring_capturing.vpcf", PATTACH_ABSORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.captureInProgressEffect, 9, Vector(self.radius, 0, 0))
  end
  ParticleManager:SetParticleControl(self.captureInProgressEffect, 3, self:GetColor())
end

function modifier_capture_point:StartClockParticle()
  if not self.captureClockEffect then
    self.captureClockEffect = ParticleManager:CreateParticle("particles/capture_point_ring/capture_point_ring_clock.vpcf", PATTACH_ABSORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.captureClockEffect, 9, Vector(self.radius, 0, 0))
    -- Controls how much of the dial to spawn. 1 is the full circle
    ParticleManager:SetParticleControl(self.captureClockEffect, 11, Vector(0, 0, 1))
  end
  ParticleManager:SetParticleControl(self.captureClockEffect, 3, self:GetColor())
end