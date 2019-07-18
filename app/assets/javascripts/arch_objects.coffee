# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  update_subfields = (object) ->
    this_object = jQuery(object)
    this_value = this_object.val()
    this_next_div = this_object.parent().next(".field")
    if(this_value=="")
      this_next_div.show()
      this_next_div.find("input").each ->
        $(this).prop('disabled', false)
    else
      this_next_div.hide()
      this_next_div.find("input").each ->
        $(this).prop('disabled', true)

  $('.observed_select').change ->
    update_subfields(this)

  $('.observed_select').each ->
    update_subfields(this)
