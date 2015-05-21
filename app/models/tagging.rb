class Tagging < ActiveRecord::Base
  self.inheritance_column = :_disabled

  TYPES_TO_WEIGHTS = {
    buildable: 3,
    archive: -1, # exclude from search
  }

  before_save :set_weight

  def set_weight
    self[:weight] = TYPES_TO_WEIGHTS.fetch(type.to_sym)
  end

  def self.types
    TYPES_TO_WEIGHTS.keys
  end

  def self.rank_adjustment_for(tags)
    tags = tags.map { |t| t.to_sym }
    TYPES_TO_WEIGHTS.values_at(*tags).inject(0, :+)
  end
end
