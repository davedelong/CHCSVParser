#this is not an official Podspec!!!

Pod::Spec.new do |spec|
    spec.name         = 'CHCSVParser'
    #this is not an official Podspec!!!
    spec.author       = 'Dave DeLong'
    spec.homepage     = 'https://github.com/davedelong/CHCSVParser'
    spec.summary      = 'A proper CSV parser for Objective-C.'
    spec.license      = 'MIT (LICENSE)'
    spec.version      = '1.0.2'
    #original source: https://github.com/davedelong/CHCSVParser
    spec.source       = { :git => 'https://github.com/nicktmro/CHCSVParser.git', :tag => '1.0.2' }
    spec.source_files = 'CHCSVParser/**/*.{h,m}'
end