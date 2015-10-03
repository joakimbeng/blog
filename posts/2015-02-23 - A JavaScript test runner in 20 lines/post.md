A few weeks ago I saw [this tweet about the world's smallest test library](https://twitter.com/snuggsi/status/565531862895169536) by [@snuggsi](https://twitter.com/snuggsi), which is a great little snippet! Though I see it more as the world's smallest assertion library, so I've decided to do a follow up on my previous post about [A JavaScript router in 20 lines](/a-javascript-router-in-20-lines/) and now make a simple test runner in about the same amount of code.

## Creating a test runner

### Must haves
When I think of a test runner there are a few things it must have IMO, mainly:

* The ability to add multiple tests
* Be able to run all tests
* Catch unexpected errors, *think syntax errors*
* Catch errors thrown by an assertion library
* Tell if everything went fine or not, and provide a stack trace if it didn't

Also when writing unit tests in JavaScript I want the test runner to be *able to test asynchronous code*.

### Some code please...

First we'll need somewhere to store all tests to run, i.e. the test queue, a simple array will do:

```javascript
var tests = [];
```

Then we must have a way to add tests to that queue. I usually use and like [Mocha](http://mochajs.org/) with the BDD syntax, which looks like this:

```javascript
describe('thing to test', function () {
  it('fulfills something...', function () {
    // test code...
  });
});
```

So let's make a simplified version of that:

```javascript
function test (name, cb) {
	tests.push({name: name, test: cb});
}

// Usage example:
test('thing to test fulfills something...', function () {
  // test code...
});
```

Simple enough :)

#### Syntax for asynchronous tests

How about asynchronous tests then? Once again I'll take inspiration from the Mocha framework, which uses `done` callbacks in the tests to execute when your test is done.

With that change our usage example now looks like:

```javascript
test('thing to test fulfills something...', function (done) {
  doSomethingAsync(function (result) {
    // assertions...
    done();
  });
});
```

Looking good!

### Running tests

Let's add a simple test, which we will run in the next step (**note** I'll use the small assertion library from the tweet mentioned in the beginning of the post):

```javascript
test('1+1 equals 2', function (done) {
  assert(1 + 1 === 2, '1+1 should be 2');
  done();
});
```

If we want to run just this one test, we could do something like:

```javascript
var testToRun = tests[0];
try {
  testToRun.test(done);
} catch (err) {
  done(err);
}
function done (err) {
  if (err) {
    console.error('Test failed!');
  } else {
	console.log('Test succeeded!');
  }
}
```

When we run this in [Node](http://nodejs.org) or in the browser a nice `"Test succeeded!"` should show up in the console.

#### Running all tests

Let's wrap that up in a function and make it get the next test from the queue, each time it's executed:

```javascript
var i = 0;
function run () {
  var testToRun = tests[i++];
  try {
    testToRun.test(done);
  } catch (err) {
    done(err);
  }
  function done (err) {
    if (err) {
      console.error('Test failed!');
    } else {
      console.log('Test succeeded!');
    }
  }
}
```

A little better, but still not useful, we don't want to manually run the runner once for each test don't we?

A useful little trick here, inspired by the middleware queue in [Express](http://expressjs.com/), is to wrap the test picking and execution in a function called `next` which will be passed as the `done` callback to all tests until there are no tests left. Like this:

```javascript
function run () {
  var i = 0; // Move this in here, so it resets on each run...
  next(); // Start runner...
  function next (err) {
    var testToRun = tests[i++];
    // Stop test runner on error or when no tests are left:
    if (err || !testToRun) return done(err);
    try {
      testToRun.test(next);
    } catch (err) {
      next(err);
    }
  }
  function done (err) {
    if (err) {
      console.error('Tests failed!');
    } else {
      console.log('Tests succeeded!');
    }
  }
}
```

That's better! Now at least all tests will be run, by calling `run()` just once.

### It's all about presentation

This test runner works, but it does not give you any information of what succeeded and what failed. We need to fix that:

```javascript
function run () {
  var i = 0;
  var testToRun; // Move this here, to get info about last test later...
  next(); // Start runner...
  function next (err) {
    if (testToRun) {
      // Show status for last test run:
      if (err) {
        console.error('✘ ' + testToRun.name);
      } else {
        console.log('✔ ' + testToRun.name);
      }
    }
    testToRun = tests[i++];
    // Stop test runner on error or when no tests are left:
    if (err || !testToRun) return done(err);
    try {
      // Calling `call` makes a better stack trace:
      testToRun.test.call(testToRun.test, next);
    } catch (err) {
      next(err);
    }
  }
  function done (err) {
  	// Show all remaining tests as skipped:
    tests.slice(i).map(function (skippedTest) { console.log('-', skippedTest.name); });
    if (err) {
      console.error('\nTests failed!\n' + err.stack); // Add stack trace to output...
    } else {
      console.log('\nTests succeeded!');
    }
  }
}
```

That's more like it!

But, there is still one problem. I said *20 lines of code*, and this is a total of 36 including comments, so there's still some refactoring that can be done.

### Wrapping it up

Let's save some lines by removing all comments and refactor some bits and pieces to oneliners, like so:

```javascript
function run () {
  var i = 0, testToRun;
  (function next (err) {
    if (testToRun) console[err ? 'error' : 'log'](err ? '✘' : '✔', testToRun.name);
    if (err || !(testToRun = tests[i++])) return done(err);
    try {
      testToRun.test.call(testToRun.test, next);
    } catch (err) {
      next(err);
    }
  })();
  function done (err) {
    tests.slice(i).map(function (skippedTest) { console.log('-', skippedTest.name); });
    console[err ? 'error' : 'log']('\nTests ' + (err ? 'failed!\n' + err.stack : 'succeeded!'));
  }
}
```

Including the `tests` array declaration and the `test` function, for adding tests, it sums up to **20 lines!** How about that :)

Finally [here's a gist with the complete version](https://gist.github.com/joakimbeng/8f57dae814a4802e2ae6) including a basic module wrapper and a runnable usage example.

All the best!
