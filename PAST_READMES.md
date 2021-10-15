# Phase 4 - Lesson 1 - Rails Fundamentals

In this phase we will be building on our knowledge of Ruby and ActiveRecord from Phase 3 to:
- build RESTful APIs with Ruby on Rails
- validate data and return responses with appropriate status codes so that we can give our users more meaningful feedback in API responses
- build applications that include user authentication and access control. 
- deploy our applications so we can share them with friends, family and potential employers

For our application we build together, we'll be working on a meetup clone. The app that you'll be building in exercises is a reading list application. We'll again be adding new features every day, but this time, you'll be working on the app on your own machine day by day. So, you'll want to be keeping up with the work for each day so you'll be ready to participate during the exercise the following day.

## What things are different with Rails than they were in Sinatra

- config/routes.rb file
- faster
- more functionality in terminal commands
- we can use generators to create files
- rails new can generate a whole new project

## Lesson 1 Todos

### Instructions for Demo

1. Create a new rails application for our reading list application. 
`rails new meetup_clone_api --api --minimal --skip-javascript -T`
Note: Do not forget the --api! The rails application will not be configured correctly if you do! If you forget it, delete the application and re-create it. 
2. Configure cors by uncommenting the `gem 'rack-cors'` and going to `config/initializers/cors.rb` and uncommenting the code below (make sure to replace `'example.com'` with `*` within origins):

