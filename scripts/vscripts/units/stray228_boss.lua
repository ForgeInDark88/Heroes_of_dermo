--------------------------------------------------------------------------------
-- БОСС STRAY228
--
-- Скиллы:
--   stray228_voroval  - ворует у героя всю броню
--   stray228_snaiping - вешает трек, цель видна на карте всем командам
--
-- При смерти запускает ивент: в центре карты открывается портал,
-- из которого волнами лезут агрессивные мобы "Теневого правительства".
--------------------------------------------------------------------------------

if Stray228Boss == nil then
    Stray228Boss = {}
end

LinkLuaModifier(
    "modifier_shadow_portal_thinker",
    "units/stray228_boss.lua",
    LUA_MODIFIER_MOTION_NONE
)

-- Пустой модификатор для невидимого thinker-а портала: на нём играет звук,
-- чтобы его можно было остановить при закрытии портала
modifier_shadow_portal_thinker = class({})

function modifier_shadow_portal_thinker:IsHidden()
    return true
end

STRAY228_BOSS_NAME = "npc_stray228_boss"

-- Точка спавна босса. Если на карте нет такой энтити - спавним в центре карты.
STRAY228_SPAWN_POINT_NAME = "stray228_point"

-- Точка портала. Если на карте нет такой энтити - портал открывается в (0, 0).
SHADOW_PORTAL_POINT_NAME = "shadow_portal_point"

-- Ресет босса, если его утащили слишком далеко от дома
STRAY228_LEASH_RANGE = 1800

-- Голда каждому герою команды, которая убила босса
STRAY228_KILL_GOLD = 300

-- Ивент портала
SHADOW_PORTAL_WAVES = 6          -- сколько волн выйдет из портала
SHADOW_PORTAL_WAVE_INTERVAL = 20 -- секунд между волнами
SHADOW_PORTAL_FIRST_WAVE_DELAY = 5
SHADOW_PORTAL_MAX_ALIVE = 40     -- лимит живых мобов, чтобы не положить сервер
SHADOW_PORTAL_TEAM = DOTA_TEAM_CUSTOM_1 -- "Теневое Правительство"

SHADOW_PORTAL_PARTICLE = "particles/units/heroes/hero_enigma/enigma_blackhole.vpcf"
SHADOW_PORTAL_SOUND = "Hero_Enigma.Black_Hole"
SHADOW_PORTAL_SOUND_STOP = "Hero_Enigma.Black_Hole.Stop"

-- Шмотка с Главы Теневого правительства
SHADOW_GOV_HEAD_NAME = "npc_shadow_gov_head"
SHADOW_GOV_HEAD_DROP = "item_shadow_gov_mantle"

--------------------------------------------------------------------------------
-- Утилиты
--------------------------------------------------------------------------------

local function Announce(text)
    GameRules:SendCustomMessage("<font color='#9b30ff'>" .. text .. "</font>", 0, 0)
end

local function GetMapCenter()
    return GetGroundPosition(Vector(0, 0, 0), nil)
end

local function GetNamedPointOrCenter(name)
    local ent = Entities:FindByName(nil, name)

    if ent then
        return ent:GetAbsOrigin()
    end

    print("[STRAY228] '" .. name .. "' not found on map, using map center")
    return GetMapCenter()
end

local function IsUnitValid(unit)
    return unit and not unit:IsNull() and unit:IsAlive()
end

--------------------------------------------------------------------------------
-- СПАВН И ИНИЦИАЛИЗАЦИЯ БОССА
--------------------------------------------------------------------------------

function Stray228Boss:Spawn()
    local position = GetNamedPointOrCenter(STRAY228_SPAWN_POINT_NAME)

    local boss = CreateUnitByName(
        STRAY228_BOSS_NAME,
        position,
        true,
        nil,
        nil,
        DOTA_TEAM_NEUTRALS
    )

    if boss then
        print("[STRAY228] Boss spawned")
        boss.Stray228HomePosition = position
    else
        print("[STRAY228] ERROR: boss spawn failed!")
    end

    return boss
end

function Stray228Boss:Init(unit)
    if unit.Stray228Initialized then
        return
    end

    unit.Stray228Initialized = true

    if not unit.Stray228HomePosition then
        unit.Stray228HomePosition = unit:GetAbsOrigin()
    end

    for i = 0, unit:GetAbilityCount() - 1 do
        local ability = unit:GetAbilityByIndex(i)

        if ability and ability:GetLevel() == 0 then
            ability:SetLevel(1)
        end
    end

    unit:SetContextThink("Stray228Think", function()
        return Stray228Boss:Think(unit)
    end, 1)

    print("[STRAY228] Boss initialized")
end

--------------------------------------------------------------------------------
-- AI БОССА
--------------------------------------------------------------------------------

