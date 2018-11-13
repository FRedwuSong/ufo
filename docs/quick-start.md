---
title: Quick Start
---

In a hurry? No sweat! Here's a quick start to using ufo that takes only a few minutes. For this example, we will use a sinatra app from [tongueroo/demo-ufo](https://github.com/tongueroo/demo-ufo).  The `ufo init` command sets up the ufo directory structure in your project. The `ufo ship` command deploys your code to an AWS ECS service.  The `ufo ps` and `ufo scale` command shows you how to verify and scale additional containers.

    gem install ufo
    git clone https://github.com/tongueroo/demo-ufo.git demo
    cd demo
    ufo init --image=tongueroo/demo-ufo # NOTE: use your own account
    ufo current --service demo-web
    ufo ship
    ufo ps
    ufo scale 2

Note: The example pushes the Docker image to Dockerhub account. You need push access the repo. So, you will need to an account that you have access to. You can control that with the `--image` option.  Example:

    ufo init --image=yourusername/yourrepo # use your own account

Also, if you are using ECR instead, you can specific an ECR repo with the `--image` option.  Example:

    ufo init --image 123456789012.dkr.ecr.us-west-2.amazonaws.com/myimage

For more info, refer to the [ufo init](http://ufoships.com/reference/ufo-init/) reference docs.

## What Happened

The `ufo ship demo-web` command does the following:

1. Builds the Docker image and pushes it to a registry
2. Builds the ECS task definitions and registry them to ECS
3. Updates the ECS Service

You should see something similar to this:

```
$ ufo init --app=demo --image=tongueroo/demo-ufo
Setting up ufo project...
      create  .env
      create  .ufo/settings.yml
      create  .ufo/task_definitions.rb
      create  .ufo/templates/main.json.erb
      create  .ufo/variables/base.rb
      create  .ufo/variables/development.rb
      create  .ufo/variables/production.rb
      create  Dockerfile
      create  bin/deploy
      append  .gitignore
Starter ufo files created.
$ ufo ship demo-web
Building docker image with:
  docker build -t tongueroo/demo-ufo:ufo-2017-09-10T15-00-19-c781aaf -f Dockerfile .
....
Software shipped!
$ ufo ps
+----------+------+-------------+---------------+---------+-------+
|    Id    | Name |   Release   |    Started    | Status  | Notes |
+----------+------+-------------+---------------+---------+-------+
| f590ee5e | web  | demo-web:85 | 1 minutes ago | RUNNING |       |
+----------+------+-------------+---------------+---------+-------+
$ ufo scale 2
Scale demo-web service in development cluster to 2
$
```

Congratulations! You have successfully deployed code to AWS ECS with ufo. It was really that simple 😁

Note: This quick start requires a working Docker installation.  For Docker installation instructions refer to to the [Docker installation guide](https://docs.docker.com/engine/installation/).

Learn more in the next sections.

<a id="next" class="btn btn-primary" href="{% link _docs/install.md %}">Next Step</a>
<p class="keyboard-tip">Pro tip: Use the <- and -> arrow keys to move back and forward.</p>