```rb 
Rails.application.config.middleware.insert_before 0, Rack::Cors do
   allow do
     origins '*'

     resource '*',
       headers: :any,
       methods: [:get, :post, :put, :patch, :delete, :options, :head]
   end
 end
```
3. Create the following migrations for meetup_clone
![Meetup Clone ERD](https://res.cloudinary.com/dnocv6uwb/image/upload/v1634013378/meetup-clone-erd_lbchpk.png)
Note: you do not need to write the tables yourself. There is a way to automatically generate the table with the corresponding columns using rails generators

4. Go to Models and add the association macros to establish the relationships pictured in the Entity Relationship Diagram (ERD). 
5. In the rails console OR in seeds create seeds for users and groups and test your relationships. (You'll want to create groups that are related to users and events that are related to groups, try checking out the [has_many](https://apidock.com/rails/ActiveRecord/Associations/ClassMethods/has_many) docs for examples)
6. In `config/routes.rb` add an index and show route for groups
7. In the groups controller add an index action that renders all of the groups in json. Make a show action that renders 1 group's information given the id
8. Run your rails server and go to the browser (or use postman) to check that your json is being rendered for both routes

# Phase 4, Lecture 2 - Client Server Communication part 1

Today's focus:

- building out `create` actions in our controllers
- validating user input
- using strong parameters to specify the allowed parameters for post/patch requests
- returning appropriate status codes
- mocking a `current_user` method in our `ApplicationController` that will return the logged in user when we've set up authentication (for now it'll just return the first user in our db)

[RailsGuides on Validations](https://guides.rubyonrails.org/active_record_validations.html) will be important today

## Meetup Clone features list

- As a User, I can create groups
  - groups must have a unique name
- As a User, I can create events
  - events must have a :title, :location, :description, :start_time, :end_time 
  - The title must be unique given the same location and start time
- As a User, I can RSVP to events
  - I can only rsvp to the same event once
- As a User, I can join groups
  - I can only join a group once

Before we hop into coding today, there's a configuration option that we're going to want to change. When we start talking about strong parameters in our controllers, rails is going to do some magic with the params that we pass in via POSTMAN or fetch and add the name of our resource as a key containing all of the attributes we're posting. If we want to disable this feature, we can do so once at the beginning by editing the `config/intializers/wrap_parameters.rb` file. It currently looks like this:

```rb
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: [:json]
end
```

We'll update it to this:

```rb
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: []
end
```

We'll also want to add in the `current_user` method to the `ApplicationController` so we can use it later on when we need to create records in the controller that should belong to the logged in user.

```rb
class ApplicationController < ActionController::API
  # ...
  private

  def current_user
    User.first
  end
end
```

We can open up the rails console and check `User.first` to confirm that we actually have a User in our database that this method will return.

## My Process for Building out features
If this is what the Request/Response flow looks like when we interact with our API using a React client application:

![MVC Flow](./mvc-flow.png)

Then, for each feature I want to figure out what request(s) are necessary to support the feature and what the response should be. From there, we can split the feature into tasks by asking what needs to change in our routes, controller and model layers in order to generate the required response from the request.
### Request

What will the fetch request look like? (Method, endpoint, headers, and body)
### Route

What route do we need to match that request? which controller action will respond?

### Controller

What needs to happen within our controller action? Are there relevant params for this request? If it's a POST or PATCH request, we're most likely going to want to do mass assignment, so what parameters should we allow within our strong params?

### Model (database)

Are there any model methods that need to be defined to support the request? (Are there any inputs from the user that don't exactly match up with columns in the associated database table?)

What validations do we need to add to ensure the we're not allowing users to add invalid or incomplete data to our database?

### Response

Depending on how our validations go, how should our controller action respond to the request? What should be included in the json? What should the status code be?

## A note about Status Codes

| Codes | Meaning | Usage |
|---|---|---|
| 200-299 | OK Response | used to indicate success (200 is OK, 201 is created, 204 is no content) |
| 300-399 | Redirect | used mainly in applications that do server side rendering (not with a react client) to indicate that the server is responding to the request by generating another request |
| 400-499 | User Error | Used to indicate some problem with the request that the user sent. (400 is bad request, 401 is unauthorized, 403 is forbidden, 404 is not found,...) |
| 500-599 | Server Error | Used to indicate that a request generated an error on the server side that needs to be fixed. When we see this during development, we need to check out network tab and rails server logs for a detailed error message. |

See [railsstatuscodes.com](http://www.railsstatuscodes.com/) for a complete list with the corresponding symbols.

The status code in the response allows us to indicate to the frontend whether or not the request was a success. The way that we interact with the status code from our client side code is by working with the [response object](https://developer.mozilla.org/en-US/docs/Web/API/Response) that fetch returns a [promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) for.

#### Example

Fetch returns a promise for a response object. The first callback that we pass to `then` to consume that resolved promise value takes that response object as an argument. That response object has a status code and a body that we can read from.  When we do `response.json()` in the promise callback, we're parsing the body of the response from JSON string format to the data structure that it represents. The response object also has an `ok` property that indicates that the status code is between 200-299

```js
fetch('http://localhost:3000/groups', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  }, 
  body: JSON.stringify({name: "Online Software Engineering 071921"})
})
  .then(response => {
    if(response.ok) {
      return response.json()
    } else {
      return response.json().then(errors => Promise.reject(errors))
    }
  })
  .then(groups => {
    console.log(groups) // happens if response was ok
  })
  .catch(errors => {
    console.error(errors) // happens if response was not ok
  })
```

If the response status is not in the 200-299 range, then ok will be false, so we'll want to return a rejected Promise for the response body parsed as json. We can then attach a catch callback to handle adding an error to state after it's caught by the catch callback.

Let's make another version of the mvc-flow diagram that includes validations.

![mvc flow with validations](./mvc-flow-with-validations-create.png)

## Users must provide a unique name when creating a group

### Request
POST '/groups'
```js
fetch(`http://localhost:3000/groups`,{
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({name: 'Online Software Engineering 071921'})
})
```

For Postman

```
{
  "name": "Online Software Engineering 071921"
}
```
### Route

```rb
resources :groups, only: [:create]
# or
post '/groups', to: 'groups#create'
```

### Controller

```rb
class GroupsController < ApplicationController
  # ...
  def create 
    byebug
  end

  # ...

  private 

  def group_params
    params.permit(:name, :location)
  end
end
```

### Model

```rb
class Group < ApplicationRecord
  # ...
  validates :name, presence: true, uniqueness: true
end
```

### Response

We want our API to check if we've successfully created a group or if some validation error prevented the save. To do this, we'll need to add some conditional logic to the create action:

```rb
class GroupsController < ApplicationController
  # ...
  def create 
    group = Group.new(group_params)
    if group.save
      render json: group, status: :created # 201 status code
    else
      render json: group.errors, status: :unprocessable_entity # 422 status code
    end
  end

  # ...

  private 

  def group_params
    params.permit(:name, :location)
  end
end
```

### Testing

Send the request twice to confirm that the creation works the first time and the uniqueness validation works the second time.

## Users must provide a :title, :location, :description, :start_time, :end_time when creating an event

### Request
POST '/events'
```js
fetch('http://localhost:3000/events',{
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    title: 'Rails Client/Server Communication part 1',
    description: 'Validations, strong parameters, mass assignment, status codes and the create action',
    location: 'online',
    start_time: "2021-09-21T11:00:00",
    end_time: "2021-09-21T13:00:00",
    group_id: 1
  })
})
```

For postman:

```json
{
  "title": "Rails Client/Server Communication part 1",
  "description": "Validations, strong parameters, mass assignment, status codes and the create action",
  "location": "online",
  "start_time": "2021-09-21T11:00:00",
  "end_time": "2021-09-21T13:00:00",
  "group_id": 1
}
```

### Route

```rb
resources :events, only: [:create]
# or
post '/events', to: 'events#create'
```

### Controller

```rb
class EventsController < ApplicationController
  # ...
  def create 
    byebug
  end

  # ...

  private 

  def event_params
    params.permit(:title, :description, :location, :start_time, :end_time, :group_id)
  end
end
```

### Model

```rb
class Event < ApplicationRecord
  # ... 
  validates :title, :description, :location, :start_time, :end_time, presence: true
  validates :title, uniqueness: { scope: [:location, :start_time]}
end
```

### Response

We want our API to check if we've successfully created an event or if some validation error prevented the save. To do this, we'll need to add some conditional logic to the create action:

```rb
class EventsController < ApplicationController
  # ...
  def create 
    event = Event.new(event_params)
    if event.save
      render json: event, status: :created # 201 status code
    else
      render json: event.errors, status: :unprocessable_entity # 422 status code
    end
  end

  # ...

  private 

  def event_params
    params.permit(:title, :description, :location, :start_time, :end_time, :group_id)
  end
end
```

### Testing

Send the request twice to confirm that the creation works the first time and the uniqueness validation works the second time.

## Users can RSVP to events

### Request

```js
fetch('http://localhost:3000/user_events', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    event_id: 1
  })
})
```

For postman

```json
{
  "event_id": 1
}
```

### Route

```rb
resources :user_events, only: [:create]
# or 
post '/user_events', to: 'user_events#create'
```

### Controller

For this functionality, users will only be able to add themselves to an event at the moment, so our API will need a way of knowing which user is making the request. Next week, we'll learn about how to do this for real, but for now, we're going to use the method called `current_user` in our application controller that just returns one of the users we created within the `db/seeds.rb` file. 

If we need to simulate being logged in as another user, we can update the `current_user` method to return the user we want to switch to. We'll replace this method later, but for now it will help us to build out functionality on the server that requires knowledge of the currently logged in user without actually having authentication set up yet. Within the other controller, we'll use the current_user method to build the associated object.

```rb
class UserEventsController < ApplicationController
  # ...
  def create
    byebug
  end

  # ...
  private

  def user_event_params
    params.permit(:event_id)
  end
