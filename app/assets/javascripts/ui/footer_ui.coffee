class Footer.UI
  constructor: ->

  initialize: (location) ->
    if location[1] == '' || location[1] == 'signup' || location[2] == 'new' || location[3] == 'edit'
      $('.display-status').css('display', 'block')
      $('body').css('background', '#fff') 
    
    if location[1] != '' && $(window).width() < 960
      $('.display-status').css('display', 'none')
