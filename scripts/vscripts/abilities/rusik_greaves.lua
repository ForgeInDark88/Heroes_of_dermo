-- Русик: шард "Гревсы на Энигму"
-- Русик покупает гревсы: снимает с себя отрицательные эффекты, лечит себя и
-- союзных героев рядом, восстанавливает им ману, а вражеских героев рядом
-- пугает (страх) на короткое время.

rusik_greaves = class({})

LinkLuaModifier("modifier_rusik_greaves_fear", "abilities/rusik_greaves", LUA_MODIFIER_MOTION_NONE)

function rusik_greaves:GetCastRange(location, target)
    return self:GetSpecialValueFor("radius")
end

function rusik_greaves:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")

    -- RemovePositiveBuffs, RemoveDebuffs, FrameOnly, RemoveStuns, RemoveExceptions
    caster:Purge(false, true, false, false, false)

    local fx = ParticleManager:CreateParticle("particles/items3_fx/warmage.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(fx)
    caster:EmitSound("Item.GuardianGreaves.Activate")

    local heal = self:GetSpecialValueFor("heal_amount")
    local mana = self:GetSpecialValueFor("mana_amount")

    local allies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, ally in pairs(allies) do
        ally:Heal(heal, self)
        ally:GiveMana(mana)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal, nil)

        local ally_fx = ParticleManager:CreateParticle("particles/items3_fx/warmage_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, ally)
        ParticleManager:ReleaseParticleIndex(ally_fx)
        ally:EmitSound("Item.GuardianGreaves.Target")
    end

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        self:GetSpecialValueFor("fear_radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    local fear_duration = self:GetSpecialValueFor("fear_duration")
    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(caster, self, "modifier_rusik_greaves_fear", { duration = fear_duration })
    end
end

--------------------------------------------------------------------------------
-- СТРАХ: убегает от Русика
--------------------------------------------------------------------------------

modifier_rusik_greaves_fear = class({})

function modifier_rusik_greaves_fear:IsHidden() return false end
function modifier_rusik_greaves_fear:IsDebuff() return true end
function modifier_rusik_greaves_fear:IsPurgable() return true end

function modifier_rusik_greaves_fear:OnCreated()
    if not IsServer() then return end
    self:RunAway()
    self:StartIntervalThink(0.2)
end

function modifier_rusik_greaves_fear:OnIntervalThink()
    self:RunAway()
end

function modifier_rusik_greaves_fear:RunAway()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    if not caster or caster:IsNull() then return end

    local direction = parent:GetAbsOrigin() - caster:GetAbsOrigin()
    direction.z = 0
    if direction:Length2D() < 1 then
        direction = -parent:GetForwardVector()
    end

    parent:MoveToPosition(parent:GetAbsOrigin() + direction:Normalized() * 400)
end

function modifier_rusik_greaves_fear:OnDestroy()
    if not IsServer() then return end
    self:GetParent():Stop()
end

function modifier_rusik_greaves_fear:CheckState()
    return {
        [MODIFIER_STATE_FEARED] = true,
    }
end

function modifier_rusik_greaves_fear:GetEffectName()
    return "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_debuff.vpcf"
end

function modifier_rusik_greaves_fear:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_rusik_greaves_fear:GetStatusEffectName()
    return "particles/status_fx/status_effect_dark_willow_wisp_fear.vpcf"
end
