require( "heroes/bosses/aghanim/boss_base" )

--------------------------------------------------------------------------------

if CBossAghanim == nil then
    CBossAghanim = class( {}, {}, CBossBase )
end

--------------------------------------------------------------------------------

function Precache( context )
end

--------------------------------------------------------------------------------

function Spawn( entityKeyValues )
    if IsServer() then
        if thisEntity == nil then
            return
        end
        thisEntity.AI = CBossAghanim( thisEntity, 1.0 )
    end
end

--------------------------------------------------------------------------------

function CBossAghanim:constructor( hUnit, flInterval )
    CBossBase.constructor( self, hUnit, flInterval )

    self.bDefeated = false

    self.ATTACKS_BETWEEN_TELEPORT = 2
    self.ENRAGE_LESS_ATTACKS_BETWEEN_TELEPORT = 1
    self.nCurrentAttacksBetweenTeleport = self.ATTACKS_BETWEEN_TELEPORT
    
    self.PHASE_CRYSTAL_ATTACK = 1
    self.PHASE_STAFF_BEAMS = 2
    self.PHASE_SUMMON_PORTALS = 3
    self.PHASE_SPELL_SWAP = 4
    self.PHASE_SHARD_ATTACK = 5
    self.PHASE_SCYTHE_ATTACK = 6
    self.PHASE_LIFE_DRAIN = 7
    self.PHASE_MYSTIC_FLARE = 8
    self.PHASE_ILLUSORY_ORB = 9

    self.nLevelUpPct = 50
    self.bHasLeveledUp = false

    self.bSpellSwapEnabled = false
    self.bShardAttackEnabled = false
    self.bStaffBeamsEnabled = false
    self.bSummonPortalsEnabled = false
    self.bCrystalAttackEnabled = false
    self.bScytheAttackEnabled = false
    self.bLifeDrainEnabled = false
    self.bMysticFlareEnabled = false
    self.bIllusoryOrbEnabled = false

    -- Trigger percentages --
    self.nCrystalAttackPct = 100
    self.nShardAttackPct = 95
    self.nMysticFlarePct = 88
    self.nSummonPortalsPct = 75
    self.nSpellSwapPct = 70
    self.nIllusoryOrbPct = 65
    self.nStaffBeamsPct = 50
    self.nLifeDrainPct = 44
    self.nScytheAttackPct = 33
    
    self.AllowedPhases = 
    {
        self.PHASE_CRYSTAL_ATTACK, -- This is what he begins with, rest is unlocked as his health drops
    }

    self.flInitialAcquireRange = 1800
    self.flAggroAcquireRange = 1800
    self.nPhaseIndex = 1
    self.nNumAttacksBeforeTeleport = self.nCurrentAttacksBetweenTeleport
    self.bReturnHome = true
    self.vLastBlinkLocation = Vector( -3328, 3264, 0 )

    self.me:SetThink( "OnBossAghanimThink", self, "OnBossAghanimThink", self.flDefaultInterval )
end

--------------------------------------------------------------------------------

function CBossAghanim:GetCurrentPhase()
    return self.AllowedPhases[ self.nPhaseIndex ]
end

--------------------------------------------------------------------------------


function CBossAghanim:SetEncounter( hEncounter )
    CBossBase.SetEncounter( self, hEncounter )
end

--------------------------------------------------------------------------------

