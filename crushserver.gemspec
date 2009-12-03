# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{crushserver}
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["PJ Kelly", "Mason Browne"]
  s.date = %q{2009-12-03}
  s.description = %q{A collection of capistrano tasks frequently used at Crush + Lovely.}
  s.email = %q{pj@crushlovely.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README"
  ]
  s.files = [
    "LICENSE",
    "Rakefile",
    "VERSION.yml",
    "lib/crushserver/recipes.rb"
  ]
  s.homepage = %q{http://github.com/crushlovely/crushserver}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A collection of capistrano tasks frequently used at Crush + Lovely.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
