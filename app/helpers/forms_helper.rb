module FormsHelper
  class BS5FormBuilder < ActionView::Helpers::FormBuilder
    def text_field(attribute, options = {})
      validated = self.object.errors.present?
      valid = !self.object.errors[attribute].present?

      control_class = ['form-control']
      if validated
        valid ? control_class.push('is-valid') : control_class.push('is-invalid')
      end

      @template.tag.div(
        super(attribute, { 
          class: control_class.join(' '),
          placeholder: options.fetch(:placeholder, attribute),
          aria: { describedby: described_by(attribute, options) }
        }) + 
        label(attribute, class: 'form-label') +
        (validated && !valid ? error_for(attribute) : hint_for(attribute, options)),
        class: 'form-floating mb-3'
      )
    end

    def check_box(attribute, options = {})
      validated = self.object.errors.present?
      valid = !self.object.errors[attribute].present?

      control_class = ['form-check-input']
      if validated
        valid ? control_class.push('is-valid') : control_class.push('is-invalid')
      end

      @template.tag.div(
        super(attribute, { 
          class: control_class.join(' '),
          aria: { describedby: described_by(attribute, options) }
        }) + 
        label(attribute, class: 'form-check-label') +
        (validated && !valid ? error_for(attribute) : hint_for(attribute, options)),
        class: 'form-check mb-3'
      )
    end

    def submit
      super(class: 'btn btn-secondary')
    end

    def error_for(attribute)
      if self.object.errors[attribute].present?
        @template.tag.div(
          self.object.errors.full_messages_for(attribute).join("; "),
          id: tag_id_for(attribute) + '_error',
          class: 'invalid-feedback'
        )
      else nil
      end
    end

    def hint_for(attribute, options = {})
      if options.has_key?(:hint)
        @template.tag.div(
          options.fetch(:hint), 
          id: tag_id_for(attribute) + '_hint', 
          class: 'form-text'
        )
      else nil
      end
    end

    def described_by(attribute, options)
      if !error_for(attribute).nil?
        tag_id_for(attribute) + '_error'
      elsif !hint_for(attribute, options).nil?
        tag_id_for(attribute) + '_hint'
      else nil
      end
    end

    def tag_id_for(attribute)
      ActionView::Helpers::Tags::TextField.new(object_name, attribute, {}).send(:tag_id)
    end

  end

  def bs5_form_with(model: nil, scope: nil, url: nil, format: nil, **options, &block)
    options.merge! builder: BS5FormBuilder
    form_with model: model, scope: scope, url: url, format: format, **options, &block
  end

end
