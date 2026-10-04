-- Дилдочка: Ульта.
-- Хуй знает кто по жизни

if dildo_who_the_fuck_is_he == nil then
    dildo_who_the_fuck_is_he = class({})
end

LinkLuaModifier(
    "modifier_dildo_ultimate",
    "abilities/dildochka_4_who_the_fuck_is_he",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_dildo_scepter_physical",
    "abilities/dildochka_4_who_the_fuck_is_he",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_dildo_scepter_magic",
    "abilities/dildochka_4_who_the_fuck_is_he",
    LUA_MODIFIER_MOTION_NONE
)

require("abilities/dildochka_shared")


function dildo_who_the_fuck_is_he:GetIntrinsicModifierName()
    return "modifier_dildo_ultimate"
end


function dildo_who_the_fuck_is_he:OnToggle()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()
    local active = self:GetToggleState()

    local mod = caster:FindModifierByName("modifier_dildo_ultimate")

    if mod then
        mod:ForceRefresh()
    end

    -- =========================================================
    -- ВКЛЮЧИЛИ УЛЬТУ → МАГИЧЕСКИЙ РЕЖИМ
    -- =========================================================

    if active then

        caster:EmitSound("Hero_Marci.Unleash")
        caster:EmitSound("Hero_Marci.Unleash.Cast")

        local p = ParticleManager:CreateParticle(
            "particles/units/heroes/hero_marci/marci_unleash.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            caster
        )

        ParticleManager:SetParticleControl(
            p,
            0,
            caster:GetAbsOrigin()
        )

        ParticleManager:ReleaseParticleIndex(p)


        -- ==========================================
        -- AGHANIM
        -- +20% скорости применения
        -- следующая атака по заражённому врагу
        -- распространяет Гнилой пальчик
        -- ==========================================

        if caster:HasScepter() then

            local duration = self:GetSpecialValueFor("scepter_duration")

            caster:AddNewModifier(
                caster,
                self,
                "modifier_dildo_scepter_magic",
                {
                    duration = duration
                }
            )
        end

    -- =========================================================
    -- ВЫКЛЮЧИЛИ УЛЬТУ → ФИЗИЧЕСКИЙ РЕЖИМ
    -- =========================================================

    else

        caster:EmitSound("Hero_Marci.Unleash.End")


        -- ==========================================
        -- AGHANIM
        -- +30% скорости атаки
        -- +20% вампиризма
        -- ==========================================

        if caster:HasScepter() then

            local duration = self:GetSpecialValueFor("scepter_duration")

            caster:AddNewModifier(
                caster,
                self,
                "modifier_dildo_scepter_physical",
                {
                    duration = duration
                }
            )
        end
    end
end


-- =========================================================
-- ОСНОВНОЙ МОДИФИКАТОР УЛЬТЫ
-- =========================================================

modifier_dildo_ultimate = class({})


function modifier_dildo_ultimate:IsHidden()
    return false
end


function modifier_dildo_ultimate:IsPurgable()
    return false
end


function modifier_dildo_ultimate:GetTexture()
    return "marci_unleash"
end


function modifier_dildo_ultimate:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end


function modifier_dildo_ultimate:OnCreated()
    self:RefreshValues()
end


function modifier_dildo_ultimate:OnRefresh()
    self:RefreshValues()
end


function modifier_dildo_ultimate:RefreshValues()

    local ability = self:GetAbility()

    self.level = ability and ability:GetLevel() or 0

    self.active = ability and ability:GetToggleState() or false

    self.attack_damage =
        ability and ability:GetSpecialValueFor("bonus_attack_damage") or 0

    self.crit_chance =
        ability and ability:GetSpecialValueFor("crit_chance") or 0

    self.crit_multiplier =
        ability and ability:GetSpecialValueFor("crit_multiplier") or 0

    self.on_hit_infection =
        ability and ability:GetSpecialValueFor("on_hit_infection") or 0

    self.spell_amp =
        ability and ability:GetSpecialValueFor("spell_amplify") or 0
end


function modifier_dildo_ultimate:GetModifierPreAttack_BonusDamage()

    if self.active then
        return 0
    end

    return self.attack_damage
end


function modifier_dildo_ultimate:GetModifierPreAttack_CriticalStrike(params)

    if self.active or self.level < 2 then
        return nil
    end

    if RollPercentage(self.crit_chance) then
        return self.crit_multiplier
    end

    return nil
end


function modifier_dildo_ultimate:GetModifierSpellAmplify_Percentage()

    if not self.active then
        return 0
    end

    return self.spell_amp
end


-- =========================================================
-- СТАРАЯ МЕХАНИКА УЛЬТЫ
-- В физическом режиме атаки заражают врага
-- =========================================================

