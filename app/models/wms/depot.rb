#encoding: utf-8

module Wms
  class Depot
    include Mongoid::Document
    has_many :accounts, class_name: "Wms::Account"
    # 仓库名称
    field :name, type: String
    # 所在国家
    field :country, type: String
  end
end
