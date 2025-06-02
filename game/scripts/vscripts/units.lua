function Respawn (keys )
    --[[
    local caster= keys.caster                --пробиваем IP усопшего
    local caster_position = caster:GetAbsOrigin() --Пробиваем адрес,где лежит жмурик
    local name= caster:GetUnitName()         --Пробиваем имя покойного
    Timers:CreateTimer(30,function()              --Через сколько секунд появится новый фраер(5)
    local unit = CreateUnitByName(name, caster_position + RandomVector( RandomFloat( 0, 50)), true, nil, nil, DOTA_TEAM_NEUTRALS)
-- создаем нового пацыка по трем аргументам ( имя покойного ,адрес жмурика ,true,nil,nil,Команда_нейтралов)
    end)
    --]]
end