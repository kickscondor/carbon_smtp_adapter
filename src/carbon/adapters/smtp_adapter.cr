class Carbon::SmtpAdapter < Carbon::Adapter
  Habitat.create do
    setting host : String = "localhost"
    setting port : Int32 = 25
    setting helo_domain : String? = nil
    setting use_tls : EMail::Client::TLSMode =
      EMail::Client::TLSMode::STARTTLS
    setting username : String? = nil
    setting password : String? = nil
  end

  def deliver_now(email : Carbon::Email)
    auth = get_auth_tuple
    config = ::EMail::Client::Config.new(settings.host, settings.port,
      helo_domain: settings.helo_domain)
    config.use_tls(settings.use_tls)
    config.use_auth(auth[0], auth[1]) if auth
    client = ::EMail::Client.new(config)

    new_email = ::EMail::Message.new
    new_email.from email.from.address, email.from.name

    email.to.each do |to_address|
      new_email.to(to_address.address, to_address.name)
    end
    email.cc.each do |cc_address|
      new_email.cc(cc_address.address, cc_address.name)
    end
    email.bcc.each do |bcc_address|
      new_email.bcc(bcc_address.address, bcc_address.name)
    end
    email.headers.each do |key, value|
      new_email.custom_header(key, value)
    end
    new_email.subject email.subject
    new_email.message email.text_body.to_s
    new_email.message_html email.html_body.to_s

    client.start do
      send(new_email)
    end
  end

  private def get_auth_tuple : Tuple(String, String)?
    username = settings.username
    password = settings.password

    if username && password.nil?
      raise "You need to provide a password when setting a username"
    end
    if password && username.nil?
      raise "You need to set a username when providing a password"
    end

    if username && password
      {username, password}
    end
  end
end
