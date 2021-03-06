module BootstrapForms
  class FormBuilder < ActionView::Helpers::FormBuilder
    delegate :content_tag, :hidden_field_tag, :check_box_tag, :radio_button_tag, :button_tag, :link_to, :to => :@template

    def error_messages
      if object.errors.full_messages.any?
        content_tag(:div, :class => 'alert alert-block alert-error validation-errors') do
          content_tag(:h4, I18n.t('bootstrap_forms.errors.header', :model => object.class.model_name.human), :class => 'alert-heading') +
          content_tag(:ul) do
            object.errors.full_messages.map do |message|
              content_tag(:li, message)
            end.join('').html_safe
          end
        end
      else
        '' # return empty string
      end
    end

    %w(collection_select select email_field file_field number_field password_field phone_field radio_button range_field search_field telephone_field text_area text_field url_field).each do |method_name|
      define_method(method_name) do |name, *args|
        @name = name
        @field_options = args.extract_options!
        @args = args

        control_group_div do
          label_field + input_div do
            extras { super(name, *(@args << @field_options)) }
          end
        end
      end
    end

    def check_box(name, *args)
      @name = name
      @field_options = args.extract_options!
      @args = args

      control_group_div do
        input_div do
          label(@name, :class => [ 'checkbox', required_class ].compact.join(' ')) do
            extras { super(name, *(@args << @field_options)) + human_attribute_name }
          end
        end
      end
    end

    def radio_buttons(name, values={}, opts={})
      @name = name
      @options = opts

      control_group_div do
        label_field + input_div do
          values.map do |text, value|
            label("#{@name}_#{value}", :class => [ 'radio', required_class ].compact.join(' ')) do
              extras { radio_button(name, value, @options) + text }
            end
          end.join.html_safe
        end
      end
    end

    def collection_check_boxes(attribute, records, record_id, record_name, *args)
      @name = attribute
      @field_options = args.extract_options!
      @args = args

      control_group_div do
        label_field + extras do
          content_tag(:div, :class => 'controls') do
            records.collect do |record|
              element_id = "#{object_name}_#{attribute}_#{record.send(record_id)}"
              checkbox = check_box_tag("#{object_name}[#{attribute}][]", record.send(record_id), [object.send(attribute)].flatten.include?(record.send(record_id)), @field_options.merge({:id => element_id}))

              content_tag(:label, :class => ['checkbox', ('inline' if @field_options[:inline])].compact.join(' ')) do
                checkbox + content_tag(:span, record.send(record_name))
              end
            end.join('').html_safe
          end
        end
      end
    end

    def collection_radio_buttons(attribute, records, record_id, record_name, *args)
      @name = attribute
      @field_options = args.extract_options!
      @args = args

      control_group_div do
        label_field + extras do
          content_tag(:div, :class => 'controls') do
            records.collect do |record|
              element_id = "#{object_name}_#{attribute}_#{record.send(record_id)}"
              radiobutton = radio_button_tag("#{object_name}[#{attribute}][]", record.send(record_id), object.send(attribute) == record.send(record_id), @field_options.merge({:id => element_id}))

              content_tag(:label, :class => ['radio', ('inline' if @field_options[:inline])].compact.join(' ')) do
                radiobutton + content_tag(:span, record.send(record_name))
              end
            end.join('').html_safe
          end
        end
      end
    end

    def uneditable_input(name, *args)
      @name = name
      @field_options = args.extract_options!
      @args = args

      control_group_div do
        label_field + input_div do
          extras do
            content_tag(:span, :class => 'uneditable-input') do
              @field_options[:value] || object.send(@name.to_sym)
            end
          end
        end
      end
    end

    def submit(name = nil, *args)
      @name = name
      @field_options = args.extract_options!
      @args = args

      @field_options[:class] = 'btn btn-primary'

      content_tag(:div, :class => 'form-actions') do
        if @field_options[:include_cancel] == false
          super(name, *(args << @field_options))
        else
          super(name, *(args << @field_options)) + ' ' + link_to(I18n.t('bootstrap_forms.buttons.cancel'), (@field_options[:back] || :back), :class => 'btn cancel')
        end
      end
    end

    private
    def control_group_div(&block)
      @field_options[:error] = error_string

      klasses = ['control-group']
      klasses << 'error' if @field_options[:error]
      klasses << 'success' if @field_options[:success]
      klasses << 'warning' if @field_options[:warning]
      klass = klasses.join(' ')

      content_tag(:div, :class => klass, &block)
    end

    def error_string
      errors = object.errors[@name]
      if errors.present?
        errors.map { |e|
          "#{@options[:label] || human_attribute_name} #{e}"
        }.join(", ")
      end
    end

    def human_attribute_name
      object.class.human_attribute_name(@name)
    end

    def input_div(&block)
      content_tag(:div, :class => 'controls') do
        if @field_options[:append] || @field_options[:prepend]
          klass = 'input-prepend' if @field_options[:prepend]
          klass = 'input-append' if @field_options[:append]
          content_tag(:div, :class => klass, &block)
        else
          yield if block_given?
        end
      end
    end

    def label_field(&block)
      label(@name, block_given? ? block : @field_options[:label], :class => ['control-label', required_class].compact.join(' '))
    end

    def required_class
      return 'required' if object.class.validators_on(@name).any? { |v| v.kind_of? ActiveModel::Validations::PresenceValidator }
      nil
    end

    %w(help_inline error success warning help_block append prepend).each do |method_name|
      define_method(method_name) do |*args|
        return '' unless value = @field_options[method_name.to_sym]
        case method_name
        when 'help_block'
          element = :p
          klass = 'help-block'
        when 'append', 'prepend'
          element = :span
          klass = 'add-on'
        else
          element = :span
          klass = 'help-inline'
        end
        content_tag(element, value, :class => klass)
      end
    end

    def extras(&block)
      [prepend, (yield if block_given?), append, help_inline, error, success, warning, help_block].join('').html_safe
    end

    def objectify_options(options)
      super.except(:label, :help_inline, :error, :success, :warning, :help_block, :prepend, :append)
    end
  end
end
