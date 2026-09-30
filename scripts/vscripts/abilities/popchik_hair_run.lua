popchik_hair_run = class({})
LinkLuaModifier("modifier_popchik_hair_run", "abilities/popchik_hair_run", LUA_MODIFIER_MOTION_NONE)

function popchik_hair_run:Precache(context)
    PrecacheResource("particle", "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf", context)
    PrecacheModel("models/items/invoker/dark_artistry/dark_artistry_hair_model.vmdl", context)
end

function popchik_hair_run:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    EmitSoundOn("animeska", caster)

    caster:AddNewModifier(caster, self, "modifier_popchik_hair_run", { duration = duration })
    caster:EmitSound("Ability.Windrun")
end

--------------------------------------------------------------------------------

modifier_popchik_hair_run = class({})

function modifier_popchik_hair_run:IsHidden() return false end
function modifier_popchik_hair_run:IsDebuff() return false end
function modifier_popchik_hair_run:IsPurgable() return true end

function modifier_popchik_hair_run:OnCreated()
    self.bonus_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
    self.evasion = self:GetAbility():GetSpecialValueFor("evasion_chance")

    if not IsServer() then return end

    local parent = self:GetParent()

    -- 1. Эффект Windrun
    self.pfx_wind = ParticleManager:CreateParticle("particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.pfx_wind, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true)
    self:AddParticle(self.pfx_wind, false, false, -1, false, false)

-- Спавн модели волос
    self.hair_wearable = SpawnEntityFromTableSynchronous("prop_dynamic_override", {
        model = "models/items/invoker/dark_artistry/dark_artistry_hair_model.vmdl",
        modelscale = "3.5"
    })

if self.hair_wearable then
        local angles = parent:GetAngles()
        self.hair_wearable:SetAngles(angles.x, angles.y - 90, angles.z)

        -- 2. ВАЖНО: передаем false вместо true, чтобы отключить BoneMerge
        self.hair_wearable:FollowEntity(parent, false)

        -- 3. Дополнительно дублируем масштаб
        self.hair_wearable:SetModelScale(5.0)

        -- 4. Из-за крупного размера подкорректируйте высоту (Z)
        self.hair_wearable:SetLocalOrigin(Vector(0, -10, -950))
    end
end


function modifier_popchik_hair_run:OnDestroy()
    if not IsServer() then return end

    if self.hair_wearable and not self.hair_wearable:IsNull() then
        UTIL_Remove(self.hair_wearable)
    end
end

function modifier_popchik_hair_run:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
    }
end

function modifier_popchik_hair_run:GetModifierMoveSpeedBonus_Percentage()
    return self.bonus_speed
end

function modifier_popchik_hair_run:GetModifierEvasion_Constant()
    return self.evasion
end