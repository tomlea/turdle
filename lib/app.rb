# frozen_string_literal: true

require 'sinatra'
require 'openssl'
require 'json'

set :root, File.expand_path('..', __dir__)

get '/' do
  game = Game.create
  redirect "/g/#{game.to_blob}"
end

get '/g/:game' do
  @game = Game.load(params[:game])
  erb :index
end

get '/w/:word' do
  game = Game.new(params[:word])
  redirect "/g/#{game.to_blob}"
  erb :index
end

post '/g/:game' do
  @game = Game.load(params[:game])
  guess = params[:guess].downcase
  @game.guess(guess).to_json
end

SUPER_SECRET_KEY = Digest::SHA256.hexdigest('I suppose I first decided to be a panda when I was 12')[0, 32]

class String
  def encrypt
    cipher = OpenSSL::Cipher.new('AES-256-CBC').encrypt
    cipher.key = SUPER_SECRET_KEY
    s = cipher.update(self) + cipher.final

    s.unpack('H*')[0].upcase
  end

  def decrypt
    cipher = OpenSSL::Cipher.new('AES-256-CBC').decrypt
    cipher.key = SUPER_SECRET_KEY
    s = [self].pack('H*').unpack('C*').pack('c*')

    cipher.update(s) + cipher.final
  end
end

class Game
  def initialize(word)
    @word = word
  end

  def self.create
    new(good_words.sample)
  end

  def to_blob
    @word.encrypt
  end

  def guess(word)
    unless Game.words.include? word
      return { error: "#{word} is not in the word list", word: word }
    end
    return { win: true, word: word, results: ['y', 'y', 'y', 'y', 'y', 'y'] } if word == @word

    results =
      word.split('').each_with_index.map do |l, index|
        if @word[index] == l
          'y'
        elsif @word.include? l
          'm'
        else
          'n'
        end
      end
    { results: results, word: word }
  end

  def self.load(blob)
    new(blob.decrypt)
  end

  def self.good_words
    File.read(File.expand_path('good-words.txt', __dir__)).split("\n")
  end

  def self.words
    File.read(File.expand_path('../public/wordlist.txt', __dir__)).split("\n")
  end
end
