------------------------------------------------------------
-- HOOKAH OF HAZE
-- Пассивно: здоровье, интеллект, вампиризм заклинаниями,
-- броня, реген маны.
-- Активка "Hookah party": волна дыма в радиусе. Дымок наносит
-- урон в секунду (фикс + % от макс. здоровья) и увеличивает
-- получаемый целью магический урон.
------------------------------------------------------------

LinkLuaModifier("modifier_item_hookah_of_haze", "items/item_hookah_of_haze", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_hookah_of_haze_smoke", "items/item_hookah_of_haze", LUA_MODIFIER_MOTION_NONE)

item_hookah_of_haze = class({})

function item_hookah_of_haze:GetIntrinsicModifierName()
    return "modifier_item_hookah_of_haze"
end

function item_hookah_of_haze:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function item_hookah_of_haze:OnSpellStart()
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    local duration = self:GetSpecialValueFor("duration")

    local particle = ParticleManager:CreateParticle(
        "particles/items2_fx/veil_of_discord.vpcf",
        PATTACH_ABSORIGIN,
        caster
    )
    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(particle)

    caster:EmitSound("DOTA_Item.VeilofDiscord.Activate")

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE, -- не проходит сквозь невосприимчивость к эффектам
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(caster, self, "modifier_item_hookah_of_haze_smoke", { duration = duration })
    end
end

------------------------------------------------------------
-- ПАССИВКА
------------------------------------------------------------

modifier_item_hookah_of_haze = class({})

function modifier_item_hookah_of_haze:IsHidden() return true end
function modifier_item_hookah_of_haze:IsPurgable() return false end
function modifier_item_hookah_of_haze:RemoveOnDeath() return false end
function modifier_item_hookah_of_haze:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_hookah_of_haze:OnCreated()
    local ability = self:GetAbility()
    if not ability then return end

    self.health = ability:GetSpecialValueFor("bonus_health")
    self.intellect = ability:GetSpecialValueFor("bonus_intellect")
    self.spell_lifesteal = ability:GetSpecialValueFor("spell_lifesteal")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_hookah_of_haze:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_item_hookah_of_haze:GetModifierHealthBonus() return self.health or 0 end
function modifier_item_hookah_of_haze:GetModifierBonusStats_Intellect() return self.intellect or 0 end
function modifier_item_hookah_of_haze:GetModifierPhysicalArmorBonus() return self.armor or 0 end
function modifier_item_hookah_of_haze:GetModifierConstantManaRegen() return self.mana_regen or 0 end

-- Вампиризм заклинаниями: лечит на % урона, нанесённого способностями.
-- Несколько кальянов не складываются.
function modifier_item_hookah_of_haze:OnTakeDamage(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.attacker ~= parent then return end
    if not params.inflictor or params.inflictor:IsNull() then return end
    if params.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= 0 then return end
    if params.unit == parent or params.unit:IsBuilding() then return end
    if parent:FindAllModifiersByName(self:GetName())[1] ~= self then return end

    local heal = params.damage * (self.spell_lifesteal or 0) / 100
    if heal <= 0 then return end

    parent:Heal(heal, self:GetAbility())

    local fx = ParticleManager:CreateParticle(
        "particles/items3_fx/octarine_core_lifesteal.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        parent
    )
    ParticleManager:ReleaseParticleIndex(fx)
end

------------------------------------------------------------
-- ДЫМОК (на враге)
------------------------------------------------------------

modifier_item_hookah_of_haze_smoke = class({})

function modifier_item_hookah_of_haze_smoke:IsHidden() return false end
function modifier_item_hookah_of_haze_smoke:IsDebuff() return true end
function modifier_item_hookah_of_haze_smoke:IsPurgable() return true end
function modifier_item_hookah_of_haze_smoke:GetTexture() return "item_veil_of_discord" end

function modifier_item_hookah_of_haze_smoke:GetEffectName()
    return "particles/items2_fx/veil_of_discord_debuff.vpcf"
end

function modifier_item_hookah_of_haze_smoke:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_hookah_of_haze_smoke:OnCreated()
    local ability = self:GetAbility()
    self.damage_per_sec = ability and ability:GetSpecialValueFor("damage_per_sec") or 0
    self.damage_max_hp_pct = ability and ability:GetSpecialValueFor("damage_max_hp_pct") or 0
    self.magic_amp = ability and ability:GetSpecialValueFor("magic_damage_amp") or 0

    if IsServer() then
        self:StartIntervalThink(1.0)
    end
end

function modifier_item_hookah_of_haze_smoke:OnRefresh()
    self:OnCreated()
end

function modifier_item_hookah_of_haze_smoke:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    if not caster or caster:IsNull() then return end

    ApplyDamage({
        victim = parent,
        attacker = caster,
        damage = self.damage_per_sec + parent:GetMaxHealth() * self.damage_max_hp_pct / 100,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(),
    })
end

function modifier_item_hookah_of_haze_smoke:DeclareFunctions()
    return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_item_hookah_of_haze_smoke:GetModifierIncomingDamage_Percentage(params)
    if params.damage_type == DAMAGE_TYPE_MAGICAL then
        return self.magic_amp
    end
    return 0
end
