# -*- encoding: utf-8 -*-
# stub: no-style-please 0.4.7 ruby lib

Gem::Specification.new do |s|
  s.name = "no-style-please".freeze
  s.version = "0.4.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Riccardo Graziosi".freeze]
  s.date = "2021-07-08"
  s.email = ["riccardo.graziosi97@gmail.com".freeze]
  s.homepage = "https://github.com/riggraz/no-style-please".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.3.5".freeze
  s.summary = "A (nearly) no-CSS, fast, minimalist Jekyll theme.".freeze

  s.installed_by_version = "3.3.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<jekyll>.freeze, ["~> 3.9.0"])
    s.add_runtime_dependency(%q<jekyll-feed>.freeze, ["~> 0.15.1"])
    s.add_runtime_dependency(%q<jekyll-seo-tag>.freeze, ["~> 2.7.1"])
  else
    s.add_dependency(%q<jekyll>.freeze, ["~> 3.9.0"])
    s.add_dependency(%q<jekyll-feed>.freeze, ["~> 0.15.1"])
    s.add_dependency(%q<jekyll-seo-tag>.freeze, ["~> 2.7.1"])
  end
end
