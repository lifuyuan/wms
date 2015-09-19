#encoding: utf-8
require 'barby'
require 'chunky_png'
require 'barby/barcode/code_128'
require 'barby/outputter/png_outputter'

module Wms
  class Depot
    include Mongoid::Document
    has_many :accounts, class_name: "Wms::Account"
    # 仓库名称
    field :name, type: String
    # 所在国家
    field :country, type: String

    # 货架数量
    field :shelf_num, type: Integer


    def self.gen_barcode(num)
    	barcode = Barby::Code128B.new(num.to_s)
    	barcode.to_png(:xdim => 8)
    end
  end
end