end
```
### Model
We want to ensure that we aren't creating multiple user events for the same combination of user and event as that would serve no purpose here.

```rb
class UserEvent < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :event_id, uniqueness: { scope: :user_id }
end
```

In this case, the error message we get will be "event_id is already taken" which is less clear than it could be. So we can customize the error message by adding another option to the hash we pass to uniqueness.

```rb
class UserEvent < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :event_id, uniqueness: { scope: :user_id, message: "Can't rsvp for the same event twice" }
end
```
### Response

We want our API to check if we've successfully created an event or if some validation error prevented the save. To do this, we'll need to add some conditional logic to the create action:

```rb
class UserEventsController < ApplicationController
  # ...
  def create
    user_event = current_user.user_events.new(user_event_params)
    if user_event.save
      render json: user_event, status: :created # 201 status code
    else 
      render json: user_event.errors, status: :unprocessable_entity # 422 status code
    end 
  end

  # ...
  private

  def user_event_params
    params.permit(:event_id)
  end
end
```
### Testing

Send the request twice to confirm that the creation works the first time and the uniqueness validation works the second time.

## Users can join other groups

### Request

```js
fetch('http://localhost:3000/user_groups', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    group_id: 1
  })
})
```

For postman

```json
{
  "group_id": 1
}
```

### Route

```rb
resources :user_groups, only: [:create]
# or 
post '/user_groups', to: 'user_groups#create'
```

### Controller

```rb
class UserGroupsController < ApplicationController
  # ...
  def create
    byebug
  end

  # ...
  private

  def user_group_params
    params.permit(:group_id)
  end
