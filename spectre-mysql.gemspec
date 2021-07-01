Gem::Specification.new do |spec|
  spec.name          = 'spectre-mysql'
  spec.version       = '1.0.0'
  spec.authors       = ['Christian Neubauer']
  spec.email         = ['me@christianneubauer.de']

  spec.summary       = 'MySQL module for spectre'
  spec.description   = 'Adds MySQL access functionality to the spectre framework'
  spec.homepage      = 'https://github.com/cneubauer/spectre-mysql'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/cneubauer/spectre-mysql'
  spec.metadata['changelog_uri'] = 'https://github.com/cneubauer/spectre-mysql/blob/develop/CHANGELOG.md'

  spec.files        += Dir.glob('lib/**/*')

  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'mysql2', '>= 0.5.3'
  spec.add_runtime_dependency 'spectre-core', '>= 1.8.4'
end
