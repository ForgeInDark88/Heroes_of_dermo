-- Катька: ульта "Смена цвета"
-- Катька перекрашивает волосы: она и её существа (Гарик, Боня) перекрашиваются
-- и быстро бегают, а Катька ещё и получает дополнительный урон атаки.
-- Аганим: при применении рядом появляются Гарик и Боня (если способности изучены),
-- даже если они ещё на перезарядке.

katka_color_change = class({})

LinkLuaModifier("modifier_katka_color_change", "abilities/katka_color_change", LUA_MODIFIER_MOTION_NONE)

-- Яркие цвета волос, выбирается случайный
local KATKA_COLORS = {
    Vector(255, 60, 200),   -- розовый
    Vector(60, 200, 255),   -- голубой
    Vector(120, 255, 80),   -- кислотно-зелёный
    Vector(180, 90, 255),   -- фиолетовый
    Vector(255, 150, 30),   -- оранжевый
}

-- Повесить бафф ульты на юнита, если Катька сейчас под ультой.
-- Зовётся и при призыве котов во время ульты (katka_garik, katka_bonnya).
function KatkaApplyColorBuff(caster, unit)
    local buff = caster:FindModifierByName("modifier_katka_color_change")
    if not buff or unit == caster then return end

    unit:AddNewModifier(caster, buff:GetAbility(), "modifier_katka_color_change", {
        duration = buff:GetRemainingTime(),
        color = buff.color_index,
    })
end

function katka_color_change:OnSpellStart()
    local caster = self:GetCaster()
    local color_index = RandomInt(1, #KATKA_COLORS)

    caster:AddNewModifier(caster, self, "modifier_katka_color_change", {
        duration = self:GetSpecialValueFor("duration"),
        color = color_index,
    })

    -- Аганим: призывает обоих котов
    if caster:HasScepter() then
        local forward = caster:GetForwardVector()
        local right = Vector(forward.y, -forward.x, 0)
        local origin = caster:GetAbsOrigin()

        local garik = caster:FindAbilityByName("katka_garik")
        if garik and garik:GetLevel() > 0 then
            garik:SpawnCat(origin + forward * 150 + right * 120)
        end

        local bonnya = caster:FindAbilityByName("katka_bonnya")
        if bonnya and bonnya:GetLevel() > 0 then
            bonnya:SpawnCat(origin + forward * 150 - right * 120)
        end
    end

    -- Все уже живые существа Катьки
    local allies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        FIND_UNITS_EVERYWHERE,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
        FIND_ANY_ORDER,
        false
    )
    for _, unit in pairs(allies) do
        if unit:GetOwner() == caster and not unit:HasModifier("modifier_katka_color_change") then
            KatkaApplyColorBuff(caster, unit)
        end
    end

    caster:EmitSound("Ability.Focusfire")
end

--------------------------------------------------------------------------------
-- ПЕРЕКРАШЕН: скорость (всем), урон атаки (только Катьке)
--------------------------------------------------------------------------------

modifier_katka_color_change = class({})

function modifier_katka_color_change:IsHidden() return false end
function modifier_katka_color_change:IsDebuff() return false end
function modifier_katka_color_change:IsPurgable() return false end

function modifier_katka_color_change:OnCreated(kv)
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
        self.move_speed = ability:GetSpecialValueFor("move_speed")
        self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    end

    if not IsServer() then return end

    self.color_index = kv.color or 1
    self:Paint(KATKA_COLORS[self.color_index] or KATKA_COLORS[1])
end

function modifier_katka_color_change:OnDestroy()
    if not IsServer() then return end
    self:Paint(Vector(255, 255, 255))
end

-- Красим модель и все её предметы-косметику (волосы — это косметика)
function modifier_katka_color_change:Paint(color)
    local parent = self:GetParent()
    if not parent or parent:IsNull() then return end

    parent:SetRenderColor(color.x, color.y, color.z)
    for _, child in pairs(parent:GetChildren()) do
        if child and not child:IsNull() and child:GetClassname() == "dota_item_wearable" then
            child:SetRenderColor(color.x, color.y, color.z)
        end
    end
end

function modifier_katka_color_change:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_katka_color_change:GetModifierMoveSpeedBonus_Percentage()
    return self.move_speed or 0
end

function modifier_katka_color_change:GetModifierPreAttack_BonusDamage()
    if self:GetParent() ~= self:GetCaster() then return 0 end
    return self.bonus_damage or 0
end

function modifier_katka_color_change:GetEffectName()
    return "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf"
end

function modifier_katka_color_change:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
