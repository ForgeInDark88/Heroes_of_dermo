LinkLuaModifier(
    "modifier_rumka_razobem_silence",
    "abilities/rumka_razobem",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_rumka_razobem_scepter",
    "abilities/rumka_razobem",
    LUA_MODIFIER_MOTION_NONE
)

rumka_razobem = class({})


--------------------------------------------------
-- PRECACHE
--------------------------------------------------

function rumka_razobem:Precache(context)

    PrecacheResource(
        "particle",
        "particles/units/heroes/hero_pudge/pudge_rot.vpcf",
        context
    )

    PrecacheResource(
        "particle",
        "particles/generic_gameplay/generic_silence.vpcf",
        context
    )

    PrecacheResource(
        "soundfile",
        "soundevents/game_sounds_heroes/game_sounds_pudge.vsndevts",
        context
    )
end


--------------------------------------------------
-- AGHANIM PASSIVE
--------------------------------------------------

function rumka_razobem:GetIntrinsicModifierName()
    return "modifier_rumka_razobem_scepter"
end


--------------------------------------------------
-- УРОН: база + % от урона атаки Рюмки
--------------------------------------------------

function rumka_razobem:GetTotalDamage()
    local caster = self:GetCaster()
    local attack_damage = caster:GetAverageTrueAttackDamage(nil)
    local pct = self:GetSpecialValueFor("attack_damage_pct") / 100

    return self:GetSpecialValueFor("damage") + attack_damage * pct
end


--------------------------------------------------
-- ОБЫЧНЫЙ КАСТ
--------------------------------------------------

function rumka_razobem:OnSpellStart()

    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()

    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetTotalDamage()
    local silence_duration =
        self:GetSpecialValueFor("silence_duration")

    local effect_duration =
        self:GetSpecialValueFor("effect_duration")

    --------------------------------------------------
    -- EFFECT
    --------------------------------------------------

    local particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_tidehunter/tidehunter_anchor_hero_mid.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )

    ParticleManager:SetParticleControl(
        particle,
        1,
        Vector(radius, 1, radius)
    )

    EmitSoundOn(
        "razobem",
        caster
    )

    --------------------------------------------------
    -- DAMAGE + SILENCE
    --------------------------------------------------

    self:ApplyExplosion(
        damage,
        DAMAGE_TYPE_PHYSICAL,
        silence_duration
    )

    --------------------------------------------------
    -- REMOVE EFFECT
    --------------------------------------------------

    GameRules:GetGameModeEntity():SetContextThink(
        "rumka_razobem_particle_" .. tostring(particle),
        function()

            ParticleManager:DestroyParticle(
                particle,
                false
            )

            ParticleManager:ReleaseParticleIndex(
                particle
            )

            return nil
        end,
        effect_duration
    )
end


--------------------------------------------------
-- ОБЩАЯ ФУНКЦИЯ ВЗРЫВА
--------------------------------------------------

function rumka_razobem:ApplyExplosion(
    damage,
    damage_type,
    silence_duration
)

    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()

    local radius = self:GetSpecialValueFor("radius")

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO +
        DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do

        --------------------------------------------------
        -- DAMAGE
        --------------------------------------------------

        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = damage,
            damage_type = damage_type,
            ability = self
        })

        --------------------------------------------------
        -- SILENCE
        --------------------------------------------------

        if silence_duration > 0 then

            enemy:AddNewModifier(
                caster,
                self,
                "modifier_rumka_razobem_silence",
                {
                    duration = silence_duration
                }
            )
        end
    end
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


--------------------------------------------------
-- AGHANIM TRACKER
--------------------------------------------------

modifier_rumka_razobem_scepter = class({})


function modifier_rumka_razobem_scepter:IsHidden()
    return true
end

function modifier_rumka_razobem_scepter:IsPurgable()
    return false
end

function modifier_rumka_razobem_scepter:IsDebuff()
    return false
end


function modifier_rumka_razobem_scepter:DeclareFunctions()

    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end


--------------------------------------------------
-- СОЗДАНИЕ
--------------------------------------------------

function modifier_rumka_razobem_scepter:OnCreated()

    if not IsServer() then
        return
    end

    self.damage_accumulator = 0
    self.next_proc_time = 0
end


--------------------------------------------------
-- ПОЛУЧЕНИЕ УРОНА
--------------------------------------------------

