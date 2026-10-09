LinkLuaModifier(
    "modifier_custom_earthquake_aura",
    "abilities/custom_earthquake_bounce",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_suprunov_opa_frost",
    "abilities/custom_earthquake_bounce",
    LUA_MODIFIER_MOTION_NONE
)

--------------------------------------------------------------------------------
-- ТРЕКИ
-- Без аганима ульта всегда играет chronoshift. С аганимом при касте у игрока
-- открывается меню выбора трека (panorama: suprunov_music.*), и от трека зависит ульта:
--   chronoshift — обычная ульта со станами
--   terra       — без станов и подбрасываний, КД предметов не больше scepter_item_cooldown, герой светится
--   opa         — +opa_spell_amp% к урону от магии и взрыв Шивы вокруг героя (даже без Шивы)
-- sound — имя звукового события (vsndevts), stuns — оглушают ли волны.
--------------------------------------------------------------------------------

SUPRUNOV_MUSIC_MENU_TIME = 5   -- Сколько секунд даётся на выбор трека, потом играет chronoshift

SUPRUNOV_TRACKS = {
    chronoshift = { id = 1, sound = "chronoshift", stuns = true },
    terra       = { id = 2, sound = "terra",       stuns = false },
    opa         = { id = 3, sound = "opa",         stuns = true },
}

local function GetTrackById(id)
    for name, track in pairs(SUPRUNOV_TRACKS) do
        if track.id == id then
            return name, track
        end
    end
    return "chronoshift", SUPRUNOV_TRACKS.chronoshift
end

-- Ответ из меню выбора трека
if IsServer() and not SUPRUNOV_MUSIC_LISTENER then
    SUPRUNOV_MUSIC_LISTENER = CustomGameEventManager:RegisterListener("suprunov_music_pick", function(_, event)
        local ability = event.ability and EntIndexToHScript(event.ability)
        if not ability or ability:IsNull() or ability:GetAbilityName() ~= "custom_earthquake_bounce" then
            return
        end

        if ability:GetCaster():GetPlayerOwnerID() ~= event.PlayerID then
            return
        end

        ability:OnMusicPicked(event.menu, event.track)
    end)
end

custom_earthquake_bounce = class({})

function custom_earthquake_bounce:GetScepterSound()
    local kv = self:GetAbilityKeyValues() or {}
    local values = kv.AbilityValues or {}
    return values.scepter_sound or "Custom_Suprunov_Scepter"
end

function custom_earthquake_bounce:GetScepterGlowParticle()
    local kv = self:GetAbilityKeyValues() or {}
    local values = kv.AbilityValues or {}
    return values.scepter_glow_particle
        or "particles/units/heroes/hero_phoenix/phoenix_supernova_rebirth.vpcf"
end

function custom_earthquake_bounce:HasScepter()
    local caster = self:GetCaster()
    return caster and not caster:IsNull() and caster:HasScepter()
end

function custom_earthquake_bounce:IsScepterItemCooldownExcluded(item)
    if not item or item:IsNull() then
        return false
    end

    local item_name = item:GetAbilityName()

    -- Рефрешер полностью исключён из механики ограничения КД предметов.
    -- Также исключаем Refresher Shard, если он используется в вашей кастомке.
    return item_name == "item_refresher"
        or item_name == "item_refresher_shard"
end

function custom_earthquake_bounce:ApplyScepterItemCooldown()
    if not self:HasScepter() then
        return
    end

    local caster = self:GetCaster()
    local cooldown = self:GetSpecialValueFor("scepter_item_cooldown")

    for slot = 0, 8 do
        local item = caster:GetItemInSlot(slot)
        if item and not item:IsNull() and not self:IsScepterItemCooldownExcluded(item) then
            -- У каждого предмета во время ульты максимальный текущий КД = scepter_item_cooldown (5 сек).
            -- Готовые предметы не блокируем. Если предмет только что использован
            -- и его обычный КД больше лимита, уменьшаем его до лимита.
            if item:GetCooldownTimeRemaining() > cooldown then
                item:EndCooldown()
                item:StartCooldown(cooldown)
            end
        end
    end
end

function custom_earthquake_bounce:OnSpellStart()
    if not self:HasScepter() then
        self:StartTrack("chronoshift")
        return
    end

    -- С аганимом — меню выбора трека. Не выбрал вовремя — chronoshift.
    self.music_menu = (self.music_menu or 0) + 1
    local menu = self.music_menu

    local player = self:GetCaster():GetPlayerOwner()
    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "suprunov_music_menu", {
            ability = self:entindex(),
            menu = menu,
            time = SUPRUNOV_MUSIC_MENU_TIME,
        })
    end

    Timers:CreateTimer(SUPRUNOV_MUSIC_MENU_TIME, function()
        if not self:IsNull() and self.music_menu == menu then
            self:StartTrack("chronoshift")
        end
    end)
