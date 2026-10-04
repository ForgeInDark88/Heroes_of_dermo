artem_mukbang = class({})

LinkLuaModifier("modifier_artem_mukbang", "lua_abilities/artem/artem_mukbang", LUA_MODIFIER_MOTION_NONE)

function artem_mukbang:GetIntrinsicModifierName()
    return "modifier_artem_mukbang"
end

-- Уровень врождёнки: 1 до ульты, далее 2/3/4 с каждым уровнем ульты.
function artem_mukbang:SyncLevelWithUltimate()
    local ultimate = self:GetCaster():FindAbilityByName("artem_vodka_kalyan_shlyuhi")
    local ultimate_level = ultimate and ultimate:GetLevel() or 0
    local mukbang_level = math.max(1, math.min(4, ultimate_level + 1))

    if self:GetLevel() ~= mukbang_level then
        self:SetLevel(mukbang_level)
    end
end

modifier_artem_mukbang = class({})

function modifier_artem_mukbang:IsHidden() return false end
function modifier_artem_mukbang:IsPurgable() return false end

function modifier_artem_mukbang:OnDeath(params)
    if not IsServer() then return end

    local hero = self:GetParent()
    if params.attacker ~= hero then return end
    if not params.unit or params.unit:IsNull() or params.unit == hero then return end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    ability:SyncLevelWithUltimate()

    -- Лечение в процентах от максимального здоровья
    local heal = hero:GetMaxHealth() * ability:GetSpecialValueFor("heal_pct") / 100
    hero:Heal(heal, ability)

    local pfx = ParticleManager:CreateParticle(
        "particles/items3_fx/mango_consume.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        hero
    )
    ParticleManager:ReleaseParticleIndex(pfx)
    hero:EmitSound("Item.Mango.Activate")
end

function modifier_artem_mukbang:DeclareFunctions()
    return { MODIFIER_EVENT_ON_DEATH }
end
