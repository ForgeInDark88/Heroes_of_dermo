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
    "modifier_dildo_ultimate_slow",
    "abilities/dildochka_4_who_the_fuck_is_he",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_dildo_ultimate_magic_reduction",
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
--
-- Неактивное состояние (физический режим):
--   1 ур. — бонус к урону атаки
--   2 ур. — + шанс крита
--   3 ур. — + шанс сильно замедлить цель
--
-- Активное состояние (магический режим):
--   1 ур. — усиление магического урона
--   2 ур. — + атаки снижают сопротивление магии
--   3 ур. — + каждые N атак накладывают Гнилой пальчик
--
-- Эффекты на врагов не проходят сквозь невосприимчивость к эффектам.
-- =========================================================

modifier_dildo_ultimate = class({})


function modifier_dildo_ultimate:IsHidden()
    return false
end


function modifier_dildo_ultimate:IsPurgable()
    return false
end


function modifier_dildo_ultimate:RemoveOnDeath()
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
    self.attack_counter = 0
end


function modifier_dildo_ultimate:GetLevel()
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
        return 0
    end
    return ability:GetLevel()
end


function modifier_dildo_ultimate:IsActive()
    local ability = self:GetAbility()
    return ability and not ability:IsNull() and ability:GetToggleState()
end


function modifier_dildo_ultimate:Value(key)
    return self:GetAbility():GetSpecialValueFor(key)
end


local function IsValidEnemy(parent, target)
    return target
        and not target:IsNull()
        and target:IsAlive()
        and not target:IsBuilding()
        and target:GetTeamNumber() ~= parent:GetTeamNumber()
end


function modifier_dildo_ultimate:GetModifierPreAttack_BonusDamage()
    if self:GetLevel() < 1 or self:IsActive() then
        return 0
    end

    return self:Value("bonus_attack_damage")
end


function modifier_dildo_ultimate:GetModifierPreAttack_CriticalStrike(params)
    if not IsServer() then
        return
    end

    if self:GetLevel() < 2 or self:IsActive() then
        return
    end

    if not IsValidEnemy(self:GetParent(), params.target) then
        return
    end

    if RollPseudoRandomPercentage(self:Value("crit_chance"), DOTA_PSEUDO_RANDOM_CUSTOM_GAME_2, self:GetParent()) then
        return self:Value("crit_multiplier")
    end
end


function modifier_dildo_ultimate:GetModifierSpellAmplify_Percentage()
    if self:GetLevel() < 1 or not self:IsActive() then
        return 0
    end

    return self:Value("spell_amplify")
end


function modifier_dildo_ultimate:OnAttackLanded(params)
    if not IsServer() then
        return
    end

    local parent = self:GetParent()
    if params.attacker ~= parent then
        return
    end

    local target = params.target
    if not IsValidEnemy(parent, target) then
        return
    end

    local level = self:GetLevel()
    if level < 2 then
        return
    end

    -- Не проходит сквозь невосприимчивость к эффектам
    if target:IsMagicImmune() then
        return
    end

    local ability = self:GetAbility()

    if not self:IsActive() then
        -- 3 ур.: шанс замедлить
        if level >= 3 and RollPseudoRandomPercentage(self:Value("slow_chance"), DOTA_PSEUDO_RANDOM_CUSTOM_GAME_3, parent) then
            target:AddNewModifier(parent, ability, "modifier_dildo_ultimate_slow", {
                duration = self:Value("slow_duration")
            })
        end
        return
    end

    -- 2 ур.: снижение сопротивления магии
    target:AddNewModifier(parent, ability, "modifier_dildo_ultimate_magic_reduction", {
        duration = self:Value("magic_resistance_duration")
    })

    -- 3 ур.: каждые N атак — Гнилой пальчик
    if level >= 3 then
        self.attack_counter = (self.attack_counter or 0) + 1

        local required = math.max(1, self:Value("rotten_attacks_required"))
        if self.attack_counter >= required then
            self.attack_counter = 0

            local rotten_finger = parent:FindAbilityByName("dildo_rotten_finger")
            if rotten_finger then
                DildochkaApplyRottenFinger(parent, target, rotten_finger, self:Value("rotten_duration"))
                target:EmitSound("Hero_Venomancer.VenomousGale")
            end
        end
    end
end


-- =========================================================
-- НЕАКТИВНЫЙ РЕЖИМ, 3 УР.: ЗАМЕДЛЕНИЕ
-- =========================================================

modifier_dildo_ultimate_slow = class({})

function modifier_dildo_ultimate_slow:IsHidden() return false end
function modifier_dildo_ultimate_slow:IsDebuff() return true end
function modifier_dildo_ultimate_slow:IsPurgable() return true end
function modifier_dildo_ultimate_slow:GetTexture() return "marci_unleash" end

function modifier_dildo_ultimate_slow:OnCreated()
    local ability = self:GetAbility()
    self.slow = ability and ability:GetSpecialValueFor("slow_pct") or 0
end

function modifier_dildo_ultimate_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_dildo_ultimate_slow:GetModifierMoveSpeedBonus_Percentage()
    return -self.slow
end


-- =========================================================
-- АКТИВНЫЙ РЕЖИМ, 2 УР.: СНИЖЕНИЕ СОПРОТИВЛЕНИЯ МАГИИ
-- =========================================================

modifier_dildo_ultimate_magic_reduction = class({})

function modifier_dildo_ultimate_magic_reduction:IsHidden() return false end
function modifier_dildo_ultimate_magic_reduction:IsDebuff() return true end
function modifier_dildo_ultimate_magic_reduction:IsPurgable() return true end
function modifier_dildo_ultimate_magic_reduction:GetTexture() return "marci_unleash" end

function modifier_dildo_ultimate_magic_reduction:OnCreated()
    local ability = self:GetAbility()
    self.reduction = ability and ability:GetSpecialValueFor("magic_resistance_reduction") or 0
end

function modifier_dildo_ultimate_magic_reduction:OnRefresh()
    self:OnCreated()
end

function modifier_dildo_ultimate_magic_reduction:DeclareFunctions()
    return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_dildo_ultimate_magic_reduction:GetModifierMagicalResistanceBonus()
    return -self.reduction
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