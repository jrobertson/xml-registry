Gem::Specification.new do |s|
  s.name = 'xml-registry'
  s.version = '0.6.0'
  s.summary = 'The XML registry can be used to store or retrieve ' + 
      'app settings etc. in an XML document.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/xml-registry.rb'] 
  s.add_runtime_dependency('simple-config', '~> 0.6', '>=0.6.4')
  s.signing_key = '../privatekeys/xml-registry.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/xml-registry'
  s.required_ruby_version = '>= 2.1.0'
end
