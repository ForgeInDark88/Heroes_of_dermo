LinkLuaModifier(
    "modifier_rumka_tolstyy",
    "abilities/rumka_tolstyy",
    LUA_MODIFIER_MOTION_NONE
)

rumka_tolstyy = class({})

function rumka_tolstyy:Precache(context)
    PrecacheResource(
        "soundfile",
        "soundevents/game_sounds_heroes/game_sounds_pudge.vsndevts",
        context
    )

    PrecacheResource(
        "particle",
        "particles/generic_gameplay/generic_hit_blood.vpcf",
        context
    )
end

function rumka_tolstyy:GetIntrinsicModifierName()
    return "modifier_rumka_tolstyy"
end


modifier_rumka_tolstyy = class({})

function modifier_rumka_tolstyy:IsHidden()
    return false
end

function modifier_rumka_tolstyy:IsPurgable()
    return false
end

function modifier_rumka_tolstyy:IsDebuff()
    return false
end

function modifier_rumka_tolstyy:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
    }
end

function modifier_rumka_tolstyy:GetModifierPhysical_ConstantBlock(params)

    local parent = self:GetParent()

    -- Пассивка отключена Истощением
    if parent:PassivesDisabled() then
        return 0
    end

    local ability = self:GetAbility()

    if not ability then
        return 0
    end

    local chance = ability:GetSpecialValueFor("block_chance")
    local block = ability:GetSpecialValueFor("damage_block")

    if RandomInt(1, 100) <= chance then

        -- Звук блока
        EmitSoundOn(
            "Hero_Pudge.AttackHookImpact",
            parent
        )

        -- Эффект блока
        local fx = ParticleManager:CreateParticle(
            "particles/generic_gameplay/generic_hit_blood.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            parent
        )

        ParticleManager:SetParticleControl(
            fx,
            0,
            parent:GetAbsOrigin()
        )

        ParticleManager:ReleaseParticleIndex(fx)

        return block
    end

    return 0
end

