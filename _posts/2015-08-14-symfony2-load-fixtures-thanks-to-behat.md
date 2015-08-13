---
layout: post
author: guilhem_bourgoin
title: "Symfony2 - Load fixtures thanks to Behat"
excerpt: "How to use Behat to write Fixtures in Symfony2"
modified: 2015-08-14
tags: [behat, symfony2, fixtures]
comments: true
image:
  feature: elastic-is-coming-ban.jpg
  credit: Alban Pommeret
  creditlink: http://reputationvip.io
---

## What is a fixture ?

[DoctrineFixturesBundle documentation](http://symfony.com/doc/current/bundles/DoctrineFixturesBundle/index.html) :

>Fixtures are used to load a controlled set of data into a database. This data can be used for testing or could be the initial data required for the application to run smoothly. Symfony2 has no built in way to manage fixtures but Doctrine2 has a library to help you write fixtures.

The goal of this article is to propose a new method based on Gherkin language and behat 3 to write and load fixtures on Symfony2.

***

## Current ways to write fixtures

There are two main ways to write symfony2 fixtures.

Write your entities directly in PHP :

{% highlight php startinline=true %}
class LoadUserAndBookData implements FixtureInterface
{
    public function load(ObjectManager $manager)
    {
         $userJames = new User();
         $userJames->setName('james');
         $userJames->setPassword('pwd');
         $manager->persist($userJames);
     
         $userJohn = new User();
         $userJohn->setName('john');
         $userJohn->setPassword('pwd'); 
         $manager->persist($userJohn); 
     
         $book1 = new Book();
         $book1->setTitle('Lord of the ring');
         $book1->setOwner($userJames); 
         $manager->persist($book1);
     
         $book2 = new Book();
         $book2->setTitle('Harry Potter 1');
         $book2->setOwner($userJohn); 
         $manager->persist($book2);
     
         $manager->flush();
    }
}
{% endhighlight %}


Or use yml format (with hautelook/alice-bundle) :

{% highlight gherkin %}
AppBundle\Entity\User:
    user1: 
        name: james
        password: pdw
    user2:
        name: john
        password: pdw

AppBundle\Entity\Book:
    book1: 
        title: Lord of the ring
        owner: @user1
    book2:
        title: Harry Potter 1
        owner: @user2
{% endhighlight %}


## Fixtures in Gherkin language

I propose here a third way, based on Gherkin language and interpreted by behat :

{% highlight gherkin %}
Feature: Load data.

    Scenario: fixture 1
        Given users :
            | name  | password |
            | james | pwd      |
            | john  | pwd      |
        Given books :
            | title            | user  |
            | Lord of the ring | james |
            | Harry Potter 1   | john  |

{% endhighlight %}

Gherkin language is more readable than yml format. Even if you are not a developer, you can write it.


## Translate Gherkin language to data

If you are already using behat on your projet, "Given" steps definitions are certainly already defined in one of your Context.
Example of steps corresponding to fixtures above :

{% highlight php startinline=true %}
/**
 * @Given users :
 */
public function users(TableNode $tableUsers)
{
    foreach ($tableUsers as $userRow) {
        $user = new User();
        $user->setName($userRow['name']);
        $user->setPassword($userRow['password']);
        $this->em->persist($user);
    }
    $this->em->flush();
}

/**
 * @Given books :
 */
public function books(TableNode $tableBooks)
{
    foreach ($tableBooks as $bookRow) {
        $book = new Book();
        $book->setTitle($bookRow['title']);
        $book->setOwner($this->findUserByName($bookRow['owner']));
        $this->em->persist($book);
    }
    $this->em->flush();
}

{% endhighlight %}

## Behat3 settings

Behat test use test databases, but fixtures have to use dev database. Create *behat_fixtures.yml* file in the root of your project as below :

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
            contexts :
                - AppBundle\Features\Context\FixturesContext
                - ...
{% endhighlight %}

First you have to define the environment who have to be used : *dev* (default value is *test*) :

{% highlight gherkin %}
default:
    extensions:
        Behat\Symfony2Extension:
            kernel:
                env: dev
{% endhighlight %}

Next, specify the folder with fixtures files,  here *src/AppBundle/DataFixtures/* :

{% highlight gherkin %}
default:
    suites:
        fixtures:
            paths:
                - src/AppBundle/DataFixtures/
{% endhighlight %}

Context class list is the same as behat test. Just add FixturesContext (see below).


## Manage data bases before to load fixtures

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
        FixturesContext::runConsole($application, "doctrine:schema:drop", ["--force" => true, "--full-database" => true]);
        FixturesContext::runConsole($application, "doctrine:schema:create");
        $kernel->shutdown();
    }
    
    private static function runConsole($application, $command, $options = array())
    {
        $options["-e"] = "dev";
        $options["-q"] = null;
        $options = array_merge($options, array('command' => $command));
        return $application->run(new ArrayInput($options));
    }
}

{% endhighlight %}

First, check database host is *localhost* (on a vagrant for example), to avoid to clear wrong databases.
Next, delete database schema, then re-create the schema from doctrine entities. You can also use a migration script like DoctrineMigration.

## Write fixtures

Fixtures format is Gherkin language, as behat scenarios. Example :

{% highlight gherkin %}
Feature: fixtures library

    Scenario: fixture writers
        Given writers :
            | name             | birth date |
            | JK Rowling       | 1965-07-31 |
            | Dan Brown        |            |
            | J. R. R. Tolkien | 1892-01-03 |

    Scenario: fixture books
        Given literary genres :
            | name            |
            | science fiction |
            | comedy          |
        Given books :
            | title                 | author     | literary genres | publication year |
            | The Lord of the Rings | JK Rowling | science fiction | 1954             |
            | Da Vinci Code         | Dan Brown  |                 | 2003             |
            | Angels and Demons     | Dan Brown  |                 | 2000             |
{% endhighlight %}

Put your fixtures files **.feature* on the folder defined in *behat_fixtures.yml* (here *src/AppBundle/DataFixtures/*).
Behat process files in alphabetical order. If you prefix the name of fixtures with a number, you can control the execution order.

## Load fixtures

To load fixtures, execute the script below in your root's project, and wait some seconds !

{% highlight sh %}
bin/behat --config behat_fixtures.yml
{% endhighlight %}


***

## To conclude

There are many benefits to use behat 3 to load fixtures :

* Fixtures are more readable and easy to write
* If you already use behat 3, your current steps definitions can be reused
* If you add a column on one of your table, you have to modify only one piece of code to make evolve behat tests and fixtures
* In your steps definitions, you can easily defined defaults values (example : users password could be "pwd" by default)

The only negative point is that the execution time is greater than classical Symfony2 fixtures.

If you like Behat, you will love write fixtures with it !
