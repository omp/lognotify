#!/usr/bin/env ruby
#
# lognotify.rb
# http://github.com/omp/lognotify
#
# Copyright 2010 David Vazgenovich Shakaryan <dvshakaryan@gmail.com>
# Distributed under the terms of the GNU General Public License v3.
# See http://www.gnu.org/licenses/gpl.txt for the full license text.

CACHE_DIR="~/.cache/lognotify"
CONFIG_DIR="~/.config/lognotify"

# Configuration file parser.
def parse identifier
  conf = Hash.new
  file = File.expand_path(CONFIG_DIR + '/' + identifier + '.conf')

  File.open(file) do |contents|
    contents.each_line do |line|
      # Remove whitespace from beginning of line, allowing for indentation.
      line.lstrip!

      # Ignore empty lines and comments.
      unless line.empty? or line[0,1] == '#'
        key, value = line.split('=', 2)

        # Raise an error if line does not contain a key/value pair.
        raise 'Error reading line ' + contents.lineno.to_s + '.' if value.nil?

        conf[key.strip.to_sym] = value.strip
      end
    end
  end

  return conf
end

# Count lines in cached log.
def count_lines identifier
  file = File.expand_path(CACHE_DIR + '/' + identifier + '.log')
  return File.open(file).readlines.length
end

# Retrieve new lines via SSH.
def retrieve_lines path, lines, hostname
  command = "cat #{path}"
  command << " | sed '1,#{lines}d'" if lines > 0

  return %x[ssh #{hostname} "#{command}"]
end

# Output all messages immediately, as opposed to buffering.
STDOUT.sync = true

# Treat each argument as a log identifier.
ARGV.each do |identifier|
  conf = parse(identifier)

  print '* Counting lines in cached log... '
  lines = count_lines(identifier)
  puts lines

  print '* Retrieving new lines via SSH... '
  newlines = retrieve_lines(conf[:log_path], lines, conf[:ssh_hostname])
  puts 'Done'

  puts '* Number of new lines: ' + newlines.lines.count.to_s
  puts
  puts newlines
end
