package "postgresql"

define :postgresql_database do
	database = params[:name]
	username = params[:name]

  execute "Create PostgreSQL user" do
    command "psql -d template1 -c 'CREATE USER #{database} CREATEDB;'"
    user "postgres"
    not_if "psql -t --csv -c '\\du #{username}' | grep -E '^#{username},'"
  end

  execute "Create PostgreSQL database" do
    command "psql -d template1 -c 'CREATE DATABASE #{database} OWNER #{database};'"
    user "postgres"
    not_if "psql --csv -c 'SELECT datname FROM pg_database;' | grep -E '^#{database}$'"
  end
end
