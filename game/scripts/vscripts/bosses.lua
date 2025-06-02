LinkLuaModifier( "modifier_unit_on_death", 'spawnunits', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_unit_boss", 'spawnunits', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_mars_ai", 'modifiers/modifier_mars_ai', LUA_MODIFIER_MOTION_NONE )

_G.FinalBossSpawnLocation = Entities:FindByName(nil, "spawn_boss_nevermore"):GetAbsOrigin()

function Respawn (keys )
    local caster= keys.caster                --пробиваем IP усопшего
    local caster_position = caster:GetAbsOrigin() --Пробиваем адрес,где лежит жмурик
    local name= caster:GetUnitName()         --Пробиваем имя покойного
    Timers:CreateTimer(60,function()              --Через сколько секунд появится новый фраер(5)
    local unit = CreateUnitByName(name, caster_position + RandomVector( RandomFloat( 0, 50)), true, nil, nil, DOTA_TEAM_NEUTRALS)
-- создаем нового пацыка по трем аргументам ( имя покойного ,адрес жмурика ,true,nil,nil,Команда_нейтралов)
    end)
end

function RespawnSF (keys )
    local caster= keys.caster                --пробиваем IP усопшего
    local caster_position = caster:GetAbsOrigin() --Пробиваем адрес,где лежит жмурик
    local name= caster:GetUnitName()         --Пробиваем имя покойного
    Timers:CreateTimer(60,function()              --Через сколько секунд появится новый фраер(5)
    local unit = CreateUnitByName("npc_dota_creature_100_boss_2", _G.FinalBossSpawnLocation, true, nil, nil, DOTA_TEAM_NEUTRALS)
     unit:AddNewModifier(unit, nil, "modifier_unit_boss", {})
    unit:AddNewModifier(unit, nil, "modifier_unit_on_death", {
        posX = caster_position.x,
        posY = caster_position.y,
        posZ = caster_position.z,
        name = name
    })
-- создаем нового пацыка по трем аргументам ( имя покойного ,адрес жмурика ,true,nil,nil,Команда_нейтралов)
    end)
end

function RespawnSF2 (keys )
    local caster= keys.caster                --пробиваем IP усопшего
    local caster_position = caster:GetAbsOrigin() --Пробиваем адрес,где лежит жмурик
    local name= caster:GetUnitName()         --Пробиваем имя покойного
    Timers:CreateTimer(60,function()              --Через сколько секунд появится новый фраер(5)
    local unit = CreateUnitByName("npc_dota_creature_100_boss_3", _G.FinalBossSpawnLocation, true, nil, nil, DOTA_TEAM_NEUTRALS)
     unit:AddNewModifier(unit, nil, "modifier_unit_boss", {})
    unit:AddNewModifier(unit, nil, "modifier_unit_on_death", {
        posX = caster_position.x,
        posY = caster_position.y,
        posZ = caster_position.z,
        name = name
    })
-- создаем нового пацыка по трем аргументам ( имя покойного ,адрес жмурика ,true,nil,nil,Команда_нейтралов)
    end)
end

function RespawnSF3 (keys )
    local caster= keys.caster                --пробиваем IP усопшего
    local caster_position = caster:GetAbsOrigin() --Пробиваем адрес,где лежит жмурик
    local name= caster:GetUnitName()         --Пробиваем имя покойного
    Timers:CreateTimer(60,function()              --Через сколько секунд появится новый фраер(5)
    local unit = CreateUnitByName("npc_dota_creature_100_boss_4", _G.FinalBossSpawnLocation, true, nil, nil, DOTA_TEAM_NEUTRALS)
     unit:AddNewModifier(unit, nil, "modifier_unit_boss", {})
     unit:AddNewModifier(unit, nil, "modifier_mars_ai", {})
    unit:AddNewModifier(unit, nil, "modifier_unit_on_death", {
        posX = caster_position.x,
        posY = caster_position.y,
        posZ = caster_position.z,
        name = name
    })
-- создаем нового пацыка по трем аргументам ( имя покойного ,адрес жмурика ,true,nil,nil,Команда_нейтралов)
    end)
end

function RespawnSF4 (keys )
    local caster= keys.caster                --пробиваем IP усопшего
    local caster_position = caster:GetAbsOrigin() --Пробиваем адрес,где лежит жмурик
    local name= caster:GetUnitName()         --Пробиваем имя покойного
    Timers:CreateTimer(60,function()              --Через сколько секунд появится новый фраер(5)
    local unit = CreateUnitByName("npc_dota_creature_100_boss_5", _G.FinalBossSpawnLocation, true, nil, nil, DOTA_TEAM_NEUTRALS)
     unit:AddNewModifier(unit, nil, "modifier_unit_boss", {})
    unit:AddNewModifier(unit, nil, "modifier_unit_on_death", {
        posX = caster_position.x,
        posY = caster_position.y,
        posZ = caster_position.z,
        name = name
    })
-- создаем нового пацыка по трем аргументам ( имя покойного ,адрес жмурика ,true,nil,nil,Команда_нейтралов)
    end)
end

function EndTheGame()
    GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
end