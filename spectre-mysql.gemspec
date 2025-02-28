Gem::Specification.new do |spec|
  spec.name          = 'spectre-mysql'
  spec.version       = '2.0.0'
  spec.authors       = ['Christian Neubauer']
  spec.email         = ['christian.neubauer@ionos.com']

  spec.summary       = 'MySQL module for spectre'
  spec.description   = 'Adds MySQL access functionality to the spectre framework'
  spec.homepage      = 'https://github.com/ionos-spectre/spectre-mysql'
  spec.license       = 'GPL-3.0-or-later'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ionos-spectre/spectre-mysql'
  spec.metadata['changelog_uri'] = 'https://github.com/ionos-spectre/spectre-mysql/blob/develop/CHANGELOG.md'
  spec.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com/ionos-spectre'

  spec.files        += Dir.glob('lib/**/*')

  spec.require_paths = ['lib']

  spec.add_dependency 'bigdecimal'
  spec.add_dependency 'logger'
  spec.add_dependency 'mysql2'
  spec.add_dependency 'ostruct'
end
