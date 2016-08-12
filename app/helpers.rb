helpers do
  def admin?
    request.cookies[settings.admin] == get_token(settings.admin, settings.password)
  end

  def user?
    token = request.cookies['user_token']
    User.count(token: token) > 0
  end

  def for_admin!
    halt [401, 'Not Authorized'] unless admin?
  end

  def for_users!
    halt [401, 'Not Authorized'] unless user? || admin?
  end

  def get_token (name, code)
    Digest::SHA1.hexdigest(name + code)
  end

  def sending_user_info(user)
    subject   = 'Welcome to Support System'
    html_body = message(:email, layout: false, user: user)
    send_email(user.email, subject, html_body)
  end

  def message(template, options={}, locals={})
    render :slim, template, options, locals
  end

  def send_email(mailto, subject, html_body='',  cc='', attach={})
    options = {
      to:          mailto,
      cc:          cc,
      from:        settings.mail_from,
      subject:     subject,
      html_body:   html_body,
      attachments: attach,
      via:         :smtp,
      via_options: settings.via_options }
    thr = Thread.new do
      Pony.mail(options)
    end
  end

  def commas(x)
    str = x.to_s.reverse
    str.gsub!(/([0-9]{3})/, '\\1 ')
    str.gsub(/ $/, '').reverse
  end

  def get_country(currency)
    country = case currency.to_s
                when 'RUR' then 'РФ'
                when 'UAH' then 'УКР'
              end
  end
end
