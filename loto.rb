pool = []
lucky_numbers = Hash.new(0)

File.foreach("loto.txt") do |line|
  pool << Thread.new {
    sleep(0.5)
    l = line.split(" ")

    l.each do |n|
      lucky_numbers[n] += 1
    end
  }
end

pool.each{ |thr| thr.join }

lucky_numbers.sort_by { |_key, value| value }.each do |key, value|
  print "Number: #{key} Repetitions: #{value} \n"
end
