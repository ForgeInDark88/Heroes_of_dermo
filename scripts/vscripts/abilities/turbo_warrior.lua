turbo_warrior = class({})
LinkLuaModifier("modifier_turbo_warrior_passive", "abilities/turbo_warrior", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_turbo_warrior_courier_boost", "abilities/turbo_warrior", LUA_MODIFIER_MOTION_NONE)

-- Автоматически прокачиваем врождённый скилл
function turbo_warrior:Spawn()
    if IsServer() then
        self:SetLevel(1)
    end
end

-- Пассивная часть (Врождённая)
function turbo_warrior:GetIntrinsicModifierName()
    return "modifier_turbo_warrior_passive"
end

-- Поведение способности
function turbo_warrior:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

-- Перезарядка отображается всегда, но проверяется при касте
function turbo_warrior:GetCooldown(level)
    return self.BaseClass.GetCooldown(self, level)
end

-- Логика использования
function turbo_warrior:OnSpellStart()
    local caster = self:GetCaster()
    if not caster or caster:IsNull() then return end

    -- Проверка на наличие Шарда (как в вашем скилле pudge_fall)
    if not caster:HasModifier("modifier_item_aghanims_shard") then
        self:ResetCooldown()
        
        -- Вывод ошибки игроку на экран
        local player = caster:GetPlayerOwner()
        if player then
            CustomGameEventManager:Send_ServerToPlayer(player, "create_error_notification", {
                message = "#dota_hud_error_no_item_shard"
            })
        end
        return
    end

    -- Достаем параметры из AbilityValues
    local duration = self:GetSpecialValueFor("shard_duration")
    local team = caster:GetTeamNumber()

    -- Находим курьеров команды и вешаем бафф
    local couriers = Entities:FindAllByClassname("npc_dota_courier")
    for _, courier in pairs(couriers) do
        if courier and not courier:IsNull() and courier:GetTeamNumber() == team then
            courier:AddNewModifier(caster, self, "modifier_turbo_warrior_courier_boost", { duration = duration })
        end
    end

    -- Звук активации
    EmitSoundOn("Hero_Centaur.Stampede.Cast", caster)
end

--------------------------------------------------------------------------------
-- Пассивный модификатор (-50% времени возрождения)
--------------------------------------------------------------------------------
modifier_turbo_warrior_passive = class({})

function modifier_turbo_warrior_passive:IsHidden() return true end
function modifier_turbo_warrior_passive:IsPurgable() return false end

function modifier_turbo_warrior_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_RESPAWNTIME,
    }
end

function modifier_turbo_warrior_passive:GetModifierRespawnTime()
    if IsServer() then
        local parent = self:GetParent()
        if parent then
            -- Вычисляем ровно половину от стандартного времени смерти
            local standard_respawn = parent:GetRespawnTime()
            return -(standard_respawn * 0.5)
        end
    end
    return 0
end

--------------------------------------------------------------------------------
-- Бафф ускорения курьера от Шарда
--------------------------------------------------------------------------------
modifier_turbo_warrior_courier_boost = class({})

function modifier_turbo_warrior_courier_boost:IsHidden() return false end
function modifier_turbo_warrior_courier_boost:IsDebuff() return false end

function modifier_turbo_warrior_courier_boost:OnCreated()
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
        self.courier_speed = ability:GetSpecialValueFor("shard_courier_speed")
    else
        self.courier_speed = 1100
    end
end

function modifier_turbo_warrior_courier_boost:GetEffectName()
    return "particles/units/heroes/hero_centaur/centaur_stampede_haste.vpcf"
end

function modifier_turbo_warrior_courier_boost:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_turbo_warrior_courier_boost:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
    }
end

function modifier_turbo_warrior_courier_boost:GetModifierMoveSpeed_Absolute()
    return self.courier_speed or 1100
end