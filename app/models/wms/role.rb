module Wms
  class Role
    include Mongoid::Document

    has_many :accounts, class_name: "Wms::Account"

   	field :name, type: String
  end
end
