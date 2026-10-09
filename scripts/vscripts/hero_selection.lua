-- Свой выбор героя
-- Все игроки появляются временным героем HERO_SELECTION_DUMMY (settings.lua), а в начале
-- PRE_GAME выбирают героя в окне panorama (content/panorama/.../hero_select.*).
-- Сервер подменяет временного героя выбранным. Кто не успел за HERO_PICK_TIME — получает случайного.
--
-- Список героев берётся из herolist.txt, способности для превью — из npc_heroes_custom.txt.
-- Данные для окна лежат в net table "hero_selection":
--   heroes — { {name, attribute, abilities = {...}}, ... }
--   picks  — { [playerID] = имя героя }
--   state  — { phase = "waiting" | "picking" | "done" | "disabled", hero_deadline, allow_same }

if HeroSelection == nil then
    HeroSelection = class({})
end

LinkLuaModifier("modifier_hero_selection_dummy", "hero_selection", LUA_MODIFIER_MOTION_NONE)

function HeroSelection:Init()
    if not USE_CUSTOM_HERO_SELECTION then
        CustomNetTables:SetTableValue("hero_selection", "state", { phase = "disabled" })
        return
    end

    GameRules:SetStrategyTime(0)
    GameRules:SetShowcaseTime(0)

    self.heroes = self:LoadHeroes()
    self.picks = {}

    CustomNetTables:SetTableValue("hero_selection", "heroes", self.heroes)
    CustomNetTables:SetTableValue("hero_selection", "picks", {})
    CustomNetTables:SetTableValue("hero_selection", "state", { phase = "waiting" })

    CustomGameEventManager:RegisterListener("hero_selection_pick", function(_, event)
        self:OnPickRequest(event.PlayerID, event.hero)
    end)

    CustomGameEventManager:RegisterListener("hero_selection_random", function(_, event)
        self:OnPickRequest(event.PlayerID, self:GetRandomHero())
    end)

    print("[HERO_SELECTION] " .. #self.heroes .. " heroes loaded")
end

function HeroSelection:LoadHeroes()
    local herolist = LoadKeyValues("scripts/npc/herolist.txt") or {}
    local custom_heroes = LoadKeyValues("scripts/npc/npc_heroes_custom.txt") or {}
    local custom_abilities = LoadKeyValues("scripts/npc/npc_abilities_custom.txt") or {}

    -- В herolist базовые имена (npc_dota_hero_slark), а свои герои
    -- в npc_heroes_custom ссылаются на них через override_hero
    local by_base = {}
    for name, data in pairs(custom_heroes) do
        if type(data) == "table" then
            by_base[data.override_hero or name] = data
        end
    end

    local function IsShownAbility(ability)
        if not ability or ability == "" or ability == "generic_hidden" then return false end
        if string.find(ability, "special_bonus") then return false end

        local kv = custom_abilities[ability]
        local behavior = type(kv) == "table" and kv.AbilityBehavior or ""
        return not string.find(tostring(behavior), "DOTA_ABILITY_BEHAVIOR_HIDDEN")
    end

    local heroes = {}
    for name, enabled in pairs(herolist) do
        if tonumber(enabled) ~= 0 then
            local data = by_base[name] or {}
            local abilities = {}

            -- Ability10 и дальше — таланты
            for i = 1, 9 do
                local ability = data["Ability" .. i]
                if IsShownAbility(ability) then
                    table.insert(abilities, ability)
                end
            end

            table.insert(heroes, {
                name = name,
                attribute = data.AttributePrimary or "",
                abilities = abilities,
            })
        end
    end

    table.sort(heroes, function(a, b) return a.name < b.name end)
    return heroes
end

-- Вызывается при переходе в PRE_GAME (events.lua)
function HeroSelection:Start()
    if not USE_CUSTOM_HERO_SELECTION or self.started then return end
    self.started = true

    CustomNetTables:SetTableValue("hero_selection", "state", {
        phase = "picking",
        hero_deadline = GameRules:GetGameTime() + HERO_PICK_TIME,
        allow_same = ALLOW_SAME_HERO_SELECTION,
    })

    Timers:CreateTimer(HERO_PICK_TIME, function()
        self:Finish()
    end)
end

-- Время вышло: невыбравшим — случайного героя
function HeroSelection:Finish()
    if self.finished then return end
    self.finished = true

    for playerID = 0, DOTA_MAX_PLAYERS - 1 do
        if PlayerResource:IsValidTeamPlayerID(playerID) and not self.picks[playerID] then
            self:Pick(playerID, self:GetRandomHero())
        end
    end

    CustomNetTables:SetTableValue("hero_selection", "state", { phase = "done" })
end

function HeroSelection:IsInList(hero_name)
    for _, hero in ipairs(self.heroes) do
        if hero.name == hero_name then return true end
    end
    return false
end

function HeroSelection:IsTaken(hero_name)
    for _, picked in pairs(self.picks) do
        if picked == hero_name then return true end
    end
    return false
end

function HeroSelection:IsAvailable(hero_name)
    return self:IsInList(hero_name) and (ALLOW_SAME_HERO_SELECTION or not self:IsTaken(hero_name))
end

-- Случайный свободный герой; если игроков больше, чем героев, — любой
function HeroSelection:GetRandomHero()
    local free = {}
    for _, hero in ipairs(self.heroes) do
        if self:IsAvailable(hero.name) then
            table.insert(free, hero.name)
        end
    end

    if #free == 0 then
        local hero = self.heroes[RandomInt(1, #self.heroes)]
        return hero and hero.name
    end

    return free[RandomInt(1, #free)]
end

function HeroSelection:OnPickRequest(playerID, hero_name)
    if not self.started or self.finished then return end
    if not hero_name or not PlayerResource:IsValidTeamPlayerID(playerID) then return end
    if self.picks[playerID] or not self:IsAvailable(hero_name) then return end

    self:Pick(playerID, hero_name)
end

function HeroSelection:Pick(playerID, hero_name)
    if not hero_name then return end

    self.picks[playerID] = hero_name

    local picks = {}
    for id, name in pairs(self.picks) do
        picks[tostring(id)] = name
    end
    CustomNetTables:SetTableValue("hero_selection", "picks", picks)

    print("[HERO_SELECTION] Player " .. playerID .. " picked " .. hero_name)

    PrecacheUnitByNameAsync(hero_name, function()
        self:ReplaceHero(playerID, hero_name, 0)
    end, playerID)
end

function HeroSelection:ReplaceHero(playerID, hero_name, attempt)
    local old_hero = PlayerResource:GetSelectedHeroEntity(playerID)

    -- Временный герой ещё не появился (или игрок отвалился на загрузке) — ждём до 60 сек.
    if not old_hero then
        if attempt < 600 then
            Timers:CreateTimer(0.1, function()
                self:ReplaceHero(playerID, hero_name, attempt + 1)
            end)
        else
            print("[HERO_SELECTION] ERROR: no hero for player " .. playerID)
        end
        return
    end

    if old_hero:GetUnitName() ~= HERO_SELECTION_DUMMY then return end

    local hero = PlayerResource:ReplaceHeroWith(playerID, hero_name, PlayerResource:GetGold(playerID), 0)

    if old_hero and not old_hero:IsNull() and old_hero ~= hero then
        UTIL_Remove(old_hero)
    end
end

-- Вызывается при спавне любого NPC (events.lua): прячем временного героя
function HeroSelection:OnNPCSpawned(npc)
    if USE_CUSTOM_HERO_SELECTION and npc:IsRealHero() and npc:GetUnitName() == HERO_SELECTION_DUMMY
        and not npc:HasModifier("modifier_hero_selection_dummy") then
        npc:AddNewModifier(npc, nil, "modifier_hero_selection_dummy", {})
    end
end

--------------------------------------------------------------------------------
-- ВРЕМЕННЫЙ ГЕРОЙ: невидим, неуязвим, не слушается приказов
--------------------------------------------------------------------------------

modifier_hero_selection_dummy = class({})

function modifier_hero_selection_dummy:IsHidden() return true end
function modifier_hero_selection_dummy:IsPurgable() return false end
function modifier_hero_selection_dummy:RemoveOnDeath() return false end

function modifier_hero_selection_dummy:OnCreated()
    if not IsServer() then return end
    self:GetParent():AddNoDraw()
end

function modifier_hero_selection_dummy:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
    }
end