function modifier_dildo_ultimate:OnAttackLanded(params)

    if not IsServer() then
        return
    end

    if params.attacker ~= self:GetParent() then
        return
    end

    if self.active or self.on_hit_infection ~= 1 then
        return
    end

    if not params.target or params.target:IsNull() then
        return
    end

    if params.target:GetTeamNumber() ==
        self:GetParent():GetTeamNumber() then
        return
    end

    local rotten_finger =
        self:GetParent():FindAbilityByName("dildo_rotten_finger")

    if rotten_finger then

        DildochkaApplyRottenFinger(
            self:GetParent(),
            params.target,
            rotten_finger
        )

        params.target:EmitSound(
            "Hero_Venomancer.VenomousGale"
        )
    end
end


-- =========================================================
-- AGHANIM
-- ФИЗИЧЕСКИЙ РЕЖИМ
-- =========================================================

modifier_dildo_scepter_physical = class({})


function modifier_dildo_scepter_physical:IsHidden()
    return false
end


function modifier_dildo_scepter_physical:IsPurgable()
    return true
end


function modifier_dildo_scepter_physical:GetTexture()
    return "marci_unleash"
end


function modifier_dildo_scepter_physical:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_LIFESTEAL
    }
end


function modifier_dildo_scepter_physical:OnCreated()

    local ability = self:GetAbility()

    self.attack_speed =
        ability:GetSpecialValueFor("scepter_attack_speed")

    self.lifesteal =
        ability:GetSpecialValueFor("scepter_lifesteal")
end


function modifier_dildo_scepter_physical:OnRefresh()

    self:OnCreated()
end


function modifier_dildo_scepter_physical:GetModifierAttackSpeedBonus_Constant()

    return self.attack_speed
end


function modifier_dildo_scepter_physical:GetModifierPreAttack_Lifesteal()

    return self.lifesteal
end


-- =========================================================
-- AGHANIM
-- МАГИЧЕСКИЙ РЕЖИМ
-- =========================================================

modifier_dildo_scepter_magic = class({})


function modifier_dildo_scepter_magic:IsHidden()
    return false
end


function modifier_dildo_scepter_magic:IsPurgable()
    return true
end


function modifier_dildo_scepter_magic:GetTexture()
    return "marci_unleash"
end


function modifier_dildo_scepter_magic:OnCreated()

    local ability = self:GetAbility()

    self.cast_speed =
        ability:GetSpecialValueFor("scepter_cast_speed")
end


function modifier_dildo_scepter_magic:OnRefresh()

    self:OnCreated()
end


function modifier_dildo_scepter_magic:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end


function modifier_dildo_scepter_magic:GetModifierPercentageCastTime()

    return -self.cast_speed
end


-- =========================================================
-- СЛЕДУЮЩАЯ АТАКА ПО ЗАРАЖЁННОМУ ВРАГУ
-- РАСПРОСТРАНЯЕТ ГНИЛОЙ ПАЛЬЧИК
-- =========================================================

function modifier_dildo_scepter_magic:OnAttackLanded(params)

    if not IsServer() then
        return
    end

    local caster = self:GetParent()

    if params.attacker ~= caster then
        return
    end

    local target = params.target

    if not target or target:IsNull() or not target:IsAlive() then
        return
    end

    -- Проверяем, что атакованный враг уже заражён
    local rotten =
        target:FindModifierByName("modifier_dildo_rotten_finger")

    if not rotten then
        return
    end

    -- Получаем способность Гнилой пальчик
    local rotten_finger =
        caster:FindAbilityByName("dildo_rotten_finger")

    if not rotten_finger then
        return
    end

    -- Радиус распространения берём из самого Гнилого пальчика
    local radius =
        rotten_finger:GetSpecialValueFor("spread_radius")

    -- Все враги вокруг заражённой цели
    local enemies = DildochkaGetEnemyUnits(
        caster,
        target:GetAbsOrigin(),
        radius
    )

    for _, enemy in pairs(enemies) do

        if enemy ~= target
            and enemy:IsAlive()
            and not enemy:IsNull()
        then

            DildochkaApplyRottenFinger(
                caster,
                enemy,
                rotten_finger
            )

            enemy:EmitSound(
                "Hero_Venomancer.VenomousGale"
            )
        end
    end

    -- Эффект распространения
    local p = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf",
        PATTACH_ABSORIGIN,
        target
    )

    ParticleManager:SetParticleControl(
        p,
        0,
        target:GetAbsOrigin()
    )

    ParticleManager:SetParticleControl(
        p,
        1,
        Vector(radius, 0, 0)
    )

    ParticleManager:ReleaseParticleIndex(p)

    -- =====================================================
    -- Механика "СЛЕДУЮЩАЯ АТАКА"
    -- После успешного распространения бонус заканчивается.
    -- =====================================================

    self:Destroy()
end