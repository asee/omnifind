Gem::Specification.new do |s|
  s.name        = 'omnifind'
  s.version     = '0.5.0'
  s.date        = '2013-07-29'
  s.summary     = "A wrapper for making requests to an Omnifind server and parsing the response"
  s.description = "A wrapper for making requests to an Omnifind server and parsing the response"
  s.authors     = ["James Prior"]
  s.email       = 'j.prior@asee.org'
  s.files       = ["lib/omnifind.rb"]
  s.homepage    = 'https://github.com/asee/omnifind'
  
  s.add_dependency 'nokogiri'
  s.add_dependency 'will_paginate'
end