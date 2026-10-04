ability_summon_cat = class({})
LinkLuaModifier("modifier_cat_passive", "abilities/ability_summon_cat.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cat_damage_reduction", "abilities/ability_summon_cat.lua", LUA_MODIFIER_MOTION_NONE)

function ability_summon_cat:OnSpellStart()
    local caster = self:GetCaster()
    local point = caster:GetAbsOrigin() + caster:GetForwardVector() * 150

    local duration = self:GetSpecialValueFor("cat_duration")
    -- Шард: котик живёт дольше
    if caster:HasShard() then
        duration = self:GetSpecialValueFor("shard_cat_duration")
    end
    local cat_hp = self:GetSpecialValueFor("cat_hp")
    local cat_damage = self:GetSpecialValueFor("cat_damage")

    -- Создаем котика
    local cat = CreateUnitByName("npc_dota_creature_cat", point, true, caster, caster, caster:GetTeamNumber())
    cat:SetOwner(caster)
    cat:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    
    -- Устанавливаем характеристики котика в зависимости от уровня абилки
    cat:SetBaseMaxHealth(cat_hp)
    cat:SetMaxHealth(cat_hp)
    cat:SetHealth(cat_hp)
    cat:SetBaseDamageMin(cat_damage)
    cat:SetBaseDamageMax(cat_damage)

    -- Таймер жизни юнита
    cat:AddNewModifier(caster, self, "modifier_kill", {duration = duration})

    -- Вешаем пассивку для обработки ударов
    cat:AddNewModifier(caster, self, "modifier_cat_passive", {})
end

--------------------------------------------------------------------------------
-- Пассивная логика котика (крик при получении урона)
--------------------------------------------------------------------------------
modifier_cat_passive = class({})

function modifier_cat_passive:IsHidden() return true end
function modifier_cat_passive:IsPurgable() return false end

function modifier_cat_passive:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_cat_passive:OnTakeDamage(keys)
    if not IsServer() then return end

    if keys.unit ~= self:GetParent() then return end

    local attacker = keys.attacker
    if not attacker or attacker:IsNull() then return end

    if self.bOnCooldown then return end

    local cat = self:GetParent()
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    local radius = ability:GetSpecialValueFor("scream_radius")
    local debuff_duration = ability:GetSpecialValueFor("debuff_duration")
    local cooldown = ability:GetSpecialValueFor("scream_cooldown")

    self.bOnCooldown = true
    cat:SetContextThink("ResetCatScreamCD", function()
        self.bOnCooldown = false
        return nil
    end, cooldown)

    -- Звук крика
    cat:EmitSound("Hero_QueenOfPain.ScreamOfPain")

    -- Поиск врагов вокруг котика
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

    -- Запуск снарядов-криков точно во врагов и наложение дебаффа
    for _, enemy in pairs(enemies) do
        local info = {
            Target = enemy,
            Source = cat,
            Ability = ability,
            EffectName = "particles/units/heroes/hero_queenofpain/queen_scream_of_pain.vpcf",
            iMoveSpeed = 900,
            bDodgeable = false,
            bReplaceExisting = false,
            iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
        }
        ProjectileManager:CreateTrackingProjectile(info)

        -- Накладываем дебафф снижения урона
        enemy:AddNewModifier(cat, ability, "modifier_cat_damage_reduction", {duration = debuff_duration})
    end
end

--------------------------------------------------------------------------------
-- Дебафф на врагов (снижает исходящий урон)
--------------------------------------------------------------------------------
modifier_cat_damage_reduction = class({})

function modifier_cat_damage_reduction:IsDebuff() return true end
function modifier_cat_damage_reduction:IsPurgable() return true end

function modifier_cat_damage_reduction:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
    }
end

function modifier_cat_damage_reduction:GetModifierBaseDamageOutgoing_Percentage()
    if self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("damage_reduction_pct")
    end
    return -15
end