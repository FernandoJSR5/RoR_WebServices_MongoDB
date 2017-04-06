class Event
  include Mongoid::Document
  field :o, as: :order, type: Integer
  field :n, as: :name, type: String
  field :d, as: :distance, type: Float
  field :u, as: :units, type: String

  embedded_in :parent, polymorphic: true, touch: true

  validates_presence_of :order, :name 

  def meters
  	case
  	when self.units == "miles"
  		then self.distance * 1609.344
  	when self.units == "kilometers"
  		then self.distance * 1000
  	when self.units == "meters"
  		then self.distance * 1
  	when self.units == "yards"
  		then self.distance * 0.9144 
  	else
  		nil
  	end
  end

  def miles
  	case
  	when self.units == "miles"
  		then self.distance * 1
  	when self.units == "kilometers"
  		then self.distance * 0.621371
  	when self.units == "meters"
  		then self.distance * 0.000621371
  	when self.units == "yards"
  		then self.distance * 0.000568182
  	else
  		nil
  	end
  end

end
