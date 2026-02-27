# frozen_string_literal: true

module Ui
  class SelectComponent < ViewComponent::Base
    def initialize(name:, options:, label: nil, selected: nil, include_blank: nil, required: false, disabled: false, error: nil, **extra_attrs)
      @name = name
      @options_list = options
      @label = label
      @selected = selected
      @include_blank = include_blank
      @required = required
      @disabled = disabled
      @error = error
      @extra_attrs = extra_attrs
    end
  end
end
