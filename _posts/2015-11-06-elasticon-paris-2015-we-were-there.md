---
layout: post
title: "Elasticon Paris 2015: We were there!"
author: quentin_fayet
modified: 2015-11-09
excerpt: "Reputation VIP were present at the Elasticon Paris 2015, here is what we thought about it!"
tags: [elastic, elasticsearch, paris, conference, kibana, elk, logstash]
comments: true
image:
  feature: elasticon.jpg
  credit: Alban Pommeret
  creditlink: http://reputationvip.io
---

On November 5th, in Paris, was held the [Elastic{ON}](https://www.elastic.co/elasticon) 2015, the conference organised
by Elastic to allow Elastic users to keep in touch. In the Bois de Boulogne, at the Pavillon d'Armenoville,
Elastic set up a stage where different figures of the company came to talk about the future of Elastic's products.

# In the morning: "Product Deep Dive and Roadmap"

The festivities began with this very first conference, held in the late morning, for Elastic staff to talk about
the future of their main products: Elasticsearch, Logstash and Kibana (the famous ELK stack).

First, as an introduction, the master of ceremony introduced a number: 15,035. This, in dollar, is the amount of money
that will be given to a French association, ["Docteur Souris"](www.docteursouris.fr) (computer mouse doctor, Ed.). In
a few words, this association helps the children in hospital to keep in touch with their family, and to carry on
studying. Also, "Docteur Souris" was looking for Elasticsearch experts to work as volunteers on the projects.

Right after, the creator and CTO of Elastic himself, Shay Banon, got on the stage, to introduce us the Elastic{ON} Paris
2015. He decided to tell us how, when his wife decided to become a Chef, he had the idea to create a cooking
application. His idea was to simply have a search bar, where his wife could type the name of a dish, or an
ingredient, and get detailed information about it. At that time, the few available APIs where low-level,
and so he decided to build an abstraction layer on top of it. Elasticsearch was born. Fun facts, when he released the
first version of Elasticsearch (still in development), Shay Banon decided to tag it as the version 0.4, instead of
0.1, to give credit to his product.

And so came some more numbers. 35,000 is the total number of users who are part of the Elastic community. Elastic
has nearly 120 user groups, spread around the world's biggest cities. All projects of the ELK stacks put together
count more than 32,000 commits! Until now, Elasticsearch has been downloaded more than 35 million times!

Then began the list of the biggest organization and companies that are using Elastic products. Wikimedia foundation
(Wikipedia) is having a transition to run under Elasticsearch. Also, Mozilla is using the ELK stack on their
security tool, named as MozDef. NASA also uses the ELK stack to collect and analyze data from martian rovers.

Finally, Shay Banon told us about a funny fact, his first customer on Elastic's IRC channel, Clinton Gormley. As Shay
was dreaming of his first customer, he imagined amazing projects would use "sexy" language in Elasticsearch, came along
Clinton, working on a project about funerals, with Perl. As the time goes, Clinton became a priceless member
of Elasticsearch community, and nowadays, he works for Elastic.

And so, the next member of Elastic's staff to be on stage was Clinton Gormley, here to tell us about Elasticsearch new
features.

First, about resiliency, Elasticsearch 2.0 has much more faster recovery times (in case of temporary disconnection, for
example). A new feature, known as "durable writes" also appeared, ensuring that each node of the cluster has written
the document on the disk before returning "OK" to the client.

Elastic engineers also improved the global performances of the different operations available on the cluster. For
example, when calling the "state" feature (which formerly responded with a complete document that summarizes the whole
state of the cluster), a diff between the former state and the current state of the cluster is returned to the client,
which is much lighter than returning the whole document. Also, an important feature, multiple compression algorithms are
available, allowing the user to choose between a good compression rate, and a fast compression algorithm. About the
queries, the filters have been merged into it, becoming part of the query clauses. The cluster is now automatically
handling priority on indexing and searching operations.

When it comes to enhance the analytics features, a lot of improvements have been made. A bunch of mathematics features
have been created, such as time-series aggregations, derivative pipeline aggregations. The pipeline aggregation allows
users to aggregate results of previous aggregations! Moreover, the new prediction feature, allows to perform anomaly
detection.

Next on stage, Adrien G., french engineer at Elasticsearch, came to speak about these famous pipeline aggregations.
It allows to perform derivative calculation, cumulative sums, and some more. Adrien gave us an example with a dataset
from the NASA, concerning the trip of the famous probe "Voyager 1". First, aggregating data about its position gave us a
linear chart on which we can see that the probe is linearly drawing away from Earth; that suggests us the speed of the
probe should be constant. To check that, Adrien used a derivative aggregation to calculate the time derivative of the
position (the time derivative of the position gives us the speed). The resulting chart is a bit different, showing that,
in fact, the speed is not constant; by two times, the probe is strongly decelerating. With another pipeline
aggregation, we were able to determine that these two strong losses of speed correspond to the date the probe was
crossing Saturn.

# In the afternoon: Use cases

During the afternoon, several big companies came to share their use experience with Elastic stack. I will talk about
two of these talks, that I found particularly interesting.

First of them, Jean-pierre P. and Zied B. from Orange, came to tell us the usage they have of Kibana to visualize
the data of their search engine. Zied created a new scoring system to rank pages on the search engine, according
to their URL. Based on the URL, the scoring algorithm is able to determine the quality of the page, and is even able
to determine whether the URL has been spammed or not! Their talk was extremely interesting in that they told us about
the process they went through with Docker, to maximise the performances of the search engine. One of the tricks they
gave us is that, to retrieve a lot of documents from Elasticsearch, they use two different queries: A first one to get
the IDs of the documents they are interested in, and a second one, based on these IDs, to retrieve the documents.

The second talk was from Vladislav P., working at ERDF ("Electricité Réseau Distribution France", the company that
manages the electricity network in France, Ed.). They are using the ELK stack to merge and monitor the logs coming from
around 9,000 servers. Their database contains more than 1 billion documents, resulting in only 290Go of data, thanks to
the compression algorithm. Their ingesting rate is 8,000 logs per second! To parse these logs, they are using Grok.

Some other speakers, from Natixis and PSA ("PSA Peugeot Citroën", french automobile manufacturer, Ed.), came to talk
about their usage of Elasticsearch, but I won't talk about it, or this article might become really long.
