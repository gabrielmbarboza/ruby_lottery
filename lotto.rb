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

        option :tens, default:"6", values: %w[6, 7, 8, 9], desc: "Number of tens you want"
        
        def call(**options)
          pool = []
          lucky_numbers = Hash.new(0)
          mutex = Mutex.new
          tens_per_game = options.fetch(:tens).to_i

          File.foreach("lotto.txt") do |line|
            pool << Thread.new {
              mutex.synchronize {
                tens_line = line.split(" ")

                tens_line.each do |ten|
                  lucky_numbers[ten] += 1
                end
              }
            }
          end

          pool.each(&:join)

          lucky_numbers.sort_by { |_key, value| value }.to_h.keys.each_slice(tens_per_game) do |numbers|
            puts numbers.sort { |a, b| a <=> b }.join(" ") if numbers.length == tens_per_game 
          end
        end
      end

      class RandomTens < Dry::CLI::Command
        desc "Print random tens"

        option :games, default:"1", desc: "Number of games you want"
        option :tens, default:"6", values: %w[6, 7, 8, 9], desc: "Number of tens you want"

        def call(**options)
          lucky_numbers = []
          equal_random_tolerance = 3
          games = options.fetch(:games).to_i
          tens_per_game = options.fetch(:tens).to_i
          first_ten = 1
          last_ten = 60

          games.times do |chance|
            tens_list = []
  
            tens_per_game.times do
              random_ten = rand(first_ten..last_ten)

              equal_random_tolerance.times do
                break unless tens_list.include?(random_ten)
                random_ten = rand(first_ten..last_ten)
              end

              tens_list << random_ten
            end 
  
            lucky_numbers << tens_list.sort! { |a, b| a <=> b }
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