function CBossAghanim:SetupAbilitiesAndItems()
    CBossBase.SetupAbilitiesAndItems( self )

    self.TeleportPositions = {}

    local TeleportPositions = Entities:FindAllByName("teleport_position")
    for _,hEnt in pairs ( TeleportPositions ) do
        table.insert( self.TeleportPositions, hEnt:GetAbsOrigin() )
    end

    local TeleportPositionMain = Entities:FindAllByName("teleport_position_main")
    if #TeleportPositionMain > 0 then
        self.TeleportPositionMain = TeleportPositionMain[1]
        self.me.vHomePosition = self.TeleportPositionMain:GetAbsOrigin()
        
        table.insert( self.TeleportPositions, self.me.vHomePosition )
    end

    self.hBlink = self.me:FindAbilityByName( "aghanim_blink" )
    if self.hBlink ~= nil then
        self.hBlink.Evaluate = self.EvaluateBlink
        self.AbilityPriority[ self.hBlink:GetAbilityName() ] = 1
    end
    
    self.hCrystalAttack = self.me:FindAbilityByName( "aghanim_crystal_attack" )
    if self.hCrystalAttack ~= nil then
        self.hCrystalAttack.nCrystalAttackPhase = 1 
        self.hCrystalAttack.hLastCrystalTarget = nil
        self.hCrystalAttack.Evaluate = self.EvaluateCrystalAttack
        self.AbilityPriority[ self.hCrystalAttack:GetAbilityName() ] = 3
    end

    self.hStaffBeams = self.me:FindAbilityByName( "aghanim_staff_beams" )
    if self.hStaffBeams ~= nil then
        self.hStaffBeams.Evaluate = self.EvaluateStaffBeams
        self.AbilityPriority[ self.hStaffBeams:GetAbilityName() ] = 3
    end

    self.hSummonPortals = self.me:FindAbilityByName( "aghanim_summon_portals" )
    if self.hSummonPortals ~= nil then
        self.hSummonPortals.Evaluate = self.EvaluateSummonPortals
        self.AbilityPriority[ self.hSummonPortals:GetAbilityName() ] = 3
    end

    self.hSpellSwap = self.me:FindAbilityByName( "aghanim_spell_swap" )
    if self.hSpellSwap ~= nil then
        self.hSpellSwap.Evaluate = self.EvaluateSpellSwap
        self.AbilityPriority[ self.hSpellSwap:GetAbilityName() ] = 4
    end

    self.hShardAttack = self.me:FindAbilityByName( "aghanim_shard_attack" )
    if self.hShardAttack ~= nil then
        self.hShardAttack.Evaluate = self.EvaluateShardAttack
        self.AbilityPriority[ self.hShardAttack:GetAbilityName() ] = 2
    end

    self.hScytheAttack = self.me:FindAbilityByName( "aghanim_scythe_attack" )
    if self.hScytheAttack ~= nil then
        self.hScytheAttack.Evaluate = self.EvaluateScytheAttack
        self.AbilityPriority[ self.hScytheAttack:GetAbilityName() ] = 3
    end

    self.hLifeDrain = self.me:FindAbilityByName( "aghanim_life_drain" )
    if self.hLifeDrain ~= nil then
        self.hLifeDrain.Evaluate = self.EvaluateLifeDrain
        self.AbilityPriority[ self.hLifeDrain:GetAbilityName() ] = 3
    end

    self.hMysticFlare = self.me:FindAbilityByName( "aghanim_mystic_flare" )
    if self.hMysticFlare ~= nil then
        self.hMysticFlare.Evaluate = self.EvaluateMysticFlare
        self.AbilityPriority[ self.hMysticFlare:GetAbilityName() ] = 3
    end

    self.hIllusoryOrb = self.me:FindAbilityByName( "aghanim_illusory_orb" )
    if self.hIllusoryOrb ~= nil then
        self.hIllusoryOrb.Evaluate = self.EvaluateIllusoryOrb
        self.AbilityPriority[ self.hIllusoryOrb:GetAbilityName() ] = 3
    end
end
--------------------------------------------------------------------------------
 
function CBossAghanim:OnBossAghanimThink()
    if self.bDefeated then
        return -1
    end
    
    if IsServer() and thisEntity:HasModifier("modifier_aghsfort_slark_pounce_leash") then
        thisEntity:RemoveModifierByName("modifier_aghsfort_slark_pounce_leash")
    end

    return self:OnBaseThink()
end

--------------------------------------------------------------------------------

function CBossAghanim:OnFirstSeen()
    CBossBase.OnFirstSeen( self )
