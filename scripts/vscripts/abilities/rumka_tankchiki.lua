LinkLuaModifier("modifier_rumka_tankchiki", "abilities/rumka_tankchiki", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rumka_tankchiki_slow", "abilities/rumka_tankchiki", LUA_MODIFIER_MOTION_NONE)

rumka_tankchiki = class({})

function rumka_tankchiki:GetIntrinsicModifierName()
    return "modifier_rumka_tankchiki"
end

-- Уровень врождёнки: 1 до ульты, далее 2/3/4 с каждым уровнем Трезвенника.
function rumka_tankchiki:SyncLevelWithUltimate()
    local ultimate = self:GetCaster():FindAbilityByName("rumka_trezvennik")
    local ultimate_level = ultimate and ultimate:GetLevel() or 0
    local level = math.max(1, math.min(4, ultimate_level + 1))

    if self:GetLevel() ~= level then
        self:SetLevel(level)
    end
end

modifier_rumka_tankchiki = class({})

function modifier_rumka_tankchiki:IsHidden() return true end
function modifier_rumka_tankchiki:IsPurgable() return false end

function modifier_rumka_tankchiki:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_rumka_tankchiki:OnAttackLanded(params)
    if not IsServer() then return end
    if params.attacker ~= self:GetParent() then return end

    local target = params.target
    if not target or target:IsNull() then return end
    if target:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
    if target:IsBuilding() then return end

    local ability = self:GetAbility()
    if not ability then return end

    ability:SyncLevelWithUltimate()

    target:AddNewModifier(self:GetParent(), ability, "modifier_rumka_tankchiki_slow", {
        duration = ability:GetSpecialValueFor("slow_duration")
    })

    -- Визуальный/звуковой эффект врождёнки.
    local hit_fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_pudge/pudge_meathook_impact.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        target
    )
    ParticleManager:SetParticleControlEnt(
        hit_fx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true
    )
    ParticleManager:ReleaseParticleIndex(hit_fx)

    EmitSoundOn("Hero_Pudge.AttackHookImpact", target)
end

modifier_rumka_tankchiki_slow = class({})

function modifier_rumka_tankchiki_slow:IsHidden() return false end
function modifier_rumka_tankchiki_slow:IsDebuff() return true end
function modifier_rumka_tankchiki_slow:IsPurgable() return true end

function modifier_rumka_tankchiki_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_rumka_tankchiki_slow:GetModifierMoveSpeedBonus_Percentage()
    local ability = self:GetAbility()
    if not ability then return 0 end
    return -ability:GetSpecialValueFor("slow_percent")
end
