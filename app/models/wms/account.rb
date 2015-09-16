#encoding: utf-8
module Wms
  class Account
    include Mongoid::Document
    include ActiveModel::SecurePassword
    before_create { generate_token }
    before_create { assign_default_role }
    before_save :ensure_android_token

    field :name, type: String
    field :email, type: String
    field :password_digest, type: String
    field :token, type: String
    field :android_token, type: String
    field :state, type: Integer, default: 1

    belongs_to :role, class_name: "Wms::Role"
    belongs_to :depot, class_name: "Wms::Depot"

    has_secure_password

    STATE = {
    # 软删除
    deleted: -1,
    # 正常
    normal: 1,
    # 请假
    leave: 2
    }

    def generate_token
      self[:token] = SecureRandom.urlsafe_base64
    end

    def assign_default_role
      self.role ||= Wms::Role.find_by(name: 'staff')
    end

    def has_role?(role)
      self.role.name == role.to_s && state == STATE[:normal]
    end

    #token为空时自动生成新的token
    def ensure_android_token
      if android_token.blank?
        self.android_token = generate_android_token
      end
    end
   
    private
   
    def generate_android_token
      loop do
        token = SecureRandom.urlsafe_base64
        break token unless Wms::Account.where(android_token: token).first
      end
    end

  end
end