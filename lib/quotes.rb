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
#


class QuoteDB
  def initialize()
    quotePath=$CONFIG[:QUOTES_FILE]
    @quotes=YAML.load_file(quotePath)
  end
  def randomQuote(quotes)
    return quotes[rand(quotes.size)];
  end
  def getLowQuote
    return randomQuote(@quotes["low_quotes"]);
  end
  def getMediumQuote
    return randomQuote(@quotes["medium_quotes"]);
  end
  def getHighQuote
    return randomQuote(@quotes["high_quotes"]);
  end
  def to_s
    retval="low quotes: #{@quotes["low_quotes"]}"
    retval+="medium quotes: #{@quotes["medium_quotes"]}"
    retval+="high quotes: #{@quotes["high_quotes"]}"
  end
end

class NoQuoteException < RuntimeError
end
