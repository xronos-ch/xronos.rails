(function() {
  jQuery(function() {

    var update_subfields;

    update_subfields = function(object) {
      var this_next_div, this_object, this_value, this_edit_link;
      this_object = jQuery(object);
      this_value = this_object.val();
      this_next_div = this_object.parent().next(".field_master");
      this_edit_link = this_object.next(".observed_select_edit_link");

      if (this_value === "") {
        this_next_div.show();
        this_edit_link.hide()
        return this_next_div.find("input").each(function() {
          return $(this).prop('disabled', false);
        });
      } else {
        this_next_div.hide();
        this_edit_link.show()
        return this_next_div.find("input").each(function() {
          return $(this).prop('disabled', true);
        });
      }

    };

    $('.observed_select').change(function() {
      return update_subfields(this);
    });
    return $('.observed_select').each(function() {
      return update_subfields(this);
    });

  });

}).call(this);
