# Banking Api
An Elxir api that supports creating accounts, withdrawals and transfers between users.
The admin users can change user values and also access the backlog, where is possible to get periodical reports about transactions.

## Technology
- [Elixir](https://elixir-lang.org/) programming language.
- [Phoenix](https://www.phoenixframework.org/) web framework.
- [PostgresSQL](https://www.postgresql.org/) for persisting data. 
- [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/) for development environment.

## Up and Running
Make sure you have Elixir and PostgresSQL installed and follow the next steps:

1. Clone this repo and open the directory
```sh
git clone https://github.com/gabrielBlankenburg/BankingApi
cd BankingApi
```

2. Install the dependencies
```sh
mix deps.get
```

3. Create the database
```sh
mix ecto.create
```

4. Run the migrations
```sh
mix ecto.migrate
```

5. Run the seeds so an admin user is generated

``` sh
mix run priv/repo/seeds.exs
```

6. Start the server
```sh
mix phx.server
```
or if you want to do some debugging

``` sh
iex -S mix phx.server
```

Now accessing the [dashboard](http://localhost:4000/dashboard/home) must show the server stats.

**Note:** It's also possible running with Docker by just executing `docker-compose up -d`. For using docker, change the `config/dev.exs` database `hostname` config to `db`. 

## Docs and Tests 
- For executing the tests, just run `mix test` or for getting the coverage `mix coveralls.html`. 
- For generating the docs, run `mix docs`.


## How it Works
### Contexts
This project follows the Phoenix pattern that works with contexts. There are currently three contexts:
- **Accounts** manipulates user data.
- **Reports** manipulates reports data, currently only transactions reports are supported.
- **Transactions** manipulates transactions data, currently is supported withdrawals and transfers.

### Handling Money
Since computers can't handle float numbers properly, we are using integer numbers. So 10.00 BRL is represented as 1000. Some formatting is possible to achieve through the module `BankingApi.Money`.

### Authentication
We use JWT for authenticating and authorizing users. The JWT token can be sent as an `Authorization` header by sending `Bearer token`.

### Users
There are two user profiles:
1. User
- When creating an account, the initial balance is of 1,000.00 BRL.
- Must have an unique email.
- Can withdraw any an amount lower or equal to his balance.
- Can transfer money to other users.
2. Admin
- Is allowed to list and manipulate user data.
- Is allowed to access the transaction reports.

### Transactions
There are two transaction types:
1. **Withdraw** allows users to withdraw any available amount in his balance.
2. **Transfer** allows users to transfer any available amount in his balance to another user.
A transaction always has a status of *success* or *fail*.
**Note:** Every transaction request requires an **idempotency key** (a string value to make that transaction unique), the client calling the api is responsible for generating an idempotency key and sending to the server. 
If a transaction fails, the same idempotency key can be sent again.
**Note:** When creating a transaction, an email is sent (actually mocked, but we can check this mock in the terminal).

## Api Routes
| Endpoint | Description | Required Profile | Method |
|-------------------|-----------------------|------------------|--------|
| /api/register | Creates an account | unauthenticated | POST |
| /api/login | Login | unauthenticated | POST |
| /api/withdraw | Creates an withdraw | user | POST |
| /api/transfer | Creates a transfer | user | POST |
| /api/admin/users | Lists the users | admin | GET |
| /api/admin/users/:id | Gets the user with the :id | admin | GET |
| /api/admin/users | Creates an user | admin | POST |
| /api/admin/users:id | Updates an user | admin | PATCH |
| /api/admin/users:id | Deletes an user | admin | DELETE |
| /api/admin/reports/transaction:id | Total transactions in the :period | admin | GET |

**Note:** the postman.json is a postman collection containing every endpoint example.
