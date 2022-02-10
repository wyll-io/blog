# How did we

# The blog : Hugo, not Wordpress

The aim of this blog is to share technical skills and experiences within a website that can be read either on a computer, a mobile, etc.. That being said, there is no need to use a CMS such as Wordpress as it would be totally overkilled because it rely on a complex tool and an interpreted langage (PHP). It can simply be a static website. For the comments, let's use a SaaS, for example [Disqus](https://disqus.com).

That is why we chose to use [Hugo](https://hugo.io).

# The deployment : Github Actions and AWS

We considered two choices regarding the deployment to AWS : *S3 bucket* or *ECS*. The S3 bucket solution appears to be cheaper as the ECS would need the instance to be always alive. The S3 just serve files, that is exactly what the website is, just files.

That being said, we need to generate the static files and sync them into out S3 bucket. This will be done by Github Actions.

```yaml
name: Build and deploy

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
      run: aws s3 sync --delete --acl public-read ./public s3://blog.wyll.io
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_DEFAULT_REGION: 'eu-west-3'
```

And that's all ! :)

# AWS Cloudfront and Route 53

TBD.