#encoding: utf-8
module Wms
  class Account
    include Mongoid::Document
    include ActiveModel::SecurePassword
    before_create { generate_token }

    field :name, type: String
    field :email, type: String
    field :password_digest, type: String
    field :token, type: String
    field :state, type: Integer, default: 1

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

    def has_role?(role)
      case role
      when :admin then admin?
      when :staff then state == STATE[:normal]
      else false
      end
    end

    # 是否是管理员
    def admin?
      Wms::Settings.admin_emails.include?(email)
    end
  end
end