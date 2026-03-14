# frozen_string_literal: true

require 'legion/extensions/emotional_regulation/version'
require 'legion/extensions/emotional_regulation/helpers/constants'
require 'legion/extensions/emotional_regulation/helpers/regulation_model'
require 'legion/extensions/emotional_regulation/runners/emotional_regulation'

module Legion
  module Extensions
    module EmotionalRegulation
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
