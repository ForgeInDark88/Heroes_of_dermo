-- Катька: 1. Гарик
-- Призывает толстого кота Гарика (подчиняется Катьке). У Гарика есть Агр —
-- как Berserker's Call у Акса: враги вокруг вынуждены бить Гарика, а он
-- получает дополнительную броню. Агр включён на автоприменение: Гарик сам
-- кидает его, когда рядом есть вражеский герой. Одновременно жив только один Гарик.
--
-- Значения Агра берутся из способности Катьки (katka_garik), чтобы на них
-- действовали её таланты.

katka_garik = class({})
katka_garik_agr = class({})

LinkLuaModifier("modifier_katka_garik_ai", "abilities/katka_garik", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_katka_garik_agr_armor", "abilities/katka_garik", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_katka_garik_taunt", "abilities/katka_garik", LUA_MODIFIER_MOTION_NONE)

KATKA_GARIK_UNIT = "npc_katka_garik"

function katka_garik:OnSpellStart()
    self:SpawnCat(self:GetCaster():GetAbsOrigin() + self:GetCaster():GetForwardVector() * 150)
    self:GetCaster():EmitSound("Hero_Beastmaster.Call.Boar")
end

-- Вызывается и из аганима ульты (katka_color_change)
function katka_garik:SpawnCat(position)
    local caster = self:GetCaster()

    if self.cat and not self.cat:IsNull() and self.cat:IsAlive() then
        self.cat:ForceKill(false)
    end

    local cat = CreateUnitByName(KATKA_GARIK_UNIT, position, true, caster, caster, caster:GetTeamNumber())
    if not cat then
        print("[KATKA] ERROR: не удалось создать " .. KATKA_GARIK_UNIT)
        return nil
    end
    self.cat = cat

    cat:SetOwner(caster)
    cat:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    FindClearSpaceForUnit(cat, position, true)

    local hp = self:GetSpecialValueFor("garik_hp")
    cat:SetBaseMaxHealth(hp)
    cat:SetMaxHealth(hp)
    cat:SetHealth(hp)
    cat:SetPhysicalArmorBaseValue(self:GetSpecialValueFor("garik_armor"))
    cat:SetBaseDamageMin(self:GetSpecialValueFor("garik_damage"))
    cat:SetBaseDamageMax(self:GetSpecialValueFor("garik_damage"))

    local agr = cat:FindAbilityByName("katka_garik_agr")
    if agr then
        agr:SetLevel(self:GetLevel())
        agr.owner_ability = self
        if not agr:GetAutoCastState() then
            agr:ToggleAutoCast()
        end
    end

    cat:AddNewModifier(caster, self, "modifier_kill", { duration = self:GetSpecialValueFor("duration") })
    cat:AddNewModifier(caster, self, "modifier_katka_garik_ai", {})

    -- Если ульта уже идёт — новый кот тоже бегает быстро
    if KatkaApplyColorBuff then
        KatkaApplyColorBuff(caster, cat)
    end

    return cat
end

--------------------------------------------------------------------------------
-- АГР (способность самого Гарика)
--------------------------------------------------------------------------------

function katka_garik_agr:GetOwnerValue(key)
    local owner_ability = self.owner_ability
    if owner_ability and not owner_ability:IsNull() then
        return owner_ability:GetSpecialValueFor(key)
    end
    return self:GetSpecialValueFor(key)
end

function katka_garik_agr:OnSpellStart()
    local cat = self:GetCaster()
    local radius = self:GetOwnerValue("agr_radius")
    local duration = self:GetOwnerValue("agr_duration")

    local enemies = FindUnitsInRadius(
        cat:GetTeamNumber(),
        cat:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(cat, self, "modifier_katka_garik_taunt", { duration = duration })
    end

    cat:AddNewModifier(cat, self, "modifier_katka_garik_agr_armor", { duration = duration })

    local fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        cat
    )
    ParticleManager:SetParticleControl(fx, 2, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(fx)

    cat:EmitSound("Hero_Axe.Berserkers_Call")
end

--------------------------------------------------------------------------------
-- ИИ ГАРИКА: сам кидает Агр, если включено автоприменение
--------------------------------------------------------------------------------

modifier_katka_garik_ai = class({})

function modifier_katka_garik_ai:IsHidden() return true end
function modifier_katka_garik_ai:IsPurgable() return false end

function modifier_katka_garik_ai:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(0.25)
end

function modifier_katka_garik_ai:OnIntervalThink()
    local cat = self:GetParent()
    if not cat:IsAlive() or cat:IsSilenced() or cat:IsStunned() then return end

    local agr = cat:FindAbilityByName("katka_garik_agr")
    if not agr or not agr:GetAutoCastState() or not agr:IsFullyCastable() then return end

    local heroes = FindUnitsInRadius(
        cat:GetTeamNumber(),
        cat:GetAbsOrigin(),
        nil,
        agr:GetOwnerValue("agr_radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_ANY_ORDER,
        false
    )

    if #heroes > 0 then
        cat:CastAbilityNoTarget(agr, cat:GetPlayerOwnerID())
    end
end

--------------------------------------------------------------------------------
-- БРОНЯ ГАРИКА ВО ВРЕМЯ АГРА
--------------------------------------------------------------------------------

modifier_katka_garik_agr_armor = class({})

function modifier_katka_garik_agr_armor:IsHidden() return false end
function modifier_katka_garik_agr_armor:IsPurgable() return false end

-- Значение берётся на сервере (там известна способность Катьки) и передаётся клиенту стаками
function modifier_katka_garik_agr_armor:OnCreated()
    if not IsServer() then return end
    local ability = self:GetAbility()
    self:SetStackCount(ability and not ability:IsNull() and ability:GetOwnerValue("agr_bonus_armor") or 0)
end

function modifier_katka_garik_agr_armor:DeclareFunctions()
    return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_katka_garik_agr_armor:GetModifierPhysicalArmorBonus()
    return self:GetStackCount()
end

--------------------------------------------------------------------------------
-- АГР НА ВРАГЕ: обязан бить Гарика
--------------------------------------------------------------------------------

modifier_katka_garik_taunt = class({})

function modifier_katka_garik_taunt:IsHidden() return false end
function modifier_katka_garik_taunt:IsDebuff() return true end
function modifier_katka_garik_taunt:IsPurgable() return false end

function modifier_katka_garik_taunt:OnCreated()
    if not IsServer() then return end
    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_katka_garik_taunt:OnIntervalThink()
    local parent = self:GetParent()
    local cat = self:GetCaster()

    if not cat or cat:IsNull() or not cat:IsAlive() then
        self:Destroy()
        return
    end

    parent:SetForceAttackTarget(nil)
    parent:MoveToTargetToAttack(cat)
    parent:SetForceAttackTarget(cat)
end

function modifier_katka_garik_taunt:OnDestroy()
    if not IsServer() then return end
    self:GetParent():SetForceAttackTarget(nil)
end

function modifier_katka_garik_taunt:CheckState()
    return {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
end

function modifier_katka_garik_taunt:GetStatusEffectName()
    return "particles/status_fx/status_effect_beserkers_call.vpcf"
end