function Stray228Boss:Think(unit)
    if not IsUnitValid(unit) then
        return nil
    end

    if GameRules:IsGamePaused() then
        return 0.5
    end

    -- Не даём утащить босса через всю карту
    local home = unit.Stray228HomePosition
    if home and (unit:GetAbsOrigin() - home):Length2D() > STRAY228_LEASH_RANGE then
        unit:MoveToPosition(home)
        return 1
    end

    if unit:IsChanneling() or unit:GetCurrentActiveAbility() then
        return 0.3
    end

    local voroval = unit:FindAbilityByName("stray228_voroval")
    local snaiping = unit:FindAbilityByName("stray228_snaiping")

    -- ВОРОВАЛ: на ближайшего героя с бронёй
    if voroval and voroval:IsFullyCastable() then
        local enemies = FindUnitsInRadius(
            unit:GetTeamNumber(),
            unit:GetAbsOrigin(),
            nil,
            voroval:GetCastRange(unit:GetAbsOrigin(), nil),
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO,
            DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
            FIND_CLOSEST,
            false
        )

        for _, enemy in pairs(enemies) do
            if enemy:IsRealHero()
                and enemy:GetPhysicalArmorValue(false) > 0
                and not enemy:HasModifier("modifier_stray228_voroval_debuff")
            then
                self:CastOnTarget(unit, voroval, enemy)
                return 0.5
            end
        end
    end

    -- СНАЙПИНГ: на самого дальнего героя без трека
    if snaiping and snaiping:IsFullyCastable() then
        local enemies = FindUnitsInRadius(
            unit:GetTeamNumber(),
            unit:GetAbsOrigin(),
            nil,
            snaiping:GetCastRange(unit:GetAbsOrigin(), nil),
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO,
            DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
            FIND_FARTHEST,
            false
        )

        for _, enemy in pairs(enemies) do
            if enemy:IsRealHero() and not enemy:HasModifier("modifier_stray228_snaiping") then
                self:CastOnTarget(unit, snaiping, enemy)
                return 0.5
            end
        end
    end

    return 0.5
end

function Stray228Boss:CastOnTarget(unit, ability, target)
    ExecuteOrderFromTable({
        UnitIndex = unit:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
        TargetIndex = target:entindex(),
        AbilityIndex = ability:entindex(),
        Queue = false
    })
end

--------------------------------------------------------------------------------
-- СМЕРТЬ БОССА
--------------------------------------------------------------------------------

function Stray228Boss:OnDeath(boss, killer)
    -- entity_killed в этом проекте приходит в OnEntityKilled дважды
    if boss.Stray228DeathHandled then
        return
    end

    boss.Stray228DeathHandled = true

    print("[STRAY228] Boss killed")

    if killer and not killer:IsNull() then
        local team = killer:GetTeamNumber()

        if team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS then
            for playerID = 0, DOTA_MAX_PLAYERS - 1 do
                if PlayerResource:IsValidPlayerID(playerID)
                    and PlayerResource:GetTeam(playerID) == team
                then
                    PlayerResource:ModifyGold(
                        playerID,
                        STRAY228_KILL_GOLD,
                        true,
                        DOTA_ModifyGold_Unspecified
                    )
                end
            end
        end
    end

    Announce("Stray228 повержен... но он успел слить координаты Теневому правительству!")

    self:StartShadowPortalEvent()
end

--------------------------------------------------------------------------------
-- ИВЕНТ: ПОРТАЛ ТЕНЕВОГО ПРАВИТЕЛЬСТВА
--------------------------------------------------------------------------------

function Stray228Boss:StartShadowPortalEvent()
    if self.PortalActive then
        print("[SHADOW PORTAL] Event already running")
        return
    end

    self.PortalActive = true
    self.PortalMobs = {}

    local position = GetNamedPointOrCenter(SHADOW_PORTAL_POINT_NAME)
    self.PortalPosition = position

    Announce("В центре карты открылся портал! Из него идёт ТЕНЕВОЕ ПРАВИТЕЛЬСТВО!")

    -- Визуал портала
    self.PortalParticle = ParticleManager:CreateParticle(
        SHADOW_PORTAL_PARTICLE,
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(self.PortalParticle, 0, position + Vector(0, 0, 64))

    self.PortalSoundSource = CreateModifierThinker(
        nil,
        nil,
        "modifier_shadow_portal_thinker",
        {},
        position,
        SHADOW_PORTAL_TEAM,
        false
    )

    if self.PortalSoundSource then
        EmitSoundOn(SHADOW_PORTAL_SOUND, self.PortalSoundSource)
    end

    -- Портал виден всем
    for _, team in pairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }) do
        AddFOWViewer(
            team,
            position,
            500,
            SHADOW_PORTAL_FIRST_WAVE_DELAY + SHADOW_PORTAL_WAVES * SHADOW_PORTAL_WAVE_INTERVAL,
            false
        )

        -- pcall: на случай, если движок не примет nil вместо юнита
        pcall(MinimapEvent, team, nil, position.x, position.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 5)
    end

    local wave = 0

    Timers:CreateTimer(SHADOW_PORTAL_FIRST_WAVE_DELAY, function()
        wave = wave + 1

        self:SpawnPortalWave(wave)

        if wave >= SHADOW_PORTAL_WAVES then
            Timers:CreateTimer(3, function()
                self:ClosePortal()
            end)
            return nil
        end

        return SHADOW_PORTAL_WAVE_INTERVAL
    end)
end

