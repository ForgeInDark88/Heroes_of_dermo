require('libraries/timers')
custom_pudge_fall = class({})
LinkLuaModifier("modifier_custom_pudge_rot_cloud", "abilities/modifier_custom_pudge_rot_cloud", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_pudge_rot_debuff", "abilities/modifier_custom_pudge_rot_debuff", LUA_MODIFIER_MOTION_NONE)


function custom_pudge_fall:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function custom_pudge_fall:OnSpellStart()
    local caster = self:GetCaster()
    local target_point = self:GetCursorPosition()
    EmitSoundOnLocationWithCaster(target_point, "koch", caster)

    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")
    local stun_duration = self:GetSpecialValueFor("stun_duration")
    local fall_speed = self:GetSpecialValueFor("fall_speed")
    local spawn_height = self:GetSpecialValueFor("spawn_height")

    local spawn_point = target_point + Vector(0, 0, spawn_height)
    local dummy_pudge = CreateUnitByName(
        "npc_dota_hero_pudge", 
        spawn_point, 
        false, 
        caster, 
        caster, 
        caster:GetTeamNumber()
    )

    dummy_pudge:SetOriginalModel("models/heroes/pudge/pudge.vmdl")
    dummy_pudge:SetModel("models/heroes/pudge/pudge.vmdl")

    dummy_pudge:AddNewModifier(caster, self, "modifier_phased", {})
    dummy_pudge:AddNewModifier(caster, self, "modifier_invulnerable", {})
    dummy_pudge:SetNeverMoveToClearSpace(true)
    dummy_pudge:SetAbsOrigin(spawn_point)

    dummy_pudge:StartGesture(ACT_DOTA_FLAIL)

    local time_passed = 0
    local tick_interval = 0.03

    GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("pudge_fall_think"), function()
        time_passed = time_passed + tick_interval
        local current_height = math.max(0, spawn_height - (fall_speed * time_passed))

        dummy_pudge:SetAbsOrigin(Vector(target_point.x, target_point.y, target_point.z + current_height))

        if current_height <= 0 then
            -- Эффект приземления
        local crash_fx = ParticleManager:CreateParticle(
        "particles/econ/items/pudge/hungry_clown/hungry_clown_rot_body.vpcf", 
            PATTACH_WORLDORIGIN, 
            nil
        )   
        ParticleManager:SetParticleControl(crash_fx, 0, target_point)
        ParticleManager:SetParticleControl(crash_fx, 1, Vector(radius, 0, 0))

        -- Удаление партикла через Timers
        Timers:CreateTimer(4.0, function()
         if crash_fx then
             ParticleManager:DestroyParticle(crash_fx, false)
             ParticleManager:ReleaseParticleIndex(crash_fx)
            end
        end)
           

            -- Нанесение урона и стана
            local enemies = FindUnitsInRadius(
                caster:GetTeamNumber(),
                target_point,
                nil,
                radius,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_ANY_ORDER,
                false
            )

            for _, enemy in pairs(enemies) do
                ApplyDamage({
                    victim = enemy,
                    attacker = caster,
                    damage = damage,
                    damage_type = self:GetAbilityDamageType(),
                    ability = self
                })

                enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = stun_duration })
            end

            if caster and not caster:IsNull() and caster:HasModifier("modifier_item_aghanims_shard") then
                local shard_duration = self:GetSpecialValueFor("shard_rot_duration")
                
                local thinker = CreateModifierThinker(
                    caster,
                    self,
                    "modifier_custom_pudge_rot_cloud",
                    { duration = shard_duration },
                    target_point,
                    caster:GetTeamNumber(),
                    false
                )
            end

            dummy_pudge:Destroy()
            return nil
        end

        return tick_interval
    end, tick_interval)
end

modifier_custom_pudge_rot_cloud = class({})

function modifier_custom_pudge_rot_cloud:IsHidden() return true end

function modifier_custom_pudge_rot_cloud:OnCreated()
    if not IsServer() then return end
    
    local ability = self:GetAbility()
    self.radius = ability and ability:GetSpecialValueFor("shard_rot_radius") or 800

    -- Эффект ВОНИ
    self.pfx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_pudge/pudge_rot.vpcf", 
        PATTACH_WORLDORIGIN, 
        nil
    )
    ParticleManager:SetParticleControl(self.pfx, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pfx, 1, Vector(self.radius, 1, self.radius))

    -- Принудительный запуск сканирования ауры
    self:StartIntervalThink(0.1)
end

function modifier_custom_pudge_rot_cloud:OnIntervalThink()
    -- Пустой интервал заставляет ауру регулярно искать юнитов в радиусе
end

function modifier_custom_pudge_rot_cloud:OnDestroy()
    if not IsServer() then return end
    if self.pfx then
        ParticleManager:DestroyParticle(self.pfx, false)
        ParticleManager:ReleaseParticleIndex(self.pfx)
        self.pfx = nil
    end
end

-- Параметры Ауры
function modifier_custom_pudge_rot_cloud:IsAura() return true end
function modifier_custom_pudge_rot_cloud:GetModifierAuraRadius() return self.radius or 800 end
function modifier_custom_pudge_rot_cloud:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_custom_pudge_rot_cloud:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_custom_pudge_rot_cloud:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_custom_pudge_rot_cloud:GetAuraModifierName() return "modifier_custom_pudge_rot_debuff" end
function modifier_custom_pudge_rot_cloud:GetAuraDuration() return 0.2 end


--------------------------------------------------------------------------------
-- Дебафф от облака
--------------------------------------------------------------------------------
modifier_custom_pudge_rot_debuff = class({})

function modifier_custom_pudge_rot_debuff:IsHidden() return false end
function modifier_custom_pudge_rot_debuff:IsDebuff() return true end
function modifier_custom_pudge_rot_debuff:IsPurgable() return true end

function modifier_custom_pudge_rot_debuff:OnCreated()
    local ability = self:GetAbility()
    if ability then
        self.slow_pct = ability:GetSpecialValueFor("shard_slow_pct")
        self.heal_reduce_pct = ability:GetSpecialValueFor("shard_heal_reduce_pct")
    else
        self.slow_pct = -10
        self.heal_reduce_pct = -10
    end
end

function modifier_custom_pudge_rot_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    }
end

function modifier_custom_pudge_rot_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow_pct or -10
end

function modifier_custom_pudge_rot_debuff:GetModifierHealAmplify_PercentageTarget()
    return self.heal_reduce_pct or -10
end

function modifier_custom_pudge_rot_debuff:GetModifierHPRegenAmplify_Percentage()
    return self.heal_reduce_pct or -10
end