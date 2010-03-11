require 'rest_client'
require 'json'

# An Armchair is <em>very</em> a minimal interface to a CouchDB database. It is Enumarable.
class Armchair
  include Enumerable
  
  # Pass in the database url and optionally
  # a <tt>batch_size</tt> which is used when iterating over the armchair in Armchair#each
  #  couch = Armchair.new 'http://127.0.0.1:5984/mycouch'
  #
  def initialize dburl, batch_size = 100
    @dburl = dburl.gsub(/\/$/,'')
    @batch_size = batch_size
  end
  
  # Create the CouchDB database at <tt>dburl</tt> (see Armchair#new) if it does not exist yet
  def create!
    RestClient.get @dburl, :accept => :json do |response|
      case response.code
      when 404
        RestClient.put @dburl, nil, :content_type => :json, :accept => :json
      else
        response.return!
      end
    end
  end
  
  # Shift a document into the Armchair. <tt>doc</tt> should be a Hash.
  #  armchair << { 'a' => 'document' } << { 'another' => 'document' }
  def << doc
    RestClient.post @dburl, JSON(doc), :content_type => :json, :accept => :json do |response|
      response.return! unless response.code == 201
    end
    self
  end
  
  # Returns the size of the Armchair (the number of documents stored).
  def size
    RestClient.get(@dburl + '/_all_docs?limit=0', :accept => :json) do |r|
      case r.code
      when 200
        JSON(r.body)['total_rows']
      else
        r.return!
      end
    end
  end

  # yields each document
  def each
    # iterate in batches of @batch_size
    # initial query
    res = RestClient.get(@dburl + "/_all_docs?limit=#{@batch_size+1}&include_docs=true", :accept => :json) do |r|
      case r.code
      when 200
        JSON(r.body)
      else
        r.return!
      end
    end
    rows = res['rows']
    last = rows.size > @batch_size ? rows.pop : nil
    rows.each { |row| doc = row['doc']; yield doc }
    # subsequent queries
    while last
      startkey = last['key']
      res = RestClient.get(@dburl + "/_all_docs?startkey=%22#{startkey}%22&limit=#{@batch_size+1}&include_docs=true", :accept => :json) do |r|
        case r.code
        when 200
          JSON(r.body)
        else
          r.return!
        end
      end
      rows = res['rows']
      last = rows.size > @batch_size ? rows.pop : nil
      rows.each { |row| yield row['doc'] }
    end
  end
end