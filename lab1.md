# Development with Containers

In this lab we are going to see how we can use Java with Quarkus to build and run containers in our local system.

## Lab 1 - Running our first quarkus application

1. Connect to the Fedora 39 system
2. Clone the application and change into the created directory

    ~~~sh
    git clone https://github.com/juazugas/rha-quarkus-library-shop library-shop
    cd library-shop
    ~~~

3. Run the application in dev mode

    ~~~sh
    ./mvnw compile quarkus:dev
    ~~~

4. Check the required database container was created

    ~~~sh
    podman ps

    CONTAINER ID  IMAGE                          COMMAND               CREATED          STATUS          PORTS                   NAMES
    2c2e8ebd9c05  docker.io/library/postgres:14  postgres -c fsync...  2 seconds ago    Up 2 seconds    0.0.0.0:5432->5432/tcp  bold_mahavira
    ~~~

5. Access the container and check the database was initialized by the application

    ~~~sh
    podman exec -ti bold_mahavira psql -U quarkus quarkus

    psql (14.5 (Debian 14.5-1.pgdg110+1))
    Type "help" for help.

    quarkus=# \dt
                List of relations
    Schema |     Name     | Type  |  Owner
    --------+--------------+-------+---------
    public | book         | table | quarkus
    public | book_authors | table | quarkus
    public | ehlo_message | table | quarkus
    (3 rows)

    quarkus=# \q
    ~~~

6. Query and check the application is running

    ~~~sh
    curl -s http://localhost:8080/hello

    Hello from RESTEasy Reactive
    ~~~

    ~~~sh
    curl -s http://localhost:8080/ehlo

    ehlo from version v1 host localhost
    ~~~

    ~~~sh
    curl -s http://localhost:8080/ehlo

    ehlo from PostgreSQL 15.3 on x86_64-redhat-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-18), 64-bit
    ~~~

## Lab 2 - Developing the application

1. Open the Visual Code and open the Folder containing the application project

2. Open the GreetingResource.java (src/main/java) and change the return message to "Hello Red Hat Academy"

    ~~~java
    public String hello() {
        return "Hello Red Hat Academy";
    }
    ~~~

3. Open a terminal and check the application reload the changes

    ~~~sh
    curl -s http://localhost:8080/hello

    Hello Red Hat Academy
    ~~~

