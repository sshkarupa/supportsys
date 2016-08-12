DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite:./db/supportsys.db')

class User
  include DataMapper::Resource

  property :id,       Serial  #primary serial key
  property :name,     String
  property :email,    String, unique: true
  property :currency, Enum['RUR', 'UAH']
  property :account,  Text
  property :password, String
  property :id_cash,  Integer
  property :block,    Boolean, default: false
  property :token,    String

  has n, :payments

  #Public class method than returns a user object if the caller supplies
  #the correct name and password
  def self.authenticate(email, password)
    user = first(email: email)
    user && user&.password == password && !user&.block ? user : false
  end
end

class Payment
  include DataMapper::Resource

  property :id,        Serial  #primary serial key
  property :timecode,  DateTime
  property :account,   String
  property :amount,    Float
  property :filename,  String
  property :sha,       String
  property :create_at, DateTime

  belongs_to :user  #defaults to required: true
end

#finalize them after declaring all of the models
DataMapper.finalize

#wipes out existing data
DataMapper.auto_upgrade!
