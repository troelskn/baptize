package :essentials do
  description "Installs various system level packages"

  before do
    @libraries = %w(git-core build-essential libmysqlclient-dev mailutils ntp libsasl2-dev)
  end

  install do
    apt @libraries
  end

  verify do
    has_apt @libraries
  end
end
