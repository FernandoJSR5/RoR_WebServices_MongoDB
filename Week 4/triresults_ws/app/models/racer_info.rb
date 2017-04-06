class RacerInfo
  include Mongoid::Document

  field :racer_id, as: :_id
	field :_id, default:->{ racer_id }
  field :fn, as: :first_name, type: String
  field :ln, as: :last_name, type: String
  field :g, as: :gender, type: String
  field :yr, as: :birth_year, type: Integer
  field :res, as: :residence, type: Address

  embedded_in :parent, polymorphic: true 

  validates_presence_of :first_name 
  validates_presence_of :last_name 
  validates_presence_of :gender 
  validates_presence_of :birth_year
  validates_inclusion_of :gender, in: %w( M F ), message: "must be M or F"
  validates :birth_year, :numericality => {:less_than => Date.current.year, :message => "must in past"}

  def city
    self.residence ? self.residence.city : nil
  end
    
  def city= name
    object=self.residence ||= Address.new
    object.city=name
    self.residence=object
  end

  ["city", "state"].each do |action|
      define_method("#{action}") do
      self.residence ? self.residence.send("#{action}") : nil
    end
      define_method("#{action}=") do |name|
      object=self.residence ||= Address.new
      object.send("#{action}=", name)
      self.residence=object
    end
  end

end