function modifier_rumka_razobem_scepter:OnTakeDamage(params)

    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    --------------------------------------------------
    -- УРОН ДОЛЖЕН БЫТЬ ПО РЮМКЕ
    --------------------------------------------------

    if params.unit ~= parent then
        return
    end

    --------------------------------------------------
    -- НЕТ AGHANIM = НЕТ ПАССИВКИ
    --------------------------------------------------

    if not parent:HasScepter() then
        return
    end

    --------------------------------------------------
    -- АТАКУЮЩИЙ ДОЛЖЕН БЫТЬ ГЕРОЕМ
    --------------------------------------------------

    local attacker = params.attacker

    if not attacker
        or attacker:IsNull()
    then
        return
    end

    if not attacker:IsHero() then
        return
    end

    --------------------------------------------------
    -- НЕ СЧИТАЕМ УРОН ОТ САМОЙ РЮМКИ
    --------------------------------------------------

    if attacker == parent then
        return
    end

    --------------------------------------------------
    -- НЕ СЧИТАЕМ НУЛЕВОЙ УРОН
    --------------------------------------------------

    if params.damage <= 0 then
        return
    end

    --------------------------------------------------
    -- COOLDOWN 0.3 SEC
    --------------------------------------------------

    local current_time = GameRules:GetGameTime()

    if current_time < self.next_proc_time then
        return
    end

    --------------------------------------------------
    -- НАКОПЛЕНИЕ УРОНА
    --------------------------------------------------

    self.damage_accumulator =
        self.damage_accumulator + params.damage

    --------------------------------------------------
    -- 475 DAMAGE
    --------------------------------------------------

    local threshold =
        self:GetAbility():GetSpecialValueFor(
            "scepter_damage_threshold"
        )

    if self.damage_accumulator < threshold then
        return
    end

    --------------------------------------------------
    -- COOLDOWN
    --------------------------------------------------

    self.next_proc_time =
        current_time +
        self:GetAbility():GetSpecialValueFor(
            "scepter_cooldown"
        )

    --------------------------------------------------
    -- СБРАСЫВАЕМ НАКОПЛЕНИЕ
    --------------------------------------------------

    self.damage_accumulator =
        self.damage_accumulator - threshold

    --------------------------------------------------
    -- АВТОМАТИЧЕСКИЙ ВЗРЫВ
    --------------------------------------------------

    self:TriggerScepterExplosion()
end


--------------------------------------------------
-- AGHANIM EXPLOSION
--------------------------------------------------

function modifier_rumka_razobem_scepter:TriggerScepterExplosion()

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not ability then
        return
    end

    --------------------------------------------------
    -- ОСНОВНЫЕ ЗНАЧЕНИЯ
    --------------------------------------------------

    local radius =
        ability:GetSpecialValueFor("radius")

    local base_damage =
        ability:GetTotalDamage()

    local base_silence =
        ability:GetSpecialValueFor("silence_duration")

    local base_effect_duration =
        ability:GetSpecialValueFor("effect_duration")

    --------------------------------------------------
    -- AGHANIM %
    --------------------------------------------------

    local damage_percent =
        ability:GetSpecialValueFor(
            "scepter_damage_percent"
        ) / 100

    local duration_percent =
        ability:GetSpecialValueFor(
            "scepter_duration_percent"
        ) / 100

    --------------------------------------------------
    -- ФИНАЛЬНЫЕ ЗНАЧЕНИЯ
    --------------------------------------------------

    local damage =
        base_damage * damage_percent

    local silence_duration =
        base_silence * duration_percent

    local effect_duration =
        base_effect_duration * duration_percent

    --------------------------------------------------
    -- EFFECT
    --------------------------------------------------

    local particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_tidehunter/tidehunter_anchor_hero_mid.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        parent
    )

    ParticleManager:SetParticleControl(
        particle,
        1,
        Vector(radius, 1, radius)
    )

    EmitSoundOn(
        "razobem",
        parent
    )

    --------------------------------------------------
    -- ФИЗИЧЕСКИЙ DAMAGE
    --------------------------------------------------

    ability:ApplyExplosion(
        damage,
        DAMAGE_TYPE_PHYSICAL,
        silence_duration
    )

    --------------------------------------------------
    -- REMOVE EFFECT
    --------------------------------------------------

    GameRules:GetGameModeEntity():SetContextThink(
        "rumka_scepter_particle_" .. tostring(particle),
        function()

            ParticleManager:DestroyParticle(
                particle,
                false
            )

            ParticleManager:ReleaseParticleIndex(
                particle
            )

            return nil
        end,
        effect_duration
    )
end