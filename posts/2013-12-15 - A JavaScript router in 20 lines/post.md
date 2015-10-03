Last week I found this post about [writing a template engine in 20 lines](http://krasimirtsonev.com/blog/article/Javascript-template-engine-in-just-20-line), which in turn is inspired by [John Resig's post on the same topic](http://ejohn.org/blog/javascript-micro-templating/). I find them really simple, interesting and inspiring so I came up with the idea of making a _simple client side router in just 20 lines of code_.

## Let's build a router

First we'll need a html template:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Building a router</title>
  <script>
    // Put John's template engine code here...
  </script>
</head>
<body>

</body>
</html>
```

For the templates I'll use `<script>` tags with `type="text/html"`, which will make the browser not parse the contents of them, like we want it. I place them right after the existing script tag.

```html
<script type="text/html" id="home">
  <h1>Router FTW!</h1>
</script>
<script type="text/html" id="template1">
  <h1>Page 1: <%= greeting %></h1>
  <p><%= moreText %></p>
</script>
<script type="text/html" id="template2">
  <h1>Page 2: <%= heading %></h1>
  <p>Lorem ipsum...</p>
</script>
```

As you can see they are really basic, that's because we are focusing on the router part...

### Hash URL's

For this router I'll use hash URL's, i.e. those specified after the `#` sign in the full URL e.g. http://example.com/#**/our/url/here**. I could have done it with the [HTML5 History API](https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Manipulating_the_browser_history) but I'll leave that for another time.

### Handling route changes

The router will use the [onhashchange event](https://developer.mozilla.org/en-US/docs/Web/API/Window.onhashchange) to handle route changes after page load and the usual [onload event](https://developer.mozilla.org/en-US/docs/Web/API/Window.onload) to handle any route in the url on page load.

### First take...

Let's begin with making the route registering function:

```javascript
// A hash to store our routes:
var routes = {};
// The route registering function:
function route (path, templateId, controller) {
  routes[path] = {templateId: templateId, controller: controller};
}
```

#### Registering routes

Now we can create new routes yay! _Notice that I'm mimicing the controller definition from AngularJS_:

```javascript
route('/', 'home', function () {});
route('/page1', 'template1', function () {
	this.greeting = 'Hello world!';
    this.moreText = 'Bacon ipsum...';
});
route('/page2', 'template2', function () {
	this.heading = 'I\'m page two!';
});
```

But yet nothing happens, because we don't handle the routes yet...

#### The actual route handler

Let's build the route handler! But first we need somewhere to render our pages, for now I settle with the convention that an element with id `view` is used as the container to render a page in.

```javascript
var el = null;
function router () {
	// Lazy load view element:
	el = el || document.getElementById('view');
    // Current route url (getting rid of '#' in hash as well):
    var url = location.hash.slice(1) || '/';
    // Get route by url:
    var route = routes[url];
    // Do we have both a view and a route?
    if (el && route.controller) {
    	// Render route template with John Resig's template engine:
        el.innerHTML = tmpl(route.templateId, new route.controller());
    }
}
// Listen on hash change:
window.addEventListener('hashchange', router);
// Listen on page load:
window.addEventListener('load', router);
```

There we have it! So let's test it!

### Testing the first version

First we'll add some navigational links to our layout, to be able to trigger the different routes, and the view element, by putting this inside our body element:

```html
  <ul>
    <li><a href="#">Home</a></li>
    <li><a href="#/page1">Page 1</a></li>
    <li><a href="#/page2">Page 2</a></li>
  </ul>
  <div id="view"></div>
```

[The complete first version can be found here](https://gist.github.com/joakimbeng/7918297/278619bd5ba9b4768eecb0020b09a43f2e8eacea).

Save and open your complete html file in a modern browser and you should see:

> Router FTW!

And the navigational links should work as well. You can also try to go to a specific route directly by navigating your browser to e.g. "path/to/your/router.html#/page1" and you should see the contents of our "page1".

### Bonus - one-directional data-binding!

To make the router a little more useful I'm going to add one-directional data-binding for automatic updating of the view when data in the controllers change. For that I'll be using [`Object.observe()`](https://simpl.info/observe/) _(note: I didn't need Chrome Canary for the flag to exist, I could enable it in Chrome 32-beta as well)_

I will extend the router handling function to register an object observer which rerenders the current view, so no advanced partial view updates at this time.

#### Router with object observation

With a small rewrite the new router look like this:

```javascript
var el = null, current = null;
function router () {
  // Lazy load view element:
  el = el || document.getElementById('view');
  // Clear existing observer:
  if (current) {
    Object.unobserve(current.controller, current.render);
    current = null;
  }
  // Current route url (getting rid of '#' in hash as well):
  var url = location.hash.slice(1) || '/';
  // Get route by url:
  var route = routes[url];
  // Do we have both a view and a route?
  if (el && route.controller) {
    // Set current route information:
    current = {
      controller: new route.controller,
      template: tmpl(route.templateId),
      render: function () {
        // Render route template with John Resig's template engine:
        el.innerHTML = this.template(this.controller);
      }
    };
    // Render directly:
    current.render();
    // And observe for changes to trigger rerender:
    Object.observe(current.controller, current.render.bind(current));
  }
}
```

**That's it!** As you can see, there's not that much extra code to get one-directional data-binding to work. I think the `Object.observe()` function is really great and can come in handy in many different scenarios in the future.

#### Testing the data-binding

To test the data-binding we'll just update one of the routes with a `setTimeout` to emulate a long running asynchronous function:

```javascript
route('/page1', 'template1', function () {
  this.greeting = 'Hello world!';
  this.moreText = 'Loading...';
  setTimeout(function () {
    this.moreText = 'Bacon ipsum...';
  }.bind(this), 500);
});
```

Then when you go to the route `#/page1` you should se "Loading..." for a short while which is then exchanged with "Bacon ipsum...".

### Result

[The full version with data-binding can be found here](https://gist.github.com/joakimbeng/7918297). I admit that it isn't only 20 lines of code, it's 28 without the comments, so it wasn't that far off :)

Even with data-binding this is still a really basic router though, for example parameter support is still missing, but this was made more as an experiment than a complete library anyway.

Hopefully someone liked it, as I did when coding it ;)
