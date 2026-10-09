-- Русик: 3. Статуэтка
-- Русик достаёт писюлька-статуэтку и на время даёт ауру камня: он сам и
-- союзные герои рядом превращаются в камень — не могут атаковать, их нельзя
-- атаковать, и они двигаются быстрее. Способности при этом работают.

rusik_statuetka = class({})

LinkLuaModifier("modifier_rusik_statuetka_aura", "abilities/rusik_statuetka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_statuetka_stone", "abilities/rusik_statuetka", LUA_MODIFIER_MOTION_NONE)

function rusik_statuetka:GetCastRange(location, target)
    return self:GetSpecialValueFor("radius")
end

function rusik_statuetka:OnSpellStart()
    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_rusik_statuetka_aura", {
        duration = self:GetSpecialValueFor("duration")
    })

    caster:EmitSound("Hero_Medusa.StoneGaze.Cast")
end

--------------------------------------------------------------------------------
-- АУРА КАМНЯ (на Русике)
--------------------------------------------------------------------------------

modifier_rusik_statuetka_aura = class({})

function modifier_rusik_statuetka_aura:IsHidden() return true end
function modifier_rusik_statuetka_aura:IsPurgable() return false end

function modifier_rusik_statuetka_aura:IsAura() return true end
function modifier_rusik_statuetka_aura:GetModifierAura() return "modifier_rusik_statuetka_stone" end
function modifier_rusik_statuetka_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_rusik_statuetka_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_rusik_statuetka_aura:GetAuraDuration() return 0.1 end

function modifier_rusik_statuetka_aura:GetAuraRadius()
    local ability = self:GetAbility()
    return ability and ability:GetSpecialValueFor("radius") or 0
end

--------------------------------------------------------------------------------
-- КАМЕННАЯ ФОРМА
--------------------------------------------------------------------------------

modifier_rusik_statuetka_stone = class({})

function modifier_rusik_statuetka_stone:IsHidden() return false end
function modifier_rusik_statuetka_stone:IsDebuff() return false end
function modifier_rusik_statuetka_stone:IsPurgable() return false end

function modifier_rusik_statuetka_stone:OnCreated()
    local ability = self:GetAbility()
    self.bonus_ms = ability and ability:GetSpecialValueFor("bonus_movement_speed") or 0

    if not IsServer() then return end
    self:GetParent():EmitSound("Hero_Medusa.StoneGaze.Target")
end

function modifier_rusik_statuetka_stone:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    }
end

function modifier_rusik_statuetka_stone:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_rusik_statuetka_stone:GetModifierMoveSpeedBonus_Percentage()
    return self.bonus_ms
end

function modifier_rusik_statuetka_stone:GetStatusEffectName()
    return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end

function modifier_rusik_statuetka_stone:StatusEffectPriority()
    return 10
end
