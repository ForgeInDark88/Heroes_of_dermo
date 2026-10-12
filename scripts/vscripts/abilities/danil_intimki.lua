-- Данил: врождёнка "Интимки"
-- Атаки по врагу с шансом накладывают безмолвие. Иллюзии не могут.
-- Не проходит сквозь невосприимчивость к эффектам. Отключается истощением.

danil_intimki = class({})

LinkLuaModifier("modifier_danil_intimki", "abilities/danil_intimki", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_danil_intimki_silence", "abilities/danil_intimki", LUA_MODIFIER_MOTION_NONE)

function danil_intimki:Spawn()
    if IsServer() and self:GetLevel() == 0 then
        self:SetLevel(1)
    end
end

function danil_intimki:GetIntrinsicModifierName()
    return "modifier_danil_intimki"
end

modifier_danil_intimki = class({})

function modifier_danil_intimki:IsHidden() return true end
function modifier_danil_intimki:IsPurgable() return false end
function modifier_danil_intimki:RemoveOnDeath() return false end

function modifier_danil_intimki:OnCreated()
    if not IsServer() then return end

    -- Врождёнка должна быть изучена, иначе значения из AbilityValues не берутся
    local ability = self:GetAbility()
    if ability and not ability:IsNull() and ability:GetLevel() == 0 then
        ability:SetLevel(1)
    end
end

function modifier_danil_intimki:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_danil_intimki:OnAttackLanded(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.attacker ~= parent then return end
    if parent:IsIllusion() or parent:PassivesDisabled() then return end

    local target = params.target
    if not target or target:IsNull() or not target:IsAlive() then return end
    if target:IsBuilding() or target:IsMagicImmune() then return end
    if target:GetTeamNumber() == parent:GetTeamNumber() then return end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    if not RollPseudoRandomPercentage(ability:GetSpecialValueFor("chance"), DOTA_PSEUDO_RANDOM_CUSTOM_GAME_1, parent) then
        return
    end

    target:AddNewModifier(parent, ability, "modifier_danil_intimki_silence", {
        duration = ability:GetSpecialValueFor("silence_duration")
    })
    target:EmitSound("Hero_Luna.ProjectileImpact")
end

--------------------------------------------------------------------------------
-- БЕЗМОЛВИЕ
--------------------------------------------------------------------------------

modifier_danil_intimki_silence = class({})

function modifier_danil_intimki_silence:IsHidden() return false end
function modifier_danil_intimki_silence:IsDebuff() return true end
function modifier_danil_intimki_silence:IsPurgable() return true end

function modifier_danil_intimki_silence:CheckState()
    return { [MODIFIER_STATE_SILENCED] = true }
end

function modifier_danil_intimki_silence:GetEffectName()
    return "particles/generic_gameplay/generic_silence.vpcf"
end

function modifier_danil_intimki_silence:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
