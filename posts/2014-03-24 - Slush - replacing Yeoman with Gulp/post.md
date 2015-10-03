When I first came across [Grunt](http://gruntjs.com) I thought it was a great tool, and it certainly was! Until I started to develop and maintain some grunt plugins of my own. Then I felt that the API was not intuitive enough for a smooth development cycle.
It got even worse when I began maintaining my own huge gruntfile in my [Yeoman](http://yeoman.io) MEAN app generator ([generator-klei](http://github.com/klei/generator-klei)).

## Gulp to the rescue
Then came [Gulp](http://gulpjs.com) and I instantly felt that it was not only a great tool, but even a superb one! I really like the "code before configuration" mantra and even more so the advocacy of DRYness when developing plugins.

### Easier to maintain
The gulp version of my `generator-klei` is under development (take a look at the [gulp branch](https://github.com/klei/generator-klei/tree/gulp) if you're intrested) and I've gone from 600 lines of gruntfile to a 300 lines long gulpfile with maintained functionality!

## Back to the point
When developing the Yeoman generator I discovered it wasn't only the gruntfile that was hard to maintain, but also the generator itself. So a couple of weeks ago I began thinking of how to replace Yeoman with something simpler.

### Main features of a generator
First I listed all the features of a Yeoman generator, the features that I'm using anyway:

1. Copying a project structure (with folders and everything)
2. Prompting the user for some project options
3. Templating some of the project files depending on the prompt answers
4. Auto-installing needed dependencies for the generated project
5. Prompting which files to overwrite (when running the generator a second time)

### Gulp as a generator
So I thought, wouldn't this be a great use for gulp?

Let's see what it handles out of the box:

1. Supported natively by [`gulp.src`](https://github.com/gulpjs/gulp/blob/master/docs/API.md#gulpsrcglobs-options)
2. One could use [`inquirer`](https://github.com/SBoudrias/Inquirer.js) directly for this
3. For instance [`gulp-template`](https://github.com/sindresorhus/gulp-template) does this
4. Missing. Could easily be implemented as a gulp plugin *(see below)*
5. Missing. Could easily be implemented as a gulp plugin *(see below)*

As you see, gulp can already act as a simple project generator!

#### A basic Gulp project scaffolding example
Let's say we have a directory structure for our first simple generator like this:

```
my-basic-generator/
├── app
│   └── templates           # This contains the app template
│       ├── gulpfile.js
│       ├── index.html
│       └── package.json
├── generator-gulpfile.js
└── package.json
```

Then we'll create a gulpfile made for scaffolding purposes, `generator-gulpfile.js`:

```javascript
var gulp = require('gulp'),
    template = require('gulp-template');

gulp.task('default', function () {
  return gulp.src(__dirname + '/app/templates/**') // Notice the `__dirname` here
    .pipe(template({})) // Empty data for now
    .pipe(gulp.dest('./')); // Relative to cwd
});
```

We can then scaffold our project into current working directory like this:

```bash
/path/to/my-basic-generator/node_modules/.bin/gulp --gulpfile /path/to/my-basic-generator/generator-gulpfile.js --cwd .
```

Alright! As you can see, there's a lot we can do with Gulp already, but it's not that convenient yet - let's change that!

## Introducing Slush - the streaming scaffolding system
To make it easier to use a project generator built with Gulp I've built [Slush](http://slushjs.github.io/generators). Slush locates all installed Gulp built project generators, from now on called "slush generators", and makes it possible to run such a generator without the need to specify it's location, like this:

```bash
slush <generator name> [<generator task>]
```

Slush can, and should be, installed globally with:

```bash
npm install -g slush
```

### Slush generators
Slush itself does not depend on Gulp but each generator must have Gulp as a dependency for this to work, Slush will run the Gulp module local to the generator.

A slush generator should have the `"slushgenerator"` keyword in its `package.json` and should be named `slush-<generator-name-dashed>`, e.g. "slush-angular".

To make a slush generator locatable for the Slush CLI it must be installed globally, e.g:

```bash
npm install -g slush-angular
```

### The slushfile
To distinguish between the scaffolding gulpfile and an ordinary gulpfile used for development the former should be named `slushfile.js`. There's no difference between an ordinary gulpfile and the slushfile in how you write it, but only how you use it.

All gulp plugins used within a generator's slushfile must be installed as ordinary project dependencies, i.e. *not* `devDependencies`.

### Making a complete Yeoman like Slush generator
As you may remember I earlier in the post listed some features of a Yeoman generator that was not currently available natively in gulp or via plugins, which was:

* Auto-installing needed dependencies for the generated project
* Prompting which files to overwrite (when running the generator a second time)

So I decided to build two gulp plugins to handle this.

#### Install project dependencies with [`gulp-install`](https://github.com/slushjs/gulp-install)
If the file stream contains a `package.json` file the plugin will trigger a call to `npm install` in the scaffolded project, and similar if it contains a `bower.json` file it will run `bower install`.

#### Prompt before overwrite with [`gulp-conflict`](https://github.com/slushjs/gulp-conflict)
Based on [Yeoman's internal conflicter](https://github.com/yeoman/generator/blob/master/lib/util/conflicter.js) the `gulp-conflict` plugin will prompt what to do when files in stream is conflicting with files in the given destination directory.

### A complete Slush generator example
Let's revisit the basic gulp generator example from above and make it a complete slush generator with prompt, autoinstall and everything.

We still have the same directory structure:

```
slush-basic/                # By convention
├── app
│   └── templates           # This contains the app template
│       ├── gulpfile.js
│       ├── index.html
│       └── package.json
├── slushfile.js            # By convention
└── package.json
```

And here's the content of our `slushfile.js`:

```javascript
var gulp = require('gulp'),
	install = require('gulp-install'),
    conflict = require('gulp-conflict'),
    template = require('gulp-template'),
    inquirer = require('inquirer');

gulp.task('default', function (done) {
  inquirer.prompt([
    {type: 'input', name: 'name', message: 'Name for the app?'}
  ],
  function (answers) {
    gulp.src(__dirname + '/app/templates/**') // Relative to __dirname
      .pipe(template(answers))
      .pipe(conflict('./'))
      .pipe(gulp.dest('./')) // Relative to cwd
      .pipe(install())
      .on('finish', function () {
        done(); // Finished!
      });
  });
});
```

**There you have it!** We can then install our new generator with:

```bash
npm install -g slush-basic   # if it's published
# or
npm link .                   # for development
```

And use it with:

```bash
slush basic
```

**Done!** As you can see, with just a few lines of gulp goodness we have recreated the functionality of a Yeoman generator.

## Final words
This is just the first version of Slush and I've probably missed something useful in the whole Yeoman generator workflow, please feel free to comment and contribute!

### Build generators
I would like to see as many useful generators out there as possible. I know I'll be using this instead of Yeoman from now on anyway...

### It's Gulp
Also remember that Slush comes with no functionality of its own, the only thing it provides is a convention and convenience of running global gulpfiles (in this case slushfiles) with the purpose of scaffolding projects, or anything else useful for that matter. So if something is missing it should probably be implemented as a gulp plugin.