end

function custom_earthquake_bounce:OnMusicPicked(menu, track)
    if menu == nil or self.music_menu ~= menu or not SUPRUNOV_TRACKS[track] then
        return
    end

    self:StartTrack(track)
end

function custom_earthquake_bounce:StartTrack(track)
    -- Меню больше не ждём
    self.music_menu = nil

    local caster = self:GetCaster()
    if not caster or caster:IsNull() or not caster:IsAlive() then
        return
    end

    -- Повторный каст (рефрешер): старая аура со своим треком заменяется новой
    caster:RemoveModifierByName("modifier_custom_earthquake_aura")

    caster:AddNewModifier(
        caster,
        self,
        "modifier_custom_earthquake_aura",
        {
            duration = self:GetSpecialValueFor("aura_duration"),
            track = SUPRUNOV_TRACKS[track].id,
        }
    )
end

-- OPA: активка Шивы вокруг героя — расходящаяся волна холода
function custom_earthquake_bounce:CastShivaBlast()
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("opa_shiva_radius")
    local speed = self:GetSpecialValueFor("opa_shiva_speed")
    local damage = self:GetSpecialValueFor("opa_shiva_damage")
    local slow_duration = self:GetSpecialValueFor("opa_shiva_slow_duration")
    local origin = caster:GetAbsOrigin()

    caster:EmitSound("DOTA_Item.ShivasGuard.Activate")

    local fx = ParticleManager:CreateParticle(
        "particles/items2_fx/shivas_guard_active.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )
    ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius / speed, speed))
    ParticleManager:ReleaseParticleIndex(fx)

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        local delay = (enemy:GetAbsOrigin() - origin):Length2D() / speed

        Timers:CreateTimer(delay, function()
            if not enemy or enemy:IsNull() or not enemy:IsAlive() then
                return
            end

            ApplyDamage({
                victim = enemy,
                attacker = caster,
                damage = damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self,
            })

            enemy:AddNewModifier(caster, self, "modifier_suprunov_opa_frost", { duration = slow_duration })

            local hit_fx = ParticleManager:CreateParticle(
                "particles/items2_fx/shivas_guard_impact.vpcf",
                PATTACH_ABSORIGIN_FOLLOW,
                enemy
            )
            ParticleManager:SetParticleControlEnt(hit_fx, 1, enemy, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
            ParticleManager:ReleaseParticleIndex(hit_fx)
        end)
    end
end

--------------------------------------------------------------------------------

modifier_custom_earthquake_aura = class({})

function modifier_custom_earthquake_aura:IsHidden()
    return false
end

function modifier_custom_earthquake_aura:IsDebuff()
    return false
end

function modifier_custom_earthquake_aura:IsPurgable()
    return false
end

-- Номер трека хранится в стаках, чтобы клиент тоже знал его (усиление магии в подсказке)
function modifier_custom_earthquake_aura:GetTrack()
    return GetTrackById(self:GetStackCount())
end

function modifier_custom_earthquake_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    }
end

function modifier_custom_earthquake_aura:GetModifierSpellAmplify_Percentage()
    if self:GetTrack() ~= "opa" then
        return 0
    end

    local ability = self:GetAbility()
    return ability and not ability:IsNull() and ability:GetSpecialValueFor("opa_spell_amp") or 0
end

--------------------------------------------------------------------------------
-- СОЗДАНИЕ АУРЫ
--------------------------------------------------------------------------------

function modifier_custom_earthquake_aura:OnCreated(kv)
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("interval")

    self:SetStackCount(kv.track or SUPRUNOV_TRACKS.chronoshift.id)

    local track_name, track = self:GetTrack()
    self.track_sound = track.sound
    self.stuns = track.stuns

    caster:EmitSound(track.sound)

    if track_name == "terra" then
        -- Постоянное свечение самого героя на время ульты.
        self.glow_pfx = ParticleManager:CreateParticle(
            "particles/items_fx/ogre_seal_totem_smash_flash.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            caster
        )
        ParticleManager:SetParticleControl(
            self.glow_pfx,
            1,
            Vector(1, 1, 1)
        )

        -- Сразу выставляем КД и дальше поддерживаем его всё время ульты.
        ability:ApplyScepterItemCooldown()
        self.item_cd_timer = Timers:CreateTimer(0.1, function()
            if not self or self:IsNull() then
                return nil
            end

            local current_ability = self:GetAbility()
            local current_caster = self:GetCaster()
            if not current_ability or current_ability:IsNull()
                or not current_caster or current_caster:IsNull() then
                return nil
            end

            if current_ability:HasScepter() and current_caster:IsAlive() then
                current_ability:ApplyScepterItemCooldown()
                return 0.25
            end

            return nil
        end)
    elseif track_name == "opa" then
        ability:CastShivaBlast()
    end

    -- Первый удар сразу
    self:OnIntervalThink()

    -- Повторные удары
    self:StartIntervalThink(interval)
