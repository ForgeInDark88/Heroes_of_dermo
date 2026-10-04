LinkLuaModifier(
    "modifier_suprunov_ender_vasya_eidolon",
    "abilities/suprunov_ender_vasya.lua",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_suprunov_ender_vasya_armor_reduction",
    "abilities/suprunov_ender_vasya.lua",
    LUA_MODIFIER_MOTION_NONE
)

suprunov_ender_vasya = class({})

function suprunov_ender_vasya:OnSpellStart()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()

    local spawn_count = self:GetSpecialValueFor("spawn_count")
    local damage = self:GetSpecialValueFor("eidolon_damage")
    local duration = self:GetSpecialValueFor("eidolon_duration")

    local origin = caster:GetAbsOrigin()

    for i = 1, spawn_count do
        local angle = (i - 1) * (360 / spawn_count)

        local direction = Vector(
            math.cos(math.rad(angle)),
            math.sin(math.rad(angle)),
            0
        )

        local spawn_position = origin + direction * 150

        local eidolon = CreateUnitByName(
            "npc_suprunov_ender_eidolon",
            spawn_position,
            true,
            caster,
            caster,
            caster:GetTeamNumber()
        )

        if eidolon then
            FindClearSpaceForUnit(
                eidolon,
                spawn_position,
                true
            )

            eidolon:SetOwner(caster)

            eidolon:SetControllableByPlayer(
                caster:GetPlayerOwnerID(),
                true
            )

            eidolon:SetBaseDamageMin(damage)
            eidolon:SetBaseDamageMax(damage)

            eidolon:AddNewModifier(
                caster,
                self,
                "modifier_suprunov_ender_vasya_eidolon",
                {
                    duration = duration
                }
            )
        end
    end

    EmitSoundOn(
        "endervasi",
        caster
    )
end


modifier_suprunov_ender_vasya_eidolon = class({})

function modifier_suprunov_ender_vasya_eidolon:IsHidden()
    return true
end

function modifier_suprunov_ender_vasya_eidolon:IsPurgable()
    return false
end

function modifier_suprunov_ender_vasya_eidolon:OnCreated()
    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    parent:SetBaseDamageMin(120)
    parent:SetBaseDamageMax(120)
end

function modifier_suprunov_ender_vasya_eidolon:OnDestroy()
    if not IsServer() then
        return
    end

    local parent = self:GetParent()

    if parent and not parent:IsNull() then
        if parent:IsAlive() then
            parent:ForceKill(false)
        end
    end
end

-- Шард: каждая атака Эндер Васи снижает броню цели на 1 (стакается)
function modifier_suprunov_ender_vasya_eidolon:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_suprunov_ender_vasya_eidolon:OnAttackLanded(params)
    if not IsServer() then
        return
    end

    local parent = self:GetParent()
    if params.attacker ~= parent then
        return
    end

    local target = params.target
    if not target or target:IsNull() or target:IsBuilding() then
        return
    end

    if target:GetTeamNumber() == parent:GetTeamNumber() then
        return
    end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
        return
    end

    local modifier = target:AddNewModifier(
        self:GetCaster(),
        ability,
        "modifier_suprunov_ender_vasya_armor_reduction",
        {
            duration = ability:GetSpecialValueFor("armor_reduction_duration")
        }
    )

    if modifier then
        modifier:IncrementStackCount()
    end
end


modifier_suprunov_ender_vasya_armor_reduction = class({})

function modifier_suprunov_ender_vasya_armor_reduction:IsHidden()
    return false
end

function modifier_suprunov_ender_vasya_armor_reduction:IsDebuff()
    return true
end

function modifier_suprunov_ender_vasya_armor_reduction:IsPurgable()
    return true
end

function modifier_suprunov_ender_vasya_armor_reduction:OnCreated()
    local ability = self:GetAbility()
    self.armor_per_stack = ability and ability:GetSpecialValueFor("armor_reduction_per_hit") or 1
end

function modifier_suprunov_ender_vasya_armor_reduction:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_suprunov_ender_vasya_armor_reduction:GetModifierPhysicalArmorBonus()
    return -self.armor_per_stack * self:GetStackCount()
end
