---
title: "How do we build and deploy our blog ?"
date: 2022-02-10
tags: ["aws", "golang", "dev"]
author: "François ALLAIS"
draft: false
---

In this article, we will present you how we choose to deploy our blog by using DevOps approach.
<!--more-->

# Hugo, not Wordpress

The aim of this blog is to share technical skills and experiences within a website that can be read either on a computer, a mobile, etc.. That being said, there is no need to use a CMS such as Wordpress as it would be totally overkilled because it rely on a complex tool and an interpreted langage (PHP). It can simply be a static website. For the comments, let's use a SaaS, for example [Disqus](https://disqus.com).

That is why we chose to use [Hugo](https://gohugo.io).

# Writing articles

The writing of the articles is done very simply, each article is basically proposed by a **Pull Request**. The PR will check for spelling using a dedicated **Github Action**.

# The deployment

We considered two choices regarding the deployment to AWS : **S3 bucket** or **ECS**. The S3 bucket solution appears to be cheaper as the ECS would need the instance to be always alive. The S3 just serve files, that is exactly what the website is, just files, and with a **Cloudfront** endpoint for serving in HTTPS, it will do the job.

That being said, we need to generate the static files and sync them into out S3 bucket. This will be done by **Github Actions**.

Let's create the action configuration file.

## With the built-in Hugo deployment for AWS

How great it is, Hugo has a built-in solution for deploying to AWS S3 ! All we need to do is declare some information into the TOML configuration file:

```toml
[deployment]

[[deployment.targets]]
name = "your-name"
URL = "s3://[BUCKET_NAME]?region=eu-east-1"

[[deployment.matchers]]
pattern = "^.+\\.(js|css|svg|ttf)$"
cacheControl = "max-age=31536000, no-transform, public"
gzip = true

[[deployment.matchers]]
pattern = "^.+\\.(png|jpg)$"
cacheControl = "max-age=31536000, no-transform, public"
gzip = false

[[deployment.matchers]]
pattern = "^sitemap\\.xml$"
contentType = "application/xml"
gzip = true

[[deployment.matchers]]
pattern = "^.+\\.(html|xml|json)$"
gzip = true
```

and then we can create the Github Action as follow:

```yaml
name: Deploy

on:
  push:
    branches: [master]

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: peaceiris/actions-hugo@v2
    - name: Generate static files
      run: hugo --minify
    - name: Deploy to AWS S3
      run: hugo deploy --force --invalidateCDN
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## With the AWS CLI

```yaml
name: Deploy

on:
  push:
    branches: [master]

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: peaceiris/actions-hugo@v2
    - name: Generate static files
      run: hugo --minify
    - name: Upload to S3
      run: aws s3 sync --delete --acl public-read ./public s3://[BUCKET_NAME]
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_DEFAULT_REGION: 'eu-west-3'
```

This action will trigger on each push on the master branch, checkout code, generate the static files,  
And that's all ! :)

# AWS Cloudfront and DNS

Will be explained soon :)

 - S3 bucket
 - Cloudfront endpoint
 - SSL certificate