-- Катька: врождёнка "Соевое мясо"
-- Универсальное уклонение от одного вражеского скилла, потом перезарядка:
--   * направленный скилл блокируется целиком (как Linken's Sphere);
--   * ненаправленный — Катька не получает его урон, а наложенные им эффекты сразу снимаются.
-- Предметы не блокирует. Не работает у иллюзий. Отключается истощением.

katka_soy_meat = class({})

LinkLuaModifier("modifier_katka_soy_meat", "abilities/katka_soy_meat", LUA_MODIFIER_MOTION_NONE)

function katka_soy_meat:Spawn()
    if IsServer() and self:GetLevel() == 0 then
        self:SetLevel(1)
    end
end

function katka_soy_meat:GetIntrinsicModifierName()
    return "modifier_katka_soy_meat"
end

function katka_soy_meat:GetCooldown(level)
    return self:GetSpecialValueFor("cooldown")
end

modifier_katka_soy_meat = class({})

function modifier_katka_soy_meat:IsHidden() return true end
function modifier_katka_soy_meat:IsPurgable() return false end
function modifier_katka_soy_meat:RemoveOnDeath() return false end

function modifier_katka_soy_meat:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    if ability and not ability:IsNull() and ability:GetLevel() == 0 then
        ability:SetLevel(1)
    end
end

function modifier_katka_soy_meat:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSORB_SPELL,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

-- Готово ли уклонение против этого скилла
function modifier_katka_soy_meat:CanDodge(source_ability)
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not ability or ability:IsNull() or not ability:IsCooldownReady() then return false end
    if parent:IsIllusion() or parent:PassivesDisabled() then return false end
    if not source_ability or source_ability:IsNull() or source_ability:IsItem() then return false end

    local caster = source_ability:GetCaster()
    return caster and not caster:IsNull() and caster:GetTeamNumber() ~= parent:GetTeamNumber()
end

function modifier_katka_soy_meat:Dodge(source_ability)
    local parent = self:GetParent()
    local ability = self:GetAbility()

    ability:StartCooldown(ability:GetEffectiveCooldown(ability:GetLevel()))

    -- Ещё мгновение режем урон этого же скилла (многоразовые попадания одного каста)
    self.dodged_ability = source_ability
    self.dodged_until = GameRules:GetGameTime() + 0.1

    local fx = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_POINT_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(fx, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(fx)
    parent:EmitSound("DOTA_Item.LinkensSphere.Activate")
end

function modifier_katka_soy_meat:GetAbsorbSpell(params)
    if not IsServer() then return 0 end

    if self:CanDodge(params.ability) then
        self:Dodge(params.ability)
        return 1
    end
    return 0
end

function modifier_katka_soy_meat:GetModifierIncomingDamage_Percentage(params)
    if not IsServer() then return 0 end

    local inflictor = params.inflictor
    if not inflictor or inflictor:IsNull() then return 0 end

    if self.dodged_ability == inflictor and GameRules:GetGameTime() <= (self.dodged_until or 0) then
        self:ClearEffectsOf(inflictor)
        return -100
    end

    if self:CanDodge(inflictor) then
        self:Dodge(inflictor)
        self:ClearEffectsOf(inflictor)
        return -100
    end

    return 0
end

-- Эффекты скилла вешаются в том же кадре, что и урон, — снимаем их чуть позже
function modifier_katka_soy_meat:ClearEffectsOf(source_ability)
    local parent = self:GetParent()

    Timers:CreateTimer(0.03, function()
        if not parent or parent:IsNull() or not source_ability or source_ability:IsNull() then return end

        for _, modifier in pairs(parent:FindAllModifiers()) do
            if modifier:GetAbility() == source_ability and modifier:GetCaster() ~= parent then
                modifier:Destroy()
            end
        end
    end)
end
