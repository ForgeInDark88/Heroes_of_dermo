-- Гильдия Ветмо
-- На базе Radiant и на базе Dire стоит неуязвимая постройка Ветмо (надгробие).
-- С каждой волной крипов постройка выпускает по VETMO_NEFORS_PER_MEMBER зомби-нефоров
-- за каждого живого или мёртвого члена гильдии своей команды. Нефоры идут как обычные
-- крипы: у Radiant — на верхний лайн, у Dire — на нижний (VETMO_LANE_POINTS).
-- Нефоры понемногу усиливаются со временем игры.
--
-- Место постройки на карте: info_target с именем из VETMO_GUILD_POINTS в Hammer.
-- Если точки нет — постройка встаёт рядом с фонтаном своей команды.

if VetmoGuild == nil then
    VetmoGuild = class({})
end

VETMO_GUILD_ID = "vetmo"                 -- id в GUILD_LIST (guilds.lua)
VETMO_GUILD_UNIT_NAME = "npc_vetmo_guild"
VETMO_NEFOR_UNIT_NAME = "npc_vetmo_nefor"

VETMO_NEFORS_PER_MEMBER = 2

-- Точки на карте, где стоит постройка
VETMO_GUILD_POINTS = {
    [DOTA_TEAM_GOODGUYS] = "vetmo_guild_radiant",
    [DOTA_TEAM_BADGUYS]  = "vetmo_guild_dire",
}

-- Точки спавна волн (WAVE_POINTS в gamemode.lua), куда идут нефоры:
-- Radiant — верхний лайн, Dire — нижний
VETMO_LANE_POINTS = {
    [DOTA_TEAM_GOODGUYS] = "rr1",
    [DOTA_TEAM_BADGUYS]  = "y1",
}

-- Усиление нефоров: каждые VETMO_UPGRADE_INTERVAL сек. игры
VETMO_UPGRADE_INTERVAL = 5 * 60
VETMO_UPGRADE_HEALTH = 60
VETMO_UPGRADE_DAMAGE = 4

