#!/usr/bin/env ruby
#
# lognotify.rb
# http://github.com/omp/lognotify
# Retrieve new lines from remote log files over SSH.
#
# Copyright 2010 David Vazgenovich Shakaryan <dvshakaryan@gmail.com>
# Distributed under the terms of the GNU General Public License v3.
# See http://www.gnu.org/licenses/gpl.txt for the full license text.
#
# To use, create a configuration file, such as identifier.conf, in the
# configuration directory, which defaults to ~/.config/lognotify/. The
# following settings are required:
#
#   hostname = ...  Hostname of SSH server.
#   path     = ...  Path of log file on server.
#
# The following setting is optional:
#
#   options  = ...  Command-line options for SSH command.
#
# Afterwards, simply run the script with the identifier as an arugment:
#
#   lognotify.rb identifier
#
# During the initial run, a cache file will be created and the entire log file
# will be retrieved. On any subsequent runs, only new lines will be retrieved
# and appended to the cached log.
#
# Although, besides for the addition of new lines, log files should never be
# altered, the remote log and the cached log are checked to be identical on
# every run, by comparing MD5 hashes. If either file has erroneously been
# altered, an error will be produced and the script will exit.

require 'digest/md5'
require 'ftools'
require 'open3'

# Global settings.
CACHE_DIR="~/.cache/lognotify"
CONF_DIR="~/.config/lognotify"

# Methods for quickly getting file paths.
class String
  def to_cache_path
    return File.expand_path(CACHE_DIR + '/' + self + '.log')
  end

  def to_conf_path
    return File.expand_path(CONF_DIR + '/' + self + '.conf')
  end
end

# Configuration file parser.
def parse identifier
  conf = Hash.new

  File.open(identifier.to_conf_path) do |file|
    file.each_line do |line|
      # Remove whitespace from beginning of line, allowing for indentation.
      line.lstrip!

      # Ignore empty lines and comments.
      unless line.empty? or line[0,1] == '#'
        key, value = line.split('=', 2)

        # Raise an error if line does not contain a key/value pair.
        raise 'Error reading line ' + file.lineno.to_s + '.' if value.nil?

        conf[key.strip.to_sym] = value.strip
      end
    end
  end

  return conf
end

# Count lines in cached log.
def count_lines identifier
  File.open(identifier.to_cache_path) do |file|
    return file.readlines.length
  end
end

# Retrieve new lines via SSH.
def retrieve_lines conf, lines
  command = "md5sum #{conf[:path]} | awk '{ print \\$1 }'"
  command << " && cat #{conf[:path]}"
  command << " | sed '1,#{lines}d'" unless lines.zero?
  command = "ssh #{conf[:options]} #{conf[:hostname]} \"#{command}\""

  Open3.popen3(command) do |stdin, stdout, stderr|
    # Raise an error if any part of the command resulted in an error.
    raise stderr.read unless stderr.eof?

    return stdout.read.split("\n", 2)
  end
end

# Verify that remote log and cached log are identical.
def verify_hash identifier, hash, lines
  File.open(identifier.to_cache_path) do |file|
    raise "Hash check failed; delete cached log file." unless
      hash == Digest::MD5.hexdigest(file.read + lines)
  end
end

# Append new lines to cached log.
def append_lines identifier, lines
  File.open(identifier.to_cache_path, 'a') do |file|
    file.print lines
  end
end

# Output all messages immediately, as opposed to buffering.
STDOUT.sync = true

# Create cache directory, if nonexistent.
path = File.expand_path(CACHE_DIR)
File.makedirs(path) unless File.directory?(path)

# Treat each argument as a log identifier.
ARGV.each do |identifier|
  conf = parse(identifier)

  # Create cache file, if nonexistent.
  path = identifier.to_cache_path
  File.open(path, 'w').close unless File.exist?(path)

  print '* Counting lines in cached log... '
  lines = count_lines(identifier)
  puts lines

  print '* Retrieving new lines via SSH... '
  hash, newlines = retrieve_lines(conf, lines)
  puts 'Done'

  puts '* Number of new lines: ' + newlines.lines.count.to_s

  # No need to inform the user about this.
  verify_hash(identifier, hash, newlines)

  unless newlines.lines.count.zero?
    print '* Appending new lines to cached log... '
    append_lines(identifier, newlines)
    puts 'Done'

    puts newlines
  end
end
