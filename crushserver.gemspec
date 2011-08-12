# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{crushserver}
  s.version = "0.3.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["PJ Kelly", "Mason Browne"]
  s.date = %q{2011-08-12}
  s.description = %q{A collection of capistrano tasks frequently used at Crush + Lovely.}
  s.email = %q{pj@crushlovely.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README"
  ]
  s.files = [
    "LICENSE",
    "README",
    "Rakefile",
    "VERSION",
    "VERSION.yml",
    "crushserver.gemspec",
    "lib/crushserver/recipes.rb"
  ]
  s.homepage = %q{http://github.com/crushlovely/crushserver}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{A collection of capistrano tasks frequently used at Crush + Lovely.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<tinder>, [">= 1.4.0"])
    else
      s.add_dependency(%q<tinder>, [">= 1.4.0"])
    end
  else
    s.add_dependency(%q<tinder>, [">= 1.4.0"])
  end
end

