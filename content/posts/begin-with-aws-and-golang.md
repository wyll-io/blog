---
title: "Begin with AWS and Golang"
date: 2021-10-05
tags: ["aws", "golang", "dev"]
author: "François ALLAIS"
draft: true
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

Pour créer une table, il faut utiliser la fonction `PutItem`

```go
func (*dynamodb.Client).PutItem(ctx context.Context, params *dynamodb.PutItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.PutItemOutput, error)
```

Cette fonction prend comme arguments le contexte, les paramètres d'ajout et des éventuelles options. Créons les paramètres ci-dessous, sachant que les éléments suivants sont obligatoires :

- Item : l'élément à ajouter
- TableName : le nom de la table

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

Ensuite on peut créer la requête ci-dessous :

```go
// Put item into table
_, err = client.PutItem(context.TODO(), params)
if err != nil {
  log.Fatalf("error while puting item into table: %v", err)
}
```

Lancer le programme en laçant la commande `go run main.go example1 create`, vous devriez voir ceci :

```sh
go run main.go example1 put -t test
2021/10/06 17:46:17 Succesfully put item into table [test]
```

On peut confirmer sur la console AWS que l'on voit bien notre élément. On verra également juste ensuite comment confirmer cela en utilisant la librairie.

![Elements dans la table DynamoDB](/images/posts/elements-table-dynamodb.png)

## Chercher des éléments dans une table

Pour récupérer des éléments dans une table, il faut utiliser la fonction
```go
func (*dynamodb.Client).Scan(ctx context.Context, params *dynamodb.ScanInput, optFns ...func(*dynamodb.Options)) (*dynamodb.ScanOutput, error)
```

Comme d'habitude, elle prend un contexte et des paramètres, seul la valeur `TableName` est obligatoire. Mais ici nous allons tester de filtrer les résultats, pour cela, il faut ajouter une propriété `FilterExpression` qui est de type `*string` et qui contient votre expression.

Dans cette exemple, on va filtrer les éléments dont la proriété `name` contient `John` (on a ajouté un élément plus haut dans le tutoriel). La particularité de ce filtre est que `name` est un nom réservé, il faut donc utiliser une `ExpressionAttributeNames` pour le remplacer par `#n`. Ensuite, on va utiliser une `ExpressionAttributeValues` pour passer dynamiquement la valeur qui servira au filtre. Voici le récapitulatif ci-dessous :

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

On exécute ensuite la requête ci-dessous :

```go
// Scan the table
resp, err := client.Scan(context.TODO(), params)
if err != nil {
  log.Fatalf("failed to list tables: %v", err)
}
```

et on obtient, s'il n'y a pas d'erreur, une réponse de type `*dynamodb.ScanOutput`. Pour afficher tous les éléments, il faudra faire une boucle sur la propriété `resp.Items`, si on veut le total on peut utiliser `resp.Count` (total après application des filtres) ou `resp.ScannedCount` (total avant application des filtres). Par exemple :

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

## Pré-requis

Pour réaliser les étapes de ce tutoriel.