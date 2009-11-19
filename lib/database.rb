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

require 'sqlite3'
require 'reading'

DB_READINGS_NAME="powerreadings"
DB_SCHEMA=<<-SQL
    create table #{DB_READINGS_NAME} (
      EPOCHTIME integer primary key,
      TIME TEXT not null,
      WATTS integer not null,
      INTERVAL float not null
    );
SQL


class FluksoBotDB
  # create a new database
  def self.create(filename)
    filename=String.new(File.expand_path(filename));
    if File.exists?(filename)
      raise "Database file #{filename} already exists."
    end
    puts "Creating new database file #{filename}" if $verbose
    db = SQLite3::Database.open(filename)
    db.execute_batch(DB_SCHEMA)
    return FluksoBotDB.new(db);
  end
  # open an existing database
  def self.open(filename)
    filename=File.expand_path(filename);
    if not File.exists?(filename)
      raise "Database file #{filename} does not exist."
    end
    db = SQLite3::Database.open( filename)
    return FluksoBotDB.new(db);
  end
  # constuctor: give SQLite::Database object as argument. see class
  # methods.
  def initialize(db)
    @db=db;
    @db.results_as_hash = true
  end
  def close
    @db.close;
  end
  def storeReading(reading)
    # TODO: Make this more efficient, recycle insert statements.
    if reading.class != FluksoReading
      raise "Must give a FluksoReading instance."
    end
    stmt=<<-SQL
      INSERT INTO #{DB_READINGS_NAME}
      VALUES ('#{reading.epochtime}', '#{reading.time}', '#{reading.watts}', '#{reading.interval}');
    SQL
    @db.execute(stmt)
  end
  def find_reading_last_five
    return find_last_reading(5);
  end
  def find_last_reading(amount)
    if not amount.class==Fixnum
      raise "Must provide the number of last readings desired as an Fixnum."
    end
    stmt=<<-SQL
      SELECT * FROM #{DB_READINGS_NAME}
      order by epochtime DESC limit #{amount};
    SQL
    readings=Array.new
    @db.execute(stmt) {|row|
      watts=row['WATTS'].to_f;
      timestamp=Time.at(row['EPOCHTIME'].to_f);
      interval=row['INTERVAL'].to_f;
      reading=FluksoReading.new(watts, timestamp, interval);
      readings << reading
    }
    if readings.empty?
      raise ElementNotFoundError
    end
    return readings;
  end
  def find_reading_by_epochtime(time)
   stmt=<<-SQL
      SELECT * FROM #{DB_READINGS_NAME}
      WHERE epochtime ='#{time}';
    SQL
    readings=Array.new
    @db.execute(stmt) {|row|
      reading=FluksoReading.new(row['VALUE'].to_i, row['TIMESTAMP'].to_i)
      readings << reading
    }
    if readings.empty?
      raise ElementNotFoundError
    end
    return readings[0];
  end
end

class ElementNotFoundError < RuntimeError
end
