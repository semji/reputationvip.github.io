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
- Create the queries files
- Charlotte review
- :

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

One of these parameters is the **numeric detection**. If the `numeric_detection` parameter is set to `true`, then Elasticsearch will search into strings to find out if the string
is a real string, or if it is a number. For example, with the **numeric detection** enabled for the `age` field, a string like `"10"` would be considered as a number.

**The query**

To turn on the `numeric detection`, we will have to query our cluster.

The query type is `PUT`.

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/indexName</span><span style="color: chartreuse">?pretty</span></code></pre></div>

The data you need to send are the following:

{% highlight json %}
{
    "name_of_the_type": {
        "numeric_detection": true
    }
}
{% endhighlight %}

**The response**

{% highlight json %}
{
  "acknowledged" : true
}
{% endhighlight %}

As you can see, there is nothing special in the response. It looks like every other response from the server, when you are creating an index. So the question that might come to
your mind is the following : How can you check that the **numeric detection** has been turned on for a given field 

Actually, it is very simple. You can request your cluster about its settings. I don't want this article to be too much, so I won't talk much about it right here. I'd rather let
you have a look here, on the official documentation : [https://www.elastic.co/guide/en/elasticsearch/reference/1.6/indices-get-settings.html](https://www.elastic.co/guide/en/elasticsearch/reference/1.6/indices-get-settings.html).

**Full example**

Let's say that we want to build an index, indexing all cities and places in Westeros. By the way, Elasticsearch provides spatial search, which is an amazing feature. I hope that
I will have time to talk about it in the articles to come. Anyway, we want to index the Westeros places. For that, let's say that our index would contain the population count
of each cities we are indexing. The index would be `game_of_thrones_place` and the type for cities, `city`. Of course, we want to enable **numeric detection** for the `city` type.

Our curl request would be :

{% highlight sh %}
$> curl –XPUT http://localhost:9200/game_of_thrones_place?pretty -d '{"city": {"numeric_detection": true }}'
{% endhighlight %}

***

###### Date detection

I'm gonna speed up a bit, because the principle about **date detection** is exactly the same than the numeric detection. The request you have to make is the same, only the
value is changing. The parameter is called `dynamic_date_formats`. As you may have noticed, the name of this parameter is plural. The reason is that the value will be an array,
containing every formats you want to recognize as a valid date format. **The format has to be specified following ISO 8601
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

For example, let's say that we want to enable **date detection** on a type, and allow the two following date format : `yyyy-MM-dd hh:mm` and `dd-MM-yyyy hh:mm`. The forged request
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

**Be careful : Disabling dynamic type guessing lead you to define your entire mapping; without defining it, unknown field will be ignored.**

**The query**

The query will have two parts:

- The first part is the type guessing disabling.
- The second part is the definition of the fields mapping.

{% highlight json %}
{
    "name_of_the_type": {
        "dynamic": false,
        "properties": {
            ...
            ...
        }
    }
}
{% endhighlight %}

As you might guess, `"dynamic": false` turns the type guessing off. On the other hand, `"properties": { ... }` contains your mapping.

Mapping could be either really simple, or really complex. Elasticsearch allows you to precisely define the format of each fields, and the way it will be handled
by Apache Lucene. To read more about the available options of each field type, you can take a look here : [https://www.elastic.co/guide/en/elasticsearch/reference/1.6/mapping-core-types.html](https://www.elastic.co/guide/en/elasticsearch/reference/1.6/mapping-core-types.html).
This page is talking about `Core Types`, which are the *basic* types : *Integer*, *String*, *float / double*, ... But even more types are available in Elasticsearch, such as `Array`,
`Object`, `IP`, `Geo Point` and `Geo Shape` (two types I'd like to write an article about).

I could write a hundred pages article about types, as they have hundred of options, but I don't think it would be relevant here. So that I let you read the official documentation,
which is complete and clear.

#### Analyzers

Wow, wow, wow ! It has been a long way til there. Right now will be our first talk about **full-text research**, and more precisely, **text analysis** with Elasticsearch's **Analyzers**.

I hope you do remember, I talked a bit about **Tokenizers** and **Token filters** in the first article, when I gave you an overview of what is behind Elasticsearch, and how text is processed by Elasticsearch.

Today, I'm in the mood, so let me refresh your memory about them.

> Using Elasticsearch, data and queries can be analyzed, with the precious help of **analyzers**. **Analyzers** is the word we use to talk about both **Tokenizers** and **Token filters**.
**Tokenizers** stand to split a string into several **tokens**, which are processed by one or more **Token filters**. The role of **Token filters** is to modify tokens : lowercasing,
uppercasing, removing some tokens, ...

Anyway, you should remember that an **analyzer** is composed of a **tokenizer** and one or more **token filters** (and some other stuff, like a **character filter**).

As Elasticsearch's developers are cool guys, they already provided you some ready-to-use **analyzers**. Nowadays, there are 4 **analyzers**, but the amazing point is that, using
**tokenizer** and **token filters**, you are able to define your own **analyzers**.

First, let's talk about the ready-to-use **analyzers**, how to use it, and finally, how to define your owns.

##### Ready-to-use Analyzers

Elasticsearch provides, at this time, 8 **analyzers**. I will talk a bit about the ones that I consider to be the most interesting.

###### Standard Analyzer

Well, as its name defines it, the **standard analyzer** is the most simple one, in terms of European Languages. Using the **standard tokenizer**, it passes tokens through **standard
token filter**, **lower case filter** ans then **stop token filter**. Although **standard token filter** and **lower case filter** speak for themselves, let's stop on the **stop token
filter**. This filter stands to remove tokens defined as *stop words*. *Stop words* are small words, such as, for example: "and", "the", etc.

Let's practice it.

In their gread goodness, Elasticsearch developers provided us a way to have a look at the token stream. That will help us to try the **analyzers** right now, and get rid of the
configuration for now.

**The query**

The query type is `GET`

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
its **end offset**. Also, you can see the type of the token, and the position in the **token stream**.

**Full example**

Ok. Remember Jon Snow ? We created his biography in the first article. Let's take the sentence I used to describe him:

> Jon Snow (15) is the bastard son of Eddard Stark, the lord of Winterfell. He is the half-brother of Arya, Sansa, Bran, Rickon and Robb.

Let's process this sentence through the **standard analyzer**, and see what we get. For that, we are using the first index we created in the first article, `game_of_thrones`.

{% highlight sh %}
$> curl -XGET 'http://localhost:9200/game_of_thrones/_analyze?pretty&analyzer=standard' -d 'Jon Snow (15) is the bastard son of Eddard Stark, the lord of Winterfell. He is the half-brother of Arya, Sansa, Bran, Rickon and Robb.'
{% endhighlight %}

And now, let's see the result.

{% highlight json %}
{
  "tokens" : [ {
    "token" : "jon",
    "start_offset" : 0,
    "end_offset" : 3,
    "type" : "<ALPHANUM>",
    "position" : 1
  }, {
    "token" : "snow",
    "start_offset" : 4,
    "end_offset" : 8,
    "type" : "<ALPHANUM>",
    "position" : 2
  }, {
    "token" : "15",
    "start_offset" : 10,
    "end_offset" : 12,
    "type" : "<NUM>",
    "position" : 3
  }, {
    "token" : "is",
    "start_offset" : 14,
    "end_offset" : 16,
    "type" : "<ALPHANUM>",
    "position" : 4
  }, {
    "token" : "the",
    "start_offset" : 17,
    "end_offset" : 20,
    "type" : "<ALPHANUM>",
    "position" : 5
  }, {
    "token" : "bastard",
    "start_offset" : 21,
    "end_offset" : 28,
    "type" : "<ALPHANUM>",
    "position" : 6
  }, {
    "token" : "son",
    "start_offset" : 29,
    "end_offset" : 32,
    "type" : "<ALPHANUM>",
    "position" : 7
  }, {
    "token" : "of",
    "start_offset" : 33,
    "end_offset" : 35,
    "type" : "<ALPHANUM>",
    "position" : 8
  }, {
    "token" : "eddard",
    "start_offset" : 36,
    "end_offset" : 42,
    "type" : "<ALPHANUM>",
    "position" : 9
  }, {
    "token" : "stark",
    "start_offset" : 43,
    "end_offset" : 48,
    "type" : "<ALPHANUM>",
    "position" : 10
  }, {
    "token" : "the",
    "start_offset" : 50,
    "end_offset" : 53,
    "type" : "<ALPHANUM>",
    "position" : 11
  }, {
    "token" : "lord",
    "start_offset" : 54,
    "end_offset" : 58,
    "type" : "<ALPHANUM>",
    "position" : 12
  }, {
    "token" : "of",
    "start_offset" : 59,
    "end_offset" : 61,
    "type" : "<ALPHANUM>",
    "position" : 13
  }, {
    "token" : "winterfell",
    "start_offset" : 62,
    "end_offset" : 72,
    "type" : "<ALPHANUM>",
    "position" : 14
  }, {
    "token" : "he",
    "start_offset" : 74,
    "end_offset" : 76,
    "type" : "<ALPHANUM>",
    "position" : 15
  }, {
    "token" : "is",
    "start_offset" : 77,
    "end_offset" : 79,
    "type" : "<ALPHANUM>",
    "position" : 16
  }, {
    "token" : "the",
    "start_offset" : 80,
    "end_offset" : 83,
    "type" : "<ALPHANUM>",
    "position" : 17
  }, {
    "token" : "half",
    "start_offset" : 84,
    "end_offset" : 88,
    "type" : "<ALPHANUM>",
    "position" : 18
  }, {
    "token" : "brother",
    "start_offset" : 89,
    "end_offset" : 96,
    "type" : "<ALPHANUM>",
    "position" : 19
  }, {
    "token" : "of",
    "start_offset" : 97,
    "end_offset" : 99,
    "type" : "<ALPHANUM>",
    "position" : 20
  }, {
    "token" : "arya",
    "start_offset" : 100,
    "end_offset" : 104,
    "type" : "<ALPHANUM>",
    "position" : 21
  }, {
    "token" : "sansa",
    "start_offset" : 106,
    "end_offset" : 111,
    "type" : "<ALPHANUM>",
    "position" : 22
  }, {
    "token" : "bran",
    "start_offset" : 113,
    "end_offset" : 117,
    "type" : "<ALPHANUM>",
    "position" : 23
  }, {
    "token" : "rickon",
    "start_offset" : 119,
    "end_offset" : 125,
    "type" : "<ALPHANUM>",
    "position" : 24
  }, {
    "token" : "and",
    "start_offset" : 126,
    "end_offset" : 129,
    "type" : "<ALPHANUM>",
    "position" : 25
  }, {
    "token" : "robb",
    "start_offset" : 130,
    "end_offset" : 134,
    "type" : "<ALPHANUM>",
    "position" : 26
  } ]
}
{% endhighlight %}

Well, we got pretty lot of data here. There is several interesting points. The first one, as I told you, **lowercase token filter** has been used, and you can see that proper names,
such as *Arya*, or *Rickon* has been divest of their uppercased first letter. Second point, parts of the original string have been removed; it is the case for parenthesis, and
final point. If you take a look at the `type` field, you may notice something. Here, I haven't disable **dynamic type guessing**, and the only number (`15`) in the string has
been recognized as such (`<NUM>`).

###### Simple analyzer

The second analyzer I'd like to talk about is the **simple analyzer**. The difference between it and the standard analyzer is really thin, but significant. First, it will ignore
and remove all non-letter characters. For example, analyzing `Jon11111Snow` with the **simple analyzer** will result as two token, `Jon` and `Snow`. The second difference is about
the type. The resulting token's type will be `word`.

I won't give you a full example here, because the query is almost the same (only the name of the analyzer is different).

###### The Snowball analyzer

The last analyzer I want to talk about is the **snowball analyzer**. This analyzer is like the ugly duckling of ready-to-use analyzers. It is using a stemming algorithm, and the token
stream resulting is made with root words. Let's take an example. Analyzing `King's Landing` with the **snowball analyzer** will result in a stream of two tokens : `king` and
`landing`. What we have here is a loss of data. Indeed, `landing` has been transformed into `land`, its root word. 

##### Configuring Indices Mapping with Analyzers

Right until now, we tested the analyzers directly through the cluster's API, without really storing data. The cluster was sending us the **token stream**, so that we can dive inside
it. But of course, I think you guessed that we can configure indices to automatically apply analyzers right onto input data. For each field defined in your mapping, you will be
able to define an analyzer to be applied on the input data.

**The query**

When defining mapping of a given type, for a given index, you can set an **analyzer** for each field, separately. The request would looks like this:

{% highlight json %}
{
    "name_of_the_type": {
        "properties": {
            "field_name": {
                ...,
                "analyzer": "name_of_the_analyzer",
                ...,
            }
        }
    }
}
{% endhighlight %}

**The response**

The response will be the classical `"aknowledge": true` of the indices creation query.

**Here, I won't give you full example, because we will make practical usage of tokens when we will come to full-text research.**

##### Making you own Analyzer

Because Elasticsearch aims to be flexible, you can **create your own analyzers**. If you remember, what we call **analyzer** is simply a combination of a **tokenizer**, some
**token filters** (and some other stuff, like a **character filter**). The creation of a custom analyzer step during the creation of the index. The definition of it stands
in the `settings.index.analysis.analyzer` field of the query you send to the cluster to create the index.

**The query**

{% highlight json %}
{
    "settings": {
        "index": {
            "analysis": {
                "analyzer": {
                    "name_of_your_analyzer": {
                        "tokenizer": "tokenizer",
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

As this process step in the index creation process, the response will be the classical response returned when creating an index.

**Full example**

I want to create an analyzer, which I will name as `wildfire_analyzer`. It will be composed, for the tokenizer, of the `standard` tokenizer, and for the token filter,
of the `synonym` token filter and the `trim` token filter. Actually, I choose them randomly, so that I don't really know what could be the token stream resulting of the analysis
of a stream by my `wildfire_analyzer`.

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

That's it ! You just defined your own analyzer ! And since you also can create your own filters, you really are able to handle data the way you want.

##### More analyzers

The handful of ready-to-use analyzers defined by Elasticsearch might not be enough. Fortunately, Elasticsearch developpers are maintaining several Github repositories, with custom
analyzers. To use them, you just have to install them the classic way you install plugins. For examples, you can find a **phonetic analyzer**, **smart chinese analyzer**, and so on.

If you don't remember how to install plugins, you can have a look at the end of [the first article's introduction to plugin](http://reputationvip.io/elasticsearch-is-coming/#introduction-to-plugins).
