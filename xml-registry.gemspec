Gem::Specification.new do |s|
  s.name = 'xml-registry'
  s.version = '0.1.13'
  s.summary = 'xml-registry'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb'] 
  s.signing_key = '../privatekeys/xml-registry.pem'
  s.cert_chain  = ['gem-public_cert.pem']
end
