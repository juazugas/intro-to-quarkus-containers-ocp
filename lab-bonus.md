# Test-Driven Development (TDD) with Quarkus

This lab continues where we left in [lab 1](lab1.md).
We are going to learn how to use Quarkus continuous testing mode to develop our application using Test-Driven Development (TDD).

## A last minute call from the Product Owner

Simon, the Product Owner, has just called you and asked for a new feature to be implemented in the application.

Simon responds to the clear stereotype of a Product Owner: he is always changing his mind and asking for new features at the last minute.
However, he is also very meticulous and is very clear about the specifications and requirements for the new features.

In this case, Simon has asked you to improve the greeting message to include the name of the person being greeted.

In addition, he wants to receive a special greeting when the name is "Simon" since he is also a very egocentric person.

The following are the requirements for the new feature:
- The endpoint is exposed in the path `/hello/{name}` for the `GET` HTTP method.
- The endpoint returns a `200` status code.
- The response `Content-Type` header is of type `text/plain`.
- The default greeting response is `Hello ${name}!` where `${name}` is the name of the person being greeted.
- If the name is "Simon", the response is `Hello Simon! You are the best!`.
- If the name is empty, the response is `Hello World!` (just like before).

## Implementing the new feature

Let's now implement the new feature using Test-Driven Development (TDD).

### Starting Quarkus in continuous testing mode

The first step is to start Quarkus in continuous testing mode.

On the top menu, click `Terminal` -> `New Terminal`. You will see a new terminal has been opened at the bottom.
Type the following command to start Quarkus in continuous testing mode:

~~~sh
./mvnw quarkus:test
~~~

After a few seconds, you will see the following message:

~~~output
__  ____  __  _____   ___  __ ____  ______
 --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
 -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
--\___\_\____/_/ |_/_/|_/_/|_|\____/___/
2024-12-15 08:13:31,754 INFO  [io.qua.test] (main) Quarkus continuous testing mode started
...
--
All 1 test is passing (0 skipped), 1 test was run in 4520ms. Tests completed at 08:13:36.
Press [r] to re-run, [:] for the terminal, [h] for more options>
~~~

### Implementing the path and status code requirements

Let's start by opening the `GreetingResourceTest.java` (`src/test/java`) class.

Add the following test method to the class:

~~~java
    @Test
    void namedGreetingReturnsOK() {
        given()
          .when().get("/hello/name")
          .then().statusCode(200);
    }
~~~

Save the file, and you will see the test being executed in the terminal.

Since we haven't implemented the endpoint yet, the test will fail with a 404 status code:

~~~output
2024-12-15 08:18:00,209 ERROR [io.qua.test] (Test runner thread) >>>>>>>>>>>>>>>>>>>> Summary: <<<<<<<<<<<<<<<<<<<<
org.acme.GreetingResourceTest#namedGreetingReturnsOK(GreetingResourceTest.java:25) GreetingResourceTest#namedGreetingReturnsOK() 1 expectation failed.
Expected status code <200> but was <404>. [Error Occurred After Shutdown]
2024-12-15 08:18:00,210 ERROR [io.qua.test] (Test runner thread) >>>>>>>>>>>>>>>>>>>> 1 TEST FAILED <<<<<<<<<<<<<<<<<<<< [Error Occurred After Shutdown]
--
1 test failed (1 passing, 0 skipped), 2 tests were run in 886ms. Tests completed at 08:18:00 due to changes to GreetingResourceTest.class.
Press [r] to re-run, [:] for the terminal, [h] for more options>
~~~

Let's now proceed to the implementation by opening the `GreetingResource.java` (`src/main/java`) class.

Add the following method to the class:

~~~java
    @GET
    @Path("/{name}")
    public String helloName(@PathParam("name") String name) {
        return "";
    }
~~~

Save the file, and you will see the test being executed in the terminal.

Since we have now implemented the first requirements, the test will now pass:

~~~output
2024-12-15 08:24:33,786 INFO  [io.qua.test] (Test runner thread) All tests are now passing
--
All 2 tests are passing (0 skipped), 2 tests were run in 550ms. Tests completed at 08:24:33 due to changes to GreetingResource.class.
Press [r] to re-run, [:] for the terminal, [h] for more options>
~~~

