LinkLuaModifier(
    "modifier_suprunov_shard_barrier",
    "abilities/innate_tp_ability",
    LUA_MODIFIER_MOTION_NONE
)

innate_tp_ability = class({})

------------------------------------------------------------
-- ПРОВЕРКА ЦЕЛИ
------------------------------------------------------------

function innate_tp_ability:CastFilterResultTarget(hTarget)
    if not IsServer() then
        return UF_SUCCESS
    end

    if hTarget:GetTeamNumber() == self:GetCaster():GetTeamNumber() then
        if hTarget:IsCreep() or hTarget:IsConsideredHero() == false then
            return UF_SUCCESS
        end
    end

    return UF_FAIL_CUSTOM
end

function innate_tp_ability:GetCustomCastErrorTarget(hTarget)
    if hTarget:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
        return "#dota_hud_error_cant_target_enemies"
    end

    if hTarget:IsHero() then
        return "#dota_hud_error_cant_target_heroes"
    end

    return "#dota_hud_error_cant_target_non_creeps"
end

------------------------------------------------------------
-- RANGE
------------------------------------------------------------

function innate_tp_ability:GetCastRange(location, target)
    return self:GetSpecialValueFor("cast_range")
end

------------------------------------------------------------
-- СОЗДАНИЕ ВРОЖДЁНКИ
------------------------------------------------------------

function innate_tp_ability:OnOwnerSpawned()
    if not IsServer() then
        return
    end

    -- Проверяем Shard регулярно
    self:StartIntervalThink(0.1)
end

------------------------------------------------------------
-- ПРОВЕРКА SHARD
------------------------------------------------------------

function innate_tp_ability:OnIntervalThink()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()

    if not caster or caster:IsNull() then
        return
    end

    if caster:HasShard() then

        if not caster:HasModifier("modifier_suprunov_shard_barrier") then

            caster:AddNewModifier(
                caster,
                self,
                "modifier_suprunov_shard_barrier",
                {}
            )

            print("[SUPRUNOV] Shard barrier added: 300")
        end

    else

        -- Если Shard каким-либо образом отсутствует,
        -- убираем барьер
        local modifier = caster:FindModifierByName(
            "modifier_suprunov_shard_barrier"
        )

        if modifier then
            modifier:Destroy()
        end
    end
end

------------------------------------------------------------
-- TELEPORT START
------------------------------------------------------------

function innate_tp_ability:OnSpellStart()
    self.caster = self:GetCaster()
    self.target = self:GetCursorTarget()

    if not self.target or not self.target:IsAlive() then
        self:EndChannel(true)
        return
    end

    local teleport_effect =
        "particles/items2_fx/teleport_end.vpcf"

    self.fx_index = ParticleManager:CreateParticle(
        teleport_effect,
        PATTACH_ABSORIGIN_FOLLOW,
        self.target
    )

    ParticleManager:SetParticleControlEnt(
        self.fx_index,
        0,
        self.target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        self.target:GetAbsOrigin(),
        true
    )

    ParticleManager:SetParticleControl(
        self.fx_index,
        1,
        self.target:GetAbsOrigin()
    )

    EmitSoundOn("princ", self.caster)
end

------------------------------------------------------------
-- TELEPORT FINISH
------------------------------------------------------------

function innate_tp_ability:OnChannelFinish(bInterrupted)

    if self.fx_index then

        ParticleManager:DestroyParticle(
            self.fx_index,
            false
        )

        ParticleManager:ReleaseParticleIndex(
            self.fx_index
        )

        self.fx_index = nil
    end

    if bInterrupted then
        StopSoundOn("princ", self.caster)
        return
    end

    if self.target and self.target:IsAlive() then

        FindClearSpaceForUnit(
            self.caster,
            self.target:GetAbsOrigin(),
            true
        )

        EmitSoundOn("princ", self.caster)

        self.caster:Stop()
    end
end

------------------------------------------------------------
-- SHARD BARRIER
------------------------------------------------------------

modifier_suprunov_shard_barrier = class({})

function modifier_suprunov_shard_barrier:IsHidden()
    return false
end

function modifier_suprunov_shard_barrier:IsDebuff()
    return false
end

function modifier_suprunov_shard_barrier:IsPurgable()
    return false
end

function modifier_suprunov_shard_barrier:GetTexture()
    return "item_barrier"
end

------------------------------------------------------------

function modifier_suprunov_shard_barrier:OnCreated()
    if not IsServer() then
        return
    end

    self.barrier = 300

    self:SetStackCount(self.barrier)
end

------------------------------------------------------------

function modifier_suprunov_shard_barrier:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
    }
end

------------------------------------------------------------

function modifier_suprunov_shard_barrier:GetModifierIncomingDamageConstant(params)

    if self.barrier <= 0 then
        return 0
    end

    --------------------------------------------------------
    -- Клиент: показываем 300 / оставшийся барьер
    --------------------------------------------------------

    if IsClient() then
        return self:GetStackCount()
    end

    --------------------------------------------------------
    -- Сервер: поглощаем урон
    --------------------------------------------------------

    local damage = params.damage

    local absorbed = math.min(
        damage,
        self.barrier
    )

    self.barrier = self.barrier - absorbed

    self:SetStackCount(
        math.max(0, math.floor(self.barrier))
    )

    if self.barrier <= 0 then
        self:Destroy()
    end

    return -absorbed
end

------------------------------------------------------------

function modifier_suprunov_shard_barrier:OnDestroy()
    if not IsServer() then
        return
    end

    self.barrier = 0
end