class Racer
	include ActiveModel::Model

	attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

	# initialize from both a Mongo and Web hash
  def initialize(params={})
    #switch between both internal and external views of id and population
    @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @gender=params[:gender]
    @group=params[:group]
    @secs=params[:secs].to_i
  end

  # tell Rails whether this instance is persisted
  def persisted?
    !@id.nil?
  end
  def created_at
    nil
  end
  def updated_at
    nil
  end
	
	# convenience method for access to client in console
  def self.mongo_client
   Mongoid::Clients.default
  end

  # convenience method for access to racers collection
  def self.collection
   self.mongo_client['racers']
  end

  def self.all(prototype={}, sort={:number=>1}, offset=0, limit=nil)

  	#map internal :number term to :number document term
    tmp = {} #hash needs to stay in stable order provided
    sort.each {|k,v| 
      k = k.to_sym==:number ? :number : k.to_sym
      tmp[k] = v  if [:first_name, :last_name, :secs, :group, :number].include?(k)
    }
    sort=tmp

    #convert to keys and then eliminate any properties not of interest
    prototype=prototype.symbolize_keys.slice(:first_name, :last_name, :secs, :gender, 
    																				:group) if !prototype.nil?

    Rails.logger.debug {"getting all racers, prototype=#{prototype}, sort=#{sort}, offset=#{offset}, limit=#{limit}"}

    result=collection.find(prototype)
          .projection({_id:true, number:true, first_name:true, last_name:true, secs:true, gender:true,
          							group:true})
          .sort(sort)
          .skip(offset)
    result=result.limit(limit) if !limit.nil?

    return result
  end


  def self.paginate(params)
    Rails.logger.debug("paginate(#{params})")
    page=(params[:page] || 1).to_i
    limit=(params[:per_page] || 30).to_i
    skip=(page-1)*limit
    sort={number:1}

    #get the associated page of Racers -- eagerly convert doc to Racer
    racers=[]
    all(params, sort, skip, limit).each do |doc|
      racers << Racer.new(doc)
    end

    #get a count of all documents in the collection
    total=collection.find().count
    
    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end    
  end

  # locate a specific document. Use initialize(hash) on the result to 
  # get in class instance form
  def self.find id
    Rails.logger.debug {"getting racers #{id}"}

    result=collection.find(:_id=> BSON::ObjectId(id))
                  .projection({id:true, number:true, first_name:true, last_name:true, secs:true, gender:true,
          							group:true})
                  .first
    return result.nil? ? nil : Racer.new(result)
  end

  # create a new document using the current instance
  def save 
    Rails.logger.debug {"saving #{self}"}

    result=self.class.collection
              .insert_one(_id:@id, number:@number, first_name:@first_name, last_name:@last_name,
              	gender:@gender, group:@group, secs:@secs)
    @id=result.inserted_id.to_s
  end

  # update the values for this instance
  def update(params)
    @number=params[:number].to_i
		@first_name=params[:first_name]
		@last_name=params[:last_name]
		@secs=params[:secs].to_i
		@gender=params[:gender]
		@group=params[:group]

		params.slice!(:number, :first_name, :last_name, :gender, :group, :secs)

    self.class.collection
              .find(_id:BSON::ObjectId.from_string(@id))
              .replace_one(:$set => {:number => @number, :first_name => @first_name, 
              	:last_name => @last_name, :gender => @gender, :group => @group, :secs => @secs})
  end 

  # remove the document associated with this instance form the DB
  def destroy
    Rails.logger.debug {"destroying #{self}"}

    self.class.collection
              .find(number:@number)
              .delete_one   
  end  

end