end
```
### Model
We want to ensure that we aren't creating multiple user groups for the same combination of user and group as that would serve no purpose here.
```rb
class UserGroup < ApplicationRecord
  belongs_to :user
  belongs_to :group

  validates :group_id, uniqueness: { scope: :user_id }
end
```

### Response

We want our API to check if we've successfully created an event or if some validation error prevented the save. To do this, we'll need to add some conditional logic to the create action:

```rb
class UserGroupsController < ApplicationController
  # ...
  def create
    user_group = current_user.user_groups.create(user_group_params)
    if user_group.save
      render json: user_group, status: :created # 201 status code
    else 
      render json: user_group.errors, status: :unprocessable_entity # 422 status code
    end 
  end

  # ...
  private

  def user_group_params
    params.permit(:group_id)
  end
end
```

After a break, we'll start our exercise for lesson 3

# Phase 4 - Lecture 3 Client/Server Communication part2

## Today's Topics

- Adding Update/Delete functionality to our API to complete full CRUD
- How to write add column migrations
- Practicing how to break down feature requirements into the RESTful API endpoints they require

## Features for Meetup Clone

- Users can delete an event they created
- Users can leave a group
- Users who rsvp'd to an event can delete their RSVP
- Users can update an event they created
- Users can update whether a user attended an event

## Features for Reading List Application

- Users can update whether or not they have read a book
- Users can remove a book from their reading list

Again, we'll be breaking down the functionality into pieces, starting with the request, going through route, controller, model and leading to a response. Today, I'll be asking for more input from you all about what the RESTful requests should be to support these features.

## Users can delete an event they created

### Request

<details>
  <summary>
    What request method do we need? GET/POST/PATCH or DELETE?
  </summary>
  <hr/>
  DELETE
  <hr/>
</details>
<br />

<details>
  <summary>
    What will the path be?
  </summary>
  <hr/>

  `/events/:id`

  <hr/>

</details>

<br/>
<details>
  <summary>
    Do we need the content-type header? 
  </summary>
  <hr/>

  NO

  <hr/>

</details>


<br/>
<details>
  <summary>
    Do we need a body? If so what will it look like?
  </summary>
  <hr/>

  N/A

  <hr/>

</details>
<br/>

### Route
<br/>
<details>
  <summary>
    What route do we need?
  </summary>
  <hr/>

  ```rb
  resources :events, only: [:destroy]
  ```

  <hr/>

</details>
<br/>

### Controller
<br/>
<details>
  <summary>
    Which controller action(s) do we need?
  </summary>
  <hr/>

  `events#destroy`

  <hr/>