### Implementing the response content type requirements

Let's now add a test to check the response `Content-Type` header.

Add the following test method to the `GreetingResourceTest.java` class:

~~~java
    @Test
    void namedGreetingReturnsTextPlain() {
        given()
          .when().get("/hello/name")
          .then().contentType("text/plain");
    }
~~~

Once you save the file, you will see the test being executed in the terminal.
Since Quarkus is smart enough to infer the content type from the method return type, the test will pass:

~~~output
All 3 tests are passing (0 skipped), 3 tests were run in 541ms. Tests completed at 17:18:55 due to changes to GreetingResourceTest.class.
~~~

### Implementing the default greeting response requirement

Let's now add a test to check the default greeting response content.

Add the following test method to the `GreetingResourceTest.java` class:

~~~java
    @Test
    void namedGreetingReturnsHelloName() {
        given()
          .when().get("/hello/name")
          .then().body(is("Hello name!"));
    }
~~~

Naturally, the test will fail since we haven't implemented the greeting message yet:

~~~output
org.acme.GreetingResourceTest#namedGreetingReturnsHelloName(GreetingResourceTest.java:38) GreetingResourceTest#namedGreetingReturnsHelloName() 1 expectation failed.
--
1 test failed (3 passing, 0 skipped), 4 tests were run in 566ms. Tests completed at 17:25:58 due to changes to GreetingResourceTest.class.
~~~

Let's now proceed to the implementation by replacing the content of the `helloName` method in the `GreetingResource.java` class.

~~~java
    @GET
    @Path("/{name}")
    public String helloName(@PathParam("name") String name) {
        return "Hello " + name + "!";
    }
~~~

Save the file, and you will see the test being executed in the terminal.
This time, the test will pass:

~~~output
2024-12-15 17:27:43,550 INFO  [io.qua.test] (Test runner thread) All tests are now passing
--
All 4 tests are passing (0 skipped), 4 tests were run in 528ms. Tests completed at 17:27:43 due to changes to GreetingResource.class.
~~~

### Implementing the special greeting for Simon

Let's now finish the new feature by adding a test to check the special greeting for Simon.

Add the following test method to the `GreetingResourceTest.java` class:

~~~java
    @Test
    void namedGreetingReturnsHelloSimonYouAreTheBest() {
        given()
          .when().get("/hello/Simon")
          .then().body(is("Hello Simon! You are the best!"));
    }
~~~

As usual the test is failing, let's improve the implementation by replacing the content of the `helloName` method in the `GreetingResource.java` class.

~~~java
    @GET
    @Path("/{name}")
    public String helloName(@PathParam("name") String name) {
        if ("Simon".equals(name)) {
            return "Hello Simon! You are the best!";
        }
        return "Hello " + name + "!";
    }
~~~

Boom! All the tests are now passing:

~~~output
2024-12-15 17:29:37,927 INFO  [io.qua.test] (Test runner thread) All tests are now passing
--
All 5 tests are passing (0 skipped), 5 tests were run in 564ms. Tests completed at 17:29:37 due to changes to GreetingResource.class.
~~~

## A job well done

Congratulations, you have successfully implemented the new feature using TDD!

More importantly, the new feature has been implemented with confidence and with a safety net of automated tests.

The following table contains the requirements and the test case that verifies them:

| Requirement                                                                                                | Test case                        |
|------------------------------------------------------------------------------------------------------------|----------------------------------|
| The endpoint is exposed in the path `/hello/{name}` for the `GET` HTTP method.                             | `namedGreetingReturnsOK`         |
| The endpoint returns a `200` status code.                                                                  | `namedGreetingReturnsOK`         |
| The response `Content-Type` header is of type `text/plain`.                                                | `namedGreetingReturnsTextPlain`  |
| The default greeting response is `Hello ${name}!` where `${name}` is the name of the person being greeted. | `namedGreetingReturnsHelloName`  |
| If the name is "Simon", the response is `Hello Simon! You are the best!`.                                  | `namedGreetingReturnsHelloSimon` |
| If the name is empty, the response is `Hello World!`.                                                      | `testHelloEndpoint`              |
