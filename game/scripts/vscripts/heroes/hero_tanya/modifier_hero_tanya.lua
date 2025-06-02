LinkLuaModifier("modifier_hero_tanya", "heroes/hero_tanya/modifier_hero_tanya.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_hero_tanya = class(ItemBaseClass)
-------------
function modifier_hero_tanya:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    local Tanya_Armor = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/antimage_female/anti_mage_nemesis_slayer_armor_persona_1/anti_mage_nemesis_slayer_armor_persona_1.vmdl"})
    local Tanya_Head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/antimage_female/anti_mage_nemesis_slayer_head_persona_1/anti_mage_nemesis_slayer_head_persona_1.vmdl"})
    local Tanya_Weapon1 = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/antimage_female/anti_mage_nemesis_slayer_offhand_weapon_persona_1/anti_mage_nemesis_slayer_offhand_weapon_persona_1.vmdl"})
    local Tanya_Weapon2 = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/antimage_female/anti_mage_nemesis_slayer_weapon_persona_1/anti_mage_nemesis_slayer_weapon_persona_1.vmdl"})

    Tanya_Armor:FollowEntity(parent, true)
    Tanya_Head:FollowEntity(parent, true)
    Tanya_Weapon1:FollowEntity(parent, true)
    Tanya_Weapon2:FollowEntity(parent, true)

    local effect_weaponL = ParticleManager:CreateParticle("particles/econ/items/antimage_female/nemesis_slayer/nemesis_weapon_l_ambient.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(
        effect_weaponL,
        1,
        parent,
        PATTACH_CUSTOMORIGIN_FOLLOW,
        "attach_attack2",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(effect_weaponL)

    local effect_weaponR = ParticleManager:CreateParticle("particles/econ/items/antimage_female/nemesis_slayer/nemesis_weapon_r_ambient.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(
        effect_weaponR,
        1,
        parent,
        PATTACH_CUSTOMORIGIN_FOLLOW,
        "attach_attack1",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(effect_weaponR)
end