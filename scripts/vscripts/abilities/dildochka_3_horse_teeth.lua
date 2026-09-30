-- abilities/dildochka_3_horse_teeth.lua

if dildo_horse_teeth == nil then
    dildo_horse_teeth = class({})
end

LinkLuaModifier(
    "modifier_dildo_horse_teeth",
    "abilities/dildochka_3_horse_teeth",
    LUA_MODIFIER_MOTION_NONE
)

function dildo_horse_teeth:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    -- Скорость без slow.
    local speed = caster:GetIdealSpeedNoSlows()

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

    -- Звук
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


function modifier_dildo_horse_teeth:OnCreated(params)
    self.move_speed = tonumber(params.move_speed) or self:GetParent():GetIdealSpeedNoSlows()

    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    -- Надёжно закреплённый на герое эффект.
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
    self.move_speed =
        tonumber(params.move_speed)
        or self.move_speed
end


function modifier_dildo_horse_teeth:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
    }
end


function modifier_dildo_horse_teeth:GetModifierMoveSpeed_Absolute()
    return self.move_speed
end


function modifier_dildo_horse_teeth:GetTexture()
    return "marci_rebound"
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

