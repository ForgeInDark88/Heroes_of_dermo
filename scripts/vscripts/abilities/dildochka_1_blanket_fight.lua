-- Дилдочка: 1. Борьба под одеялом (пассивная)
-- Каждая атака наносит доп. физ. урон и копит счётчик на цели.
-- На N-м ударе — ministun. Стан не проходит сквозь невосприимчивость
-- к эффектам, пока не взят талант 25 уровня.

if dildo_blanket_fight == nil then dildo_blanket_fight = class({}) end

LinkLuaModifier("modifier_dildo_blanket_fight", "abilities/dildochka_1_blanket_fight", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dildo_blanket_counter", "abilities/dildochka_1_blanket_fight", LUA_MODIFIER_MOTION_NONE)

local TALENT_HITS = "special_bonus_unique_dildochka_blanket_hits"

function dildo_blanket_fight:GetIntrinsicModifierName()
    return "modifier_dildo_blanket_fight"
end

modifier_dildo_blanket_fight = class({})

function modifier_dildo_blanket_fight:IsHidden() return true end
function modifier_dildo_blanket_fight:IsPurgable() return false end
function modifier_dildo_blanket_fight:RemoveOnDeath() return false end

function modifier_dildo_blanket_fight:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_dildo_blanket_fight:OnAttackLanded(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.attacker ~= parent then return end
    if parent:PassivesDisabled() or parent:IsIllusion() then return end

    local target = params.target
    if not target or target:IsNull() or not target:IsAlive() then return end
    if target:GetTeamNumber() == parent:GetTeamNumber() then return end
    if target:IsBuilding() then return end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() or ability:GetLevel() <= 0 then return end

    local bonus = ability:GetSpecialValueFor("bonus_damage_per_hit")
    local hits_to_trigger = math.max(1, ability:GetSpecialValueFor("hits_to_trigger"))
    local ministun_duration = ability:GetSpecialValueFor("ministun_duration")
    local counter_duration = ability:GetSpecialValueFor("counter_duration")

    local talent = parent:FindAbilityByName(TALENT_HITS)
    local stun_pierces = talent and talent:GetLevel() > 0

    local counter = target:FindModifierByNameAndCaster("modifier_dildo_blanket_counter", parent)
    if not counter then
        counter = target:AddNewModifier(parent, ability, "modifier_dildo_blanket_counter", {
            duration = counter_duration
        })
    else
        counter:SetDuration(counter_duration, true)
    end

    if counter then
        counter:IncrementStackCount()

        if counter:GetStackCount() >= hits_to_trigger then
            counter:SetStackCount(0)

            if stun_pierces or not target:IsMagicImmune() then
                target:AddNewModifier(parent, ability, "modifier_stunned", {
                    duration = ministun_duration
                })
                target:EmitSound("Hero_Marci.Unleash")

                local p = ParticleManager:CreateParticle(
                    "particles/econ/items/tuskarr/tusk_ti9_immortal/tusk_ti9_walruspunch_start_fishes.vpcf",
                    PATTACH_ABSORIGIN_FOLLOW,
                    target
                )
                ParticleManager:SetParticleControl(p, 0, target:GetAbsOrigin())
                ParticleManager:ReleaseParticleIndex(p)
            end
        end
    end

    ApplyDamage({
        victim = target,
        attacker = parent,
        damage = bonus,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = ability,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
    })
end

modifier_dildo_blanket_counter = class({})

function modifier_dildo_blanket_counter:IsHidden() return false end
function modifier_dildo_blanket_counter:IsDebuff() return true end
function modifier_dildo_blanket_counter:IsPurgable() return false end
function modifier_dildo_blanket_counter:RemoveOnDeath() return true end
function modifier_dildo_blanket_counter:GetTexture() return "marci_rebound" end
