# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "tsjobcrawler"
  spec.version       = '0.1.1'
  spec.authors       = ["M. C. McGrath"]
  spec.email         = ["shidash@shidash.com"]

  spec.summary       = %q{Crawls job listing websites for jobs requiring security clearance.}
  spec.description   = %q{Crawls job listing websites for jobs requiring security clearance.}
  spec.homepage      = "https://github.com/TransparencyToolkit/TSJobCrawler"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "nokogiri"
  spec.add_runtime_dependency "requestmanager"
  spec.add_runtime_dependency "harvesterreporter"
  spec.add_runtime_dependency "pry"
  spec.add_runtime_dependency "headless"
end
