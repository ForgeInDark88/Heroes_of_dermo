-- Дилдочка: 1. Борьба под одеялом

if dildo_blanket_fight == nil then dildo_blanket_fight = class({}) end

LinkLuaModifier("modifier_dildo_blanket_fight", "abilities/dildochka_1_blanket_fight", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dildo_blanket_counter", "abilities/dildochka_1_blanket_fight", LUA_MODIFIER_MOTION_NONE)

function dildo_blanket_fight:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    caster:RemoveModifierByName("modifier_dildo_blanket_fight")
    caster:AddNewModifier(caster, self, "modifier_dildo_blanket_fight", { duration = duration })

    caster:EmitSound("Hero_Marci.Rebound")

    local p = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_marci/marci_rebound.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )
    ParticleManager:SetParticleControl(p, 0, caster:GetAbsOrigin())
    caster:CreateFOWViewer(caster:GetTeamNumber(), 250, 0.2, false)

    Timers:CreateTimer(duration, function()
        if not caster:IsNull() and caster:IsAlive() then
            caster:StopSound("Hero_Marci.Rebound")
            ParticleManager:DestroyParticle(p, false)
            ParticleManager:ReleaseParticleIndex(p)
        end
    end)
end

modifier_dildo_blanket_fight = class({})

function modifier_dildo_blanket_fight:IsHidden() return false end
function modifier_dildo_blanket_fight:IsPurgable() return false end
function modifier_dildo_blanket_fight:RemoveOnDeath() return true end
function modifier_dildo_blanket_fight:GetTexture() return "marci_rebound" end

function modifier_dildo_blanket_fight:OnCreated()
    self.targets = {}
end

function modifier_dildo_blanket_fight:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_dildo_blanket_fight:OnAttackLanded(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.attacker ~= parent then return end
    if not params.target or params.target:IsNull() then return end
    if params.target:GetTeamNumber() == parent:GetTeamNumber() then return end

    local ability = self:GetAbility()
    if not ability then return end

    local bonus = ability:GetSpecialValueFor("bonus_damage_per_hit")
    local hits_to_trigger = ability:GetSpecialValueFor("hits_to_trigger")
    local ministun_duration = ability:GetSpecialValueFor("ministun_duration")

    local counter = params.target:FindModifierByNameAndCaster(
        "modifier_dildo_blanket_counter",
        parent
    )

    if not counter then
        counter = params.target:AddNewModifier(parent, ability, "modifier_dildo_blanket_counter", {
            duration = self:GetRemainingTime()
        })
        if counter then
            table.insert(self.targets, params.target)
        end
    elseif self:GetRemainingTime() > 0 then
        counter:SetDuration(self:GetRemainingTime(), true)
    end

    if counter then
        counter:SetStackCount(counter:GetStackCount() + 1)

        local stack_particle = ParticleManager:CreateParticle(
            "particles/units/heroes/hero_marci/marci_rebound.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            params.target
        )
        ParticleManager:SetParticleControl(stack_particle, 0, params.target:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(stack_particle)

        params.target:EmitSound("Hero_Marci.ReboundLeap")

        if counter:GetStackCount() >= hits_to_trigger then
            counter:SetStackCount(0)
            params.target:AddNewModifier(parent, ability, "modifier_stunned", {
                duration = ministun_duration
            })
            params.target:EmitSound("Hero_Marci.Unleash")
        end
    end

    ApplyDamage({
        victim = params.target,
        attacker = parent,
        damage = bonus,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = ability,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
    })
end

function modifier_dildo_blanket_fight:OnDestroy()
    if not IsServer() then return end

    for _, target in pairs(self.targets or {}) do
        if target and not target:IsNull() then
            local counter = target:FindModifierByNameAndCaster(
                "modifier_dildo_blanket_counter",
                self:GetParent()
            )
            if counter then
                counter:Destroy()
            end
        end
    end
end

modifier_dildo_blanket_counter = class({})

function modifier_dildo_blanket_counter:IsHidden() return false end
function modifier_dildo_blanket_counter:IsPurgable() return false end
function modifier_dildo_blanket_counter:RemoveOnDeath() return true end
function modifier_dildo_blanket_counter:GetTexture() return "marci_rebound" end
