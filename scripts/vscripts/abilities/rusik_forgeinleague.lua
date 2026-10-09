-- Русик: ульта "ForgeInLeague"
-- Русик начинает турнир: в области появляется арена, союзные и вражеские
-- герои внутри дерутся между собой, все с заглушением (безмолвие + немота
-- предметов) и не могут выйти с арены. Союзники получают скорость атаки.
--   * Союзники победили — Русик и союзники-участники получают золото.
--   * Победил противник — Русик и союзники-участники получают урон.
-- Победитель: сторона, у которой остались живые (или к концу турнира
-- больше средний % здоровья).
-- Турнир идёт и 1 на 1. Если противнику не с кем драться (на арене нет ни
-- одного союзного героя, включая самого Русика), турнир отменяется: врагам
-- просто наносится урон и оглушение.

rusik_forgeinleague = class({})

LinkLuaModifier("modifier_rusik_forgeinleague_arena", "abilities/rusik_forgeinleague", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_forgeinleague_participant", "abilities/rusik_forgeinleague", LUA_MODIFIER_MOTION_NONE)

local function FindRealHeroes(caster, center, radius, team_filter, flags)
    local units = FindUnitsInRadius(
        caster:GetTeamNumber(),
        center,
        nil,
        radius,
        team_filter,
        DOTA_UNIT_TARGET_HERO,
        flags,
        FIND_ANY_ORDER,
        false
    )

    local heroes = {}
    for _, unit in pairs(units) do
        if unit:IsRealHero() and not unit:IsClone() then
            table.insert(heroes, unit)
        end
    end
    return heroes
end

function rusik_forgeinleague:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function rusik_forgeinleague:OnSpellStart()
    local caster = self:GetCaster()
    local center = self:GetCursorPosition()
    local radius = self:GetSpecialValueFor("radius")

    local enemies = FindRealHeroes(caster, center, radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
    local allies = FindRealHeroes(caster, center, radius,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_FLAG_NONE)

    if #enemies == 0 or #allies == 0 then
        self:CancelTournament(center, radius, enemies)
        return
    end

    local thinker = CreateModifierThinker(
        caster,
        self,
        "modifier_rusik_forgeinleague_arena",
        { duration = self:GetSpecialValueFor("duration") },
        center,
        caster:GetTeamNumber(),
        false
    )

    local arena = thinker:FindModifierByName("modifier_rusik_forgeinleague_arena")
    if arena then
        arena:Setup(allies, enemies)
    end
end

-- Турнир отменён: урон и оглушение врагам в области
function rusik_forgeinleague:CancelTournament(center, radius, enemies)
    local caster = self:GetCaster()

    local fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(fx, 0, center)
    ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
    ParticleManager:SetParticleControl(fx, 2, Vector(radius, radius, radius))
    Timers:CreateTimer(2.0, function()
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end)

    EmitSoundOnLocationWithCaster(center, "Hero_ObsidianDestroyer.SanityEclipse", caster)

    local damage = self:GetSpecialValueFor("cancel_damage")
    local stun = self:GetSpecialValueFor("cancel_stun_duration")

    for _, enemy in pairs(enemies) do
        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self,
        })
        if enemy:IsAlive() then
            enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = stun })
        end
    end
end

--------------------------------------------------------------------------------
-- АРЕНА (thinker): следит за участниками и подводит итог
--------------------------------------------------------------------------------

modifier_rusik_forgeinleague_arena = class({})

function modifier_rusik_forgeinleague_arena:IsHidden() return true end
function modifier_rusik_forgeinleague_arena:IsPurgable() return false end

function modifier_rusik_forgeinleague_arena:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    self.center = self:GetParent():GetAbsOrigin()
    self.radius = ability:GetSpecialValueFor("radius")
    self.allies = {}
    self.enemies = {}

    self.fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_mars/mars_arena_of_blood.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(self.fx, 0, self.center)
    ParticleManager:SetParticleControl(self.fx, 1, Vector(self.radius + 50, 0, 0))
    ParticleManager:SetParticleControl(self.fx, 2, self.center)
    ParticleManager:SetParticleControl(self.fx, 3, self.center)

    EmitSoundOnLocationWithCaster(self.center, "Hero_Mars.ArenaOfBlood.Start", self:GetCaster())
end

function modifier_rusik_forgeinleague_arena:Setup(allies, enemies)
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local kv = {
        duration = self:GetRemainingTime(),
        x = self.center.x,
        y = self.center.y,
        radius = self.radius,
    }

    self.allies = allies
    self.enemies = enemies

    for _, list in pairs({ allies, enemies }) do
        for _, hero in pairs(list) do
            hero:AddNewModifier(caster, ability, "modifier_rusik_forgeinleague_participant", kv)
        end
    end

    self:StartIntervalThink(0.1)
end

