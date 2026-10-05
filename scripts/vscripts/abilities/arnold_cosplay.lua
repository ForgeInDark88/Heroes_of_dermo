-- Арнольд: врождёнка "Косплей"
-- Атаки выжигают ману (фикс + за уровень героя + % от макс. маны) и наносят
-- физический урон в размере % от выжженной маны. Проходит сквозь
-- невосприимчивость к эффектам. Снижает сопротивление магии самому Арнольду
-- (с талантом 25 уровня — наоборот, даёт). Отключается истощением.

arnold_cosplay = class({})

LinkLuaModifier("modifier_arnold_cosplay", "abilities/arnold_cosplay", LUA_MODIFIER_MOTION_NONE)

local TALENT_MAGIC_RESIST = "special_bonus_unique_arnold_cosplay_magic_resist"

function arnold_cosplay:Spawn()
    if IsServer() and self:GetLevel() == 0 then
        self:SetLevel(1)
    end
end

function arnold_cosplay:GetIntrinsicModifierName()
    return "modifier_arnold_cosplay"
end

modifier_arnold_cosplay = class({})

function modifier_arnold_cosplay:IsHidden() return true end
function modifier_arnold_cosplay:IsPurgable() return false end
function modifier_arnold_cosplay:RemoveOnDeath() return false end

function modifier_arnold_cosplay:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
end

function modifier_arnold_cosplay:GetModifierMagicalResistanceBonus()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    if not ability or ability:IsNull() or parent:PassivesDisabled() then return 0 end

    local value = ability:GetSpecialValueFor("self_magic_resistance")
    local talent = parent:FindAbilityByName(TALENT_MAGIC_RESIST)
    if talent and talent:GetLevel() > 0 then
        return value
    end
    return -value
end

function modifier_arnold_cosplay:OnAttackLanded(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.attacker ~= parent then return end
    if parent:PassivesDisabled() then return end

    local target = params.target
    if not target or target:IsNull() or not target:IsAlive() then return end
    if target:IsBuilding() or target:GetTeamNumber() == parent:GetTeamNumber() then return end
    if target:GetMaxMana() <= 0 then return end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    -- Иллюзии (Бустеры) считают по уровню владельца
    local owner = parent
    if parent:IsIllusion() and parent:GetPlayerOwner() and parent:GetPlayerOwner():GetAssignedHero() then
        owner = parent:GetPlayerOwner():GetAssignedHero()
    end

    local burn = ability:GetSpecialValueFor("mana_burn_base")
        + ability:GetSpecialValueFor("mana_burn_per_level") * owner:GetLevel()
        + target:GetMaxMana() * ability:GetSpecialValueFor("mana_burn_pct") / 100

    burn = math.min(burn, target:GetMana())
    if burn <= 0 then return end

    target:ReduceMana(burn, ability)

    ApplyDamage({
        victim = target,
        attacker = parent,
        damage = burn * ability:GetSpecialValueFor("damage_pct") / 100,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
        ability = ability,
    })

    local fx = ParticleManager:CreateParticle(
        "particles/generic_gameplay/generic_manaburn.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        target
    )
    ParticleManager:ReleaseParticleIndex(fx)
    target:EmitSound("Hero_Antimage.ManaBreak")
end
