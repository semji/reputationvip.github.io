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
- **Compound Queries** are some more complicated queries //TODO COMPLETE THIS EXCERPT ABOUT COMPOUND QUERIES
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

Basically, the function is not really complicated.