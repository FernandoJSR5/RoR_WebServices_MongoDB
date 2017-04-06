class Contest
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  field :name, type: String
  field :date, type: Date

  belongs_to :venue, foreign_key: :venue_id
  embeds_many :entrants
  has_and_belongs_to_many :judges

end
