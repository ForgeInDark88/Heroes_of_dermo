custom_doom_aura = class({})
LinkLuaModifier("modifier_custom_doom_aura_caster", "abilities/custom_doom_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_doom_aura_effect", "abilities/custom_doom_aura", LUA_MODIFIER_MOTION_NONE)

function custom_doom_aura:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    caster:EmitSound("midas")

    caster:RemoveModifierByName("modifier_custom_doom_aura_caster")
    caster:AddNewModifier(caster, self, "modifier_custom_doom_aura_caster", { duration = duration })
end

--------------------------------------------------------------------------------
-- МОДИФИКАТОР КАСТЕРА (Излучатель + Партикл Пентаграммы)
--------------------------------------------------------------------------------
modifier_custom_doom_aura_caster = class({})

function modifier_custom_doom_aura_caster:IsHidden() return false end
function modifier_custom_doom_aura_caster:IsPurgable() return false end

function modifier_custom_doom_aura_caster:OnCreated()
    if not IsServer() then return end

    local caster = self:GetParent()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")

   self.nFXIndex = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_doom_bringer/doom_bringer_doom_aura.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        caster
    )
    -- Для doom_aura CP1 задает радиус
    ParticleManager:SetParticleControl(self.nFXIndex, 1, Vector(radius, 1, 1))
    self:StartIntervalThink(0.1)
end

function modifier_custom_doom_aura_caster:OnIntervalThink()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()
    if not caster or caster:IsNull() or not ability or ability:IsNull() then return end

    local radius = ability:GetSpecialValueFor("radius")

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(caster, ability, "modifier_custom_doom_aura_effect", { duration = 0.25 })
    end
end

function modifier_custom_doom_aura_caster:OnDestroy()
    if not IsServer() then return end

    -- Удаляем партикл пентаграммы при завершении действия
    if self.nFXIndex then
        ParticleManager:DestroyParticle(self.nFXIndex, false)
        ParticleManager:ReleaseParticleIndex(self.nFXIndex)
    end
end

--------------------------------------------------------------------------------
-- ДЕБАФФ ЭФФЕКТ (Дум + Замедление + Магрезист + Золото)
--------------------------------------------------------------------------------
modifier_custom_doom_aura_effect = class({})

function modifier_custom_doom_aura_effect:IsHidden() return false end
function modifier_custom_doom_aura_effect:IsDebuff() return true end
function modifier_custom_doom_aura_effect:IsPurgable() return false end


function modifier_custom_doom_aura_effect:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
end

function modifier_custom_doom_aura_effect:GetModifierMoveSpeedBonus_Percentage()
    if self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("move_speed_slow")
    end
    return -15
end

function modifier_custom_doom_aura_effect:GetModifierMagicalResistanceBonus()
    if self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("spell_resist_reduction")
    end
    return -10
end

function modifier_custom_doom_aura_effect:OnCreated()
    if not IsServer() then return end
    
    local interval = 1.0
    if self:GetAbility() then
        interval = self:GetAbility():GetSpecialValueFor("tick_interval")
    end
    self:StartIntervalThink(interval)

    -- Эффект Дума над головой жертвы
    self.nFXIndex = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        self:GetParent()
    )
    ParticleManager:SetParticleControlEnt(self.nFXIndex, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
end

function modifier_custom_doom_aura_effect:OnIntervalThink()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetParent()

    if caster and not caster:IsNull() and caster:HasScepter() and target:IsRealHero() then
        local gold_to_steal = 20
        if self:GetAbility() then
            gold_to_steal = self:GetAbility():GetSpecialValueFor("gold_steal_per_tick_scepter")
        end
        
        local target_gold = target:GetGold()
        local actual_steal = math.min(target_gold, gold_to_steal)

        if actual_steal > 0 then
            target:SpendGold(actual_steal, DOTA_ModifyGold_Unspecified)
            caster:ModifyGold(actual_steal, true, DOTA_ModifyGold_Unspecified)
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, target, actual_steal, nil)
        end
    end
end

function modifier_custom_doom_aura_effect:OnDestroy()
    if not IsServer() then return end
    if self.nFXIndex then
        ParticleManager:DestroyParticle(self.nFXIndex, false)
        ParticleManager:ReleaseParticleIndex(self.nFXIndex)
    end
end