LinkLuaModifier("modifier_vetmo_guild", "units/vetmo_guild", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vetmo_guild_member", "units/vetmo_guild", LUA_MODIFIER_MOTION_NONE)

function VetmoGuild:IsMember(unit)
    return Guilds ~= nil and Guilds:GetUnitGuild(unit) == VETMO_GUILD_ID
end

function VetmoGuild:FindFountain(team)
    for _, fountain in pairs(Entities:FindAllByClassname("ent_dota_fountain")) do
        if fountain:GetTeamNumber() == team then
            return fountain
        end
    end
    return nil
end

function VetmoGuild:GetBuildingPosition(team)
    local point = Entities:FindByName(nil, VETMO_GUILD_POINTS[team])
    if point then
        return point:GetAbsOrigin()
    end

    print("[VETMO_GUILD] '" .. VETMO_GUILD_POINTS[team] .. "' not found on map, placing near fountain")

    local fountain = self:FindFountain(team)
    if not fountain then
        return nil
    end

    -- Чуть в сторону центра карты от фонтана
    local origin = fountain:GetAbsOrigin()
    local to_center = Vector(0, 0, 0) - origin
    to_center.z = 0
    if to_center:Length2D() < 1 then
        return origin
    end
    return GetGroundPosition(origin + to_center:Normalized() * 900, nil)
end

-- Вызывается в начале игры (gamemode.lua, OnGameInProgress)
function VetmoGuild:Spawn()
    self.buildings = self.buildings or {}

    for team in pairs(VETMO_GUILD_POINTS) do
        local building = self.buildings[team]
        if not building or building:IsNull() then
            local position = self:GetBuildingPosition(team)
            if position then
                building = CreateUnitByName(VETMO_GUILD_UNIT_NAME, position, true, nil, nil, team)
                if building then
                    building:AddNewModifier(building, nil, "modifier_vetmo_guild", {})
                    self.buildings[team] = building
                    print("[VETMO_GUILD] Building spawned for team " .. team)
                else
                    print("[VETMO_GUILD] ERROR: spawn failed for team " .. team)
                end
            else
                print("[VETMO_GUILD] ERROR: no position for team " .. team)
            end
        end
    end
end

function VetmoGuild:CountMembers(team)
    local count = 0
    for playerID = 0, DOTA_MAX_PLAYERS - 1 do
        if PlayerResource:IsValidTeamPlayerID(playerID)
            and PlayerResource:GetTeam(playerID) == team
            and Guilds and Guilds:GetPlayerGuild(playerID) == VETMO_GUILD_ID then
            count = count + 1
        end
    end
    return count
end

-- Вызывается с каждой волной крипов (gamemode.lua, WaveMobs)
function VetmoGuild:SpawnNefors()
    if not self.buildings then return end

    local level = math.floor(GameRules:GetDOTATime(false, false) / VETMO_UPGRADE_INTERVAL)

    for team, building in pairs(self.buildings) do
        local defeated = GameMode.TeamDefeated and GameMode.TeamDefeated[team]
        local count = self:CountMembers(team) * VETMO_NEFORS_PER_MEMBER

        if not defeated and count > 0 and building and not building:IsNull() then
            local lane_point = Entities:FindByName(nil, VETMO_LANE_POINTS[team])
            if not lane_point then
                print("[VETMO_GUILD] ERROR: lane point '" .. VETMO_LANE_POINTS[team] .. "' not found")
            else
                for i = 1, count do
                    self:SpawnNefor(team, building, lane_point, level)
                end

                local fx = ParticleManager:CreateParticle(
                    "particles/units/heroes/hero_undying/undying_zombie_spawn.vpcf",
                    PATTACH_ABSORIGIN,
                    building
                )
                ParticleManager:ReleaseParticleIndex(fx)
            end
        end
    end
end

function VetmoGuild:SpawnNefor(team, building, lane_point, level)
    local position = building:GetAbsOrigin() + RandomVector(RandomFloat(150, 250))
    local nefor = CreateUnitByName(VETMO_NEFOR_UNIT_NAME, position, true, nil, nil, team)
    if not nefor then return end

    if level > 0 then
        local health = nefor:GetMaxHealth() + VETMO_UPGRADE_HEALTH * level
        nefor:SetBaseMaxHealth(health)
        nefor:SetMaxHealth(health)
        nefor:SetHealth(health)
        nefor:SetBaseDamageMin(nefor:GetBaseDamageMin() + VETMO_UPGRADE_DAMAGE * level)
        nefor:SetBaseDamageMax(nefor:GetBaseDamageMax() + VETMO_UPGRADE_DAMAGE * level)
    end

    nefor:SetInitialGoalEntity(lane_point)
end

-- Вызывается при спавне любого NPC (Guilds:OnNPCSpawned): членам гильдии вешаем значок
function VetmoGuild:OnNPCSpawned(npc)
    if npc:IsRealHero() and self:IsMember(npc) and not npc:HasModifier("modifier_vetmo_guild_member") then
        npc:AddNewModifier(npc, nil, "modifier_vetmo_guild_member", {})
    end
end

--------------------------------------------------------------------------------
-- ПОСТРОЙКА: неуязвима, ничего не делает сама
--------------------------------------------------------------------------------

modifier_vetmo_guild = class({})

function modifier_vetmo_guild:IsHidden() return true end
function modifier_vetmo_guild:IsPurgable() return false end
function modifier_vetmo_guild:RemoveOnDeath() return false end

function modifier_vetmo_guild:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_DISARMED] = true,
    }
end

--------------------------------------------------------------------------------
-- ЗНАЧОК ЧЛЕНА ГИЛЬДИИ
--------------------------------------------------------------------------------

modifier_vetmo_guild_member = class({})

function modifier_vetmo_guild_member:IsHidden() return false end
function modifier_vetmo_guild_member:IsDebuff() return false end
function modifier_vetmo_guild_member:IsPurgable() return false end
function modifier_vetmo_guild_member:RemoveOnDeath() return false end
function modifier_vetmo_guild_member:IsPermanent() return true end
function modifier_vetmo_guild_member:GetTexture() return "undying_tombstone" end
