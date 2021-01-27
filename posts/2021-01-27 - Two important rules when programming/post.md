The following rules are two of the most important rules to follow when writing code in my opinion. They apply both if you’re in a team or in a one-person project.

## Rule 1 - Write for the next developer

The next developer reading your code can either be yourself or someone else, make that person a great service by making your code readable. Usually you read more code than you write, so if you have to write some more code to make it more readable that’s worth it.

### Some practical tips on writing more readable code

- Use a linter with some recommended/common configuration, for instance [Eslint](https://eslint.org) and [eslint-config-airbnb](https://www.npmjs.com/package/eslint-config-airbnb)
- Use code formatting tools like [Prettier](https://prettier.io)
- Use linting and code formatting rules that yields smaller git diffs, e.g.§§ always trailing commas and always parentheses around function parameters
- Never write one-line if statements, i.e. those without `{` and `}`
- Prefer if statements before nested ternary operators
- Never use negated or negative words in variable names, i.e. prefer `isEnabled` and `isValid` over `isDisabled` and `isWrong`. Why? Because sooner or later you’ll end up with statements that take some time to digest like: `if (isInvalid !== true && !disallowedToSave) { ...`
- If you still think your code isn’t perfect from a reader’s perspective, or you don’t have the time or mind to do it right now, add some automated tests that verifies the functionality and perhaps enhance the code with some descriptive [JSDoc](https://jsdoc.app) comments

The focus you should have when improving readability of code is primarily so that the next developer understands your code faster, in case that person has to debug it.

## Rule 2 - Leave the code better than when you found it

Also known as the “scouts rule”. Improving the code quality in a large code base all at once is very time consuming. It’s cheaper and easier to aim for “Eventual Good Code Quality”, i.e. while you’re adding some new feature or fixing a bug in a file take the time to also improve the code quality of that same file. You don’t have to fix all issues at once, one change for the better is better than none.

### Some quick wins when improving code quality

- Rename variables or functions for clarity and easing the reading experience
- When you’re debugging some hard to read code, once you understand it, add automated tests for it to aid the next developer
- Refactor hard to follow statements or conditions into separate functions with descriptive names, e.g. instead of `if (name && name.length > 0 && hasAccess(userId, parentId)) {` do `if (canSave()) {`
- Remove unused code

## Conclusion

_Readability, readability, readability!_ Readable code is more important than fast written code.

If you keep **Rule 1** in mind all the time and apply those guidelines when you’re changing old code you get **Rule 2** for free.

[Follow me on Twitter](https://twitter.com/joakimbeng) for more insights like this!