function Stray228Boss:CountAliveMobs()
    local alive = 0

    for i = #self.PortalMobs, 1, -1 do
        if IsUnitValid(self.PortalMobs[i]) then
            alive = alive + 1
        else
            table.remove(self.PortalMobs, i)
        end
    end

    return alive
end

function Stray228Boss:SpawnPortalWave(wave)
    print("[SHADOW PORTAL] Wave " .. wave)

    -- С каждой волной мобов больше и они сильнее
    local agents = 2 + wave
    local snipers = 1 + math.floor(wave / 2)
    local power = 1 + (wave - 1) * 0.2

    if wave == SHADOW_PORTAL_WAVES then
        Announce("Из портала выходит ГЛАВА ТЕНЕВОГО ПРАВИТЕЛЬСТВА!")
        self:SpawnPortalMob(SHADOW_GOV_HEAD_NAME, power)
    else
        Announce("Теневое правительство: волна " .. wave .. "/" .. SHADOW_PORTAL_WAVES)
    end

    for i = 1, agents do
        self:SpawnPortalMob("npc_shadow_gov_agent", power)
    end

    for i = 1, snipers do
        self:SpawnPortalMob("npc_shadow_gov_sniper", power)
    end
end

function Stray228Boss:SpawnPortalMob(unitName, power)
    if self:CountAliveMobs() >= SHADOW_PORTAL_MAX_ALIVE then
        return nil
    end

    local position = self.PortalPosition + RandomVector(RandomFloat(50, 250))

    local mob = CreateUnitByName(
        unitName,
        position,
        true,
        nil,
        nil,
        SHADOW_PORTAL_TEAM
    )

    if not mob then
        print("[SHADOW PORTAL] ERROR: failed to spawn " .. unitName)
        return nil
    end

    -- Тёмная окраска
    mob:SetRenderColor(70, 40, 110)

    if power > 1 then
        local hp = math.floor(mob:GetMaxHealth() * power)
        mob:SetBaseMaxHealth(hp)
        mob:SetMaxHealth(hp)
        mob:SetHealth(hp)
        mob:SetBaseDamageMin(math.floor(mob:GetBaseDamageMin() * power))
        mob:SetBaseDamageMax(math.floor(mob:GetBaseDamageMax() * power))
    end

    table.insert(self.PortalMobs, mob)

    mob:SetContextThink("ShadowGovThink", function()
        return Stray228Boss:MobThink(mob)
    end, 0.5)

    return mob
end

-- Мобы агрессивные: сами идут к ближайшему герою на карте
function Stray228Boss:MobThink(mob)
    if not IsUnitValid(mob) then
        return nil
    end

    if GameRules:IsGamePaused() then
        return 1
    end

    -- Уже дерётся - не мешаем
    if mob:IsAttacking() and mob:GetAttackTarget() then
        return 1
    end

    local heroes = FindUnitsInRadius(
        mob:GetTeamNumber(),
        mob:GetAbsOrigin(),
        nil,
        FIND_UNITS_EVERYWHERE,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
        FIND_CLOSEST,
        false
    )

    for _, hero in pairs(heroes) do
        if hero:IsRealHero() and hero:IsAlive() then
            mob:MoveToPositionAggressive(hero:GetAbsOrigin())
            return 1.5
        end
    end

    return 2
end

function Stray228Boss:ClosePortal()
    if not self.PortalActive then
        return
    end

    self.PortalActive = false

    if self.PortalParticle then
        ParticleManager:DestroyParticle(self.PortalParticle, false)
        ParticleManager:ReleaseParticleIndex(self.PortalParticle)
        self.PortalParticle = nil
    end

    local soundSource = self.PortalSoundSource
    self.PortalSoundSource = nil

    if soundSource and not soundSource:IsNull() then
        StopSoundOn(SHADOW_PORTAL_SOUND, soundSource)
        EmitSoundOnLocationWithCaster(soundSource:GetAbsOrigin(), SHADOW_PORTAL_SOUND_STOP, nil)
        UTIL_Remove(soundSource)
    end

    Announce("Портал Теневого правительства закрылся. Добейте оставшихся агентов!")

    print("[SHADOW PORTAL] Portal closed")
end

--------------------------------------------------------------------------------
-- СМЕРТЬ ГЛАВЫ ТЕНЕВОГО ПРАВИТЕЛЬСТВА: дроп мантии
--------------------------------------------------------------------------------

function Stray228Boss:OnShadowHeadDeath(head)
    -- entity_killed в этом проекте приходит в OnEntityKilled дважды
    if head.ShadowHeadDeathHandled then
        return
    end

    head.ShadowHeadDeathHandled = true

    local item = CreateItem(SHADOW_GOV_HEAD_DROP, nil, nil)

    if item then
        CreateItemOnPositionSync(head:GetAbsOrigin(), item)
        item:LaunchLoot(false, 300, 0.75, head:GetAbsOrigin() + RandomVector(100))
        Announce("Глава Теневого правительства повержен и оставил после себя Мантию Теневого правительства!")
    else
        print("[SHADOW PORTAL] ERROR: failed to create " .. SHADOW_GOV_HEAD_DROP)
    end
end
