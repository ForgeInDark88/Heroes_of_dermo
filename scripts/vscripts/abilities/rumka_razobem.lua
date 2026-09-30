LinkLuaModifier(
    "modifier_rumka_razobem_silence",
    "abilities/rumka_razobem",
    LUA_MODIFIER_MOTION_NONE
)

rumka_razobem = class({})



function rumka_razobem:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()

    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")
    local silence_duration = self:GetSpecialValueFor("silence_duration")
    local effect_duration = self:GetSpecialValueFor("effect_duration")

    --------------------------------------------------
    -- ЭФФЕКТ РАЗБИВАНИЯ
    --------------------------------------------------

    local particle = ParticleManager:CreateParticle(
        "particles/world_environmental_fx/water_splash_rocks_generic.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )

    -- Размер эффекта
    ParticleManager:SetParticleControl(
        particle,
        1,
        Vector(radius, 1, radius)
    )

    --------------------------------------------------
    -- ЗВУК
    --------------------------------------------------

    EmitSoundOn(
        "razobem",
        caster
    )

    --------------------------------------------------
    -- УРОН + SILENCE
    --------------------------------------------------

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do

        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        })

        enemy:AddNewModifier(
            caster,
            self,
            "modifier_rumka_razobem_silence",
            {
                duration = silence_duration
            }
        )
    end

    --------------------------------------------------
    -- УДАЛЯЕМ PARTICLE
    --------------------------------------------------

    local caster_ref = caster
    local particle_ref = particle

    caster:SetContextThink(
        "rumka_razobem_effect_" .. tostring(particle_ref),
        function()

            if particle_ref ~= nil then
                ParticleManager:DestroyParticle(
                    particle_ref,
                    false
                )

                ParticleManager:ReleaseParticleIndex(
                    particle_ref
                )
            end

            return nil
        end,
        effect_duration
    )
end

--------------------------------------------------
-- SILENCE
--------------------------------------------------

modifier_rumka_razobem_silence = class({})

function modifier_rumka_razobem_silence:IsHidden()
    return false
end

function modifier_rumka_razobem_silence:IsDebuff()
    return true
end

function modifier_rumka_razobem_silence:IsPurgable()
    return true
end

function modifier_rumka_razobem_silence:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

function modifier_rumka_razobem_silence:OnCreated()
    if not IsServer() then
        return
    end

    --------------------------------------------------
    -- ВИЗУАЛЬНЫЙ SILENCE
    --------------------------------------------------

    local parent = self:GetParent()

    self.silence_fx = ParticleManager:CreateParticle(
        "particles/generic_gameplay/generic_silence.vpcf",
        PATTACH_OVERHEAD_FOLLOW,
        parent
    )

    self:AddParticle(
        self.silence_fx,
        false,
        false,
        -1,
        false,
        false
    )
end