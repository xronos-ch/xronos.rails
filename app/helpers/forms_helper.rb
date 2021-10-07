module FormsHelper
  class BS5FormBuilder < ActionView::Helpers::FormBuilder

    # BOOTSTRAPPED STANDARD FIELDS
    
    def text_field(attribute, options = {})
      control_class = ['form-control']
      if is_validated
        is_valid(attribute) ? control_class.push('is-valid') : control_class.push('is-invalid')
      end

      @template.tag.div(
        super(attribute, { 
          class: control_class.join(' '),
          placeholder: options.fetch(:placeholder, attribute),
          aria: { describedby: described_by(attribute, options) }
        }) + 
        label(attribute, class: 'form-label') +
        (is_validated && !is_valid(attribute) ? error_for(attribute) : hint_for(attribute, options)),
        class: 'form-floating mb-3'
      )
    end

    def number_field(attribute, options = {})
      control_class = ['form-control']
      if is_validated
        is_valid(attribute) ? control_class.push('is-valid') : control_class.push('is-invalid')
      end

      @template.tag.div(
        super(attribute, { 
          class: control_class.join(' '),
          placeholder: options.fetch(:placeholder, attribute),
          aria: { describedby: described_by(attribute, options) }
        }) + 
        label(attribute, class: 'form-label') +
        (is_validated && !is_valid(attribute) ? error_for(attribute) : hint_for(attribute, options)),
        class: 'form-floating mb-3'
      )
    end

    def check_box(attribute, options = {})
      control_class = ['form-check-input']
      if is_validated
        is_valid(attribute) ? control_class.push('is-valid') : control_class.push('is-invalid')
      end

      @template.tag.div(
        super(attribute, { 
          class: control_class.join(' '),
          aria: { describedby: described_by(attribute, options) }
        }) + 
        label(attribute, class: 'form-check-label') +
        (is_validated && !is_valid(attribute) ? error_for(attribute) : hint_for(attribute, options)),
        class: 'form-check mb-3'
      )
    end

    def submit
      super(class: 'btn btn-secondary')
    end

    # CUSTOM FIELDS

    # Year with era select box, e.g. for start/end times
    def year_field(attribute, options = {})
      number_field(attribute, options)
    end

    # HELPERS
    
    def is_validated
      self.object.errors.present?
    end

    def is_valid(attribute)
      !self.object.errors[attribute].present?
    end
    
    def error_for(attribute)
      if !is_valid(attribute)
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
