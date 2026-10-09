BAREBONES_VERSION = '1.00'
BAREBONES_DEBUG_SPEW = true

if GameMode == nil then
    _G.GameMode = class({})
    print('[CUSTOM_GAME] GameMode class created')
end

-- Required libraries only.
-- The current game logic needs Timers; the other Barebones helper libraries
-- are not required and were removed from the startup path to avoid a hard
-- failure if one of them is absent from the published addon.
require('item_shemelis')
print('[SHEMELIS] Lua loaded')

print('[CUSTOM_GAME] require libraries/timers')
require('libraries/timers')
print('[CUSTOM_GAME] timers loaded')

print('[CUSTOM_GAME] require internal/gamemode')
require('internal/gamemode')
print('[CUSTOM_GAME] internal/gamemode loaded')

print('[CUSTOM_GAME] require internal/events')
require('internal/events')
print('[CUSTOM_GAME] internal/events loaded')

print('[CUSTOM_GAME] require settings')
require('settings')
print('[CUSTOM_GAME] settings loaded')

print('[CUSTOM_GAME] require events')
require('events')
print('[CUSTOM_GAME] events loaded')

LinkLuaModifier("modifier_always_visible", "modifiers/modifier_always_visible", LUA_MODIFIER_MOTION_NONE)

require('units/stray228_boss')
print('[STRAY228] boss module loaded')

require('units/brudskoe_boss')
print('[BRUDSKOE] boss module loaded')

require('units/alko_guild')
print('[ALKO_GUILD] module loaded')

require('guilds')
require('hero_selection')
print('[CUSTOM_GAME] guilds / hero_selection loaded')

function GameMode:OnFirstPlayerLoaded()
    DebugPrint('[BAREBONES] First Player has loaded')
end

function GameMode:OnAllPlayersLoaded()
    DebugPrint('[BAREBONES] All Players have loaded into the game')
end

function GameMode:OnHeroInGame(hero)
    if hero then
        DebugPrint('[BAREBONES] Hero spawned in game for first time -- ' .. hero:GetUnitName())
    end
end

function GameMode:OnGameInProgress()
    print('[GAME] Game in progress started! Starting wave timers...')

        local avanpost = Entities:FindByName(nil, "avan1")

    if avanpost then
        avanpost:SetTeam(DOTA_TEAM_GOODGUYS)

        print("[OUTPOST] avan1 -> RADIANT / GOODGUYS")
    else
        print("[OUTPOST] ERROR: avan1 not found!")
    end

    if self._waveTimerStarted then
        print('[GAME] Wave timer already started; skipping duplicate')
        return
    end

    self._waveTimerStarted = true

    GameMode:QopBoss()
    Stray228Boss:Spawn()
    BrudskoeBoss:Spawn()
    AlkoGuild:Spawn()


    GameMode:StartDayNightCycle()

    Timers:CreateTimer(5, function()
        print('[GAME] Spawning wave...')
        GameMode:WaveMobs()
        return WAVE_INTERVAL
    end)
end

-- Невидимость отключена для всех: каждый юнит получает modifier_always_visible
-- (на спавне в OnNPCSpawned + страховочный таймер для героев)
function GameMode:ApplyAlwaysVisible(unit)
    if unit and not unit:IsNull() and unit.HasModifier
        and not unit:HasModifier("modifier_always_visible") then
        unit:AddNewModifier(unit, nil, "modifier_always_visible", {})
    end
end

Timers:CreateTimer(1, function()
    for playerID = 0, DOTA_MAX_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(playerID) then
            GameMode:ApplyAlwaysVisible(PlayerResource:GetSelectedHeroEntity(playerID))
        end
    end
    return 0.5
end)

QOP_RESPAWN_TIME = 5 * 60   -- через сколько секунд после смерти Квопа возрождается

function GameMode:QopBoss()
    local point = Entities:FindByName(nil, "bosses_point")

    if not point then
        print("[QOP] ERROR: bosses_point not found!")
        return
    end

    local qop = CreateUnitByName(
        "npc_qop_intellect_boss",
        point:GetAbsOrigin(),
        true,
        nil,
        nil,
        DOTA_TEAM_NEUTRALS
    )

    if qop then
        print("[QOP] QOP spawned at bosses_point!")
        qop.QopHomePosition = point:GetAbsOrigin()
    else
        print("[QOP] ERROR: QOP spawn failed!")
    end
