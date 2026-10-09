-- Гильдии
-- В начале игры (после выбора героя) каждый игрок выбирает гильдию в окне panorama
-- (content/panorama/.../guild_select.*) или остаётся без гильдии.
-- Кто не выбрал за отведённое время — без гильдии.
--
-- Новая гильдия = новая запись в GUILD_LIST + строки "guild_<id>" и "guild_<id>_description"
-- в addon_english.txt. Проверка членства: Guilds:GetUnitGuild(unit) == "<id>".
--
-- Net table "guilds":
--   list    — GUILD_LIST
--   players — { [playerID] = id гильдии или GUILD_NONE }
--   state   — { phase = "waiting" | "picking" | "done", deadline }

if Guilds == nil then
    Guilds = class({})
end

GUILD_NONE = "none"

-- Порядок = порядок карточек в окне выбора.
-- icon  — иконка способности Доты для карточки;
-- image — своя картинка вместо icon, например "file://{images}/custom_game/guilds/alko.png"
--         (файл кладётся в content/.../panorama/images/custom_game/guilds/alko.png).
GUILD_LIST = {
    { id = "alko", icon = "brewmaster_drunken_brawler" },
}

function Guilds:Init()
    self.players = {}

    CustomNetTables:SetTableValue("guilds", "list", GUILD_LIST)
    CustomNetTables:SetTableValue("guilds", "players", {})
    CustomNetTables:SetTableValue("guilds", "state", { phase = "waiting" })

    CustomGameEventManager:RegisterListener("guild_select", function(_, event)
        self:OnSelect(event.PlayerID, event.guild)
    end)
end

-- Вызывается при переходе в PRE_GAME (events.lua).
-- Если герой выбирается своим окном, на гильдию остаётся время после него.
function Guilds:Start()
    if self.started then return end
    self.started = true

    local duration = GUILD_PICK_TIME
    if USE_CUSTOM_HERO_SELECTION then
        duration = duration + HERO_PICK_TIME
    end

    CustomNetTables:SetTableValue("guilds", "state", {
        phase = "picking",
        deadline = GameRules:GetGameTime() + duration,
    })

    Timers:CreateTimer(duration, function()
        self.finished = true
        CustomNetTables:SetTableValue("guilds", "state", { phase = "done" })
    end)
end

function Guilds:Exists(guild_id)
    for _, guild in ipairs(GUILD_LIST) do
        if guild.id == guild_id then return true end
    end
    return false
end

function Guilds:OnSelect(playerID, guild_id)
    if not self.started or self.finished then return end
    if not PlayerResource:IsValidTeamPlayerID(playerID) or self.players[playerID] then return end
    if guild_id ~= GUILD_NONE and not self:Exists(guild_id) then return end

    self.players[playerID] = guild_id

    local players = {}
    for id, guild in pairs(self.players) do
        players[tostring(id)] = guild
    end
    CustomNetTables:SetTableValue("guilds", "players", players)

    print("[GUILDS] Player " .. playerID .. " -> " .. guild_id)

    -- Значок гильдии на уже появившегося героя (новым героям его вешает OnNPCSpawned)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero and AlkoGuild then
        AlkoGuild:OnNPCSpawned(hero)
    end
end

function Guilds:GetPlayerGuild(playerID)
    return self.players and self.players[playerID] or GUILD_NONE
end

function Guilds:GetUnitGuild(unit)
    if not unit or unit:IsNull() or not unit.GetPlayerOwnerID then
        return GUILD_NONE
    end

    local playerID = unit:GetPlayerOwnerID()
    if playerID == nil or playerID < 0 then
        return GUILD_NONE
    end

    return self:GetPlayerGuild(playerID)
end
