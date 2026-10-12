-- Катька: 2. Боння
-- Призывает кота Боню (подчиняется Катьке): быстро бьёт и наносит много урона.
-- У Бони есть Бег — как Windrun у Windranger: ускорение и уклонение от атак.
-- Бег включён на автоприменение: Боня сам кидает его, когда рядом вражеский герой.
-- Одновременно жив только один Боня.
--
-- Значения Бега берутся из способности Катьки (katka_bonnya), чтобы на них
-- действовали её таланты.

katka_bonnya = class({})
katka_bonnya_run = class({})

LinkLuaModifier("modifier_katka_bonnya_ai", "abilities/katka_bonnya", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_katka_bonnya_run", "abilities/katka_bonnya", LUA_MODIFIER_MOTION_NONE)

KATKA_BONNYA_UNIT = "npc_katka_bonnya"

function katka_bonnya:OnSpellStart()
    self:SpawnCat(self:GetCaster():GetAbsOrigin() + self:GetCaster():GetForwardVector() * 150)
    self:GetCaster():EmitSound("Hero_Beastmaster.Call.Hawk")
end

-- Вызывается и из аганима ульты (katka_color_change)
function katka_bonnya:SpawnCat(position)
    local caster = self:GetCaster()

    if self.cat and not self.cat:IsNull() and self.cat:IsAlive() then
        self.cat:ForceKill(false)
    end

    local cat = CreateUnitByName(KATKA_BONNYA_UNIT, position, true, caster, caster, caster:GetTeamNumber())
    if not cat then
        print("[KATKA] ERROR: не удалось создать " .. KATKA_BONNYA_UNIT)
        return nil
    end
    self.cat = cat

    cat:SetOwner(caster)
    cat:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    FindClearSpaceForUnit(cat, position, true)

    local hp = self:GetSpecialValueFor("bonnya_hp")
    cat:SetBaseMaxHealth(hp)
    cat:SetMaxHealth(hp)
    cat:SetHealth(hp)
    cat:SetBaseDamageMin(self:GetSpecialValueFor("bonnya_damage"))
    cat:SetBaseDamageMax(self:GetSpecialValueFor("bonnya_damage"))

    local run = cat:FindAbilityByName("katka_bonnya_run")
    if run then
        run:SetLevel(self:GetLevel())
        run.owner_ability = self
        if not run:GetAutoCastState() then
            run:ToggleAutoCast()
        end
    end

    cat:AddNewModifier(caster, self, "modifier_kill", { duration = self:GetSpecialValueFor("duration") })
    cat:AddNewModifier(caster, self, "modifier_katka_bonnya_ai", {})

    -- Если ульта уже идёт — новый кот тоже бегает быстро
    if KatkaApplyColorBuff then
        KatkaApplyColorBuff(caster, cat)
    end

    return cat
end

--------------------------------------------------------------------------------
-- БЕГ (способность самого Бони)
--------------------------------------------------------------------------------

function katka_bonnya_run:GetOwnerValue(key)
    local owner_ability = self.owner_ability
    if owner_ability and not owner_ability:IsNull() then
        return owner_ability:GetSpecialValueFor(key)
    end
    return self:GetSpecialValueFor(key)
end

function katka_bonnya_run:OnSpellStart()
    local cat = self:GetCaster()

    cat:AddNewModifier(cat, self, "modifier_katka_bonnya_run", {
        duration = self:GetOwnerValue("run_duration")
    })
    cat:EmitSound("Ability.Windrun")
end

--------------------------------------------------------------------------------
-- ИИ БОНИ: сам бежит, если включено автоприменение и рядом вражеский герой
--------------------------------------------------------------------------------

modifier_katka_bonnya_ai = class({})

function modifier_katka_bonnya_ai:IsHidden() return true end
function modifier_katka_bonnya_ai:IsPurgable() return false end

function modifier_katka_bonnya_ai:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(0.25)
end

function modifier_katka_bonnya_ai:OnIntervalThink()
    local cat = self:GetParent()
    if not cat:IsAlive() or cat:IsSilenced() or cat:IsStunned() then return end

    local run = cat:FindAbilityByName("katka_bonnya_run")
    if not run or not run:GetAutoCastState() or not run:IsFullyCastable() then return end

    local heroes = FindUnitsInRadius(
        cat:GetTeamNumber(),
        cat:GetAbsOrigin(),
        nil,
        700,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_ANY_ORDER,
        false
    )

    if #heroes > 0 then
        cat:CastAbilityNoTarget(run, cat:GetPlayerOwnerID())
    end
end

--------------------------------------------------------------------------------
-- БЕГ: ускорение и уклонение от атак
--------------------------------------------------------------------------------

modifier_katka_bonnya_run = class({})

function modifier_katka_bonnya_run:IsHidden() return false end
function modifier_katka_bonnya_run:IsPurgable() return true end

-- Значения берутся на сервере (там известна способность Катьки); скорость
-- передаётся клиенту стаками
function modifier_katka_bonnya_run:OnCreated()
    if not IsServer() then return end
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    self:SetStackCount(ability:GetOwnerValue("run_move_speed"))
    self.evasion = ability:GetOwnerValue("run_evasion")
end

function modifier_katka_bonnya_run:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
    }
end

function modifier_katka_bonnya_run:GetModifierMoveSpeedBonus_Percentage()
    return self:GetStackCount()
end

function modifier_katka_bonnya_run:GetModifierEvasion_Constant()
    return self.evasion or 0
end

function modifier_katka_bonnya_run:GetEffectName()
    return "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf"
end

function modifier_katka_bonnya_run:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
