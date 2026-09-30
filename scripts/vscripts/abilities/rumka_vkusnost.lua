LinkLuaModifier(
    "modifier_rumka_vkusnost_slow",
    "abilities/rumka_vkusnost",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_rumka_vkusnost_pull",
    "abilities/rumka_vkusnost",
    LUA_MODIFIER_MOTION_HORIZONTAL
)

LinkLuaModifier(
    "modifier_rumka_vkusnost_blood",
    "abilities/rumka_vkusnost",
    LUA_MODIFIER_MOTION_NONE
)

rumka_vkusnost = class({})

function rumka_vkusnost:Precache(context)

    PrecacheResource(
        "particle",
        "particles/units/heroes/hero_pudge/pudge_meathook_impact.vpcf",
        context
    )

    PrecacheResource(
        "soundfile",
        "soundevents/game_sounds_heroes/game_sounds_pudge.vsndevts",
        context
    )
end


function rumka_vkusnost:OnSpellStart()

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target then
        return
    end

    if target:IsMagicImmune() then
        return
    end

    EmitSoundOn(
    "sladost",
        caster
    )

    local damage = self:GetSpecialValueFor("damage")
    local slow_duration = self:GetSpecialValueFor("slow_duration")
    local pull_duration = self:GetSpecialValueFor("pull_duration")

    --------------------------------------------------
    -- УРОН
    --------------------------------------------------

    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
    })

    --------------------------------------------------
    -- SLOW
    --------------------------------------------------

    target:AddNewModifier(
        caster,
        self,
        "modifier_rumka_vkusnost_slow",
        {
            duration = slow_duration
        }
    )

    --------------------------------------------------
    -- ПРИТЯГИВАНИЕ
    --------------------------------------------------

    target:AddNewModifier(
        caster,
        self,
        "modifier_rumka_vkusnost_pull",
        {
            duration = pull_duration
        }
    )

    --------------------------------------------------
    -- ЭФФЕКТ КРОВИ
    --------------------------------------------------

    target:AddNewModifier(
        caster,
        self,
        "modifier_rumka_vkusnost_blood",
        {
            duration = 0.7
        }
    )

    --------------------------------------------------
    -- ЗВУК
    --------------------------------------------------


end


--------------------------------------------------
-- SLOW
--------------------------------------------------

modifier_rumka_vkusnost_slow = class({})

function modifier_rumka_vkusnost_slow:IsHidden()
    return false
end

function modifier_rumka_vkusnost_slow:IsDebuff()
    return true
end

function modifier_rumka_vkusnost_slow:IsPurgable()
    return true
end

function modifier_rumka_vkusnost_slow:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_rumka_vkusnost_slow:GetModifierMoveSpeedBonus_Percentage()

    local ability = self:GetAbility()

    if not ability then
        return 0
    end

    return -ability:GetSpecialValueFor("slow_percent")
end


--------------------------------------------------
-- BLOOD EFFECT
--------------------------------------------------

modifier_rumka_vkusnost_blood = class({})

function modifier_rumka_vkusnost_blood:IsHidden()
    return true
end

function modifier_rumka_vkusnost_blood:IsDebuff()
    return true
end

function modifier_rumka_vkusnost_blood:IsPurgable()
    return false
end

function modifier_rumka_vkusnost_blood:OnCreated()

    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    self.blood_fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_pudge/pudge_meathook_impact.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        parent
    )

    ParticleManager:SetParticleControl(
        self.blood_fx,
        0,
        parent:GetAbsOrigin()
    )

    -- Автоматически удалить particle вместе с modifier
    self:AddParticle(
        self.blood_fx,
        false,
        false,
        -1,
        false,
        false
    )
end


--------------------------------------------------
-- PULL
--------------------------------------------------

modifier_rumka_vkusnost_pull = class({})

function modifier_rumka_vkusnost_pull:IsHidden()
    return true
end

function modifier_rumka_vkusnost_pull:IsPurgable()
    return false
end

function modifier_rumka_vkusnost_pull:CheckState()

    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_rumka_vkusnost_pull:OnCreated()

    if not IsServer() then
        return
    end

    self.caster = self:GetCaster()
    self.parent = self:GetParent()

    self:ApplyHorizontalMotionController()
end


function modifier_rumka_vkusnost_pull:UpdateHorizontalMotion(unit, dt)

    if not self.caster
        or self.caster:IsNull()
        or not self.parent
        or self.parent:IsNull()
    then
        self:Destroy()
        return
    end

    local caster_pos = self.caster:GetAbsOrigin()
    local target_pos = self.parent:GetAbsOrigin()

    local direction = caster_pos - target_pos
    local distance = direction:Length2D()

    if distance <= 120 then
        self:Destroy()
        return
    end

    direction = direction:Normalized()

    local speed = distance / self:GetRemainingTime()

    self.parent:SetAbsOrigin(
        target_pos + direction * speed * dt
    )
end


function modifier_rumka_vkusnost_pull:OnHorizontalMotionInterrupted()
    self:Destroy()
end


function modifier_rumka_vkusnost_pull:OnDestroy()

    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    if parent and not parent:IsNull() then

        FindClearSpaceForUnit(
            parent,
            parent:GetAbsOrigin(),
            true
        )

        parent:InterruptMotionControllers(true)
    end
end
