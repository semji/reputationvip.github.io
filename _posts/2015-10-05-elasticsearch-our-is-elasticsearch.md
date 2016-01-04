---
layout: post
author: quentin_fayet
title: "Our is the Elasticsearch"
excerpt: "This third article about Elasticsearch will go with //TODO FINISH IT"
modified: 2015-10-05
tags: [elasticsearch, fullt-text research, apache, lucene, routing]
comments: true
image:
  feature: elastic-always-pays-its-debts-ban.jpg
  credit: Alban Pommeret
  creditlink: http://reputationvip.io
---

#TODOS

- Complete excerpt with the content of the article
- Complete tags
- Write conclusion
- Charlotte review
- Re-check queries (execute them in term)
- check //TODOS
- check !, :, ?
- Complete introduction with blabla about the github repository containing the docker cluster (v3)

# OUR IS ELASTICSEARCH

Welcome back! This article, the third one over my set of articles about Elasticsearch, will introduce you some more advanced concepts
about Elasticsearch.

In the two last articles, I guided you through the basic configuration of an Elasticsearch cluster, how to configure it, how to do mapping,
how to perform CRUD operations, and finally, how to execute simple full-text search queries.

If you don't remember well about these notions, I recommend you to read the previous articles:

- [Elasticsearch Is Coming](http://reputationvip.io/elasticsearch-is-coming/)
- [Elasticsearch Always Pays Its Debts](http://reputationvip.io/elasticsearch-always-pays-its-debts/)

## ROADMAP

As I just said, this article adds itself to the two previous ones. Without no more waiting, let's take a look at the menu.

- **Routing** will be the first subject I will talk about in this article. I will detail you why and how your can configure
the way your data are spread among the cluster.
- **Parent-child relationships** and **nested objects** will be my second subject. Indeed, we haven't go through every Elasticsearch data types yet.
- **Scoring** will be my third theoretical subject. I will detail you how much the choice of a scoring function is important.
- **Compound Queries** allow you to combine multiple queries, or to alter the result of other queries.
- **Scripting** will be at the end of this article... And honestly, I can't wait to talk about it!

Ok, Elasticsearch fans, get ready to dive even deeper in the fabulous world of Elasticsearch!

# Routing

Here we are, back in some theoretical notions for a while.

The first notion I will talk about is **routing**.

## The "classical" routing

In a "classical" normal configuration, Elasticsearch would evenly **dispatch the indexed documents among all shards** that compose
an **index**.

> You can notice that I used "all shards that compose your **index**", and not "**cluster**". Indeed, each node of the cluster
**may** represents a shard for a given index, but an index may not be "sharded" on each nodes.

With this configuration, **documents are spread on all shards**, and **each time you query an index**, then the cluster has to **query all the shards
that compose it**, which may not be the desired behavior. Imagine now that we could **tell the cluster, for each index, where to store the data**,
according the **routing value** we give it. The **performances** of an index using this configuration may be higher.

This mechanism - to chose where to store documents - is called **routing**.

Well, you may ask yourself how Elasticsearch decides where to store a document. By default, Elasticsearch calculates the **hash value of each
document's ID**, and on the basis of this hash, it will decide on which **primary shard** the document will be stored. Then, the shard redistributes
the document **over the replicas**.

I did talk a bit about the way Elasticsearch is handling queries. Actually, the way it handles queries **depends on the routing configuration**.
So with the default routing configuration, Elasticsearch will have to query **each shard** that compose your index (the query actually involve the
score of the document). Once Elasticsearch gets the score, it will **re-query the shards considered as relevant** (shards that contains documents that
match the query). Finally, Elasticsearch will merge the results, and send it back to you.

## Routing Value

### Manually defining the routing value

The first way we can go with **routing** is to manually define a **routing value**. **Routing value** is a value that indicates Elasticsearch  on which
shard to index a document (and thus, which shard to query).

Defining a routing value makes you indicate this value **each time you are querying the index**.

To index a document by providing its routing value, the request would looks like this:

The query type is `PUT`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: chartreuse">/index/type/ID?routing=routingValue</span></code></pre></div>

In the query above, of course, `index`, `type`, and `ID` should be replaced with the document's index, type and ID. What's interesting is the
`routing` parameter. Here, `routingValue` stands as its value, and should be replaced by the value of your choice. Note that this value could
either be digits (integer, long, float, ...) or a string

Using this method, you will also need to **provide the routing value**, under a HTTP GET parameter, on **each query you are making** to the cluster.

Elasticsearch may store documents that have **different routing values on the same shard**. As a result, if you don't provide the routing value
each time you query Elasticsearch, you may have **results that come from totally different shards**.

That is why this method **is not the most convenient**.

### Semi-automated routing value

Routing stands to **group the documents that have something in common**. For example, in my previous article, I stored document that are Game of Thrones'
characters. I could use their house as a routing value. That would result in documents that have the same `house` value to be stored on the same
shard.

Semi-automated routing value is about that: **find a common ground** (a common field for each document that should be stored together, that would
have the same value).

And using this field that documents have in common, we can **indicate the cluster to use it as a routing value**.

Indicating it to the cluster is done when defining the **mapping**. I've talked about mapping in the previous article ([Elasticsearch Always Pays Its Debts - Mapping](http://reputationvip.io/elasticsearch-always-pays-its-debts/#mapping).

When defining the mapping for a given type, you can add the `_routing` value, which is a JSON object that describes your routing rule. This JSON object
is composed of two fields: the `path` field contains **the name of the document's field** containing what should be used as the routing value. The
`required` field that says whether or not the routing value is **required when performing index operation**.

For example, considering the `elasticsearch` index with `character` type, I could have add this to my JSON mapping object:

{% highlight json %}
{
    "mappings": {
        "character": {
            "_routing": {
                "required": true,
                "path": "house"
            }
        }
    }
}
{% endhighlight %}

The above JSON object tells Elasticsearch to use the `house` field of my `character` type document as the routing value.

### Limits of routing

Well, maybe the title is a little exaggerated. There are no real "limits" to the routing features, just some facts that you should
take care about.

The most important among them, is called **hotspot**. A **hotspot** is a shard that **handles way more documents than other shards**. Using the classical
routing, Elasticsearch will distribute the documents evenly among the shards, so hotspots won't show up easily. But when using manual or semi-automated
routing, then the documents **may not be spread evenly** among the shards. That could result in some shards to handle a lot of documents.

Unfortunately, there are **no ways to automatically handle** these hotspots.

The solution stands on the client side. Indeed, your application (or whatever indexes documents on your index) has to identify routing values
that will support too much documents. A solution may be to create a special index for these documents, and then using aliases to make it transparent
to your application.

# Parent-child relationships and nested objects

Through the two previous articles, I talked a lot about *indexing*, *mapping*, how to fill your database with documents, how to update them,
how to perform CRUD operations on them, and finally, how to use basic full-text search features.

However, a question might have come to your mind: **How to manage relations between documents?**

In this chapter, I will go through the main principles of indexing more complex documents, and how to define the relations that bind them
together. Also, I will introduce you with the **nested types** of Elasticsearch, and how to index non-flat data.

## Nested types

The definition of the *nested type* is quite simple: It is an **array of objects** that lives inside a document.

As you know, Elasticsearch works on top of Apache Lucene. Yet, Apache Lucene doesn't know anything about inner
objects, so that the job of Elasticsearch is to flatten them.

In other words, if you try to index a document that contains an array of objects, by default, each field of each object
of the array will be inserted in a field in your top document that contains an array of each value that correspond to
this field's name in the objects of the array. Is that clear ? I think it is not. Let me give you an example:

Let's assume that our *character* type documents have a field, named `weapons` that contains an array of objects,
each of them would be a weapon, as following:

{% highlight json %}
{
    "_id": "Arya Stark"
    "house": "Stark",
    "gender": "female",
    "age":17,
    "biography": "Arya Stark is the younger daughter and third child [...]",
    "tags": ["stark","needle","faceless god"],
    "weapons": [
        {
            "type": "sword",
            "name": "Needle"
        },
        {
            "type": "axe",
            "name": "My beloved Axe"
        }
    ]
}
{% endhighlight %}

As you can see, the document `Arya Stark` has a field named `weapons`, that contains two objects. The first one is a
sword (the famous sword named "Needle"), and the second one is an axe named "My beloved Axe" (thanks to my imagination
for this name).

If you index this document in the cluster, without precising in the mapping that the field `weapons` is *nested* type,
then the indexed document will look like this:

{% highlight json %}
{
    "_id": "Arya Stark"
    "house": "Stark",
    "gender": "female",
    "age":17,
    "biography": "Arya Stark is the younger daughter and third child [...]",
    "tags": ["stark","needle","faceless god"],
    "weapons.type": ["sword", "axe"],
    "weapons.name": ["Needle", "My beloved Axe"]
}
{% endhighlight %}

As you can see, each field of the objects contained in the array of objects has been inserted into an array of values,
which field's name is composed of the array object's field name. The two field named `type`, of the `weapons`array
for example, result into a new field named `weapons.type`, which is an array of the former values contained in the
`type` field of the `weapons` array.

Here, we lost any relation between the fields, because the objects have been flatten.

The solution to this problem is, in the mapping, to define the field `weapon` as a *nested* type field:

{% highlight json %}
{
    "mappings": {
        "character": {
            "dynamic": "false",
            "properties": {
                [...]
                "weapons": {"type": "nested"}
            }
        }
    }
}
{% endhighlight %}

And, with this mapping, the nested object will not be altered.

## Parent-child relationships

As we just saw, *nested* type is a way for a document to embed one or more "sub-documents". But with nested documents,
each sub-document lives in its parents. In other words, you cannot change one of the sub-documents without reindexing
the parent. Also, if you have a large amount of sub-documents, it might become tricky to add documents, update them
or delete them.

Here comes the parent-child relationship. With this relationship, a document is bound to another, but it still remains
a single entity.

Pay attention though, if the parent document has a routing defined in its mapping, the child has to follow the same routing.
Indeed, Elasticsearch maintains a map of parent-child relationships to make search faster, but it implies for the
parents and the children to be indexed on the same shard. What it means is that if you try to index a orphan child
document, Elasticsearch will require you to precise the routing value.

### Define the mapping

First thing to do when we want to introduce a parent-child relationship is to write the mapping of both the parent
and the child. In our case, the parent (which is `character` type)is already defined, so that we just have to define
the child's mapping.

For example, let's say that we want to store the animals that company our characters. We would store them in the same
index, `game_of_thrones`, but under the `animal` type. What we need to do is to update our mapping to include the new
type, and define the relationship between `character` and `animal`:

{% highlight json %}
{
    "mappings": {
        "character": {
                [...]
            }
        },
        "animal": {
            "_parent": {
                "type": "character"
            },
            "dynamic": "false",
            "properties": {
                "type": {"type": "string"},
                "name": {"type": "string"}
            }
        }
    }
}
{% endhighlight %}

As you can see, under the mapping of the `character` type, I added a new type, which is `animal`. I would like to draw
your attention on the `"_parent"` field. As you can see, I defined the `"type"` field inside it to "character", which
tells Elasticsearch that the parent type for `animal` is `character`.

You should already know the other fields, such as `"dynamic"` and `"properties"`, so I will not tell anything about it
now.

The `animal` type will carry two fields:

- `type` which represents the type of the animal
- `name` which represents the name of the animal

### Index a child

Well, know that the mappings are defined, let's index some children. For my example, I will talk about two famous
animals in Game of Thrones: Nymeria, which is Arya's direwolf, and Ghost which is Robb's direwolf.

To index a child and build the relationship with its parents, you need to specify its parent's ID in the `POST`
request:

Request type is `POST`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/index/type</span><span style="color: chartreuse">/?parent=ID</span></code></pre></div>

The `parent` parameter specifies the parent's ID.

#### The tricky case of routing

Previously, we activated routing on our `game_of_throne` `character` type, by using `house` as the routing value. And,
maybe you remember, I told you that when it comes to parent-child relationships and routing, the things might get
delicate. Indeed, both parents and children have to be stored on the same shard. When default routing is used, everything
is simple, because Elasticsearch uses a hash of the parent's ID to build the routing value, resulting into the children
and the parents to be stored on the same shard.

Because we defined `house` as the routing value, we need to use it when indexing children, by specifying the `routing`
parameter in the request's URL.

Now, let's index Arya and Jon's direwolves:

{% highlight sh %}
$>curl -XPOST 'http://localhost:9200/game_of_thrones/animal/?routing=Stark&parent=Arya%20Stark' -d '{"type":"direwolf", "name":"Nymeria"}'
{% endhighlight %}

{% highlight sh %}
$>curl -XPOST 'http://localhost:9200/game_of_thrones/animal/?routing=Stark&parent=Jon%20Snow' -d '{"type":"direwolf", "name":"Ghost"}'
{% endhighlight %}

You may have notive that I've used `%20` in the URL. That's because the IDs of my parent documents are the character's
names. Thus, there is a space between the first and last name, which is represented by `%20` in the URL.

### Query a document with children

Elasticsearch created two special filters, which are `has_child`, to query a document by searching data into its
children, and `has_parents` to query a document by searching data into its parents. Note that while `has_child` will
give you the parent document, `has_parent` will give you the child document.

#### Retrieve the parent document

Let's start by retrieving the parent document, with the `has_child` filter.

As a single type of parent document can have several types of children documents, the `has_child` query has to know
the type of child you are interested searching data into.

For example, let's say that we want to get the character which animal is Nymeria (so, we are looking for Arya Stark).

Our query will be the following:

{% highlight json %}
{
    "query": {
        "has_child": {
            "type": "animal",
            "query" : {
                "term": {
                    "name": "Nymeria"
                }
            }
        }
    }
}
{% endhighlight %}

It is a simple query, with the `has_child` filter on a `term` query based on the `name` field of the `animal` type.

The query is available at `queries/DSL/query_has_child.json`, let's run it:

{% highlight sh %}
$>curl -XPOST 'http://localhost:9200/game_of_thrones/_search?pretty' -d @queries/DSL/query_has_child.json
{% endhighlight %}

As the answer, we got the following JSON:

{% highlight json %}
{
  "took" : 3,
  "timed_out" : false,
  "_shards" : {
    "total" : 5,
    "successful" : 5,
    "failed" : 0
  },
  "hits" : {
    "total" : 1,
    "max_score" : 1.0,
    "hits" : [ {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Arya Stark",
      "_score" : 1.0,
      "_source":{
        "house": "Stark",
        "gender": "female",
        "age":17,
        "biography": "Arya Stark is the younger daughter and [...] lose her eyesight.",
        "tags": [
            "stark",
            "needle",
            "faceless god"
        ],
        "weapons": [
            {
             "type": "sword",
             "name": "needle"
            },
            {
             "type": "axe"
             }
         ]
        }
    } ]
  }
}
{% endhighlight %}

As you can see, we successfully retrieved `Arya Stark` from her direwolf, `Nymeria`.

#### Retrieve the child document

On the other hand, we can retrieve the children documents by querying the parent's data. For example, let's say
that we want to retrieve every `animal` that is a child of a `character` document which `house` field is "Stark".

{% highlight json %}
{
    "query": {
        "has_parent": {
            "type": "character",
            "query" : {
                "term": {
                    "house": "Stark"
                }
            }
        }
    }
}
{% endhighlight %}

You should recognize that the structure is the same than the previous query, except that the filter we used is
`has_parent`. We set the type to `character`, and the query is still a simple `term` query on the `house` field.

Let's run the query:

{% highlight sh %}
$>curl -XPOST 'http://localhost:9200/game_of_thrones/_search?pretty' -d @queries/DSL/query_has_parent.json
{% endhighlight %}

As the answer, we got the following JSON:

{% highlight json %}
{
  "took" : 6,
  "timed_out" : false,
  "_shards" : {
    "total" : 5,
    "successful" : 5,
    "failed" : 0
  },
  "hits" : {
    "total" : 2,
    "max_score" : 1.0,
    "hits" : [ {
      "_index" : "game_of_thrones",
      "_type" : "animal",
      "_id" : "AVE6LZwmGZdMVtWmkP-D",
      "_score" : 1.0,
      "_source":{"genre":"direwolf", "name":"Nymeria"}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "animal",
      "_id" : "AVE6NLBzGZdMVtWmkP-E",
      "_score" : 1.0,
      "_source":{"genre":"direwolf", "name":"Ghost"}
    } ]
  }
}
{% endhighlight %}

We got two documents, corresponding to the two `animal` documents we indexed earlier. Indeed, both of them belong to
a `character` document which `house` field is set two "Stark".

## The Scoring

Great. With everything we talked about, I think you are ready to start using Elasticsearch. However, using Elasticsearch
in its basics features might not be enough.

That's why I am going to talk a bit about the scoring. Remember, we already talked about it in the very first article,
and also in the second one. Scoring is the way Elasticsearch (and thus Apache Lucene) determines the relevance of a document
against a given query.

If your goal is to use Elasticsearch at the very best of its capabilities, then you should know about scoring. I am now
going to talk about the Apache Lucene scoring mechanism and the TF/IDF algorithm (though we already did talk about it).

### Scoring factors

So the question is simple: How does Elasticsearch (Apache Lucene) calculate the score of a document against a query ?

Well, there is a lot of factor that has a influence on the final score. The score depends on the documents, but also on
the query (and so, comparing scores of documents on different queries doesn't make much sense).

Before I talk about the factors, I want you to know that I have never talked about much of the things that I am going to
talk about now in my previous articles.

Last warning, this part will be a bit mathematical and theoretical ; however, it is totally fine that you don't perfectly
understand what I will go through now. For me, it took a bit of time to understand it.

#### Inverse Document Frequency

**Inverse Document Frequency** first. Maybe you remember that I've already talked about it in the first article. The
**inverse document frequency**, IDF in the short way, is a formula, based on terms, that give a factor about how rare
a term is. The higher the IDF is, the rarer is the term in the document.

Let's have a look to the formula.

<a href="https://www.codecogs.com/eqnedit.php?latex=idf_{i}&space;=&space;log(\frac{\left&space;|&space;D&space;\right&space;|}{\left&space;|&space;\left&space;\{&space;d_{j}&space;:&space;t_{i}&space;\in&space;d_{j}&space;\right&space;\}&space;\right&space;|})" target="_blank"><img src="https://latex.codecogs.com/gif.latex?idf_{i}&space;=&space;log(\frac{\left&space;|&space;D&space;\right&space;|}{\left&space;|&space;\left&space;\{&space;d_{j}&space;:&space;t_{i}&space;\in&space;d_{j}&space;\right&space;\}&space;\right&space;|})" title="idf_{i} = log(\frac{\left | D \right |}{\left | \left \{ d_{j} : t_{i} \in d_{j} \right \} \right |})" /></a>

With <a href="https://www.codecogs.com/eqnedit.php?latex=i" target="_blank"><img src="https://latex.codecogs.com/gif.latex?i" title="i" /></a> the term.

Here, <a href="https://www.codecogs.com/eqnedit.php?latex=\left&space;|&space;D&space;\right&space;|" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\left&space;|&space;D&space;\right&space;|" title="\left | D \right |" /></a>
represents the total number of documents for a given type *type*

<a href="https://www.codecogs.com/eqnedit.php?latex=\left&space;|&space;\left&space;\{&space;d_{j}&space;:&space;t_{i}&space;\in&space;d_{j}&space;\right&space;\}&space;\right&space;|" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\left&space;|&space;\left&space;\{&space;d_{j}&space;:&space;t_{i}&space;\in&space;d_{j}&space;\right&space;\}&space;\right&space;|" title="\left | \left \{ d_{j} : t_{i} \in d_{j} \right \} \right |" /></a>
simply is a complicated way to represent the number of documents in which the term appears.

But this is only the *theoretical* formula. In practice, this formula has a weakness : What if <a href="https://www.codecogs.com/eqnedit.php?latex=\left&space;|&space;\left&space;\{&space;d_{j}&space;:&space;t_{i}&space;\in&space;d_{j}&space;\right&space;\}&space;\right&space;|&space;=&space;0" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\left&space;|&space;\left&space;\{&space;d_{j}&space;:&space;t_{i}&space;\in&space;d_{j}&space;\right&space;\}&space;\right&space;|&space;=&space;0" title="\left | \left \{ d_{j} : t_{i} \in d_{j} \right \} \right | = 0" /></a> ?
In other words, what if the term doesn't appear in any document? It would result in dividing by zero, and this is simply... Not possible.

So in practice, we add 1 to this value. The final formula is:

<a href="https://www.codecogs.com/eqnedit.php?latex=idf_{i}&space;=&space;log(\frac{\left&space;|&space;D&space;\right&space;|}{\left&space;|&space;\left&space;\{&space;d_{j}&space;:&space;t_{i}&space;\in&space;d_{j}&space;\right&space;\}&space;\right&space;|&space;&plus;&space;1})" target="_blank"><img src="https://latex.codecogs.com/gif.latex?idf_{i}&space;=&space;log(\frac{\left&space;|&space;D&space;\right&space;|}{\left&space;|&space;\left&space;\{&space;d_{j}&space;:&space;t_{i}&space;\in&space;d_{j}&space;\right&space;\}&space;\right&space;|&space;&plus;&space;1})" title="idf_{i} = log(\frac{\left | D \right |}{\left | \left \{ d_{j} : t_{i} \in d_{j} \right \} \right | + 1})" /></a>

Oh... I see you ! You'd like an example! Well, I'm in a good mood today, so let's go!

Let's consider the 3 following documents:

- **Document 1**: "Hello, my name is Arya"
- **Document 2**: "Arya is part of the Stark family"
- **Document 3**: "The Stark family really has no chance..."

Also, we will consider that a *term* is a word. For example, "Hello" is a term. We want to calculate the IDF value of
the term **"Arya"** against the 3 documents.

In this case, <a href="https://www.codecogs.com/eqnedit.php?latex=\left&space;|&space;D&space;\right&space;|" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\left&space;|&space;D&space;\right&space;|" title="\left | D \right |" /></a>
is 3 (indeed, we have 3 documents).

Also, <a href="https://www.codecogs.com/eqnedit.php?latex=\left&space;|&space;\left&space;\{&space;d_{j}&space;:&space;t_{i}&space;\in&space;d_{j}&space;\right&space;\}&space;\right&space;|" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\left&space;|&space;\left&space;\{&space;d_{j}&space;:&space;t_{i}&space;\in&space;d_{j}&space;\right&space;\}&space;\right&space;|" title="\left | \left \{ d_{j} : t_{i} \in d_{j} \right \} \right |" /></a>
is equal to 2, because the term **"Arya"** can be find in 2 documents (**Document 1** and **Document 2**).

So, the IDF value for the term **"Arya"** against these documents is <a href="https://www.codecogs.com/eqnedit.php?latex=idf_{arya}&space;=&space;log(\frac{\left&space;|&space;3&space;\right&space;|}{\left&space;|&space;2&space;\right&space;|})" target="_blank"><img src="https://latex.codecogs.com/gif.latex?idf_{arya}&space;=&space;log(\frac{\left&space;|&space;3&space;\right&space;|}{\left&space;|&space;2&space;\right&space;|})" title="idf_{arya} = log(\frac{\left | 3 \right |}{\left | 2 \right |})" /></a>

And that's it ! Quite simple, isn't it ?!

#### Term Frequency

The IDF by itself is not enough. Indeed, IDF gives a score for a term against **all** documents, so the score is not relevant
without a moderation. Here comes the **term frequency** (TF). That's why we are talking of **TF/IDF**, and not only of
**TF** or **IDF**.

The **term frequency** of a term, as it name suggests, is the frequency of the term in a given document. Some scientists
invented a complicated formula to describe it, which is:

<a href="https://www.codecogs.com/eqnedit.php?latex=tf_{i,d}&space;=&space;\frac{n_{i,d}}{\sum&space;_{k}&space;n_{k,d}}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?tf_{i,d}&space;=&space;\frac{n_{i,d}}{\sum&space;_{k}&space;n_{k,d}}" title="tf_{i,d} = \frac{n_{i,d}}{\sum _{k} n_{k,d}}" /></a>

Behind this *complicated* formula, it is simply a frequency calculation: The number of times the term appears in the document,
divided by the total number of terms in the document.

With <a href="https://www.codecogs.com/eqnedit.php?latex=i" target="_blank"><img src="https://latex.codecogs.com/gif.latex?i" title="i" /></a> the term,
<a href="https://www.codecogs.com/eqnedit.php?latex=d" target="_blank"><img src="https://latex.codecogs.com/gif.latex?d" title="d" /></a> the document.

So, <a href="https://www.codecogs.com/eqnedit.php?latex=n_{i,d}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?n_{i,d}" title="n_{i,d}" /></a> is
the number of times the term appears in the document, and <a href="https://www.codecogs.com/eqnedit.php?latex=\sum&space;_{k}&space;n_{k,d}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\sum&space;_{k}&space;n_{k,d}" title="\sum _{k} n_{k,d}" /></a>
is the sum of occurrences of each single term in the document (thus, the total number of terms in the document).

Let's resume with the 3 documents we used to calculate IDF. Our query still is **"Arya"**.

- **Document 1**: "Hello, my name is Arya" : <a href="https://www.codecogs.com/eqnedit.php?latex=tf_{arya,&space;Document&space;1}&space;=&space;\frac{1}{5}&space;=&space;0,20" target="_blank"><img src="https://latex.codecogs.com/gif.latex?tf_{arya,&space;Document&space;1}&space;=&space;\frac{1}{5}&space;=&space;0,20" title="tf_{arya, Document 1} = \frac{1}{5} = 0,20" /></a> (We don't consider a coma as a term)
- **Document 2**: "Arya is part of the Stark family" : <a href="https://www.codecogs.com/eqnedit.php?latex=tf_{arya,&space;Document&space;2}&space;=&space;\frac{1}{7}&space;\approx&space;0,14" target="_blank"><img src="https://latex.codecogs.com/gif.latex?tf_{arya,&space;Document&space;2}&space;=&space;\frac{1}{7}&space;\approx&space;0,14" title="tf_{arya, Document 2} = \frac{1}{7} \approx 0,14" /></a>
- **Document 3**: "The Stark family really has no chance..." : <a href="https://www.codecogs.com/eqnedit.php?latex=tf_{arya,&space;Document&space;3}&space;=&space;\frac{0}{7}&space;=&space;0" target="_blank"><img src="https://latex.codecogs.com/gif.latex?tf_{arya,&space;Document&space;3}&space;=&space;\frac{0}{7}&space;=&space;0" title="tf_{arya, Document 3} = \frac{0}{7} = 0" /></a>

From now, we can even calculate the **TF/IDF** for each document, as the **TF/IDF** is simply the following:

<a href="https://www.codecogs.com/eqnedit.php?latex=tfidf_{i,d}&space;=&space;tf_{i,d}&space;\cdot&space;idf_{i}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?tfidf_{i,d}&space;=&space;tf_{i,d}&space;\cdot&space;idf_{i}" title="tfidf_{i,d} = tf_{i,d} \cdot idf_{i}" /></a>

- **Document 1**: "Hello, my name is Arya" : <a href="https://www.codecogs.com/eqnedit.php?latex=tfidf_{Arya,Document&space;1}&space;=&space;0,20&space;\cdot&space;log(\frac{\left&space;|&space;3&space;\right&space;|}{\left&space;|&space;2&space;\right&space;|})&space;\approx&space;0,04" target="_blank"><img src="https://latex.codecogs.com/gif.latex?tfidf_{Arya,Document&space;1}&space;=&space;0,20&space;\cdot&space;log(\frac{\left&space;|&space;3&space;\right&space;|}{\left&space;|&space;2&space;\right&space;|})&space;\approx&space;0,04" title="tfidf_{Arya,Document 1} = 0,20 \cdot log(\frac{\left | 3 \right |}{\left | 2 \right |}) \approx 0,04" /></a>
- **Document 2**: "Arya is part of the Stark family" : <a href="https://www.codecogs.com/eqnedit.php?latex=tfidf_{Arya,Document&space;2}&space;=&space;\frac{1}{7}&space;\cdot&space;log(\frac{\left&space;|&space;3&space;\right&space;|}{\left&space;|&space;2&space;\right&space;|})&space;\approx&space;0,03" target="_blank"><img src="https://latex.codecogs.com/gif.latex?tfidf_{Arya,Document&space;2}&space;=&space;\frac{1}{7}&space;\cdot&space;log(\frac{\left&space;|&space;3&space;\right&space;|}{\left&space;|&space;2&space;\right&space;|})&space;\approx&space;0,03" title="tfidf_{Arya,Document 2} = \frac{1}{7} \cdot log(\frac{\left | 3 \right |}{\left | 2 \right |}) \approx 0,03" /></a>
- **Document 3**: "The Stark family really has no chance..." : <a href="https://www.codecogs.com/eqnedit.php?latex=tfidf_{Arya,Document&space;3}&space;=&space;0&space;\cdot&space;log(\frac{\left&space;|&space;3&space;\right&space;|}{\left&space;|&space;2&space;\right&space;|})&space;=&space;0" target="_blank"><img src="https://latex.codecogs.com/gif.latex?tfidf_{Arya,Document&space;3}&space;=&space;0&space;\cdot&space;log(\frac{\left&space;|&space;3&space;\right&space;|}{\left&space;|&space;2&space;\right&space;|})&space;=&space;0" title="tfidf_{Arya,Document 3} = 0 \cdot log(\frac{\left | 3 \right |}{\left | 2 \right |}) = 0" /></a>

#### Document Boost

**Document Boost** is something that I never talked about. This is an artificial way to influence the scoring value for
a document. The **Document Boost** is simply a boost value that can be given to a document during indexing.

#### Field Boost

In the same idea as the *Document Boost*, the **Field Boost** is a boost value that can be given to a specific field
during indexing.

#### Coordination Factor

The **coordination factor** is quite simple: The more searched terms the document contains, the higher the **coordination
factor** is. Without the **coordination factor**, the combined weight value of the matching terms in a document
would evolve in a linear way. With the **coordination factor**, the weight value is being multiplied by the number of matching
terms in the document, and then divided by the number of terms in the query. Let's reconsider our documents. Let's imagine that
our query would be **"Arya Stark family"**. Also, we consider each term has a weight of 1.

- **Document 1**: "Hello, my name is Arya"
- **Document 2**: "Arya is part of the Stark family"
- **Document 3**: "The Stark family really has no chance..."

Without the **coordination factor**, the weight scores would be:

- **Document 1**: "Hello, my name is Arya" : Weight Score = 1
- **Document 2**: "Arya is part of the Stark family" : Weight Score = 3
- **Document 3**: "The Stark family really has no chance..." : Weight Score = 2

As you can see, the weight score is just the addition of the score of each term of the query that is present in the
document.

Now, with the **coordination factor**:

- **Document 1**: "Hello, my name is Arya" : Weight Score = <a href="https://www.codecogs.com/eqnedit.php?latex=1&space;*&space;\frac{1}{3}&space;=&space;\frac{1}{3}&space;\approx&space;0,33" target="_blank"><img src="https://latex.codecogs.com/gif.latex?1&space;*&space;\frac{1}{3}&space;=&space;\frac{1}{3}&space;\approx&space;0,33" title="1 * \frac{1}{3} = \frac{1}{3} \approx 0,33" /></a>
- **Document 2**: "Arya is part of the Stark family" : Weight Score = <a href="https://www.codecogs.com/eqnedit.php?latex=3&space;*&space;\frac{3}{3}&space;=&space;3" target="_blank"><img src="https://latex.codecogs.com/gif.latex?3&space;*&space;\frac{3}{3}&space;=&space;3" title="3 * \frac{3}{3} = 3" /></a>
- **Document 3**: "The Stark family really has no chance..." : Weight Score = <a href="https://www.codecogs.com/eqnedit.php?latex=2&space;*&space;\frac{2}{3}&space;=&space;\approx&space;1,33" target="_blank"><img src="https://latex.codecogs.com/gif.latex?2&space;*&space;\frac{2}{3}&space;=&space;\approx&space;1,33" title="2 * \frac{2}{3} = \approx 1,33" /></a>

As you can see, the evolution of the score is not linear anymore. Indeed, the **Document 2** has a score of *3*, while
the **Document 1** has a score of around 0,33.

#### Query Normalization Factor

As I said, it is a non-sense to compare the scoring value of a document against a given query to the scoring value
of the same document against another query.

But, the **query normalization factor** is an attempt from Elasticsearch to "normalize" a query, so that the score of a
given document can be compared against different queries.

Careful though, the **query normalization factor** is not really relevant, and still, you have to be really careful when
comparing the score of a document against different queries.

As it is not really important, I won't talk about it here.

#### Field-length norm

Basically, it is the length of the field we are searching in. The shorter the field, the higher the weight. In other words,
a term found in a little field will be given more weight than the same term found in a longer field.

The calculation is quite simple:

<a href="https://www.codecogs.com/eqnedit.php?latex=norm_{d}&space;=&space;\frac{1}{\sqrt{\sum&space;_{k}&space;n_{k,d}}}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?norm_{d}&space;=&space;\frac{1}{\sqrt{\sum&space;_{k}&space;n_{k,d}}}" title="norm_{d} = \frac{1}{\sqrt{\sum _{k} n_{k,d}}}" /></a>

With <a href="https://www.codecogs.com/eqnedit.php?latex=d" target="_blank"><img src="https://latex.codecogs.com/gif.latex?d" title="d" /></a> the document.

As you can see, the calculation doesn't depend on the term, but on the document (on the field, actually).

Let's calculate the **field-length norm** for our 3 documents:

- **Document 1**: "Hello, my name is Arya" : <a href="https://www.codecogs.com/eqnedit.php?latex=norm_{Document&space;1}&space;=&space;\frac{1}{\sqrt{5}}&space;\approx&space;0,45" target="_blank"><img src="https://latex.codecogs.com/gif.latex?norm_{Document&space;1}&space;=&space;\frac{1}{\sqrt{5}}&space;\approx&space;0,45" title="norm_{Document 1} = \frac{1}{\sqrt{5}} \approx 0,45" /></a>
- **Document 2**: "Arya is part of the Stark family" : <a href="https://www.codecogs.com/eqnedit.php?latex=norm_{Document&space;2}&space;=&space;\frac{1}{\sqrt{7}}&space;\approx&space;0,38" target="_blank"><img src="https://latex.codecogs.com/gif.latex?norm_{Document&space;2}&space;=&space;\frac{1}{\sqrt{7}}&space;\approx&space;0,38" title="norm_{Document 2} = \frac{1}{\sqrt{7}} \approx 0,38" /></a>
- **Document 3**: "The Stark family really has no chance..." : <a href="https://www.codecogs.com/eqnedit.php?latex=norm_{Document&space;2}&space;=&space;\frac{1}{\sqrt{7}}&space;\approx&space;0,38" target="_blank"><img src="https://latex.codecogs.com/gif.latex?norm_{Document&space;2}&space;=&space;\frac{1}{\sqrt{7}}&space;\approx&space;0,38" title="norm_{Document 2} = \frac{1}{\sqrt{7}} \approx 0,38" /></a>

As you can notice, the more term in the document, the lower the **field-norm length**.

### The final scoring function

With all of this, we can finally build the scoring function, which is:

<a href="https://www.codecogs.com/eqnedit.php?latex=score_{q,d}&space;=&space;queryNormalizationFactor_{q}&space;\cdot&space;coordinationFactor_{q,d}&space;\cdot&space;\sum&space;(tf_{i,d}&space;\cdot&space;idf_{i}^{2}&space;\cdot&space;boost_{i}&space;\cdot&space;fieldLengthNorm_{i,d})" target="_blank"><img src="https://latex.codecogs.com/gif.latex?score_{q,d}&space;=&space;queryNormalizationFactor_{q}&space;\cdot&space;coordinationFactor_{q,d}&space;\cdot&space;\sum&space;(tf_{i,d}&space;\cdot&space;idf_{i}^{2}&space;\cdot&space;boost_{i}&space;\cdot&space;fieldLengthNorm_{i,d})" title="score_{q,d} = queryNormalizationFactor_{q} \cdot coordinationFactor_{q,d} \cdot \sum (tf_{i,d} \cdot idf_{i}^{2} \cdot boost_{i} \cdot fieldLengthNorm_{i,d})" /></a>

Basically, the function is not really complicated: It takes the scoring factor that are specific to the document and the query
(the normalization factor and the coordination factor), and multiply them to get a coefficient. This coefficient is then
used with a combination (multiplication) of each scoring factors specific to terms of the query.

## Compound Queries

Well, after this little theoretical part, it is time for us to be back in the essence of Elasticsearch: the full-text
search.

I would like to introduce you the **compound queries**. In the previous article, we went through some basic queries
available in Elasticsearch, such as the *term query* or the *match query*.

But what if we want to connect multiply queries between them, to perform more precise search ?

### The boolean query

The first compound query I want to introduce you is the **boolean query**. The boolean query allows you to **connect
multiple queries to get a boolean value**.

With three keywords that are *should*, *must* et *must_not*, you will be able to define some inbound rules
to include or exclude a document from the results.

Each of the keywords may be present multiple times in a single query, as the query is processed as a stream: Each
keyword is applied on the result of the previous keyword.

Let me give you a simple example: let's say that we want to retrieve `character` that **must** match the term "Stark" in their
`biography` field (it is a *match query*), but their `age` field **must not** be between 20 and 30.

Let's take a look at the request:

{% highlight json %}
{
  "query": {
    "bool": {
      "must": {
        "match": {
          "biography": "Stark"
        }
      },
      "must_not": {
        "range": {
          "age": {
            "from": 20,
            "to": 30
          }
        }
      }
    }
  }
}
{% endhighlight %}

As you can see, I indicated the "bool" type for the query, followed by as much boolean clauses as I want. My first clause
is the *match query* I talked before, matching the term "Stark" on the `biography` field. Then, I indicated a *must_not*
clause, and I used a very new query type: the *range* query, that allows us to specify a range to match (the range can
be performed on integer or date fields, but also on string fields).

The query is available at `queries/DSL/compound_query_bool.json`, let's run it:

{% highlight sh %}
$>curl -XPOST 'http://localhost:9200/game_of_thrones/_search?pretty' -d @queries/DSL/compound_query_bool.json
{% endhighlight %}

And, the result of the query, once executed, is the following:

{% highlight json %}
{
  "took" : 34,
  "timed_out" : false,
  "_shards" : {
    "total" : 5,
    "successful" : 5,
    "failed" : 0
  },
  "hits" : {
    "total" : 6,
    "max_score" : 0.08118988,
    "hits" : [ {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Bran Stark",
      "_score" : 0.08118988,
      "_source":{"house": "Stark","gender": "male","age":11,"biography": "Brandon Bran Stark is the second son and fourth child of Eddard and Catelyn Stark. He was named after his deceased uncle, Brandon. His dire wolf is called Summer. During the King's visit to Winterfell, he accidentally came across Cersei and Jaime Lannister engaging in sex, following which Bran is shoved from the window by Jaime, permanently crippling his legs. An assassin tries to kill Bran, but Summer, the direwolf companion, kills the assassin. Bran, when he awakens, finds that he is crippled from the waist down, forced to be carried everywhere by Hodor, and he cannot remember the events immediately before his fall. Slowly, he realizes that he has gained the ability to assume Summer's consciousness, making him a warg or a skinchanger. After his older brother, Robb, is crowned King in the North, Bran becomes Robb's heir and the Lord of Winterfell. After Theon Greyjoy captures Winterfell, Bran goes into hiding. To cement his claim on Winterfell, Theon kills two orphan boys and tells the people of Winterfell that Bran, and his younger brother Rickon Stark, are dead. After Theon's men betray him and Winterfell is sacked, Bran, Rickon, Hodor, Osha and their direwolves head north to find his older brother Jon Snow for safety. They ultimately stumble upon Jojen and Meera Reed, two siblings who aid them in their quest. After coming close to the wall, Osha departs with Rickon for Last Hearth while Bran insists on following his visions beyond the Wall. He also encounters Sam and Gilly, who tries to persuade him not to, but Bran claims it is his destiny and leaves through the gate with Hodor and the Reeds. Along the way, Bran and the others stumble across Craster's Keep, where they are captured and held hostage by the Night's Watch mutineers led by Karl. Night's Watch rangers led by Jon eventually attack Craster's Keep to kill the mutineers, but Locke, a new recruit but secretly a spy for Roose Bolton, attempts to take Bran away and kill him elsewhere. Bran wargs into Hodor and kills Locke by snapping his neck, but Bran and his group are forced to continue on their journey without alerting Jon, whom Jojen claims would stop them. They eventually reach the three-eyed raven in a cave, who claims he cannot restore Bran's legs, but will make him fly instead.","tags": ["stark","disable","crow"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Tywin Lannister",
      "_score" : 0.07654656,
      "_source":{"house": "Lannister","gender": "male","age":70,"biography": "Lord of Casterly Rock, Shield of Lannisport and Warden of the West, Tywin is a calculating, ruthless, and controlling man. He is also the former Hand of King Aerys II. He is the father of Cersei, Jaime, and Tyrion. After Eddard Stark's arrest, Joffrey names him Hand of the King once more, but after Jaime is taken captive by the Starks, Eddard is unexpectedly executed by Joffrey, and Renly and Stannis Baratheon challenge Joffrey's claim to the throne; Tywin elects to remain in the field commanding his forces until he wins his war, and in the meantime gives the position of Hand of the King to Tyrion. Tywin continues the war through Season 2 at Harrenhal where he criticizes his commanders for losing and underestimating the Stark army led by King Robb Stark. While there, he forms an unlikely friendship with his cup bearer, unaware that she is actually Arya Stark. Originally, he was about to attack Robb's forces while they are distracted by the Greyjoys seizing Winterfell, but changes his mind and helps the defenders of King's Landing drive Stannis Baratheon's forces away. He assumes his position of Hand of the King once again and arranges for Joffrey to marry Margaery Tyrell to secure an alliance between the Lannisters and Tyrells. In the third season, as Hand of the King, he fortifies his position as de facto leader of the Seven Kingdoms, and he successfully defeats Robb Stark, the King in the North, by forging an alliance with the lords Frey and Bolton, who betray and kill Stark and his men. The crown subsequently pardons and rewards them with Riverrun and the North, respectively, though Tywin is criticized by Tyrion for winning the war through such an unscrupulous scheme. He also has to deal with an increasingly belligerent Joffrey, who chides his grandfather as a coward who hid under Casterly Rock while Robert Baratheon led the rebellion against Aerys Targaryen, and complicated relations with his children as he forces them into marriage alliances with Sansa Stark and Loras Tyrell, to secure the support of the Tyrells and Lannister dominion in the North (now Sansa's heirdom, as all her brothers are presumed dead). In the fourth season, Tywin is present at the royal wedding where Joffrey dies, and has King's Landing closed off to prevent Sansa from escaping (although she escapes with help from Petyr Baelish and Dontos Hollard). He grooms Joffrey's younger brother, Tommen, to becoming the new King, and appears determined to make sure Tommen becomes a much better King than Joffrey was. The presence of Prince Oberyn Martell of Dorne poses a new problem, however, as he resurfaces the Martell–Lannister antagonism over the rape and murder of his sister Elia by Gregor The Mountain Clegane during the Robert's Rebellion; Oberyn believes the deed was done on Tywin's order. Tywin denies the allegations and promises Oberyn justice in exchange for Oberyn serving as one of the judges at Tyrion's trial. At the trial, when several supposed witnesses give false statements regarding Tyrion's supposed guilt, Tywin promises Jaime in private that if Tyrion is found guilty and pleads for mercy, he will exile him to the Night's Watch but only if Jaime ceases to be a Kinsguard and takes his place as heir to House Lannister. However, Tyrion loses his composure, lashes out at Tywin and demands a trial by combat, to Tywin's anger. When Tyrion's champion, Oberyn, loses the fight and is killed, Tywin sentences his son to death. Later, when Jamie helps Tyrion escape, Tyrion discovers that Tywin was having an affair with Shae, Tyrion's former lover, who falsely testified against him at his trial. Tywin is ambushed by Tyrion while in a privy, wielding Joffrey's crossbow. Tywin attempts to reason with Tyrion, swearing that he would never have had him executed, but also – upon Tyrion showing regret for Shae's death – taunts him as afraid of a dead whore. In rage, Tyrion shoots Tywin twice in the chest, killing him. His body is discovered shortly afterwards, and a grand funeral is held in the Sept of Baelor. As revealed by Davos Seaworth, he was 67 years old. Tywin's death heralds instability in the Seven Kingdoms, with the arrival of the Sparrows in the capital, and rivalry rising between Cersei, who aspires to her father's position but lacks many of his statesmanlike qualities, and the Tyrells. The Boltons also lose the potential Lannister military support just when they are faced with Stannis Baratheon planning to take Winterfell on his way to the Iron Throne.","tags": ["lannister","father"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Cersei Lannister",
      "_score" : 0.0543492,
      "_source":{"house": "Lannister","gender": "female","age":34,"biography": "Cersei Lannister, Queen of the Seven Kingdoms of Westeros, is the wife of King Robert Baratheon. Her father arranged the marriage when she was a teenager, initiating himself as a political counselor for King Robert. The Lannisters are the richest family in Westeros,[31] which is why Robert was interested in a marriage between them. Cersei has a twin brother, Jaime, with whom she has been involved in an incestuous affair from early childhood. All three of Cersei's children are Jaime's.[31] Cersei's main character attribute is her desire for power and her deep loyalty to her father, children, and brother Jaime. Cersei learns that her husband Robert is in danger of finding out that the children he sees as his heirs to the throne are not his. Robert meets his end as the result of a boar attack on a hunting trip, before Ned Stark tells him of the truth about his children. Cersei works quickly to instate her oldest son, Joffrey, on the throne, with her as his chief political advisor and Queen Regent.[32] Joffrey quits listening to his mother, and by the beginning of the second season her father decides Cersei does not exercise enough control over her son, and her father sends his youngest son Tyrion as an additional political advisor. Cersei and Tyrion do not get along, and constantly try to undermine each other's authority over the crown. As of the end of season 2, Tyrion has accumulated more sway over the Iron Throne, and has shipped Cersei's only daughter off against Cersei's will to be married to the prince of Dorne. In season 3, she takes pleasure in Tyrion's diminished position and taunts him for being forced into a marriage pact with Sansa Stark, only to be told by her father that he intends to marry her to Loras Tyrell. At the end of the season, the two siblings ponder at their respective marriages, and Cersei reunites with Jaime in her bedchamber as he unexpectedly returns from captivity. In season 4, she has Tyrion arrested after Joffrey is fatally poisoned. It is implied that she knows Tyrion's guilt is highly unlikely, but just wants to see him dead, though Jaime refuses to carry out the order.[33] Indeed, at Tyrion's trial, it is obvious that Cersei has manipulated the entire procedure so that the only witnesses (herself, Lord Varys, Meryn Trant, Grand Maester Pycelle and Shae) give either incomplete or entirely false testimonies to implicate Tyrion and Sansa further in the murder. When Tyrion demands a trial by combat, Cersei quickly chooses Ser Gregor The Mountain Clegane as her champion to diminish Tyrion's chances of acquittal, and has Bronn betrothed to a noblewoman so that Tyrion cannot choose him as his champion. Cersei's wish comes true when Tyrion's champion, Oberyn Martell, is killed by Clegane, but she still refuses to marry Loras, even threatening her father with revealing the truth about her relationship with Jaime and the parentage of her children. Tywin rebuffs her threats, though he himself is killed by an escaping Tyrion soon afterwards. Cersei attends Tywin's funeral and later orders a bounty on Tyrion's head. Cersei and Jaime receive a message from Dorne: a small viper statue with a necklace in its fangs. Cersei tells Jaime that the necklace belongs to their daughter, Myrcella, who was sent to Dorne by Tyrion. Jaime tells Cersei that he will travel to Dorne and bring Myrcella back. Cersei meets with two hunters who have brought her a severed head, though she is disappointed to find that it is not Tyrion's head. Qyburn lays claim to the head for his research and the two walk to a small council meeting. With the office of Hand of the King vacant, Cersei tells the council that she will stand in temporarily until Tommen chooses a new Hand. She appoints Mace Tyrell as the new Master of Coin and Qyburn as the new Master of Whisperers. When Cersei tries to appoint her uncle Kevan as the Master of War, he declines, telling her that as the queen mother she holds no power, and has no interest in serving in a council filled with her sycophants. In defiance of Cersei's orders, Kevan states that he will return to Casterly Rock until he hears direct word from Tommen that he is required. Tommen soon weds Margaery Tyrell. Under Margaery's influence, Tommen drops hints that he would like Cersei to return to Casterly Rock, but she refuses, and confronts Margaery, who insults her. Cersei catches the High Septon being punished for entering a brothel by her cousin Lancel, who has become a member of the Faith Militant, an extremist group that worships the Seven. Cersei talks to their leader, the High Sparrow, and instates him as the new High Septon. The Faith Militant then aggressively puncture all barrels of wine and trash Petyr Baelish's brothel. They also arrest Margaery's brother Loras on the grounds of his homosexuality. Tommen, at Margaery's insistance, tries to get Cersei to release Loras, but Cersei swears she had nothing to do with it, After a trial, Loras is arrested after a prostitute named Olyvar testifies against Loras. Margaery is also arrested for lying about Loras' sexual orientation, and both are put in dungeons. All of this delights Cersei, who goes to see Margaery in her cell and brings her a bowl of venison stew. Cersei has one final talk with the High Sparrow about the accomplishments of the pair, but he soon reveals that Lancel has confessed everything (in Season 1, Cersei had sex with him in Jaime's absence). Cersei is subsequently arrested for adultery, incest, and murder (it was her plan to get Robert drunk so that he would injure himself while hunting). She is only visited in her cell by Qyburn, who tells her that Grand Maester Pycelle has seized power of the throne, and that Kevan is serving as hand of the king. Cersei is distraught to learn that Tommen, anguished over his wife's and mother's arrests, has not been eating. Cersei is also visited by a septa, who orders her to confess to her sins. Cersei refuses, and she is hit by the septa. Weakened, Cersei is forced to lick the water off the floors of the cell. She eventually agrees to reveal herself to the High Septon, confessing her incestuous relationship to Lancel Lannister but refusing to admit more serious offences, which would be harder for the Faith to prove. The High Sparrow allows her to leave captivity in favor of house arrest in the Red Keep, pending the trial, but only if she agrees to do atonement for her sins by being shaved and walking naked through the streets of King's Landing. Cersei endures the walk with great resolve, bleeding and covered in filth as she eventually reaches the Keep, where she reunites with her uncle Kevan, now Hand of the King, and Qyburn, who introduces her to the newest member of the Kingsguard, a freakishly large, silent giant implied to be the reanimated corpse of Gregor Clegane.","tags": ["lannister","queen","baratheon","shame"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Arya Stark",
      "_score" : 0.054126587,
      "_source":{"house": "Stark","gender": "female","age":17,"biography": "Arya Stark is the younger daughter and third child of Lord Eddard and Catelyn Stark of Winterfell. Ever the tomboy, Arya would rather be training to use weapons than sewing with a needle. Her direwolf is called Nymeria. When Ned is arrested for treason, her dancing master Syrio Forel helps her escape the Lannisters. She is later disguised as an orphan boy by Yoren, a Night's Watch recruiter, in hopes of getting her back to Winterfell. From then on, she takes the name Arry. During Season 2, Yoren's convoy is attacked by the Lannisters who are under orders by King Joffrey to find and kill Robert's bastard children. Before she is captured, she releases the prisoner Jaqen H'ghar and two others, saving their lives. She and the rest of the captured recruits are sent to Harrenhal under Gregor Clegane who cruelly tortures and kills prisoners everyday. At the same time, she follows the advice of the late Yoren and makes a list of those she wants dead like a prayer. When Tywin Lannister arrives at Harrenhal, he orders the killing of prisoners stopped and makes Arya his cup bearer after figuring out she is a girl. Tywin forms an unlikely friendship with Arya due to her intelligence while remaining unaware of her true identity. Arya reunites with Jaqen who offers to kill three lives in exchange for the three lives she saved. The first two she picks, the Tickler, Harrenhal's torturer and Ser Amory Lorch, after he catches Arya reading one of Tywin's war plans and tries to inform Tywin. After she fails to find Jaqen to kill Tywin, after he heads out to face Robb's forces, she forces Jaqen to help her, Gendry and Hot Pie escape Harrenhal after choosing Jaqen as her third name, for which she promises to unname him if he helps them. After successfully escaping, Jaqen gives her an iron coin and tells her to give it to any Braavosi and say Valar morghulis if she ever needs to find him. Arya, Gendry and Hot Pie head north for Riverrun and Arya's mother Lady Stark, but are captured by the Brotherhood Without Banners and taken to the Inn of the Kneeling Man. There, Arya is horrified to be reunited with the vile Sandor Clegane, one of the Brotherhood's prisoners. Arya and Gendry travel with the Brotherhood to meet their leader, now friends with them as they know Arya is Ned Stark's daughter. She escapes them after the Brotherhood acquits Sandor Clegane of murder after a trial by combat and selling Gendry to Melisandre to be sacrificed. Captured by Sandor, she is taken to the Twins to be ransomed to her brother, only to see his wolf and forces slaughtered and her brother paraded headless on a horse. Sandor knocks her unconscious and saves her from the ensuing slaughter, and she subsequently kills her first man when falling upon a party of Freys, boasting of how they mutilated her brother's corpse. In season 4, Sandor decides to ransom her to her Aunt Lysa Arryn in the Vale. With Sandor's help, Arya later retrieves her sword, Needle (a gift from Jon Snow), and kills the sadistic soldier Polliver, who stole it from her. Along the way, Arya slowly begins to bond with Sandor, helping to heal one of his wounds when they are attacked. They eventually arrive at the Vale, but are told that Lysa Arryn killed herself three days prior. Arya laughs with disbelief. Later, Arya and Sandor are found by Brienne of Tarth and Podrick Payne. Arya refuses to leave with Brienne, assuming her to be an agent of the Lannisters. In the ensuing fight between Brienne and Sandor, Arya flees and manages to catch a boat to Braavos, befriending the Braavosi captain by showing him the coin Jaqen gave her outside Harrenhal. In Season 5 Arya arrives in Braavos, and the ship's captain, Ternesio takes her to the House of Black and White. She is turned away by the doorman, even after showing the iron coin given to her by Jaqen H'ghar. After spending the night sitting in front of the House, she throws the coin into the water and leaves. Later, after killing a pigeon, Arya is confronted by a group of thieves in the street. Arya prepares to fight them, but the thieves flee when the doorman appears. He walks her back to the House of Black and White, and gives her the iron coin. He then changes his face to Jaqen, and informs Arya that she must become no one before taking her inside the House. Arya's training progresses, during which she gets better and better at lying about her identity. Jaqen eventually gives her her first new identity, as Lana, a girl who sells oysters on the streets of Braavos. She eventually encounters Meryn Trant, who she tortures and executes in retaliation for Syrio's death, revealing her identity and motive in the process. When she returns to the House of Black and White she is confronted by Jaqen H'ghar and the Waif, who tell her that Meryn's life was not hers to take and that a debt must be paid. Arya screams as she begins to lose her eyesight.","tags": ["stark","needle","faceless god"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Jon Snow",
      "_score" : 0.047360763,
      "_source":{"house": "Stark","gender": "male","age":19,"biography": "Jon Snow is the bastard son of Ned Stark who joins the Night's Watch. Jon is a talented fighter, but his sense of compassion and justice brings him into conflict with his harsh surroundings. Ned claims that Jon's mother was a wet nurse named Wylla. His dire wolf is called Ghost due to his albinism and quiet nature. Jon soon learns that the Watch is no longer a glorious order, but is now composed mostly of society's rejects, including criminals and exiles. Initially, he has only contempt for his low-born brothers of the Watch, but he puts aside his prejudices and befriends his fellow recruits, especially Sam Tarly, after they unite against the cruel master-at-arms. He chooses to take his vows before the Old God of the North, and to his disappointment he is made steward to Lord Commander Jeor Mormont rather than a ranger. He eventually realizes that he is being groomed for command. He saves Mormont's life by slaying a wight, a corpse resurrected by the White Walkers. In return, he receives Longclaw, the ancestral blade of House Mormont. When Eddard is arrested for treason, Jon is torn between his family and his vows. After Eddard's execution, he tries to join Robb's army but is convinced to come back by his friends. Shortly after, he joins the large force Mormont leads beyond the Wall. Jon is part of a small scouting party in Season 2. When the party is overtaken by wildlings, Jon is ordered to appear to defect and join the wildlings so he can discover their plans. On affirming his loyalty to the King-Beyond-the-Wall, Mance Rayder, he travels toward the Wall with the wildlings and is seduced by one, the flame-haired Ygritte. Upon crossing the wall, he refuses to behead a farmer whose escape might alert the Night's Watch of their coming, and is subsequently branded an enemy of the wildlings. Ygritte shields him from her comrades but ultimately confronts and injures Jon when he stops to drink. He manages to escape back to the wall, injured by three arrows, where he reunites with his comrades and informs the commanders of Mance Rayder's plans. Jon subsequently resumes his training at the Wall and suggests an expedition to Craster's Keep in order to kill the Night's Watch mutineers who may tell Mance of the Wall's weak defences if caught. Jon's request is granted and he bands together a group of rangers to aid him, among them the new recruit Locke, who has actually come to kill Jon on Roose Bolton's orders. Jon successfully attacks Craster's Keep and kills the mutineers, while Locke is killed by Hodor during an attempt to kill Bran, who was captive at Craster's Keep. However, Jon's proposal to barricade the entrance to Castle Black to stop the wildlings from entering is denied. He survives the wildling attack on Castle Black, personally killing Styr and taking Tormund Giantsbane prisoner. In the aftermath, he departs Castle Black to hunt down Mance Rayder, giving his sword to Sam. He quickly locates Mance on the pretence of parleying, but he is found out. Before he is killed, however, Jon is saved by the timely arrival by Stannis Baratheon, who places Mance and his men under arrest, and accompanies Jon back to Castle Black. Jon later burns Ygritte's body in the woods. In Season 5, Stannis attempts to use Jon as an intermediary between himself and Mance, hoping to rally the wildling army to help him retake the North from Roose Bolton and gain Jon's support in avenging his family. Jon fails to convince Mance, and when Mance is burned at the stake by Stannis' red priestess Melisandre, Jon shoots him from afar to give him a quick death. After that Jon is chastised by Stannis for showing mercy to Mance. Stannis shows Jon a letter he received from Bear Island, stating that former Lord Commander Jeor Mormont's relatives will only recognize a Stark as their King. Ser Davos tells Jon that the Night's Watch will elect a new Lord Commander that night, and that it is almost assured that Ser Alliser will win. Stannis asks Jon to kneel before him and pledge his life to him, and in exchange he will legitimize Jon, making him Jon Stark, and giving him Winterfell. In the great hall, Jon tells Sam that he will refuse Stannis's offer, as he swore an oath to the Night's Watch. After Ser Alliser and Denys Mallister are announced as possible candidates, Sam gives a speech imploring his brothers to vote for Jon, reminding them all how he led the mission to Craster's Keep to avenge Commander Mormont's death and how he led the defense of Castle Black. After the voting is complete, the ballots are tallied and show a tie between Jon and Ser Alliser. Maester Aemon casts the deciding vote in favor of Jon, making him the new Lord Commander of the Night's Watch. To lessen the animosity between the two, Jon makes Ser Alliser First Ranger. Melisandre takes an interest in Jon, visiting him in his quarters and trying to have sex with him. Jon refuses, out of respect for Ygritte and his Night's Watch vows. Jon makes plans to give the wildlings the lands south of the wall, known as the gift. He wants the Night's Watch and the wildlings to unite against the threat of the White Walkers. These more liberal views are not taken well by the men of the Night's Watch, in particular Ser Alliser and a young boy named Olly, whose village was massacred by wildlings. Jon then makes a trip north of the Wall to the wildling village of Hardhome, where he hopes to get the wildlings to join his cause. However, before many of them can get on boats to leave, a massive group of White Walkers arrives on the scene. A massive battle ensues, in which many wildlings are killed. The last remaining Night's Watchmen and wildlings, including Jon, depart from Hardhome, defeated. As they return to the Wall, they are let in by Ser Alliser Thorne, who disapproves of his drastic action of joining forces with the wildlings. Shorty after, Jon sends Sam and Gilly to safety in Oldtown, approving of their relationship and Sam's motives of keeping her safe. He is later approached by Davos asking for men, and later Melisandre, whose silence confirms Stannis's defeat. That evening, Jon is met by Olly who claims that a range has arrived with knowledge of Jon's uncle Benjen. However, Jon discovers that he has been fooled and a mutinee, led by Ser Alliser Thorne, stab Jon repeatedly, with Olly dealing the final blow to Jon's heart, leaving him to die in the snow.","tags": ["stark","night's watch","brother","snow"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Jaime Lannister",
      "_score" : 0.0314803,
      "_source":{"house": "Lannister","gender": "male","age":34,"biography": "Ser Jaime Lannister is a member of the Kingsguard and an exceptionally skilled swordsman. He is the Queen's twin brother and has carried on an incestuous love affair with her all his life, fathering all three of her living children. He truly does love his sister and will do anything, no matter how rash, to stay close to her. He is nicknamed Kingslayer for killing the previous King, Aerys II, whom he was sworn to protect. He was allowed to keep his post in the current Kingsguard as he and his influential father helped Robert win the war, but no one feels he deserves this post, which frustrates Jaime. Despite Eddard Stark's animosity against him for forsaking his oath to protect the King during Robert's Rebellion, Jaime has great respect for Eddard, whom he considers a great warrior and his equal. Unlike his father and sister, Jaime cares deeply about his younger brother Tyrion. When Tyrion is arrested by Catelyn, Jaime confronts Eddard and duels him, much to Jaime's joy. But to his displeasure, one of his men interferes with the fight by spearing Eddard, whereupon Jaime punches the man and lets Eddard live. Jaime later joins his father's campaign in the Riverlands as a revenge for Catelyn's actions by leading an army. However, his army is ambushed by Robb's army and Jaime is made prisoner of the Starks. Despite his capture, Cersei names him Lord Commander of the Kingsguard after Barristan Selmy is dismissed. In Season 2, Catelyn releases and sends Jaime to King's Landing under Brienne of Tarth's watch in exchange for a pledge to send her daughters home. On the journey, they are captured by the violent Locke, a man-at-arms under Roose Bolton, a Northern Lord. On their way to Harrenhal, now held by Bolton, the lowborn Locke cuts off Jaime's sword hand to taunt his position and privilege. Jaime survives and is allowed to depart Harrenhal on condition that he acquits Bolton from any guilt (unbeknownst to him, Bolton had conspired with Tywin and Walder Frey to assassinate Robb Stark, an alliance put in jeopardy by Locke's actions). During his time in Harrenhal, Jaime reveals to Brienne on why he killed King Aerys II; Aerys planned to burn King's Landing by igniting a large stock of Wildfire hidden under the city to ensure its destruction; Jaime killed the King to prevent the Wildfire plot and didn't tell Ned Stark the truth, knowing he wouldn't listen to an oathbreaker. After Bolton's departure, Jaime returns to Harrenhal just in time to save Brienne from Locke, who intended to feed her to his bear rather than accept her father's offer for a ransom. Locke reluctantly allows them to leave rather than kill Jaime as well, knowing it would earn him the enmity of Boltons as well as Lannisters. Jaime travels to King's Landing with Brienne and disgraced Maester Qyburn, given by Bolton to tend to his injury, in tow. At the end of Season 3, they arrive at the gates and Jaime reunites with Cersei, who is visibly shocked at his missing hand. In season 4, Jaime is fitted with a golden prosthetic hand and given a new sword, and is trained by Bronn in fencing with his left hand. He is present at the royal wedding that results in Joffrey's death (which Tyrion is arrested for), as well as the funeral. Jaime is one of the few people in King's Landing who believe in Tyrion's innocence, and does his best to comfort his younger brother, while outright refusing Cersei's order to kill Tyrion before his trial. At the trial, Jaime is visibly uncomfortable at the lies the witnesses are telling and confronts Tywin. In desperation, Jaime agrees to step down from the Kingsguard and serve as Tywin's heir if he spares Tyrion and exiles him to the Night's Watch instead of executing him. When Tyrion is sentenced to death, Jaime frees Tyrion from captivity and arranges for him to be smuggled to Essos with Varys's help, bidding his little brother farewell with a hug. This leads to Tywin's murder at Tyrion's hands, for which Cersei holds Jaime partly responsible. Jaime pays his respects at Tywin's funeral. Jaime and Cersei receive a message from Dorne: a small viper statue with a necklace in its fangs. Cersei tells Jaime that the necklace belongs to their daughter, Myrcella, who was sent to Dorne by Tyrion. Jaime tells Cersei that he will travel to Dorne and bring Myrcella back. He travels to meet with Bronn, who has gone to Castle Stokeworth with Lollys, his fiancée. Jaime gives Bronn a letter telling him that he will not be wed to Lollys. When Bronn reminds him of the deal he had with Cersei, Jaime tells him that, should he agree to help rescue Myrcella, he will instead be wed to a woman of higher standing, with a larger castle. The two head south on a ship. Upon arriving in Dorne, the two are almost instantly attacked by a group of Dornishmen. Jaime and Bronn defeat them and take their horses and clothing. They then go to the Water Gardens, where they surprise Myrcella and her betrothed, Trystane Martell. They are soon attacked by Oberyn Martell's bastard daughters, the Sand Snakes. Before any serious damage can be done, Prince Doran Martell's guard Areo Hotah halts the fighting. Jaime is placed in a luxurious cell, where he attempts to talk to Myrcella. Myrcella says that she likes it in Dorne and doesn't want to go back to King's Landing. However, she eventually leaves with her uncle and Trystane, after Doran bargains to have his son take his seat on the Small Council. On the journey home, Jaime reveals his incestuous relationship to Cersei to their daughter, who then reveals she knows and is glad that Jaime is her father and hugs him, but moments later Myrcella collapses from poison and dies.","tags": ["lannister","king slayer","golden hand","ser","blond"]}
    } ]
  }
}
{% endhighlight %}

I got 6 results. Well you can notice that the result doesn't include the character "Robb Stark", as its age in our dataset
is defined to 22 (so it doesn't satisfy the *must_not* clause).

### The Function Score Query

The **Function Score Query** is one of the most powerful compound query in Elasticsearch. Basically, it allows you to
define a new scoring function! Isn't it amazing?

As we saw right before, the relevance scoring function of Elasticsearch is a mix between a lot of mathematical coefficients.

But, what if the default relevance scoring function is not relevant to you? What if you'd like to define your own relevance
scoring function? Well, that is possible!

The compound query **Function Score Query** is one of the most complex query of Elasticsearch, as it is really complete,
and allows you to manipulate the score in a lot of different ways.

To perfectly understand how it works, we should first take a look at the query's structure:

{% highlight json %}
{
  "query": {
    "function_score": {
        "query": {
            [...]
        },
        "boost": "aBoostValue",
        "functions": [
            [...]
        ],
        "boost_mode": "boostMode",
        "max_boost": maxBoost,
        "score_mode": "scoreMode",
        "min_score": minScore
    }
  }
}
{% endhighlight %}

So, several points to be discussed:

- the `query` field is the place where you define your query.
- the `boost` field is the place where you define a boost value that will be applied to the whole query.
- the `functions` field is the place where you will define the functions that calculates the score. As you may have
noticed, this field is an array, meaning that you can define one or more relevance scoring functions.
- the `boost_mode` field defines the type of boost mode (multiply, replace, ...) that you will use.
- the `max_boost` is an optional field, and as it name suggests, it allows you to define a maximum score.
- the `score_mode` is an optional field that allows you to define the score mode (max, multiply, ...).
- the `min_score` is an optional field that allows you to define the minimal score.

As I told you, several relevance scoring functions can be defined, and you can choose which one to apply according
the match to a given filter.

#### The possible scoring functions

As there is 5 different possible scoring functions, I am not going to introduce them all. I will just go through one of
them, which is the `script_score` function.

##### The script_score function

The first scoring function I am introducing is the *script_score* function. It allows you to manipulate the score with
scripting.

If you don't remember well about scripting, I did talk a bit about it in the second article.

When defining a **script_score** function, different variables will be available to you:

- `_score` is the score calculated with the default algorithm of Elasticsearch (Apache Lucene)
- `doc` allows you to access the document's fields.

Also, you will be able to define some parameters, with the `params` field.

Let's have a look to the structure:

{% highlight json %}
{
  "script_score": {
    "params": {
        "my_param_1": value,
        "my_param_2": value
    },
    "script": "theScriptGoesHere"
  }
}
{% endhighlight %}

**be careful though, the result of the script is not going to be the final score of the document by default. If you wish
this score to be the final score, you'll have to set the `boost_mode` to "replace".**

Let's take an example: I want the *final score* of my query to be the age of my *character* divided by two. Quite simple.
My query will be a *term* query on the `house field, to "Lannister".

The query would then be the following:

{% highlight json %}
{
  "query": {
    "function_score": {
        "query": {
            "match": {
                "house": "Lannister"
            }
        },
        "functions": [
            {
                "script_score": {
                    "script": "doc['age'].value / 2"
                }
            }
        ],
        "boost_mode": "replace"
    }
  }
}
{% endhighlight %}

Well you can see it is quite simple. Under the `query` field, I defined a *match* query on the `house` field of the document.
Then, under the `functions` array, I added an object that contains my `script_score` script. This script takes the value of
the field `age` of the document, and divides it by two. Finally, I set the `boost_mode` to "replace", so that the final
score is the score calculated by my script.

The query is available at `queries/DSL/compound_query_score_script.json`, let's run it:

{% highlight sh %}
$>curl -XPOST 'http://localhost:9200/game_of_thrones/_search?pretty' -d @queries/DSL/compound_query_score_script.json
{% endhighlight %}

{% highlight json %}
{
  "took" : 96,
  "timed_out" : false,
  "_shards" : {
    "total" : 5,
    "successful" : 5,
    "failed" : 0
  },
  "hits" : {
    "total" : 4,
    "max_score" : 35.0,
    "hits" : [ {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Tywin Lannister",
      "_score" : 35.0,
      "_source":{"house": "Lannister","gender": "male","age":70,"biography": "Lord of Casterly Rock, Shield of Lannisport and Warden of the West, Tywin is a calculating, ruthless, and controlling man. He is also the former Hand of King Aerys II. He is the father of Cersei, Jaime, and Tyrion. After Eddard Stark's arrest, Joffrey names him Hand of the King once more, but after Jaime is taken captive by the Starks, Eddard is unexpectedly executed by Joffrey, and Renly and Stannis Baratheon challenge Joffrey's claim to the throne; Tywin elects to remain in the field commanding his forces until he wins his war, and in the meantime gives the position of Hand of the King to Tyrion. Tywin continues the war through Season 2 at Harrenhal where he criticizes his commanders for losing and underestimating the Stark army led by King Robb Stark. While there, he forms an unlikely friendship with his cup bearer, unaware that she is actually Arya Stark. Originally, he was about to attack Robb's forces while they are distracted by the Greyjoys seizing Winterfell, but changes his mind and helps the defenders of King's Landing drive Stannis Baratheon's forces away. He assumes his position of Hand of the King once again and arranges for Joffrey to marry Margaery Tyrell to secure an alliance between the Lannisters and Tyrells. In the third season, as Hand of the King, he fortifies his position as de facto leader of the Seven Kingdoms, and he successfully defeats Robb Stark, the King in the North, by forging an alliance with the lords Frey and Bolton, who betray and kill Stark and his men. The crown subsequently pardons and rewards them with Riverrun and the North, respectively, though Tywin is criticized by Tyrion for winning the war through such an unscrupulous scheme. He also has to deal with an increasingly belligerent Joffrey, who chides his grandfather as a coward who hid under Casterly Rock while Robert Baratheon led the rebellion against Aerys Targaryen, and complicated relations with his children as he forces them into marriage alliances with Sansa Stark and Loras Tyrell, to secure the support of the Tyrells and Lannister dominion in the North (now Sansa's heirdom, as all her brothers are presumed dead). In the fourth season, Tywin is present at the royal wedding where Joffrey dies, and has King's Landing closed off to prevent Sansa from escaping (although she escapes with help from Petyr Baelish and Dontos Hollard). He grooms Joffrey's younger brother, Tommen, to becoming the new King, and appears determined to make sure Tommen becomes a much better King than Joffrey was. The presence of Prince Oberyn Martell of Dorne poses a new problem, however, as he resurfaces the Martell–Lannister antagonism over the rape and murder of his sister Elia by Gregor The Mountain Clegane during the Robert's Rebellion; Oberyn believes the deed was done on Tywin's order. Tywin denies the allegations and promises Oberyn justice in exchange for Oberyn serving as one of the judges at Tyrion's trial. At the trial, when several supposed witnesses give false statements regarding Tyrion's supposed guilt, Tywin promises Jaime in private that if Tyrion is found guilty and pleads for mercy, he will exile him to the Night's Watch but only if Jaime ceases to be a Kinsguard and takes his place as heir to House Lannister. However, Tyrion loses his composure, lashes out at Tywin and demands a trial by combat, to Tywin's anger. When Tyrion's champion, Oberyn, loses the fight and is killed, Tywin sentences his son to death. Later, when Jamie helps Tyrion escape, Tyrion discovers that Tywin was having an affair with Shae, Tyrion's former lover, who falsely testified against him at his trial. Tywin is ambushed by Tyrion while in a privy, wielding Joffrey's crossbow. Tywin attempts to reason with Tyrion, swearing that he would never have had him executed, but also – upon Tyrion showing regret for Shae's death – taunts him as afraid of a dead whore. In rage, Tyrion shoots Tywin twice in the chest, killing him. His body is discovered shortly afterwards, and a grand funeral is held in the Sept of Baelor. As revealed by Davos Seaworth, he was 67 years old. Tywin's death heralds instability in the Seven Kingdoms, with the arrival of the Sparrows in the capital, and rivalry rising between Cersei, who aspires to her father's position but lacks many of his statesmanlike qualities, and the Tyrells. The Boltons also lose the potential Lannister military support just when they are faced with Stannis Baratheon planning to take Winterfell on his way to the Iron Throne.","tags": ["lannister","father"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Cersei Lannister",
      "_score" : 17.0,
      "_source":{"house": "Lannister","gender": "female","age":34,"biography": "Cersei Lannister, Queen of the Seven Kingdoms of Westeros, is the wife of King Robert Baratheon. Her father arranged the marriage when she was a teenager, initiating himself as a political counselor for King Robert. The Lannisters are the richest family in Westeros,[31] which is why Robert was interested in a marriage between them. Cersei has a twin brother, Jaime, with whom she has been involved in an incestuous affair from early childhood. All three of Cersei's children are Jaime's.[31] Cersei's main character attribute is her desire for power and her deep loyalty to her father, children, and brother Jaime. Cersei learns that her husband Robert is in danger of finding out that the children he sees as his heirs to the throne are not his. Robert meets his end as the result of a boar attack on a hunting trip, before Ned Stark tells him of the truth about his children. Cersei works quickly to instate her oldest son, Joffrey, on the throne, with her as his chief political advisor and Queen Regent.[32] Joffrey quits listening to his mother, and by the beginning of the second season her father decides Cersei does not exercise enough control over her son, and her father sends his youngest son Tyrion as an additional political advisor. Cersei and Tyrion do not get along, and constantly try to undermine each other's authority over the crown. As of the end of season 2, Tyrion has accumulated more sway over the Iron Throne, and has shipped Cersei's only daughter off against Cersei's will to be married to the prince of Dorne. In season 3, she takes pleasure in Tyrion's diminished position and taunts him for being forced into a marriage pact with Sansa Stark, only to be told by her father that he intends to marry her to Loras Tyrell. At the end of the season, the two siblings ponder at their respective marriages, and Cersei reunites with Jaime in her bedchamber as he unexpectedly returns from captivity. In season 4, she has Tyrion arrested after Joffrey is fatally poisoned. It is implied that she knows Tyrion's guilt is highly unlikely, but just wants to see him dead, though Jaime refuses to carry out the order.[33] Indeed, at Tyrion's trial, it is obvious that Cersei has manipulated the entire procedure so that the only witnesses (herself, Lord Varys, Meryn Trant, Grand Maester Pycelle and Shae) give either incomplete or entirely false testimonies to implicate Tyrion and Sansa further in the murder. When Tyrion demands a trial by combat, Cersei quickly chooses Ser Gregor The Mountain Clegane as her champion to diminish Tyrion's chances of acquittal, and has Bronn betrothed to a noblewoman so that Tyrion cannot choose him as his champion. Cersei's wish comes true when Tyrion's champion, Oberyn Martell, is killed by Clegane, but she still refuses to marry Loras, even threatening her father with revealing the truth about her relationship with Jaime and the parentage of her children. Tywin rebuffs her threats, though he himself is killed by an escaping Tyrion soon afterwards. Cersei attends Tywin's funeral and later orders a bounty on Tyrion's head. Cersei and Jaime receive a message from Dorne: a small viper statue with a necklace in its fangs. Cersei tells Jaime that the necklace belongs to their daughter, Myrcella, who was sent to Dorne by Tyrion. Jaime tells Cersei that he will travel to Dorne and bring Myrcella back. Cersei meets with two hunters who have brought her a severed head, though she is disappointed to find that it is not Tyrion's head. Qyburn lays claim to the head for his research and the two walk to a small council meeting. With the office of Hand of the King vacant, Cersei tells the council that she will stand in temporarily until Tommen chooses a new Hand. She appoints Mace Tyrell as the new Master of Coin and Qyburn as the new Master of Whisperers. When Cersei tries to appoint her uncle Kevan as the Master of War, he declines, telling her that as the queen mother she holds no power, and has no interest in serving in a council filled with her sycophants. In defiance of Cersei's orders, Kevan states that he will return to Casterly Rock until he hears direct word from Tommen that he is required. Tommen soon weds Margaery Tyrell. Under Margaery's influence, Tommen drops hints that he would like Cersei to return to Casterly Rock, but she refuses, and confronts Margaery, who insults her. Cersei catches the High Septon being punished for entering a brothel by her cousin Lancel, who has become a member of the Faith Militant, an extremist group that worships the Seven. Cersei talks to their leader, the High Sparrow, and instates him as the new High Septon. The Faith Militant then aggressively puncture all barrels of wine and trash Petyr Baelish's brothel. They also arrest Margaery's brother Loras on the grounds of his homosexuality. Tommen, at Margaery's insistance, tries to get Cersei to release Loras, but Cersei swears she had nothing to do with it, After a trial, Loras is arrested after a prostitute named Olyvar testifies against Loras. Margaery is also arrested for lying about Loras' sexual orientation, and both are put in dungeons. All of this delights Cersei, who goes to see Margaery in her cell and brings her a bowl of venison stew. Cersei has one final talk with the High Sparrow about the accomplishments of the pair, but he soon reveals that Lancel has confessed everything (in Season 1, Cersei had sex with him in Jaime's absence). Cersei is subsequently arrested for adultery, incest, and murder (it was her plan to get Robert drunk so that he would injure himself while hunting). She is only visited in her cell by Qyburn, who tells her that Grand Maester Pycelle has seized power of the throne, and that Kevan is serving as hand of the king. Cersei is distraught to learn that Tommen, anguished over his wife's and mother's arrests, has not been eating. Cersei is also visited by a septa, who orders her to confess to her sins. Cersei refuses, and she is hit by the septa. Weakened, Cersei is forced to lick the water off the floors of the cell. She eventually agrees to reveal herself to the High Septon, confessing her incestuous relationship to Lancel Lannister but refusing to admit more serious offences, which would be harder for the Faith to prove. The High Sparrow allows her to leave captivity in favor of house arrest in the Red Keep, pending the trial, but only if she agrees to do atonement for her sins by being shaved and walking naked through the streets of King's Landing. Cersei endures the walk with great resolve, bleeding and covered in filth as she eventually reaches the Keep, where she reunites with her uncle Kevan, now Hand of the King, and Qyburn, who introduces her to the newest member of the Kingsguard, a freakishly large, silent giant implied to be the reanimated corpse of Gregor Clegane.","tags": ["lannister","queen","baratheon","shame"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Jaime Lannister",
      "_score" : 17.0,
      "_source":{"house": "Lannister","gender": "male","age":34,"biography": "Ser Jaime Lannister is a member of the Kingsguard and an exceptionally skilled swordsman. He is the Queen's twin brother and has carried on an incestuous love affair with her all his life, fathering all three of her living children. He truly does love his sister and will do anything, no matter how rash, to stay close to her. He is nicknamed Kingslayer for killing the previous King, Aerys II, whom he was sworn to protect. He was allowed to keep his post in the current Kingsguard as he and his influential father helped Robert win the war, but no one feels he deserves this post, which frustrates Jaime. Despite Eddard Stark's animosity against him for forsaking his oath to protect the King during Robert's Rebellion, Jaime has great respect for Eddard, whom he considers a great warrior and his equal. Unlike his father and sister, Jaime cares deeply about his younger brother Tyrion. When Tyrion is arrested by Catelyn, Jaime confronts Eddard and duels him, much to Jaime's joy. But to his displeasure, one of his men interferes with the fight by spearing Eddard, whereupon Jaime punches the man and lets Eddard live. Jaime later joins his father's campaign in the Riverlands as a revenge for Catelyn's actions by leading an army. However, his army is ambushed by Robb's army and Jaime is made prisoner of the Starks. Despite his capture, Cersei names him Lord Commander of the Kingsguard after Barristan Selmy is dismissed. In Season 2, Catelyn releases and sends Jaime to King's Landing under Brienne of Tarth's watch in exchange for a pledge to send her daughters home. On the journey, they are captured by the violent Locke, a man-at-arms under Roose Bolton, a Northern Lord. On their way to Harrenhal, now held by Bolton, the lowborn Locke cuts off Jaime's sword hand to taunt his position and privilege. Jaime survives and is allowed to depart Harrenhal on condition that he acquits Bolton from any guilt (unbeknownst to him, Bolton had conspired with Tywin and Walder Frey to assassinate Robb Stark, an alliance put in jeopardy by Locke's actions). During his time in Harrenhal, Jaime reveals to Brienne on why he killed King Aerys II; Aerys planned to burn King's Landing by igniting a large stock of Wildfire hidden under the city to ensure its destruction; Jaime killed the King to prevent the Wildfire plot and didn't tell Ned Stark the truth, knowing he wouldn't listen to an oathbreaker. After Bolton's departure, Jaime returns to Harrenhal just in time to save Brienne from Locke, who intended to feed her to his bear rather than accept her father's offer for a ransom. Locke reluctantly allows them to leave rather than kill Jaime as well, knowing it would earn him the enmity of Boltons as well as Lannisters. Jaime travels to King's Landing with Brienne and disgraced Maester Qyburn, given by Bolton to tend to his injury, in tow. At the end of Season 3, they arrive at the gates and Jaime reunites with Cersei, who is visibly shocked at his missing hand. In season 4, Jaime is fitted with a golden prosthetic hand and given a new sword, and is trained by Bronn in fencing with his left hand. He is present at the royal wedding that results in Joffrey's death (which Tyrion is arrested for), as well as the funeral. Jaime is one of the few people in King's Landing who believe in Tyrion's innocence, and does his best to comfort his younger brother, while outright refusing Cersei's order to kill Tyrion before his trial. At the trial, Jaime is visibly uncomfortable at the lies the witnesses are telling and confronts Tywin. In desperation, Jaime agrees to step down from the Kingsguard and serve as Tywin's heir if he spares Tyrion and exiles him to the Night's Watch instead of executing him. When Tyrion is sentenced to death, Jaime frees Tyrion from captivity and arranges for him to be smuggled to Essos with Varys's help, bidding his little brother farewell with a hug. This leads to Tywin's murder at Tyrion's hands, for which Cersei holds Jaime partly responsible. Jaime pays his respects at Tywin's funeral. Jaime and Cersei receive a message from Dorne: a small viper statue with a necklace in its fangs. Cersei tells Jaime that the necklace belongs to their daughter, Myrcella, who was sent to Dorne by Tyrion. Jaime tells Cersei that he will travel to Dorne and bring Myrcella back. He travels to meet with Bronn, who has gone to Castle Stokeworth with Lollys, his fiancée. Jaime gives Bronn a letter telling him that he will not be wed to Lollys. When Bronn reminds him of the deal he had with Cersei, Jaime tells him that, should he agree to help rescue Myrcella, he will instead be wed to a woman of higher standing, with a larger castle. The two head south on a ship. Upon arriving in Dorne, the two are almost instantly attacked by a group of Dornishmen. Jaime and Bronn defeat them and take their horses and clothing. They then go to the Water Gardens, where they surprise Myrcella and her betrothed, Trystane Martell. They are soon attacked by Oberyn Martell's bastard daughters, the Sand Snakes. Before any serious damage can be done, Prince Doran Martell's guard Areo Hotah halts the fighting. Jaime is placed in a luxurious cell, where he attempts to talk to Myrcella. Myrcella says that she likes it in Dorne and doesn't want to go back to King's Landing. However, she eventually leaves with her uncle and Trystane, after Doran bargains to have his son take his seat on the Small Council. On the journey home, Jaime reveals his incestuous relationship to Cersei to their daughter, who then reveals she knows and is glad that Jaime is her father and hugs him, but moments later Myrcella collapses from poison and dies.","tags": ["lannister","king slayer","golden hand","ser","blond"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Tyrion Lannister",
      "_score" : 15.0,
      "_source":{"house": "Lannister","gender": "male","age":30,"biography": "Nicknamed The Imp or Halfman, Tyrion Lannister is the younger brother of Cersei and Jaime Lannister. He is a dwarf; and his mother died during his birth, for which his father, Tywin Lannister, blames him. While not physically powerful, Tyrion has a cunning mind and often uses to his advantage the fact that others constantly underestimate him. Initially, Tyrion bears the Starks no ill will, but after being wrongly captured and put on trial for the crime of murdering Jon Arryn and conspiring to kill Bran Stark, both of which he had no hand in or knowledge of, his ire toward Lady Catelyn prompts him to join his father's war against the Starks. At the end of the Lannister army's first loss against Robb Stark's army, after Jaime Lannister is captured, they learn that King Joffrey has killed Ned Stark against their wishes and Robert's brothers are challenging Joffrey's claim to the throne. To ensure that someone trusted controls Joffrey while he deals with the war effort, Tywin sends Tyrion to rule in his stead as Hand of the King, finally taking notice of his lesser son's cunning intellect. He arrives in King's Landing and immediately enters a bitter power struggle with Cersei and Joffrey, methodically removing the Queen's supporters from positions of power. With his small army of hill tribesmen and his mercenary friend Bronn leading the City Watch, he becomes one of the most powerful men in the city. Before Stannis' fleet arrives at King's Landing, Tyrion prepares the attack by stockpiling large quantities of Wild Fire, putting it all in a single ship, and sending it towards Stannis' fleet. Bronn detonates the Wild Fire, causing a giant explosion and destroying half of Stannis' forces. When the city's defenders morale drops after Joffrey abandons them, Tyrion rallies the men and leads a surprise counterattack against the besiegers. During the battle, he is betrayed and nearly killed by a member of the Kingsguard under the orders of Joffrey, but he is saved by his squire Podrick Payne. When he wakes up after the battle is over, Tyrion learns that his father Tywin has taken over as Hand of the King and stripped his son of all power and all the allies he had gained. Furthermore, Tyrion's role in helping defend King's Landing is completely discounted for. Despite this setback and his lover Shae's telling him to leave Westeros, Tyrion still wants to stay, since he has finally found something he both excels at and enjoys—out-talking and out-thinking his less than noble family members. In Season Three, Tyrion is given the job of Master of Coin, a role that he is unprepared and inexperienced for. Tyrion is commanded by his father to marry Sansa Stark; however, on the wedding night, Tyrion refuses to consummate his marriage and instead lets Sansa sleep alone, promising not to touch her unless she wanted him to. The death of her brother Robb, in which Tyrion took no part, causes a further rift between the couple and between Tyrion and his father, who he claims can't distinguish between his interests and his often-praised ideal of devotion to family. Tywin bitterly claims that he had wanted to drown Tyrion upon birth, but stayed himself for the sake of duty. In season 4, Tyrion welcomes Prince Oberyn Martell of Dorne to King's Landing for Joffrey's wedding to Margaery Tyrell, though Oberyn implies to Tyrion that his true purpose is to seek vengeance for his sister, who was murdered by Ser Gregor Clegane on Tywin's orders. When Joffrey is fatally poisoned, Tyrion is framed and arrested, though several people, such as Jaime, Bronn and Sansa, do not believe he committed the crime (Olenna Tyrell, Petyr Baelish and Dontos Hollard were responsible). Tyrion, however, implies that Cersei knows of his innocence and just wants him dead. At Tyrion's trial, several witnesses give either incomplete or false testimonies which seem to bolster the case against Tyrion. Tyrion finally loses his temper and lashes out at the entire court, wishing that he had killed Joffrey and left them all to die when Stannis attacked, and demands a trial by combat. When Jaime and Bronn prove unavailable, Tyrion is approached by Oberyn, who volunteers to be his champion in order to fight Cersei's champion, Ser Gregor Clegane. When Oberyn loses the fight and is killed, Tyrion is sentenced to death. Jaime, however, frees Tyrion and arranges for him to escape King's Landing. Tyrion goes to confront Tywin in his chambers but finds Shae, who testified against him and is now Tywin's lover. After a brief struggle, Tyrion strangles Shae to death, and finds Tywin in a privy. The two share a tense conversation, in which Tywin insults Shae once too many times, and Tyrion shoots Tywin to death with Joffrey's crossbow. Tyrion is then placed in a crate and smuggled off to Essos with help from Varys. They arrive in Pentos, where Varys manages to convince Tyrion to travel with him to Meereen and aid Daenerys Targaryen in retaking the Iron Throne. Travelling to Volantis, Tyrion and Varys discuss the former's brief tenure as Hand of the King. Tyrion laments not leaving King's Landing with Shae when he had the chance, but tells Varys that he enjoyed serving as Hand. Tyrion is bound and gagged by Jorah Mormont, who says that he will take him to the queen. He ends up in a sailboat with Jorah, whose identity Tyrion quickly deduces when he tells Tyrion that he is taking him to Daenerys, not Cersei. The journey goes relatively smoothly, until Jorah decides to avoid pirates by sailing straight through the ruins of Valyria, which is overrun with people (known as stone men) who have a deadly condition known as greyscale, which Stannis' daughter Shireen also has. Tyrion and Jorah are soon attacked by stone men, and the pair struggle to defend themselves. Tyrion is grabbed by one of the stone men and dragged underwater, losing consciousness. When Tyrion wakes up, he finds himself out of harm's way on a beach, as Jorah caught him and swam to safety. As the stone men did not touch Tyrion's bare skin, he is not affected by the disease; however, Jorah is not so lucky. Jorah tells Tyrion that the two will walk to Meereen, During the walk, Jorah tells Tyrion why he serves Daenerys, which makes him eager to meet her. En route, however, they are captured by slavers, who sell Jorah off to a man named Yezzan mo Qaggaz, who oversees the training for the gladiatorial match in the fighting pits which Daenerys has recently reopened. Tyrion also manages to get himself sold to Yezzan as well by beating up his guard. Tyrion and Jorah are taken to a pit, where they wait their turn to fight. Coincidentally, Daenerys visits this particular fighting pit while Tyrion and Jorah are there. When Jorah hears of Daenerys' presence, he runs out to fight without waiting his turn. All of the other combatants run out as well, leaving Tyrion alone inside the waiting room. Since Tyrion is the only one chained up, he frantically begins sawing at his chain. An unnamed guard snaps Tyrion's chain, and he runs out to find that Jorah has defeated all of his competitors and has unveiled himself to Daenerys. She is not happy to see him, however, and orders him out of her sight. He tells her that he has brought her a gift, and Tyrion appears, telling a stunned Daenerys of his identity. Daenerys takes them both to her home in the Great Pyramid of Meereen and asks Tyrion why he is here. Tyrion tells her everything, including Varys' plan. As a test, Daenerys asks Tyrion what to do with Jorah. Tyrion tells her that though it would be wrong to kill Jorah, as killing those who love you does not inspire devotion, it would also not be wise to keep him around, as he has betrayed her. Daenerys subsequently banishes Jorah again, and takes Tyrion on as her advisor. He initially counsels her to stay in Meereen, but Daenerys makes it plain to him that her eyes are still on Westeros. Tyrion tells Daenerys how hard it will be to win the love of both the common people and the nobles. He later joins her at the opening celebrations of Daznak's Pit, where Jorah unexpectedly reappears to defeat every other foe on the arena. As the Sons of the Harpy attack, Tyrion manages to survive by fleeing to the midst of the arena, where they are rescued by Drogon, while Daenerys is spirited away on his back. He confers with Daario, Jorah and Grey Worm, who agree that Tyrion should stay behind with the latter to rule Meereen, being the only one with the experience required. Varys reappears, wishing him good fortune as their predicament in the absence of Daenerys seems increasingly complicated.","tags": ["imp","lannister","dead mother"]}
    } ]
  }
}
{% endhighlight %}

As you can notice, the score of the document is equal to half of the age of the corresponding document.

## Scripting

For the last part of this article, I decided to talk about scripting. Indeed, Elasticsearch comes with a very interesting
scripting feature that allow you to return custom values, or to perform some operations such as custom scoring.

If you remember well, we already talked about scripting in the previous article, where I introduced a way to perform
dynamic calculation of a virtual field.

Until Elasticsearch 1.3, the used scripting language was MVEL (an expression language for the Java Platform), but now,
Groovy is used. Yet, some other languages can be used, such as Mustach, Javascript or Python (the two last ones require
plugins to work).

If you are working under the docker cluster I provided, the scripting functions already are enabled in the `elasticsearch.yml`
file. Otherwise, you will have to enable them with the following configuration line:

`script.engine.groovy.inline.search: on`.

There is three ways to load a script in an Elasticsearch query:

- Using **inline** script by inserting the script line directly into the query
- Using **a file** that contains the script, and indicating its name to the query
- Using **a special index** named `.scripts` 

As I already introduced the first way to perform scripting, I will now have a quick tour of the second method.

### The sandboxed environment

When talking about data warehouse, or more commonly databases, security is a primordial point. Yet, scripting introduce
a lot of security concerns, as it allows to perform some operations that are off the control of Elasticsearch.

What if you were using a language that contains a huge security breach, and that anybody could easily take control
over your cluster ?

That's why Elasticsearch scripting feature is only working with sandboxed languages. Sandbox environment is a special
environment used to run untrusted scripts, so that there scope is limited.

### Scripting with file

When your needs are to use the same script at different point of your application, on different Elasticsearch queries,
it might be useful to have your script stored in one unique file.

Script files have to be stored in a specific folder: `config/scripts` in the Elasticsearch directory.

I will use a very simple example. We just took a look over custom scoring functions, and especially the `function_score`
query. We used an inline script under the `script_score` field. Yet, we can use a file instead of this inline script.

The script has to be written in a file (we will name it as `score.groovy`) located in `config/scripts` directory:

```groovy
doc['age'].value / 2
```

Then, we can run our query by indicating the `script_file` field (simply filled with the script filename):

//TODO TESTER
{% highlight json %}
{
  "query": {
    "function_score": {
        "query": {
            "match": {
                "house": "Lannister"
            }
        },
        "functions": [
            {
                "script_score": {
                    "script_file": "score"
                }
            }
        ],
        "boost_mode": "replace"
    }
  }
}
{% endhighlight %}

Also, if you are using other languages than Groovy, you can indicate the name of this language under the `lang` field
under the `script_score` field. If you need to introduce some params, the `params` field can contain an object of which
each field is a param name, and the corresponding value is the param value.

### Scripting with index

As I said, you can store scripts directly into a dedicated index named `.scripts`. Yet, there is a special REST endpoint
to manage the scripts, which is `_scripts`. A script is identified by its ID, and stored under a specific `lang`:

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/_scripts/lang/ID</span></code></pre></div>

For example, I want to store the previous script. The language I used is Groovy, and I will give it the ID `score`.

The request to index the script is the following:

//TODO Revoir & tester (.scripts index is missing)
{% highlight sh %}
$>curl -XPOST http://localhost:9200/_scripts/groovy/score -d '"script": "doc['age'].value / 2"'
{% endhighlight %}

Once the script indexed in the cluster, we can run the previous query by using `script_id` instead of `script_file`, and
by providing the ID we gave to the script (*score*). We should also provide the `lang` field with the corresponding language
of our script (*groovy*).

//TODO TESTER
{% highlight json %}
{
  "query": {
    "function_score": {
        "query": {
            "match": {
                "house": "Lannister"
            }
        },
        "functions": [
            {
                "script_score": {
                    "script_id": "score",
                    "lang": "groovy"
                }
            }
        ],
        "boost_mode": "replace"
    }
  }
}
{% endhighlight %}

### Scripting security

Scripting is a powerful feature of Elasticsearch. But with great power comes great responsibility. Indeed, scripting
is powerful, but even sandboxed environment cannot stop all attempts to attack a cluster.

If you are concerned with security in Elasticsearch (which is **primordial** if you are willing to run Elasticsearch in
a production state), a good start is [this article](https://www.elastic.co/blog/scripting-security) on the Elastic's blog.

On the other hand, if your interest is more about security research, a good start would be to look at some pull requests
done on the Metasploit framework, like [this one](https://github.com/rapid7/metasploit-framework/pull/4907).

As I also have interest into security concerns, let's have a bit of fun by trying to make this exploit by ourselves.

First of all, as described in the pull request, this security breach on Elasticsearch has a **CVE (Common Vulnerabilities
and Exposures)** code, which is *CVE-2015-1427*.

CVE has a website on which we can read the complete description of this breach: [here](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-1427).

The description is as follow:

> The Groovy scripting engine in Elasticsearch before 1.3.8 and 1.4.x before 1.4.3 allows remote attackers to bypass
the sandbox protection mechanism and execute arbitrary shell commands via a crafted script.

Well, the good point for us, as Elasticsearch user, is that this breach seems to be solved, as the concerned Elasticsearch
versions are the ones bellow 1.4.3.

As you can also see, the vulnerability has been recognized by Elasticsearch, and can be found on the list on the official
website, [here](https://www.elastic.co/community/security/).

This security breach is a good example that sandboxed environment doesn't protect your cluster from everything. As any
software or application, sandboxed environment may contain security breach.

This breach is related to the Groovy script sandboxed environment, which contains a vulnerability that allows an attacker
to execute shell commands on your cluster. Even if the shell commands are executed with the same user running Elasticsearch,
an attacker may use other exploit to perform a privilege escalation and get the root privileges.

The [related topic on PacketstormSecurity](https://packetstormsecurity.com/files/130784/ElasticSearch-Unauthenticated-Remote-Code-Execution.html) 
shows a Python script that runs the famous script:

{% highlight json %}
{
    "size":1,
    "script_fields": {
        "lupin": {
            "script": "java.lang.Math.class.forName(\\"java.lang.Runtime\\").getRuntime().exec(\\"ls -l\\").getText()"
        }
    }
}
{% endhighlight %}

As you can see, this is a simple request, coming along with a `script_fields` that describe a field named `lupin`. The
content of this field is the malicious code:

`java.lang.Math.class.forName("java.lang.Runtime").getRuntime().exec("ls -l").getText()`

The principle is simple (even if it may change a bit according to the host operating system: The script (written in Java)
gets the runtime instance of the JVM, and perform a simple `exec()` on it, which executes shell commands on the host.

I simply put a `ls -l`, which lists the content of the current directory, but you can imagine more complex operations,
such as downloading a script from a remote server, script that would perform a privilege escalation, or open a backdoor
on the host system.