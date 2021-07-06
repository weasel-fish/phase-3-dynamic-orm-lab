require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true

        sql = "pragma table_info('#{table_name}')"

        info = DB[:conn].execute(sql)
        
        col_names = []
        info.each do |col|
            col_names << col["name"]
        end
        col_names.compact
    end
    
    def initialize(stuff = {})
        stuff.each do |prop, val|
            self.send("#{prop}=", val)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        col_names = []
        self.class.column_names.each do |col|
            col_names << col unless col == "id"
        end
        col_names.join(", ")
    end

    def values_for_insert
        vals = []

        self.class.column_names.each do |col_name|
            vals << "'#{send(col_name)}'" unless col_name == "id"
        end
        vals.join(", ")
    end

    def save
        sql = <<-SQL
            INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})
        SQL
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = <<-SQL
            SELECT * FROM #{table_name} WHERE name = ?
        SQL

        DB[:conn].execute(sql, name)
    end

    def self.find_by(attribute)
        value = attribute.values.first

        sql = "SELECT * FROM #{table_name} WHERE #{attribute.keys.first} = '#{value}'"
        DB[:conn].execute(sql)
    end


end