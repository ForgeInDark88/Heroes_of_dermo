-- Гильдия алкашей
-- Неуязвимая постройка на карте. Члены гильдии (Русик, Супрунов, Артем)
-- активируют её, подойдя вплотную (правый клик по гильдии ведёт героя к ней):
-- мгновенно восстанавливается здоровье и мана. Перезарядка у каждого героя
-- своя — 120 сек. (висит на герое как "Похмелье").
--
-- Место на карте: info_target с именем ALKO_GUILD_POINT_NAME в Hammer.
-- Если точки нет — гильдия появится в центре карты.

if AlkoGuild == nil then
    AlkoGuild = class({})
end

ALKO_GUILD_UNIT_NAME = "npc_alko_guild"
ALKO_GUILD_POINT_NAME = "alko_guild_point"

ALKO_GUILD_ACTIVATION_RADIUS = 400
ALKO_GUILD_COOLDOWN = 120
ALKO_GUILD_HEAL_PCT = 50   -- % от макс. здоровья
ALKO_GUILD_MANA_PCT = 50   -- % от макс. маны

-- override_hero оставляет герою имя базового героя, поэтому проверяем оба
ALKO_GUILD_MEMBERS = {
    ["npc_dota_hero_obsidian_destroyer"] = true, -- Русик
    ["npc_dota_hero_rusik"] = true,
    ["npc_dota_hero_tinker"] = true,             -- Супрунов
    ["npc_dota_hero_suprunov"] = true,
    ["npc_dota_hero_hoodwink"] = true,           -- Артем
    ["npc_dota_hero_artem"] = true,
}

LinkLuaModifier("modifier_alko_guild", "units/alko_guild", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_alko_guild_member", "units/alko_guild", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_alko_guild_cooldown", "units/alko_guild", LUA_MODIFIER_MOTION_NONE)

function AlkoGuild:IsMember(unit)
    return unit and not unit:IsNull() and unit.GetUnitName
        and ALKO_GUILD_MEMBERS[unit:GetUnitName()] == true
end

function AlkoGuild:Spawn(position)
    if not position then
        local point = Entities:FindByName(nil, ALKO_GUILD_POINT_NAME)
        if point then
            position = point:GetAbsOrigin()
        else
            print("[ALKO_GUILD] '" .. ALKO_GUILD_POINT_NAME .. "' not found on map, using map center")
            position = GetGroundPosition(Vector(0, 0, 0), nil)
        end
    end

    local guild = CreateUnitByName(ALKO_GUILD_UNIT_NAME, position, true, nil, nil, DOTA_TEAM_NEUTRALS)
    if not guild then
        print("[ALKO_GUILD] ERROR: spawn failed!")
        return nil
    end

    guild:SetForwardVector(Vector(0, -1, 0))
    guild:AddNewModifier(guild, nil, "modifier_alko_guild", {})
    print("[ALKO_GUILD] Guild spawned")

    return guild
end

-- Вызывается при спавне любого NPC: членам гильдии вешаем значок
function AlkoGuild:OnNPCSpawned(npc)
    if npc:IsRealHero() and self:IsMember(npc) and not npc:HasModifier("modifier_alko_guild_member") then
        npc:AddNewModifier(npc, nil, "modifier_alko_guild_member", {})
    end
end

-- Фильтр приказов: правый клик (атака) по гильдии превращается в "подойти"
function AlkoGuild:FilterOrder(filterTable)
    if filterTable.order_type ~= DOTA_UNIT_ORDER_ATTACK_TARGET then return end

    local target = filterTable.entindex_target and EntIndexToHScript(filterTable.entindex_target)
    if target and not target:IsNull() and target:GetUnitName() == ALKO_GUILD_UNIT_NAME then
        filterTable.order_type = DOTA_UNIT_ORDER_MOVE_TO_TARGET
    end
end

function AlkoGuild:Activate(guild, hero)
    hero:AddNewModifier(hero, nil, "modifier_alko_guild_cooldown", { duration = ALKO_GUILD_COOLDOWN })

    local heal = hero:GetMaxHealth() * ALKO_GUILD_HEAL_PCT / 100
    local mana = hero:GetMaxMana() * ALKO_GUILD_MANA_PCT / 100

    hero:Heal(heal, nil)
    hero:GiveMana(mana)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, hero, heal, nil)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, hero, mana, nil)

    local fx = ParticleManager:CreateParticle("particles/items_fx/bottle.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
    Timers:CreateTimer(2.0, function()
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end)

    local guild_fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf",
        PATTACH_ABSORIGIN,
        guild
    )
    ParticleManager:SetParticleControl(guild_fx, 1, Vector(ALKO_GUILD_ACTIVATION_RADIUS, ALKO_GUILD_ACTIVATION_RADIUS, ALKO_GUILD_ACTIVATION_RADIUS))
    ParticleManager:ReleaseParticleIndex(guild_fx)

    hero:EmitSound("Bottle.Drink")
    guild:EmitSound("Hero_Brewmaster.CinderBrew.Cast")
end

--------------------------------------------------------------------------------
-- ПОСТРОЙКА: неуязвима, ищет рядом членов гильдии
--------------------------------------------------------------------------------

modifier_alko_guild = class({})

function modifier_alko_guild:IsHidden() return true end
function modifier_alko_guild:IsPurgable() return false end
function modifier_alko_guild:RemoveOnDeath() return false end

function modifier_alko_guild:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_DISARMED] = true,
    }
end

function modifier_alko_guild:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(0.25)
end

function modifier_alko_guild:OnIntervalThink()
    local guild = self:GetParent()

    local heroes = FindUnitsInRadius(
        guild:GetTeamNumber(),
        guild:GetAbsOrigin(),
        nil,
        ALKO_GUILD_ACTIVATION_RADIUS,
        DOTA_UNIT_TARGET_TEAM_BOTH,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
        FIND_ANY_ORDER,
        false
    )

    for _, hero in pairs(heroes) do
        if hero:IsRealHero() and hero:IsAlive() and AlkoGuild:IsMember(hero)
            and not hero:HasModifier("modifier_alko_guild_cooldown") then
            AlkoGuild:Activate(guild, hero)
        end
    end
end

--------------------------------------------------------------------------------
-- ЗНАЧОК ЧЛЕНА ГИЛЬДИИ
--------------------------------------------------------------------------------

modifier_alko_guild_member = class({})

function modifier_alko_guild_member:IsHidden() return false end
function modifier_alko_guild_member:IsDebuff() return false end
function modifier_alko_guild_member:IsPurgable() return false end
function modifier_alko_guild_member:RemoveOnDeath() return false end
function modifier_alko_guild_member:IsPermanent() return true end
function modifier_alko_guild_member:GetTexture() return "brewmaster_drunken_brawler" end

--------------------------------------------------------------------------------
-- ПОХМЕЛЬЕ: перезарядка гильдии для героя
--------------------------------------------------------------------------------

modifier_alko_guild_cooldown = class({})

function modifier_alko_guild_cooldown:IsHidden() return false end
function modifier_alko_guild_cooldown:IsDebuff() return true end
function modifier_alko_guild_cooldown:IsPurgable() return false end
function modifier_alko_guild_cooldown:RemoveOnDeath() return false end
function modifier_alko_guild_cooldown:GetTexture() return "brewmaster_cinder_brew" end
