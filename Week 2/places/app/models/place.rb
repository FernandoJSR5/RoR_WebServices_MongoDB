class Place
  include ActiveModel::Model

  def persisted?
    !@id.nil?
  end

  attr_accessor :id, :formatted_address, :location, :address_components

  def initialize params = nil
    if !params.nil?
      @id = params[:_id].to_s
      @formatted_address = params[:formatted_address]
      @location = Point.new params[:geometry][:geolocation]
      if !params[:address_components].nil?
        @address_components = params[:address_components].map { |e| AddressComponent.new e }
      end
    end
  end

	# convenience method for access to client in console
  def self.mongo_client
   Mongoid::Clients.default
  end

  # convenience method for access to places collection
  def self.collection
   self.mongo_client['places']
  end


  # helper method that will load a file and return a parsed JSON document as a hash
  def self.load_all(file_path) 
    file=File.read(file_path)
    collection.insert_many(JSON.parse(file))
  end

  def self.find_by_short_name param
    collection.find({ "address_components.short_name": param })
  end

  def self.to_places parameter
    parameter.map { |e| Place.new e }
  end

  def self.find id
    f =collection.find(_id: BSON::ObjectId.from_string(id)).first
    return f.nil? ? nil : Place.new(f)
  end

  def self.all (offset = 0, limit = 0)
    collection.find().skip(offset).limit(limit).map { |e| Place.new e } 
  end

  # remove the document associated with this instance form the DB
  def destroy
    self.class.collection.find(:_id => BSON::ObjectId.from_string(@id)).delete_one  
  end

  def self.get_address_components(sort = nil, offset = nil, limit= nil)
    ag_functions = [
      {:$unwind => '$address_components'},
      {:$project => 
        {:_id => 1, :address_components => 1, :formatted_address => 1, "geometry.geolocation" => 1}
      }
    ]

    ag_functions << {:$sort => sort} if !sort.nil?
    ag_functions << {:$skip => offset} if !offset.nil?
    ag_functions << {:$limit => limit} if !limit.nil?

    collection.find.aggregate(ag_functions)
  end

  def self.get_country_names
    collection.find.aggregate(
      [  
        {:$project => { :_id => 0, "address_components.long_name" => 1, 
                            "address_components.types" => 1} },
        {:$unwind => '$address_components'},
        {:$match => {"address_components.types" => "country"}},
        {:$group => {:_id => '$address_components.long_name' }} 
      ]
    ).to_a.map { |h| h[:_id]  }

  end

  def self.find_ids_by_country_code country_code
    collection.find.aggregate(
      [
        {:$match => {"address_components.short_name" => country_code}},
        {:$project => {:_id => 1}}
      ]
    ).map {|doc| doc[:_id].to_s}
  end

  def self.create_indexes
    collection.indexes.create_one({"geometry.geolocation" => Mongo::Index::GEO2DSPHERE})
  end

  def self.remove_indexes
    collection.indexes.drop_one("geometry.geolocation_2dsphere")
  end

  def self.near (point , max_meters = 0)
    collection.find(
      "geometry.geolocation" => {:$near => 
        {:$geometry => point.to_hash, :$maxDistance=> max_meters}}
    )
  end

  def near max_meters = 0
    self.class.to_places(self.class.near(@location, max_meters))
  end

  def photos offset = 0, limit = 0
    files = []
    Photo.find_photos_for_place(@id).skip(offset).limit(limit).each do |photo|
      files << Photo.new(photo)
    end
    return files
  end

end