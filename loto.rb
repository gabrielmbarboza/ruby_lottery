pool = []
lucky_numbers = Hash.new(0)

File.foreach("loto.txt") do |line|
  pool << Thread.new {
    sleep(0.5)
    l = line.split(" ")

    l.each do |n|
      if !lucky_numbers.has_key?(n)
        lucky_numbers[n] = 0
      end

      lucky_numbers[n] += 1
    end
  }
end

pool.each{ |thr| thr.join }

lucky_numbers.sort_by { |_key, value| value }.each do |key, value|
  print "Number: #{key} Repetition: #{value} \n"
end
