--------------------------------------------------------------------------------
-- БОСС БРУДСКОЕ (чёрная бруда)
--
-- Живучая:
--   - получает на BRUDSKOE_DAMAGE_REDUCTION% меньше урона, сопротивление эффектам;
--   - вампиризм с атак;
--   - за каждые BRUDSKOE_BROOD_HP_STEP% потерянного здоровья выпускает паучков рядом с собой;
--   - на BRUDSKOE_COCOON_HP_PCT% здоровья один раз прячется в кокон: неуязвима, лечится, зовёт паучков;
--   - если её утащить от дома дальше BRUDSKOE_LEASH_RANGE — возвращается и полностью лечится.
--
-- Пока идёт бой с брудой, всем игрокам играет музыка BRUDSKOE_FIGHT_MUSIC
-- (громкость — в content/soundevents/game_sounds_brudskoe.vsndevts).
-- Бой начинается с первого удара героя и заканчивается смертью бруды,
-- её возвратом в логово или если её BRUDSKOE_FIGHT_TIMEOUT сек. никто не бьёт.
--
-- При смерти по всей карте в случайных местах появляются агрессивные паучки.
--
-- Внешний вид: сет Widow of the Undermount Gloom — в npc_units_custom.txt (AttachWearables).
--
-- Место на карте: info_target с именем BRUDSKOE_SPAWN_POINT_NAME в Hammer.
--------------------------------------------------------------------------------

if BrudskoeBoss == nil then
    BrudskoeBoss = {}
end

BRUDSKOE_BOSS_NAME = "npc_brudskoe_boss"
BRUDSKOE_SPIDER_NAME = "npc_brudskoe_spider"

BRUDSKOE_SPAWN_POINT_NAME = "brudskoe_point"

BRUDSKOE_LEASH_RANGE = 1500
BRUDSKOE_KILL_GOLD = 400            -- голда каждому герою команды, убившей бруду

BRUDSKOE_DAMAGE_REDUCTION = 30      -- % меньше входящего урона
BRUDSKOE_STATUS_RESISTANCE = 50     -- % сопротивления эффектам (станы короче)
BRUDSKOE_LIFESTEAL = 30             -- % вампиризма с атак
BRUDSKOE_BROOD_HP_STEP = 10         -- каждые 10% потерянного HP...
BRUDSKOE_BROOD_SPIDERS = 2          -- ...вылезает столько паучков
BRUDSKOE_COCOON_HP_PCT = 35         -- на скольки % HP прячется в кокон (один раз)
BRUDSKOE_COCOON_DURATION = 4
BRUDSKOE_COCOON_HEAL_PCT = 25       -- сколько % макс. HP восстанавливает кокон
BRUDSKOE_COCOON_SPIDERS = 6

BRUDSKOE_DEATH_SPIDERS = 30         -- паучков по карте после смерти
BRUDSKOE_SPIDERS_MAX_ALIVE = 60     -- лимит живых паучков, чтобы не положить сервер
BRUDSKOE_SPIDER_AGGRO_RANGE = 900   -- с какого расстояния паучок бросается на героя
BRUDSKOE_FOUNTAIN_SAFE_RANGE = 1800 -- паучки не появляются ближе к фонтанам

BRUDSKOE_FIGHT_MUSIC = "brudskoe_fight_music"
BRUDSKOE_FIGHT_TIMEOUT = 10         -- через сколько сек. без ударов по бруде бой (и музыка) заканчивается
BRUDSKOE_FIGHT_MUSIC_LENGTH = 0     -- длина трека в сек.: если > 0, трек повторяется, пока идёт бой
BRUDSKOE_SPAWN_PARTICLE = "particles/units/heroes/hero_broodmother/broodmother_spiderlings_spawn.vpcf"
BRUDSKOE_COLOR = Vector(25, 25, 30)

