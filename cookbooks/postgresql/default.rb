package "postgresql"

define :postgresql_database do
	database = params[:name]
	username = params[:name]

  execute "psql -d template1 -c 'CREATE USER #{database} CREATEDB;'" do
    user "postgres"
    not_if "psql -t --csv -c '\\du #{username}' | grep -E '^#{username},'"
  end

  execute "psql -d template1 -c 'CREATE DATABASE #{database} OWNER #{database};'" do
    user "postgres"
    not_if "psql --csv -c 'SELECT datname FROM pg_database;' | grep -E '^#{database}$'"
  end
end
