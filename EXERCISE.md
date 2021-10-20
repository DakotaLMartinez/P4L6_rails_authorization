# Phase 4 - Lecture 5/6: Rails Authentication & Authorization Exercise
There are two portions of the exercise:
- Authentication: applying what we did in the previous lecture with the meetup clone to the reading list application.
- Authorization: Ensuring only logged in users can access our data and only admins are able to update and delete books
## Authentication
If you haven't completed adding authentication to the reading list application, the steps to complete for that are below. If you have, feel free to skip ahead to the [Authorization](#Authorization) portion. 

### Dependencies (Gems/packages)
We need bcrypt so that we can store encrypted (salted and hashed) versions of our users passwords instead of storing passwords in plain text:

```bash
bundle add bcrypt
```
### Configuration (environment variables/other stuff in config folder)
We need to tell rails that we want session cookies. To do that, we'll add the following to the config block in `config/application.rb`
```rb
config.middleware.use ActionDispatch::Cookies
config.middleware.use ActionDispatch::Session::CookieStore

# Use SameSite=Strict for all cookies to help protect against CSRF
config.action_dispatch.cookies_same_site_protection = :strict
```
We'll also need to include the middleware within the `ApplicationController`

```rb
class ApplicationController < ActionController::API
  include ActionController::Cookies
  # ...
end

```
### Database
We need a `password_digest` column in our `users` table.

```bash
rails g migration AddPasswordDigestToUsers password_digest
```

```bash
rails db:migrate
```
### Models

- We need to add a uniqueness validation for username so we can consistently find the right user for authentication
- We'll add a uniqueness validation to email, but we can set `allow_blank: true` so that it's not required.
- We need to add the `has_secure_password` macro to the model to implement the `authenticate` and `password=` methods used in login & signup actions respectively
- After you've added `has_secure_password` to the `User` model, you can open up rails console to assign a password to the existing users to allow them to log in:

```rb
User.all.each{|u| u.password="password"; u.save }
```
This is necessary so that you'll be able to log in as tester1 with a password of password later on when you test this out in the browser.
### Views/Serializers

- We'll want a `UserSerializer` that returns only the `id`, `username`, `email`, and `bio`

### Controllers

We'll need actions for:
- `users#show` - for rendering the currently logged in user as json
- `users#create` - for handling the signup form submission and rendering the newly created user as json (while logging them in)
- `sessions#create` - for handling the login form submission and rendering the newly logged in user as json
- `sessions#destroy` - for handling logout and removing the user_id from the session cookie

We'll also need to change the `current_user` method so that it makes use of the user_id stored in the session cookie sent from the browser. This will allow us to login as different users and have our application recognize user's requests by reading the user_id out of the cookie and returning the associated user.

```rb
def current_user
  @current_user ||= session[:user_id] && User.find_by_id(session[:user_id])
end
```
Using the `&&` here ensures that we only query the DB to get the user if there is a user_id stored in the session, otherwise we return `nil`.
### Routes

```rb
get "/me", to: "users#show"
post "/signup", to: "users#create"
post "/login", to: "sessions#create"
delete "/logout", to: "sessions#destroy"
```

| Endpoint | Purpose | params |
|---|---|---|
| get '/me' | returns the currently logged in user or 401 unauthorized if none exists. Used to determine whether to load the `AuthenticatedApp` or `UnauthenticatedApp` | none |
| post '/login' | returns the newly logged in user or a 401 if invalid credentials are submitted | username and password |
| post '/signup' | returns the newly created (and logged in) user or a 422 with validation errors if something goes wrong. | username, password, and password_confirmation |
| delete '/logout' | removes the user_id from the session cookie are returns 204 | none |

## Authorization

- Create and run a migration to add an `admin` boolean column to the `users` table.
- Add a private method called `confirm_authentication` to the `ApplicationController`
    - this method should return a rendered json message saying `"you must be logged in to do that"` with a status of unauthorized unless there is a user currently logged in. (We can use the `current_user` method to confirm this)
- Add a `before_action` call to `:confirm_authentication` to the `BooksController` and `UserBooksController`
- Add a private method `set_book` to the `BooksController`
```rb
  def set_book
    @book = Book.find(params[:id])
  end
```

- Add a `before_action` for `:set_book` to the `BooksController` below `:confirm_authentication`
     
    run this only before the `:show, :update, :destroy` actions
- We don't currently have `update` or `destroy` defined within the `BooksController`, so add them and remove the restrictions in `config/routes.rb` ( `only: [:index, :show, :create]`)so there are routes for them as well:
```rb
def update
  if @book.update(book_params)
    render json: @book, status: :ok, serializer: BookShowSerializer
  else
    render json: book.errors, status: :unprocessable_entity
  end
end

def destroy
  @book.destroy
  head :no_content
end
```
```rb
resources :books
```
- Add a private method `authorize_user` to the `BooksController`. In it, check if the current user is an admin. If they're not, render an error message indicating `"you don't have permission to perform that action"` as JSON with a `403` (forbidden) status code. If they are an admin, do nothing.
- Add a `before_action` for `authorize_user` to the `BooksController` that runs only before `:update` and `:destroy`.
- Since we're allowing books to be destroyed now (by admins only) we need to handle the join records that may be pointing back to any existing books by adding `dependent: :destroy` after the `has_many :user_books` within the `Book` model (app/models/book.rb)
- Finally, since our frontend will show additional options to admins, we need to include the admin status in our `UserSerializer` so that the UI for updating and deleting books will be visible to admin users.


## Testing it Out

- Drop into the rails console and make the first user an admin: `User.first.update(admin: true)`
- Boot up the [react client](https://github.com/DakotaLMartinez/reading_list_client) dev server and login as the `tester1` admin user. 
- You should now have the ability to update and delete books!
- Try logging out from the application
- log in as `tester2`
- The buttons to edit and delete books should no longer appear

## Congratulations!!!