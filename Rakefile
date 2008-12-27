require 'rubygems'
require 'rake/gempackagetask'

GEM_NAME    = "dm-proc-scenarios"
GEM_VERSION = "0.0.1"
AUTHOR      = "Oleg Andreev, Michael Klishin"
EMAIL       = "oleganza@gmail.com, michael.s.klishin@gmail.com"
SUMMARY     = ""

spec = Gem::Specification.new do |s|
  s.rubyforge_project = 'dm-proc-scenarios'
  s.name              = GEM_NAME
  s.version           = GEM_VERSION
  s.platform          = Gem::Platform::RUBY
  s.has_rdoc          = false
  s.extra_rdoc_files  = ["README", "LICENSE", 'TODO']
  s.summary           = SUMMARY
  s.description       = SUMMARY
  s.author            = AUTHOR
  s.email             = EMAIL
  s.require_path      = 'lib'
  s.files             = %w(LICENSE README Rakefile) + Dir.glob("{lib,spec}/**/*")
  
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end
