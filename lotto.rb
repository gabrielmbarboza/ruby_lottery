#!/usr/bin/env ruby
require 'bundler/setup'
require 'dry/cli'
require 'date'
require 'mechanize'
require 'tty/spinner'

module Lotto
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Version < Dry::CLI::Command
        desc "Print version"

        def call(*)
          puts "0.0.1"
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
            lotto_url = "https://asloterias.com.br/resultados-da-mega-sena-#{year}"
            agent = Mechanize.new
            page = agent.get(lotto_url)
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

      register "version", Version, aliases: ["v", "-v", "--version"]
      register "load", LoadTens
      register "lucky", LuckyNumbers
    end
  end
end

Dry::CLI.new(Lotto::CLI::Commands).call
