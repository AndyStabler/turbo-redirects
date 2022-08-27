# Turbo Stream Redirects

When a form is submitted I want to either redirect or, if the
data submitted was invalid, re-render the form with errors.

I had some bother achieving this with Rails Turbo Streams. When attempting
to redirect I saw the following error:

```
Response has no matching <turbo-frame id="user_form"> element
```

The new page we're redirecting to doesn't have a matching `turbo_frame_tag`
and so an error is shown, but I want to do a full page redirect. I don't
care about the turbo frame tag in this scenario.

This is the solution I came up with. It feels a bit clunky, so let me
know if there's a better way.

In my example I want to create a user. If the form is successful I want to redirect
to the root URL, otherwise I want to re-render the user form with validation errors.

Here's my form, you can see it's wrapped in a `turbo_frame_tag`:

```rb
  # app/views/users/_form.html.erb
  <%= turbo_frame_tag 'user_form' do %>
    <%= form_with(model: user) do |form| %>
      <% if user.errors.any? %>
        <div style="color: red">
          <h2><%= pluralize(user.errors.count, "error") %> prohibited this user from being saved:</h2>

          <ul>
            <% user.errors.each do |error| %>
              <li><%= error.full_message %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <div>
        <%= form.label :name, style: "display: block" %>
        <%= form.text_field :name %>
      </div>

      <div>
        <%= form.submit %>
      </div>
    <% end %>
  <% end %>
<% end %>
```

And here's my controller:

```rb
  # app/controllers/users_controller.rb
  # POST /users
  def create
    user = User.new(user_params)

    if user.save
      render turbo_stream: turbo_stream.append("user_form", template: "users/_account_created")
    else
      render turbo_stream: turbo_stream.replace("user_form", template: 'users/_form', locals: { user: user})
    end
  end
<% end %>
```

If the save is successful, then we append the `users/_account_created` template to the `turbo_frame_tag`.

The `_account_created` partial sets a redirect url value that a stimulus controller detects and redirects the browser to. Here's what `users/_account_created` looks like:

```rb
<div data-controller="redirect" data-redirect-url-value="<%= root_url %>"></div>
```

Our stimulus controller looks like this:

```js
// app/javascript/controllers/redirect_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  connect () {
    window.location.href = this.urlValue
  }
}
<% end %>
```

This has the desired effect—we re-render the form with validation errors
if save is unsuccesful, otherwise we redirect to our root page.

From [looking around](https://discuss.hotwired.dev/t/redirect-after-turbo-stream-response/2303/3?u=andystabler) it seems like this is an approach others have taken. Feels like Rails Turbo Streams should
be able to handle either manipulating a turbo frame tag _or_ redirecting to another page entirely. There's a fairly large chance it already handles this though and I've just missed it!
