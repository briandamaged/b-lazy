
Gem::Specification.new do |s|
  s.name                  = 'b-lazy'
  s.version               = '0.1.2'
  s.date                  = '2011-02-04'
  s.summary               = "Why work hard for lazy-evaluation?"
  s.description           = "Extends core Ruby objects to provide inherent support for lazy-evaluation."
  s.authors               = ["Brian Lauber"]
  s.email                 = 'constructible.truth@gmail.com'
  s.homepage              = 'http://b-lazy.rubyforge.org'
  s.files                 = Dir['{specs/*,lib/*}'] + ['README','b-lazy.gemspec']
  s.required_ruby_version = '>= 1.9.1'
  s.rubyforge_project     = 'b-lazy'
end

