(in /Users/tmorgan/Documents/Scribd/rscribd)
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rscribd}
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jared Friedman, Tim Morgan"]
  s.date = %q{2009-3-4}
  s.description = %q{This gem provides a simple and powerful library for the Scribd API, allowing you to write Ruby applications or Ruby on Rails websites that upload, convert, display, search, and control documents in many formats. For more information on the Scribd platform, visit http://www.scribd.com/publisher}
  s.email = %q{api@scribd.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt", "sample/test.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "lib/scribdapi.rb", "lib/scribddoc.rb", "lib/scribderrors.rb", "lib/scribdmultiparthack.rb", "lib/scribdresource.rb", "lib/rscribd.rb", "lib/scribduser.rb", "sample/01_upload.rb", "sample/02_user.rb", "sample/test.txt"]
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rscribd}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby client library for the Scribd API}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mime-types>, ["> 0.0.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.2"])
    else
      s.add_dependency(%q<mime-types>, ["> 0.0.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.2"])
    end
  else
    s.add_dependency(%q<mime-types>, ["> 0.0.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.2"])
  end
end
