configure do
  set :website, 'http://supportsystem.com'
  set :site_name,'Support System'
  set :files_path, 'public/uploads/'

  set :admin, ENV['ADM_NAME']
  set :password, ENV['ADM_PASSWORD']

  set :mail_to, ENV['MAIL_TO']
  set :copy_to, ENV['COPY_TO']
  set :mail_from, ENV['MAIL_FROM']

  set via_options: {
    address: 'smtp.gmail.com',
    port: '587',
    user_name: ENV['MAIL_USER'] ,
    password: ENV['MAIL_PASSWORD'],
    authentication: :plain,
    domain: 'mail.gmail.com'
    }
end
