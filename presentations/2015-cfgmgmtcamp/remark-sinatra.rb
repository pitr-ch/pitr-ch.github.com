require 'sinatra'

get '/' do
  File.read(File.join(self.class.public_folder, 'index.html'))
end
