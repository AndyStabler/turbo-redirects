# Turbo Stream Redirects

When a form is submitted I want to either redirect or, if the
data submitted was invalid, re-render the form with errors.

I had some bother achieving this with Rails Turbo Streams while my form
was inside a `turbo_frame_tag`. When attempting
to redirect I saw the following error:

```js
  Response has no matching <turbo-frame id="user_form"> element
```

The new page we're redirecting to doesn't have a matching `turbo_frame_tag`
and so an error is shown, but I want to do a full page redirect. I don't
care about the turbo frame tag in this scenario.

The "right" solution I found was to not use a `turbo_frame_tag` and instead
wrap my form in a normal div. The controller can then either replace the contents
of this div using a turbo stream, or it can do a full page redirect.

If we _do_ need a `turbo_frame_tag`, then the following work around seems to do the trick. It feels a bit clunky, but maybe that's because a `turbo_frame_tag` isn't best suited to this use case.

In my example I want to create a user. If the form is successful I want to redirect
to the root URL, otherwise I want to re-render the user form with validation errors.

Here's my form, you can see it's wrapped in a `turbo_frame_tag`:

```rb
  # app/views/users/_form.html.erb
  <%= turbo_frame_tag dom_id(user) do %>
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
```

And here's my controller:

```rb
  # app/controllers/users_controller.rb
  # POST /users
  def create
    user = User.new(user_params)

    if user.save
      # The following line doesn't work as I'd expect. It results in:
      #  Response has no matching <turbo-frame id="new_user"> element
      #redirect_to root_url

      render turbo_stream: turbo_stream.append('new_user', template: "users/_account_created")
    else
      render turbo_stream: turbo_stream.replace('new_user', template: 'users/_form', locals: { user: user})
    end
  end
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
```

This has the desired effect—we re-render the form with validation errors
if save is unsuccesful, otherwise we redirect to our root page.

From [looking around](https://discuss.hotwired.dev/t/redirect-after-turbo-stream-response/2303/3?u=andystabler) it seems like this is an approach others have taken.

Take a look at the [without-turbo-frame-tag branch](https://github.com/AndyStabler/turbo-redirects/pull/1/files) to see how this can be done without using a `turbo-frame-tag`.
