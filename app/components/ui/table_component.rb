# frozen_string_literal: true

module Ui
  class TableComponent < ViewComponent::Base
    renders_one :header
    renders_many :body_rows

    def initialize(striped: false)
      @striped = striped
    end
  end
end
