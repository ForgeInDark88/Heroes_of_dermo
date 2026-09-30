------------------------------------------------------------
-- SHEMELIS
------------------------------------------------------------

LinkLuaModifier(
    "modifier_item_shemelis",
    "item_shemelis",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_item_shemelis_slow",
    "item_shemelis",
    LUA_MODIFIER_MOTION_NONE
)


item_shemelis = class({})


------------------------------------------------------------
-- INTRINSIC MODIFIER
------------------------------------------------------------

function item_shemelis:GetIntrinsicModifierName()
    return "modifier_item_shemelis"
end


------------------------------------------------------------
-- АКТИВКА
------------------------------------------------------------

function item_shemelis:OnSpellStart()

    print("[SHEMELIS] OnSpellStart!")

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not caster then
        print("[SHEMELIS] ERROR: caster nil")
        return
    end

    if not target then
        print("[SHEMELIS] ERROR: target nil")
        return
    end


    --------------------------------------------------------
    -- SPELL BLOCK
    --------------------------------------------------------

    if target:TriggerSpellAbsorb(self) then
        print("[SHEMELIS] Spell blocked")
        return
    end


    --------------------------------------------------------
    -- VALUES
    --------------------------------------------------------

    local blink_range =
        self:GetSpecialValueFor("blink_range")

    local slow_duration =
        self:GetSpecialValueFor("slow_duration")


    print(
        "[SHEMELIS] range = " .. tostring(blink_range)
    )

    print(
        "[SHEMELIS] slow duration = " ..
        tostring(slow_duration)
    )


    --------------------------------------------------------
    -- ПОЗИЦИИ
    --------------------------------------------------------

    local caster_pos =
        caster:GetAbsOrigin()

    local target_pos =
        target:GetAbsOrigin()


    local direction =
        target_pos - caster_pos

    direction.z = 0


    local distance =
        direction:Length2D()


    if distance <= 0 then
        direction = Vector(1, 0, 0)
        distance = 1
    else
        direction = direction:Normalized()
    end


    --------------------------------------------------------
    -- BLINK
    --------------------------------------------------------

    local destination


    if distance <= blink_range then

        destination =
            target_pos - direction * 80

    else

        destination =
            caster_pos +
            direction * blink_range

    end


    destination =
        GetGroundPosition(
            destination,
            caster
        )


    --------------------------------------------------------
    -- PARTICLE START
    --------------------------------------------------------

    local p1 =
        ParticleManager:CreateParticle(
            "particles/items_fx/blink_dagger_start.vpcf",
            PATTACH_ABSORIGIN,
            caster
        )

    ParticleManager:SetParticleControl(
        p1,
        0,
        caster_pos
    )

    ParticleManager:ReleaseParticleIndex(p1)


    --------------------------------------------------------
    -- SOUND
    --------------------------------------------------------

    caster:EmitSound(
        "DOTA_Item.BlinkDagger.Activate"
    )


    --------------------------------------------------------
    -- TELEPORT
    --------------------------------------------------------

    FindClearSpaceForUnit(
        caster,
        destination,
        true
    )


    --------------------------------------------------------
    -- PARTICLE END
    --------------------------------------------------------

    local p2 =
        ParticleManager:CreateParticle(
            "particles/items_fx/blink_dagger_end.vpcf",
            PATTACH_ABSORIGIN,
            caster
        )

    ParticleManager:SetParticleControl(
        p2,
        0,
        destination
    )

    ParticleManager:ReleaseParticleIndex(p2)


    --------------------------------------------------------
    -- SLOW
    --------------------------------------------------------

    target:AddNewModifier(
        caster,
        self,
        "modifier_item_shemelis_slow",
        {
            duration = slow_duration
        }
    )


    target:EmitSound(
        "DOTA_Item.DiffusalBlade.Activate"
    )


    print("[SHEMELIS] Blink + Slow SUCCESS!")

end



----------------------------------------------------------------
-- ПАССИВНЫЙ MODIFIER
----------------------------------------------------------------

modifier_item_shemelis = class({})


function modifier_item_shemelis:IsHidden()
    return true
end


function modifier_item_shemelis:IsPurgable()
    return false
end


function modifier_item_shemelis:RemoveOnDeath()
    return false
end


function modifier_item_shemelis:DeclareFunctions()

    return {

        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,

        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,

        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,

        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,

        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE

    }

end


------------------------------------------------------------
-- STRENGTH
------------------------------------------------------------

function modifier_item_shemelis:GetModifierBonusStats_Strength()

    local ability = self:GetAbility()

    if not ability then
        return 0
    end

    return ability:GetSpecialValueFor(
        "bonus_strength"
    )

end


------------------------------------------------------------
-- AGILITY
------------------------------------------------------------

function modifier_item_shemelis:GetModifierBonusStats_Agility()

    local ability = self:GetAbility()

    if not ability then
        return 0
    end

    return ability:GetSpecialValueFor(
        "bonus_agility"
    )

end


------------------------------------------------------------
-- INTELLIGENCE
------------------------------------------------------------

function modifier_item_shemelis:GetModifierBonusStats_Intellect()

    local ability = self:GetAbility()

    if not ability then
        return 0
    end

    return ability:GetSpecialValueFor(
        "bonus_intellect"
    )

end


------------------------------------------------------------
-- ATTACK SPEED
------------------------------------------------------------

function modifier_item_shemelis:GetModifierAttackSpeedBonus_Constant()

    local ability = self:GetAbility()

    if not ability then
        return 0
    end

    return ability:GetSpecialValueFor(
        "bonus_attack_speed"
    )

end


------------------------------------------------------------
-- MOVE SPEED
------------------------------------------------------------

function modifier_item_shemelis:GetModifierMoveSpeedBonus_Percentage()

    local ability = self:GetAbility()

    if not ability then
        return 0
    end

    return ability:GetSpecialValueFor(
        "bonus_movespeed"
    )

end



----------------------------------------------------------------
-- SLOW MODIFIER
----------------------------------------------------------------

modifier_item_shemelis_slow = class({})


function modifier_item_shemelis_slow:IsHidden()
    return false
end


function modifier_item_shemelis_slow:IsDebuff()
    return true
end


function modifier_item_shemelis_slow:IsPurgable()
    return true
end


function modifier_item_shemelis_slow:GetTexture()
    return "item_diffusal_blade"
end


function modifier_item_shemelis_slow:DeclareFunctions()

    return {

        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE

    }

end


function modifier_item_shemelis_slow:GetModifierMoveSpeedBonus_Percentage()

    local ability = self:GetAbility()

    if not ability then
        return -50
    end

    return -ability:GetSpecialValueFor(
        "slow_percent"
    )

end