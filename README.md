# Seabase

Seabase is an **underwater** HTML5 Roguelike built with Phaser and ROT.js.

[Under construction sign]

## Building

Build using NodeJS and browserify:

```
$ npm install
$ cake build
```

Requires a local webserver. I use [knod](https://github.com/moserrya/knod), `gem install knod`. Then:

```
$ knod
```

### Developing

You can also use `watchify` to automatically compile:

  * `watchify -t coffeeify --extension=".coffee" src/seabase.coffee -o js/seabase.js`

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
