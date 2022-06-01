# AppCount

## Set up Dev environment

#### Installing Language/Framework Tools
1. Follow instructions at http://elixir-lang.org/install.html to install elixir
   and erlang -- appropriate versions are listed in `.tool-versions`. Using ASDF
   is probably easiest for this.
1. install hex: `mix local.hex`
1. Install nodejs and NPM (again, appropriate versions are in `.tool-versions`)
1. install Golang to compile the crypto server: https://golang.org/dl/ -- or you
   can use ASDF. Proper version is in `.tool-versions`
1. You'll need [`wkhtmltopdf`](https://wkhtmltopdf.org/) installed. You can use
   Homebrew (`$ brew install wkhmltopdf`), Aptana (`$ apt-get install
   wkhtmltopdf`), or other package managers.
1. You'll also need Ghostscript (`$ apt-get install ghostscript` or use your
   favorite package manager)

If you're using a Mac (with Catalina, Big Sur, or later) and run into Erlang
install issues, [this
article](https://dev.to/andresdotsh/how-to-install-erlang-on-macos-with-asdf-3p1c)
might be of use to you.

This application assumes a postgres server (NOTE: Version 12 or later) on
`postgres://localhost:5432`, and uses your system user (run ` echo $USER`). It
assumes that this user will have no password. You can change these settings in
`config/dev.exs`.

To override the assumed values above, you can define your own environment variables.
In `~/.bash_profile` for example:
```
  ## AppRent Project
  export APPRENT_DB_USERNAME=postgres
  export APPRENT_DB_PASSWORD=postgres
```
You'll need the following files as well:

1. `config/dev.secret.exs`
1. `config/gcp.secret.json`

You'll also need to ensure that the proper CA Cert has been created. Given the
existing cert file in `priv/keys/wildcard` (which will be
`\*.appcount.appr.cer`), you can double-click the cert to install it (Mac) or
you can follow these steps (Linux) to install:

1. `$ sudo openssl x509 -inform DER -in your-cert-file.cer -out appcount.appr.crt`
1. `$ sudo mv appcount.appr.crt /usr/share/ca-certificates`
1. `$ sudo dpkg-reconfigure ca-certificates` (use Spacebar to activate this
   option)
1. `$ sudo update-ca-certificates`

Finally, you'll need to ensure that you've got your hosts and resolvers set
correctly:

In `/etc/hosts`, add this line:

```
127.0.0.1 appcount.appr application.appcount.appr residents.appcount.appr
```

Create this file: `/etc/resolver/appr`, with the following contents:

```
nameserver 127.0.0.1
port 21334

```

(note the blank line)

#### Installing App

1. clone repo
1. cd into app root
1. `cd crypto`
1. `go build crypto.go`
1. `./crypto gen`
1. ``HASHED_PRIVATE=`cat priv.key` ./compile.sh``
1. copy the contents of `crypto/pub.key` into `config/pub.key` - this key is
   used by the crypto server to encrypt data
1. Go back to app folder `cd ..`
1. Install Dependencies: `mix deps.get` - this will install application
  dependencies (defined in `mix.exs` and enumerated more specifically in
  `mix.lock`)
1. Install NPM dependencies `cd assets && npm install`
1. Go back to app folder `cd ..`
1. Compile email templates: `mix compile_mjml`
1. Create directory for the DB dump and make it writeable/readable: `sudo mkdir /tmp/appcount-db && sudo chmod -R 606 /tmp/appcount-db`
1. Set up the database by cloning from production: `pg_restore -d app_count_dev
   -U your-user-name-here -h localhost -W -Fc /tmp/appcount-db/db.dump` or
   `mix db_pull`

Next you'll need to set up your seed data:

```sh
  mix run priv/repo/seeds.exs
```

This will create a super admin tied to all properties.

Super Admin login: `admin@example.com` + `password`

#### Running the server

- `mix phx.server`

#### Pulling Production DB backup

- `iex -S mix`
- `AppCount.Utils.db_dump()`
- exit IEX
- from command prompt: `mix ecto.drop && mix ecto.create && pg_restore -d app_count_dev -U [username] -Fc /tmp/appcount-db/db.dump`

##### Docker running Postgres
 `mix ecto.drop && mix ecto.create`
 `docker ps` # and get the image-name of your PG image like: 4e3735544ba4
 `docker cp  /tmp/appcount-db/db.dump  [container-id]:/tmp/db.dump`
 Now log into Docker console with the **container-name**  not the image-name, this time
 `docker exec -it [container-id] /bin/bash`
 `=> root@4e3735544ba4:/#`
 `pg_restore -d app_count_dev -U [username] -Fc /tmp/db.dump  -h localhost -p 5432`

 most common username is: `postgres` so this would be the command:
 `pg_restore -d app_count_dev -U postgres -Fc /tmp/db.dump  -h localhost -p 5432`


#### Property Credentials

After pulling the production DB all encrypted data will be inaccessible in
development. This is not a bug, it's a feature.  Production and development use
different public/private keys. So in order to set up property credentials in dev
after pulling production:

- add the following to dev.secret.exs:

```elixir
config :app_count, :processors, %{
  cc: [List of test credentials for Credit Card processor],
  ba: [List of test credentials for ACH processor],
  screening: [List of test credentials for Tenant Screening processor],
  lease: [List of test credentials for Lease system(ex. BlueMoon) processor]
}
```
- run `mix test_credentials`

That's it!

#### Production DB shortcut

If you have set up the `dev.secret.exs` file as outlined above, you can use the
shortcut `mix db_pull` task to execute everything at once

Propay test account # 32451351o

#### Seeing Sent Mail

You can see sent mail at
[http://administration.appcount.test:4002/sent_emails](http://administration.appcount.test:4002/sent_emails)

#### Ecto Migrations

We are using [https://hexdocs.pm/triplex/readme.html](triplex) for tenant migrations and ecto migrations for common/public/master schema. If you want to make some changes to tenant tables, you need to use the following command:

```
mix triplex.gen.migration your_migration_name
```

This will generate a migraion file inside the /priv/repo/tenant_migrations folder. These migrations are to be used for non public schema. So if you want to update the tables for all the clients.

To create a migration for the public schema, such as the clients table or users table run the following command:

```
mix ecto.gen.migration your_migration_name
```

This will generate a migration file inside /priv/repo/migrations folder.

If you would like to see what percentage of the Repo calls have `client_schema` included in their argument, you can run the script located in `bin/count_client_schema_percentage`

#####  the citext extension
If you see an error message like this:
```
** (Postgrex.QueryError) type `citext` can not be handled by the types module Postgrex.DefaultTypes
    (ecto_sql 3.4.5) lib/ecto/adapters/sql.ex:593: Ecto.Adapters.SQL.raise_sql_call_error/1
    (ecto_sql 3.4.5) lib/ecto/adapters/sql.ex:526: Ecto.Adapters.SQL.execute/5
```

You may want to create a temporary migration (and not check it in!) like this:
```
 mix ecto.gen.migration temp
 ```

and fill it in like this"
```
defmodule AppCount.Repo.Migrations.Temp do
  use Ecto.Migration

  def change do
    execute "ALTER EXTENSION citext SET SCHEMA public;"
  end
end
```

And run the migrtation like this:
```
MIX_ENV=dev  mix triplex.migrate
MIX_ENV=test  mix triplex.migrate
```

#### Test Payments

In Development or Test mode, we can run sample credit card payments. Use the
following card credentials:

+ **Number**: `5424000000000015`
+ **CVV**: `999`
+ **Expiration**: Any time in the future
+ **Name**: Any name

[Here are more functioning sample
cards](https://developer.authorize.net/hello_world/testing_guide.html). By
modifying the zip code or CVV, you can force different responses from
Authorize.net's sandbox.

You'll sometimes need to override the sandbox logic and instead go straight to
working with processors directly. In that case, you can set all CC processors in
the system to use sandbox credentials like so:

```ex
from(p in AppCount.Properties.Processor, where: p.name == "Authorize")
|> Repo.update_all(set: [keys: ["8m4k6TZ4Qn", "29765pH6SVp2eYEt", "Simon"]])
```

#### Testing Configuration Tips

##### Testing without ghostscript
In module `AppCount.Data.PDFCase`  with `@moduletag :pdfs` there are two tests
that rely on a system utility called `gs` ...  I think this is "ghost script"

if you do not have `gs` installed the tests will fail and look something like this:

```
1) test find_pdfs (AppCount.Accounting.ChecksCase)
     test/app_count/accounting/checks_test.exs:49
     ** (ErlangError) Erlang error: :enoent
     code: Accounting.find_pdfs([check.id])
     stacktrace:
       (elixir 1.10.3) lib/system.ex:795: System.cmd("gs", ["-q", "-sPAPERSIZE=letter", "-dNOPAUSE", "-dBATCH", "-sDEVICE=pdfwrite", "-sOutputFile=/tmp/pdfs/3bc6c52f-73b7-497d-9031-8008fbac3e31/out.pdf"], [])
       (app_count 0.1.0) lib/app_count/data/utils/pdf.ex:40: AppCount.Data.Utils.PDF.do_concat/2
       (app_count 0.1.0) lib/app_count/accounting/utils/checks.ex:107: AppCount.Accounting.Utils.Checks.find_pdfs/1
       test/app_count/accounting/checks_test.exs:62: (test)
```

So rather than requiring another utility be installed just for these tests, you
can now exclude those tests with the following environment variable.

in file ".bash_profile"

```sh
  alias APPRENT_GS_INSTALLED=false
```


Changing the value of the system environment requires a full recompile

```sh
  MIX_ENV=test mix compile --force
```

## Test Environments

We have two testing environments, one for unit tests and one for integration/feature tests.

Support files that are shared between integration and test environments are located in test/support.

### Unit Tests

Unit tests go in the test/unit folder. Support files specific to unit testing are in test/unit/support.

Unit tests are intended to focus on one bit of the code, generally one test per one 
public function. All "delegated" functionality ie. background tasks or functionality that is handed off
to a different layer of the application should be somehow stubbed/mocked out when possible and plausible. 
To this end in the regular `test` environment all calls to `AppCount.Core.Tasker` as well as `AppCount.Tasks.Queue`
are skipped. In addition, in controller tests calls to the 
business layer(basically any module starting with `AppCount.`) should be mocked out as well.

### Integration tests

Unit tests go in the test/integration folder. Support files specific to unit testing are in test/integration/support.

Integration tests test out the full scope of any given action we expect the application to execute.
This includes but is not limited to:

  * HTTP requests
  * WebSocket calls
  * Scheduled Jobs
  
In these tests NOTHING is stubbed or mocked out, and asynchronous tasks are run synchronously 
to ensure that the full gamut of that request/action is running properly. These tests are not described
by any particular module or function, but are described by the action they are intended to simulate.

### Running the tests

Unit tests are run via the normal `mix test` command, whereas integration tests are 
run by `mix test.integration`. Expect the unit tests to run vastly faster than the integration tests,
that is once the tests have been properly sorted by their type.

### Coverage reports

`mix coveralls._` will create a coverage report that will show what parts of the code are covered by the tests.
This will be done per environment. `mix coveralls.html` will show test coverage for the unit tests and
`mix coveralls.integration` will show for the integration environment. Our goal is to have all code covered
by both types of tests.

Before deploy both test suites will be run, unit tests and then integration.