LinkLuaModifier("modifier_brudskoe_carapace", "units/brudskoe_boss", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_brudskoe_cocoon", "units/brudskoe_boss", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------
-- Утилиты
--------------------------------------------------------------------------------

local function Announce(text)
    GameRules:SendCustomMessage("<font color='#8a8a8a'>" .. text .. "</font>", 0, 0)
end

local function IsUnitValid(unit)
    return unit and not unit:IsNull() and unit:IsAlive()
end

local function GetSpawnPosition()
    local point = Entities:FindByName(nil, BRUDSKOE_SPAWN_POINT_NAME)
    if point then
        return point:GetAbsOrigin()
    end

    print("[BRUDSKOE] '" .. BRUDSKOE_SPAWN_POINT_NAME .. "' not found on map, using map center")
    return GetGroundPosition(Vector(0, 0, 0), nil)
end

local function IsNearFountain(position)
    for _, fountain in pairs(Entities:FindAllByClassname("ent_dota_fountain")) do
        if (fountain:GetAbsOrigin() - position):Length2D() < BRUDSKOE_FOUNTAIN_SAFE_RANGE then
            return true
        end
    end
    return false
end

-- Случайная проходимая точка на карте (не у фонтанов)
local function GetRandomMapPosition()
    local min_x, max_x = GetWorldMinX(), GetWorldMaxX()
    local min_y, max_y = GetWorldMinY(), GetWorldMaxY()

    for _ = 1, 50 do
        local position = GetGroundPosition(Vector(RandomFloat(min_x, max_x), RandomFloat(min_y, max_y), 0), nil)

        if GridNav:IsTraversable(position) and not GridNav:IsBlocked(position) and not IsNearFountain(position) then
            return position
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- СПАВН И ИНИЦИАЛИЗАЦИЯ
--------------------------------------------------------------------------------

function BrudskoeBoss:Spawn()
    local position = GetSpawnPosition()

    local boss = CreateUnitByName(BRUDSKOE_BOSS_NAME, position, true, nil, nil, DOTA_TEAM_NEUTRALS)
    if not boss then
        print("[BRUDSKOE] ERROR: boss spawn failed!")
        return nil
    end

    boss.BrudskoeHome = position
    print("[BRUDSKOE] Boss spawned")

    return boss
end

function BrudskoeBoss:Init(unit)
    if unit.BrudskoeInitialized then
        return
    end

    unit.BrudskoeInitialized = true
    unit.BrudskoeHome = unit.BrudskoeHome or unit:GetAbsOrigin()

    unit:SetRenderColor(BRUDSKOE_COLOR.x, BRUDSKOE_COLOR.y, BRUDSKOE_COLOR.z)
    unit:AddNewModifier(unit, nil, "modifier_brudskoe_carapace", {})

    unit:SetContextThink("BrudskoeThink", function()
        return BrudskoeBoss:Think(unit)
    end, 1)

    print("[BRUDSKOE] Boss initialized")
end

-- Не даём утащить бруду: далеко от дома — бежит домой и полностью лечится
function BrudskoeBoss:Think(unit)
    if not IsUnitValid(unit) then
        return nil
    end

    if GameRules:IsGamePaused() then
        return 0.5
    end

    local home = unit.BrudskoeHome

    if unit.BrudskoeFighting
        and GameRules:GetGameTime() - (unit.BrudskoeLastHit or 0) > BRUDSKOE_FIGHT_TIMEOUT then
        self:StopFight(unit)
    end

    if unit.BrudskoeReturning then
        if (unit:GetAbsOrigin() - home):Length2D() < 200 then
            unit.BrudskoeReturning = false
            unit:SetHealth(unit:GetMaxHealth())
        else
            unit:MoveToPosition(home)
        end
        return 0.5
    end

    if (unit:GetAbsOrigin() - home):Length2D() > BRUDSKOE_LEASH_RANGE then
        unit.BrudskoeReturning = true
        self:StopFight(unit)
        unit:Stop()
        unit:MoveToPosition(home)
    end

    return 0.5
end

--------------------------------------------------------------------------------
-- БОЙ И МУЗЫКА
--------------------------------------------------------------------------------

function BrudskoeBoss:OnFightHit(boss)
    boss.BrudskoeLastHit = GameRules:GetGameTime()

    -- Пока бежит в логово лечиться, бой заново не начинается
    if boss.BrudskoeFighting or boss.BrudskoeReturning then
        return
    end

    boss.BrudskoeFighting = true
    boss.BrudskoeMusicId = (boss.BrudskoeMusicId or 0) + 1
    local music_id = boss.BrudskoeMusicId

    EmitGlobalSound(BRUDSKOE_FIGHT_MUSIC)
    Announce("Началась битва с Брудским!")

    if BRUDSKOE_FIGHT_MUSIC_LENGTH > 0 then
        Timers:CreateTimer(BRUDSKOE_FIGHT_MUSIC_LENGTH, function()
            if boss:IsNull() or not boss.BrudskoeFighting or boss.BrudskoeMusicId ~= music_id then
                return nil
            end
            EmitGlobalSound(BRUDSKOE_FIGHT_MUSIC)
            return BRUDSKOE_FIGHT_MUSIC_LENGTH
        end)
    end
end

function BrudskoeBoss:StopFight(boss)
    if not boss.BrudskoeFighting then
        return
    end

    boss.BrudskoeFighting = false
    StopGlobalSound(BRUDSKOE_FIGHT_MUSIC)
end

--------------------------------------------------------------------------------
-- ПАУЧКИ
--------------------------------------------------------------------------------

function BrudskoeBoss:CountAliveSpiders()
    self.Spiders = self.Spiders or {}

    local alive = 0
    for i = #self.Spiders, 1, -1 do
        if IsUnitValid(self.Spiders[i]) then
            alive = alive + 1
        else
            table.remove(self.Spiders, i)
        end
    end

    return alive
end

function BrudskoeBoss:SpawnSpider(position)
    if not position or self:CountAliveSpiders() >= BRUDSKOE_SPIDERS_MAX_ALIVE then
        return nil
    end

    local spider = CreateUnitByName(BRUDSKOE_SPIDER_NAME, position, true, nil, nil, DOTA_TEAM_NEUTRALS)
    if not spider then
        print("[BRUDSKOE] ERROR: spider spawn failed!")
        return nil
    end

    spider:SetRenderColor(BRUDSKOE_COLOR.x, BRUDSKOE_COLOR.y, BRUDSKOE_COLOR.z)
    table.insert(self.Spiders, spider)

    local fx = ParticleManager:CreateParticle(BRUDSKOE_SPAWN_PARTICLE, PATTACH_ABSORIGIN, spider)
    ParticleManager:ReleaseParticleIndex(fx)

    spider:SetContextThink("BrudskoeSpiderThink", function()
        return BrudskoeBoss:SpiderThink(spider)
    end, 0.5)

    return spider
end

function BrudskoeBoss:SpawnSpidersAround(boss, count)
    for _ = 1, count do
        self:SpawnSpider(boss:GetAbsOrigin() + RandomVector(RandomFloat(100, 300)))
    end
end

-- Паучки агрессивные: бросаются на ближайшего героя рядом
function BrudskoeBoss:SpiderThink(spider)
    if not IsUnitValid(spider) then
        return nil
    end

    if GameRules:IsGamePaused() then
        return 1
    end

    if spider:IsAttacking() and spider:GetAttackTarget() then
        return 1
    end

    local heroes = FindUnitsInRadius(
        spider:GetTeamNumber(),
        spider:GetAbsOrigin(),
        nil,
        BRUDSKOE_SPIDER_AGGRO_RANGE,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_CLOSEST,
        false
    )

    for _, hero in pairs(heroes) do
        if hero:IsAlive() then
            spider:MoveToTargetToAttack(hero)
            return 1.5
        end
    end

    return 1.5
end

--------------------------------------------------------------------------------
-- СМЕРТЬ
--------------------------------------------------------------------------------

function BrudskoeBoss:OnDeath(boss)
    -- entity_killed в этом проекте приходит в OnEntityKilled дважды
    if boss.BrudskoeDeathHandled then
        return
    end

    boss.BrudskoeDeathHandled = true

    print("[BRUDSKOE] Boss killed")

    local team = boss.BrudskoeKillerTeam

    if team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS then
        for playerID = 0, DOTA_MAX_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:GetTeam(playerID) == team then
                PlayerResource:ModifyGold(playerID, BRUDSKOE_KILL_GOLD, true, DOTA_ModifyGold_Unspecified)
            end
        end
    end

    self:StopFight(boss)
    Announce("Брудское повержена... но её детишки расползлись по всей карте!")

    local spawned = 0
    for _ = 1, BRUDSKOE_DEATH_SPIDERS do
        if self:SpawnSpider(GetRandomMapPosition()) then
            spawned = spawned + 1
        end
    end

    print("[BRUDSKOE] Spiders spawned across the map: " .. spawned)
end

--------------------------------------------------------------------------------
-- ПАНЦИРЬ: живучесть, вампиризм, паучки от урона, кокон
--------------------------------------------------------------------------------

modifier_brudskoe_carapace = class({})

function modifier_brudskoe_carapace:IsHidden() return false end
function modifier_brudskoe_carapace:IsPurgable() return false end
function modifier_brudskoe_carapace:RemoveOnDeath() return true end
function modifier_brudskoe_carapace:GetTexture() return "broodmother_insatiable_hunger" end

function modifier_brudskoe_carapace:OnCreated()
    if not IsServer() then return end
    self.brood_steps = 0
    self.cocoon_used = false
end

function modifier_brudskoe_carapace:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_brudskoe_carapace:GetModifierIncomingDamage_Percentage()
    return -BRUDSKOE_DAMAGE_REDUCTION
end

function modifier_brudskoe_carapace:GetModifierStatusResistanceStacking()
    return BRUDSKOE_STATUS_RESISTANCE
end

function modifier_brudskoe_carapace:OnTakeDamage(params)
    if not IsServer() then return end

    local boss = self:GetParent()

    -- Вампиризм с атак бруды
    if params.attacker == boss and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and params.damage > 0 then
        boss:Heal(params.damage * BRUDSKOE_LIFESTEAL / 100, nil)

        local fx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, boss)
        ParticleManager:ReleaseParticleIndex(fx)
        return
    end

    if params.unit ~= boss or not boss:IsAlive() then
        return
    end

    -- Удар от игроков: запоминаем команду (для награды) и запускаем/продлеваем бой с музыкой
    local attacker = params.attacker
    if attacker and not attacker:IsNull() then
        local team = attacker:GetTeamNumber()
        if team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS then
            boss.BrudskoeKillerTeam = team
            BrudskoeBoss:OnFightHit(boss)
        end
    end

    local hp_pct = boss:GetHealthPercent()

    -- Каждые BRUDSKOE_BROOD_HP_STEP% потерянного HP — паучки
    local steps = math.floor((100 - hp_pct) / BRUDSKOE_BROOD_HP_STEP)
    if steps > self.brood_steps then
        self.brood_steps = steps
        BrudskoeBoss:SpawnSpidersAround(boss, BRUDSKOE_BROOD_SPIDERS)
    end

    -- Кокон
    if not self.cocoon_used and hp_pct <= BRUDSKOE_COCOON_HP_PCT then
        self.cocoon_used = true
        boss:AddNewModifier(boss, nil, "modifier_brudskoe_cocoon", { duration = BRUDSKOE_COCOON_DURATION })
    end
