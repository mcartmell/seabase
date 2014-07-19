class Seabase.Menu
  constructor: (@sb) ->
    @game = sb.game
    @rows = []
    @draw()
    @currentMenu = {
    }
    @defaultMenu = {
      items: [
        {
          text: 'wield',
          callback: @buildWieldMenu
        },
      ]
    }
    @showMenu @defaultMenu

  buildWieldMenu: =>
    player = @sb.map.player
    allItems = player.getItems('weapon')
    weapons = []
    allItems.forEach (weapon, idx) ->
      weapons.push [weapon.name, idx]
    wieldCallback = (idx) ->
      player.wieldWeapon allItems[idx]
    @showMenu @buildSelectMenu(weapons, wieldCallback)

  showMenu: (menu) ->
    @clearMenu()
    menu.items.forEach (item, i) =>
      @rows[i].text = item.text
    @currentMenu = menu
    @selectRow(0)

  clearMenu: ->
    @all (row) ->
      row.text = ''

  numItems: ->
    if @currentMenu?
      @currentMenu.items.length
    else
      0

  select: ->
    @pick(@selectedRow)

  buildSelectMenu: (items, cb) ->
    mitems = []
    for i in items
      hash = if i instanceof Array
        {
          text: i[0],
          value: i[1]
        }
      else
        {
          text: i,
          value: i
        }
      mitems.push hash
    return {
      items: mitems,
      selectCallback: cb
    }

  pick: (i) ->
    menuItem = @currentMenu.items[i]
    if menuItem.callback
      return menuItem.callback()
    else if menuItem.value?
      @currentMenu.selectCallback(menuItem.value)
      @hide()
    else if menuItem.submenu
      return @showMenu(menuItem.submenu)

  draw: ->
    # background
    @group = new Phaser.Group(@game)
    @group.visible = false
    top = 12
    left = 12
    padding = 12
    g = @game.add.graphics(left, top)
    width = @sb.game.width - 24
    height = @sb.game.height - 24
    g.beginFill(0x000000, 0.6)
    g.drawRect(0,0,width,height)
    g.endFill()
    g.fixedToCamera = true
    @group.add(g)

    fontSize = 48 
    rowHeight = fontSize * 1.2

    maxRows = ((g.getBounds().height - (padding * 2)) / rowHeight)

    for i in [0..maxRows-1]
      y = top + padding + (i * rowHeight)
      x = left + padding
      # rows
      t = @game.add.text(x, y, '', { font: fontSize + 'px monospace', fill: SBConf.colours['base1'], align: 'left' })
      t.fixedToCamera = true
      @rows[i] = t
      @group.add(t)

    @selectRow(0)

  hide: ->
    @group.visible = false

  show: ->
    @group.visible = true

  all: (cb) ->
    @rows.forEach (row) =>
      cb(row)

  isVisible: ->
    @group && @group.visible

  highlightRow: (i) ->
    @all (row) ->
      row.fill = SBConf.colours['base1']
    @rows[i].fill = SBConf.colours['blue']

  selectRow: (i) ->
    return unless @numItems() > 0
    if i > (@numItems() - 1)
      return @selectRow(0)
    if i < 0
      return @selectRow(@numItems() - 1)
    @selectedRow = i
    @highlightRow(i)

  move: (dir) ->
    switch dir
      when 'up'
        @selectRow(@selectedRow - 1)
      when 'down'
        @selectRow(@selectedRow + 1)

  toggle: ->
    if @isVisible()
      @hide()
    else
      @showMenu(@defaultMenu)
      @show()
