local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_book_of_lies = class(ItemBaseClass)

function item_book_of_lies:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    PlayerBuffs:OpenBuffWindow(caster)
    
    if self:GetCurrentCharges() > 1 then
        self:SetCurrentCharges(self:GetCurrentCharges()-1)
    else
        caster:RemoveItem(self)
    end
end