local function CountAlive(list)
    local alive = 0
    local health_pct = 0
    for _, hero in pairs(list) do
        if not hero:IsNull() and hero:IsAlive() then
            alive = alive + 1
            health_pct = health_pct + hero:GetHealthPercent()
        end
    end
    return alive, alive > 0 and health_pct / alive or 0
end

function modifier_rusik_forgeinleague_arena:OnIntervalThink()
    local allies_alive = CountAlive(self.allies)
    local enemies_alive = CountAlive(self.enemies)

    -- Одна из сторон полностью выбыла — турнир окончен досрочно
    if allies_alive == 0 or enemies_alive == 0 then
        self:Destroy()
    end
end

function modifier_rusik_forgeinleague_arena:OnDestroy()
    if not IsServer() then return end

    if self.fx then
        ParticleManager:DestroyParticle(self.fx, false)
        ParticleManager:ReleaseParticleIndex(self.fx)
    end

    EmitSoundOnLocationWithCaster(self.center, "Hero_Mars.ArenaOfBlood.End", self:GetCaster())

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    for _, list in pairs({ self.allies, self.enemies }) do
        for _, hero in pairs(list) do
            if not hero:IsNull() then
                hero:RemoveModifierByNameAndCaster("modifier_rusik_forgeinleague_participant", caster)
            end
        end
    end

    if #self.allies == 0 or not ability or ability:IsNull() or not caster or caster:IsNull() then return end

    local allies_alive, allies_hp = CountAlive(self.allies)
    local enemies_alive, enemies_hp = CountAlive(self.enemies)

    local allies_won
    if enemies_alive == 0 and allies_alive > 0 then
        allies_won = true
    elseif allies_alive == 0 then
        allies_won = false
    else
        allies_won = allies_hp >= enemies_hp
    end

    -- Русик получает награду/наказание, даже если сам стоял вне арены
    local recipients = { caster }
    for _, hero in pairs(self.allies) do
        if hero ~= caster and not hero:IsNull() then
            table.insert(recipients, hero)
        end
    end

    if allies_won then
        local gold = ability:GetSpecialValueFor("gold_reward")
        for _, hero in pairs(recipients) do
            local player_id = hero:GetPlayerOwnerID()
            if player_id and player_id >= 0 then
                PlayerResource:ModifyGold(player_id, gold, true, DOTA_ModifyGold_Unspecified)
                SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, hero, gold, nil)

                local fx = ParticleManager:CreateParticle(
                    "particles/generic_gameplay/lasthit_coins.vpcf",
                    PATTACH_ABSORIGIN_FOLLOW,
                    hero
                )
                ParticleManager:ReleaseParticleIndex(fx)
            end
        end
        caster:EmitSound("General.Coins")
    else
        local damage = ability:GetSpecialValueFor("lose_damage")
        for _, hero in pairs(recipients) do
            if hero:IsAlive() then
                ApplyDamage({
                    victim = hero,
                    attacker = caster,
                    damage = damage,
                    damage_type = DAMAGE_TYPE_PURE,
                    damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
                    ability = ability,
                })
            end
        end
        caster:EmitSound("Hero_ObsidianDestroyer.SanityEclipse")
    end
end

--------------------------------------------------------------------------------
-- УЧАСТНИК ТУРНИРА: заглушение, не может покинуть арену,
-- союзникам — скорость атаки
--------------------------------------------------------------------------------

modifier_rusik_forgeinleague_participant = class({})

function modifier_rusik_forgeinleague_participant:IsHidden() return false end
function modifier_rusik_forgeinleague_participant:IsPurgable() return false end

function modifier_rusik_forgeinleague_participant:IsDebuff()
    return self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber()
end

function modifier_rusik_forgeinleague_participant:OnCreated(kv)
    local ability = self:GetAbility()
    self.attack_speed = 0
    if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() and ability then
        self.attack_speed = ability:GetSpecialValueFor("ally_attack_speed")
    end

    if not IsServer() then return end

    self.center = Vector(kv.x or 0, kv.y or 0, 0)
    self.radius = kv.radius or 0
    self:StartIntervalThink(0.05)
end

-- Не даём выйти (или блинкнуть) за пределы арены
function modifier_rusik_forgeinleague_participant:OnIntervalThink()
    local parent = self:GetParent()
    if not parent:IsAlive() then return end

    local pos = parent:GetAbsOrigin()
    local offset = pos - self.center
    offset.z = 0
    if offset:Length2D() <= self.radius then return end

    local inside = self.center + offset:Normalized() * (self.radius - 40)
    inside.z = GetGroundHeight(inside, parent)
    FindClearSpaceForUnit(parent, inside, true)
    parent:Stop()
end

function modifier_rusik_forgeinleague_participant:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED] = true,
    }
end

function modifier_rusik_forgeinleague_participant:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_rusik_forgeinleague_participant:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

function modifier_rusik_forgeinleague_participant:GetEffectName()
    return "particles/generic_gameplay/generic_silence.vpcf"
end

function modifier_rusik_forgeinleague_participant:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
