function UpdateInnateLevel(keys)
    local caster = keys.caster
    local ability = keys.ability
    
    if not caster or not ability then return end

    -- Находим ультимейт героя (обычно 6-й слот / индекс 5)
    local ult = caster:GetAbilityByIndex(5)
    
    if ult then
        local ult_level = ult:GetLevel()
        
        -- Повышаем уровень врожденки синхронно с ультом:
        -- Ульт 0 лвл -> Врожденка 1 лвл
        -- Ульт 1 лвл -> Врожденка 2 лвл
        -- Ульт 2 лвл -> Врожденка 3 лвл
        -- Ульт 3 лвл -> Врожденка 4 лвл
        local target_level = ult_level + 1
        
        if ability:GetLevel() ~= target_level then
            ability:SetLevel(target_level)
        end
    end
end