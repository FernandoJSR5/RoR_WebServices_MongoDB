class Address
  attr_accessor :city, :state, :location

  def initialize (city=nil, state=nil, point=nil)
    @city = city
    @state = state
    @location = point
  end

  #creates a DB-form of the instance
  def mongoize
    {:city=>@city, :state=>@state, :loc=>Point.mongoize(@location)}
  end
  
  #creates an instance of the class from the DB-form of the data
  def self.demongoize(object)
    case object
    when Hash then
    Address.new(object[:city], object[:state], Point.demongoize(object[:loc]))
    when Address then object
    else nil  
    end
  end

  #takes in all forms of the object and produces a DB-friendly form
  def self.mongoize(object) 
    case object
    when Address then object.mongoize
    when Hash then 
      Address.new(object[:city], object[:state], object[:loc]).mongoize
    else nil
    end
  end
  
  #used by criteria to convert object to DB-friendly form
  def self.evolve(object)
    case object
    when Address then object.mongoize
    when Hash then object
    else nil
    end
  end
end
