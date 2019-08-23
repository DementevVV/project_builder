# encoding: utf-8
#!/usr/bin/env ruby
require 'json'

class AppBuilder
  attr_reader :source_file

  def initialize(args)
    @source_file = args[:source_file]
  end

  def read_json
    file = File.read(@source_file)
    data_hash = JSON.parse(file)
  end

  def new_rails_app(data_hash)
    if data_hash.key?('app_name') && data_hash.key?('app_path')
      system "cd #{data_hash['app_path']} && rails new #{data_hash['app_name']} -d postgresql"
    end
  end

  def db(data_hash)
    system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && rails db:create"
  end

  def skeleton(data_hash)
    if data_hash.key?('controllers')
      data_hash['controllers'].each do |k, v|
        system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && rails g controller #{k} #{v.join(' ')}"
      end
    end

    if data_hash.key?('models')
      data_hash['models'].each do |k, v|
        fields = ""
        v.each do |kk, vv|
          fields << "#{kk}:#{vv} "
        end
        system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && rails g model #{k} #{fields}"
        system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && rails db:migrate"
      end
    end

    if data_hash.key?('scaffolds')
      data_hash['scaffolds'].each do |k, v|
        fields = ""
        v.each do |kk, vv|
          fields << "#{kk}:#{vv} "
        end
        system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && rails g scaffold #{k} #{fields}"
        system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && rails db:migrate"
      end
    end

    system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && rails db:migrate"
  end

  def gems(data_hash)
  end
end

## new app
app = AppBuilder.new(:source_file => '/Users/i/Desktop/example.json')

## parse json
data_hash = app.read_json

## create app
app.new_rails_app(data_hash)

## db
app.db(data_hash)

## app skeleton
app.skeleton(data_hash)