</details>
<br/>

### Model/Database
<br/>
<details>
  <summary>
    Any changes needed to model layer (methods/validations/etc.)?
  </summary>
  <hr/>

  Nope!

  <hr/>

</details>
<br/>

<details>
  <summary>
    Any changes needed to the database to support this request?
  </summary>
  <hr/>

  Nope!

  <hr/>

</details>
<br/>

<details>
  <summary>
    What model objects are involved and how do we interact with them in the controller?
  </summary>
  <hr/>

  - We need to find the event object we're going to delete using the find method with the id included in the request url parameters.
  - We need to call destroy on that object.

  <hr/>

</details>
<br/>

### Response
<br/>
<details>
  <summary>
    What should the response be to our API request?
  </summary>
  <hr/>

  ```rb
  def destroy
    event = Event.find(params[:id])
    event.destroy
  end
  ```
  no content (204 status code) We can get this by leaving off the render.
  
   We can also respond with 200 ok and the deleted record if we want to enable an undo feature from our frontend (we can send a POST request to insert the deleted record again)
  ```rb
  def destroy
    event = Event.find(params[:id])
    event.destroy
    render json: event
  end
  ```
  <hr/>

</details>
<br/>


## Users who rsvp'd to an event can delete their RSVP

### Request
<details>
  <summary>
    What request method do we need? GET/POST/PATCH or DELETE?
  </summary>
  <hr/>
  DELETE
  <hr/>
</details>
<br />

<details>
  <summary>
    What will the path be?
  </summary>
  <hr/>

  `/user_events/:id `

  <hr/>

</details>

<br/>
<details>
<summary>
Do we need the content-type header?
</summary>
<hr/>

NO

<hr/>

</details>


<br/>
<details>
  <summary>
    Do we need a body? If so what will it look like?
  </summary>
  <hr/>

  N/A

  <hr/>

</details>
<br/>

### Route
<details>
  <summary>
    What route do we need?
  </summary>
  <hr/>

  `resources :user_events, only: [:destroy]`

  <hr/>

</details>
<br/>

### Controller
<details>
  <summary>
    Which controller action(s) do we need?
  </summary>
  <hr/>

  `user_events#destroy`

  <hr/>

</details>
<br/>

### Model/Database
<details>
  <summary>
    Any changes needed to model layer (methods/validations/etc.)?
  </summary>
  <hr/>

  Nope!

  <hr/>

</details>
<br/>

<details>
  <summary>
    Any changes needed to the database to support this request?
  </summary>
  <hr/>

  Nope!

  <hr/>

</details>
<br/>

<details>
  <summary>
    What model objects are involved and how do we interact with them in the controller?
  </summary>
  <hr/>

  - We need to find the `UserEvent` we're going to delete using the find method and the id included in the url parameters of the request. 
  - Then we need to call destroy on that object.

  <hr/>

</details>
<br/>



### Response
<details>
  <summary>
    What should the response be to our API request?
  </summary>
  <hr/>

  ```rb
    def destroy
      user_event = UserEvent.find(params[:id])
      user_event.destroy
    end
  ```

  None needed. If we just leave out the render method, we'll send a 204 no content response by default. We can explicitly send the 204 no content response by adding

  ```rb
  head :no_content
  ```

  <hr/>

</details>
<br/>

## Users can leave a group

### Request

<details>
  <summary>
    What request method do we need? GET/POST/PATCH or DELETE?
  </summary>
  <hr/>
  DELETE
  <hr/>
</details>
<br />

<details>
  <summary>
    What will the path be?
  </summary>
  <hr/>

  `/user_groups/:id`

  <hr/>

</details>

<br/>
<details>
  <summary>
    Do we need the content-type header? 
  </summary>
  <hr/>

  NO

  <hr/>

