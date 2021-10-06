---
title: "Débuter avec AWS et Golang"
date: 2021-10-05T08:47:11+01:00
tags: ["aws", "golang"]
author: "François ALLAIS"
draft: false
---

# Objectifs du tutoriel

Vous allez découvrir comment utliser certains **services AWS (DynamoDB, S3, etc..)** avec le langage **Golang**. Pour cela nous allons utiliser la librairie officielle d'Amazon pour Golang : `github.com/aws/aws-sdk-go-v2`. C'est la version 2 qui sera utilisée.

# DynamoBD

DynamoDB est le service cloud d'Amazon qui propose des **bases de données** non relationnelles (comme MongoDB, RethinkDB, etc..), nous allons utiliser la librairie Golang pour créer une base de données, lister les valeurs d'une table, ajouter et supprimer de la donnée.

## Pré-requis



## Créer une table

Pour créer une table, il faut utiliser la fonction
```go
func (*dynamodb.Client).CreateTable(ctx context.Context, params *dynamodb.CreateTableInput, optFns ...func(*dynamodb.Options)) (*dynamodb.CreateTableOutput, error)
```

Cette fonction prend comme arguments le contexte, les paramètres de création et des éventuelles options. Créons les paramètres ci-dessous, sachant que les éléments suivants sont obligatoires :

- AttributeDefinitions : attributs de la clef primaire
- KeySchema : schéma de la clef primaire
- TableName : le nom de la table

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
}
```

## Ajouter des éléments dans une table

Pour créer une table, il faut utiliser la fonction
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
    "_id":   &types.AttributeValueMemberS{Value: "12346"},
    "name":  &types.AttributeValueMemberS{Value: "John Doe"},
    "email": &types.AttributeValueMemberS{Value: "john@doe.io"},
  },
}
```

On peut ensuite lancer la requête ci-dessous :

```go
// Put item into table
_, err = client.PutItem(context.TODO(), params)
if err != nil {
  log.Fatalf("error while puting item into table: %v", err)
}
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