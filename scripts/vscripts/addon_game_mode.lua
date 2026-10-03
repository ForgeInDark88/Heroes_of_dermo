-- Main entry point for the custom game.
-- Keep the startup path simple so the gamemode can initialize reliably.

require('internal/util')
print('[CUSTOM_GAME] loading gamemode.lua')
require('gamemode')
print('[CUSTOM_GAME] gamemode.lua loaded')

function Precache(context)
    print('[CUSTOM_GAME] Precache()')

    -- Original Barebones/custom-game precache restored.
    PrecacheResource("particle", "particles/econ/items/pudge/hungry_clown/hungry_clown_rot_body.vpcf", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_custom.vsndevts", context)

    PrecacheResource("particle", "particles/units/heroes/hero_razor/razor_ambient_g.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_razor/razor_static_link.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_morphling/morphling_waveform.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_pudge/pudge_rot.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf", context)

    PrecacheResource("model", "models/items/invoker/dark_artistry/dark_artistry_hair_model.vmdl", context)

    PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf", context)
    PrecacheResource("model", "models/creeps/neutral_creeps/n_creep_gnoll/n_creep_gnoll_frost.vmdl", context)
    PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_suicide.vpcf", context)

    PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_doom_aura.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_lich/lich_gaze.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_centaur/centaur_warstomp.vpcf", context)

    PrecacheResource("particle", "particles/units/heroes/hero_tinker/tinker_laser.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_queenofpain/queen_scream_of_pain.vpcf", context)
    
    PrecacheResource("particle", "particles/items3_fx/mango_consume.vpcf", context)
    
    PrecacheResource("particle", "particles/units/heroes/hero_alchemist/alchemist_acid_spray.vpcf", context)
    
    PrecacheResource("particle", "particles/units/heroes/hero_furion/furion_sprout_damage_aoe.vpcf", context)
    
    PrecacheResource("particle", "particles/econ/items/dark_seer/dark_seer_imperious/dark_seer_imperious_back_flashes_glow_b.vpcf", context)
    
    PrecacheResource("particle", "particles/units/heroes/hero_sandking/sandking_epicenter_ambient.vpcf", context)
    
    PrecacheResource("particle", "particles/units/heroes/hero_enigma/enigma_base_attack.vpcf", context)

    PrecacheResource("particle", "particles/units/heroes/hero_tidehunter/tidehunter_anchor_hero_mid.vpcf", context)
    
    PrecacheResource("particle", "particles/units/heroes/hero_life_stealer/life_stealer_rage_bkb01.vpcf", context)

    PrecacheResource("particle", "particles/units/heroes/hero_marci/marci_rebound.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf", context)
    
  
    PrecacheResource("particle", "particles/units/heroes/hero_marci/marci_companion_run.vpcf", context)
    PrecacheResource("particle",   "particles/units/heroes/hero_marci/marci_unleash.vpcf", context)
   
    PrecacheResource("model",  "models/heroes/queenofpain/queenofpain.vmdl", context)
    
    PrecacheResource("model",  "models/heroes/enigma/eidelon.vmdl", context)

    PrecacheResource(
    "particle",
    "particles/econ/generic/generic_buff_1/generic_buff_1.vpcf",
    context
    )

end

function Activate()
    print('[CUSTOM_GAME] Activate()')

    if GameRules.GameMode ~= nil then
        print('[CUSTOM_GAME] GameMode already exists; skipping duplicate initialization')
        return
    end

    GameRules.GameMode = GameMode()
    GameRules.GameMode:_InitGameMode()

    print('[CUSTOM_GAME] GameMode initialized')
end
