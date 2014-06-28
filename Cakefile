fs = require 'fs'
browserify  = require 'browserify'
coffeeify  = require 'coffeeify'

task 'build', 'Build Seabase', (options) ->
  b = browserify(['./src/seabase.coffee'], { extensions: ['.coffee']})
  b.transform coffeeify
  b.bundle
    transform: coffeeify,
    (err, result) ->
      if not err
        fs.writeFile "js/seabase.js", result, (err) ->
          if not err
            console.log "✔ built seabase"
          else
            console.error "failed: " + err
      else
        console.error "failed: " + err
