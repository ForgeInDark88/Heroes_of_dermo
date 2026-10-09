-- Русик: Гревсы на энигму (шард)
-- Русик покупает гревсы: лечит себя и союзных героев рядом, а вражеских
-- героев поблизости пугает — они на fear_duration сек. убегают от Русика.

rusik_greaves = class({})

LinkLuaModifier("modifier_rusik_greaves_fear", "abilities/rusik_greaves", LUA_MODIFIER_MOTION_NONE)

function rusik_greaves:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local heal = self:GetSpecialValueFor("heal")

    local fx = ParticleManager:CreateParticle("particles/items3_fx/warmage.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(fx)
    caster:EmitSound("Item.GuardianGreaves.Activate")

    local allies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        self:GetSpecialValueFor("heal_radius"),
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )
    for _, ally in pairs(allies) do
        ally:Heal(heal, self)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal, nil)

        local heal_fx = ParticleManager:CreateParticle("particles/items3_fx/warmage_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, ally)
        ParticleManager:ReleaseParticleIndex(heal_fx)
        if ally ~= caster then
            ally:EmitSound("Item.GuardianGreaves.Target")
        end
    end

    local roar = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_lone_druid/lone_druid_savage_roar.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )
    ParticleManager:ReleaseParticleIndex(roar)

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        self:GetSpecialValueFor("fear_radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )
    local duration = self:GetSpecialValueFor("fear_duration")
    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(caster, self, "modifier_rusik_greaves_fear", {
            duration = duration * (1 - enemy:GetStatusResistance())
        })
    end
    if #enemies > 0 then
        caster:EmitSound("Hero_LoneDruid.SavageRoar.Cast")
    end
end

--------------------------------------------------------------------------------
-- СТРАХ: цель убегает от Русика
--------------------------------------------------------------------------------

modifier_rusik_greaves_fear = class({})

function modifier_rusik_greaves_fear:IsHidden() return false end
function modifier_rusik_greaves_fear:IsDebuff() return true end
function modifier_rusik_greaves_fear:IsPurgable() return true end

function modifier_rusik_greaves_fear:OnCreated()
    if not IsServer() then return end
    self.source = self:GetCaster():GetAbsOrigin()
    self:RunAway()
    self:StartIntervalThink(0.1)
end

function modifier_rusik_greaves_fear:OnIntervalThink()
    self:RunAway()
end

function modifier_rusik_greaves_fear:RunAway()
    local parent = self:GetParent()
    local direction = parent:GetAbsOrigin() - self.source
    direction.z = 0
    if direction:Length2D() < 1 then
        direction = parent:GetForwardVector()
    end
    parent:MoveToPosition(parent:GetAbsOrigin() + direction:Normalized() * 400)
end

function modifier_rusik_greaves_fear:OnDestroy()
    if not IsServer() then return end
    self:GetParent():Stop()
end

function modifier_rusik_greaves_fear:CheckState()
    return {
        [MODIFIER_STATE_FEARED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
end

function modifier_rusik_greaves_fear:GetStatusEffectName()
    return "particles/status_fx/status_effect_lone_druid_savage_roar.vpcf"
end

function modifier_rusik_greaves_fear:GetEffectName()
    return "particles/units/heroes/hero_lone_druid/lone_druid_savage_roar_debuff.vpcf"
end

function modifier_rusik_greaves_fear:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
