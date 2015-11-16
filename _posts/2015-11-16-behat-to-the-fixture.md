---
layout: post
author: guilhem_bourgoin
title: "Behat to the Fixture"
excerpt: "How to use Behat to write Fixtures in Symfony2"
modified: 2015-11-16
tags: [behat, symfony2, fixtures]
comments: true
image:
  feature: behat-to-the-fixture.jpg
  credit: Alban Pommeret
  creditlink: http://reputationvip.io
---

## What is a fixture?

[DoctrineFixturesBundle documentation](http://symfony.com/doc/current/bundles/DoctrineFixturesBundle/index.html):

>Fixtures are used to load a controlled set of data into a database. This data can be used for testing or could be the initial data required for the application to run smoothly. Symfony2 has no built in way that manages fixtures but Doctrine2 has a library to help you write fixtures.

The goal of this article is to give a new method based on Gherkin language and Behat 3 to write and load fixtures on Symfony2.

For further information about Behat test, refer to the following articles: [BDD, Behaviour Driven Development](/bdd-behat-driven-development) 

***

## Current ways to write fixtures on Symfony2

There are two main ways to write Symfony2 fixtures.

Write your entities directly in PHP:

{% highlight php startinline=true %}
class LoadUserAndBookData implements FixtureInterface
{
    public function load(ObjectManager $manager)
    {
         $authorJKR = new Author();
         $authorJKR->setName('JK Rowling');
         $manager->persist($authorJKR);
     
         $authorDB = new Author();
         $authorDB->setName('Dan Brown');
         $manager->persist($authorDB); 
     
         $book1 = new Book();
         $book1->setTitle('Harry Potter');
         $book1->setAuthor($authorJKR); 
         $manager->persist($book1);
     
         $book2 = new Book();
         $book2->setTitle('Da Vinci Code');
         $book2->setAuthor($authorDB); 
         $manager->persist($book2);
     
         $manager->flush();
    }
}
{% endhighlight %}


Or use yml format (with hautelook/alice-bundle):

{% highlight gherkin %}
AppBundle\Entity\Author:
    author1: 
        name: JK Rowling
    author2:
        name: Dan Brown

AppBundle\Entity\Book:
    book1: 
        title: Harry Potter
        author: @author1
    book2:
        title: Da Vinci Code
        author: @author2
{% endhighlight %}


## Fixtures in Gherkin language

Here, I am offering you a third way, based on Gherkin language and interpreted by Behat:

{% highlight gherkin %}
Feature: Load data.

    Scenario: fixture 1
        Given authors:
            | name       |
            | JK Rowling |
            | Dan Brown  |
        Given books:
            | title         | author     |
            | Harry Potter  | JK Rowling |
            | Da Vinci Code | Dan Brown  |

{% endhighlight %}

Gherkin language is more condensed and less verbose than yml format, which makes it more readable. So, even if you are not a developer, you can write it.


## Translate Gherkin language to data

If you already use Behat on your project, "Given" steps should already have been defined in one of your Context.
Example of steps corresponding to fixtures above:

{% highlight php startinline=true %}
/**
 * @Given authors:
 */
public function givenAuthors(TableNode $tableAuthors)
{
    foreach ($tableAuthors as $authorRow) {
        $author = new Author();
        $author->setName($authorRow['name']);
        $this->em->persist($author);
    }
    $this->em->flush();
}

/**
 * @Given books:
 */
public function givenBooks(TableNode $tableBooks)
{
    foreach ($tableBooks as $bookRow) {
        $book = new Book();
        $book->setTitle($bookRow['title']);
        $book->setAuthor($this->findAuthorByName($bookRow['author']));
        $this->em->persist($book);
    }
    $this->em->flush();
}

{% endhighlight %}

## Behat3 settings

Behat test uses test databases, but fixtures have to use dev databases. Create *behat_fixtures.yml* file in the root directory of your project as shown below:

{% highlight gherkin %}
default:
    extensions:
        Behat\Symfony2Extension:
            kernel:
                env: dev
    suites:
        fixtures:
            type: symfony_bundle
            bundle: 'AppBundle'
            paths:
                - src/AppBundle/DataFixtures/
            contexts:
                - AppBundle\Features\Context\FixturesContext
                - ...
{% endhighlight %}

First you have to define the environment that you need: *dev* (default value is *test*):

{% highlight gherkin %}
default:
    extensions:
        Behat\Symfony2Extension:
            kernel:
                env: dev
{% endhighlight %}

Then, specify the folder that holds fixtures files, here *src/AppBundle/DataFixtures/*:

{% highlight gherkin %}
default:
    suites:
        fixtures:
            paths:
                - src/AppBundle/DataFixtures/
{% endhighlight %}

Context class list is the same as Behat test. Just add FixturesContext (see below).


## Manage databases before loading fixtures

{% highlight php startinline=true %}
class FixturesContext implements Context
{
    /** @BeforeSuite */
    public static function before($event)
    {
        $kernel = new AppKernel("dev", true);
        $kernel->boot();
    
        FixturesContext::checkDatabasesHosts($kernel);
    
        $application = new Application($kernel);
        $application->setAutoExit(false);
        FixturesContext::runConsole($application, 'doctrine:schema:drop', ['--force' => true, '--full-database' => true]);
        FixturesContext::runConsole($application, 'doctrine:schema:create');
        $kernel->shutdown();
    }
    
    private static function runConsole($application, $command, $options = [])
    {
        $options['-e'] = 'dev';
        $options['-q'] = null;
        $options = array_merge($options, ['command' => $command]);
        
        return $application->run(new ArrayInput($options));
    }
}

{% endhighlight %}

First, ensure that the database host is *localhost* (on a vagrant for example), in order to avoid clearing wrong databases.
Next, delete database schema, then re-create the schema from doctrine entities. You can also use a migration script like DoctrineMigration.

## Write fixtures

Fixtures format is Gherkin language, as Behat scenarios. Example:

{% highlight gherkin %}
Feature: fixtures library

    Scenario: fixture writers
        Given authors:
            | name             | birth date |
            | JK Rowling       | 1965-07-31 |
            | Dan Brown        |            |
            | J. R. R. Tolkien | 1892-01-03 |

    Scenario: fixture books
        Given literary genres:
            | name            |
            | science fiction |
            | comedy          |
        Given books:
            | title             | author     | literary genres | publication year |
            | Harry Potter      | JK Rowling | science fiction | 1954             |
            | Da Vinci Code     | Dan Brown  |                 | 2003             |
            | Angels and Demons | Dan Brown  |                 | 2000             |
{% endhighlight %}

Put your fixtures files **.feature* on the folder defined in *behat_fixtures.yml* (here *src/AppBundle/DataFixtures/*).
Behat processes files in alphabetical order. If you prefix the name of fixtures with a number, you can control the execution order.

## Load fixtures

To load fixtures, execute the script below in your project root and wait a few seconds!

{% highlight sh %}
bin/behat --config behat_fixtures.yml
{% endhighlight %}


***

## To conclude

There are many benefits to using Behat 3 to load fixtures:

* Fixtures are more readable and easy to write
* If you already use Behat 3, your current steps definitions can be reused
* If you add a column on one of your table, you need to modify only one piece of code to make Behat tests and fixtures evolve
* In your steps definitions, you can easily define default values (example: users password could be "pwd" by default)

For me, the only negative point is that the execution time is greater than classical Symfony2 fixtures.

If you like Behat, you will love writing fixtures with it!
