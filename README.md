# Seabase

Seabase is an **underwater** HTML5 Roguelike built with Phaser and ROT.js.

[Under construction sign]

## Running

Dependencies for compiling:

* npm
* coffee-script
* browserify
* coffeeify

* Copy dependencies into `js/`:
  * phaser.min.js
  * rot.js
  * hammer.min.js
* Compile using (yes this is ridiculous):
  * `watchify -t coffeeify --extension=".coffee" seabase.coffee -o seabase.js`

## Features:

* Map generation (using rot.js)
* Camera follow (using Phaser)
* Going up/down levels
* Enemies
* Combat
* Death
* XP and leveling
* Difficulty (different enemies)

## TODO:

* Items
  * Weapons
  * Armour
  * Loot
* Scoreboard
* Better AI
* More enemies
* Interesting stuff
