# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "crushserver/version"

Gem::Specification.new do |s|
  s.name        = "crushserver"
  s.version     = Crushserver::VERSION
  s.authors     = ["PJ Kelly", "Mason Browne"]
  s.email       = ["pj@crushlovely.com"]
  s.homepage    = "http://crushlovely.com"
  s.summary     = %q{A collection of capistrano tasks frequently used at Crush + Lovely.}
  s.description = %q{A collection of capistrano tasks frequently used at Crush + Lovely.}

  s.rubyforge_project = "crushserver"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "hipchat"
end