end

--------------------------------------------------------------------------------

function CBossAghanim:ChangePhase()
    self.nNumAttacksBeforeTeleport = self.nNumAttacksBeforeTeleport - 1
    --print ( "Aghanim is changing phase! old:" .. self:GetCurrentPhase() )
    if self.nPhaseIndex == #self.AllowedPhases then
        self.nPhaseIndex = 1
    else
        self.nPhaseIndex = self.nPhaseIndex + 1
    end

    self.nPhase = self.AllowedPhases[ self.nPhaseIndex ]
    if self.nPhase == self.PHASE_SHARD_ATTACK then
        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end
end

--------------------------------------------------------------------------------

function CBossAghanim:OnHealthPercentThreshold( nPct )
    CBossBase.OnHealthPercentThreshold( self, nPct )

    if self.bHasLeveledUp then
        self.me:Purge(false, true, false, true, false)

        self.AllowedPhases = 
        {
            self.PHASE_SHARD_ATTACK,
            self.PHASE_STAFF_BEAMS,
            self.PHASE_CRYSTAL_ATTACK,
            self.PHASE_SPELL_SWAP,
            self.PHASE_SUMMON_PORTALS,
            self.PHASE_MYSTIC_FLARE,
            self.PHASE_ILLUSORY_ORB,
        }

        local randomPhase = self.AllowedPhases[RandomInt(1, #self.AllowedPhases)]
        self.nPhaseIndex = randomPhase
        self:ChangePhase()

        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end

    --[[
    if nPct < self.nSpellSwapPct and self.bSpellSwapEnabled == false then
        self.me:Purge(false, true, false, true, false)

        self.nCurrentAttacksBetweenTeleport = math.max( 1, self.nCurrentAttacksBetweenTeleport - self.ENRAGE_LESS_ATTACKS_BETWEEN_TELEPORT )
        self.bSpellSwapEnabled = true
        self.AllowedPhases = 
        {
            self.PHASE_SPELL_SWAP,
            self.PHASE_SUMMON_PORTALS,
            self.PHASE_CRYSTAL_ATTACK,
            self.PHASE_SHARD_ATTACK,
            self.PHASE_MYSTIC_FLARE,
        }

        self.nPhaseIndex = #self.AllowedPhases
        self:ChangePhase()

        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end
    --]]

    if nPct < self.nLevelUpPct and self.bHasLeveledUp == false then
        self.bHasLeveledUp = true
        self.me:CreatureLevelUp( 1 )
        --GameRules:SendCustomMessage("<font color='blue'>Aghanim has grown tired of your games and empowers himself.</font>", 0, 0)
    end
    

    if nPct < self.nShardAttackPct and self.bShardAttackEnabled == false then
        self.me:Purge(false, true, false, true, false)

        self.nCurrentAttacksBetweenTeleport = math.max( 1, self.nCurrentAttacksBetweenTeleport - self.ENRAGE_LESS_ATTACKS_BETWEEN_TELEPORT )
        self.bShardAttackEnabled = true
        self.AllowedPhases = 
        {
            self.PHASE_SHARD_ATTACK,
            self.PHASE_CRYSTAL_ATTACK,
        }

        self.nPhaseIndex = #self.AllowedPhases
        self:ChangePhase()

        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end

    if nPct < self.nStaffBeamsPct and self.bStaffBeamsEnabled == false then
        self.me:Purge(false, true, false, true, false)

        self.nCurrentAttacksBetweenTeleport = math.max( 1, self.nCurrentAttacksBetweenTeleport - self.ENRAGE_LESS_ATTACKS_BETWEEN_TELEPORT )
        self.bStaffBeamsEnabled = true
        self.AllowedPhases = 
        {
            self.PHASE_STAFF_BEAMS,
            self.PHASE_CRYSTAL_ATTACK,
            self.PHASE_SPELL_SWAP,
            self.PHASE_SUMMON_PORTALS,
            self.PHASE_SHARD_ATTACK,
            self.PHASE_MYSTIC_FLARE,
            self.PHASE_ILLUSORY_ORB,
        }

        self.nPhaseIndex = #self.AllowedPhases
        self:ChangePhase()

        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end

    if nPct < self.nSummonPortalsPct and self.bSummonPortalsEnabled == false then
        self.me:Purge(false, true, false, true, false)

        self.nCurrentAttacksBetweenTeleport = math.max( 1, self.nCurrentAttacksBetweenTeleport - self.ENRAGE_LESS_ATTACKS_BETWEEN_TELEPORT )
        self.bSummonPortalsEnabled = true
        self.AllowedPhases = 
        {
            self.PHASE_SUMMON_PORTALS,
            self.PHASE_SHARD_ATTACK,
            self.PHASE_CRYSTAL_ATTACK,
            self.PHASE_MYSTIC_FLARE,
        }

        self.nPhaseIndex = #self.AllowedPhases
        self:ChangePhase()

        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end

    if nPct < self.nCrystalAttackPct and self.bCrystalAttackEnabled == false then
        self.me:Purge(false, true, false, true, false)

        self.nCurrentAttacksBetweenTeleport = math.max( 1, self.nCurrentAttacksBetweenTeleport - self.ENRAGE_LESS_ATTACKS_BETWEEN_TELEPORT )

        self.bCrystalAttackEnabled = true
        self.AllowedPhases = 
        {
            self.PHASE_CRYSTAL_ATTACK,
        }

        self.nPhaseIndex = #self.AllowedPhases
        self:ChangePhase()

        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end

    if nPct < self.nScytheAttackPct and self.bScytheAttackEnabled == false then
        self.me:Purge(false, true, false, true, false)

        self.nCurrentAttacksBetweenTeleport = math.max( 1, self.nCurrentAttacksBetweenTeleport - self.ENRAGE_LESS_ATTACKS_BETWEEN_TELEPORT )

        self.bScytheAttackEnabled = true
        self.AllowedPhases = 
        {
            self.PHASE_SCYTHE_ATTACK,
            self.PHASE_SUMMON_PORTALS,
            self.PHASE_SHARD_ATTACK,
            self.PHASE_STAFF_BEAMS,
            self.PHASE_SPELL_SWAP,
            self.PHASE_CRYSTAL_ATTACK,
            self.PHASE_LIFE_DRAIN,
            self.PHASE_MYSTIC_FLARE,
            self.PHASE_ILLUSORY_ORB,
        }

        self.nPhaseIndex = #self.AllowedPhases
        self:ChangePhase()

        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end

    if nPct < self.nLifeDrainPct and self.bLifeDrainEnabled == false then
        self.me:Purge(false, true, false, true, false)

        self.nCurrentAttacksBetweenTeleport = math.max( 1, self.nCurrentAttacksBetweenTeleport - self.ENRAGE_LESS_ATTACKS_BETWEEN_TELEPORT )

        self.bLifeDrainEnabled = true
        self.AllowedPhases = 
        {
            self.PHASE_LIFE_DRAIN,
            self.PHASE_SUMMON_PORTALS,
            self.PHASE_SHARD_ATTACK,
            self.PHASE_STAFF_BEAMS,
            self.PHASE_SPELL_SWAP,
            self.PHASE_CRYSTAL_ATTACK,
            self.PHASE_MYSTIC_FLARE,
            self.PHASE_ILLUSORY_ORB,
        }

        self.nPhaseIndex = #self.AllowedPhases
        self:ChangePhase()

        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end

    if nPct < self.nMysticFlarePct and self.bMysticFlareEnabled == false then
        self.me:Purge(false, true, false, true, false)

        self.nCurrentAttacksBetweenTeleport = math.max( 1, self.nCurrentAttacksBetweenTeleport - self.ENRAGE_LESS_ATTACKS_BETWEEN_TELEPORT )

        self.bMysticFlareEnabled = true
        self.AllowedPhases = 
        {
            self.PHASE_MYSTIC_FLARE,
            self.PHASE_SHARD_ATTACK,
            self.PHASE_CRYSTAL_ATTACK,
        }

        self.nPhaseIndex = #self.AllowedPhases
        self:ChangePhase()

        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end

    if nPct < self.nIllusoryOrbPct and self.bIllusoryOrbEnabled == false then
        self.me:Purge(false, true, false, true, false)

        self.nCurrentAttacksBetweenTeleport = math.max( 1, self.nCurrentAttacksBetweenTeleport - self.ENRAGE_LESS_ATTACKS_BETWEEN_TELEPORT )

        self.bIllusoryOrbEnabled = true
        self.AllowedPhases = 
        {
            self.PHASE_ILLUSORY_ORB,
            self.PHASE_SUMMON_PORTALS,
            self.PHASE_SHARD_ATTACK,
            self.PHASE_SPELL_SWAP,
            self.PHASE_CRYSTAL_ATTACK,
            self.PHASE_MYSTIC_FLARE,
        }

        self.nPhaseIndex = #self.AllowedPhases
        self:ChangePhase()

        self.nNumAttacksBeforeTeleport = 0
        self.bReturnHome = true
    end
end

--------------------------------------------------------------------------------

function CBossAghanim:EvaluateCrystalAttack()
    if self:GetCurrentPhase() ~= self.PHASE_CRYSTAL_ATTACK then
        return nil
    end

    local Enemies = shallowcopy( self.hPlayerHeroes )
    local Order = nil
    if Enemies == nil or #Enemies == 0 then
        return Order
    end

    Order = 
    {
        UnitIndex = self.me:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = Enemies[ #Enemies ]:GetAbsOrigin(),
        AbilityIndex = self.hCrystalAttack:entindex(),
        Queue = false,
    }
    Order.flOrderInterval = GetSpellCastTime( self.hCrystalAttack )
    self.hCrystalAttack.hLastCrystalTarget = Enemies[#Enemies]
    
    return Order
end

--------------------------------------------------------------------------------

function CBossAghanim:EvaluateStaffBeams()
    if self:GetCurrentPhase() ~= self.PHASE_STAFF_BEAMS then
        return nil
    end

    local vTargetPos = self.me.vHomePosition 
    if vTargetPos == self.vLastBlinkLocation then
        local hEnemies = GetEnemyHeroesInRange( self.me, 5000 )
        if #hEnemies > 0 then
            vTargetPos = hEnemies[#hEnemies]:GetAbsOrigin()
        end
    end

    local Order = nil
    Order = 
    {
        UnitIndex = self.me:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = vTargetPos,
        AbilityIndex = self.hStaffBeams:entindex(),
        Queue = false,
    }
    Order.flOrderInterval = GetSpellCastTime( self.hStaffBeams ) + self.hStaffBeams:GetChannelTime()
    
    return Order
end


--------------------------------------------------------------------------------

function CBossAghanim:EvaluateBlink()
    if IsServer() and thisEntity:HasModifier("modifier_aghsfort_slark_pounce_leash") then
        thisEntity:RemoveModifierByName("modifier_aghsfort_slark_pounce_leash")
    end
    
    if self.nNumAttacksBeforeTeleport > 0 then
        return nil
    end

    if self.bReturnHome == true and self.vLastBlinkLocation == self.me.vHomePosition then
        self.nNumAttacksBeforeTeleport = self.nCurrentAttacksBetweenTeleport
        self.bReturnHome = false
        return nil
    end

    local vTeleportLocations = shallowcopy( self.TeleportPositions )
    for k,v in pairs ( vTeleportLocations ) do
        if v == self.vLastBlinkLocation then
            table.remove( vTeleportLocations, k )
            break
        end
    end

    local vPos = nil
    if self.bReturnHome == true then
        vPos = self.me.vHomePosition
    else
        if self:GetCurrentPhase() == self.PHASE_SUMMON_PORTALS then
            local hEnemies = GetEnemyHeroesInRange( self.me, 5000 )
            if #hEnemies > 0 then
                local vFarthestEnemyPos = hEnemies[#hEnemies]:GetAbsOrigin()
                local vClosestPosToEnemy = nil
                local flShortestDist = 99999
                for _,vTeleportPos in pairs ( vTeleportLocations ) do
                    local flDistToEnemy = ( vTeleportPos - vFarthestEnemyPos ):Length2D()
                    if flDistToEnemy < flShortestDist then
                        flShortestDist = flDistToEnemy
                        vClosestPosToEnemy = vTeleportPos
                    end
                end

                if vTeleportPos ~= nil then
                    vPos = vClosestPosToEnemy
                end
            end
        end

        if vPos == nil then
            vPos = vTeleportLocations[ RandomInt( 1, #vTeleportLocations ) ]
        end
    end

    if vPos == nil then
        return nil
    end

    self.vLastBlinkLocation = vPos

    Order = 
    {
        UnitIndex = self.me:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = vPos,
        AbilityIndex = self.hBlink:entindex(),
        Queue = false,
    }
    Order.flOrderInterval = 3.0

    return Order
end

--------------------------------------------------------------------------------

function CBossAghanim:EvaluateSummonPortals()
    if self:GetCurrentPhase() ~= self.PHASE_SUMMON_PORTALS then
        return nil
    end

    local vTarget = self.me.vHomePosition
    local hEnemies = GetEnemyHeroesInRange( self.me, 5000 )
    if #hEnemies > 0 and self.vLastBlinkLocation == self.me.vHomePosition then
        vTarget = hEnemies[ 1 ]:GetAbsOrigin()
    end

    local Order = nil
    Order = 
    {
        UnitIndex = self.me:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = vTarget,
        AbilityIndex = self.hSummonPortals:entindex(),
        Queue = false,
    }
    Order.flOrderInterval = GetSpellCastTime( self.hSummonPortals ) + self.hSummonPortals:GetChannelTime()
    
    return Order
end

--------------------------------------------------------------------------------

function CBossAghanim:EvaluateSpellSwap()
    if self:GetCurrentPhase() ~= self.PHASE_SPELL_SWAP then
        return nil
    end

    local vTargetPos = self.me.vHomePosition 
    if vTargetPos == self.vLastBlinkLocation then
        local hEnemies = GetEnemyHeroesInRange( self.me, 5000 )
        if #hEnemies > 0 then
            vTargetPos = hEnemies[#hEnemies]:GetAbsOrigin()
        end
    end

    local Order = nil
    Order = 
    {
        UnitIndex = self.me:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = vTargetPos,
        AbilityIndex = self.hSpellSwap:entindex(),
        Queue = false,
    }
    Order.flOrderInterval = GetSpellCastTime( self.hSpellSwap ) + self.hSpellSwap:GetChannelTime()
    
    return Order
end

--------------------------------------------------------------------------------

function CBossAghanim:EvaluateShardAttack()
    if self:GetCurrentPhase() ~= self.PHASE_SHARD_ATTACK then
        return nil
    end

    local Order = nil
    Order = 
    {
        UnitIndex = self.me:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
        Position = self.me.vHomePosition + Vector( 0, -150, 0 ),
        AbilityIndex = self.hShardAttack:entindex(),
        Queue = false,
    }
    Order.flOrderInterval = GetSpellCastTime( self.hShardAttack ) + self.hShardAttack:GetChannelTime()
    
    return Order
end

--------------------------------------------------------------------------------

function CBossAghanim:EvaluateScytheAttack()
    if self:GetCurrentPhase() ~= self.PHASE_SCYTHE_ATTACK then
        return nil
    end

    local vTargetPos = self.me.vHomePosition 
    if vTargetPos == self.vLastBlinkLocation then
        local hEnemies = GetEnemyHeroesInRange( self.me, 5000 )
        if #hEnemies > 0 then
            vTargetPos = hEnemies[#hEnemies]:GetAbsOrigin()
        end
    end

    local Order = nil
    Order = 
    {
        UnitIndex = self.me:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        Position = vTargetPos,
        AbilityIndex = self.hScytheAttack:entindex(),
        Queue = false,
    }
    Order.flOrderInterval = GetSpellCastTime( self.hScytheAttack ) + self.hScytheAttack:GetChannelTime()
    return Order
end

--------------------------------------------------------------------------------

function CBossAghanim:EvaluateIllusoryOrb()
    if self:GetCurrentPhase() ~= self.PHASE_ILLUSORY_ORB then
        return nil
    end

    local vTargetPos = self.me.vHomePosition 
    if vTargetPos == self.vLastBlinkLocation then
        local hEnemies = GetEnemyHeroesInRange( self.me, 5000 )
        if #hEnemies > 0 then
            vTargetPos = hEnemies[#hEnemies]:GetAbsOrigin()
        end
    end

    local Order = nil
    Order = 
    {
        UnitIndex = self.me:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        Position = vTargetPos,
        AbilityIndex = self.hIllusoryOrb:entindex(),
        Queue = false,
    }
    Order.flOrderInterval = GetSpellCastTime( self.hIllusoryOrb ) + self.hIllusoryOrb:GetChannelTime()
    return Order
end

--------------------------------------------------------------------------------

function CBossAghanim:EvaluateLifeDrain()
    if self:GetCurrentPhase() ~= self.PHASE_LIFE_DRAIN then
        return nil
    end

    local vTargetPos = self.me.vHomePosition 
    if vTargetPos == self.vLastBlinkLocation then
        local hEnemies = GetEnemyHeroesInRange( self.me, 5000 )
        if #hEnemies > 0 then
            vTargetPos = hEnemies[#hEnemies]:GetAbsOrigin()
        end
    end

    local Order = nil
    Order = 
    {
        UnitIndex = self.me:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        Position = vTargetPos,
        AbilityIndex = self.hLifeDrain:entindex(),
        Queue = false,
    }
    Order.flOrderInterval = GetSpellCastTime( self.hLifeDrain ) + self.hLifeDrain:GetChannelTime()
    return Order
end

--------------------------------------------------------------------------------

function CBossAghanim:EvaluateMysticFlare()
    if self:GetCurrentPhase() ~= self.PHASE_MYSTIC_FLARE then
        return nil
    end

    local vTargetPos = self.me.vHomePosition 
    if vTargetPos == self.vLastBlinkLocation then
        local hEnemies = GetEnemyHeroesInRange( self.me, 5000 )
        if #hEnemies > 0 then
            vTargetPos = hEnemies[#hEnemies]:GetAbsOrigin()
        end
    end

    local Order = nil
    Order = 
    {
        UnitIndex = self.me:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
        Position = vTargetPos,
        AbilityIndex = self.hMysticFlare:entindex(),
        Queue = false,
    }
    Order.flOrderInterval = GetSpellCastTime( self.hMysticFlare ) + self.hMysticFlare:GetChannelTime()
    return Order
end

--------------------------------------------------------------------------------

function CBossAghanim:OnBossUsedAbility( szAbilityName )
    if szAbilityName == "aghanim_blink" then
        self.nNumAttacksBeforeTeleport = self.nCurrentAttacksBetweenTeleport
        self.bReturnHome = false
        return
    end

    if szAbilityName == "aghanim_crystal_attack" then
        if self.hCrystalAttack.nPhase == 6 then
            self:ChangePhase()
        end

        return
    end

    if szAbilityName == "ascension_magic_immunity" or szAbilityName == "ascension_pathfinder_dilation" or szAbilityName == "aghsfort_ascension_firefly" or szAbilityName == "aghsfort_ascension_silence" or szAbilityName == "aghsfort_ascension_magnetic_field" then
        return
    end

    self:ChangePhase()
end

