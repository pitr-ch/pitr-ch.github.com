require 'rest-client'
require 'multi_json'
require 'pp'

data    = [
    *MultiJson.load(
        RestClient.get(
            'https://api.github.com/repos/ruby-concurrency/concurrent-ruby/contributors')),
    *MultiJson.load(
        RestClient.get(
            'https://api.github.com/repos/ruby-concurrency/atomic/contributors')),
    *MultiJson.load(
        RestClient.get(
            'https://api.github.com/repos/ruby-concurrency/thread_safe/contributors'))]

# pp data

avatars = data.reduce({}) do |h, u|
  avatar       = u['login'] + '.jpeg'
  h[avatar]    ||= [avatar, u['avatar_url'], 0]
  h[avatar][2] += u['contributions']
  h
end.values.sort_by { |u| u[2] }.reverse

pp avatars

# avatars.each do |name, url|
#   File.write name, RestClient.get(url)
# end

puts avatars.size
puts avatars.each_with_index.map { |(name, *_), i|
       ".avatar[![#{name}](images/avatars/#{name})]#{i%8 == 7 ? '<br/>' : ''}"
     }.join("\n")
puts avatars.map { |n, _| n[0..-6] }.join(' ')
