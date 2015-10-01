---
layout: post
author: quentin_fayet
title: "Elasticsearch Always Pays Its Debts"
excerpt: "This second article about Elasticsearch goes through mapping and the basics of full-text search"
modified: 2015-10-01
tags: [elasticsearch, fullt-text research, apache, lucene, mapping]
comments: true
image:
  feature: elastic-always-pays-its-debts-ban.jpg
  credit: Alban Pommeret
  creditlink: http://reputationvip.io
---

# ELASTICSEARCH ALWAYS PAYS ITS DEBTS

Welcome back! First of all, if you're new to Elasticsearch and/or you don't feel comfortable with the basics of Elasticsearch,
I advise you to read our first article about Elasticsearch. You can find it here: [http://reputationvip.io/elasticsearch-is-coming](http://reputationvip.io/elasticsearch-is-coming).

From the title, you may have guessed that this set of article if following a guideline: Game Of Thrones. In this article, there are no spoilers about the TV show nor the books.

**Well, let's go!**

## ROADMAP

If you've read the first article, then you've learned all the basics required to read this article. As a little reminder, we've talked about the theoretical concepts that are
behind Elasticsearch ; we've also seen a bit about the basic architecture Elasticsearch is based on ; then, we've talked about the basics *CRUD* operations, and a bit about
**indexing**; finally, we've talked about some Elasticsearch plugins: **Head** and **Marvel**

Well, keeping in mind that Elasticsearch is a full-text search engine above all. In the first article, we didn't really have fun with full-text search features. In this
article, I will talk mainly about two points:

- Indexing operations: **Mappings configuration** and **Batch Indexing**
- Searching operations: **Querying** and **Filtering** the results.

From now, I can tell you that we won't talk about all the query types available in Elasticsearch in this article. There are two reasons to that: the first one is that there are
plenty of query types, and the second one is that most of them are not an everyday use.

1. [Indexing is back!](/elasticsearch-always-pays-its-debts/#indexing-is-back)
2. [Mapping](/elasticsearch-always-pays-its-debts/#mapping)
3. [Batch Indexing](/elasticsearch-always-pays-its-debts/#batch-indexing)
4. [Searching](/elasticsearch-always-pays-its-debts/#searching)

***

## Indexing is back!

Before we have fun with the full-text search, I want to tell you more about **indexing**. Indeed, this operation is quite important in Elasticsearch, because the quality and the
speed of your queries directly depend on the structure of your index.

### What exactly are we talking about?

Here, I want to deal with two operations of the indexing: **Mapping** and **Batch Indexing**. They are not the only operations of indexing, however I won't talk about the other ones
in this article, but in the next one.

The first operation we'll talk about is: **Mapping**. **Mapping** means the description of the schema of your data. As Elasticsearch is **schemaless** (it doesn't care about the schema
of the data you're giving to it), I think it is better to define the schema. There are many reasons why you should describe your data schema as far as practical. Schemaless has a
lot of advantages, **on the database layer** (easy to go with autoscaling, for example). But on the application layer, data has a schema most often.

The second operation we'll make concerns **Batch Indexing**. Currently, we know how to index a single document into Elasticsearch. However, there are ways to index multiple documents
at the same time, being efficient and fast.

### Mapping

Well, **Mapping**. In the previous article, I did talk a bit about the index creation. In reality, index creation can be more complex, and there is a bunch of parameters that can
be configured.

#### Automated Index creation

What you may not know about Elasticsearch, is that by default, you **don't need to create index before you insert
documents into it**. Well, **that's not necessarily a good thing**.

Let's imagine the following situation: You've got the automated index creation enabled, and you're quietly working on your application. Let's say that you store data in an index
called *book*. As a reminder, indices names should be written in the singular form. Now, let's assume that you've made a typo in your application, writing *book* as *boook* (with
three *"o"* letter). When you are running the application, you have no error. That is because **automated index creation is enabled: If Elasticsearch is not aware of the index you are
trying to insert data into, it will create it!**. And now, your application stores data on two different indices, causing a phase shift in your data. You may spend hours before
you find this mistake of yours, because Elasticsearch will not send your application any error!

The good practice hidden behind this situation is to disable automated index creation if you don't need it.

To do so, we need to edit the configuration file *elasticsearch.yml* (or *elasticsearch.json* if you chose the JSON format) to add the following line:

`action.auto_create_index: false`

Then, if you try to insert a document into an index which hasn't been created, you will find yourself having an error from Elasticsearch:

{% highlight json %}
{
    "error": "IndexMissingException[[your_index_name] missing]",
    "status": 404
}
{% endhighlight %}

> `action.auto_create_index` can take more than a *true/false* value. You can specify several regex, separated by a coma, and begining with a *+* or a *-*, according to the
fact that you want to allow or disallow automatic index creation for the indices' names pattern that match the regex. For example:
`action.auto_create_index: -game, +game_of, -*` will disallow automatic index creation for indices' names beginning with "game" (*-game*), but allow automatic index creation
for indices' names beginning with "game_of" (*+game_of*), and finally, the `-*` will disallow automatic index creation for every other patterns.

#### Dynamic Mapping

Before we dive into defining our own mapping, it is important to understand **dynamic mapping**, how it works, and what we can configure.

**Be careful: The parameters shown below can only be set when creating the index. If you want to modify the mapping of an existing index, there is some tricks
involving aliases.**

##### Type detection

When you're inserting data into Elasticsearch, they are formatted with JSON structure. Elasticsearch is able to automatically guess the type of each fields: numbers, string,
booleans. Indeed, numbers are defined with digits, strings are surrounded by quotes, and boolean are specific words. This behavior is called **type detection**.

But, what if we want this behavior to be a little different? Several options are set by Elasticsearch to customize the type detection.  For example,
we could like digits between quotes to be recognized as numbers (the default behavior is to identify them as strings).

These parameters are specific to each index. It means that the parameters have to be set through the Elasticsearch cluster's API.

###### Numeric detection

One of these parameters is the **numeric detection**. If the `numeric_detection` parameter is set to `true`, then Elasticsearch will search into strings to find out if the string
is a real string, or if it is a number. For example, with the **numeric detection** enabled for the `age` field, a string like `"10"` would be considered as a number.

**The request**

To turn on the `numeric detection`, we will have to query our cluster.

The request type is `PUT`.

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/indexName</span><span style="color: chartreuse">?pretty</span></code></pre></div>

The data you need to send are the following:

{% highlight json %}
{
    "nameOfTheType": {
        "numeric_detection": true
    }
}
{% endhighlight %}

**The response**

{% highlight json %}
{
  "acknowledged": true
}
{% endhighlight %}

As you can see, there is nothing special in the response. It looks like every other response from the server, when you are creating an index. So the question that might come to
your mind is the following: How can you check that the **numeric detection** has been turned on for a given field?

Actually, it is very simple. You can request your cluster about its settings. I don't want this article to go on too much, so I won't talk much about it right here. I'd rather let
you have a look here, on the official documentation: [https://www.elastic.co/guide/en/elasticsearch/reference/1.6/indices-get-settings.html](https://www.elastic.co/guide/en/elasticsearch/reference/1.6/indices-get-settings.html).

**Full example**

Let's say that we want to build an index, indexing all cities and places in *Westeros*. By the way, Elasticsearch provides spatial search, which is an amazing feature. I hope that
I will have time to talk about it in the articles to come. Anyway, we want to index the *Westeros* places. For that, let's say that our index would contain the population count
of each cities we are indexing. The index would be `game_of_thrones_place` and the type for cities, `city`. Of course, we want to enable **numeric detection** for the `city` type.

Our curl request would be:

{% highlight sh %}
$> curl –XPUT 'http://localhost:9200/game_of_thrones_place?pretty' -d '{"city": {"numeric_detection": true }}'
{% endhighlight %}

***

###### Date detection

I'm gonna speed up a bit, because the principle about **date detection** is exactly the same than the numeric detection. The request you have to make is the same, only the
value is changing. The parameter is called `dynamic_date_formats`. As you may have noticed, the name of this parameter is plural. The reason is that the value will be an array,
containing every patterns you want to recognize as a valid date format. **The format has to be specified following ISO 8601
([https://en.wikipedia.org/wiki/ISO_8601](https://en.wikipedia.org/wiki/ISO_8601))**

Considering that, your request would looks like this:

{% highlight json %}
{
    "name_of_the_type": {
        "numeric_detection": ["format_1", "format_2", ...]
    }
}
{% endhighlight %}

Replacing `format_1` and `format_2` with the date format, at the ISO 8601 standard, will give you a correct request.

For example, let's say that we want to enable **date detection** on a type, and allow the two following date format: `yyyy-MM-dd hh:mm` and `dd-MM-yyyy hh:mm`. The forged request
would be the following:

{% highlight json %}
{
    "name_of_the_type": {
        "numeric_detection": ["yyyy-MM-dd hh:mm", "dd-MM-yyyy hh:mm"]
    }
}
{% endhighlight %}

###### The boolean case

Well, no tool can be perfect. Unfortunately, at the time I wrote this article, boolean guessing from string doesn't exist in Elasticsearch.

##### Turn dynamic type guessing off

We talked about type guessing, and how to handle dynamic type guessing, such as numeric or date. But now, let's have a look about what to do if you want the type guessing to
be disabled. With **dynamic type guessing** turned on, every unknown field (field which is not described in mapping) will be automatically type-guessed and added into
the document. This can lead to undesired behaviour of your application. Disabling **dynamic type guessing** allows you to completely control the shape of your document,
the fields, and the format they should have.

**Be careful: Disabling dynamic type guessing leads you to define your entire mapping; without defining it, unknown fields will be ignored.**

**The request**

The request will have two parts:

- The first part is the type guessing disabling.
- The second part is the definition of the fields mapping.

{% highlight json %}
{
    "nameOfTheType": {
        "dynamic": false,
        "properties": {
            ...
            ...
        }
    }
}
{% endhighlight %}

As you might guess, `"dynamic": false` turns the type guessing off. On the other hand, `"properties": { ... }` contains your mapping (we will see it later).

Mapping could be either really simple, or really complex. Elasticsearch allows you to precisely define the format of each fields, and the way it will be handled
by Apache Lucene. To read more about the available options of each field type, you can take a look here: [https://www.elastic.co/guide/en/elasticsearch/reference/1.6/mapping-core-types.html](https://www.elastic.co/guide/en/elasticsearch/reference/1.6/mapping-core-types.html).
This page is talking about `Core Types`, which are the *basic* types: *Integer*, *String*, *float / double*, ... But even more types are available in Elasticsearch, such as `Array`,
`Object`, `IP`, `Geo Point` and `Geo Shape` (two types I'd like to write an article about).

I could write a hundred page article about types, as they have hundreds of options, but I don't think it would be relevant here. So that I let you read the official documentation,
which is complete and clear.

#### Analyzers

Wow, wow, wow! It has been a long way until we got here. Right now will be our first talk about **full-text search**, and more precisely, **text analysis** with Elasticsearch's **Analyzers**.

I hope you do remember, I talked a bit about **Tokenizers** and **Token filters** in the first article, when I gave you an overview of what is behind Elasticsearch, and how text is processed by Elasticsearch.

Today, I'm in the mood, so let me refresh your memory about them.

> Using Elasticsearch, data and queries can be analyzed, with the precious help of **analyzers**. **Analyzers** is the word we use to talk about both **Tokenizers** and **Token filters**.
**Tokenizers** stand to split a string into several **tokens**, which are processed by one or more **Token filters**. The role of **Token filters** is to modify tokens: lowercasing,
uppercasing, removing some tokens, ...

Anyway, you should remember that an **analyzer** is composed of a **tokenizer** and one or more **token filters** (and some other stuff, like a **character filter**).

As Elasticsearch's developers are cool guys, they already provided you some ready-to-use **analyzers**. Nowadays, there are 8 **analyzers**, but the amazing point is that, using
**tokenizer** and **token filters**, you can to define your own **analyzers**.

First, let's talk about the ready-to-use **analyzers**, how to use it, and finally, how to define your own.

##### Ready-to-use Analyzers

Elasticsearch provides, at this time, 8 **analyzers**. I will talk a bit about the ones that I consider to be the most interesting.

###### Standard Analyzer

Well, as its name defines it, the **standard analyzer** is the most simple one, in terms of European Languages. Using the **standard tokenizer**, it passes tokens through **standard
token filter**, **lower case filter** ans then **stop token filter**. Although **standard token filter** and **lower case filter** speak for themselves, let's stop on the **stop token
filter**. This filter stands to remove tokens defined as *stop words*. *Stop words* are small words, such as, for example: "and", "the", etc.

Let's practice it.

In their great goodness, Elasticsearch developers provided us a way to take a look at the token stream. This will help us to try the **analyzers** right now, and get rid of the
configuration for now.

**The request**

The request type is `GET`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/game_of_thrones</span><span style="color: chartreuse">/_analyze?analyzer=standard</span></code></pre></div>

The data we need to provide it, is a string, containing the text to analyze.

**The response**

Our cluster will send us a response of the following format:

{% highlight json %}
{
    "tokens": [
        {
            "token": "value",
            "start_offset": xxxx,
            "end_offset": yyyy,
            "type": "type",
            "position": zzzz
        },
        ...
    ]
}
{% endhighlight %}

What we got there is an array of objects. Each object represents a token, defined, as we talked in the first article, by its value, its **start offset** in the original string, and
its **end offset**. Also, you can see the type of the token, and its position in the **token stream**.

**Full example**

Ok. Remember Jon Snow? We created his biography in the first article. Let's take the sentence I used to describe him:

> Jon Snow (15) is the bastard son of Eddard Stark, the lord of Winterfell. He is the half-brother of Arya, Sansa, Bran, Rickon and Robb.

Let's process this sentence through the **standard analyzer**, and see what we get. For that, we are using the first index we created in the first article, `game_of_thrones`.

{% highlight sh %}
$> curl -XGET 'http://localhost:9200/game_of_thrones/_analyze?pretty&analyzer=standard' -d 'Jon Snow (15) is the bastard son of Eddard Stark, the lord of Winterfell. He is the half-brother of Arya, Sansa, Bran, Rickon and Robb.'
{% endhighlight %}

And now, let's see the result.

{% highlight json %}
{
  "tokens": [ {
    "token": "jon",
    "start_offset": 0,
    "end_offset": 3,
    "type": "<ALPHANUM>",
    "position": 1
  }, {
    "token": "snow",
    "start_offset": 4,
    "end_offset": 8,
    "type": "<ALPHANUM>",
    "position": 2
  }, {
    "token": "15",
    "start_offset": 10,
    "end_offset": 12,
    "type": "<NUM>",
    "position": 3
  }, {
    "token": "is",
    "start_offset": 14,
    "end_offset": 16,
    "type": "<ALPHANUM>",
    "position": 4
  }, {
    "token": "the",
    "start_offset": 17,
    "end_offset": 20,
    "type": "<ALPHANUM>",
    "position": 5
  }, {
    "token": "bastard",
    "start_offset": 21,
    "end_offset": 28,
    "type": "<ALPHANUM>",
    "position": 6
  }, {
    "token": "son",
    "start_offset": 29,
    "end_offset": 32,
    "type": "<ALPHANUM>",
    "position": 7
  }, {
    "token": "of",
    "start_offset": 33,
    "end_offset": 35,
    "type": "<ALPHANUM>",
    "position": 8
  }, {
    "token": "eddard",
    "start_offset": 36,
    "end_offset": 42,
    "type": "<ALPHANUM>",
    "position": 9
  }, {
    "token": "stark",
    "start_offset": 43,
    "end_offset": 48,
    "type": "<ALPHANUM>",
    "position": 10
  }, {
    "token": "the",
    "start_offset": 50,
    "end_offset": 53,
    "type": "<ALPHANUM>",
    "position": 11
  }, {
    "token": "lord",
    "start_offset": 54,
    "end_offset": 58,
    "type": "<ALPHANUM>",
    "position": 12
  }, {
    "token": "of",
    "start_offset": 59,
    "end_offset": 61,
    "type": "<ALPHANUM>",
    "position": 13
  }, {
    "token": "winterfell",
    "start_offset": 62,
    "end_offset": 72,
    "type": "<ALPHANUM>",
    "position": 14
  }, {
    "token": "he",
    "start_offset": 74,
    "end_offset": 76,
    "type": "<ALPHANUM>",
    "position": 15
  }, {
    "token": "is",
    "start_offset": 77,
    "end_offset": 79,
    "type": "<ALPHANUM>",
    "position": 16
  }, {
    "token": "the",
    "start_offset": 80,
    "end_offset": 83,
    "type": "<ALPHANUM>",
    "position": 17
  }, {
    "token": "half",
    "start_offset": 84,
    "end_offset": 88,
    "type": "<ALPHANUM>",
    "position": 18
  }, {
    "token": "brother",
    "start_offset": 89,
    "end_offset": 96,
    "type": "<ALPHANUM>",
    "position": 19
  }, {
    "token": "of",
    "start_offset": 97,
    "end_offset": 99,
    "type": "<ALPHANUM>",
    "position": 20
  }, {
    "token": "arya",
    "start_offset": 100,
    "end_offset": 104,
    "type": "<ALPHANUM>",
    "position": 21
  }, {
    "token": "sansa",
    "start_offset": 106,
    "end_offset": 111,
    "type": "<ALPHANUM>",
    "position": 22
  }, {
    "token": "bran",
    "start_offset": 113,
    "end_offset": 117,
    "type": "<ALPHANUM>",
    "position": 23
  }, {
    "token": "rickon",
    "start_offset": 119,
    "end_offset": 125,
    "type": "<ALPHANUM>",
    "position": 24
  }, {
    "token": "and",
    "start_offset": 126,
    "end_offset": 129,
    "type": "<ALPHANUM>",
    "position": 25
  }, {
    "token": "robb",
    "start_offset": 130,
    "end_offset": 134,
    "type": "<ALPHANUM>",
    "position": 26
  } ]
}
{% endhighlight %}

Well, we have got a lot of data here. There is several interesting points. The first one, as I told you, **lowercase token filter** has been used, and you can see that proper names,
such as *Arya*, or *Rickon* has been divest of their uppercased first letter. Second point, parts of the original string have been removed; it is the case for parenthesis, and
final point. If you take a look at the `type` field, you may notice something. Here, I haven't disabled **dynamic type guessing**, and the only number (`15`) in the string has
been recognized as such (`<NUM>`).

###### Simple analyzer

The second analyzer I'd like to talk about is the **simple analyzer**. The difference between it and the standard analyzer is really thin, but significant. First, it will ignore
and remove all non-letter characters. For example, analyzing `Jon11111Snow` with the **simple analyzer** will result as two token, `Jon` and `Snow`. The second difference is about
the type. The resulting token's type will be `word`.

I won't give you a full example here, because the query is almost the same (only the name of the analyzer is different).

###### The Snowball analyzer

The last analyzer I want to talk about is the **snowball analyzer**. This analyzer is like the ugly duckling of ready-to-use analyzers. It is using a stemming algorithm, and the token
stream resulting is made with root words. Let's take an example. Analyzing `King's Landing` with the **snowball analyzer** will result in a stream of two tokens: `king` and
`land`. What we have here is a loss of data. Indeed, `landing` has been transformed into `land`, its root word. 

##### Configuring Indices Mapping with Analyzers

Right until now, we tested the analyzers directly through the cluster's API, without really storing data. The cluster was sending us the **token stream**, so that we can dive inside
it. But of course, I think you guessed that we can configure indices so that they automatically apply analyzers right onto input data. For each field defined in your mapping, you will be
able to define an analyzer to be applied on the input data.

**The request**

When defining mapping of a given type, for a given index, you can set an **analyzer** for each field, separately. The request would looks like this:

{% highlight json %}
{
    "nameOfTheType": {
        "properties": {
            "nameOfTheField": {
                ...,
                "analyzer": "nameOfTheAnalyzer",
                ...,
            }
        }
    }
}
{% endhighlight %}

**The response**

The response will be the classical `"aknowledge": true` of the indices creation query.

**Here, I won't give you full example, because we will make practical usage of tokens when we will come to full-text search (soon, I promise)**

##### Making you own Analyzer

Because Elasticsearch aims to be flexible, you can **create your own analyzers**. If you remember well, what we call **analyzer** is simply a combination of a **tokenizer**, some
**token filters** (and some other stuff, like a **character filter**). The creation of a custom analyzer steps during the creation of the index. The definition of it stands
in the `settings.index.analysis.analyzer` field of the query you send to the cluster to create the index.

**The request**

{% highlight json %}
{
    "settings": {
        "index": {
            "analysis": {
                "analyzer": {
                    "nameOfYourAnalyzer": {
                        "tokenizer": "nameOfTheTokenizer",
                        "filter": [
                            "filter1",
                            "filter2",
                            ...
                        ]
                    }
                }
            }
        }
    }
}
{% endhighlight %}

Pay attention to the `filter` field; despite the fact that it is an array, the field's name remains singular.

**The response**

As this process step in the index creation process, the response will be the classical response returned when creating an index:

{% highlight json %}
{
  "acknowledged": true
}
{% endhighlight %}

**Full example**

I want to create an analyzer, which I will name as `wildfire_analyzer`. It will be composed, for the tokenizer, of the `standard` tokenizer, and for the token filter,
of the `synonym` token filter and the `trim` token filter. Actually, I chose them randomly, so that I don't really know what could be the token stream resulting of the analysis
of a stream by my `wildfire_analyzer`, this just stands for example.

{% highlight json %}
{
    "settings": {
        "index": {
            "analysis": {
                "analyzer": {
                    "name_of_your_analyzer": {
                        "tokenizer": "standard",
                        "filter": [
                            "synonym",
                            "trim"
                        ]
                    }
                }
            }
        }
    }
}
{% endhighlight %}

That's it! You just defined your own analyzer! And since you also can create your own filters, you really are able to handle data the way you want.

##### More analyzers

The handful of ready-to-use analyzers defined by Elasticsearch might not be enough. Fortunately, Elasticsearch developers are maintaining several Github repositories, with custom
analyzers. To use them, you just have to install them the classic way you install plugins. For example, you can find a **phonetic analyzer**, a **smart chinese analyzer**, and so on.

If you don't remember how to install plugins, you can take a look at the end of [the first article's introduction to plugin](http://reputationvip.io/elasticsearch-is-coming/#introduction-to-plugins).

### Batch Indexing

Wel, I must admit that... There are still some little things that I'd like to talk about, before we dive into full-text search. In the first
article, I talked about indexing a single document. But now, let's imagine that you have to put one million of documents into an index. At this
point, you have got two choices: The first one, you can do it all by yourself, indexing them one after another... But honestly, I don't recommend you
to do so; the second choice is probably the most reasonable one, to use **batch indexing**.

#### Request format

*Batch indexing* provides you the solution to **perform creation, replacement, indexing, and deletion of many documents, all in one request**. Hence, the
request's format has been optimized to perform efficiency. And, the icing on the cake: Each request can contain multiple type of operation, among
the following:

- *create*: This operations stands to create a whole new document (**a document that has never be indexed**)
- *index*: Adding or replacing an exiting document
- *delete*: delete a document

The principle is simple: Elasticsearch assumes that **each line of your request's data is a JSON object**, containing the type of query you are making
(*index*, *create*, *delete*), and information about it, such as index's name, type's name, etc. **The following line must contain the data you are
indexing or creating.** In the case of a *delete*, no data is required (and thus, Elasticsearch assumes that for *delete*, the following line is
a new set of instructions).

For example, the following data could be used to batch index some Game Of Thrones' characters:

{% highlight json %}
{"create":{"_index":"game_of_thrones","_type":"character","_id":"JonSnow"}}
{"house":"Stark","age":"17","biography":"Hello I'm Jon","tags":["jon","night's watch"]}
{% endhighlight %}

The bad news is that **there is a default limitation about the size of the data you are passing through the API.** This limitation is of **100 Mb**...
But, we are working here with Elasticsearch, and nothing is impossible. It means that, of course, you can configure this limitation!
The corresponding line in the configuration file of your node is `http.max_content_length`.

#### Bulk index request

Now that we know how to format our data, let's see how to call the cluster's API to execute our queries.

**The request**

The request type is `POST`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: chartreuse">/_bulk</span></code></pre></div>

**The data**

Something really important about this special request is: the data. As I said before, Elasticsearch is parsing the data you give using new lines
characters. Yet, the `-d` option we were used to use with *curl* **doesn't preserve new lines character**. Then, you will have to use the
`--data-binary` option, indicating then the path to the file which contains your data. The path must start with `@` and is relative.

**The Response**

{% highlight json %}
{
  "took": 39,
  "errors": false,
  "items": [ {
    "create": {
      "_index": "nameOfTheIndex",
      "_type": "nameOfTheType",
      "_id": "ID",
      "status": 200,
      "error": "SomeError"
    }
  },
  ...
  ]
}
{% endhighlight %}


The response is more complex than the response we were used to. It is composed of many fields: `took`, which is the **total time it took
to Elasticsearch to run all queries** (in milliseconds). The `errors` field (a boolean), indicates whether the process encountered errors; if set to `true`, it **doesn't
mean that the whole process failed**, but that an error occurred with **at least one of the queries**. Finally, the `items` field is an array. It contains
a set of objects, describing the result of each query you sent. The object contains information such as index name, type, id, version (actually, it
should remember you the result returned for the CRUD operations). The object also contains a `status` field, filled with an HTTP code. Also, if something
went wrong, the object should contain an `error` field, describing the error.

#### UDP Bulk Request

**First of all, you should know that this way is to make deprecated request, and it will be removed in Elasticsearch 2.0. Anyway, I thought this
was worth talking about, and I want to give you some information about it.**

I told you many times that Elasticsearch wishes you the best. Bulk requests throughout API are quick. But if you are looking for an even more
efficient way to make bulk queries, then the **UDP** bulk operations are here for you. As a reminder, **UDP** stands for **User Datagram Protocol**.
It is the brother of **TCP**. So yes, **UDP** is faster. BUT. Yes, there is a but. You can't have your cake and eat it. **UDP** is faster because
it does not guarantee that some data wont be lost during the process. You should use it **only if performances are more important than data accuracy**.

**I want to use it!**

Well, well, you got me, I'll show you how to use it.

##### Configuring the cluster for UDP bulk

Yes, nothing comes without a bit of configuration. In the Elasticsearch configuration file, some fields stand to configure **UDP** API. `bulk.udp.host`
indicate the host (default is the same than the standard API's host). `bulk.udp.port` indicates the port on which the UDP API can be requested.

##### Requesting

To make it quicker, let's assume your queries are available in a file called `queries.json`, and the **UDP API** reachable on `localhost`, under
the port `9700`. Then, the command line should look like:

{% highlight sh %}
$> cat queries.json | nc -u localhost 9700
{% endhighlight %}

`nc` (for *netcat*) will send the data piped to it from `queries.json`, using *UDP* protocol (`-u` argument).

### Searching

WOOOOOW! Can you believe it?! We are finally there, talking about the most important and valuable feature of Elasticsearch: **The full-text search**!!

But first, I need to be honest with you. There are still plenty of things that need to be said about other features of Elasticsearch. I am thinking about routing, Segment merging,
and so on. Nevertheless, I don't want this article to be boring, so I decided to talk about full-text search now, since routing & co. are not essential to practice full-text search.

Before we start making full-text search queries, we should have something on what to search... Which is actually not the case. As my objective right now is not to introduce you
to high-performance full-text search, we won't need a big database. In my infinite kindness, **I provided you a JSON document you can find in the `dataset` folder of the
Github repositories that comes with this article**. Okay, you won, I give you the address: [https://github.com/quentinfayet/elasticsearch/tree/v2.0](https://github.com/quentinfayet/elasticsearch/tree/v2.0). This document, named as `game_of_thrones_dataset.json` contains a hand-made
(yes, I said hand-made) dataset of Game of Thrones characters, along with their biographies.

#### The mapping

Before bulk indexing data, **we need to configure the index's mapping**. I provided you a turnkey mapping, that can be found into the `queries/mapping/mapping.json` file of the Github
repository. First of all, let's take a look at this mapping.

{% highlight json %}
{
    "mappings": {
        "character": {
            "dynamic": "false",
            "properties": {
                "id": {"type": "string"},
                "house": {"type": "string", "index": "not_analyzed"},
                "gender": {"type": "string", "index": "not_analyzed"},
                "age": {"type":"integer"},
                "biography": {"type": "string", "term_vector": "with_positions_offsets", "index": "analyzed"},
                "tags": {"type": "string"}
            }
        }
    }
}
{% endhighlight %}

As you can see, I defined 5 fields for the `character` type.

- `id` (the document's ID) is simply **a string**.
- `house` refers to the house's name of the character (for example: "Stark", "Lannister", ...). As **this field can be considered as a single entity**,
I set the `index` property to `not_analyzed`. This will result as **the value of this field to be considered as a single term**. You can learn more about `index` property
here [https://www.elastic.co/guide/en/elasticsearch//reference/master/mapping-index.html](https://www.elastic.co/guide/en/elasticsearch//reference/master/mapping-index.html)
- `gender` represents the gender of the character. The value would be either "male" or "female", so that it could be **considered as a single term**. That's why the `index` property
is also set to `no_analyzed`.
- `age` stores the age of the character. Its type is `integer`.
- `biography` is the field we will talk the most when performing full-text search. The `term_vector` property describes **which data this field's term_vector contains**. The value
`with_positions_offsets` is valuable when we want to use fast vector highlighter (I will talk about this in details in an other article). Also, `index` is set to `analyzed`,
that means **this string will go through analyzer** (standard analyzer, as it is the default analyzer) to be converted into terms; then, **when searching, the query string will go through the same analyzer.**
- `tags` is an array (arrays are Elasticsearch's datatype, and you should have a look to the difference between `Array` and `Nested` datatypes).

So, let's perform this mapping:

{% highlight sh %}
$>curl –XPUT 'http://localhost:9200/game_of_thrones/' -d @mapping.json
{% endhighlight %}

#### Bulk inserting the data

I know you may be impatient to start full-text search. But before that (the last step, I promise), we need to insert data into our Elasticsearch cluster. In a surge of generosity,
I created a bulk-index request, that you can find in the `dataset` folder.

You can perform the bulk request with the following command:

{% highlight sh %}
$>curl –XPOST 'http://localhost:9200/_bulk/' --data-binary @game_of_thrones_dataset
{% endhighlight %}

#### Basic search query

Elasticsearch accepts 3 main types of queries. The `basic queries`, such as, for example, term queries. The `compound queries`, such as boolean ones, and, finally, the `filter queries`.

Right now, we will go into the basic queries.

Elasticsearch API provides us two way of performing the basic queries.

##### The inline query

The first way, is the **inline query**, is a way to pass the query through the get parameters, **directly into the URL.**

**The request**

The request type is `GET`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/index/type</span><span style="color: chartreuse">/_search?q=the_query</span></code></pre></div>

The action, `_search` indicates to Elasticsearch that we are willing to perform a search. The `q` parameter contains the query. Its format is basic: `field:value`.

**The response**

The response from the server will contain each **whole document** that matches your query.

**Full example**

Well, let's say that I want to retrieve each `character` that field `house` is set to `Stark`.

{% highlight sh %}
$>curl –XGET 'http://localhost:9200/game_of_thrones/character/_search?q=house:Stark&pretty'
{% endhighlight %}

{% highlight json %}
{
  "took" : 25,
  "timed_out" : false,
  "_shards" : {
    "total" : 5,
    "successful" : 5,
    "failed" : 0
  },
  "hits" : {
    "total" : 5,
    "max_score" : 1.4054651,
    "hits" : [ {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Robb Stark",
      "_score" : 1.4054651,
      "_source":{"house": "Stark","gender": "male","age":22,"biography": "Robb Stark is the eldest son of Eddard and Catelyn Stark and the heir to Winterfell. His dire wolf is called Grey Wind. Robb becomes involved in the war against the Lannisters after his father, Ned Stark, is arrested for treason. Robb summons his bannermen for war against House Lannister and marches to the Riverlands. Eventually, crossing the river at the Twins becomes strategically necessary. To win permission to cross, Robb agrees to marry a daughter of Walder Frey, Lord of the Twins. Robb leads the war effort against the Lannisters and successfully captures Jaime. After Ned is executed, the North and the Riverlands declare their independence from the Seven Kingdoms and proclaim Robb as their new King, The King in The North. He wins a succession of battles in Season 2, earning him the nickname the Young Wolf. However, he feels that he botched the political aspects of war. He sends Theon to the Iron Islands hoping that he can broker an alliance with Balon Greyjoy, Theon's father. In exchange for Greyjoy support, Robb as King in the North will recognize the Iron Islands' independence. He also sends his mother Catelyn to deal with Stannis Baratheon and Renly Baratheon, both of whom are fighting to be the rightful king. Theon and Catelyn fail in their missions, and Balon launches an invasion of the North. Robb falls in love with Talisa Maegyr, a healer from Volantis due to her kindness and spirit. Despite his mother's protest, Robb breaks his engagement with the Freys and marries Talisa in the 2nd season finale. On news of his grandfather, Lord Hoster Tully's, death, Robb and his party travel north to Riverrun for the funeral, where the young king is reunited with his great-uncle, Brynden Blackfish, and his uncle, Edmure Tully, the new lord of Riverrun. While at Riverrun, Robb makes the decision to execute Lord Rickard Karstark for the murders of two teenage squires related to the Lannisters, a decision that loses the support of the Karstarks and leads Robb to make the ultimately fatal decision to ask the Freys for their alliance. He is killed in the Red Wedding Massacre, after witnessing the murder of his pregnant wife and their child. Lord Bolton personally executes Robb, stabbing him through the heart while taunting that the Lannisters send their regards, in fact a promise made to Jaime (who had no knowledge of Bolton's impending treason) when leaving for the Twins. His corpse is later decapitated and Grey Wind's head is sewn on and paraded around as the Stark forces are slaughtered by the Freys and the Boltons.","tags": ["stark","king of the north"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Arya Stark",
      "_score" : 1.2231436,
      "_source":{"house": "Stark","gender": "female","age":17,"biography": "Arya Stark is the younger daughter and third child of Lord Eddard and Catelyn Stark of Winterfell. Ever the tomboy, Arya would rather be training to use weapons than sewing with a needle. Her direwolf is called Nymeria. When Ned is arrested for treason, her dancing master Syrio Forel helps her escape the Lannisters. She is later disguised as an orphan boy by Yoren, a Night's Watch recruiter, in hopes of getting her back to Winterfell. From then on, she takes the name Arry. During Season 2, Yoren's convoy is attacked by the Lannisters who are under orders by King Joffrey to find and kill Robert's bastard children. Before she is captured, she releases the prisoner Jaqen H'ghar and two others, saving their lives. She and the rest of the captured recruits are sent to Harrenhal under Gregor Clegane who cruelly tortures and kills prisoners everyday. At the same time, she follows the advice of the late Yoren and makes a list of those she wants dead like a prayer. When Tywin Lannister arrives at Harrenhal, he orders the killing of prisoners stopped and makes Arya his cup bearer after figuring out she is a girl. Tywin forms an unlikely friendship with Arya due to her intelligence while remaining unaware of her true identity. Arya reunites with Jaqen who offers to kill three lives in exchange for the three lives she saved. The first two she picks, the Tickler, Harrenhal's torturer and Ser Amory Lorch, after he catches Arya reading one of Tywin's war plans and tries to inform Tywin. After she fails to find Jaqen to kill Tywin, after he heads out to face Robb's forces, she forces Jaqen to help her, Gendry and Hot Pie escape Harrenhal after choosing Jaqen as her third name, for which she promises to unname him if he helps them. After successfully escaping, Jaqen gives her an iron coin and tells her to give it to any Braavosi and say Valar morghulis if she ever needs to find him. Arya, Gendry and Hot Pie head north for Riverrun and Arya's mother Lady Stark, but are captured by the Brotherhood Without Banners and taken to the Inn of the Kneeling Man. There, Arya is horrified to be reunited with the vile Sandor Clegane, one of the Brotherhood's prisoners. Arya and Gendry travel with the Brotherhood to meet their leader, now friends with them as they know Arya is Ned Stark's daughter. She escapes them after the Brotherhood acquits Sandor Clegane of murder after a trial by combat and selling Gendry to Melisandre to be sacrificed. Captured by Sandor, she is taken to the Twins to be ransomed to her brother, only to see his wolf and forces slaughtered and her brother paraded headless on a horse. Sandor knocks her unconscious and saves her from the ensuing slaughter, and she subsequently kills her first man when falling upon a party of Freys, boasting of how they mutilated her brother's corpse. In season 4, Sandor decides to ransom her to her Aunt Lysa Arryn in the Vale. With Sandor's help, Arya later retrieves her sword, Needle (a gift from Jon Snow), and kills the sadistic soldier Polliver, who stole it from her. Along the way, Arya slowly begins to bond with Sandor, helping to heal one of his wounds when they are attacked. They eventually arrive at the Vale, but are told that Lysa Arryn killed herself three days prior. Arya laughs with disbelief. Later, Arya and Sandor are found by Brienne of Tarth and Podrick Payne. Arya refuses to leave with Brienne, assuming her to be an agent of the Lannisters. In the ensuing fight between Brienne and Sandor, Arya flees and manages to catch a boat to Braavos, befriending the Braavosi captain by showing him the coin Jaqen gave her outside Harrenhal. In Season 5 Arya arrives in Braavos, and the ship's captain, Ternesio takes her to the House of Black and White. She is turned away by the doorman, even after showing the iron coin given to her by Jaqen H'ghar. After spending the night sitting in front of the House, she throws the coin into the water and leaves. Later, after killing a pigeon, Arya is confronted by a group of thieves in the street. Arya prepares to fight them, but the thieves flee when the doorman appears. He walks her back to the House of Black and White, and gives her the iron coin. He then changes his face to Jaqen, and informs Arya that she must become no one before taking her inside the House. Arya's training progresses, during which she gets better and better at lying about her identity. Jaqen eventually gives her her first new identity, as Lana, a girl who sells oysters on the streets of Braavos. She eventually encounters Meryn Trant, who she tortures and executes in retaliation for Syrio's death, revealing her identity and motive in the process. When she returns to the House of Black and White she is confronted by Jaqen H'ghar and the Waif, who tell her that Meryn's life was not hers to take and that a debt must be paid. Arya screams as she begins to lose her eyesight.","tags": ["stark","needle","faceless god"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Bran Stark",
      "_score" : 1.2231436,
      "_source":{"house": "Stark","gender": "male","age":11,"biography": "Brandon Bran Stark is the second son and fourth child of Eddard and Catelyn Stark. He was named after his deceased uncle, Brandon. His dire wolf is called Summer. During the King's visit to Winterfell, he accidentally came across Cersei and Jaime Lannister engaging in sex, following which Bran is shoved from the window by Jaime, permanently crippling his legs. An assassin tries to kill Bran, but Summer, the direwolf companion, kills the assassin. Bran, when he awakens, finds that he is crippled from the waist down, forced to be carried everywhere by Hodor, and he cannot remember the events immediately before his fall. Slowly, he realizes that he has gained the ability to assume Summer's consciousness, making him a warg or a skinchanger. After his older brother, Robb, is crowned King in the North, Bran becomes Robb's heir and the Lord of Winterfell. After Theon Greyjoy captures Winterfell, Bran goes into hiding. To cement his claim on Winterfell, Theon kills two orphan boys and tells the people of Winterfell that Bran, and his younger brother Rickon Stark, are dead. After Theon's men betray him and Winterfell is sacked, Bran, Rickon, Hodor, Osha and their direwolves head north to find his older brother Jon Snow for safety. They ultimately stumble upon Jojen and Meera Reed, two siblings who aid them in their quest. After coming close to the wall, Osha departs with Rickon for Last Hearth while Bran insists on following his visions beyond the Wall. He also encounters Sam and Gilly, who tries to persuade him not to, but Bran claims it is his destiny and leaves through the gate with Hodor and the Reeds. Along the way, Bran and the others stumble across Craster's Keep, where they are captured and held hostage by the Night's Watch mutineers led by Karl. Night's Watch rangers led by Jon eventually attack Craster's Keep to kill the mutineers, but Locke, a new recruit but secretly a spy for Roose Bolton, attempts to take Bran away and kill him elsewhere. Bran wargs into Hodor and kills Locke by snapping his neck, but Bran and his group are forced to continue on their journey without alerting Jon, whom Jojen claims would stop them. They eventually reach the three-eyed raven in a cave, who claims he cannot restore Bran's legs, but will make him fly instead.","tags": ["stark","disable","crow"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Jon Snow",
      "_score" : 1.2231436,
      "_source":{"house": "Stark","gender": "male","age":19,"biography": "Jon Snow is the bastard son of Ned Stark who joins the Night's Watch. Jon is a talented fighter, but his sense of compassion and justice brings him into conflict with his harsh surroundings. Ned claims that Jon's mother was a wet nurse named Wylla. His dire wolf is called Ghost due to his albinism and quiet nature. Jon soon learns that the Watch is no longer a glorious order, but is now composed mostly of society's rejects, including criminals and exiles. Initially, he has only contempt for his low-born brothers of the Watch, but he puts aside his prejudices and befriends his fellow recruits, especially Sam Tarly, after they unite against the cruel master-at-arms. He chooses to take his vows before the Old God of the North, and to his disappointment he is made steward to Lord Commander Jeor Mormont rather than a ranger. He eventually realizes that he is being groomed for command. He saves Mormont's life by slaying a wight, a corpse resurrected by the White Walkers. In return, he receives Longclaw, the ancestral blade of House Mormont. When Eddard is arrested for treason, Jon is torn between his family and his vows. After Eddard's execution, he tries to join Robb's army but is convinced to come back by his friends. Shortly after, he joins the large force Mormont leads beyond the Wall. Jon is part of a small scouting party in Season 2. When the party is overtaken by wildlings, Jon is ordered to appear to defect and join the wildlings so he can discover their plans. On affirming his loyalty to the King-Beyond-the-Wall, Mance Rayder, he travels toward the Wall with the wildlings and is seduced by one, the flame-haired Ygritte. Upon crossing the wall, he refuses to behead a farmer whose escape might alert the Night's Watch of their coming, and is subsequently branded an enemy of the wildlings. Ygritte shields him from her comrades but ultimately confronts and injures Jon when he stops to drink. He manages to escape back to the wall, injured by three arrows, where he reunites with his comrades and informs the commanders of Mance Rayder's plans. Jon subsequently resumes his training at the Wall and suggests an expedition to Craster's Keep in order to kill the Night's Watch mutineers who may tell Mance of the Wall's weak defences if caught. Jon's request is granted and he bands together a group of rangers to aid him, among them the new recruit Locke, who has actually come to kill Jon on Roose Bolton's orders. Jon successfully attacks Craster's Keep and kills the mutineers, while Locke is killed by Hodor during an attempt to kill Bran, who was captive at Craster's Keep. However, Jon's proposal to barricade the entrance to Castle Black to stop the wildlings from entering is denied. He survives the wildling attack on Castle Black, personally killing Styr and taking Tormund Giantsbane prisoner. In the aftermath, he departs Castle Black to hunt down Mance Rayder, giving his sword to Sam. He quickly locates Mance on the pretence of parleying, but he is found out. Before he is killed, however, Jon is saved by the timely arrival by Stannis Baratheon, who places Mance and his men under arrest, and accompanies Jon back to Castle Black. Jon later burns Ygritte's body in the woods. In Season 5, Stannis attempts to use Jon as an intermediary between himself and Mance, hoping to rally the wildling army to help him retake the North from Roose Bolton and gain Jon's support in avenging his family. Jon fails to convince Mance, and when Mance is burned at the stake by Stannis' red priestess Melisandre, Jon shoots him from afar to give him a quick death. After that Jon is chastised by Stannis for showing mercy to Mance. Stannis shows Jon a letter he received from Bear Island, stating that former Lord Commander Jeor Mormont's relatives will only recognize a Stark as their King. Ser Davos tells Jon that the Night's Watch will elect a new Lord Commander that night, and that it is almost assured that Ser Alliser will win. Stannis asks Jon to kneel before him and pledge his life to him, and in exchange he will legitimize Jon, making him Jon Stark, and giving him Winterfell. In the great hall, Jon tells Sam that he will refuse Stannis's offer, as he swore an oath to the Night's Watch. After Ser Alliser and Denys Mallister are announced as possible candidates, Sam gives a speech imploring his brothers to vote for Jon, reminding them all how he led the mission to Craster's Keep to avenge Commander Mormont's death and how he led the defense of Castle Black. After the voting is complete, the ballots are tallied and show a tie between Jon and Ser Alliser. Maester Aemon casts the deciding vote in favor of Jon, making him the new Lord Commander of the Night's Watch. To lessen the animosity between the two, Jon makes Ser Alliser First Ranger. Melisandre takes an interest in Jon, visiting him in his quarters and trying to have sex with him. Jon refuses, out of respect for Ygritte and his Night's Watch vows. Jon makes plans to give the wildlings the lands south of the wall, known as the gift. He wants the Night's Watch and the wildlings to unite against the threat of the White Walkers. These more liberal views are not taken well by the men of the Night's Watch, in particular Ser Alliser and a young boy named Olly, whose village was massacred by wildlings. Jon then makes a trip north of the Wall to the wildling village of Hardhome, where he hopes to get the wildlings to join his cause. However, before many of them can get on boats to leave, a massive group of White Walkers arrives on the scene. A massive battle ensues, in which many wildlings are killed. The last remaining Night's Watchmen and wildlings, including Jon, depart from Hardhome, defeated. As they return to the Wall, they are let in by Ser Alliser Thorne, who disapproves of his drastic action of joining forces with the wildlings. Shorty after, Jon sends Sam and Gilly to safety in Oldtown, approving of their relationship and Sam's motives of keeping her safe. He is later approached by Davos asking for men, and later Melisandre, whose silence confirms Stannis's defeat. That evening, Jon is met by Olly who claims that a range has arrived with knowledge of Jon's uncle Benjen. However, Jon discovers that he has been fooled and a mutinee, led by Ser Alliser Thorne, stab Jon repeatedly, with Olly dealing the final blow to Jon's heart, leaving him to die in the snow.","tags": ["stark","night's watch","brother","snow"]}
    }, {
      "_index" : "game_of_thrones",
      "_type" : "character",
      "_id" : "Sansa Stark",
      "_score" : 1.0,
      "_source":{"house": "Stark","gender": "female","age":25,"biography": "Sansa Stark is the first daughter and second child of Eddard and Catelyn Stark. She was also the future bride of Prince Joffrey, and thus the future Queen of the Seven Kingdoms as well. Her direwolf is called Lady, she is the smallest of the pack. Sansa is naive and wants to live the life of a fairy tale princess and is unwilling to see the harsh realities of the kingdom's politics and rivalries. Her fantasy begins to shatter when Lady is killed, and the situation continues to worsen when her father is arrested for treason. She becomes a hostage to the Lannisters in order for them to have a legitimate claim for the North. Her naivete is finally shattered when King Joffrey executes her father despite promising her that he would spare him. Sansa is forced to put up an act or endure Joffrey's cruelty. Throughout Season 2, she suffers under Joffrey's abuse until Tyrion puts a stop to it. By the Season 2 finale, Joffrey breaks his engagement with Sansa to marry Margaery Tyrell. However, she is still a hostage; but Petyr Baelish promises to help her return to Winterfell. In Season 3, she is married to Tyrion to secure the Lannisters the North should Robb Stark die. The marriage is unhappy and yet to be consummated, and after Robb's death – upon which Joffrey insists to be given his head to present to Sansa, a request coldly ignored by his grandfather – she is unable to speak to him. In Season 4, Sansa has been mourning her family for weeks and is starving herself in depression. She attends Joffrey's wedding with Tyrion and witnesses Joffrey's death. Dontos Hollard immediately spirits her away from the wedding, moments ahead of Cersei's orders to have her and Tyrion arrested. Dontos brings Sansa to a ship concealed in fog, and she is greeted by Petyr Baelish. Under the guise of making payment, Petyr has the fool killed by his archers, with Petyr explaining that killing Dontos was the only way to ensure his silence - her disappearance when Joffrey died, the execution of her father, deaths of her family and years of torment at the king's hand, will all be considerable motive for Sansa helping Tyrion murder Joffrey. Currently, a thousand of the City Watch are searching for her, Cersei thirsts for vengeance, and Tyrion himself stands trial. Sansa is assured she has finally escaped King's Landing and is safe with Lord Baelish, who takes her to her Aunt Lysa for shelter. Lysa takes Sansa in warmly and has her betrothed to her son, Robin. However, Sansa realises the worst is far from over when Lysa, who is smitten with Petyr, accuses Sansa of trying to seduce him, and she discovers that Robin is a spoiled and rude child, slapping him at one point. When Petyr unexpectedly kisses Sansa, Lysa becomes enraged and nearly pushes Sansa through the castle's Moon Door, but Petyr intervenes by pacifying Lysa and then pushing her through the Moon Door to her death before Sansa's eyes, making Sansa realise that Petyr may have romantic or lustful feelings for her. Sansa speaks up for Petyr when he is questioned about his involvement in Lysa's death, but Sansa reaffirms Petyr's claim that Lysa killed herself due to her own instability and insecurities. Afterward she told Petyr that her reason to protect him in the hearing was because she knew he was the only person she could count on to protect her, demonstrated by his initiative in getting her out of King's Landing while everyone else in power there only wanted to use her as a pawn. In Season 5, she and Petyr leave the Eyrie for a place Petyr promises where Cersei will never find her. At an In, Brienne of Tarth materializes unexpectedly and declares herself for Sansa. Petyr doubts that Sansa would want a sworn shield who let both of her previous masters die, even when Brienne reveals the true, somewhat unbelievable circumstances of Renly's death. Sansa seems inclined to agree, pointing out that Brienne was present at Joffrey's wedding, to which the warrior replies that neither of them wanted to be there. Sansa rejects Brienne's offer of service and watches as she handily defeats the guards and escapes. Petyr tells her that he has arranged for her to be married to Ramsay Bolton, the son of Lord Roose Bolton. This will put her back in Winterfell, which the Boltons now occupy as a reward for their role in the deaths of Robb and Catelyn. Though Ramsay initially seems interested in Sansa, his psychopathic nature quickly shows through, and Sansa is disgusted. She is also antagonized by Myranda, the kennelmaster's daughter, who is in a sexual relationship with Ramsay. Myranda frequently makes veiled threats to Sansa, and shows her what has become of Theon Greyjoy, who was Eddard Stark's ward and whom she grew up with. Sansa is horrified to find that after Ramsay emasculated him, he has taken on a submissive, sullen persona called Reek. After Sansa and Ramsay are wed, he brutally rapes her while forcing Reek to watch. Later, Sansa attempts to talk to Reek, who is unresponsive to her attempts to make him act like his old self by repeatedly calling him Theon instead of Reek. At one point, Reek mistakenly lets slip that her younger brothers, Bran and Rickon, are alive, when she had assumed that they were dead. This realization gives Sansa hope in the midst of her unfortunate situation. As Stannis Baratheon's army sneaks up on Winterfell and is greeted by the bulk of the Bolton forces, Sansa manages to escape her chamber but is stopped by Myranda, who threatens her with a bow. Reminding Sansa that she has nothing left to live for in Ramsay's custody, she is unexpectedly saved by Reek, who breaks his spell of subjugation by throwing Myranda over the bannister. In terror, the couple flees to the wall, where they make the jump off the ledge.","tags": ["stark","wife","dead father"]}
    } ]
  }
}
{% endhighlight %}

That's it! You will get each document that matches `house:Stark` (and some more information, I will detail it right after).

##### The DSL Query

The **DSL (for *Domain Specific Language*) query** is a way to perform queries on the Elasticsearch cluster, by using a **JSON structured document** that
describes your query.

**The request**

The request type is `GET`.

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/index/type</span><span style="color: chartreuse">/_search</span></code></pre></div>

As you might guess, we will either use `-d` option of curl, providing then our JSON query, or the `--data-binary` query, by indicating the path
to the file that contains the JSON query.

**The response**

The response depends on your DSL query, and is composed of a document. Along this article, I will separately detail each response.

**Full example**

The previous query, to retrieve each character from the Stark house, is called `query_string`. So, we will perform a query string using DSL.

Our query will be the following:

{% highlight json %}
{
    "query": {
        "query_string": {
            "query": "house:Stark"
        }
    }
}
{% endhighlight %}

The query is available at `queries/DSL/query_string.json`, let's launch it:

{% highlight sh %}
$>curl –XGET 'http://localhost:9200/game_of_thrones/character/_search?pretty' --data-binary @query_string.json
{% endhighlight %}

Let's take a closer look at the response, which should looks like the following JSON document:

{% highlight json %}
{
  "took": 78,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "failed": 0
  },
  "hits": {
    "total": 5,
    "max_score": 1.4054651,
    "hits": [ {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Robb Stark",
      "_score": 1.4054651,
      "_source":{"house": "Stark","gender": "male","age":"22","biography": "Robb Stark is the eldest son of Eddard and Catelyn Stark and the heir to Winterfell. His dire wolf is called Grey Wind. Robb becomes involved in the war against the Lannisters after his father, Ned Stark, is arrested for treason. Robb summons his bannermen for war against House Lannister and marches to the Riverlands. Eventually, crossing the river at the Twins becomes strategically necessary. To win permission to cross, Robb agrees to marry a daughter of Walder Frey, Lord of the Twins. Robb leads the war effort against the Lannisters and successfully captures Jaime. After Ned is executed, the North and the Riverlands declare their independence from the Seven Kingdoms and proclaim Robb as their new King, The King in The North. He wins a succession of battles in Season 2, earning him the nickname the Young Wolf. However, he feels that he botched the political aspects of war. He sends Theon to the Iron Islands hoping that he can broker an alliance with Balon Greyjoy, Theon's father. In exchange for Greyjoy support, Robb as King in the North will recognize the Iron Islands' independence. He also sends his mother Catelyn to deal with Stannis Baratheon and Renly Baratheon, both of whom are fighting to be the rightful king. Theon and Catelyn fail in their missions, and Balon launches an invasion of the North. Robb falls in love with Talisa Maegyr, a healer from Volantis due to her kindness and spirit. Despite his mother's protest, Robb breaks his engagement with the Freys and marries Talisa in the 2nd season finale. On news of his grandfather, Lord Hoster Tully's, death, Robb and his party travel north to Riverrun for the funeral, where the young king is reunited with his great-uncle, Brynden Blackfish, and his uncle, Edmure Tully, the new lord of Riverrun. While at Riverrun, Robb makes the decision to execute Lord Rickard Karstark for the murders of two teenage squires related to the Lannisters, a decision that loses the support of the Karstarks and leads Robb to make the ultimately fatal decision to ask the Freys for their alliance. He is killed in the Red Wedding Massacre, after witnessing the murder of his pregnant wife and their child. Lord Bolton personally executes Robb, stabbing him through the heart while taunting that the Lannisters send their regards, in fact a promise made to Jaime (who had no knowledge of Bolton's impending treason) when leaving for the Twins. His corpse is later decapitated and Grey Wind's head is sewn on and paraded around as the Stark forces are slaughtered by the Freys and the Boltons.","tags": ["stark","king of the north"]}
    }, {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Arya Stark",
      "_score": 1.2231436,
      "_source":{"house": "Stark","gender": "female","age":"17","biography": "Arya Stark is the younger daughter and third child of Lord Eddard and Catelyn Stark of Winterfell. Ever the tomboy, Arya would rather be training to use weapons than sewing with a needle. Her direwolf is called Nymeria. When Ned is arrested for treason, her dancing master Syrio Forel helps her escape the Lannisters. She is later disguised as an orphan boy by Yoren, a Night's Watch recruiter, in hopes of getting her back to Winterfell. From then on, she takes the name Arry. During Season 2, Yoren's convoy is attacked by the Lannisters who are under orders by King Joffrey to find and kill Robert's bastard children. Before she is captured, she releases the prisoner Jaqen H'ghar and two others, saving their lives. She and the rest of the captured recruits are sent to Harrenhal under Gregor Clegane who cruelly tortures and kills prisoners everyday. At the same time, she follows the advice of the late Yoren and makes a list of those she wants dead like a prayer. When Tywin Lannister arrives at Harrenhal, he orders the killing of prisoners stopped and makes Arya his cup bearer after figuring out she is a girl. Tywin forms an unlikely friendship with Arya due to her intelligence while remaining unaware of her true identity. Arya reunites with Jaqen who offers to kill three lives in exchange for the three lives she saved. The first two she picks, the Tickler, Harrenhal's torturer and Ser Amory Lorch, after he catches Arya reading one of Tywin's war plans and tries to inform Tywin. After she fails to find Jaqen to kill Tywin, after he heads out to face Robb's forces, she forces Jaqen to help her, Gendry and Hot Pie escape Harrenhal after choosing Jaqen as her third name, for which she promises to unname him if he helps them. After successfully escaping, Jaqen gives her an iron coin and tells her to give it to any Braavosi and say Valar morghulis if she ever needs to find him. Arya, Gendry and Hot Pie head north for Riverrun and Arya's mother Lady Stark, but are captured by the Brotherhood Without Banners and taken to the Inn of the Kneeling Man. There, Arya is horrified to be reunited with the vile Sandor Clegane, one of the Brotherhood's prisoners. Arya and Gendry travel with the Brotherhood to meet their leader, now friends with them as they know Arya is Ned Stark's daughter. She escapes them after the Brotherhood acquits Sandor Clegane of murder after a trial by combat and selling Gendry to Melisandre to be sacrificed. Captured by Sandor, she is taken to the Twins to be ransomed to her brother, only to see his wolf and forces slaughtered and her brother paraded headless on a horse. Sandor knocks her unconscious and saves her from the ensuing slaughter, and she subsequently kills her first man when falling upon a party of Freys, boasting of how they mutilated her brother's corpse. In season 4, Sandor decides to ransom her to her Aunt Lysa Arryn in the Vale. With Sandor's help, Arya later retrieves her sword, Needle (a gift from Jon Snow), and kills the sadistic soldier Polliver, who stole it from her. Along the way, Arya slowly begins to bond with Sandor, helping to heal one of his wounds when they are attacked. They eventually arrive at the Vale, but are told that Lysa Arryn killed herself three days prior. Arya laughs with disbelief. Later, Arya and Sandor are found by Brienne of Tarth and Podrick Payne. Arya refuses to leave with Brienne, assuming her to be an agent of the Lannisters. In the ensuing fight between Brienne and Sandor, Arya flees and manages to catch a boat to Braavos, befriending the Braavosi captain by showing him the coin Jaqen gave her outside Harrenhal. In Season 5 Arya arrives in Braavos, and the ship's captain, Ternesio takes her to the House of Black and White. She is turned away by the doorman, even after showing the iron coin given to her by Jaqen H'ghar. After spending the night sitting in front of the House, she throws the coin into the water and leaves. Later, after killing a pigeon, Arya is confronted by a group of thieves in the street. Arya prepares to fight them, but the thieves flee when the doorman appears. He walks her back to the House of Black and White, and gives her the iron coin. He then changes his face to Jaqen, and informs Arya that she must become no one before taking her inside the House. Arya's training progresses, during which she gets better and better at lying about her identity. Jaqen eventually gives her her first new identity, as Lana, a girl who sells oysters on the streets of Braavos. She eventually encounters Meryn Trant, who she tortures and executes in retaliation for Syrio's death, revealing her identity and motive in the process. When she returns to the House of Black and White she is confronted by Jaqen H'ghar and the Waif, who tell her that Meryn's life was not hers to take and that a debt must be paid. Arya screams as she begins to lose her eyesight.","tags": ["stark","needle","faceless god"]}
    }, {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Bran Stark",
      "_score": 1.2231436,
      "_source":{"house": "Stark","gender": "male","age":"11","biography": "Brandon Bran Stark is the second son and fourth child of Eddard and Catelyn Stark. He was named after his deceased uncle, Brandon. His dire wolf is called Summer. During the King's visit to Winterfell, he accidentally came across Cersei and Jaime Lannister engaging in sex, following which Bran is shoved from the window by Jaime, permanently crippling his legs. An assassin tries to kill Bran, but Summer, the direwolf companion, kills the assassin. Bran, when he awakens, finds that he is crippled from the waist down, forced to be carried everywhere by Hodor, and he cannot remember the events immediately before his fall. Slowly, he realizes that he has gained the ability to assume Summer's consciousness, making him a warg or a skinchanger. After his older brother, Robb, is crowned King in the North, Bran becomes Robb's heir and the Lord of Winterfell. After Theon Greyjoy captures Winterfell, Bran goes into hiding. To cement his claim on Winterfell, Theon kills two orphan boys and tells the people of Winterfell that Bran, and his younger brother Rickon Stark, are dead. After Theon's men betray him and Winterfell is sacked, Bran, Rickon, Hodor, Osha and their direwolves head north to find his older brother Jon Snow for safety. They ultimately stumble upon Jojen and Meera Reed, two siblings who aid them in their quest. After coming close to the wall, Osha departs with Rickon for Last Hearth while Bran insists on following his visions beyond the Wall. He also encounters Sam and Gilly, who tries to persuade him not to, but Bran claims it is his destiny and leaves through the gate with Hodor and the Reeds. Along the way, Bran and the others stumble across Craster's Keep, where they are captured and held hostage by the Night's Watch mutineers led by Karl. Night's Watch rangers led by Jon eventually attack Craster's Keep to kill the mutineers, but Locke, a new recruit but secretly a spy for Roose Bolton, attempts to take Bran away and kill him elsewhere. Bran wargs into Hodor and kills Locke by snapping his neck, but Bran and his group are forced to continue on their journey without alerting Jon, whom Jojen claims would stop them. They eventually reach the three-eyed raven in a cave, who claims he cannot restore Bran's legs, but will make him fly instead.","tags": ["stark","disable","crow"]}
    }, {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Jon Snow",
      "_score": 1.2231436,
      "_source":{"house": "Stark","gender": "male","age":"19","biography": "Jon Snow is the bastard son of Ned Stark who joins the Night's Watch. Jon is a talented fighter, but his sense of compassion and justice brings him into conflict with his harsh surroundings. Ned claims that Jon's mother was a wet nurse named Wylla. His dire wolf is called Ghost due to his albinism and quiet nature. Jon soon learns that the Watch is no longer a glorious order, but is now composed mostly of society's rejects, including criminals and exiles. Initially, he has only contempt for his low-born brothers of the Watch, but he puts aside his prejudices and befriends his fellow recruits, especially Sam Tarly, after they unite against the cruel master-at-arms. He chooses to take his vows before the Old God of the North, and to his disappointment he is made steward to Lord Commander Jeor Mormont rather than a ranger. He eventually realizes that he is being groomed for command. He saves Mormont's life by slaying a wight, a corpse resurrected by the White Walkers. In return, he receives Longclaw, the ancestral blade of House Mormont. When Eddard is arrested for treason, Jon is torn between his family and his vows. After Eddard's execution, he tries to join Robb's army but is convinced to come back by his friends. Shortly after, he joins the large force Mormont leads beyond the Wall. Jon is part of a small scouting party in Season 2. When the party is overtaken by wildlings, Jon is ordered to appear to defect and join the wildlings so he can discover their plans. On affirming his loyalty to the King-Beyond-the-Wall, Mance Rayder, he travels toward the Wall with the wildlings and is seduced by one, the flame-haired Ygritte. Upon crossing the wall, he refuses to behead a farmer whose escape might alert the Night's Watch of their coming, and is subsequently branded an enemy of the wildlings. Ygritte shields him from her comrades but ultimately confronts and injures Jon when he stops to drink. He manages to escape back to the wall, injured by three arrows, where he reunites with his comrades and informs the commanders of Mance Rayder's plans. Jon subsequently resumes his training at the Wall and suggests an expedition to Craster's Keep in order to kill the Night's Watch mutineers who may tell Mance of the Wall's weak defences if caught. Jon's request is granted and he bands together a group of rangers to aid him, among them the new recruit Locke, who has actually come to kill Jon on Roose Bolton's orders. Jon successfully attacks Craster's Keep and kills the mutineers, while Locke is killed by Hodor during an attempt to kill Bran, who was captive at Craster's Keep. However, Jon's proposal to barricade the entrance to Castle Black to stop the wildlings from entering is denied. He survives the wildling attack on Castle Black, personally killing Styr and taking Tormund Giantsbane prisoner. In the aftermath, he departs Castle Black to hunt down Mance Rayder, giving his sword to Sam. He quickly locates Mance on the pretence of parleying, but he is found out. Before he is killed, however, Jon is saved by the timely arrival by Stannis Baratheon, who places Mance and his men under arrest, and accompanies Jon back to Castle Black. Jon later burns Ygritte's body in the woods. In Season 5, Stannis attempts to use Jon as an intermediary between himself and Mance, hoping to rally the wildling army to help him retake the North from Roose Bolton and gain Jon's support in avenging his family. Jon fails to convince Mance, and when Mance is burned at the stake by Stannis' red priestess Melisandre, Jon shoots him from afar to give him a quick death. After that Jon is chastised by Stannis for showing mercy to Mance. Stannis shows Jon a letter he received from Bear Island, stating that former Lord Commander Jeor Mormont's relatives will only recognize a Stark as their King. Ser Davos tells Jon that the Night's Watch will elect a new Lord Commander that night, and that it is almost assured that Ser Alliser will win. Stannis asks Jon to kneel before him and pledge his life to him, and in exchange he will legitimize Jon, making him Jon Stark, and giving him Winterfell. In the great hall, Jon tells Sam that he will refuse Stannis's offer, as he swore an oath to the Night's Watch. After Ser Alliser and Denys Mallister are announced as possible candidates, Sam gives a speech imploring his brothers to vote for Jon, reminding them all how he led the mission to Craster's Keep to avenge Commander Mormont's death and how he led the defense of Castle Black. After the voting is complete, the ballots are tallied and show a tie between Jon and Ser Alliser. Maester Aemon casts the deciding vote in favor of Jon, making him the new Lord Commander of the Night's Watch. To lessen the animosity between the two, Jon makes Ser Alliser First Ranger. Melisandre takes an interest in Jon, visiting him in his quarters and trying to have sex with him. Jon refuses, out of respect for Ygritte and his Night's Watch vows. Jon makes plans to give the wildlings the lands south of the wall, known as the gift. He wants the Night's Watch and the wildlings to unite against the threat of the White Walkers. These more liberal views are not taken well by the men of the Night's Watch, in particular Ser Alliser and a young boy named Olly, whose village was massacred by wildlings. Jon then makes a trip north of the Wall to the wildling village of Hardhome, where he hopes to get the wildlings to join his cause. However, before many of them can get on boats to leave, a massive group of White Walkers arrives on the scene. A massive battle ensues, in which many wildlings are killed. The last remaining Night's Watchmen and wildlings, including Jon, depart from Hardhome, defeated. As they return to the Wall, they are let in by Ser Alliser Thorne, who disapproves of his drastic action of joining forces with the wildlings. Shorty after, Jon sends Sam and Gilly to safety in Oldtown, approving of their relationship and Sam's motives of keeping her safe. He is later approached by Davos asking for men, and later Melisandre, whose silence confirms Stannis's defeat. That evening, Jon is met by Olly who claims that a range has arrived with knowledge of Jon's uncle Benjen. However, Jon discovers that he has been fooled and a mutinee, led by Ser Alliser Thorne, stab Jon repeatedly, with Olly dealing the final blow to Jon's heart, leaving him to die in the snow.","tags": ["stark","night's watch","brother","snow"]}
    }, {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Sansa Stark",
      "_score": 1.0,
      "_source":{"house": "Stark","gender": "female","age":"25","biography": "Sansa Stark is the first daughter and second child of Eddard and Catelyn Stark. She was also the future bride of Prince Joffrey, and thus the future Queen of the Seven Kingdoms as well. Her direwolf is called Lady, she is the smallest of the pack. Sansa is naive and wants to live the life of a fairy tale princess and is unwilling to see the harsh realities of the kingdom's politics and rivalries. Her fantasy begins to shatter when Lady is killed, and the situation continues to worsen when her father is arrested for treason. She becomes a hostage to the Lannisters in order for them to have a legitimate claim for the North. Her naivete is finally shattered when King Joffrey executes her father despite promising her that he would spare him. Sansa is forced to put up an act or endure Joffrey's cruelty. Throughout Season 2, she suffers under Joffrey's abuse until Tyrion puts a stop to it. By the Season 2 finale, Joffrey breaks his engagement with Sansa to marry Margaery Tyrell. However, she is still a hostage; but Petyr Baelish promises to help her return to Winterfell. In Season 3, she is married to Tyrion to secure the Lannisters the North should Robb Stark die. The marriage is unhappy and yet to be consummated, and after Robb's death – upon which Joffrey insists to be given his head to present to Sansa, a request coldly ignored by his grandfather – she is unable to speak to him. In Season 4, Sansa has been mourning her family for weeks and is starving herself in depression. She attends Joffrey's wedding with Tyrion and witnesses Joffrey's death. Dontos Hollard immediately spirits her away from the wedding, moments ahead of Cersei's orders to have her and Tyrion arrested. Dontos brings Sansa to a ship concealed in fog, and she is greeted by Petyr Baelish. Under the guise of making payment, Petyr has the fool killed by his archers, with Petyr explaining that killing Dontos was the only way to ensure his silence - her disappearance when Joffrey died, the execution of her father, deaths of her family and years of torment at the king's hand, will all be considerable motive for Sansa helping Tyrion murder Joffrey. Currently, a thousand of the City Watch are searching for her, Cersei thirsts for vengeance, and Tyrion himself stands trial. Sansa is assured she has finally escaped King's Landing and is safe with Lord Baelish, who takes her to her Aunt Lysa for shelter. Lysa takes Sansa in warmly and has her betrothed to her son, Robin. However, Sansa realises the worst is far from over when Lysa, who is smitten with Petyr, accuses Sansa of trying to seduce him, and she discovers that Robin is a spoiled and rude child, slapping him at one point. When Petyr unexpectedly kisses Sansa, Lysa becomes enraged and nearly pushes Sansa through the castle's Moon Door, but Petyr intervenes by pacifying Lysa and then pushing her through the Moon Door to her death before Sansa's eyes, making Sansa realise that Petyr may have romantic or lustful feelings for her. Sansa speaks up for Petyr when he is questioned about his involvement in Lysa's death, but Sansa reaffirms Petyr's claim that Lysa killed herself due to her own instability and insecurities. Afterward she told Petyr that her reason to protect him in the hearing was because she knew he was the only person she could count on to protect her, demonstrated by his initiative in getting her out of King's Landing while everyone else in power there only wanted to use her as a pawn. In Season 5, she and Petyr leave the Eyrie for a place Petyr promises where Cersei will never find her. At an In, Brienne of Tarth materializes unexpectedly and declares herself for Sansa. Petyr doubts that Sansa would want a sworn shield who let both of her previous masters die, even when Brienne reveals the true, somewhat unbelievable circumstances of Renly's death. Sansa seems inclined to agree, pointing out that Brienne was present at Joffrey's wedding, to which the warrior replies that neither of them wanted to be there. Sansa rejects Brienne's offer of service and watches as she handily defeats the guards and escapes. Petyr tells her that he has arranged for her to be married to Ramsay Bolton, the son of Lord Roose Bolton. This will put her back in Winterfell, which the Boltons now occupy as a reward for their role in the deaths of Robb and Catelyn. Though Ramsay initially seems interested in Sansa, his psychopathic nature quickly shows through, and Sansa is disgusted. She is also antagonized by Myranda, the kennelmaster's daughter, who is in a sexual relationship with Ramsay. Myranda frequently makes veiled threats to Sansa, and shows her what has become of Theon Greyjoy, who was Eddard Stark's ward and whom she grew up with. Sansa is horrified to find that after Ramsay emasculated him, he has taken on a submissive, sullen persona called Reek. After Sansa and Ramsay are wed, he brutally rapes her while forcing Reek to watch. Later, Sansa attempts to talk to Reek, who is unresponsive to her attempts to make him act like his old self by repeatedly calling him Theon instead of Reek. At one point, Reek mistakenly lets slip that her younger brothers, Bran and Rickon, are alive, when she had assumed that they were dead. This realization gives Sansa hope in the midst of her unfortunate situation. As Stannis Baratheon's army sneaks up on Winterfell and is greeted by the bulk of the Bolton forces, Sansa manages to escape her chamber but is stopped by Myranda, who threatens her with a bow. Reminding Sansa that she has nothing left to live for in Ramsay's custody, she is unexpectedly saved by Reek, who breaks his spell of subjugation by throwing Myranda over the bannister. In terror, the couple flees to the wall, where they make the jump off the ledge.","tags": ["stark","wife","dead father"]}
    } ]
  }
}
{% endhighlight %}

This JSON document, more than just giving your the results, also provides some data about the way the query has been handled. The `took` field
tells you **how long (in milliseconds) the request took to be executed.** `_shards` gives you **information about the shards involved in the processing
of the query.** Finally, `hits` provides information about the results: `total` which is the **total number of documents that matches the query**, `max_score`
is the **maximum relevance score found among the matching documents**, and finally, `hits` is an array that **contains JSON objects**. Inside these objects,
your document can be found in the `_source` field.

#### Choosing the fields to be returned

Well, sometimes, documents can be heavy. That's why it could be interesting, when querying, to **only return some specifics fields**. That can
be done by setting the `fields` field in your DSL query. The `fields` field is an array, **containing the name of the fields you want to be returned.**

For example, let's say that we only want the name and the age of the Game Of Thrones' character that match the house "Targaryen" to be returned (for reminder, the
name is also our document's id, so it is stored into the `id` field).

**The DSL Query:**

{% highlight json %}
{
  "fields": ["id", "age"],
  "query": {
    "query_string": {
      "query": "house:Targaryen"
    }
  }
}
{% endhighlight %}

This DSL query is available in the `queries/DSL/query_string_fields.json` file.

{% highlight sh %}
$>curl –XGET 'http://localhost:9200/game_of_thrones/character/_search?pretty' --data-binary @query_string_fields.json
{% endhighlight %}

After executing the query as we did above, we obtained the following JSON response:

{% highlight json %}
{
  "took": 28,
  "timed_out": false,
  "_shards": {
    "total": 5,
    "successful": 5,
    "failed": 0
  },
  "hits": {
    "total": 1,
    "max_score": 1.4054651,
    "hits": [ {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Daenerys Targaryen",
      "_score": 1.4054651,
      "fields": {
        "age": [ "18" ]
      }
    } ]
  }
}
{% endhighlight %}

Here, you can see a little difference between this document and the previous response. Indeed, `_source` **field has been replaced by** `fields` field,
containing the fields your required. Also, you can see that `_id` field is separated from other fields, and is not contained into `fields` field.

Note that if you give an empty array to the `fields` field, all fields will be returned (an other way would be to give `*` value to `fields` field).

#### Scripting

Yes, Elasticsearch **allows you to do scripting!** I told you, what an amazing tool it was! Actually, we are talking here about **fields that value is
calculated by the cluster.**

The first thing to do, is to **turn scripting on.** Indeed, **by default, this module is disabled, because it may cause security issues on not well configured
clusters.** Scripting requires to be turned on specifically for **each type of request** (search, aggregate, ...). For example, to turn on inline scripting
on search request (we will need that right after), the need is just to put this line in your `elasticsearch.yml` file:

`script.engine.groovy.inline.search: on`

Fortunately, **if you are using the pre-configured docker-based Elasticsearch cluster I provided you in the Github repository, this configuration
is already set.**

So, for example, let's say that we want to know how old the character of the "Stark" house will be in 16 years. What we need to do, is create
a script-evaluated field, named `future_age`, calculated from the `age` field. All we have to do, is to add `16` to the `age` field.

With scripting, there are two ways to select a field from an existing document.

- Using `doc['name_of_the_field'].value`, is **faster but has a higher memory usage**, and is **limited to fields that have a single value**, and **single terms.**
For us, that would mean that we cannot use the `doc` notation on fields such as `tags` (it is an array), or `biography` (it is not single term field).
- Using `_source.name_of_the_field` notation, that allows **more complicated fields to be used, and has a lower memory usage (but is slower).**

I will show you the two ways to retrieve the `future_age`:

The first one, with the `doc` notation (can be found in `queries/DSL/query_string_script_doc.json`):

{% highlight json %}
{
  "script_fields": {
    "future_age": {
      "script": "doc['age'].value + 16"
    }
  },
  "query": {
    "query_string": {
      "query": "house:Stark"
    }
  }
}
{% endhighlight %}

And the second one, with the `_source` notation (can be found in `queries/DSL/query_string_script_source.json`):

{% highlight json %}
{
  "script_fields": {
    "future_age": {
      "script": "_source.age + 16"
    }
  },
  "query": {
    "query_string": {
      "query": "house:Stark"
    }
  }
}
{% endhighlight %}

We can try each of them by executing the request on the cluster (assuming we are located in `queries/DSL`):

The request type is `GET`:

{% highlight sh %}
$>curl –XGET 'http://localhost:9200/_search?pretty' -d @query_string_script_doc.json
{% endhighlight %}

Or

{% highlight sh %}
$>curl –XGET 'http://localhost:9200/_search?pretty' -d @query_string_script_source.json
{% endhighlight %}

The response would look like this:

{% highlight json %}
{
  [...]
  "hits": {
    [...]
    "hits": [ {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Robb Stark",
      "_score": 1.4054651,
      "fields": {
        "future_age": [ 38 ]
      }
    }, {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Arya Stark",
      "_score": 1.2231436,
      "fields": {
        "future_age": [ 33 ]
      }
    },
    [...]
    ]
  }
}
{% endhighlight %}

As you can see, for each `hits.fields`, the field `future_age` has been calculated by the cluster.

> Note that the cluster didn't insert the `_source` field containing the whole document. Indeed, if you wish to have the `_source` field, you will have to request for it by
using the `fields` parameter in the DSL query, the same way we did above.

#### The basic queries

I want to introduce you some of the **basic queries**, available on Elasticsearch. There is a bunch of query types that can be performed. The ones we are going to review
right now are the simplest ones. In the next article, I will talk about more complicated queries (such as compound queries, geo-localisation, ...).

But let's focus on the full-text basic queries for now.

##### The Term and Terms queries

The two first queries I want to talk about are the *Term* and *Terms* queries. The first one, the *Term* query is **simply searching for a single term on the cluster, for a
specific field.** The second one, the *Terms* query - as you might have guessed - stands to **search for one or several terms, for a specific field.**

**The Term query**

There is not much to be said about this query, except that the term you will provide has to be the *exact* term you are looking for (it is not analyzed). The JSON syntax for this type of
query is quite simple:

{% highlight json %}
{
  "query": {
    "term": {
      "nameOfTheField": "valueToBeSearched"
    }
  }
}
{% endhighlight %}

`nameOfTheField` should be replaced with the field's name that contain the term you are looking for, and `valueToBeSearched` represents its value.

For example, if we want to retrieve all characters that belongs to the `Targaryen` house. `house` field would then be set to `Targaryen`. Please note that, once again, only
the **exact** term will be searched. Therefore, terms such as `targaryen` (without first capital letter), or `TaRgArYEN` will not match anything.

Our query is the following (available at `queries/DSL/query_term.json`):

{% highlight json %}
{
    "query": {
        "term": {
            "house": "Targaryen"
        }
    }
}
{% endhighlight %}

Then, let's query the cluster:

{% highlight sh %}
$> curl -XGET 'http://localhost:9200/game_of_thrones/character/_search?pretty' -d @query_term.json
{% endhighlight %}

> Note that as the `game_of_thrones` index contains only one type (`character`), we could get rid of the `/character` part in the curl call.

We got the response from the server:

{% highlight json %}
{
  [...]
  "hits": {
    "total": 1,
    "max_score": 1.4054651,
    "hits": [ {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Daenerys Targaryen",
      "_score": 1.4054651,
      "_source":{
            "house": "Targaryen",
            "gender": "female",
            "age":18,
            "biography": "Daenerys Targaryen [...] a trail she is surrounded.",
            "tags": ["targaryen","dothraki","khaleesi"]}
    } ]
  }
}
{% endhighlight %}

As you can see, only one document matches the query, with the id `Daenerys Targaryen`.

**The terms query**

This query allows to search documents that **match several terms in their content.** The query will then be an array of all different searched terms, and in addition to that,
a `minimum_match` parameter can be set, indicating **how many terms have to match in the document for it to be considered as matching the query.** Careful though, as the
*Term* query, the term **is not analyzed**, and has to be *exactly* the one you are searching.

The query is the following:

{% highlight json %}
{
    "query": {
        "terms": {
            "nameOfTheField": ["value1", "value2", ...]
            "minimum_match": minimumMatchNumber
        }
    }
}
{% endhighlight %}

The search will be performed on the field named as `nameOfTheField`, and will search for the values contain in the array. In addition, the parameter `minimum_match` will ensure
that the document contains at least `minimumMatchNumber` matching terms.

For example, as you know, bastards in Game of Thrones are named as Snow. In the dataset I provided you, the field `tags` contains a bunch of keywords related to each character.
For bastards, such as Jon Snow, I added the tag `snow`. Let's look for it.

Our query (available at `queries/DSL/query_terms.json`):

{% highlight json %}
{
    "query": {
        "terms": {
            "tags": ["snow"],
            "minimum_match": 1
        }
    }
}
{% endhighlight %}

We can launch it with curl:

{% highlight sh %}
$> curl -XGET 'http://localhost:9200/game_of_thrones/character/_search?pretty' -d @query_terms.json
{% endhighlight %}

And the result will be the following:

{% highlight json %}
{
  [...]
  "hits": {
    "total": 2,
    "max_score": 0.83837724,
    "hits": [ {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Jon Snow",
      "_score": 0.83837724,
      "_source":{
            "house": "Stark",
            "gender": "male",
            "age":19,
            "biography": "Jon Snow is the bastard [...] in the snow.",
            "tags": ["stark","night's watch","brother","snow"]
            }
    }, {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Ramsay Bolton",
      "_score": 0.614891,
      "_source":{
            "house": "Bolton",
            "gender": "male",
            "age":23,
            "biography": "The illegitimate son of Roose Bolton, Ramsay Snow [...] the process.",
            "tags": ["bolton","sansa stark","bastard","snow"]}
    } ]
  }
}

{% endhighlight %}

As you can see, two characters has been returned: Jon Snow and Ramsay Bolton.

##### The Match query

I talked about *Term* and *Terms* queries, that are working with non-analyzed terms. In other words, you have to give Elasticsearch the *exact* term(s) you are looking for, because
the cluster is not going to analyze it. For example, a *term* query on `Jon Snow and Cersei Lannister` on the `biography` field won't give us any result, because the term is considered to be
the full sentence: `Jon Snow and Cersei Lannister`.

Well now, if we want to search for `Jon`, `Snow`, `and`, `Cersei`, `Lannister`, *term* query won't be enough. Though we can proceed this query with *terms* query, it is not
convenient. Moreover, *match* query allows us to use some more parameters, as we will see. Also, **the query string will be analyzed.**

The global format for this query is the following:

{% highlight json %}
{
    "query": {
        "match": {
            "nameOfTheField": "queryString",
        }
    }
}
{% endhighlight %}

Well here, `nameOfTheField` should be replaced with the field's name, and `queryString` with the query string.

Let's try it on the previous query string (`Jon Snow and Cersei Lannister`) (available at `queries/DSL/query_match.json`):

{% highlight json %}
{
    "query": {
        "match": {
            "biography": "Jon Snow and Cersei Lannister"
        }
    }
}
{% endhighlight %}

Then, we request the cluster:

{% highlight sh %}
$> curl -XGET 'http://localhost:9200/game_of_thrones/character/_search?pretty' -d @query_match.json
{% endhighlight %}

And the result is:

{% highlight json %}
{
  [...]
  "hits": {
    "total": 13,
    "max_score": 0.17795758,
    "hits": [ {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Bran Stark",
      "_score": 0.17795758,
      "_source":{
            "house": "Stark",
            "gender": "male",
            "age":11,
            "biography": "Brandon Bran Stark [...] instead.",
            "tags": ["stark","disable","crow"]}
    }, {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Jon Snow",
      "_score": 0.10023197,
      "_source":{
            "house": "Stark",
            "gender": "male",
            "age":19,
            "biography": "Jon Snow is [...] the snow.",
            "tags": ["stark","night's watch","brother","snow"]}
    },
    ...
    ]
  }
}

{% endhighlight %}

You can see that 13 documents are matching the query.

If you wish to insert parameters, then the format is the following:

{% highlight json %}
{
    "query": {
        "match": {
            "nameOfTheField": {
                "query": "queryString",
                "parameter1": "value",
                [...]
            }
        }
    }
}
{% endhighlight %}

The syntax in nearly the same than the "without parameters" *match* query, except that `nameOfTheField` contains an **object that describes both the query and its parameters.** Then, the query string has to be set as the value
of the `query` parameter, followed by the other parameters.

I won't detail each parameter, because some are not relevant in this article. Furthermore, some parameters would need a bunch of explanations...

Ok, let's simply begin with the `operator` parameter. What you should know is that the query string is in fact **analyzed by the cluster** (by default, with the same analyzer than
the field). Once the query string analyzed (and split into *terms*), a *term* query is performed for each *term*. Then, the **results are merged to create the final result.**
Default value of `operator` is `or`. Possible values are either `and` or `or`.

For example, let's perform the same query, but with the `and` operator (query available in `queries/DSL/query_match_operator_and.json`):

{% highlight json %}
{
  "query": {
    "match": {
      "biography": {
        "query": "Jon Snow and Cersei Lannister",
        "operator": "and"
      }
    }
  }
}
{% endhighlight %}

Requesting the cluster with this query would return the following result:

{% highlight json %}
{
  [...]
  "hits": {
    "total": 1,
    "max_score": 0.1779576,
    "hits": [ {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Bran Stark",
      "_score": 0.1779576,
      "_source":{
            "house": "Stark",
            "gender": "male",
            "age":11,
            "biography": "[...] Cersei and [...] Lannister [...] Jon Snow [...]",
            "tags": ["stark","disable","crow"]}
    } ]
  }
}

{% endhighlight %}

As you can see, the document identified as `Bran Stark` is the only one that gather the requirements. Indeed, in its `biography` field, all the required terms are present.

The next parameter I would like to introduce is the `fuzziness` parameter. To make it short, *fuzziness* is like **"allowing you to make typo mistakes"**. On numeric, IP and date
fields, fuzziness **will be interpreted as a range.** On string, an algorithm, known as *Levenshtein Edit Distance* will be applied. [https://en.wikipedia.org/wiki/Levenshtein_distance](https://en.wikipedia.org/wiki/Levenshtein_distance).

The fuzziness value must be set between 0.0 and 2.0, or `AUTO`. Also, fuzziness depends on the length of the terms. The more longer the term is, the more "edits" will be allowed.

Let's try the previous query (with the `operator` parameter), but by setting the `fuzziness` parameter to `2`.

The format of the query (available at `queries/DSL/query_match_fuzziness.json`):

{% highlight json %}
{
  "query": {
    "match": {
      "biography": {
        "query": "Jon Snow and Cersei Lannister",
        "operator": "and",
        "fuzziness": 2
      }
    }
  }
}
{% endhighlight %}

The result returned by the cluster:

{% highlight json %}
{
  [...]
  "hits": {
    "total": 8,
    "max_score": 0.29372954,
    "hits": [ {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Jaime Lannister",
      "_score": 0.29372954,
      "_source":{
            "house": "Lannister",
            "gender": "male",
            "age":34,
            "biography": "Ser Jaime Lannister [...]",
            "tags": ["lannister","king slayer","golden hand","ser","blond"]}
    }, {
      "_index": "game_of_thrones",
      "_type": "character",
      "_id": "Cersei Lannister",
      "_score": 0.21208765,
      "_source":{
            "house": "Lannister",
            "gender": "female",
            "age":34,
            "biography": "Cersei Lannister, [...] Gregor Clegane.",
            "tags": ["lannister","queen","baratheon","shame"]}
    },
     ...]
  }
}
{% endhighlight %}

As you can see, from the same request, with `and` operator and `fuzziness` set to `2`, we got **8 results**.

## What's coming next?

With this article, I just started to scratch the surface of Elasticsearch's possibilities concerning full-text search.

In the next article, I would like to talk about tree-like document structures, scoring (because there are several way for scoring to be calculated).
Also, I think I will introduce you to scripting with Groovy and other languages that can be used to perform scripting with Elasticsearch.
