# -*- encoding : utf-8 -*-
# Class to manage Hangout information
class Hangout < Cinch::Plugins::Hangouts
  attr_accessor :nick, :id, :time, :hangout_filename

  def initialize(nick, id, time)
    @nick = nick
    @id = id
    @time = time
  end

  def save
    storage = Cinch::Storage.new(@@hangout_filename)
    storage.data[:hangouts] ||= {}
    storage.data[:hangouts][id] = self
    storage.save
  end

  def self.find_by_id(id)
    listing[id]
  end

  def self.delete_expired(expire_time)
    return if listing.nil?
    storage = read_file
    storage.data[:hangouts].delete_if do |id, hangout|
      (Time.now - hangout.time) > (expire_time * 60)
    end
    storage.save
  end

  def self.sorted
    hangouts = listing.values
    hangouts.sort! { |x, y| y.time <=> x.time }
    hangouts
  end

  def self.listing
    read_file.data[:hangouts]
  end

  def self.url(id, shorten = true)
    url = "https://plus.google.com/hangouts/_/#{id}"
    return url unless shorten
    Cinch::Toolbox.shorten(url)
  end

  private

  def self.read_file
    storage = Cinch::Storage.new(@@hangout_filename)
    unless storage.data[:hangouts]
      storage.data[:hangouts] = {}
      storage.save
    end
    storage
  end
end
