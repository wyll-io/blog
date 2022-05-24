---
title: "Build and deploy a Golang application to Docker Hub"
date: 2022-01-15
tags: ["docker", "golang", "dev"]
author: "François ALLAIS"
draft: true
---

In this article, you will learn a very basic example of how to build, test and deploy a Golang application into the Docker Hub. To do so we will use the Github Actions.

# The Github repository

I assume that you created the Github repository, added a README, etc.. For this post, I will call the application `awesomeapp`.

# The Golang application

Let's create a very basic Web application with Golang that will sum two integers and display the result into the browser.

```go
package main

import (
  "fmt"
  "log"
  "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
  fmt.Fprintf(w, sum(1,2))
}

func sum(a, b int) int {
  return a + b
}

func main() {
  http.HandleFunc("/", handler)
  log.Fatal(http.ListenAndServe(":8000", nil))
}
```

This very simple application will basically print `Hello World` on a Web page.

# Do not forget the tests

Let's write some basic tests for the `sum()` function.

```go
package main

import (
  "testing"
)

func TestSum(t *testing.T) {
  if sum(1,1) != 2 {
    t.Fatalf(`should be 3 but got %d`, sum(1,1))
  }
}
```

# The Dockerfile

At the root of the projet, we also need to add a **Dockerfile**:

```Dockerfile
FROM golang:latest as builder
WORKDIR /go/src/awesomeapp
ADD . /go/src/awesomeapp
RUN go get -d -v ./...
RUN go build -o /go/bin/awesomeapp

FROM gcr.io/distroless/base-debian10
COPY --from=builder /go/bin/awesomeapp /
CMD [ "/awesomeapp" ]
```

# Deploy it !

```yaml
name: Deploy to Docker registry

on:
  push:

jobs:
  push_to_registry:
    name: Push Docker image to Docker Hub
    runs-on: ubuntu-latest
    steps:
      - name: Check out the repo
        uses: actions/checkout@v2
      
      - name: Log in to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@v3
        with:
          images: username/awesomeapp
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v3
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```