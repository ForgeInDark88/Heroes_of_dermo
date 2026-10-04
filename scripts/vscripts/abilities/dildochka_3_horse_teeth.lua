-- abilities/dildochka_3_horse_teeth.lua

if dildo_horse_teeth == nil then
    dildo_horse_teeth = class({})
end

LinkLuaModifier(
    "modifier_dildo_horse_teeth",
    "abilities/dildochka_3_horse_teeth",
    LUA_MODIFIER_MOTION_NONE
)

require("abilities/dildochka_shared")


function dildo_horse_teeth:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    -- Сохраняем реальную скорость героя без учёта замедлений.
    local speed = caster:GetIdealSpeedNoSlows()

    -- Убираем старый эффект, если он каким-то образом остался.
    caster:RemoveModifierByName("modifier_dildo_horse_teeth")

    caster:AddNewModifier(
        caster,
        self,
        "modifier_dildo_horse_teeth",
        {
            duration = duration,
            move_speed = speed
        }
    )

    caster:EmitSound("Hero_Marci.Rebound")
end


modifier_dildo_horse_teeth = class({})


function modifier_dildo_horse_teeth:IsHidden()
    return false
end


function modifier_dildo_horse_teeth:IsPurgable()
    return false
end


function modifier_dildo_horse_teeth:RemoveOnDeath()
    return true
end


function modifier_dildo_horse_teeth:GetTexture()
    return "marci_rebound"
end


function modifier_dildo_horse_teeth:OnCreated(params)
    self.move_speed = tonumber(params.move_speed)
        or self:GetParent():GetIdealSpeedNoSlows()

    self.bonus_speed = self:GetAbility():GetSpecialValueFor("bonus_movespeed_pct")
    self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_magic_damage")
    self.rotten_extend = self:GetAbility():GetSpecialValueFor("rotten_extend")
    self.status_resistance = self:GetAbility():GetSpecialValueFor("status_resistance")

    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    -- Эффект на Дилдочке.
    self.particle = ParticleManager:CreateParticle(
        "particles/econ/generic/generic_buff_1/generic_buff_1.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        parent
    )

    ParticleManager:SetParticleControl(
        self.particle,
        0,
        parent:GetAbsOrigin()
    )

    self:AddParticle(
        self.particle,
        false,
        false,
        -1,
        false,
        false
    )
end


function modifier_dildo_horse_teeth:OnRefresh(params)
    self.move_speed = tonumber(params.move_speed)
        or self.move_speed

    self.bonus_speed =
        self:GetAbility():GetSpecialValueFor("bonus_movespeed_pct")

    self.bonus_damage =
        self:GetAbility():GetSpecialValueFor("bonus_magic_damage")

    self.rotten_extend =
        self:GetAbility():GetSpecialValueFor("rotten_extend")

    self.status_resistance =
        self:GetAbility():GetSpecialValueFor("status_resistance")
end


function modifier_dildo_horse_teeth:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end


function modifier_dildo_horse_teeth:GetModifierStatusResistanceStacking()
    return self.status_resistance or 0
end


function modifier_dildo_horse_teeth:GetModifierMoveSpeed_Absolute()
    -- Старая механика:
    -- полностью игнорируем обычные замедления.

    local speed = self.move_speed

    -- И добавляем бонус Зубов коня.
    speed = speed * (1 + self.bonus_speed / 100)

    return speed
end


function modifier_dildo_horse_teeth:OnAttackLanded(params)
    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    -- Атаковать должна сама Дилдочка.
    if params.attacker ~= parent then
        return
    end

    local target = params.target

    if not target or target:IsNull() then
        return
    end

    if not target:IsAlive() then
        return
    end

    -- Не атакуем союзников.
    if target:GetTeamNumber() == parent:GetTeamNumber() then
        return
    end

    -- ==========================================================
    -- ВЗАИМОДЕЙСТВИЕ С ГНИЛЫМ ПАЛЬЧИКОМ
    -- ==========================================================

    local rotten = target:FindModifierByName(
        "modifier_dildo_rotten_finger"
    )

    if rotten then

        -- Продлеваем Гнилой пальчик.
        local remaining = rotten:GetRemainingTime()

        rotten:SetDuration(
            math.max(remaining, self.rotten_extend) + self.rotten_extend,
            true
        )

        -- Дополнительный магический урон от Зубов коня.
        ApplyDamage({
            victim = target,
            attacker = parent,
            damage = self.bonus_damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility(),
            damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
        })

        -- Небольшой эффект укуса.
local bite_particle = ParticleManager:CreateParticle(
    "particles/units/heroes/hero_venomancer/venomancer_venomous_gale_mouth.vpcf",
    PATTACH_ABSORIGIN_FOLLOW,
    target
)

ParticleManager:SetParticleControl(
    bite_particle,
    0,
    target:GetAbsOrigin()
)

Timers:CreateTimer(0.5, function()
    if bite_particle then
        ParticleManager:DestroyParticle(
            bite_particle,
            false
        )

        ParticleManager:ReleaseParticleIndex(
            bite_particle
        )
    end
end)

target:EmitSound("Hero_Venomancer.PoisonNovaImpact")
    end
end


function modifier_dildo_horse_teeth:OnDestroy()
    if not IsServer() then
        return
    end

    if self.particle then
        ParticleManager:DestroyParticle(
            self.particle,
            false
        )

        ParticleManager:ReleaseParticleIndex(
            self.particle
        )

        self.particle = nil
    end
end