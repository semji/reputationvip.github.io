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

- **Routing** will be the first subject I will be talking about in this article. I will detail you why and how your can configure
the way your data are spread among the cluster.
- **Tree-like index structures** and **nested objects** will be my second subject. Indeed, we haven't go through every Elasticsearch data types yet.
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

//TODO check it...
The query type is `PUT` OR `POST`

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

And using this field that documents have in common, we can **indicates the cluster to use it as a routing value**.

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

//TODO Slides: indicate that difficulties may show up when using parent/child structure

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
