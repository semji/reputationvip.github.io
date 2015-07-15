---
layout: post
author: quentin_fayet
title: "Elasticsearch Is Coming"
excerpt: "The first article about Elasticsearch, the full-text search engine based on Apache Lucene"
modified: 2015-07-15
tags: [gitlab, git]
comments: true
image:
  feature: bandeau-gitlab.jpg
  credit: Alban Pommeret
  creditlink: http://reputationvip.io
---

# ELASTICSEARCH IS COMING

## ROADMAP

This article is the first of many to come about Elasticsearch. Elasticsearch is a vast and amazing technology, and I could write thousands of lines about it.

So first, let me introduce the summary of very this first article :

1. A smooth introduction to Elasticsearch
2. Theorical approach : What's under the armor of Elasticsearch ?
3. Installation and configuration of Elasticsearch
4. Querying : Basic CRUD
5. Introduction to plugins

***

## How to read these articles ?

Before we dive in Elasticsearch head first, let me tell you how I organized these articles.

#### The articles 
First of all, all along these articles, I will guide you through the understanding of Elasticsearch. 
Each part of the articles will provide you theorical explanations, as well as examples.

At ReputationVIP, we are big fans of Game of Thrones. So, the guideline I chose for these articles is Game of Thrones.
All along these articles (though I don't know how many of them will follow this one), we will build a database filled with the Game of Thrones characters.

#### The Github Repository

Available here : [https://github.com/quentinfayet/elasticsearch](https://github.com/quentinfayet/elasticsearch)

It contains everything you need to run this article's examples : A ready-to-run Elasticsearch cluster under Docker containers, and, also, for those of you who
are not working with an UNIX based system, a Vagrant virtual machine.

#### The Docker container

Beside being a big fan of Game of Thrones, I also am a big fan of Docker. For those whom don't know about Docker, you can take a look here : [https://www.docker.com/](https://www.docker.com/)
So, I decided to create an Elasticsearch **cluster** with Docker containers.
Each **node** of this **cluster** takes the name of a member of the Stark family.

In deed, I know how difficult it can be to read and run examples of other people. With this Docker container, you will have the same environment I used to write this article.

To launch the docker cluster, first clone the repository in the folder of your choice, and go into it.

I also ask you to install [https://docs.docker.com/compose/]( *docker compose*), which is a good solution to build and run multi-container applications with Docker.
The installation takes 2 minutes, and is really easy. Go here to install it : [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)

Once installed *docker compose* on your system, go into the `elasticsearch/docker` repository folder ; then, launch this command :

`docker-compose build`

This command will build the images of the containers. Once done, just launch the cluster with the following command :

`docker-compose up`

**Welcome on the Game of Thrones Elasticsearch cluster !**

***

## A smooth introduction to Elasticsearch

### A bit of history

The story of Elasticsearch started in 2004, when Shay Banon (founder of the [Compass Project](https://en.wikipedia.org/wiki/Compass_Project)) thought about the third version of Compass.
The need then was to create a scalable search engine. Shay Banon decided to build a whole new project from the ground, using a common JSON and HTTP interface (building a REST API),
making it suitable for other programming languages than Java.
The first version of Elasticsearch has been released in 2010.

Elasticsearch is based on [Apache Lucene](https://lucene.apache.org/), an open source information retrieval library, also written in Java by Doug Cutting and 
supported by the Apache Software Foundation.

Also, Elasticsearch is distributed, which means that **it can be divided into shards**, spread on a cluster of servers.

### Specific Vocabulary

In order for you to understand the rest of these articles, we'll need to speak the same language. That's why I give you here the basic vocabulary used when talking about Elasticsearch :

#### Document
The **Document** is the main data carrier of Elasticsearch, used for indexing and searching. It is composed of **fields, containing data**, retrieved by Apache Lucene.

#### Field
The **Field** refers as a part of a **Document**, composed of **a name and a value**.

#### Term
The **Term** is the unit of search. It represents **a word from the text**.

#### Token
The **Token** is **an occurence of a Term in a text field**. It is composed of **the Term, and both its start and end offsets**.

***

## Theorical approach : What's under the armor of Elasticsearch ?

In this part, I will talk about the main concepts that run Elasticsearch, about Apache Lucene and the full-text research. I will also give you an overview of data analysis, and how it is performed
by Elasticsearch and Apache Lucene. Finally, I will talk a bit about the architecture Elasticsearch is based on.

### Inverted Index

Apache Lucene stores data into a structure called **inverted index**. Instead of classical "relational" way, **inverted index** maps **Terms** to **Documents**. It is **term-oriented**,
instead of being **document-oriented** (like a classical document based database would be).

More than words, let me give you an example.

Given these 3 documents (simple text lines) :

- Document <1> : ReputationVIP digital fortress
- Document <2> : ReputationVIP likes Elasticsearch
- Document <3> : Elasticsearch Cookbook

The resulting **inverted index mapping** would be :

Terms         | Occurences | Documents |
--------------|:----------:|---------- |
ReputationVIP | 2          | <1>, <2>  |
digital       | 1          | <1>       |
fortress      | 1          | <1>       |
Elasticsearch | 2          | <1>, <2>  |

### Segment

Indices (plural form of index) can be really big. So, Apache Lucene divides them into **Segments**.
A **Segment** is only write once, and read many times. This means **segments can't be updated**.
Informations about deleted documents are written into separate files, since segments can't be updated.

#### Segments Merge

In order to improve performances, Apache Lucene may decides to proceed a **segment merge**.
Small segments are merged into bigger ones. **This can demands a lot of I/O**.
At that time, data are re-written into a new, bigger segment, and they might be updated ( *i.e* deleted documents).
It is faster to search in one big segment, rather than in several small ones.

### Input Data Analysis

**Input Data Analysis (IDA)** defines the process that transforms input raw data into indexed data.
The **Analyzer** is in charge of this process. **Different analyzers can be applied to different fields**.

#### Tokenizer
Apache Lucene's **Tokenizer** splits raw text into **tokens** (terms with position in the text & length).
The result is called **Token Stream** (stream of tokens which are going to be processed one by one by the **filters**).

#### Token Filters

**Token Filters** are applied on each token of the token stream.
Example of filters : 

- **Lowercase filter** (all tokens are lowercased)
- **Synonyms filter** (applies basic synonym rules to tokens), ...
-

The list of Elasticsearch's filters stands here : [https://www.elastic.co/guide/en/elasticsearch/reference/1.6/analysis-tokenfilters.html](https://www.elastic.co/guide/en/elasticsearch/reference/1.6/analysis-tokenfilters.html)

**Token Filters are processed one after another**

![Input Data Analysis](/images/elastic/input-data-analysis.png)

### Versioning

An important feature of Elasticsearch is the **versioning**. When a document is added, updated or deleted, the version number is incremented. This process is known as **versioning**.
It allows Elasticsearch to perform **optimistic concurrency control**

The **optimistic concurrency control (OCC)** assumes that frequently, multiple transactions car be performed. Each of them need to not to interfer with each other. When executing the
transaction, the data resources aren't locked. Before committing the transactions, it verifies that the data hasn't been modified by another transaction (using the version number). If so,
the transaction rolls back, and restarts.

### Scoring & Relevance

When Elasticsearch retrieve documents, it uses a formula, known as the **pratical scoring function** to calculate the relevance of each results. This formula (you can find
it here : [https://www.elastic.co/guide/en/elasticsearch/guide/current/practical-scoring-function.html](https://www.elastic.co/guide/en/elasticsearch/guide/current/practical-scoring-function.html))
depends on several KPIs. I won't detail them here, because it is not really relevant to know them right now. You should just know that this formula is based on a concept named
**TF/IDF (Term Frequency / Inverse Document Frequency)**. Basically, the final rank given to a document by Elasticsearch depends on the weight of each **term** in the document.

This weight is calculated with the **term frequency** (how often does it appear in the document), the **inverse document frequency** (how often does it appear **in every** document in the collection),
and the **field-length norm** (the field's length).

Scoring is a really interesting theoretical subject, but too long to be explained here. If you want to know more, I suggest you to take a look here : [https://www.elastic.co/guide/en/elasticsearch/guide/current/scoring-theory.html](https://www.elastic.co/guide/en/elasticsearch/guide/current/scoring-theory.html).

### Architecture : Nodes & Clusters

Elasticsearch is organized in **clusters**, composed of **nodes**.

A **node** is a **single instance of Elasticsearch server**.

A **cluster** is a **group of nodes** working together as a single entity, with a **master** and several **slaves**. Clustering nodes achieves **fault tolerance**, **high availability** and allows
**large set of data**.

![Elasticsearch Cluster](/images/elastic/cluster.png)

### Architecture : Shards

Nodes may be limited (RAM, I/O, Processing power, ...), and may not be able to answer queries fast enough.
So, each node can have **shards**.
**Shards** can be placed on different servers, and data are spread among them.
To answer a query, a node may then query each shard and then, merge the results in a single answer.
**Shards** can also **speed up indexing**.
When a node is added to the cluster, shards are **dynamically re-allocated**

![Shard](/images/elastic/shard.png)

### Architecture : Replicas

A **replica** is an exact copy of a shard, stored on an other server. It achieves **high availability**, because if a server fails down, the data can be found on an other **replica**.
Elasticsearch choose a shard to be the one which handles the index updates. It is called **Primary Shard** ; other shards are known as **Replica Shard**.
If the primary shard is lost ( *i.e* the server crashes), a replica shard is chosen as the new **primary shard**.

![Replica Shard](/images/elastic/replica.png)

### Architecture : Indexing

With a sharded architecture, indexing becomes a tricky operation. **Master node is in charge of this operation**. Its role is to **distribute indexing operations** to other nodes.

![Indexing](/images/elastic/indexing.png)

### Architecture : Querying

With a sharded architecture, querying also becomes a tricky operation. **Master node is in charge of this operation**. Its role is to **distribute searching operations** to other nodes.

![Searching](/images/elastic/searching.png)

***

## Installation

**If you just want to try Elasticsearch, you can get rid of the installation, since I already installed it on the Vagrant virtual machine, provided with this article.**

First of all, please take a look at the prerequisites to install Elasticsearch (at the time I wrote this article, Elasticsearch version is 1.6.0).

- Java 6 or more installed on each server of the cluster. **(Java 7 is highly recommended)**
- OpenJDK is highly recommended.

Elasticsearch is provided as a zip file, available here : [https://www.elastic.co/downloads/elasticsearch](https://www.elastic.co/downloads/elasticsearch)

Now, just unpack it in the folder of your choice. **You're ready to run Elasticsearch**.

***

## Configuration

Now Elasticsearch is installed, we need to configure it before running.

### Directory Layout

Let's take a look at the directory layout, which is pretty simple :

{% highlight sh %}
Directory
    |- *bin* : Stores the scripts used to run Elasticsearch
    |- *config* : Stores the configuration files
    |- *lib* : The libraries needed by Elasticsearch to run properly
    |- *data* : All the data of the node will be stored here !
    |- *logs* : The log files
    |- *plugins* : Stores the installed plugins
    |- *work* : The temporary files used by Elasticsearch when running
{% endhighlight %}

### Configuring Nodes & Cluster

According to the previous directory layout, the configurations files are stored in the `config` folder.

The main configuration file is located in `config/elasticsearch.yml`. It is a YAML file. If you're not comfortable with YAML, take a look at [http://yaml.org/](http://yaml.org/).
The syntax is really simple though. This file **handles the default configuration values** for the node.

Note that if you really don't like YAML, you can use a `config/elasticsearch.json` file, using the common JSON format. **I'll use the YAML format**, as it is the default format.

#### Important values

There is a bunch of values in this file, but 3 of them are really important, and represent the basic configuration values :

- `cluster.name` : It is the name of the cluster. **It is used to identify nodes belonging to the same cluster**
- `node.name` : It is the name of the node. If it is not provided, then Elasticsearch will performs a random-pick among a list of defined names.
- `http.port` : It is the default port on which Elasticsearch will listen to the HTTP traffic.

#### The discovery & the discovery modes

When running a cluster, each node has to be aware of his neighbours. This process (how to discover your neighbours) is called **discovery**.

There is **several ways for a new node to discover other nodes** of the same cluster.

##### Multicast Discovery

The **multicast discovery** is the **simpliest discovery mode**. Using the port 54328, the node will **ping** every other node with the multicast IP address on the network.
To enable the multicast discovery, set the following line in your configuration file :

`discovery.zen.ping.multicast.enabled: true`

##### Unicast Discovery

In **unicast discovery** mode, **each node has to know IP address of other nodes** in the cluster. The configuration in a little bit different. The configuration line in your
configuration file is the following :

`discovery.zen.ping.multicast.enabled: []`.

The point is on `[]`. It is an array of IP addresses, optionally defined with a port or a port range.

##### EC2 AWS

This **special mode** is made for the Elasticsearch cluster to work with **AWS EC2** instances. You can read more about it on [https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery-ec2.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery-ec2.html)

## Querying

That's it ! Our Elasticsearch cluster is now ready to use, and we will be able to query it !

### Basics of Querying

To **query** means that you will ask your Elasticsearch cluster to perform CRUD operations on its database. For that, you'll need to learn **how to use Elasticsearch's REST API**.

#### The REST API

All of the queries you'll make will go through **Elasticsearch's REST API**. If you don't know what a REST API is, you can have a look at [https://fr.wikipedia.org/wiki/Representational_State_Transfer](https://fr.wikipedia.org/wiki/Representational_State_Transfer).
Also, if you are not aware of the commons **HTTP Verbs**, take a look at [https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol)

#### The JSON format

To give Elasticsearch your criteria, you will have to pass them through data in HTTP headers, formatted with **JSON structure**.

#### CURL

If you don't have **curl** installed on your local machine (the machine with which you will query the cluster), I strongly recommend you to install it.

### Before Querying

All the examples above are available in the Github repository I created for this article, under the JSON format.

CURL gives you two ways of using the JSON data for your queries :

- The first one, by including it directly into your CURL call, using the `-d` parameter.
- The second one, by including data from the files I gave you in your CURL call, using the `--data-binary` parameter, indicating the path to the JSON file preceded with an @. (Example
: `--data-binary @path/to/file.json`)

### Understanding the REST API

To query Elasticsearch, we make calls to its **REST API**. The format of the URL we use is the following (assuming Elasticsearch is available on your localhost on port 9200) :

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">[/index[/type]]</span><span style="color: chartreuse">[/_action[?parameters]]</span></code></pre></div>

The first part is the **URL on which your Elasticsearch server is available**

<span style="color: orange">The second part indicates on which index (an index could be compared to an SQL database) your
query will be performed, and what is the type (a type could be compared to an SQL table) of the document. **From now, I will write indices and types in orange**</span>

<span style="color: chartreuse">The last part might be used to indicate which operation we want to do, and parameters can be set here. Note the uderscore (`_`) before the
action name). **From now, I will write actions and parameters in green.**</span>

### Create an Index

In Elasticsearch, an index might be compared to an SQL database. It will store a collection of documents, classified by type (SQL table).

#### The Query

The query type is `PUT`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/indexName</span><span style="color: chartreuse">?pretty</span></code></pre></div>

The first part is the **URL on which your Elasticsearch cluster API is available**.

<span style="color: orange">The **indexName** part indicates the name of the index you want to create.</span>

<span style="color: chartreuse">The **pretty** parameter stands to pretty-print the JSON response</span>

#### The response

The cluster should responds like this :

{% highlight json %}
{
    "acknowledge" : true
}
{% endhighlight %}

**"acknowledge** indicates that the **cluster is now aware of this index**

#### Full Example

Now, let's say that we'd like to created the *"game_of_throne"* index. By convention, **all indices should be written in the singular form**.

{% highlight sh %}
$> curl -XPUT "http://localhost:9200/game_of_throne?pretty"
{% endhighlight %}

And the response from the cluster is :

{% highlight json %}
{
    "acknowledge" : true
}
{% endhighlight %}

More options can be passed to the index API. More about it here : [https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html)

### List Indices

#### The Query

You can list all Indices on your cluster this way :

The query type is `GET`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: chartreuse">/_cat/indices?v</span></code></pre></div>

The first part is the **URL on which your Elasticsearch cluster API is available**.

<span style="color: chartreuse">The **\_cat** action is used to print data about the cluster. Here, we cat the **indices** (data about indices)</span>

#### The Response

The server should responds like this, with a table and the following headers :

{% highlight sh %}
health   status   index   pri   rep   docs.count   docs.deleted   store.size   pri.store.size
{% endhighlight %}

The table shows data about indices, such as name, health, number of documents, size of the index, ...

#### Full Example

Let's say we'd like to take a look at the *"game_of_throne"* index we just created.

{% highlight sh %}
$> curl -XPUT "http://localhost:9200/_cat/indices?v"
{% endhighlight %}

And the response is :

{% highlight sh %}
health   status   index          pri   rep   docs.count   docs.deleted   store.size   pri.store.size
green    open     game_of_throne  5     1            0              0        970b              575b
{% endhighlight %}

### Create documents

Here the real fun begins. Now that our cluster is properly set, and contains an index (*"game_of_throne"*), we can take a look at the standards **CRUD** operations.

The first operation is the **creation**. Elasticsearch will stores documents into the shards by this operation. The format is the following :

#### The Query

The query type is `POST`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/index/type</span></code></pre></div>

The first part is the **URL on which your Elasticsearch cluster API is available**.

<span style="color: orange">The second part indicates on which index your document will be stored, and what its type is.</span>

#### The Response

The Elasticsearch cluster will answer, with the following response :

{% highlight json %}
{
    "_index" : "index",
    "_type" : "type",
    "_id" : "id",
    "_version" : 1,
    "created" : true
}
{% endhighlight %}

*\_index* and *\_type* are the ones you specified in the query.

*\_id* is an **ID** automatically set by Elasticsearch. **You can also specify it** if you wish. We'll talk about it deeper later in this article.

*\_version* is the **version of your document**. This is the famous **versioning** I talked about earlier.

#### Full Example

Let's say now we want to add a **Document** which represents Jon Snow.
Its type would be *"character"* and it will stands in the *"game_of_throne"* index.

To perform this operation, we need to use a JSON data file. I provided it in the Vagrant environment, under the `simple_cluster/queries/basics/add_document.json` file.

Its content is the following :

{% highlight json %}
{
  "name": "Jon Snow",
  "age": 14,
  "house": "Stark",
  "gender": "male",
  "biography": "Jon Snow is the bastard son of Eddard Stark, the lord of Winterfell. He is the half-brother of Arya, Sansa, Bran, Rickon and Robb.",
  "tags": [
    "stark",
    "night's watch",
    "you know nothing"
  ]
}
{% endhighlight %}

Given that, the CURL request is the following :

{% highlight sh %}
$>curl –XPOST http://localhost:9200/game_of_throne/character/ -d {"name": "Jon Snow","age": 14,"house": "Stark","gender": "male","biography": "Jon Snow is the bastard son of Eddard Stark, the lord of Winterfell. He is the half-brother of Arya, Sansa, Bran, Rickon and Robb.","tags": ["stark","night's watch","you know nothing"]}
{% endhighlight %}

The response given by the cluster :

{% highlight json %}
{
    "_index" : "game_of_throne",
    "_type" : "character",
    "_id" : "AU0QJ2sJ1MYCa_CVGtD5",
    "_version" : 1,
    "created" : true
}
{% endhighlight %}

You can see here that our document has been inserted in the *"game_of_throne"* index, with the type *"character"*. You can also see that Elasticsearch gave our document an ID which id *AU0QJ2sJ1MYCa_CVGtD5*.
Also, the version of the document has been set to 1 (the first version). Finally, Elasticsearch informed us that he performed the creation.

### Retrieve documents

Well, now that we inserted a document, we'd like to retrieve it. You have to keep in mind that Elasticsearch is working on Apache Lucene, which is a full-text index and search library. Even if Elasticsearch
is designed to perform full-text research, a single document can be retrieved by its **ID**.

#### The Query

So, the second **CRUD** operation is the **Reading**. Elasticsearch is able to retrieve a document, as I said, according to its **ID** :

The query type is `GET`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/index/type/ID</span></code></pre></div>

The first part is the **URL on which your Elasticsearch cluster API is available**.

<span style="color: orange">The second part indicates on which index your document is stored, what its type is, and finally, its **ID**</span>

#### The Response

The Elasticsearch cluster will answer with a response similar to the following: 

{% highlight json %}
{
    "_index" : "index",
    "_type" : "type",
    "_id" : "id",
    "_version" : 1,
    "_exists" : true,
    "_source" : {
        "THE JSON DOCUMENT"
    }
}
{% endhighlight %}

Compared to the previous answer, there is two more fields here : *\_exists* and *\_source*.

*\_exists* is a **boolean** value that informs you if the document defined by the **ID** you gave exists in the given index and type. If so, then the value will be **true**, otherwise it will be **false**.

*\_source* contains the JSON document you requested.

#### Full Example

Let's say that we want to retrieve the previous document ( *Jon Snow*) we stored in the *game_of_throne* index, and which has the *character* type. As a reminder, the ID Elasticsearch gave us is *AU0QJ2sJ1MYCa_CVGtD5*.

{% highlight sh %}
$>curl –XPOST http://localhost:9200/game_of_throne/character/AU0QJ2sJ1MYCa_CVGtD5
{% endhighlight %}

The answer from the cluster is :

{% highlight json %}
{
    "_index" : "game_of_throne",
    "_type" : "character",
    "_id" : "AU0QJ2sJ1MYCa_CVGtD5",
    "_version" : 1,
    "_exists" : true,
    "_source" : {
          "name": "Jon Snow",
          "age": 14,
          "house": "Stark",
          "gender": "male",
          "biography": "Jon Snow is the bastard son of Eddard Stark, the lord of Winterfell. He is the half-brother of Arya, Sansa, Bran, Rickon and Robb.",
          "tags": [
            "stark",
            "night's watch",
            "you know nothing"
          ]
        }
}
{% endhighlight %}

That's it ! You can see that the *_source* field contains our document !

### Update documents

Well. We know how to insert documents, and retrieve them according to their **ID**.

Now, we will see the third **CRUD** operation, the **Update**.

In Elasticsearch, update can be kind of a difficult operation. In deed, there is several "kind" of updates, I would say. The one we're going to see now is the simpliest
one, it is about doing a **partial update**.

If your document contains counters, or fields on which you want to perform some operations, the update operation is a bit more touchy, and we will talk about it later.

Still according to the **ID** of the document, Elasticsearch can retrieve it and update it. The side-effect of this operation will be the incrementation of the version number.

#### The Query

The query type is `POST`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/index/type/ID</span><span style="color: chartreuse">/_update</span></code></pre></div>

The first part is the **URL on which your Elasticsearch cluster API is available**.

<span style="color: orange">The second part indicates on which index your document is stored, what its type is, and its ID</span>

<span style="color: chartreuse">The second part is the name of the action. Here, *\_update* notifies Elasticsearch that we are willing to update an existing document.</span>

To update a part of a document, the format of the JSON data you will provide is the following :

{% highlight json %}
{
    "doc" : {
        "THE UPDATED FIELDS"
    },
    "detect_noop" : true
}
{% endhighlight %}

Here, I purposely included an option called *detect_noop*. This options, if it is set to **true**, will make a diff between the actual version of your document, stored by
Elasticsearch, and the one you're sending. If the diff in null, then Elasticsearch will just drop the request.

#### The Response

The Elasticsearch cluster will answer with the following response :

{% highlight json %}
{
    "_index" : "index",
    "_type" : "type",
    "_id" : "id",
    "_version" : 2
}
{% endhighlight %}

Here, the important change is in the *\_version* field. You can notice that it has been incremented.

#### Full Example

Let's say that we want to update the previous document ( *Jon Snow*) we stored, and change his age. As a reminder, its ID is *AU0QJ2sJ1MYCa_CVGtD5*.

Our JSON will be the following (you can find it in `simple_cluster/queries/basics/update_document.json`).

{% highlight json %}
{
    "doc" : {
        "age" : 20
    }
}
{% endhighlight %}

Then, we can make our request to the cluster :

{% highlight sh %}
$>curl –XPOST http://localhost:9200/game_of_throne/character/AU0QJ2sJ1MYCa_CVGtD5/_update -d {"doc" : {"age" : 20} }
{% endhighlight %}

The response from the Elasticsearch cluster is the following :

{% highlight json %}
{
    "_index" : "game_of_throne",
    "_type" : "character",
    "_id" : "AU0QJ2sJ1MYCa_CVGtD5",
    "_version" : 2
}
{% endhighlight %}

Note that the version has been incremented to **2**.

### Delete documents

The last **CRUD** operation is the **deletion**. Elasticsearch is able to retrieve a document, according to its **ID**, and delete id.

#### The Query

The query type is `DELETE`

<div class="highlight"><pre><code>http://localhost:9200<span style="color: orange">/index/type/ID</span></code></pre></div>

The first part is the **URL on which your Elasticsearch cluster API is available**.

<span style="color: orange">The second part indicates on which index your document is stored, what its type is, and its ID</span>

#### The Response

The Elasticsearch server will answer with the following response :

{% highlight json %}
{
    "_index" : "index",
    "_type" : "type",
    "_id" : "id",
    "_version" : 3,
    "found", true
}
{% endhighlight %}

You can notice here that **the version of the document has been incremented !** That's because the segment thing. Remember : segments are **not updated**, so that the document
is not really removed from it, unless a **segment merge** is processed ; instead, a new version is created.

#### Full Example

Let's say that we want to delete the previous document ( *Jon Snow*) we stored. As a reminder, the **ID** Elasticsearch gave us is *AU0QJ2sJ1MYCa_CVGtD5*

{% highlight sh %}
$>curl –XDELETE http://localhost:9200/game_of_throne/character/AU0QJ2sJ1MYCa_CVGtD5
{% endhighlight %}

The answer from the server is :

{% highlight json %}
{
    "_index" : "game_of_throne",
    "_type" : "character",
    "_id" : "AU0QJ2sJ1MYCa_CVGtD5",
    "_version" : 3,
    "found", true
}
{% endhighlight %}

## Introduction to plugins

The last point I want to talk about in this first article is about the plugins, available with Elasticsearch.
As Elasticsearch provides a REST API interface to communicate with the cluster, it is really easy to develop a bunch of helpful tools.

Today, I will talk about two of the most known and used plugins : Marvel & Head (already installed in the Docker I provided)

### How does plugin work with Elasticsearch ?

Plugins are an important part of Elasticsearch. Natively, Elasticsearch handles plugins. It provides a binary file to install plugins from remote repositories.
To install a plugin, the command line is really simple (but it requires you to have a shell access to the cluster).

Once you're logged on the cluster (for example via SSH), installation of plugins comes that way (assuming Elasticsearch is in the `/usr/share/elasticsearch` directory) :

`$> /usr/share/elasticsearch/bin/plugins -i name_of_the_plugin`

Then, read the documentation of your plugin to learn the usage.

#### Cluster managing : *Head*

*Head* official documentation here : [http://mobz.github.io/elasticsearch-head/](http://mobz.github.io/elasticsearch-head/)
*Head* is a tool designed to help you manage your Elasticsearch cluster, using a web-based interface.
To connect **Head** on our cluster, open your favorite browser, and go `http://127.0.0.1:9200/_plugin/head/`.
On the main page, you can see our three Elasticsearch nodes : *Arya Stark*, *Catelyn Stark*, and *Eddard Stark*.
For each node, you can access related information, and actions (such as poweroff).
On the top of the page, the health of your cluster is displayed. This value is based on several KPIs such as the number of shards, replicas, ...
The top tabs give you access to indices management, and also a graphical way to perform requests.

#### Cluster monitoring : *Marvel*

*Marvel* is an official plugin from Elastic.co, and the documentation is available here : [https://www.elastic.co/products/marvel](https://www.elastic.co/products/marvel)
This plugin is free only for development purpose.
I did not install it on the cluster, but you can do it yourself, by following the instructions I gave you above.
It is based on the ELK (Elasticsearch - Logstach - Kibana) stack, each of these products are from Elastic.co.
*Marvel* provides you statistics about your cluster, KPIs monitoring, and a very powerfull log parser ; moreover, it has a nice interface !

## What's coming next ?

Well, I think that's enough for today. I let you have fun with Elasticsearch, and i'll release the second article in a few weeks.