end

--------------------------------------------------------------------------------
-- ВОЛНЫ КРИПОВ
-- Обычная волна: 1 дальник + 3 милишника на каждой точке, каждые WAVE_INTERVAL сек.
-- Усиленная волна (+катапульта, +1 милишник) выходит у группы точек
-- с первой обычной волной после каждой отметки её интервала (по игровому времени).
--------------------------------------------------------------------------------

WAVE_INTERVAL = 40

WAVE_POINTS = {
    { name = 'z1',  team = DOTA_TEAM_BADGUYS },
    { name = 'z7',  team = DOTA_TEAM_GOODGUYS },
    { name = 'y1',  team = DOTA_TEAM_BADGUYS },
    { name = 'x1',  team = DOTA_TEAM_GOODGUYS },
    { name = 'rz1', team = DOTA_TEAM_BADGUYS },
    { name = 'rr1', team = DOTA_TEAM_GOODGUYS },
}

-- Интервалы усиленных волн (в секундах игрового времени) по группам точек
BIG_WAVE_GROUPS = {
    { interval = 5 * 60, points = { z1 = true, z7 = true } },
    { interval = 7 * 60, points = { x1 = true, rz1 = true } },
    { interval = 8 * 60, points = { rr1 = true, y1 = true } },
}

local CREEP_NAMES = {
    [DOTA_TEAM_GOODGUYS] = {
        melee  = 'npc_dota_creep_goodguys_melee',
        ranged = 'npc_dota_creep_goodguys_ranged',
        siege  = 'npc_dota_goodguys_siege',
    },
    [DOTA_TEAM_BADGUYS] = {
        melee  = 'npc_dota_creep_badguys_melee',
        ranged = 'npc_dota_creep_badguys_ranged',
        siege  = 'npc_dota_badguys_siege',
    },
}

-- Какие точки в этой волне получают усиление
function GameMode:GetBigWavePoints()
    local big = {}
    local game_time = GameRules:GetDOTATime(false, false)

    self.BigWaveLastIndex = self.BigWaveLastIndex or {}

    for i, group in ipairs(BIG_WAVE_GROUPS) do
        local index = math.floor(game_time / group.interval)
        local last = self.BigWaveLastIndex[i] or 0

        if index > last then
            self.BigWaveLastIndex[i] = index
            for name in pairs(group.points) do
                big[name] = true
            end
            print(string.format('[WAVE] Усиленная волна (%d мин) на %.0f сек игры', group.interval / 60, game_time))
        end
    end

    return big
end

function GameMode:SpawnWaveAtPoint(point_name, team, is_big)
    if self.TeamDefeated[team] then
        print('[WAVE] Team ' .. team .. ' defeated - skipping ' .. point_name)
        return
    end

    local point = Entities:FindByName(nil, point_name)
    if not point then
        print('[ERROR] Не найдена точка ' .. point_name .. '!')
        return
    end

    local names = CREEP_NAMES[team]
    local origin = point:GetAbsOrigin()

    local function Spawn(unit_name)
        local unit = CreateUnitByName(unit_name, origin, true, nil, nil, team)
        if unit then
            unit:SetInitialGoalEntity(point)
        end
        return unit
    end

    Spawn(names.ranged)

    local melee_count = is_big and 4 or 3
    for i = 1, melee_count do
        Spawn(names.melee)
    end

    if is_big then
        Spawn(names.siege)
    end
end

function GameMode:WaveMobs()
    DebugPrint('[GAME] WaveMobs()')

    -- Если таблица ещё не создана, создаём её здесь.
    if self.TeamDefeated == nil then
        self.TeamDefeated = {
            [DOTA_TEAM_GOODGUYS] = false,
            [DOTA_TEAM_BADGUYS] = false,
        }
    end

    local big = self:GetBigWavePoints()

    for _, point in ipairs(WAVE_POINTS) do
        self:SpawnWaveAtPoint(point.name, point.team, big[point.name] == true)
    end
end

