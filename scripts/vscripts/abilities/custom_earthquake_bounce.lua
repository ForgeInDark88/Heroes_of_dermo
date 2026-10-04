LinkLuaModifier(
    "modifier_custom_earthquake_aura",
    "abilities/custom_earthquake_bounce",
    LUA_MODIFIER_MOTION_NONE
)

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

    -- Рефрешер полностью исключён из механики 3-секундного КД.
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
            -- У каждого предмета во время ульты максимальный текущий КД = 3 сек.
            -- Готовые предметы не блокируем. Если предмет только что использован
            -- и его обычный КД больше 3 сек, уменьшаем его до 3 сек.
            if item:GetCooldownTimeRemaining() > cooldown then
                item:EndCooldown()
                item:StartCooldown(cooldown)
            end
        end
    end
end

function custom_earthquake_bounce:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("aura_duration")

    caster:AddNewModifier(
        caster,
        self,
        "modifier_custom_earthquake_aura",
        {
            duration = duration
        }
    )
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

--------------------------------------------------------------------------------
-- СОЗДАНИЕ АУРЫ
--------------------------------------------------------------------------------

function modifier_custom_earthquake_aura:OnCreated()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local radius = ability:GetSpecialValueFor("radius")

    local interval = ability:GetSpecialValueFor("interval")



    if ability:HasScepter() then
        caster:EmitSound("terra")

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
    else
        caster:EmitSound("chronoshift")
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

            --------------------------------------------------------
            -- МИКРОСТАН
            -- Стан оставляем и при наличии Aghanim's Scepter.
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

            enemy:EmitSound("Hero_Leshrac.Split_Earth")

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

    if caster and not caster:IsNull() then
        local ability = self:GetAbility()
        if ability and not ability:IsNull() and ability:HasScepter() then
            caster:StopSound("terra")
        else
            caster:StopSound("chronoshift")
        end
    end
end