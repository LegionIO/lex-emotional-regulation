# frozen_string_literal: true

require_relative 'lib/legion/extensions/emotional_regulation/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-emotional-regulation'
  spec.version       = Legion::Extensions::EmotionalRegulation::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Emotional Regulation'
  spec.description   = "Gross's Process Model of Emotion Regulation for brain-modeled agentic AI — " \
                       'five strategies for modulating emotional responses'
  spec.homepage      = 'https://github.com/LegionIO/lex-emotional-regulation'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-emotional-regulation'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-emotional-regulation'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-emotional-regulation'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-emotional-regulation/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-emotional-regulation.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
end