end

--------------------------------------------------------------------------------
-- КОКОН: неуязвима, лечится, зовёт паучков
--------------------------------------------------------------------------------

modifier_brudskoe_cocoon = class({})

function modifier_brudskoe_cocoon:IsHidden() return false end
function modifier_brudskoe_cocoon:IsPurgable() return false end
function modifier_brudskoe_cocoon:GetTexture() return "broodmother_spin_web" end

function modifier_brudskoe_cocoon:GetEffectName()
    return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function modifier_brudskoe_cocoon:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_brudskoe_cocoon:OnCreated()
    if not IsServer() then return end

    local boss = self:GetParent()
    boss:Stop()
    boss:EmitSound("Hero_Broodmother.SpawnSpiderlings")

    self.heal_per_tick = boss:GetMaxHealth() * BRUDSKOE_COCOON_HEAL_PCT / 100 / (BRUDSKOE_COCOON_DURATION / 0.25)
    self:StartIntervalThink(0.25)

    BrudskoeBoss:SpawnSpidersAround(boss, BRUDSKOE_COCOON_SPIDERS)
    Announce("Брудское окуталась коконом и зовёт детишек!")
end

function modifier_brudskoe_cocoon:OnIntervalThink()
    self:GetParent():Heal(self.heal_per_tick, nil)
end

function modifier_brudskoe_cocoon:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_STUNNED] = true,
    }
end
