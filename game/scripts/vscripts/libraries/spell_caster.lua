require 'lib/lua/base'

SpellCaster = SpellCaster or {}

function SpellCaster:IsCorrectTarget( hSpell, hTarget, bFilterResult )
    local hCaster = hSpell:GetCaster()
    local nFilterTeam = hSpell:GetAbilityTargetTeam()
    local nFilterType = hSpell:GetAbilityTargetType()
    local nFilterFlag = hSpell:GetAbilityTargetFlags()
    local nResult

    if binhas( nFilterTeam, DOTA_UNIT_TARGET_TEAM_CUSTOM ) or binhas( nFilterTeam, DOTA_UNIT_TARGET_CUSTOM ) then
        nResult = UF_SUCCESS
    else
        nResult = UnitFilter( hTarget, nFilterTeam, nFilterType, nFilterFlag, hCaster:GetTeam() )
    end

    if bFilterResult then
        return nResult
    end

    return nResult == UF_SUCCESS
end

function SpellCaster:IsUnitTarget( hAbility )
    local nBehavior = hAbility:GetBehaviorInt()
    return binhas( nBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET )
end

function SpellCaster:Cast( hSpell, xTarget, bUseResources )
    local hCaster = hSpell:GetCaster()
    local bNoTarget = true
    local hOldTarget = Vector( 0, 0, 0 )
    local vOldTarget

    local function fSetTarget()
        bNoTarget = hCaster:GetCursorTargetingNothing()
        vOldTarget = hCaster:GetCursorPosition()
        hOldTarget = hCaster:GetCursorCastTarget()

        hCaster:SetCursorTargetingNothing( true )
        hCaster:SetCursorPosition( Vector( 0, 0, 0 ) )
        hCaster:SetCursorCastTarget( nil )

        if xTarget then
            hCaster:SetCursorTargetingNothing( false )

            if IsVector( xTarget ) then
                hCaster:SetCursorPosition( xTarget )
            elseif isdotaobject( xTarget ) then
                hCaster:SetCursorCastTarget( xTarget )
                hCaster:SetCursorPosition( xTarget:GetOrigin() )
            end
        end
    end

    local function fResetTarget()
        hCaster:SetCursorTargetingNothing( bNoTarget )
        hCaster:SetCursorPosition( vOldTarget )
        hCaster:SetCursorCastTarget( hOldTarget )
           
        bNoTarget = true
        vOldTarget = Vector( 0, 0, 0 )
        hOldTarget = nil
    end

    fSetTarget()
    if(bUseResources) then
        hSpell:CastAbility()
    else
        hSpell:OnSpellStart()
    end
    fResetTarget()
end