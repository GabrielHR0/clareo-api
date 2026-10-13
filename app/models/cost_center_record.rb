class CostCenterRecord < ApplicationRecord
  self.table_name = "cost_centers"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :cost_center_records

  validates :code, presence: true, uniqueness: { scope: :institution_id }
  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
