throw_creeper = class({})

LinkLuaModifier(
    "modifier_throw_creeper_stun",
    "abilities/throw_creeper",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_creeper_attached",
    "abilities/throw_creeper",
    LUA_MODIFIER_MOTION_NONE
)


function throw_creeper:OnSpellStart()

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target or target:TriggerSpellAbsorb(self) then
        return
    end

    local speed = self:GetSpecialValueFor("projectile_speed")
    local start_pos = caster:GetAbsOrigin()

    ----------------------------------------------------------------
    -- СПАВН КРИПА
    ----------------------------------------------------------------

    local flying_creeper = CreateUnitByName(
        "npc_dota_custom_creeper1",
        start_pos,
        false,
        caster,
        caster,
        caster:GetTeamNumber()
    )

    if not flying_creeper then
        return
    end

    flying_creeper:SetOwner(caster)

    ----------------------------------------------------------------
    -- УРОВЕНЬ ВЗРЫВА
    ----------------------------------------------------------------

    local explode_ability =
        flying_creeper:FindAbilityByName("creeper_explode")

    if explode_ability then
        explode_ability:SetLevel(self:GetLevel())
    end

    ----------------------------------------------------------------
    -- В ПОЛЁТЕ КРИП НЕУЯЗВИМ И ПРОХОДИТ СКВОЗЬ ЮНИТОВ
    ----------------------------------------------------------------

    flying_creeper:AddNewModifier(
        caster,
        self,
        "modifier_phased",
        {}
    )

    flying_creeper:AddNewModifier(
        caster,
        self,
        "modifier_invulnerable",
        {}
    )

    ----------------------------------------------------------------
    -- ПОЛЁТ
    ----------------------------------------------------------------

    local current_pos = start_pos

    Timers:CreateTimer(0.03, function()

        if not flying_creeper
            or flying_creeper:IsNull()
            or not flying_creeper:IsAlive()
        then
            return nil
        end

        if not target
            or target:IsNull()
            or not target:IsAlive()
        then

            flying_creeper:Kill(self, caster)

            return nil
        end

        local target_pos = target:GetAbsOrigin()

        local distance =
            (target_pos - current_pos):Length2D()

        local direction =
            (target_pos - current_pos):Normalized()

        local move_distance = speed * 0.03

        ----------------------------------------------------------------
        -- ПОПАЛ В ЦЕЛЬ
        ----------------------------------------------------------------

        if distance <= move_distance then

            self:OnCreeperImpact(
                target,
                flying_creeper
            )

            return nil
        end

        ----------------------------------------------------------------
        -- ДВИЖЕНИЕ
        ----------------------------------------------------------------

        current_pos =
            current_pos +
            direction * move_distance

        local current_z =
            GetGroundHeight(
                current_pos,
                flying_creeper
            )

        flying_creeper:SetAbsOrigin(
            Vector(
                current_pos.x,
                current_pos.y,
                current_z
            )
        )

        flying_creeper:SetForwardVector(direction)

        return 0.03
    end)

    caster:EmitSound("soldatik")
end


--------------------------------------------------------------------------------
-- ПОПАДАНИЕ
--------------------------------------------------------------------------------

