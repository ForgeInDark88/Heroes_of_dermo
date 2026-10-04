------------------------------------------------------------
-- МАНТИЯ ТЕНЕВОГО ПРАВИТЕЛЬСТВА
-- Дропается с Главы Теневого правительства.
-- Активка "Стримснайп": вешает трек Stray228 на случайного
-- вражеского героя в любой точке карты.
------------------------------------------------------------

LinkLuaModifier(
    "modifier_item_shadow_gov_mantle",
    "items/item_shadow_gov_mantle",
    LUA_MODIFIER_MOTION_NONE
)

-- Трек берём у Снайпинга Stray228
LinkLuaModifier(
    "modifier_stray228_snaiping",
    "abilities/stray228_snaiping.lua",
    LUA_MODIFIER_MOTION_NONE
)

item_shadow_gov_mantle = class({})

function item_shadow_gov_mantle:GetIntrinsicModifierName()
    return "modifier_item_shadow_gov_mantle"
end

function item_shadow_gov_mantle:OnSpellStart()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        FIND_UNITS_EVERYWHERE,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
        FIND_ANY_ORDER,
        false
    )

    local heroes = {}

    for _, enemy in pairs(enemies) do
        if enemy:IsRealHero() and enemy:IsAlive() then
            table.insert(heroes, enemy)
        end
    end

    if #heroes == 0 then
        -- Некого снайпить - не тратим кулдаун
        self:EndCooldown()
        return
    end

    local target = heroes[RandomInt(1, #heroes)]

    target:AddNewModifier(
        caster,
        self,
        "modifier_stray228_snaiping",
        {
            duration = self:GetSpecialValueFor("track_duration")
        }
    )

    EmitSoundOn("Hero_BountyHunter.Target", target)
    EmitSoundOnClient("Hero_BountyHunter.Target", caster:GetPlayerOwner())

    print("[MANTLE] Streamsnipe: " .. target:GetUnitName())
end

------------------------------------------------------------
-- ПАССИВНЫЕ СТАТЫ
------------------------------------------------------------

modifier_item_shadow_gov_mantle = class({})

function modifier_item_shadow_gov_mantle:IsHidden()
    return true
end

function modifier_item_shadow_gov_mantle:IsPurgable()
    return false
end

function modifier_item_shadow_gov_mantle:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_shadow_gov_mantle:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
end

function modifier_item_shadow_gov_mantle:GetValue(name)
    local ability = self:GetAbility()

    if not ability then
        return 0
    end

    return ability:GetSpecialValueFor(name)
end

function modifier_item_shadow_gov_mantle:GetModifierBonusStats_Strength()
    return self:GetValue("bonus_all_stats")
end

function modifier_item_shadow_gov_mantle:GetModifierBonusStats_Agility()
    return self:GetValue("bonus_all_stats")
end

function modifier_item_shadow_gov_mantle:GetModifierBonusStats_Intellect()
    return self:GetValue("bonus_all_stats")
end

function modifier_item_shadow_gov_mantle:GetModifierPhysicalArmorBonus()
    return self:GetValue("bonus_armor")
end

function modifier_item_shadow_gov_mantle:GetModifierMagicalResistanceBonus()
    return self:GetValue("bonus_magic_resist")
end
