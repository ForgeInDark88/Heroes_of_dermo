-- Данил: 2. Сын яблочек
-- Данил скидывает шмотки: на время снижается входящий урон, а с модельки
-- пропадают все предметы-косметика.

danil_son_yablochek = class({})

LinkLuaModifier("modifier_danil_son_yablochek", "abilities/danil_son_yablochek", LUA_MODIFIER_MOTION_NONE)

function danil_son_yablochek:OnSpellStart()
    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_danil_son_yablochek", {
        duration = self:GetSpecialValueFor("duration")
    })
    caster:EmitSound("DOTA_Item.BladeMail.Activate")
end

modifier_danil_son_yablochek = class({})

function modifier_danil_son_yablochek:IsHidden() return false end
function modifier_danil_son_yablochek:IsDebuff() return false end
function modifier_danil_son_yablochek:IsPurgable() return false end

function modifier_danil_son_yablochek:OnCreated()
    self:OnRefresh()
    if not IsServer() then return end

    -- Прячем всю косметику героя
    self.hidden = {}
    for _, child in pairs(self:GetParent():GetChildren()) do
        if child and not child:IsNull() and child:GetClassname() == "dota_item_wearable" then
            child:AddEffects(EF_NODRAW)
            table.insert(self.hidden, child)
        end
    end
end

function modifier_danil_son_yablochek:OnRefresh()
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    self.damage_reduction = ability:GetSpecialValueFor("damage_reduction")
end

function modifier_danil_son_yablochek:OnDestroy()
    if not IsServer() then return end

    for _, wearable in pairs(self.hidden or {}) do
        if wearable and not wearable:IsNull() then
            wearable:RemoveEffects(EF_NODRAW)
        end
    end
    self.hidden = nil
end

function modifier_danil_son_yablochek:DeclareFunctions()
    return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_danil_son_yablochek:GetModifierIncomingDamage_Percentage()
    return -(self.damage_reduction or 0)
end
