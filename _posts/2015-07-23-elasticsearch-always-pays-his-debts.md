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
