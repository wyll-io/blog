---
title: "Begin with AWS and Golang"
date: 2022-02-05
tags: ["aws", "golang", "dev"]
author: "François ALLAIS"
draft: false
---

# Tutorial objectives

You will discover how to use certain **AWS services (DynamoDB, S3, etc.)** with the **Golang** language. For this we will use the official Amazon library for Golang: `github.com/aws/aws-sdk-go-v2`.

# DynamoBD

DynamoDB is the Amazon's cloud service that offers non-relational **databases** (like MongoDB, RethinkDB, etc..), we will use the Golang library to create a database, list the values of a table, add and delete data.

## Prerequisites

You obviously need an account on the AWS console, and the necessary permissions for these examples:
- Permission to create a table
- ...
- ...

## Create a table

To create a table, use the function
```go
func (*dynamodb.Client).CreateTable(ctx context.Context, params *dynamodb.CreateTableInput, optFns ...func(*dynamodb.Options)) (*dynamodb.CreateTableOutput, error)
```

This function takes as arguments the context, the creation parameters and other non-mandatory options. Let's create the parameters below, knowing that the following are mandatory:

- AttributeDefinitions: attributes of the primary key
- KeySchema: primary key scheme
- TableName: the name of the table

We will also choose the `BillingModePayPerRequest` mode to simplify the exercise.

```go
// Set the parameters
keyName := "_id"
name := "test"
params := &dynamodb.CreateTableInput{
  AttributeDefinitions: []types.AttributeDefinition{
    {
      AttributeName: &keyName,
      AttributeType: types.ScalarAttributeTypeS,
    },
  },
  KeySchema: []types.KeySchemaElement{
    {
      AttributeName: &keyName,
      KeyType:       types.KeyTypeHash,
    },
  },
  TableName: &name,
  BillingMode: types.BillingModePayPerRequest,
}
```

Then we can create the following request:

```go
// Create the table
_, err = client.CreateTable(context.TODO(), params)
if err != nil {
  log.Fatalf("failed to list tables: %v", err)
}
```

Run the app by using that command `go run main.go example1 create`, you should see this :

```sh
go run main.go example1 create
2021/10/06 17:46:17 Successfully created table [test]
```

You can confirm that your table is created in the AWS console :

![Table créée](/images/posts/table-creee.png)

## Ajouter des éléments dans une table

To create a table, we must use the function `PutItem`:

```go
func (*dynamodb.Client).PutItem(ctx context.Context, params *dynamodb.PutItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.PutItemOutput, error)
```

This function takes as arguments the context, the addition parameters and any options. Let's create the parameters below, knowing that the following are mandatory:

- Item : the item to add
- TableName : the name of the table

```go
// Set the parameters
params := &dynamodb.PutItemInput{
  TableName: aws.String(tableName),
  Item: map[string]types.AttributeValue{
    "_id":        &types.AttributeValueMemberS{Value: "12346"},
    "name":       &types.AttributeValueMemberS{Value: "John Doe"},
    "email":      &types.AttributeValueMemberS{Value: "john@doe.io"},
    "age":        &types.AttributeValueMemberN{Value: "49"},
    "is_enabled": &types.AttributeValueMemberBOOL{Value: false},
  },
}
```


Then we can create the query below:

```go
// Put item into table
_, err = client.PutItem(context.TODO(), params)
if err != nil {
  log.Fatalf("error while puting item into table: %v", err)
}
```

Launch the program by running the command `go run main.go example1 create`, you should see this:

```sh
go run main.go example1 put -t test
2021/10/06 17:46:17 Succesfully put item into table [test]
```

We can confirm on the AWS console that we see our element. We will also see just then how to confirm this using the library.

![Elements dans la table DynamoDB](/images/posts/elements-table-dynamodb.png)

## Find elements in a table

To retrieve elements from a table, use the `Scan` function:

```go
func (*dynamodb.Client).Scan(ctx context.Context, params *dynamodb.ScanInput, optFns ...func(*dynamodb.Options)) (*dynamodb.ScanOutput, error)
```

As usual, it takes context and parameters, only the `TableName` value is required. But here we are going to test to filter the results, for that, you must add a `FilterExpression` property which is of the `*string` type and which contains your expression.

In this example, we will filter the elements whose `name` property contains `John` (we added an element earlier in the tutorial). The particularity of this filter is that `name` is a reserved name, so you have to use an `ExpressionAttributeNames` to replace it with `#n`. Then, we will use an `ExpressionAttributeValues` to dynamically pass the value that will be used for the filter. Here is the summary below:

```go
filterExpression := "contains(#n, :n)"
params := &dynamodb.ScanInput{
  TableName:        &tableName,
  FilterExpression: &filterExpression,
  ExpressionAttributeNames: map[string]string{
    "#n": "name",
  },
  ExpressionAttributeValues: map[string]types.AttributeValue{
    ":n": &types.AttributeValueMemberS{
      Value: "John",
    },
  },
}
```

Then run the query below:

```go
// Scan the table
resp, err := client.Scan(context.TODO(), params)
if err != nil {
  log.Fatalf("failed to list tables: %v", err)
}
```

and we get, if there is no error, a response of type `*dynamodb.ScanOutput`. To display all the items, you will have to loop on the `resp.Items` property, if you want the total you can use `resp.Count` (total after applying filters) or `resp.ScannedCount` (total before applying filters). For example :

```go
if resp.Count == 0 {
  log.Print("no item has been found")
} else {
  log.Printf("%d items has been found", resp.Count)
}

// Process the items
for _, item := range resp.Items {
  log.Print(item)
}
```

# Simple Service Storage (S3)

## Prerequisites

Soon be published !