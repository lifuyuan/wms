module Wms
	class Account
    include Mongoid::Document
    include ActiveModel::SecurePassword
    before_create { generate_token }

    field :name, type: String
    field :email, type: String
    field :password_digest, type: String
    field :token, type: String

    has_secure_password

    def generate_token
    	self[:token] = SecureRandom.urlsafe_base64
    end
  end
end