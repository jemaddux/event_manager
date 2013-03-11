####
#Event Manager
#by John Maddux
#Completed 2/3/13
####

require 'chronic'
require "csv"
require "sunlight"
require 'erb'
require 'rainbow'

Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0,5]
end

def legislators_for_zipcode(zipcode)
  legislators = Sunlight::Legislator.all_in_zipcode(zipcode)
end

def make_letter(name,zipcode,phone_number)
  form_letter ||= File.read "form_letter.erb.html"
  legislators = legislators_for_zipcode(zipcode)
  legislators.each do |x|
    x.phone = formated_phone_number(x.phone)
  end
  template = ERB.new form_letter
  results = template.result(binding)
end

def save_letter(name,id,zipcode,phone_number) 
  Dir.mkdir("output") unless Dir.exists? "output"
  filename = "output/thanks_#{id}.html"
  File.open(filename,'w') do |file|
    file.puts make_letter(name,zipcode,phone_number)
  end
  puts "Made letter for #{name}."
end

def number_to_array(number)
  number_array = []
  number.length.times do |y|
    number_array.push(number[y])
  end
  return number_array
end

def stripped_phone_numbers(number)
  number_array = number_to_array(number)
  new_number_array = []
  number_array.each do |x|
    new_number_array.push(x) unless (x == "-" or x == "(" or x == ")" or x == " " or x == ".")
  end
  new_number_array.join("")
end

def clean_short_phone_number(number)
  number = stripped_phone_numbers(number)
  case number.length
    when 10 then return number
    when 11 then 
      if number[0] == "1" 
        return (number_to_array(number))[1,10].join("")
      else
        return "0000000000" #Then a bad number and equals "0000000000"
      end
    else return "0000000000"
  end
end

def formated_phone_number(number)
  number = clean_short_phone_number(number)
  return "(#{number[0,3]}) #{number[3,3]}-#{number[6,9]}"
end

def event_manager
  puts "EventManager initialized."
  contents = get_csv_contents
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    phone_number = formated_phone_number(row[:homephone])
    save_letter(name,id,zipcode,phone_number)
  end
end

def get_csv_contents
  CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
end

def time_targeting
  puts ""
  puts "Sign ups per hour:"
  contents = get_csv_contents
  hours_count = Hash.new
  (0..23).each do |num|
    hours_count[num] = 0
  end
  contents.each do |row|
    name = row[:first_name]
    reg_date = Chronic.parse(row[:regdate])
    hours_count[reg_date.hour] += 1
  end
  hours_count = hours_count.sort_by {|hour, count| count}.reverse
  hours_count.each do |hour|
    if hour[1] > 0
      puts "#{hour[1]} people signed up at #{hour[0]} o'clock."
    end
  end
end

def day_targeting
  puts ""
  puts "Sign ups per day of the week:"
  contents = get_csv_contents
  days_of_the_week = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
  days_count = Hash.new
  days_of_the_week.each do |day|
    days_count[day] = 0
  end
  contents.each do |row|
    name = row[:first_name]
    reg_date = Chronic.parse(row[:regdate]).wday
    days_count[days_of_the_week[reg_date]] += 1
  end
  days_count = days_count.sort_by {|day, count| count}.reverse
  days_count.each do |day|
    puts "#{day[1]} people signed up on #{day[0]}."
  end
end


def run_program
  puts "Would you like to run the (E)vent Manager do (T)ime targeting or do (D)ay of the week targeting?"
  what_to_do = gets.chomp.downcase
  case what_to_do
  when "e" then event_manager
  when "t" then time_targeting
  when "d" then day_targeting
  else 
    puts "Please enter the letter 'E', 'T' or 'D'.".color(:red)
    run_program
  end
end

run_program