function throw_creeper:OnCreeperImpact(
    target,
    flying_creeper
)

    local caster = self:GetCaster()

    local duration =
        self:GetSpecialValueFor("stun_duration")

    local damage_value =
        self:GetSpecialValueFor("damage")

    ----------------------------------------------------------------
    -- УРОН
    ----------------------------------------------------------------

    if damage_value and damage_value > 0 then

        ApplyDamage({
            victim = target,
            attacker = caster,
            damage = damage_value,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        })

    end

    ----------------------------------------------------------------
    -- СТАН
    ----------------------------------------------------------------

    target:AddNewModifier(
        caster,
        self,
        "modifier_throw_creeper_stun",
        {
            duration = duration
        }
    )

    ----------------------------------------------------------------
    -- КРИП ОСТАЁТСЯ НА ЦЕЛИ НА 3 СЕКУНДЫ
    ----------------------------------------------------------------

    if flying_creeper
        and not flying_creeper:IsNull()
    then

        flying_creeper:RemoveModifierByName(
            "modifier_invulnerable"
        )

        -- НЕ убираем phased!
        -- Поэтому крип не блокирует героя.

        ----------------------------------------------------------------
        -- Ставим крипа рядом/в позиции героя
        ----------------------------------------------------------------

        flying_creeper:SetAbsOrigin(
            target:GetAbsOrigin()
        )

        ----------------------------------------------------------------
        -- Следим за героем
        ----------------------------------------------------------------

        flying_creeper:AddNewModifier(
            caster,
            self,
            "modifier_creeper_attached",
            {
                duration = 3.0,
                target_entindex = target:entindex()
            }
        )
    end

    target:EmitSound("Hero_Tiny.TossImpact")
end


--------------------------------------------------------------------------------
-- КРИП ПРИКРЕПЛЁН К ГЕРОЮ
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- КРИП ПРИКРЕПЛЁН К ГЕРОЮ НА 3 СЕКУНДЫ
--------------------------------------------------------------------------------

modifier_creeper_attached = class({})

function modifier_creeper_attached:IsHidden()
    return true
end

function modifier_creeper_attached:IsPurgable()
    return false
end

function modifier_creeper_attached:CheckState()
    return {
        -- Не блокирует героя
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,

        -- Не ходит сам
        [MODIFIER_STATE_ROOTED] = true,
    }
end


function modifier_creeper_attached:OnCreated(params)

    if not IsServer() then
        return
    end

    self.target_entindex = tonumber(params.target_entindex)

    if self.target_entindex then
        self.target = EntIndexToHScript(self.target_entindex)
    end

    self:StartIntervalThink(0.03)
end


function modifier_creeper_attached:OnIntervalThink()

    local creeper = self:GetParent()

    if not creeper or creeper:IsNull() then
        return
    end

    -- Если герой умер, крип просто умирает.
    -- OnDeath у creeper_explode сам вызовет взрыв.
    if not self.target
        or self.target:IsNull()
        or not self.target:IsAlive()
    then

        if creeper:IsAlive() then
            creeper:Kill(nil, self:GetCaster())
        end

        return
    end

    -- Держим крипа на герое
    creeper:SetAbsOrigin(self.target:GetAbsOrigin())

    creeper:SetForwardVector(self.target:GetForwardVector())
end


function modifier_creeper_attached:OnDestroy()

    if not IsServer() then
        return
    end

    local creeper = self:GetParent()

    if not creeper or creeper:IsNull() then
        return
    end

    -- Если крипа уже убили раньше 3 секунд,
    -- OnDeath уже сам сделал взрыв.
    if not creeper:IsAlive() then
        return
    end

    local explode_ability =
        creeper:FindAbilityByName("creeper_explode")

    if explode_ability then

        -- ВЗРЫВ ПОСЛЕ 3 СЕКУНД
        explode_ability:ExplodeCreeper(creeper)

    end

    -- После взрыва удаляем крипа
    if creeper:IsAlive() then
        creeper:ForceKill(false)
    end
end

--------------------------------------------------------------------------------
-- СТАН
--------------------------------------------------------------------------------

modifier_throw_creeper_stun = class({})

function modifier_throw_creeper_stun:IsDebuff()
    return true
end

function modifier_throw_creeper_stun:IsStunDebuff()
    return true
end

function modifier_throw_creeper_stun:IsPurgable()
    return true
end

function modifier_throw_creeper_stun:CheckState()

    return {
        [MODIFIER_STATE_STUNNED] = true,
    }
end

function modifier_throw_creeper_stun:GetEffectName()

    return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_throw_creeper_stun:GetEffectAttachType()

    return PATTACH_OVERHEAD_FOLLOW
end