LinkLuaModifier("modifier_boss_arc_warden_magnetic_field_collapse_thinker", "heroes/bosses/arc_warden/boss_arc_warden_magnetic_field_collapse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_arc_warden_magnetic_field_collapse_thinker_aura", "heroes/bosses/arc_warden/boss_arc_warden_magnetic_field_collapse", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_arc_warden_magnetic_field_collapse = class(ItemBaseClass)
modifier_boss_arc_warden_magnetic_field_collapse_thinker = class(boss_arc_warden_magnetic_field_collapse)
modifier_boss_arc_warden_magnetic_field_collapse_thinker_aura = class(boss_arc_warden_magnetic_field_collapse)
-------------
function boss_arc_warden_magnetic_field_collapse:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local amount = self:GetSpecialValueFor("number_of_fields")
    local delay = self:GetSpecialValueFor("delay")
    local radius = self:GetSpecialValueFor("creation_radius")
    local pos = caster:GetAbsOrigin()

    local safeZoneNumber = RandomInt(1, amount)

    local createdZones = 0

    local fieldEntities = {}

    local vo = {
        "arc_warden_arcwar_magnetic_field_01",
        "arc_warden_arcwar_magnetic_field_02",
        "arc_warden_arcwar_magnetic_field_03",
        "arc_warden_arcwar_magnetic_field_04",
        "arc_warden_arcwar_magnetic_field_05",
        "arc_warden_arcwar_magnetic_field_06",
        "arc_warden_arcwar_magnetic_field_07",
        "arc_warden_arcwar_magnetic_field_08",
    }

    EmitSoundOn(vo[RandomInt(1, #vo)], caster)

    Timers:CreateTimer(0.25, function()
        if createdZones >= amount then return end 

        local point = Vector(pos.x+RandomInt(-radius, radius), pos.y+RandomInt(-radius, radius), pos.z)
        local ctx = CreateModifierThinker(
            caster,
            self,
            "modifier_boss_arc_warden_magnetic_field_collapse_thinker",
            { duration = delay+1, safeZone = (createdZones == safeZoneNumber) },
            point,
            caster:GetTeam(),
            false
        )

        table.insert(fieldEntities, ctx)

        createdZones = createdZones + 1

        return 0.25
    end)

    Timers:CreateTimer(delay, function()
        local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_terrorblade/terrorblade_scepter.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControl(vfx, 0, caster:GetAbsOrigin())
        ParticleManager:SetParticleControl(vfx, 1, Vector(radius, radius, radius))
        ParticleManager:SetParticleControl(vfx, 2, Vector(radius, radius, radius))
        EmitSoundOn("Hero_Terrorblade.Metamorphosis.Scepter", caster)

        local enemies = FindUnitsInRadius(
            caster:GetTeam(),
            caster:GetAbsOrigin(),
            nil,
            radius*2,
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO,
            DOTA_UNIT_TARGET_FLAG_NONE ,
            FIND_ANY_ORDER,
            false
        )

        for _,enemy in ipairs(enemies) do
            if enemy:IsAlive() and not enemy:HasModifier("modifier_boss_arc_warden_magnetic_field_collapse_thinker_aura") then
                enemy:Kill(self, caster)
            end
        end

        -- Remove the fields 
        for _,field in ipairs(fieldEntities) do
            if field ~= nil and not field:IsNull() then
                UTIL_Remove(field)
            end
        end
    end)
end
-------------
function modifier_boss_arc_warden_magnetic_field_collapse_thinker:OnCreated(props)
    if not IsServer() then return end 

    local parent = self:GetParent()
    self.safeZone = props.safeZone

    local particle = "particles/units/heroes/hero_arc_warden/arc_warden_magnetic.vpcf"

    if self.safeZone == 1 then
        particle = "particles/units/heroes/hero_arc_warden/arc_warden_magnetic_tempest.vpcf"
    end

    self.vfx = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(self.vfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 1, Vector(300, 300, 300))

    EmitSoundOn("Hero_ArcWarden.MagneticField.Cast", parent)
    EmitSoundOn("Hero_ArcWarden.MagneticField", parent)
end

function modifier_boss_arc_warden_magnetic_field_collapse_thinker:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    StopSoundOn("Hero_ArcWarden.MagneticField", parent)

    UTIL_Remove(parent)
end

function modifier_boss_arc_warden_magnetic_field_collapse_thinker:IsAura()
    return true
end
  
function modifier_boss_arc_warden_magnetic_field_collapse_thinker:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_boss_arc_warden_magnetic_field_collapse_thinker:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_boss_arc_warden_magnetic_field_collapse_thinker:GetAuraRadius()
    return 300
end

function modifier_boss_arc_warden_magnetic_field_collapse_thinker:GetModifierAura()
    return "modifier_boss_arc_warden_magnetic_field_collapse_thinker_aura"
end

function modifier_boss_arc_warden_magnetic_field_collapse_thinker:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_boss_arc_warden_magnetic_field_collapse_thinker:GetAuraEntityReject()
    if not self.safeZone then return true end 

    return false
end