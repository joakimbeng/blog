**For quite awhile now I've been thinking** about creating a blog where I could share my thoughts about anything, and particularly coding & development...

As I'm really into *javascript* nowadays I was very glad to see the [public launch of Ghost](http://blog.ghost.org/public-launch/) which is the blog platform that this one is built with.

And here's how I got it up and running:

## Ghost + Appfog
I decided that I wanted to host my blog on [Appfog](http://appfog.com) because I think it's a good and easy to use service, moreover I've discovered that they have a great uptime using another useful service [Pingdom](http://pingdom.com).

### Making Ghost work on Appfog

#### Ignore NodeJS 0.10 requirement
Currently Appfog doesn't support NodeJS 0.10 which Ghost claims it needs, but fear not! Just comment out these lines in `./core/server.js` (starting at line 382):

        if (!semver.satisfies(process.versions.node, packageInfo.engines.node)) {
            console.log(
                "\nERROR: Unsupported version of Node".red,
                "\nGhost needs Node version".red,
                packageInfo.engines.node.yellow,
                "you are using version".red,
                process.versions.node.yellow,
                "\nPlease go to http://nodejs.org to get the latest version".green
            );

            process.exit(0);
        }

And remove line 9-11 in `./package.json`:

    {
      // these lines:
      "engines": {
        "node": ">=0.10.* <0.11.4"
      },
      // ...
    }

**N.B** Probably Ghost has a good reason for the 0.10 requirement, but I haven't found anything that doesn't work yet. *Please let me know me if you do!*

#### Change DB to MySQL
Ghost uses Sqlite by default but have support for MySQL as well, which Appfog does too. I followed [this post at Codeforest](http://www.codeforest.net/ghost-blogging-platform-review) and adapted it to Appfog like this:

Add a MySQL service to your Appfog application, then modify `./config.js` lines 4-5 to this:

    var path = require('path'),
        mysql = process.env.NODE_ENV === 'production' ? JSON.parse(process.env.VCAP_SERVICES)["mysql-5.1"][0].credentials : {},
        config;

And then under the `production` config section set the database configuration to the following:

    database: {
        client: 'mysql',
        connection: {
            database: mysql.name,
            host: mysql.host,
            user: mysql.user,
            password: mysql.password
        },
        debug: false
    },

Also don't forget to install `mysql` module with:

    npm install mysql

### Profit
That's it, now you can run:

    af update <your_app_name>

And it should work!

**Happy blogging!**
