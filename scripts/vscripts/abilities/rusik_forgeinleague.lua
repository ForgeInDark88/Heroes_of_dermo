-- Русик: ульта "ForgeInLeague"
-- Русик начинает турнир. Если в радиусе хотя бы 2 вражеских героя — вокруг
-- встаёт арена: союзные и вражеские герои внутри не могут её покинуть, у всех
-- участников безмолвие и заглушение (только руки), союзники получают скорость
-- атаки. Посторонних героев арена выталкивает.
-- Итог турнира:
--   все враги-участники пали (или по таймеру у союзников больше % здоровья) —
--     союзники-участники получают золото;
--   все союзники-участники пали (или по таймеру у врагов больше % здоровья) —
--     судьи бьют выживших врагов молнией (магический урон).
-- Если враг в радиусе один — турнир отменяется: он просто получает урон и
-- оглушение. Проходит сквозь невосприимчивость к эффектам.

rusik_forgeinleague = class({})

LinkLuaModifier("modifier_rusik_forgeinleague_arena", "abilities/rusik_forgeinleague", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_forgeinleague_fighter", "abilities/rusik_forgeinleague", LUA_MODIFIER_MOTION_NONE)

function rusik_forgeinleague:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

local function FindHeroes(caster, origin, radius, team_filter)
    local units = FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        radius,
        team_filter,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
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

function rusik_forgeinleague:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")

    local enemies = FindHeroes(caster, origin, radius, DOTA_UNIT_TARGET_TEAM_ENEMY)

    caster:EmitSound("Hero_LegionCommander.Duel")

    if #enemies == 0 then
        return
    end

    if #enemies == 1 then
        self:CancelTournament(enemies[1])
        return
    end

    local allies = FindHeroes(caster, origin, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY)

    local thinker = CreateModifierThinker(
        caster,
        self,
        "modifier_rusik_forgeinleague_arena",
        { duration = self:GetSpecialValueFor("duration") },
        origin,
        caster:GetTeamNumber(),
        false
    )
    local arena = thinker and thinker:FindModifierByName("modifier_rusik_forgeinleague_arena")
    if arena then
        arena:Setup(allies, enemies)
    end
end

-- Один противник: турнира не будет, просто урон и оглушение
function rusik_forgeinleague:CancelTournament(enemy)
    local caster = self:GetCaster()

    self:JudgeStrike(enemy, self:GetSpecialValueFor("solo_damage"))

    if enemy:IsAlive() then
        enemy:AddNewModifier(caster, self, "modifier_stunned", {
            duration = self:GetSpecialValueFor("solo_stun") * (1 - enemy:GetStatusResistance())
        })
    end
end

function rusik_forgeinleague:JudgeStrike(enemy, damage)
    local pos = enemy:GetAbsOrigin()
    local fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(fx, 0, pos)
    ParticleManager:SetParticleControl(fx, 1, pos + Vector(0, 0, 2000))
    ParticleManager:ReleaseParticleIndex(fx)
    enemy:EmitSound("Hero_Zuus.LightningBolt")

    ApplyDamage({
        victim = enemy,
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self,
    })
end

--------------------------------------------------------------------------------
-- АРЕНА (висит на thinker'е в центре)
--------------------------------------------------------------------------------

modifier_rusik_forgeinleague_arena = class({})

function modifier_rusik_forgeinleague_arena:IsHidden() return true end
function modifier_rusik_forgeinleague_arena:IsPurgable() return false end

function modifier_rusik_forgeinleague_arena:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    self.origin = self:GetParent():GetAbsOrigin()
    self.radius = ability:GetSpecialValueFor("radius")
    self.allies = {}
    self.enemies = {}
    self.participants = {}

    self.fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_mars/mars_arena_of_blood.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(self.fx, 0, self.origin)
    ParticleManager:SetParticleControl(self.fx, 1, Vector(self.radius + 50, 0, 0))
    ParticleManager:SetParticleControl(self.fx, 2, self.origin)
    ParticleManager:SetParticleControl(self.fx, 3, self.origin)

    EmitSoundOnLocationWithCaster(self.origin, "Hero_Mars.ArenaOfBlood.Start", self:GetCaster())
end

function modifier_rusik_forgeinleague_arena:Setup(allies, enemies)
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local duration = self:GetRemainingTime()

    self.allies = allies
    self.enemies = enemies

    for _, list in pairs({ allies, enemies }) do
        for _, hero in pairs(list) do
            self.participants[hero:entindex()] = true
            hero:AddNewModifier(caster, ability, "modifier_rusik_forgeinleague_fighter", { duration = duration })
        end
    end

    self:StartIntervalThink(0.05)
end

local function CountAlive(list)
    local alive = 0
    for _, hero in pairs(list) do
        if not hero:IsNull() and hero:IsAlive() then
            alive = alive + 1
        end
    end
    return alive
end

local function AverageHealthPct(list)
    local total, count = 0, 0
    for _, hero in pairs(list) do
        if not hero:IsNull() and hero:IsAlive() then
            total = total + hero:GetHealthPercent()
            count = count + 1
        end
    end
    if count == 0 then return 0 end
    return total / count
end

function modifier_rusik_forgeinleague_arena:OnIntervalThink()
    -- Участники не могут выйти
    for _, list in pairs({ self.allies, self.enemies }) do
        for _, hero in pairs(list) do
            if not hero:IsNull() and hero:IsAlive() then
                local offset = hero:GetAbsOrigin() - self.origin
                offset.z = 0
                if offset:Length2D() > self.radius - 40 then
                    local dir = offset:Length2D() > 1 and offset:Normalized() or Vector(1, 0, 0)
                    FindClearSpaceForUnit(hero, self.origin + dir * (self.radius - 80), true)
                end
            end
        end
    end

    -- Посторонние не могут зайти
    local outsiders = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(),
        self.origin,
        nil,
        self.radius + 40,
        DOTA_UNIT_TARGET_TEAM_BOTH,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_ANY_ORDER,
        false
    )
    for _, unit in pairs(outsiders) do
        if not self.participants[unit:entindex()] then
            local offset = unit:GetAbsOrigin() - self.origin
            offset.z = 0
            local dir = offset:Length2D() > 1 and offset:Normalized() or Vector(1, 0, 0)
            FindClearSpaceForUnit(unit, self.origin + dir * (self.radius + 100), true)
        end
    end

    -- Досрочный итог
    if CountAlive(self.enemies) == 0 then
        self.winner = "allies"
        self:Destroy()
    elseif CountAlive(self.allies) == 0 then
        self.winner = "enemies"
        self:Destroy()
    end
end

function modifier_rusik_forgeinleague_arena:OnDestroy()
    if not IsServer() then return end

    if self.fx then
        ParticleManager:DestroyParticle(self.fx, false)
        ParticleManager:ReleaseParticleIndex(self.fx)
    end
    EmitSoundOnLocationWithCaster(self.origin, "Hero_Mars.ArenaOfBlood.End", self:GetCaster())

    for _, list in pairs({ self.allies, self.enemies }) do
        for _, hero in pairs(list) do
            if not hero:IsNull() then
                hero:RemoveModifierByName("modifier_rusik_forgeinleague_fighter")
            end
        end
    end

    local ability = self:GetAbility()
    if ability and not ability:IsNull() and #self.enemies > 0 then
        -- По таймеру побеждает сторона с большим средним % здоровья
        local winner = self.winner
        if not winner then
            winner = AverageHealthPct(self.allies) >= AverageHealthPct(self.enemies) and "allies" or "enemies"
        end

        if winner == "allies" then
            local gold = ability:GetSpecialValueFor("win_gold")
            for _, hero in pairs(self.allies) do
                if not hero:IsNull() and hero:IsAlive() then
                    hero:ModifyGold(gold, true, DOTA_ModifyGold_Unspecified)
                    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, hero, gold, nil)
                    local fx = ParticleManager:CreateParticle("particles/generic_gameplay/lasthit_coins.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
                    ParticleManager:ReleaseParticleIndex(fx)
                    hero:EmitSound("General.Coins")
                end
            end
        else
            local damage = ability:GetSpecialValueFor("lose_damage")
            for _, hero in pairs(self.enemies) do
                if not hero:IsNull() and hero:IsAlive() then
                    ability:JudgeStrike(hero, damage)
                end
            end
        end
    end

    UTIL_Remove(self:GetParent())
end

--------------------------------------------------------------------------------
-- УЧАСТНИК ТУРНИРА: безмолвие + заглушение, союзникам — скорость атаки
--------------------------------------------------------------------------------

modifier_rusik_forgeinleague_fighter = class({})

function modifier_rusik_forgeinleague_fighter:IsHidden() return false end
function modifier_rusik_forgeinleague_fighter:IsPurgable() return false end

function modifier_rusik_forgeinleague_fighter:IsDebuff()
    return self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber()
end

function modifier_rusik_forgeinleague_fighter:OnCreated()
    local ability = self:GetAbility()
    self.attack_speed = 0
    if ability and self:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then
        self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    end
end

function modifier_rusik_forgeinleague_fighter:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED] = true,
    }
end

function modifier_rusik_forgeinleague_fighter:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_rusik_forgeinleague_fighter:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

function modifier_rusik_forgeinleague_fighter:GetEffectName()
    if self.attack_speed > 0 then
        return "particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_buff.vpcf"
    end
    return "particles/generic_gameplay/generic_silence.vpcf"
end

function modifier_rusik_forgeinleague_fighter:GetEffectAttachType()
    if self.attack_speed > 0 then
        return PATTACH_ABSORIGIN_FOLLOW
    end
    return PATTACH_OVERHEAD_FOLLOW
end
