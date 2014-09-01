class Animal

  width = 90
  console.log "THIS", @

  constructor: (@settings) ->

  	@color = "blue"
  	console.log "my width", width
  	console.log "constructed", @

  getheight: ->
  	return 7

duck = new Animal
console.log "height", do duck.getheight
      
