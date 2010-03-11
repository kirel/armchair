require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'armchair'

describe Armchair do
  
  before(:each) do
    @dburl = 'http://localhost:5984/test_armchair/'
    @couch = Armchair.new @dburl
    @doc = {'some' => 'doc'}
  end
  
  after(:each) do
    begin
      RestClient.delete(@dburl)
    rescue RestClient::ResourceNotFound
    end
  end
  
  it "should create the database" do
    @couch.create!
    lambda { RestClient.get(@dburl) }.should_not raise_error(RestClient::ResourceNotFound)
  end
  
  it "should insert documents" do
    # just checking if CouchDB API is correctly used
    RestClient.should_receive(:post).with(@dburl, JSON(@doc), :content_type => :json, :accept => :json)
    @couch << @doc
  end
  
  describe "with some documents in it" do
    
    before(:each) do
      @num = 42
      @couch.create!
      @docs = (1..@num).map { |i| { 'number' => i } }
      @docs.each { |doc| @couch << doc }
    end
    
    it "should know the numbers" do
      @couch.size.should == @num
    end
        
    it "should iterate over each document" do
      docs = @docs.dup
      @couch.each do |doc|
        docs.delete(docs.detect { |d| d['number'] == doc['number']})
      end
      docs.should be_empty
    end
    
  end
  
end