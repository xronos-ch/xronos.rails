module FormHelper
  class BS5FormBuilder < ActionView::Helpers::FormBuilder
    def text_field(attribute, options = {})
      @template.tag.div(
        super(attribute, { 
          class: 'form-control', 
          placeholder: options.fetch(:placeholder, attribute),
          aria: { describedby: (options.has_key?(:hint) ? tag_id_for(attribute) + '_hint' : nil) },
          required: true
        }) + 
        label(attribute, class: 'form-label') +
        hint(attribute, options),
        class: 'form-floating mb-3'
      )
    end

    def submit
      super(class: 'btn btn-secondary')
    end

    def hint(attribute, options = {})
      if(options.has_key?(:hint)) 
        @template.tag.div(options.fetch(:hint), 
                          id: tag_id_for(attribute) + '_hint', 
                          class: 'form-text')
      else nil
      end
    end

    def tag_id_for(attribute)
      ActionView::Helpers::Tags::TextField.new(object_name, attribute, {}).send(:tag_id)
    end
  end
end
