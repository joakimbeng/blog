This is another post in my series of ”20 lines of code” posts. For the previous ones see:

- [A JavaScript router in 20 lines](https://joakim.beng.se/blog/posts/a-javascript-router-in-20-lines.html)
- [A JavaScript test runner in 20 lines](https://joakim.beng.se/blog/posts/a-javascript-test-runner-in-20-lines.html)

## What’s memoization and what’s special about React’s useMemo?

[Memoization](https://en.wikipedia.org/wiki/Memoization), in short, is used to cache function results given its input to avoid expensive computations. React's [`useMemo`](https://reactjs.org/docs/hooks-reference.html#usememo) is a special kind of memoization function as it does not re-run the “expensive computation” based on its input but on an explicit list of dependencies, which should be set to all variables that the memoized function depends on/uses.

Let’s demonstrate the difference with an example...

**Example of memoization tracking its input:**

```javascript
let a = [1, 2, 3];
const expensive = (b) => {
  return a.reduce((sum, val) => sum * b + val, 0);
};
const expensiveMemoized = memoize(expensive);
expensiveMemoized(2);
// => 12 (not in cache)
expensiveMemoized(2);
// => 12 (from cache)
a = [...a, 4];
expensiveMemoized(2);
// => 12 (from cache, because "a" is not part of the function's input)
```

**Example using useMemo:**

(ignore the fact that `useExpensive` should be used within a component or other hook)

```javascript
const useExpensive = (a, b) => {
  const result = useMemo(() => {
    return a.reduce((sum, val) => sum * b + val, 0);
  }, [a, b]);

  return result;
};

let a = [1, 2, 3];
useExpensive(a, 2);
// => 12 (not in cache)
useExpensive(a, 2);
// => 12 (in cache)
a = [1, 2, 3, 4];
useExpensive(a, 2);
// => 20 (not in cache)
```

As you can see the `useMemo` function re-runs the expensive function when any of its dependencies (`a` and `b` in this case) changes. Another special thing about React’s `useMemo` is the fact that it memoizes the function result per component instance that uses it, i.e. the following code runs the ”expensive calculation” twice even though the parameters are the same and they get the same result:

```javascript
const Comp = ({ a, b }) => {
  const result = useExpensive(a, b);
  return <p>One: {result}</p>;
};

const a = [1, 2, 3];
const App = () => {
  return (
    <div>
      <Comp a={a} b={2} />
      <Comp a={a} b={2} />
    </div>
  );
};
```

The same is also true if two different components uses the same hook.

Enough about the existing `useMemo` and let’s write some code to built it ourselves!

## Let’s make our own memoization hook

The key part of memoization is to know when to discard an old value and re-run the memoized function. To do that we have to check if any of the specified dependencies have changed, which can be done using the following naive approach:

```javascript
let lastDeps = null;
let lastValue;

const useMemo = (func, deps = []) => {
  if (lastDeps === null || deps.some((dep, i) => dep !== lastDeps[i])) {
    lastDeps = deps;
    return (lastValue = func());
  }
  return lastValue;
};
```

I said “naive” because this implementation has a big drawback - it can’t be reused! E.g:

```javascript
const a = 4;
useMemo(() => a ** 2, [a]); // => 16
useMemo(() => a * 2, [a]); // => 16, because the dependencies hasn't changed, but our function has...
```

We therefore have to track the function somehow. A simple solution would be to add the function as a dependency and compare it as well:

```javascript
let lastDeps = null;
let lastValue;

const useMemo = (func, deps = []) => {
  const newDeps = [func, ...deps];
  if (lastDeps === null || newDeps.some((dep, i) => dep !== lastDeps[i])) {
    lastDeps = newDeps;
    return (lastValue = func());
  }
  return lastValue;
};
```

That will solve our previous issue, but will cause another... Using this implementation of `useMemo` inside a component will trigger a re-run of the function on every render, for instance a component such as:

```javascript
const Comp = () => {
  const result = useMemo(() => 1000 ** 5, []);
  return <p>{result}</p>;
};
```

Every time `Comp` is rendered the `() => 1000 ** 5` function is recreated, which means it will never make our comparison with `newDeps` be true and the function will be re-run all the time.

### Tracking the memoized function

To solve this we need a way to see if a function is unchanged without relying on its reference, as the reference is changed on every render. One approach would be to convert the function to a string and see if the string has changed, but I’m afraid that will only work in simple scenarios. Consider the following:

```javascript
// in Component.js:
const doSomething = () => {
  return 1000 ** 5;
};

const result = useMemo(() => doSomething(), []); // (1)

// in OtherComponent.js:
const doSomething = () => {
  return 1000 + 5;
};

const result = useMemo(() => doSomething(), []); // (2)
```

As you can see in the snippet above the statements **(1)** and **(2)** looks the same and would be the same if we cast the memoized functions to strings, even though `doSomething` is different in the two files. So we need something else that we can use as a stable reference to our memoized functions, even when they are recreated on every render.

React has solved this by tracking the order of called hooks per component instance, which is exactly why there are [Rules of Hooks](https://reactjs.org/docs/hooks-rules.html), because if that order would change the results would be mixed and unexpected. The solution I've come up with is different and thanks to that will have some less strict rules as you’ll see.

My solution is based on the fact that there is one thing that’s always constant for each invocation of `useMemo` in your code - its call site, i.e. the place in the code like the file, line and column number from where the function is called. So how can we get that information without any extra tooling? ([`function.caller`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/caller)is deprecated and doesn’t work anymore)

A simple trick to get a function’s call site is to get hold of a stack trace and get the information from there (see potential caveats of this approach in the bottom of the post).

```javascript
const getCallSite = (depth) => {
  const { stack } = new Error("getting call site");
  return stack.split("\n")[depth];
};

const A = () => {
  console.log(getCallSite(2));
};
const B = () => {
  console.log(getCallSite(2));
};

A();
// at A (.../index.js:7:15)
B();
// at B (.../index.js:10:15)
```

I’m passing a `depth` of `2` because the first line of a stack trace (index = 0) is usally the error message (“getting call site" in this case), the second line (index = 1) is the actual `getCallSite` function and in this case the third line (index = 2) is our functions `A` and `B` .

Let’s use this new `getCallSite` function to improve the `useMemo` implementation. You'll notice in the code that I've increased the depth to `3` because here the third line of the stack trace (index = 2) corresponds to our `useMemo` function and we care for from where it was called and not declared so we have to check the next line of the stack trace:

```javascript
const lastDeps = new Map();
const lastValue = new Map();

const getCallSite = (depth) => {
  const { stack } = new Error("getting call site");
  return stack.split("\n")[depth];
};

const useMemo = (func, deps) => {
  const callSite = getCallSite(3);
  if (!lastDeps.has(callSite) || lastDeps.get(callSite).some((dep, i) => dep !== deps[i])) {
    lastDeps.set(callSite, deps);
    const value = func();
    lastValue.set(callSite, value);
    return value;
  }
  return lastValue.get(callSite);
};
```

One could think that we would be done here, but this version still has some issues. The problem is that the cache only stores one value per call site, which means that a scenario like the following will never re-use anything from the cache:

```javascript
const Child = ({ val }) => {
  const result = useMemo(() => val ** 5, [val]);
  return <p>{result}</p>;
};

const Parent = () => {
  return (
    <div>
      <Child val={1} />
      <Child val={2} />
    </div>
  );
};
```

On first render when `<Child val={1} />` is rendered there's nothing in the cache so the memoized function will be run and when `<Child val={2} />` is rendered there's nothing in the cache for `val=2` so the memoized function will be run again. On the next render when `<Child val={1} />` is rendered again there is nothing in the cache for `val=1` so the memoized function is re-run, and so on…

### Caching multiple values

To remedy this issue we’ll have to store multiple values per call site. Instead of using only the call site as the key for `lastValue` we'll generate a key from both the call site and the current dependencies.

How do we generate a good lookup key out of an array of dependencies? Would [JSON.stringify()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify) do? No, it can't handle functions or circular data structures for instance. But by using its `replacer` option and a neat use of [WeakMap](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap) we get a memory efficient key generator:

```javascript
let keys = new WeakMap();
let i = 0;
const getKeySet = (arr) =>
  JSON.stringify(arr, (_, val) => {
    // val !== arr -- because we ignore the dependency array itself
    // typeof val === "object" -- because only objects can be used as keys in a WeakMap
    // val !== null -- because typeof null === "object" :P
    if (val !== arr && typeof val === "object" && val !== null) {
      if (!keys.has(val)) {
        keys.set(val, `$$obj${i++}`);
      }
      return keys.get(val);
    }
    return val;
  });

// Example usage:
const a = {};
const b = {};
getKeySet([a, 10]); // ["$$obj0", 10]
getKeySet([b, 10]); // ["$$obj1", 10]
getKeySet([true, b, a]); // [true, "$$obj1", "$$obj0"]
```

Let’s use this key generator in our `useMemo` implementation:

```javascript
const values = new Map();
const keys = new WeakMap();
let i = 0;
const getKeySet = (arr = []) =>
  JSON.stringify(arr, (_, val) => {
    if (val !== arr && typeof val === "object" && val) {
      if (!keys.has(val)) {
        keys.set(val, `$$obj${i++}`);
      }
      return keys.get(val);
    }
    return val;
  });
const getCallSite = (depth) => new Error("getting call site").stack.split("\n")[depth];
const useMemo = (func, deps) => {
  const key = `${getCallSite(3)}|${getKeySet(deps)}`;
  if (!values.has(key)) {
    values.set(key, func());
  }
  return values.get(key);
};
```

**That’s it, our own `useMemo` hook is complete!** I made the `getCallSite` function a one-liner to land on a total of exactly 20 lines of code as I promised (alright 21 after [Prettier](https://prettier.io) has done its deal).

## Pros and cons over React’s useMemo

One downside of this solution is that it can be expensive performance-wise to generate a stack trace, although under normal circumstances it should take less than a millisecond. Another thing about getting the call site is that the stack trace format is not standardized, even though most browsers have a similar format, so our `getCallSite` function can either crash, in case `error.stack` is not a string, or give the wrong result (see [Error.prototype.stack](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/Stack) for more info).

Another caveat is that cached values are never cleared, so unused values for key sets that don’t even exist anymore because of garbage collected objects will still be stored in memory. Switching the `const values = new Map()` to a Least Recently Used Cache (e.g. [lru-cache](https://www.npmjs.com/package/lru-cache) ) would solve this in a configurable manner.

There is also a potential issue if a dependency is a string with a value colliding with an existing `$$objN` key, a fix for that would be to replace the outer `JSON.stringify` with an ordinary `Array.map` and only stringify the non-objects like so:

```javascript
const getKeySet = (arr = []) =>
  arr
    .map((val) => {
      if (typeof val === "object" && val) {
        if (!keys.has(val)) {
          keys.set(val, `$$obj${i++}`);
        }
        return keys.get(val);
      }
      return JSON.stringify(val);
    })
    .join(",");
```

On the plus side, as I mentioned earlier, this solution doesn’t have the same strict rules as React’s hooks has, for instance this `useMemo` can be used both _outside components and conditionally_, thanks to the fact that the call site is constant even for conditional calls.

Another advantage is that memoized values will be shared across component instances as long as they have the same dependencies.

## Final words

I hope you enjoyed this journey of writing a `useMemo` hook from scratch, I know I did! You should know that the hook has not been battle tested in a real app so there could be other issues with it apart from the small downsides in the previous section.

If you have any questions, suggestions or anything else don’t hesitate to reach out!

**Until next time!** / [@joakimbeng](https://twitter.com/joakimbeng)
