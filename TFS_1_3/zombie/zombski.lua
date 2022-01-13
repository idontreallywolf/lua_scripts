local mType = Game.createMonsterType("Zombski")
local monster = {}
monster.description = "a zombski"
monster.experience = 1
monster.outfit = {
    lookType = 311
}
monster.health = 100
monster.maxHealth = monster.health
monster.race = "undead"
monster.corpse = 9875
monster.speed = 200
monster.maxSummons = 0
monster.changeTarget = {
    interval = 1000,
    chance   = 40
}
monster.flags = {
    hostile            = true,
    summonable         = false,
    attackable         = false,
    convinceable       = false,
    illusionable       = false,
    canPushItems       = true,
    canPushCreatures   = false,
    targetDistance     = 1,
    staticAttackChance = 100
}
monster.voices = {
    interval = 5000,
    chance   = 10,
    {text = "KHGKHGKH", yell = false},
    {text = "KHAAAA",   yell = false}
}
monster.attacks = {
    {name = "melee", attack = 1, skill = 1, effect = CONST_ME_DRAWBLOOD, interval = 1500}
}
monster.defenses = {
    defense = 55,
    armor = 55,
--  {name = "combat", type = COMBAT_HEALING, chance = 15, interval = 2*1000, minDamage = 180, maxDamage = 250, effect = CONST_ME_MAGIC_BLUE},
--  {name = "speed", chance = 15, interval = 2*1000, speed = 320, effect = CONST_ME_MAGIC_RED}
}
monster.elements = {
    {type = COMBAT_PHYSICALDAMAGE, percent = 100},
    {type = COMBAT_DEATHDAMAGE,    percent = 100},
    {type = COMBAT_ENERGYDAMAGE,   percent = 100},
    {type = COMBAT_EARTHDAMAGE,    percent = 100},
    {type = COMBAT_ICEDAMAGE,      percent = 100},
    {type = COMBAT_HOLYDAMAGE,     percent = 100},
    {type = COMBAT_POISONDAMAGE,   percent = 100},
    {type = COMBAT_FIREDAMAGE,     percent = 100},
    {type = COMBAT_DROWNDAMAGE,    percent = 100},
    {type = COMBAT_LIFEDRAIN,      percent = 100}
}
monster.immunities = {
    {type = "fire", combat = true, condition = true},
    {type = "drown", condition = true},
    {type = "lifedrain", combat = true},
    {type = "paralyze", condition = true},
    {type = "invisible", condition = true}
}
mType:register(monster)