--------------------------------------------------------------------------------
-- ДЕНЬ / НОЧЬ: смена каждые DAY_NIGHT_INTERVAL сек
-- (естественный цикл отключён в settings.lua)
--------------------------------------------------------------------------------

DAY_NIGHT_INTERVAL = 5 * 60

function GameMode:StartDayNightCycle()
    if self._dayNightStarted then return end
    self._dayNightStarted = true

    local is_day = true

    Timers:CreateTimer(0, function()
        -- 0.5 = полдень, 0.0 = полночь
        GameRules:SetTimeOfDay(is_day and 0.5 or 0.0)
        print('[DAYNIGHT] ' .. (is_day and 'День' or 'Ночь'))
        is_day = not is_day
        return DAY_NIGHT_INTERVAL
    end)
end

--------------------------------------------------------------------------------
-- 3 ТРОНА / ВЫБЫВАНИЕ КОМАНДЫ
--------------------------------------------------------------------------------

function GameMode:OnEntityKilled(keys)
    local killed = EntIndexToHScript(keys.entindex_killed)

    if not killed or killed:IsNull() then
        return
    end

    ----------------------------------------------------------------
    -- QOP BOSS
    ----------------------------------------------------------------

    -- entity_killed в этом проекте приходит в OnEntityKilled дважды:
    -- флаг, чтобы не выпало два аегиса и не было двух респавнов
    if killed:GetUnitName() == "npc_qop_intellect_boss" and not killed.QopDeathHandled then
        killed.QopDeathHandled = true

        print("[QOP BOSS] BOSS KILLED")

        local position = killed:GetAbsOrigin()

        local aegis = CreateItem("item_aegis", nil, nil)

        if aegis then
            CreateItemOnPositionSync(position, aegis)

            print("[QOP BOSS] AEGIS DROPPED")
        else
            print("[QOP BOSS] ERROR: Failed to create Aegis")
        end

        -- Квопа возрождается через QOP_RESPAWN_TIME
        GameRules:SendCustomMessage(
            "<font color='#c040ff'>Квопа повержена! Она вернётся через " .. math.floor(QOP_RESPAWN_TIME / 60) .. " мин.</font>",
            0, 0
        )
        Timers:CreateTimer(QOP_RESPAWN_TIME, function()
            GameMode:QopBoss()
            GameRules:SendCustomMessage("<font color='#c040ff'>Квопа снова на месте!</font>", 0, 0)
        end)

        -- Здесь НЕ делаем return,
        -- потому что ниже находится существующая логика тронов.
    end

    ----------------------------------------------------------------
    -- STRAY228 BOSS -> ивент портала Теневого правительства
    ----------------------------------------------------------------

    if killed:GetUnitName() == STRAY228_BOSS_NAME then
        local killer = nil

        if keys.entindex_attacker then
            killer = EntIndexToHScript(keys.entindex_attacker)
        end

        Stray228Boss:OnDeath(killed, killer)
    end

    if killed:GetUnitName() == BRUDSKOE_BOSS_NAME then
        BrudskoeBoss:OnDeath(killed)
    end

    if killed:GetUnitName() == SHADOW_GOV_HEAD_NAME then
        Stray228Boss:OnShadowHeadDeath(killed)
    end


    ----------------------------------------------------------------
    -- ТВОЯ СУЩЕСТВУЮЩАЯ ЛОГИКА ТРОНОВ
    ----------------------------------------------------------------

    local name = killed:GetName()

    if name == "throne_team1" then
        self:DefeatTeam(DOTA_TEAM_GOODGUYS)
        return
    end

    if name == "throne_team2" then
        self:DefeatTeam(DOTA_TEAM_BADGUYS)
        return
    end
end

function GameMode:OnNPCSpawned(keys)
    if not keys or not keys.entindex then
        return
    end

    -- Видимость, таланты на статы, гильдия алкашей (events.lua)
    GameMode:OnNPCSpawnedShared(keys)

    local unit = EntIndexToHScript(keys.entindex)

    if not unit or unit:IsNull() then
        return
    end

    if unit:GetUnitName() == STRAY228_BOSS_NAME then
        Stray228Boss:Init(unit)
        return
    end

    if unit:GetUnitName() == BRUDSKOE_BOSS_NAME then
        BrudskoeBoss:Init(unit)
        return
    end

    if unit:GetUnitName() ~= "npc_qop_intellect_boss" then
        return
    end

    -- Чтобы npc_spawned не инициализировал одного босса много раз
    if unit.QopBossInitialized then
        return
    end

    unit.QopBossInitialized = true

    print("[QOP BOSS] Spawn detected")

    if QopIntellectBoss then
        QopIntellectBoss:Init(unit)
    else
        print("[QOP BOSS] ERROR: QopIntellectBoss is nil")
    end
