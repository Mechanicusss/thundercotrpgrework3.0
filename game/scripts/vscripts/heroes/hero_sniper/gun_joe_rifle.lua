require('heroes/hero_sniper/linked_ability')

LinkLuaModifier( "modifier_gun_joe_rifle", "heroes/hero_sniper/modifiers/modifier_gun_joe_rifle", LUA_MODIFIER_MOTION_NONE )

gun_joe_rifle = gun_joe_rifle or MakeLinkedBaseClass("gun_joe_machine_gun", "modifier_gun_joe_rifle")
