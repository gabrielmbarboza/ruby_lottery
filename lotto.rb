#!/usr/bin/env ruby
require 'bundler/setup'
require 'dry/cli'
require 'date'
require 'mechanize'
require 'tty/spinner'
require 'yaml'

module Lotto
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Version < Dry::CLI::Command
        desc "Print version"

        def call(*)
          puts "1.0.0"
        end
      end

      class LoadTens < Dry::CLI::Command
        desc "Load tens"
  
        def call(*)
          spinner = TTY::Spinner.new("[:spinner] Loading tens...")
          spinner.auto_spin
          lotto_start_date = 1996
          current_year = DateTime.now.year
          years = (lotto_start_date..current_year).to_a
          file = File.open("lotto.txt", "w")
          file.truncate(0)
          
          years.each do |year|
            loto_url = "https://asloterias.com.br/resultados-da-mega-sena-#{year}"
            agent = Mechanize.new
            page = agent.get(loto_url)
            lotto_numbers = page.search('.dezenas_mega').each_slice(6).to_a
            
            lotto_numbers.each do |tens|
              parsed_tens = tens.map(&:children).join(' ')
              file.puts(parsed_tens)
            end
          end
          
          file.close
          spinner.success("(Tens loaded)")
        end
      end

      class LuckyNumbers < Dry::CLI::Command
        desc "Show lucky numbers"
        
        def call(*)
          pool = []
          lucky_numbers = Hash.new(0)
          mutex = Mutex.new
          File.foreach("lotto.txt") do |line|
            pool << Thread.new {
              mutex.synchronize {
                tens = line.split(" ")

                tens.each do |ten|
                  lucky_numbers[ten] += 1
                end
              }
            }
          end

          pool.each(&:join)

          lucky_numbers.sort_by { |_key, value| value }.to_h.keys.each_slice(6) do |numbers|
            puts numbers.sort { |a, b| a <=> b }.join(" ")
          end
        end
      end

      class RandomTens < Dry::CLI::Command
        desc "Print random tens"

        argument :games, desc: "Number of games you want"

        def call(games: 1, **)
          lucky_numbers = []
          tens_per_game = 6
          equal_random_tolerance = 3
          first_ten = 1
          last_ten = 60

          games.to_i.times do |chance|
            tens = []
  
            tens_per_game.times do
              random_ten = rand(first_ten..last_ten)

              equal_random_tolerance.times do
                break unless tens.include?(random_ten)
                random_ten = rand(first_ten..last_ten)
              end

              tens << random_ten
            end 
  
            lucky_numbers << tens.sort! { |a, b| a <=> b }
          end

          lucky_numbers.each do |tens| 
            puts tens.map!{ |ten| ten.to_s.rjust(2, "0") }.join(" ") 
          end
        end
      end

      register "version", Version, aliases: ["v", "-v", "--version"]
      register "load", LoadTens
      register "lucky", LuckyNumbers
      register "random", RandomTens
    end
  end
end

Dry::CLI.new(Lotto::CLI::Commands).call