</details>


<br/>
<details>
  <summary>
    Do we need a body? If so what will it look like?
  </summary>
  <hr/>

  N/A

  <hr/>

</details>
<br/>

### Route
<br/>
<details>
  <summary>
    What route do we need?
  </summary>
  <hr/>

  ```rb
  resources :user_groups, only: [:destroy]
  ```

  <hr/>

</details>
<br/>

### Controller
<br/>
<details>
  <summary>
    Which controller action(s) do we need?
  </summary>
  <hr/>

  `user_groups#destroy`

  <hr/>

</details>
<br/>

### Model/Database
<br/>
<details>
  <summary>
    Any changes needed to model layer (methods/validations/etc.)?
  </summary>
  <hr/>

  Nope!

  <hr/>

</details>
<br/>
<details>
  <summary>
    Any changes needed to the database to support this request?
  </summary>
  <hr/>

  Nope!

  <hr/>

</details>
<br/>

<details>
  <summary>
    What model objects are involved and how do we interact with them in the controller?
  </summary>
  <hr/>

  - We need to find the `UserGroup` we're going to delete using the find method with the id included in the request url parameters
  - and then we need to call destroy on that object.

  <hr/>

</details>
<br/>

### Response
<br/>
<details>
  <summary>
    What should the response be to our API request?
  </summary>
  <hr/>

  ```rb
  user_group = UserGroup.find(params[:id])
  user_group.destroy
  ```

  no content (204 status code) We can get this by leaving off the render.
  
  We can also respond with 200 ok and the deleted record if we want to enable an undo feature from our frontend (we can send a POST request to insert the deleted record again)

  <hr/>

</details>
<br/>


## Users can update an event they created

### Request
<details>
  <summary>
    What request method do we need? GET/POST/PATCH or DELETE?
  </summary>
  <hr/>

  `PATCH`

  <hr/>

</details>
<br/>


<details>
  <summary>
    What will the path be?
  </summary>
  <hr/>

  `/events/:id`

  <hr/>

</details>
<br/>


<details>
  <summary>
    Do we need the Content-Type header?
  </summary>
  <hr/>

  YES because we have a JSON body

  <hr/>

</details>
<br/>

<details>
  <summary>
    Do we need a body? If so, what will it include?
  </summary>
  <hr/>

  YES
  - :title
  - :description
  - :location
  - :start_time
  - :end_time
  - :group_id

  To see what these things should be, we can take a look at the corresponding database table in our schema and think about which things a user should be able to edit directly. We can also check the strong parameters in the corresponding controller.

  <hr/>

</details>
<br/>

### Route
<details>
  <summary>
    What route do we need?
  </summary>
  <hr/>

  `patch "/events/:id" => events#update`

  -- or --

  `resources :events, only: [:update]`

  <hr/>

</details>
<br/>

### Controller
<details>
  <summary>
    Which controller action(s) do we need?
  </summary>
  <hr/>

  `events#update`

  <hr/>

</details>
<br/>

### Model/Database

<details>
  <summary>
    Any changes needed to model layer (methods/validations/etc.)?
  </summary>
  <hr/>

  None

  <hr/>

</details>
<br/>

<details>
  <summary>
    Any changes needed to the database to support this request?
  </summary>
  <hr/>

  Nope!

  <hr/>

</details>
<br/>

<details>
  <summary>
    What model objects are involved and how do we interact with them in the controller?
  </summary>
  <hr/>

  - We need to find the event whose id appears in the url parameters of the request
  - We need to try to update that event with the `event_params`

  <hr/>

</details>
<br/>



### Response
<details>
  <summary>
    What should the response be to our API request?
  </summary>
  <hr/>

  - if update succeeds, the json version of the updated event and a 200 status code
  - if not, error messages with 422 status code upon failed validation

   ```rb
  def update
      event = Event.find(params[:id])
      if event.update(event_params)
        render json: event, status: :ok
      else
        render json: event.errors, status: :unprocessable_entity
      end
    end
  ```

  <hr/>

