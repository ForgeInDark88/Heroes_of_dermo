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

require('units/stray228_boss')
print('[STRAY228] boss module loaded')

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


    Timers:CreateTimer(5, function()
        print('[GAME] Spawning wave...')
        GameMode:WaveMobs()
        return 40
    end)
end

Timers:CreateTimer(1, function()
    for playerID = 0, DOTA_MAX_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(playerID) then
            local hero = PlayerResource:GetSelectedHeroEntity(playerID)
            if hero and not hero:IsNull() and hero:IsAlive()
                and not hero:HasModifier("modifier_truesight") then
                hero:AddNewModifier(hero, nil, "modifier_truesight", {})
            end
        end
    end
    return 0.5
end)

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

function GameMode:WaveMobs()
    DebugPrint('[GAME] WaveMobs()')

    -- Если таблица ещё не создана, создаём её здесь.
    -- Это не меняет существующую структуру GameMode/settings/events/timers.
    if self.TeamDefeated == nil then
        self.TeamDefeated = {
            [DOTA_TEAM_GOODGUYS] = false,
            [DOTA_TEAM_BADGUYS] = false,
        }
    end

    ----------------------------------------------------------------
    -- TEAM 2 / BADGUYS
    -- Точка z1
    ----------------------------------------------------------------
    local bad_point = Entities:FindByName(nil, 'z1')

    if self.TeamDefeated[DOTA_TEAM_BADGUYS] then
        print('[WAVE] BADGUYS defeated - skipping z1')
    elseif bad_point then
        local ranged = CreateUnitByName(
            'npc_dota_creep_badguys_ranged',
            bad_point:GetAbsOrigin(),
            true, nil, nil, DOTA_TEAM_BADGUYS
        )

        if ranged then
            ranged:SetInitialGoalEntity(bad_point)
        end

        for i = 1, 3 do
            local unit = CreateUnitByName(
                'npc_dota_creep_badguys_melee',
                bad_point:GetAbsOrigin(),
                true, nil, nil, DOTA_TEAM_BADGUYS
            )

            if unit then
                unit:SetInitialGoalEntity(bad_point)
            end
        end
    else
        print('[ERROR] Не найдена точка z1!')
    end

    ----------------------------------------------------------------
    -- TEAM 1 / GOODGUYS
    -- Точка z7
    ----------------------------------------------------------------
    local good_point = Entities:FindByName(nil, 'z7')

    if self.TeamDefeated[DOTA_TEAM_GOODGUYS] then
        print('[WAVE] GOODGUYS defeated - skipping z7')
    elseif good_point then
        local ranged = CreateUnitByName(
            'npc_dota_creep_goodguys_ranged',
            good_point:GetAbsOrigin(),
            true, nil, nil, DOTA_TEAM_GOODGUYS
        )

        if ranged then
            ranged:SetInitialGoalEntity(good_point)
        end

        for i = 1, 3 do
            local unit = CreateUnitByName(
                'npc_dota_creep_goodguys_melee',
                good_point:GetAbsOrigin(),
                true, nil, nil, DOTA_TEAM_GOODGUYS
            )

            if unit then
                unit:SetInitialGoalEntity(good_point)
            end
        end
    else
        print('[ERROR] Не найдена точка z7!')
    end

    ----------------------------------------------------------------
    -- TEAM 2 / BADGUYS
    -- Точка y1
    ----------------------------------------------------------------
    local bad_point1 = Entities:FindByName(nil, 'y1')

    if self.TeamDefeated[DOTA_TEAM_BADGUYS] then
        print('[WAVE] BADGUYS defeated - skipping y1')
    elseif bad_point1 then
        local ranged = CreateUnitByName(
            'npc_dota_creep_badguys_ranged',
            bad_point1:GetAbsOrigin(),
            true, nil, nil, DOTA_TEAM_BADGUYS
        )

        if ranged then
            ranged:SetInitialGoalEntity(bad_point1)
        end

        for i = 1, 3 do
            local unit = CreateUnitByName(
                'npc_dota_creep_badguys_melee',
                bad_point1:GetAbsOrigin(),
                true, nil, nil, DOTA_TEAM_BADGUYS
            )

            if unit then
                unit:SetInitialGoalEntity(bad_point1)
            end
        end
    else
        print('[ERROR] Не найдена точка y1!')
    end

    ----------------------------------------------------------------
    -- TEAM 1 / GOODGUYS
    -- Точка x1
    ----------------------------------------------------------------
    local good_point1 = Entities:FindByName(nil, 'x1')

    if self.TeamDefeated[DOTA_TEAM_GOODGUYS] then
        print('[WAVE] GOODGUYS defeated - skipping x1')
    elseif good_point1 then
        local ranged = CreateUnitByName(
            'npc_dota_creep_goodguys_ranged',
            good_point1:GetAbsOrigin(),
            true, nil, nil, DOTA_TEAM_GOODGUYS
        )

        if ranged then
            ranged:SetInitialGoalEntity(good_point1)
        end

        for i = 1, 3 do
            local unit = CreateUnitByName(
                'npc_dota_creep_goodguys_melee',
                good_point1:GetAbsOrigin(),
                true, nil, nil, DOTA_TEAM_GOODGUYS
            )

            if unit then
                unit:SetInitialGoalEntity(good_point1)
            end
        end
    else
        print('[ERROR] Не найдена точка x1!')
    end

        local bad_point2 = Entities:FindByName(nil, 'rz1')

    if self.TeamDefeated[DOTA_TEAM_BADGUYS] then
        print('[WAVE] BADGUYS defeated - skipping rz1')
    elseif bad_point2 then
        local ranged = CreateUnitByName(
            'npc_dota_creep_badguys_ranged',
            bad_point2:GetAbsOrigin(),
            true, nil, nil, DOTA_TEAM_BADGUYS
        )

        if ranged then
            ranged:SetInitialGoalEntity(bad_point2)
        end

        for i = 1, 3 do
            local unit = CreateUnitByName(
                'npc_dota_creep_badguys_melee',
                bad_point2:GetAbsOrigin(),
                true, nil, nil, DOTA_TEAM_BADGUYS
            )

            if unit then
                unit:SetInitialGoalEntity(bad_point2)
            end
        end
    else
        print('[ERROR] Не найдена точка rz1!')
    end

    ----------------------------------------------------------------
    -- TEAM 1 / GOODGUYS
    -- Точка x1
    ----------------------------------------------------------------
    local good_point2 = Entities:FindByName(nil, 'rr1')

    if self.TeamDefeated[DOTA_TEAM_GOODGUYS] then
        print('[WAVE] GOODGUYS defeated - skipping rr1')
    elseif good_point2 then
        local ranged = CreateUnitByName(
            'npc_dota_creep_goodguys_ranged',
            good_point2:GetAbsOrigin(),
            true, nil, nil, DOTA_TEAM_GOODGUYS
        )

        if ranged then
            ranged:SetInitialGoalEntity(good_point2)
        end

        for i = 1, 3 do
            local unit = CreateUnitByName(
                'npc_dota_creep_goodguys_melee',
                good_point2:GetAbsOrigin(),
                true, nil, nil, DOTA_TEAM_GOODGUYS
            )

            if unit then
                unit:SetInitialGoalEntity(good_point2)
            end
        end
    else
        print('[ERROR] Не найдена точка rr1!')
    end
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

    if killed:GetUnitName() == "npc_qop_intellect_boss" then

        print("[QOP BOSS] BOSS KILLED")

        local position = killed:GetAbsOrigin()

        local aegis = CreateItem("item_aegis", nil, nil)

        if aegis then
            CreateItemOnPositionSync(position, aegis)

            print("[QOP BOSS] AEGIS DROPPED")
        else
            print("[QOP BOSS] ERROR: Failed to create Aegis")
        end

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

    local unit = EntIndexToHScript(keys.entindex)

    if not unit or unit:IsNull() then
        return
    end

    if unit:GetUnitName() == STRAY228_BOSS_NAME then
        Stray228Boss:Init(unit)
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