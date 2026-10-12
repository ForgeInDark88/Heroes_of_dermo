-- Гильдии без построек: бонусы висят прямо на героях-членах гильдии.
--
-- Слюни (slyuni): атаки по врагам обслюнявливают их — минус броня и замедление.
-- Анимешники (anime): когда здоровье падает ниже порога, герой входит
--   в режим протагониста — лечится и ускоряется. Перезарядка своя у каждого героя.

if GuildPerks == nil then
    GuildPerks = class({})
end

SLYUNI_GUILD_ID = "slyuni"
SLYUNI_DURATION = 3
SLYUNI_ARMOR = 2
SLYUNI_SLOW = 10           -- %

ANIME_GUILD_ID = "anime"
ANIME_HEALTH_THRESHOLD = 25  -- % здоровья
ANIME_HEAL_PCT = 20          -- % от макс. здоровья
ANIME_DURATION = 5
ANIME_ATTACK_SPEED = 40
ANIME_MOVE_SPEED = 20        -- %
ANIME_COOLDOWN = 90

LinkLuaModifier("modifier_guild_slyuni_member", "guild_perks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_guild_slyuni_debuff", "guild_perks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_guild_anime_member", "guild_perks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_guild_anime_protagonist", "guild_perks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_guild_anime_cooldown", "guild_perks", LUA_MODIFIER_MOTION_NONE)

local MEMBER_MODIFIERS = {
    [SLYUNI_GUILD_ID] = "modifier_guild_slyuni_member",
    [ANIME_GUILD_ID] = "modifier_guild_anime_member",
}

-- Вызывается при спавне любого NPC и при выборе гильдии (Guilds:OnNPCSpawned)
function GuildPerks:OnNPCSpawned(npc)
    if not npc:IsRealHero() or not Guilds then return end

    local modifier = MEMBER_MODIFIERS[Guilds:GetUnitGuild(npc)]
    if modifier and not npc:HasModifier(modifier) then
        npc:AddNewModifier(npc, nil, modifier, {})
    end
end

--------------------------------------------------------------------------------
-- СЛЮНИ
--------------------------------------------------------------------------------

modifier_guild_slyuni_member = class({})

function modifier_guild_slyuni_member:IsHidden() return false end
function modifier_guild_slyuni_member:IsDebuff() return false end
function modifier_guild_slyuni_member:IsPurgable() return false end
function modifier_guild_slyuni_member:RemoveOnDeath() return false end
function modifier_guild_slyuni_member:IsPermanent() return true end
function modifier_guild_slyuni_member:GetTexture() return "bristleback_viscous_nasal_goo" end

function modifier_guild_slyuni_member:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_guild_slyuni_member:OnAttackLanded(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.attacker ~= parent then return end

    local target = params.target
    if not target or target:IsNull() or not target:IsAlive() then return end
    if target:IsBuilding() or target:GetTeamNumber() == parent:GetTeamNumber() then return end

    target:AddNewModifier(parent, nil, "modifier_guild_slyuni_debuff", { duration = SLYUNI_DURATION })
end

modifier_guild_slyuni_debuff = class({})

function modifier_guild_slyuni_debuff:IsHidden() return false end
function modifier_guild_slyuni_debuff:IsDebuff() return true end
function modifier_guild_slyuni_debuff:IsPurgable() return true end
function modifier_guild_slyuni_debuff:GetTexture() return "bristleback_viscous_nasal_goo" end

function modifier_guild_slyuni_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_guild_slyuni_debuff:GetModifierPhysicalArmorBonus()
    return -SLYUNI_ARMOR
end

function modifier_guild_slyuni_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -SLYUNI_SLOW
end

function modifier_guild_slyuni_debuff:GetEffectName()
    return "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf"
end

function modifier_guild_slyuni_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------------
-- АНИМЕШНИКИ
--------------------------------------------------------------------------------

modifier_guild_anime_member = class({})

function modifier_guild_anime_member:IsHidden() return false end
function modifier_guild_anime_member:IsDebuff() return false end
function modifier_guild_anime_member:IsPurgable() return false end
function modifier_guild_anime_member:RemoveOnDeath() return false end
function modifier_guild_anime_member:IsPermanent() return true end
function modifier_guild_anime_member:GetTexture() return "marci_unleash" end

function modifier_guild_anime_member:DeclareFunctions()
    return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_guild_anime_member:OnTakeDamage(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.unit ~= parent or not parent:IsAlive() then return end
    if parent:GetHealthPercent() >= ANIME_HEALTH_THRESHOLD then return end
    if parent:HasModifier("modifier_guild_anime_cooldown") then return end

    parent:AddNewModifier(parent, nil, "modifier_guild_anime_cooldown", { duration = ANIME_COOLDOWN })
    parent:AddNewModifier(parent, nil, "modifier_guild_anime_protagonist", { duration = ANIME_DURATION })

    local heal = parent:GetMaxHealth() * ANIME_HEAL_PCT / 100
    parent:Heal(heal, nil)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, heal, nil)
    parent:EmitSound("DOTA_Item.MaskOfMadness.Activate")
end

modifier_guild_anime_protagonist = class({})

function modifier_guild_anime_protagonist:IsHidden() return false end
function modifier_guild_anime_protagonist:IsDebuff() return false end
function modifier_guild_anime_protagonist:IsPurgable() return true end
function modifier_guild_anime_protagonist:GetTexture() return "marci_unleash" end

function modifier_guild_anime_protagonist:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_guild_anime_protagonist:GetModifierAttackSpeedBonus_Constant()
    return ANIME_ATTACK_SPEED
end

function modifier_guild_anime_protagonist:GetModifierMoveSpeedBonus_Percentage()
    return ANIME_MOVE_SPEED
end

function modifier_guild_anime_protagonist:GetEffectName()
    return "particles/items2_fx/mask_of_madness.vpcf"
end

function modifier_guild_anime_protagonist:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

modifier_guild_anime_cooldown = class({})

function modifier_guild_anime_cooldown:IsHidden() return false end
function modifier_guild_anime_cooldown:IsDebuff() return true end
function modifier_guild_anime_cooldown:IsPurgable() return false end
function modifier_guild_anime_cooldown:RemoveOnDeath() return false end
function modifier_guild_anime_cooldown:GetTexture() return "marci_unleash" end