end

--------------------------------------------------------------------------------
-- УДАР
--------------------------------------------------------------------------------

function modifier_custom_earthquake_aura:OnIntervalThink()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if not caster or caster:IsNull() then
        return
    end

    if not caster:IsAlive() then
        return
    end

    if not ability or ability:IsNull() then
        return
    end

    local caster_pos = caster:GetAbsOrigin()

    local radius = ability:GetSpecialValueFor("radius")
    local delay = ability:GetSpecialValueFor("delay")
    local damage = ability:GetSpecialValueFor("damage")
    local stun_duration = ability:GetSpecialValueFor("stun_duration")
    local bounce_height = ability:GetSpecialValueFor("bounce_height")
    local bounce_duration = ability:GetSpecialValueFor("bounce_duration")

    ------------------------------------------------------------
    -- Обновляем размер поля
    ------------------------------------------------------------

    if self.pfx then
        ParticleManager:SetParticleControl(
            self.pfx,
            1,
            Vector(radius, radius, radius)
        )
    end

    ------------------------------------------------------------
    -- Визуальная волна
    ------------------------------------------------------------

    local pulse_fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_centaur/centaur_warstomp.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )

    ParticleManager:SetParticleControl(
        pulse_fx,
        1,
        Vector(radius, radius, radius)
    )

    ParticleManager:ReleaseParticleIndex(pulse_fx)

    ------------------------------------------------------------
    -- Ищем врагов
    ------------------------------------------------------------

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster_pos,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    ------------------------------------------------------------
    -- ЗАДЕРЖКА ПЕРЕД УДАРОМ
    ------------------------------------------------------------

    for _, enemy in pairs(enemies) do

        Timers:CreateTimer(delay, function()

            -- Аура закончилась
            if not self or self:IsNull() then
                return
            end

            -- Враг умер / исчез
            if not enemy or enemy:IsNull() or not enemy:IsAlive() then
                return
            end

            --------------------------------------------------------
            -- УРОН
            --------------------------------------------------------

            ApplyDamage({
                victim = enemy,
                attacker = caster,
                damage = damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = ability
            })

            enemy:EmitSound("Hero_Leshrac.Split_Earth")

            -- Трек terra: только урон, без станов и подбрасываний
            if not self.stuns then
                return
            end

            --------------------------------------------------------
            -- МИКРОСТАН
            --------------------------------------------------------

            enemy:AddNewModifier(
                caster,
                ability,
                "modifier_generic_stunned",
                {
                    duration = stun_duration
                }
            )


            --------------------------------------------------------
            -- ПОДБРАСЫВАНИЕ
            --------------------------------------------------------

            enemy:AddNewModifier(
                caster,
                ability,
                "modifier_knockback",
                {
                    should_knockback_z = true,

                    knockback_duration = bounce_duration,
                    duration = bounce_duration,

                    knockback_distance = 0,
                    knockback_height = bounce_height,

                    center_x = enemy:GetAbsOrigin().x,
                    center_y = enemy:GetAbsOrigin().y,
                    center_z = enemy:GetAbsOrigin().z
                }
            )

        end)
    end
end

--------------------------------------------------------------------------------
-- УДАЛЕНИЕ АУРЫ
--------------------------------------------------------------------------------

function modifier_custom_earthquake_aura:OnDestroy()
    if not IsServer() then
        return
    end

    if self.pfx then

        ParticleManager:DestroyParticle(
            self.pfx,
            false
        )

        ParticleManager:ReleaseParticleIndex(
            self.pfx
        )

        self.pfx = nil
    end

    if self.glow_pfx then
        ParticleManager:DestroyParticle(
            self.glow_pfx,
            false
        )
        ParticleManager:ReleaseParticleIndex(
            self.glow_pfx
        )
        self.glow_pfx = nil
    end

    local caster = self:GetCaster()

    if caster and not caster:IsNull() and self.track_sound then
        caster:StopSound(self.track_sound)
    end
end

--------------------------------------------------------------------------------
-- OPA: замедление от взрыва Шивы
--------------------------------------------------------------------------------

modifier_suprunov_opa_frost = class({})

function modifier_suprunov_opa_frost:IsHidden() return false end
function modifier_suprunov_opa_frost:IsDebuff() return true end
function modifier_suprunov_opa_frost:IsPurgable() return true end
function modifier_suprunov_opa_frost:GetTexture() return "item_shivas_guard" end

function modifier_suprunov_opa_frost:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_suprunov_opa_frost:GetModifierMoveSpeedBonus_Percentage()
    local ability = self:GetAbility()
    return ability and not ability:IsNull() and -ability:GetSpecialValueFor("opa_shiva_slow") or 0
end

function modifier_suprunov_opa_frost:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost.vpcf"
end