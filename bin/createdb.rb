#!/usr/bin/env ruby
# This file is part of fluksobot
# (c) 2009 Mathias Dalheimer, md@gonium.net
#
# FluksoBot is free software; you can 
# redistribute it and/or modify it under the terms of the GNU General Public 
# License as published by the Free Software Foundation; either version 2 of 
# the License, or any later version.
#
# FluksoBot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FluksoBot; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

# Read the fluksobot location 
libpath=File.join(File.dirname(__FILE__), '..', 'lib')
confpath=File.join(File.dirname(__FILE__), '..', 'etc')
$:.unshift << libpath << confpath
#puts "Using libraty path #{$:.join(":")}" 

require 'config.rb'     # Our configuration file.
require 'rubygems'
require 'optparse'
require 'ostruct'
require 'database'

###
## Commandline parser
#
class Optparser
  CODES = %w[iso-2022-jp shift_jis euc-jp utf8 binary]
  CODE_ALIASES = { "jis" => "iso-2022-jp", "sjis" => "shift_jis" }
  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.inplace = false
    options.encoding = "utf8"
    options.verbose = false
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.separator ""
      opts.separator "Specific options:"
    # Boolean switch.
    opts.on("-f", "--force", "Ignore warnings") do |f|
      options.force = f 
    end
    opts.on("-v", "--verbose", "Run verbosely") do |v|
      options.verbose = v
    end
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end
  opts.parse!(args)
  options
end
end

###
## Script startup
#
options = Optparser.parse(ARGV)
$verbose = options.verbose
$force = options.force
dbfile=$CONFIG[:DB_FILE]
puts "FluksoBot database setup script."
if $verbose
  puts " Using database #{dbfile}"
end
# check and expand paths.
if File.exists?(dbfile) and not $force
  puts "Database already exists. Aborting."
  exit(-2);
end

# The database does not exist. Create the DB and populate it with 
# tables.
begin
  db=FluksoBotDB.create(dbfile);
  db.close();
  puts "Success."
rescue Exception => e
  puts "Failed to initialize db: #{e}"
end

