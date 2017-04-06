class Photo
  include ActiveModel::Model
	
  attr_accessor :id, :location
	attr_writer :contents 

	# convenience method for access to client in console
  def self.mongo_client
   Mongoid::Clients.default
  end

  def initialize params=nil
    if !params.nil?
      @id=params[:_id].to_s
      @location= Point.new params[:metadata][:location]
      @place= params[:metadata][:place]
    end
  end

  def persisted?
    !@id.nil?
  end

  def save
    if persisted?
      self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id))
                             .update_one(:$set => {"metadata.location" => @location.to_hash,
                              "metadata.place" => @place})
    else
      gps = EXIFR::JPEG.new(@contents).gps
      @location = Point.new(:lng => gps.longitude, :lat => gps.latitude)
      description = {}
      description[:content_type]="image/jpeg"
      if @location
        description[:metadata] = {}
        description[:metadata][:location]=@location.to_hash if !@location.nil?
        description[:metadata][:place]=@place
      end
      
      @contents.rewind
      grid_file = Mongo::Grid::File.new(@contents.read, description)
      id=self.class.mongo_client.database.fs.insert_one(grid_file)
      @id=id.to_s
    end
  end

  #def self.all offset = 0, limit = 0
  # files=[]
  #  mongo_client.database.fs.find.skip(offset).limit(limit).each do |r| 
  #    files << Photo.new(r)
  #  end
  #  return files
  #end

  def self.all offset=0, limit = 0
    mongo_client.database.fs.find.skip(offset).limit(limit).map { |e| Photo.new e }
  end

  def self.find id
    f=mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(id)).first
    return f.nil? ? nil : Photo.new(f)
  end

  def contents
    f = self.class.mongo_client.database.fs.find_one(:_id => BSON::ObjectId.from_string(@id))
    if f 
      buffer = ""
      f.chunks.reduce([]) do |x,chunk| 
          buffer << chunk.data.data 
      end
      return buffer
    end 
  end

  def destroy 
    self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id)).delete_one
  end

  def find_nearest_place_id max_meters
    res =Place.near(@location, max_meters).limit(1).projection(:_id => 1).first
    res.nil? ? nil : res[:_id]
  end

  def place
    @place.nil? ? nil : Place.find(@place.to_s)
  end

  def place= input
    if input.is_a? Place
      @place=BSON::ObjectId.from_string(input.id)
    elsif input.is_a? String
      @place=BSON::ObjectId.from_string(input)
    else
      @place=input
    end
  end

  def self.find_photos_for_place place_id
    place_id = BSON::ObjectId.from_string(place_id) if place_id.is_a? String 
    mongo_client.database.fs.find('metadata.place' => place_id) 
  end

end