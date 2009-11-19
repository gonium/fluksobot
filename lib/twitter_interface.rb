# This file is part of FluksoBot
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
# along with CGWG; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

require 'twitter'

class TwitterInterface
  def initialize()
    twitter_config=YAML.load_file($CONFIG[:TWITTER_PASSWD_FILE])
    username=twitter_config["username"]
    passwd=twitter_config["password"]
    puts "Using twitter account #{username}" if $verbose
    httpauth = Twitter::HTTPAuth.new(username, passwd)
    puts "HTTPAuth options: #{httpauth.options}" if $verbose
    @client = Twitter::Base.new(httpauth)
  end
  def tweet(msg)
    @client.update(msg);
  end
end
