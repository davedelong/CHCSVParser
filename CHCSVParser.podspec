#this is not an official Podspec!!!

Pod::Spec.new do |spec|
    spec.name         = 'CHCSVParser'
    #this is not an official Podspec!!!
    spec.author       = 'Dave DeLong'
    spec.homepage     = 'https://github.com/davedelong/CHCSVParser'
    spec.summary      = 'A proper CSV parser for Objective-C.'
    spec.license      = 'MIT (LICENSE)'
    spec.version      = '2.0.0'
    #original source: https://github.com/davedelong/CHCSVParser
    spec.source       = { :git => 'https://github.com/davedelong/CHCSVParser', :tag => '2.0.0' }
    spec.source_files = 'CHCSVParser/CHCSVParser/CHCSVParser.{h,m}'
end