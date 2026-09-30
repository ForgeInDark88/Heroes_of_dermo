artem_snyusik = class({})

LinkLuaModifier("modifier_artem_snyusik", "lua_abilities/artem/artem_snyusik", LUA_MODIFIER_MOTION_NONE)

local TALENT = "special_bonus_artem_snyusik_damage"

function artem_snyusik:OnSpellStart()
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_artem_snyusik", { duration = self:GetSpecialValueFor("duration") })
    caster:EmitSound("snus")
end

modifier_artem_snyusik = class({})

function modifier_artem_snyusik:IsPurgable() return true end

function modifier_artem_snyusik:OnAttackLanded(params)
    if not IsServer() then return end
    local parent = self:GetParent()
    if params.attacker ~= parent then return end
    local target = params.target
    if not target or target:IsNull() or target:IsBuilding() then return end

    local damage = self:GetAbility():GetSpecialValueFor("bonus_magic_damage")
    local talent = parent:FindAbilityByName(TALENT)
    if talent and talent:GetLevel() > 0 then
        damage = damage + 50
    end

    ApplyDamage({
        victim = target,
        attacker = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(),
    })
end

function modifier_artem_snyusik:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end
