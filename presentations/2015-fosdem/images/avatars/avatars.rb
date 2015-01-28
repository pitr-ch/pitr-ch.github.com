require 'rest-client'
require 'multi_json'

data = MultiJson.load(
    RestClient.get(
        'https://api.github.com/repos/ruby-concurrency/concurrent-ruby/contributors'))

avatars = data.map { |u| [u['login'] + '.jpeg', u['avatar_url']] }

# avatars.each do |name, url|
#   File.write name, RestClient.get(url)
# end

puts avatars.size
puts avatars.map { |name, _| ".avatar[![#{name}](images/avatars/#{name})]" }.join("\n")
puts avatars.map { |n, _| n[0..-6]}.join(' ')
