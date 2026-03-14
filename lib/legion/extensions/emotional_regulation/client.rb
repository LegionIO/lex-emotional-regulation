# frozen_string_literal: true

require 'legion/extensions/emotional_regulation/helpers/constants'
require 'legion/extensions/emotional_regulation/helpers/regulation_model'
require 'legion/extensions/emotional_regulation/runners/emotional_regulation'

module Legion
  module Extensions
    module EmotionalRegulation
      class Client
        include Runners::EmotionalRegulation

        attr_reader :regulation_model

        def initialize(regulation_model: nil, **)
          @regulation_model = regulation_model || Helpers::RegulationModel.new
        end
      end
    end
  end
end
