# -*- encoding : utf-8 -*-
# Class to manage Hangout information
class Hangout < Cinch::Plugins::Hangouts
  attr_accessor :nick, :id, :time, :hangout_filename

  def initialize(nick, id, time, files)
    @nick = nick
    @id = id
    @time = time
    fail if files.nil? || !files.key?(:hangouts) || files[:hangouts].empty?
    @filename = files[:hangouts]
  end

  def save
    storage = Cinch::Storage.new(@filename)
    storage.data[:hangouts] ||= {}
    storage.data[:hangouts][id] = self
    storage.save
  end

  def self.find_by_id(id, files)
    listing(files)[id]
  end

  def self.delete_expired(expire_time, files)
    return if listing(files).nil?
    storage = read_file(files)
    storage.data[:hangouts].delete_if do |id, hangout|
      (Time.now - hangout.time) > (expire_time * 60)
    end
    storage.save
  end

  def self.sorted(files)
    hangouts = listing(files).values
    hangouts.sort! { |x, y| y.time <=> x.time }
    hangouts
  end

  def self.listing(files)
    read_file(files).data[:hangouts]
  end

  def self.url(id)
    "https://plus.google.com/hangouts/_/#{id}"
  end

  private

  def self.read_file(files)
    fail "No Hangout filename passed" unless files.key?(:hangouts)
    storage = Cinch::Storage.new(files[:hangouts])
    unless storage.data[:hangouts]
      storage.data[:hangouts] = {}
      storage.save
    end
    storage
  end
end
