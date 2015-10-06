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