end


function GameMode:DefeatTeam(team)
    if self.TeamDefeated == nil then
        self.TeamDefeated = {
            [DOTA_TEAM_GOODGUYS] = false,
            [DOTA_TEAM_BADGUYS] = false,
        }
    end

    if self.TeamDefeated[team] then
        return
    end

    self.TeamDefeated[team] = true

    print("[TEAM] Team " .. team .. " defeated!")
    print("[TEAM] New creeps for this team are disabled.")

    -- Отключаем возрождение героев только проигравшей команды.
    for playerID = 0, DOTA_MAX_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(playerID) then
            if PlayerResource:GetTeam(playerID) == team then
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)

                if hero then
                    hero:SetRespawnsDisabled(true)

                    if hero:IsAlive() then
                        hero:ForceKill(false)
                    end
                end
            end
        end
    end
end


--------------------------------------------------------------------------------
-- SECRET SHOP ДЛЯ 3 КОМАНД
--------------------------------------------------------------------------------

function GameMode:FilterCourierSecretShop(filterTable)

    -- Правый клик по Гильдии алкашей = подойти к ней
    AlkoGuild:FilterOrder(filterTable)

    local units = filterTable.units

    if not units then
        return true
    end

    for _, unitIndex in pairs(units) do

        local courier = EntIndexToHScript(unitIndex)

        if courier
            and not courier:IsNull()
            and courier:IsCourier()
        then

            local orderType = filterTable.order_type

            -- Нас интересуют только касты без цели.
            -- Именно так ванильный курьер получает команду Secret Shop.
            if orderType == DOTA_UNIT_ORDER_CAST_NO_TARGET then

                local abilityIndex = filterTable.entindex_ability

                if abilityIndex then

                    local ability = EntIndexToHScript(abilityIndex)

                    if ability
                        and not ability:IsNull()
                    then

                        local abilityName = ability:GetName()

                        print(
                            "[COURIER] "
                            .. courier:GetUnitName()
                            .. " / team "
                            .. courier:GetTeamNumber()
                            .. " / ability "
                            .. abilityName
                        )

                        -- Проверяем, что это способность Secret Shop.
                        if string.find(
                            string.lower(abilityName),
                            "shop"
                        )
                        then

                            local team =
                                courier:GetTeamNumber()

                            local shopName = nil

                            ----------------------------------------------------------------
                            -- TEAM 1
                            ----------------------------------------------------------------

                            if team == DOTA_TEAM_GOODGUYS then

                                shopName =
                                    "secret_shop_radiant"

                            ----------------------------------------------------------------
                            -- TEAM 2
                            ----------------------------------------------------------------

                            elseif team == DOTA_TEAM_BADGUYS then

                                shopName =
                                    "secret_shop_dire"

                            if shopName then

                                local shop =
                                    Entities:FindByName(
                                        nil,
                                        shopName
                                    )

                                if shop then

                                    print(
                                        "[COURIER] Redirecting "
                                        .. "team "
                                        .. team
                                        .. " courier to "
                                        .. shopName
                                    )

                                    ----------------------------------------------------------------
                                    -- Меняем стандартный приказ
                                    -- на движение к нашему магазину
                                    ----------------------------------------------------------------

                                    filterTable.order_type =
                                        DOTA_UNIT_ORDER_MOVE_TO_POSITION

                                    filterTable.position_x =
                                        shop:GetAbsOrigin().x

                                    filterTable.position_y =
                                        shop:GetAbsOrigin().y

                                    filterTable.position_z =
                                        shop:GetAbsOrigin().z

                                    ----------------------------------------------------------------
                                    -- Полностью убираем ability cast
                                    ----------------------------------------------------------------

                                    filterTable.entindex_ability = -1

                                    return true
                                else

                                    print(
                                        "[COURIER] ERROR: "
                                        .. shopName
                                        .. " not found!"
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return true
end
end

function GameMode:InitGameMode()
    print('[CUSTOM_GAME] InitGameMode()')

    ListenToGameEvent(
        "entity_killed",
        Dynamic_Wrap(GameMode, "OnEntityKilled"),
        self
    )

    ListenToGameEvent(
    "npc_spawned",
    Dynamic_Wrap(GameMode, "OnNPCSpawned"),
    self
    )



    if self._customCommandsRegistered then
        return
    end
    self._customCommandsRegistered = true

    -- Свой выбор героя и гильдии в начале игры
    HeroSelection:Init()
    Guilds:Init()

    Convars:RegisterCommand(
        'command_example',
        Dynamic_Wrap(GameMode, 'ExampleConsoleCommand'),
        'A console command example',
        FCVAR_CHEAT
    )
    Convars:RegisterCommand(
    "test_shemelis",
    function()
        local player = Convars:GetCommandClient()
        if not player then return end

        local hero = player:GetAssignedHero()
        if not hero then return end

        local item = CreateItem("item_shemelis", hero, hero)

        if item then
            hero:AddItem(item)
            print("[SHEMELIS] ITEM CREATED SUCCESSFULLY")
        else
            print("[SHEMELIS] FAILED TO CREATE ITEM")
        end
    end,
    "Test Shemelis item",
    FCVAR_CHEAT
    )

    Convars:RegisterCommand(
        'spawn_wave',
        function()
            print('[CHEAT] Manual spawn wave triggered!')
            GameMode:WaveMobs()
        end,
        'Spawns a wave of creeps',
        FCVAR_CHEAT
    )

    Convars:RegisterCommand(
    "spawn_qop",
    function()
        local point = Entities:FindByName(nil, "bosses_point")

        if not point then
            print("[QOP] ERROR: point z1 not found!")
            return
        end

        local qop = CreateUnitByName(
            "npc_qop_intellect_boss",
            point:GetAbsOrigin(),
            true,
            nil,
            nil,
            DOTA_TEAM_NEUTRALS
        )

        if qop then
            qop:SetInitialGoalEntity(point)
            print("[QOP] QOP spawned at z1!")
        end
    end,
    "Spawn QOP at z1",
    FCVAR_CHEAT
    )

    Convars:RegisterCommand(
        "spawn_stray228",
        function()
            Stray228Boss:Spawn()
        end,
        "Spawn Stray228 boss",
        FCVAR_CHEAT
    )

    Convars:RegisterCommand(
        "spawn_alko_guild",
        function()
            local player = Convars:GetCommandClient()
            local hero = player and player:GetAssignedHero()
            if not hero then return end

            AlkoGuild:Spawn(hero:GetAbsOrigin() + hero:GetForwardVector() * 400)
        end,
        "Spawn Alko Guild in front of your hero",
        FCVAR_CHEAT
    )

    Convars:RegisterCommand(
        "spawn_brudskoe",
        function()
            BrudskoeBoss:Spawn()
        end,
        "Spawn Brudskoe boss",
        FCVAR_CHEAT
    )

    Convars:RegisterCommand(
        "shadow_portal",
        function()
            Stray228Boss:StartShadowPortalEvent()
        end,
        "Start Shadow Government portal event",
        FCVAR_CHEAT
    )

    
    GameRules:GetGameModeEntity():SetExecuteOrderFilter(
        Dynamic_Wrap(GameMode, "FilterCourierSecretShop"),
        self
    )

    print("[COURIER] Secret Shop filter enabled")

    print('[CUSTOM_GAME] InitGameMode() done')
end

function GameMode:ExampleConsoleCommand()
    print('******* Example Console Command ***************')
    local cmdPlayer = Convars:GetCommandClient()
    if cmdPlayer then
        local playerID = cmdPlayer:GetPlayerID()
        if playerID ~= nil and playerID ~= -1 then
            PlayerResource:ReplaceHeroWith(playerID, 'npc_dota_hero_viper', 1000, 1000)
        end
    end
    print('***********************************************')
end