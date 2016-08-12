#Compiling of styles.sass into style.css
get '/style.css' do
  content_type 'text/css', charset: 'utf-8'
  sass :style, style: :compressed, views: './public/sass/'
end

get '/' do
  @method_action = '/user'
  @form_title = 'Support'
  slim :login
end

post '/user' do
  @user = User.authenticate(params[:email], params[:password])
  if @user
      response.set_cookie('user_token', @user.token)
      redirect '/payments/new'
    else
      redirect back, error: "User's email or password incorrect"
    end
end

#create payment
get '/payments/new' do
  for_users!
  token = request.cookies['user_token']
  @user = User.first(token: token)
  slim :payment_create
end

post '/payments/new' do
  token = request.cookies['user_token']
  @user = User.first(token: token)

  tmpfile = params[:file][:tempfile]
  name = params[:file][:filename]
  unless params[:file] && tmpfile && name
    @error = "No file selected"
    slim :payment_create
  end

  account = params[:account].split('@')[0]
  extantion = File.extname(name)
  @payment = Payment.create(user_id: @user.id, timecode: params[:timecode], account: account,
    amount: params[:amount].to_f.round(2), sha: get_token(name, params[:timecode].to_s),
    filename: "", create_at: Time.now )

  @payment.filename = @payment.id.to_s + @payment.sha + extantion
  @payment.save

  upload_file = settings.files_path + @payment.filename
  FileUtils.cp tmpfile.path, upload_file

  send_file = 'check.' + extantion
  country = get_country(@user.currency)
  subject   = "Deposit account #{@payment.account} #{country}: #{@user.id_cash} :
    #{commas(@payment.amount)} #{@user.currency} : #{@payment.timecode.strftime("%d.%m.%Y %H:%M")}"
  html_body = ""
  attach    = { send_file  => File.read(upload_file) }
  send_email(settings.mail_to, subject, '', settings.copy_to, attach)

  slim :send_ok
end

get '/info' do
  for_users!
  slim :info
end

# admin authorization
get '/root' do
  @method_action = '/admin'
  @form_title = 'Admin'
  slim :login
end

before '/admin/*' do
  for_admin!
end

post '/admin' do
  if params[:email] == settings.admin && params[:password] == settings.password
    response.set_cookie(settings.admin, get_token(settings.admin, settings.password))
    redirect '/admin/payments'
  else
    redirect back, error: "Admin's name or password incorrect"
  end
end

# view all users
get '/admin/users' do
  @users = User.all
  slim :users
end

# create new user
get '/admin/users/create' do
  slim :user_create
end

post '/admin/users/create' do
  params[:block] ||= false
  params[:id_cash] = params[:id_cash].gsub(' ', '')
  params.delete 'submit'
  sending = params.delete 'sending'
  @user = User.create(params)
  @user.token = get_token(@user.email, @user.password)
  @user.save
  sending_user_info(@user) if sending
  redirect '/admin/users'
end

# edit user
get '/admin/users/:id/edit' do
  @user = User.get(params[:id])
  slim :user_edit
end

patch '/admin/users/:id/edit' do
  @user = User.get(params[:id])
  %w(submit id splat captures _method).each {|key| params.delete(key)}
  sending = params.delete 'sending'
  params[:block] ||= false
  params[:id_cash] = params[:id_cash].gsub(' ', '').to_i
  @user.attributes = params
  @user.token = get_token(@user.email, @user.password)
  @user.save
  sending_user_info(@user) if sending
  redirect '/admin/users'
end

# block/unblock user
get '/admin/users/:id/block' do
  @user = User.get(params[:id])
  @user.block = !@user.block
  @user.save
  redirect '/admin/users'
end

# delete user
get '/admin/users/:id/delete' do
  @user = User.first(id: params[:id])
  slim :user_delete
end

delete '/admin/users/:id' do
  User.get(params[:id]).destroy
  redirect '/admin/users'
end

# view all payments
get '/admin/payments' do
  @payments = Payment.paginate(page: params[:page], per_page: 10, order: [:create_at.desc])
  @users = User.all
  slim :payments
end

# view the payment
get '/admin/payments/:id/view' do
  @payment = Payment.get(params[:id])
  @user = User.first(id: @payment.user_id)
  slim :payment_view
end

# edit the payment
get '/admin/payments/:id/edit' do
  @payment = Payment.get(params[:id])
  @user = User.first(id: @payment.user_id)
  slim :payment_edit
end

patch '/admin/payments/:id/edit' do
  @payment = Payment.get(params[:id])
  %w(submit id splat captures _method).each {|key| params.delete(key)}
  sending = params.delete 'sending'
  params[:account] = params[:account].split('@')[0]
  @payment.attributes = params
  @payment.save

  if sending
    @user     = User.first(id: @payment.user_id)
    file      = settings.files_path + @payment.filename
    send_file = 'check.' + File.extname(@payment.filename)
    country   = get_country(@user.currency)
    subject   = "Пополнение счета #{@payment.account} #{country} :
      #{@user.id_cash} : #{commas(@payment.amount)} #{@user.currency} :
      #{@payment.timecode.strftime('%d.%m.%Y %H:%M')}"
    attach = { send_file  => File.read(file) }
    send_email(settings.mail_to, subject, '', settings.copy_to, attach)
  end
  redirect '/admin/payments'
end

#delete payment
get '/admin/payments/:id/delete' do
  @payment = Payment.first(id: params[:id])
  @user = User.first(id: @payment.user_id)
  @country = get_country(@user.currency)
  slim :payment_delete
end

delete '/admin/payments/:id' do
  @payment = Payment.first(id: params[:id])
  path_to_file = settings.files_path + @payment.filename
  File.delete(path_to_file) if File.exist?(path_to_file)
  Payment.get(params[:id]).destroy
  redirect '/admin/payments'
end

#logout
get '/logout' do
  response.set_cookie(settings.admin, false)
  response.set_cookie('user_token', false)
  redirect '/'
end

#if page not found
not_found do
  @title = 'Page not found'
  slim :'404'
end