</details>
<br/>




## Users can update whether a user attended an event

### Request
<details>
  <summary>
    What request method do we need?
  </summary>
  <hr/>

  `PATCH`

  <hr/>

</details>
<br/>


<details>
  <summary>
    What will the path be?
  </summary>
  <hr/>

  `/user_events/:id`

  <hr/>

</details>
<br/>

<details>
  <summary>
    Do we need the Content-Type header?
  </summary>
  <hr/>

  YES

  <hr/>

</details>
<br/>


<details>
  <summary>
    Do we need a body? If so, what will it include?
  </summary>
  <hr/>

- YES
    - event_id
    - attended (boolean)

This could be debatable to an extent.  If we're updating an RSVP, would it make sense to change the event the rsvp belongs to or simply to focus on whether they attended or not? If we decided we only want to allow updating of the attended attribute, what change would we need to make?
  <hr/>

</details>
<br/>

### Route
<details>
  <summary>
    What route do we need?
  </summary>
  <hr/>

  `patch '/user_events/:id', to: 'user_events#update'`

  -- or --

  `resources :user_events, only: [:update]`

  <hr/>

</details>
<br/>

### Controller
<details>
  <summary>
    Which controller action(s) do we need?
  </summary>
  <hr/>

  `user_events#update`

  <hr/>

</details>
<br/>

<details>
  <summary>
    Can we use our strong parameters from create or is update different for some reason?
  </summary>
  <hr/>

  In this case, we probably don't want to allow `event_id` through when doing an update, so we'll need a separate method for `update_user_event_params` here to only permit `attended` to be updated.

  <hr/>

</details>
<br/>


### Model/Database

<details>
  <summary>
    Any changes needed to model layer (methods/validations/etc.)?
  </summary>
  <hr/>

  Nope!

  <hr/>

</details>
<br/>

<details>
  <summary>
    Any changes needed to the database to support this request?
  </summary>
  <hr/>

  YES! We don't currently have an attended column in the user_events table, so we'll need to add that.

  <hr/>

</details>
<br/>



<details>
  <summary>
    What model objects are involved and how do we interact with them in the controller?
  </summary>
  <hr/>

  - We need to find the `UserEvent` object to update by using the find method with the id including in the url parameters of the request.
  - We need to call update on that object and pass only the attended parameter (using strong_params)

  ```rb
  def update_user_event_params
    params.permit(:attended)
  end
  ```

  <hr/>

</details>
<br/>


### Response
<details>
  <summary>
    What should the response be to our API request?
  </summary>
  <hr/>

  - if update succeeds, the json version of the updated user_event and a 200 status code
  - if not, error messages with 422 status code upon failed validation

  ```rb
  def update
    user_event = UserEvent.find(params[:id])
    if user_event.update(update_user_event_params)
      render json: user_event, status: :ok
    else
      render json: user_event.errors, status: :unprocessable_entity
    end
  end
  ```

  <hr/>

</details>
<br/>




## Bonus Notes from the End of Time

```rb
# GET '/books/:id' # I don't get everything, but I see maybe the 10 most recent comments
# GET '/books/:book_id/comments' => all comments on book
# POST '/books/:book_id/user_books'
# GET '/books' allows you to make a request that has url parameters like this:
# http://localhost:3000/books?author=Malcolm+Gladwell'

# resources :posts do 
#   resources :comments
# end

# resources :users do 
#   resources :user_books, only: [:index]
# end

#get '/users/:user_id/user_books', to: "user_books#index"
```

Chaining scopes

```rb
class Post
  def self.search(options)
    results = self.all
    allowed_options = ["author", "publication_year"]
    allowed_options.each do |option|
      if options['option']
        results = results.where(option: options['option'])
      end
    end
    results
  end
end
```


