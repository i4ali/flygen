# scripts/add_to_xcode.rb — add Swift files to the FlyGen target. Idempotent.
# Usage: ruby scripts/add_to_xcode.rb FlyGen/FlyGen/Chat/Foo.swift [more...]
require 'xcodeproj'

project = Xcodeproj::Project.open('FlyGen/FlyGen.xcodeproj')
target = project.targets.find { |t| t.name == 'FlyGen' } or abort 'FlyGen target not found'
group = project.main_group['Chat'] || project.main_group.new_group('Chat', 'FlyGen/FlyGen/Chat')

ARGV.each do |rel|
  abort "missing file: #{rel}" unless File.exist?(rel)
  abs = File.expand_path(rel)
  if project.files.any? { |f| f.real_path.to_s == abs }
    puts "skip (already in project): #{rel}"; next
  end
  ref = group.new_reference(abs)
  target.add_file_references([ref])
  puts "added: #{rel}"
end
project.save
puts 'saved project.'