4. Fix the test GreetingsResourceTest.java (src/test/java) and launch the test suite

    ~~~java
    @Test
    void testHelloEndpoint() {
        given()
          .when().get("/hello")
          .then()
             .statusCode(200)
             .body(is("Hello Red Hat Academy"));
    ~~~

    ~~~sh
    ./mvnw test

    ...
    [INFO]
    [INFO] Results:
    [INFO]
    [INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
    [INFO]
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    ~~~

5. Generate the application binary and check the distributables

    ~~~sh
    ./mvnw package
    ~~~

    Check the target directory and verify the generated jar and the dependencies


6. (optional) Validate the application code

    ~~~sh
    ./mvnw validate

    ...
    [INFO]
    [INFO] --- checkstyle:3.3.1:check (default) @ library-shop ---
    [INFO] You have 0 Checkstyle violations.
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    ~~~

5. Execute the application using the generated binaries

    ~~~sh
    java -jar target/quarkus-app/quarkus-run.jar
    ~~~


## Lab 3 - Building the container image

- Build container image manually

1. Check the file Containerfile.jvm (src/main/docker)

    ~~~Dockerfile
    FROM registry.access.redhat.com/ubi9/openjdk-17-runtime:1.17-1

    ENV LANGUAGE='en_US:en'


    # We make four distinct layers so if there are application changes the library-shop layers can be re-used
    COPY --chown=185 target/quarkus-app/lib/ /deployments/lib/
    COPY --chown=185 target/quarkus-app/*.jar /deployments/
    COPY --chown=185 target/quarkus-app/app/ /deployments/app/
    COPY --chown=185 target/quarkus-app/quarkus/ /deployments/quarkus/

    EXPOSE 8080
    USER 185
    ENV JAVA_OPTS_APPEND="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
    ENV JAVA_APP_JAR="/deployments/quarkus-run.jar"

    ENTRYPOINT [ "/opt/jboss/container/java/run/run-java.sh" ]
    ~~~

2. Open a terminal and execute the build command in the application directory

    ~~~sh
    podman build -f ./src/main/docker/Containerfile.jvm -t rha/library-shop:1.0.0 .
    ~~~

3. Inspect the created image

    ~~~sh
    podman inspect rha/library-shop:1.0.0

    [
     {
          "Id": "e80167037960e12a56cba8f5d6d41a794d2815e37123c86dd177f6bdd56557de",
          "Digest": "sha256:be2ce6355483cf775f74ba73982976d02c3088da90de2d5dc5bf5e1548cf8176",
          "RepoTags": [
               "localhost/rha/library-shop:1.0.0",
               "localhost/rha/library-shop-docker:1.0.0"
          ],
    ...
    ~~~

4. Run the generated container image

    ~~~sh
    podman run --rm -it -e DATABASE_HOST=alumno -p 8080:8080 rha/library-shop:1.0.0

    INFO exec -a "java" java -XX:MaxRAMPercentage=80.0 -XX:+UseParallelGC -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=20 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:+ExitOnOutOfMemoryError -Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager -cp "." -jar /deployments/quarkus-run.jar
    INFO running in /deployments
    __  ____  __  _____   ___  __ ____  ______
    --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
    -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
    --\___\_\____/_/ |_/_/|_/_/|_|\____/___/
    2023-12-04 16:39:39,239 INFO  [io.quarkus] (main) library-shop 1.0.0 on JVM (powered by Quarkus 3.6.0) started in 2.739s. Listening on: http://0.0.0.0:8080
    2023-12-04 16:39:39,241 INFO  [io.quarkus] (main) Profile prod activated.
    ~~~

5. Verify the application runs correct

    ~~~sh
    curl -s http://localhost:8080/ehlo

    ehlo from version v1 host localhost
    ~~~

- Build the container image using Quarkus Jib Extension

6. Open a terminal, change into the application directory and run the build command

    ~~~sh
    ./mvnw package -Pjib

    ...
    [INFO] [io.quarkus.container.image.jib.deployment.JibProcessor] Container entrypoint set to [java, -Djava.util.logging.manager=org.jboss.logmanager.LogManager, -jar, quarkus-run.jar]
    [INFO] [io.quarkus.container.image.jib.deployment.JibProcessor] Created container image rha/library-shop-jib:1.0.0 (sha256:811d30992a7dccf41c88b5ec00800ece3945372650bc2311c987c9af4867f8d6)

    [INFO] [io.quarkus.deployment.QuarkusAugmentor] Quarkus augmentation completed in 9947ms
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    ~~~

7. Run the generated container image and verify the application runs correctly and check the differences between the previous container process.

    ~~~sh
    podman run --rm -it -e DATABASE_HOST=alumno -p 8080:8080 rha/library-shop-jib:1.0.0
    ~~~

- Build the container image using Quarkus Docker Extension

8. Open a terminal, change into the application directory and run the build command

    ~~~sh
    ./mvnw package -Pdocker

    ...
    [INFO] [io.quarkus.deployment.util.ExecUtil] COMMIT rha/library-shop-docker:1.0.0
    [INFO] [io.quarkus.deployment.util.ExecUtil] --> 2eb0ac51a204
    [INFO] [io.quarkus.deployment.util.ExecUtil] Successfully tagged localhost/rha/library-shop-docker:1.0.0
    [INFO] [io.quarkus.deployment.util.ExecUtil] 2eb0ac51a2042742c46897d822bcf8d4c065688ad107933db64375dd411dfb61
    [INFO] [io.quarkus.container.image.docker.deployment.DockerProcessor] Built container image rha/library-shop-docker:1.0.0

    [INFO] [io.quarkus.deployment.QuarkusAugmentor] Quarkus augmentation completed in 5802ms
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    ~~~

9. Run the generated container image and check the application runs correctly

    ~~~sh
    podman run --rm -it -e DATABASE_HOST=alumno -p 8080:8080 rha/library-shop-docker:1.0.0
    ~~~

10. Compare the generated image with the generated manually running the podman command

    ~~~sh
    podman images | grep -i library-shop

    rha/library-shop-docker:1.0.0      2eb0ac51a204  9 minutes ago   406 MB
    rha/library-shop-jib:1.0.0         2866d5084033  16 minutes ago  406 MB
    rha/library-shop:1.0.0             2eb0ac51a204  22 minutes ago  406 MB
    ~~~

## Lab 4 - Building the container image for the native application

1. Open a terminal and execute the command to compile to native

    NOTE: it may take some minutes to compile, add `-Dquarkus.native.builder-image.pull=never` to avoid pulling the mandrel container image again

    ~~~sh
    ./mvnw package -Dnative -Dquarkus.native.container-build=true -Dquarkus.native.container-runtime=podman
    ~~~

    Check the command used to generated the native binary ...

    ~~~sh
    ...
    [INFO] [io.quarkus.deployment.pkg.steps.NativeImageBuildStep] Running Quarkus native-image plugin on MANDREL 23.1.1.0 JDK 21.0.1+12-LTS
    [INFO] [io.quarkus.deployment.pkg.steps.NativeImageBuildRunner] podman run --env LANG=C --rm --user 1000:1000 --userns=keep-id ...
    ~~~

    For detailed information and explanations on the build output, visit:
    https://github.com/oracle/graal/blob/master/docs/reference-manual/native-image/BuildOutput.md


2. Verify the generated binary and run the application

    ~~~sh
    ls -l target/*-runner

    -rwxr-xr-x. 1 alumno alumno 92462592 Dec  5 07:24 target/library-shop-1.0.0-runner
    ~~~

    Run the integration test suite with the native application

    ~~~sh
    ./mvnw test-compile failsafe:integration-test -Dnative

    [INFO]
    [INFO] Results:
    [INFO]
    [INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
    [INFO]
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    ~~~

    ~~~sh
    target/library-shop-1.0.0-runner

    __  ____  __  _____   ___  __ ____  ______
    --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
    -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
    --\___\_\____/_/ |_/_/|_/_/|_|\____/___/
    2023-12-05 07:53:40,252 INFO  [io.quarkus] (main) library-shop 1.0.0 native (powered by Quarkus 3.6.0) started in 0.047s. Listening on: http://0.0.0.0:8080
    2023-12-05 07:53:40,253 INFO  [io.quarkus] (main) Profile prod activated.
    2023-12-05 07:53:40,253 INFO  [io.quarkus] (main) Installed features: [agroal, cdi, hibernate-orm, hibernate-orm-panache, hibernate-orm-rest-data-panache, jdbc-postgresql, narayana-jta, resteasy-reactive, resteasy-reactive-jackson, resteasy-reactive-links, smallrye-context-propagation, smallrye-health, smallrye-openapi, swagger-ui, vertx]
    ~~~

3. Verify the application is running correctly

    ~~~sh
    curl -s http://localhost:8080/ehlo

    ehlo from version v1 host localhost
    ~~~

    And check that connects to the database ...

    ~~~sh
    curl -s http://localhost:8080/library/

    [{"id":1,"title":"The Hitchhiker's Guide to the Galaxy", ...}]
    ~~~

4. Finally, build the container image for the native application.

- Manually

5. Check the file Containerfile.native (src/main/docker)

    ~~~Dockerfile
    FROM registry.access.redhat.com/ubi8/ubi-minimal:8.9-1029

    WORKDIR /work/
    RUN chown 1001 /work \
        && chmod "g+rwX" /work \
        && chown 1001:root /work
    COPY --chown=1001:root target/*-runner /work/application

    EXPOSE 8080
    USER 1001

    ENTRYPOINT ["./application", "-Dquarkus.http.host=0.0.0.0"]
    ~~~

6. Run the podman command to build the native image

    ~~~sh
    podman build -f ./src/main/docker/Containerfile.native -t rha/library-shop-native:1.0.0 .

    COMMIT rha/library-shop-native:1.0.0
    --> 3eb5839295ed
    Successfully tagged localhost/rha/library-shop-native:1.0.0
    ~~~

7. Run the container image and verify the app is running correctly

    ~~~sh
    podman run --rm -it -e DATABASE_HOST=alumno -p 8080:8080 rha/library-shop-native:1.0.0

    __  ____  __  _____   ___  __ ____  ______
    --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
    -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
    --\___\_\____/_/ |_/_/|_/_/|_|\____/___/
    2023-12-05 07:01:46,428 INFO  [io.quarkus] (main) library-shop 1.0.0 native (powered by Quarkus 3.6.0) started in 0.042s. Listening on: http://0.0.0.0:8080
    2023-12-05 07:01:46,428 INFO  [io.quarkus] (main) Profile prod activated.
    ...
    ~~~

    Add a book to the shop

    ~~~sh
    curl -i -X POST http://localhost:8080/library -H "Content-type: application/json" -d '{"title":"The Difference Engine","year":1990,"isbn":"0-575-04762-3","price":12.0,"authors":[{"name":"William Gibson"},{"name":"Bruce Sterling"}]}'

    HTTP/1.1 200 OK
    content-length: 153
    Content-Type: application/json;charset=UTF-8

    {"id":10,"title":"The Difference Engine","year":1990,"isbn":"0-575-04762-3","price":12.0,"authors":[{"name":"William Gibson"},{"name":"Bruce Sterling"}]}
    ~~~

    Check the book was created successfully

    ~~~sh
    curl -i -s http://localhost:8080/library/10

    HTTP/1.1 200 OK
    content-length: 153
    Content-Type: application/json;charset=UTF-8

    {"id":10,"title":"The Difference Engine","year":1990,"isbn":"0-575-04762-3","price":12.0,"authors":[{"name":"William Gibson"},{"name":"Bruce Sterling"}]}
    ~~~

    More information can be found in the [Quarkus Guide - Building a Native Executable](https://quarkus.io/guides/building-native-image) (https://quarkus.io/guides/building-native-image)

- Build the image via the Quarkus Extensions

8. (optional) Run the maven command to build the native image and the

    ~~~sh
    ./mvnw verify -Dnative -Pdocker -Dquarkus.container-image.name=library-shop-docker-native -Dquarkus.native.reuse-existing=true

    [INFO] [io.quarkus.deployment.util.ExecUtil] COMMIT rha/library-shop-docker-native:1.0.0
    [INFO] [io.quarkus.deployment.util.ExecUtil] --> 0877361cdb46
    [INFO] [io.quarkus.deployment.util.ExecUtil] Successfully tagged localhost/rha/library-shop-docker-native:1.0.0
    [INFO] [io.quarkus.deployment.util.ExecUtil] 0877361cdb4610839031d82e42482647fe8761774aff3f2f67832b906414f76d
    [INFO] [io.quarkus.container.image.docker.deployment.DockerProcessor] Built container image rha/library-shop-docker-native:1.0.0
    ~~~

    Via Jib Container Extension

    ~~~sh
    ./mvnw package -Dnative -Pjib -Dquarkus.container-image.name=library-shop-jib-native -Dquarkus.native.reuse-existing=true

    ...
    [WARNING] [io.quarkus.container.image.jib.deployment.JibProcessor] Base image 'quay.io/quarkus/quarkus-micro-image:2.0' does not use a specific image digest - build may not be reproducible
    [INFO] [io.quarkus.container.image.jib.deployment.JibProcessor] Using base image with digest: sha256:77a3524aca02a5875979ecfe06bb283af2960ed922264ceadd97865077e7b087
    [INFO] [io.quarkus.container.image.jib.deployment.JibProcessor] Container entrypoint set to [./application]
    [INFO] [io.quarkus.container.image.jib.deployment.JibProcessor] Created container image rha/library-shop-jib-native:1.0.0 (sha256:909d34b44768def9b940a771a4048c454c3a6457ebe139b9b098809996359c3a)
    ~~~

9. (optional) Run the container images and check the application is running correctly

    Container image generated with Docker Extension

    ~~~sh
    podman run --rm -it -e DATABASE_HOST=alumno -p 8080:8080 rha/library-shop-docker-native:1.0.0

    __  ____  __  _____   ___  __ ____  ______
    --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
    -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
    --\___\_\____/_/ |_/_/|_/_/|_|\____/___/
    2023-12-05 07:35:36,743 INFO  [io.quarkus] (main) library-shop 1.0.0 native (powered by Quarkus 3.6.0) started in 0.041s. Listening on: http://0.0.0.0:8080
    2023-12-05 07:35:36,743 INFO  [io.quarkus] (main) Profile prod activated.
    ~~~

    Container image generated with Jib Extension

    ~~~sh
    podman run --rm -it -e DATABASE_HOST=alumno -p 8080:8080 rha/library-shop-jib-native:1.0.0

    __  ____  __  _____   ___  __ ____  ______
    --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
    -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
    --\___\_\____/_/ |_/_/|_/_/|_|\____/___/
    2023-12-05 07:37:52,731 INFO  [io.quarkus] (main) library-shop 1.0.0 native (powered by Quarkus 3.6.0) started in 0.041s. Listening on: http://0.0.0.0:8080
    2023-12-05 07:37:52,731 INFO  [io.quarkus] (main) Profile prod activated.
    ~~~

10. Compare the generated container images

    ~~~sh
    podman images | grep -i library-shop

    rha/library-shop-jib-native        45cf9fe1a674  17 minutes ago  123 MB
    rha/library-shop-docker-native     7f01978dfc26  19 minutes ago  187 MB
    rha/library-shop-native            3eb5839295ed  42 minutes ago  187 MB
    rha/library-shop-docker            2eb0ac51a204  15 hours ago    406 MB
    rha/library-shop                   2eb0ac51a204  15 hours ago    406 MB
    rha/library-shop-jib               2866d5084033  15 hours ago    406 MB
    ~~~