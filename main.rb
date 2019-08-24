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

  def angular_js_material(data_hash)
    if data_hash.key?('angular_js_material')
      if data_hash['angular_js_material']
        path = "#{data_hash['app_path']}/#{data_hash['app_name']}"
        begin
          puts "Creating folder for angular"
          puts `cd #{path} && mkdir ./app/assets/javascripts/app-0000-angular`
        rescue Exception => e
          puts "Folder exists"
        end
        
        puts "Downloading angular JS files"
        `wget -c https://ajax.googleapis.com/ajax/libs/angularjs/1.7.6/angular.min.js                         -O  #{path}/app/assets/javascripts/app-0000-angular/app-0000-0-angular.js  -q --show-progress`
        `wget -c https://ajax.googleapis.com/ajax/libs/angularjs/1.7.6/angular-animate.min.js                 -O  #{path}/app/assets/javascripts/app-0000-angular/app-0000-1-animate.js  -q --show-progress`
        `wget -c https://ajax.googleapis.com/ajax/libs/angularjs/1.7.6/angular-aria.min.js                    -O  #{path}/app/assets/javascripts/app-0000-angular/app-0000-2-aria.js     -q --show-progress`
        `wget -c https://ajax.googleapis.com/ajax/libs/angularjs/1.7.6/angular-messages.min.js                -O  #{path}/app/assets/javascripts/app-0000-angular/app-0000-3-messages.js -q --show-progress`
        `wget -c https://ajax.googleapis.com/ajax/libs/angular_material/1.1.12/angular-material.min.js        -O  #{path}/app/assets/javascripts/app-0000-angular/app-0000-4-material.js -q --show-progress`
        `wget -c https://cdnjs.cloudflare.com/ajax/libs/angular-file-upload/2.5.0/angular-file-upload.min.js  -O  #{path}/app/assets/javascripts/app-0000-angular/app-0000-6-uploader.js -q --show-progress`

        File.open("#{path}/app/assets/javascripts/app-0000-angular/app-0000-9999-main.js", "w") do |out|
          out.puts "var app = angular.module('#{data_hash['app_name']}', ['ngMaterial','ngMessages', 'angularFileUpload']);"
        end

        puts "Downloading angular CSS files"
        `wget -c https://ajax.googleapis.com/ajax/libs/angular_material/1.1.12/angular-material.min.css -O #{path}/app/assets/stylesheets/angular_material.min.css -q --show-progress`
        File.open("#{path}/app/views/layouts/application.html.erb") do |i|
          File.open("output", 'w') do |o|
            while line = i.gets
              o.puts line
              if line.chomp == "<head>"
                o.puts "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\" />"
              end
            end
          end
        end
        `mv output #{path}/app/views/layouts/application.html.erb`

        content = File.open("#{path}/app/views/layouts/application.html.erb", "r").read
        if !content.include?("ng-app")
          content["<html"] = "<html ng-app='#{data_hash['app_name']}' ng-cloak"
          File.open("#{path}/app/views/layouts/application.html.erb", "w") do |out|
            out.puts content
          end 
        end
      end
    end
  end

  def turbolinks(data_hash)
    if data_hash.key?('turbolinks')
      if data_hash['turbolinks'] == false
        #  REMOVE TURBOLINKS
        `sed -i.bak "s/gem 'turbolinks'/#gem 'turbolinks'/g" #{data_hash['app_path']}/#{data_hash['app_name']}/Gemfile`
        `sed -i.bak 's/reload/false/' #{data_hash['app_path']}/#{data_hash['app_name']}/app/views/layouts/application.html.erb`
        `sed -i.bak 's@//= require turbolinks@@g' #{data_hash['app_path']}/#{data_hash['app_name']}/app/assets/javascripts/application.js`
      end
    end
  end

  def gems(data_hash)
    if data_hash.key?('gems')
      File.open("#{data_hash['app_path']}/#{data_hash['app_name']}/Gemfile", 'a'){ |file| file.puts data_hash['gems'] }
      system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && bundle install"
    end
  end

  def devise(data_hash)
    if data_hash.key?('devise')
      if data_hash['devise']
        system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && rails generate devise:install"
        File.open("#{data_hash['app_path']}/#{data_hash['app_name']}/config/environments/development.rb") do |i|
          File.open("output", 'w') do |o|
            while line = i.gets
              o.puts line
              if line.chomp == "Rails.application.configure do"
                o.puts "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }"
              end
            end
          end
        end
        `mv output #{data_hash['app_path']}/#{data_hash['app_name']}/config/environments/development.rb`
      end
      system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && rails generate devise User && rails db:migrate"
      system "cd #{data_hash['app_path']}/#{data_hash['app_name']} && rails generate devise:views"
    end
  end

  def fa(data_hash)
    if data_hash.key?('devise')
      if data_hash['devise']
        puts "Adding font-awesome"
        system "mkdir #{data_hash['app_path']}/#{data_hash['app_name']}/app/assets/webfonts"
        system "cp font-awesome/* #{data_hash['app_path']}/#{data_hash['app_name']}/app/assets/webfonts/"
        system "mv #{data_hash['app_path']}/#{data_hash['app_name']}/app/assets/webfonts/app-000-fa.css #{data_hash['app_path']}/#{data_hash['app_name']}/app/assets/stylesheets/"
      end
    end
  end
end

## new app
app = AppBuilder.new(:source_file => 'example.json')

## parse json
data_hash = app.read_json

## create app
app.new_rails_app(data_hash)

## db
app.db(data_hash)

## app skeleton
app.skeleton(data_hash)

## add angular js material
app.angular_js_material(data_hash)

## turbolinks
app.turbolinks(data_hash)

## gems
app.gems(data_hash)

## devise install
app.devise(data_hash)

## add fa
app.fa(data_hash)