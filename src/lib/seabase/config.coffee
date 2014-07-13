window.SBConf =
  colours:
    base03:    '#002b36';
    base02:    '#073642';
    base01:    '#586e75';
    base00:    '#657b83';
    base0:     '#839496';
    base1:     '#93a1a1';
    base2:     '#eee8d5';
    base3:     '#fdf6e3';
    yellow:    '#b58900';
    orange:    '#cb4b16';
    red:       '#dc322f';
    magenta:   '#d33682';
    violet:    '#6c71c4';
    blue:      '#268bd2';
    cyan:      '#2aa198';
    green:     '#859900';
  bodyparts:
    body:
      fatal: true
      hp: 10
    head:
      fatal: true
    arm:
      fatal: false
    leg:
      fatal: false
  monsters:
    human:
      weapon: 'small_sword'
      char: '@'
      bodyparts:
        body: {}
    seamonkey:
      bodyparts:
        body:
          hp: 5
      level: 1
      name: 'seamonkey'
      char: 's'
      colour: 'cyan'
      weapon: 'bite'
    merlion:
      level: 2
      hp: 10
      name: 'merlion'
      char: 'm'
      weapon: 'bite'
  weapons:
    golden_hammer:
      name: 'golden hammer'
      type: 'crushing'
      att: 5
      dmg: [4,8]
    small_sword:
      name: 'small sword'
      type: 'slashing'
      att: 1
      dmg: [3,5]
    bite:
      name: 'bite'
      type: 'slashing'
      att: 2
      dmg: [2,4]
  getWeapon: (key) ->
    SBConf['weapons'][key]
