As I said in my [previous post](https://joakim.beng.se/blog/posts/building-an-app-i-need.html) I’m about to build a new web app, and the first thing I will do is to decide what programming language to use. Previously you didn’t have much choice as to what language to pick, regarding the frontend anyway, but with the [wide support for WebAssembly](https://caniuse.com/wasm) and languages that can compile to it theese days you now have plenty to choose from.

The big benefit, as I see it, with using WebAssembly for the frontend is that you can use the same language for both the frontend and the backend.

## Should I go for high developer satisfaction?

At first I was thinking about writing the app in [Rust](https://www.rust-lang.org) so I spent a lot of time last summer reading the [Rust Book](https://doc.rust-lang.org/book/). I was leaning towards Rust mainly because of the [high developer satisfaction](https://insights.stackoverflow.com/survey/2020#technology-most-loved-dreaded-and-wanted-languages-loved) with it and its high performance.

For a while there I really had made up my mind. I was going to build my next app using Rust, I thought, but when I started playing out with it, that all changed.

I realized it would take quite some time for me to be productive in Rust, compared to [TypeScript](https://www.typescriptlang.org) (TS) or JavaScript. Nothing wrong with that and I would love to do a Rust project because I really like the language, but as I will be building an app on my spare time, which is quite limited nowadays, I want to be productive from the start.

> I never thought I would say this a couple of years ago about a typed language

With that realization I decided to go with TS for both frontend and backend. And regarding developer satisfaction I must say that, and I never thought I would say this a couple of years ago about a typed language, TS is the programming language I’m most satisfied with so far! The type inference, great intellisense/autocomplete, built-in utility types and union types are real time savers!

## Why I think types are good

When linters became the norm for JavaScript development it was so nice because it could catch common typos like:

```ts
const myFunc = (value) => {
  return valeu * 2;
}
```

And it could do so without any types. But the problem is that it can’t catch similar typos in nested properties:

```ts
cost myFunc = (obj) => {
  return obj.valeu * 2;
}
// or using destructuring
cost anotherFunc = ({usreId}) => {
  // many lines of code...
  doSomething(usreId); // here I even get autocomplete on that wrongly spelled "userId"
}
```

Such errors will be caught by the TypeScript type checker (in almost real time in your editor) which is so nice, because IMO one of the most common uncaught errors are caused by typos like that especially after a big refactor (if you don’t have almost 100 % test coverage, which I admit I never have). Features like that helps out a lot, even in a one person project!

### What frameworks to pick then?

Now that I’ve settled on a programming language it’s time to select the framework(s) to use. What that’ll be you’ll read about in an upcoming post!
