---
layout: post
author: quentin_fayet
title: "Elasticsearch Always Pays His Debts"
excerpt: "Our second article about Elasticsearch"
modified: 2015-07-23
tags: [elasticsearch, fullt-text research, apache, lucene]
comments: true
image:
  feature: elastic-is-coming-ban.jpg
  credit: Alban Pommeret
  creditlink: http://reputationvip.io
---

# TODOS

- Complete excerpt with what's in the article exactly
- Set the proper date (modified : xxxx)
- Complete tags if needed
- Build summary

# ELASTICSEARCH ALWAYS PAYS HIS DEBTS

Welcome back ! First of all, if you're new to Elasticsearch and/or you don't feel comfortable with the basics of Elasticsearch,
I advise you to read our first article about Elasticsearch. You can find it here : [http://reputationvip.io/elasticsearch-is-coming](http://reputationvip.io/elasticsearch-is-coming).

From the title, you may have guessed that this set of article if following a guideline : Game Of Thrones. In this article, there is no spoilers about the TV show nor the books.

**Well, let's go !**

## ROADMAP

If you've read the first article, then you've learned all the basics required to read this article. As a little reminder, we've talked about the theoretical concepts that are
behind Elasticsearch ; we've also seen a bit about the basic architecture Elasticsearch is based on ; then, we've talked about the basics *CRUD* operations, and a bit about
**indexing**; finally, we've talked about some Elasticsearch plugins: **Head** and **Marvel**

Well, I'm keeping in mind that Elasticsearch is a full-text search engine above all. In the first article, we didn't really have fun with full-text research features. In this
article, I will talk mainly about two points:

- Indexing operations : **Mappings config** and **Batch Indexing**
- Searching operations: **Querying** and **Filtering** the results.

From now, I can tell you that we won't talk about all the query types available in Elasticsearch in this article. There is two reasons to that : the first one is that there is
plenty of query types, and the second one is that most of them are not everyday-use

***

## Indexing is back !

Before we have fun with the full-text research, I want to tell you more about **indexing**. Indeed, this operation is quite important in Elasticsearch, because the quality and the
speed of your queries directly depend on the structure of your index.

### What exactly are we talking about ?

Here, I want to deal with two operations of the indexing : **Mapping** and **Batch Indexing**. They are not the only operations of indexing, but I won't talk about the other ones
in this article, but in the next one.

The first operation we'll talk about is : **Mapping**. **Mapping** means to describe the schema of your data. As Elasticsearch is **schemaless** (it doesn't care about the schema
of the data you're giving to it), I think it is better to define the schema. There is many reasons why you should describe your data schema as far as practical. Schemaless has a
lot of advantages, **on the DB layer** (easy to go with autoscaling, for example). But on the application layer, data has a schema most often.

The second operation we'll make concerns **Batch Indexing**. Currently, we know how to index a single document into Elasticsearch. However, there is ways to index multiple documents
at the same time, being efficient and fast.

### Mapping

Well, **Mapping**. In the previous article, I did talk a bit about the index creation. In reality, index creation can be more complex, and there is a bunch of parameters that can
be configured.

#### Automated Index creation

In the last article, I did talk a bit about **index creation**. What you may not know about Elasticsearch, is that by default, you **don't need to create index before you insert
documents into it**. Well, **that's not necessarily a good thing**.

Let's imagine the following situation : You've got the automated index creation enabled, and you're quietly working on your application. Let's say that you store data in an index
called *book*. As a reminder, indices names should be written in the singular form. Now, let's assume that you've made a typo in your application, writing *book* as *boook* (with
three *o* letter). When you are running the application, you have no error. That is because **automated index creation is enabled : If Elasticsearch is not aware of the index you are
trying to insert data into, it will create it !**. And know, you're application stored data on two different indices, causing a phase shift in your data. You may spend hours before
you find this mistake of yours, because Elasticsearch will not send your application any error !

The good practice hidden behind this situation is to disable automated index creation if you don't need it.

To do so, we need to edit the configuration file *elasticsearch.yml* (or *elasticsearch.json* if you chose the JSON format) to add the following line :

`action.auto_create_index: false`

Then, if you try to insert a document into an index which hasn't been created, you will find yourself having an error from Elasticsearch :

{% highlight json %}
{
    "error": "IndexMissingException[[your_index_name] missing]",
    "status": 404
}
{% endhighlight %}

> `action.auto_create_index` can take more than a *true/false* value. You can specify several regex, separated by a coma, and begining with a *+* or a *-*, according to the
fact that you want to allow or disallow automatic index creation for the indices' names pattern that match the regex. For example :
`action.auto_create_index: -game, +game_of, -*` will disallow automatic index creation for indices' names beginning with "game" (*-game*), but allow automatic index creation
for indices' names beginning with "game_of" (*+game_of*), and finally, the `-*` will disallow automatic index creation for every other patterns.

#### Dynamic Mapping

Before we dive into defining our own mapping, it is important to understand **dynamic mapping**, how it works, and what we can configure.

**Be careful: The parameters shown bellow can only be set when creating the index. If you want to modify the mapping of an existing index, there is some tricks
involving aliases, but we will talk about it later.**

##### Type detection

When you're inserting data into Elasticsearch, they are formatted with JSON structure. Elasticsearch is able to automatically guess the type of each fields : numbers, string,
booleans. Indeed, numbers are defined with digits, strings are surrounded by quotes, and boolean are specific words. This behavior is called **type detection**.

But, what if we want this behavior to be a little different ? Several options are set by Elasticsearch to customize the type detection.  For example,
we could like digits between quotes to be recognized as numbers (the default behavior is to identify them as strings).

These parameters are specific to each index. It means that the parameters have to be set through the Elasticsearch cluster's API.

###### Numeric detection

One of these parameters is the **numeric detection**. If the `numeric_detection` parameter is set to `true`, then Elasticsearch will search into strings to find out if the string is a real string,
or if it is a number. For example, with the **numeric detection** enabled, a string like `"10"` would be considered as a number.

**The query**

To turn on the `numeric detection`, we will have to query our cluster.

The query type is `PUT`.

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/indexName</span><span style="color: chartreuse">?pretty</span></code></pre></div>

The data you need to send are the following:

{% highlight json %}
{
    "name_of_your_index": {
        "numeric_detection": true
    }
}
{% endhighlight %}

**The response**



***
