golda = class({})

function golda:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target or target:TriggerSpellAbsorb(self) then
        return
    end

    -- Чтение параметров из AbilityValues
    local damage = self:GetSpecialValueFor("damage")
    local root_duration = self:GetSpecialValueFor("root_duration")
    local knockback_distance = self:GetSpecialValueFor("knockback_distance")
    local knockback_duration = self:GetSpecialValueFor("knockback_duration")

    -- Звук и эффекты
    target:EmitSound("goldak")
    
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_laser.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    
    -- Control Point 0: Исток (пушка Тинкера)
    ParticleManager:SetParticleControlEnt(
        particle, 
        0, 
        caster, 
        PATTACH_POINT_FOLLOW, 
        "attach_attack1", 
        caster:GetAbsOrigin(), 
        true
    )
    
    -- Control Point 1: Цель (куда бьет лазер)
    ParticleManager:SetParticleControlEnt(
        particle, 
        1, 
        target, 
        PATTACH_POINT_FOLLOW, 
        "attach_hitloc", 
        target:GetAbsOrigin(), 
        true
    )
    
    -- Control Point 9: Важно для партикла Тинкера! Отвечает за позицию источника луча
    ParticleManager:SetParticleControlEnt(
        particle, 
        9, 
        caster, 
        PATTACH_POINT_FOLLOW, 
        "attach_attack1", 
        caster:GetAbsOrigin(), 
        true
    )
    
    ParticleManager:ReleaseParticleIndex(particle)

    -- Нанесение чистого урона
    local damageTable = {
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        ability = self
    }
    ApplyDamage(damageTable)

    -- Отталкивание (Knockback)
    target:AddNewModifier(caster, self, "modifier_knockback", {
        center_x = caster:GetAbsOrigin().x,
        center_y = caster:GetAbsOrigin().y,
        center_z = caster:GetAbsOrigin().z,
        duration = knockback_duration,
        knockback_duration = knockback_duration,
        knockback_distance = knockback_distance,
        knockback_height = 0,
        should_hit_floor = true
    })

    -- Наложение оцепенения (Root)
    target:AddNewModifier(caster, self, "modifier_rooted", {
        duration = root_duration
    })
end