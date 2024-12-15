# Development with Containers

In this lab we are going to see how we can use Java with [Quarkus](https://quarkus.io/) to build and run containers in our local system.

## Lab 1 - Running our first quarkus application

1. Connect to the Fedora 41 system.

2. Open the `Visual Studio Code` application.

3. On the top menu, click `Terminal` -> `New Terminal`. You will see a new terminal has been opened at the bottom.

4. In this terminal, clone the application and change into the created directory:

    ~~~sh
    git clone https://github.com/juazugas/rha-quarkus-library-shop.git  ~/library-shop
    cd ~/library-shop/
    ~~~

5. Open the folder containing the application in Visual Studio Code. In the VSCode Menu click on `File` -> `Open Folder` -> `Carpeta personal` -> `library-shop` -> `Abrir`.

6. Run the application in dev mode from the terminal (check step 3 to open a new terminal):

    ~~~sh
    ./mvnw compile quarkus:dev
    ~~~

7. Eventually, you will get this in your screen:

    > :bulb: **Note:** At this point the application is running.

    ~~~console
    2024-12-13 12:00:14,288 INFO  [io.quarkus] (Quarkus Main Thread) library-shop 1.0.0 on JVM (powered by Quarkus 3.17.2) started in 20.200s. Listening on: http://localhost:8080
    2024-12-13 12:00:14,296 INFO  [io.quarkus] (Quarkus Main Thread) Profile dev activated. Live Coding activated.
    2024-12-13 12:00:14,297 INFO  [io.quarkus] (Quarkus Main Thread) Installed features: [agroal, cdi, hibernate-orm, hibernate-orm-panache, hibernate-orm-rest-data-panache, jdbc-postgresql, narayana-jta, rest, rest-jackson, rest-links, smallrye-context-propagation, smallrye-health, smallrye-openapi, swagger-ui, vertx]
    ~~~

8. The terminal we previously opened is now running our application, we will open a new terminal to run the following commands. On the top menu, click `Terminal` -> `New Terminal`.

9. Check the required database container was created:

    ~~~sh
    podman ps | grep postgres
    ~~~

    ~~~output
    6da04462bde3  docker.io/library/postgres:17         postgres -c fsync...  2 seconds ago  Up 3 seconds  0.0.0.0:5432->5432/tcp   loving_mclaren
    ~~~

10. Access the container and check the database was initialized by the application:

    ~~~sh
    POSTGRES_CONTAINER=$(podman ps | grep postgres | awk '{print $1}')
    podman exec -ti ${POSTGRES_CONTAINER}  psql -U quarkus -d quarkus -c '\dt'
    ~~~

    ~~~output
            List of relations
     Schema |     Name     | Type  |  Owner
    --------+--------------+-------+---------
     public | book         | table | quarkus
     public | book_authors | table | quarkus
     public | ehlo_message | table | quarkus
    (3 rows)
    ~~~

11. Query and check the application is running:

    ~~~sh
    curl -s http://localhost:8080/hello
    ~~~

    ~~~output
    Hello from RESTEasy Reactive
    ~~~

    ~~~sh
    curl -s http://localhost:8080/ehlo
    ~~~

    ~~~output
    ehlo from version v1 host localhost
    ~~~

    ~~~sh
    curl -s http://localhost:8080/ehlo/database
    ~~~

    ~~~output
    ehlo from PostgreSQL 17.2 (Debian 17.2-1.pgdg120+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
    ~~~

## Lab 2 - Developing the application

1. Open the `GreetingResource.java` (`src/main/java`), change the return message to `Hello Red Hat Academy` and save the changes.

    ~~~java
    public String hello() {
        return "Hello Red Hat Academy";
    }
    ~~~

2. In the terminal, check that the application has the new changes (It's been rebuilt and restarted):

    ~~~sh
    curl -s http://localhost:8080/hello
    ~~~

    ~~~output
    Hello Red Hat Academy
    ~~~

3. Fix the test `GreetingsResourceTest.java` (`src/test/java`), save the changes and launch the test suite.

    ~~~java
    @Test
    void testHelloEndpoint() {
        given()
          .when().get("/hello")
          .then()
             .statusCode(200)
             .body(is("Hello Red Hat Academy"));
    }
    ~~~

    ~~~sh
    ./mvnw test
    ~~~

    ~~~output
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

4. Generate the application binary and check the distributables:

    ~~~sh
    ./mvnw package
    ~~~

    Check the target directory and verify the generated jar and the dependencies.

5. (optional) Validate the application code:

    ~~~sh
    ./mvnw validate
    ~~~

    ~~~output
    ...
    [INFO]
    [INFO] --- checkstyle:3.3.1:check (default) @ library-shop ---
    [INFO] You have 0 Checkstyle violations.
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    ~~~

6. Pause the execution of the application in dev mode. Go to the first terminal you opened and press the key `q` to exit.

7. Execute the application using the generated binaries and podman for running the database:

    ~~~sh
    podman network create rhademo --ignore
    podman run --net rhademo --rm -d --name pg-library-shop -e POSTGRES_USER=quarkus -e POSTGRES_PASSWORD=quarkus -e POSTGRESQL_DATABASE=quarkus -p 5432:5432 -v $PWD/src/main/database:/docker-entrypoint-initdb.d:ro,z docker.io/library/postgres:17
    java -jar target/quarkus-app/quarkus-run.jar
    ~~~

8. You can query the application now from another terminal:

    ~~~sh
    curl -s http://localhost:8080/hello
    ~~~

    ~~~output
    Hello Red Hat Academy
    ~~~

9. Before moving to the next lab, stop the application. Go to the terminal where you executed the `java` command and press `Ctrl+C`. You should see the following output:

    ~~~output
    2024-12-13 15:11:57,415 INFO  [io.quarkus] (main) library-shop stopped in 0.036s
    ~~~

10. Want more?

    > :bulb: **Note:** Complete the [bonus lab](lab-bonus.md).

## Lab 3 - Building the container image

### Build container image manually

1. Check the file `Containerfile.jvm` (`src/main/docker`).

2. In the terminal execute the build command in the application directory:

    ~~~sh
    cd ~/library-shop/
    podman build -f src/main/docker/Containerfile.jvm -t rha/library-shop:1.0.0 .
    ~~~

3. Inspect the created image:

   > :bulb: **Note:** We can see the different layers, commands used, etc.

    ~~~sh
    podman inspect rha/library-shop:1.0.0
    ~~~

    ~~~output
    [
     {
          "Id": "e80167037960e12a56cba8f5d6d41a794d2815e37123c86dd177f6bdd56557de",
          "Digest": "sha256:be2ce6355483cf775f74ba73982976d02c3088da90de2d5dc5bf5e1548cf8176",
          "RepoTags": [
               "localhost/rha/library-shop:1.0.0"
          ],
    ...
    ~~~

4. We can run the application in a container now:

    ~~~sh
    podman run --net rhademo --name library-shop-app --rm -d -e DATABASE_HOST=pg-library-shop -p 8080:8080 rha/library-shop:1.0.0
    ~~~

    ~~~sh
    podman logs library-shop-app
    ~~~

    ~~~output
    INFO exec -a "java" java -XX:MaxRAMPercentage=80.0 -XX:+UseParallelGC -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=20 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:+ExitOnOutOfMemoryError -Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager -cp "." -jar /deployments/quarkus-run.jar
    INFO running in /deployments
    __  ____  __  _____   ___  __ ____  ______
    --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
    -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
    --\___\_\____/_/ |_/_/|_/_/|_|\____/___/
    2024-12-13 15:32:24,215 INFO  [io.quarkus] (main) library-shop 1.0.0 on JVM (powered by Quarkus 3.17.2) started in 1.989s. Listening on: http://0.0.0.0:8080
    2024-12-13 15:32:24,218 INFO  [io.quarkus] (main) Profile prod activated.
    2024-12-13 15:32:24,219 INFO  [io.quarkus] (main) Installed features: [agroal, cdi, hibernate-orm, hibernate-orm-panache, hibernate-orm-rest-data-panache, jdbc-postgresql, narayana-jta, rest, rest-jackson, rest-links, smallrye-context-propagation, smallrye-health, smallrye-openapi, swagger-ui, vertx]
    ~~~

5. Verify the application runs correctly:

    ~~~sh
    curl -s http://localhost:8080/ehlo
    ~~~

    ~~~output
    ehlo from version v1 host localhost
    ~~~

6. Stop the container with `Ctrl + c` on the terminal:

    ~~~sh
    podman stop library-shop-app
    ~~~

### Build the container image using Quarkus Jib Extension

1. In one of the terminals, change into the application directory and run the build command:

    ~~~sh
    cd ~/library-shop/
    ./mvnw package -Pjib
    ~~~

    ~~~output
    ...
    [INFO] [io.quarkus.container.image.jib.deployment.JibProcessor] Container entrypoint set to [/opt/jboss/container/java/run/run-java.sh]
    [INFO] [io.quarkus.container.image.jib.deployment.JibProcessor] Created container image rha/library-shop-jib:1.0.0 (sha256:5da55cd92fbf03c7e3f39200d92e4dff6e3c896383afdf4f6c9e33d91e34061c)

    [INFO] [io.quarkus.deployment.QuarkusAugmentor] Quarkus augmentation completed in 16426ms
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    ~~~

2. Run the generated container image and verify the application runs correctly and check the differences between the previous container process.

    ~~~sh
    podman run --net rhademo --name library-shop-app --rm -d -e DATABASE_HOST=pg-library-shop -p 8080:8080 rha/library-shop-jib:1.0.0
    ~~~

3. Verify the application runs correctly:

    ~~~sh
    curl -s http://localhost:8080/ehlo
    ~~~

    ~~~output
    ehlo from version v1 host localhost
    ~~~

4. Stop the container:

    ~~~sh
    podman stop library-shop-app
    ~~~

### Build the container image using Quarkus Docker Extension

1. In one of the terminals, change into the application directory and run the build command:

    ~~~sh
    cd ~/library-shop/
    ./mvnw package -Pdocker
    ~~~

    ~~~output
    ...
    [INFO] [io.quarkus.deployment.util.ExecUtil] COMMIT rha/library-shop-docker:1.0.0
    [INFO] [io.quarkus.deployment.util.ExecUtil] --> 8041fd1c34a1
    [INFO] [io.quarkus.deployment.util.ExecUtil] Successfully tagged localhost/rha/library-shop-docker:1.0.0
    [INFO] [io.quarkus.deployment.util.ExecUtil] 8041fd1c34a19c00ea783bca1cc5a68cf0cb971ea84033c9f936d845596eaa6a
    [INFO] [io.quarkus.container.image.docker.deployment.DockerProcessor] Built container image rha/library-shop-docker:1.0.0

    [INFO] [io.quarkus.deployment.QuarkusAugmentor] Quarkus augmentation completed in 7240ms
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    ~~~

2. Run the generated container image and check the application runs correctly:

    ~~~sh
    podman run --net rhademo --name library-shop-app --rm -d -e DATABASE_HOST=pg-library-shop -p 8080:8080 rha/library-shop-docker:1.0.0
    ~~~

3. Verify the application runs correctly:

    ~~~sh
    curl -s http://localhost:8080/ehlo
    ~~~

    ~~~output
    ehlo from version v1 host localhost
    ~~~

4. Stop the container:

    ~~~sh
    podman stop library-shop-app
    ~~~

5. Compare the generated image with the generated manually running the podman command:

    ~~~sh
    podman images | grep -i library-shop
    ~~~

    ~~~output
    localhost/rha/library-shop-docker                   1.0.0       5b0dd26b635c  2 minutes ago      406 MB
    localhost/rha/library-shop-jib                      1.0.0       b15f3e3b6ab0  5 minutes ago      406 MB
    localhost/rha/library-shop                          1.0.0       5c8c31912a20  35 minutes ago      406 MB
    ~~~

## Lab 4 - Building the container image for the native application

1. In one of the terminals, execute the command to compile to native:

    > :bulb: **Note:**
    >
    > It may take some minutes to compile, we added`-Dquarkus.native.builder-image.pull=never` to avoid pulling the mandrel container image again.
    >
    > For detailed information and explanations on the build output, visit [the docs](https://github.com/oracle/graal/blob/master/docs/reference-manual/native-image/BuildOutput.md).

    ~~~sh
    cd ~/library-shop
    ./mvnw package -Dnative -Dquarkus.native.builder-image.pull=never -Dquarkus.native.container-build=true -Dquarkus.native.container-runtime=podman
    ~~~

    > :bulb: **Note:** This step may take up to 5 minutes to finish.

    ~~~output
    [INFO] [io.quarkus.deployment.pkg.steps.NativeImageBuildStep] Running Quarkus native-image plugin on MANDREL 23.1.5.0 JDK 21.0.5+11-LTS
    [INFO] [io.quarkus.deployment.pkg.steps.NativeImageBuildRunner] podman run --env LANG=C --rm --user 1000:1000 --userns=keep-id -v /home/fedora/library-shop/target/library-shop-1.0.0-native-image-source-jar:/project:z --name build-native-ShcBl quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21 -J-DCoordinatorEnvironmentBean.transactionStatusManagerEnable=false -J-Dsun.nio.ch.maxUpdateArraySize=100 -J-Djava.util.logging.manager=org.jboss.logmanager.LogManager -J-Duser.language=en -J-Duser.country=US -J-Dlogging.initial-configurator.min-level=500 -J-Dvertx.logger-delegate-factory-class-name=io.quarkus.vertx.core.runtime.VertxLogDelegateFactory -J-Dvertx.disableDnsResolver=true -J-Dio.netty.leakDetection.level=DISABLED -J-Dio.netty.allocator.maxOrder=3 -H:+UnlockExperimentalVMOptions -H:IncludeLocales=en-US -H:-UnlockExperimentalVMOptions -J-Dfile.encoding=UTF-8 --features=io.quarkus.caffeine.runtime.graal.CacheConstructorsFeature,io.quarkus.jdbc.postgresql.runtime.graal.SQLXMLFeature,io.quarkus.runner.Feature,io.quarkus.runtime.graal.DisableLoggingFeature,io.quarkus.hibernate.orm.runtime.graal.DisableLoggingFeature,org.hibernate.graalvm.internal.GraalVMStaticFeature -J--add-exports=java.security.jgss/sun.security.krb5=ALL-UNNAMED -J--add-exports=java.security.jgss/sun.security.jgss=ALL-UNNAMED -J--add-opens=java.base/java.text=ALL-UNNAMED -J--add-opens=java.base/java.io=ALL-UNNAMED -J--add-opens=java.base/java.lang.invoke=ALL-UNNAMED -J--add-opens=java.base/java.util=ALL-UNNAMED -H:+UnlockExperimentalVMOptions -H:BuildOutputJSONFile=library-shop-1.0.0-runner-build-output-stats.json -H:-UnlockExperimentalVMOptions -H:+UnlockExperimentalVMOptions -H:+GenerateBuildArtifactsFile -H:-UnlockExperimentalVMOptions --strict-image-heap -H:+UnlockExperimentalVMOptions -H:+AllowFoldMethods -H:-UnlockExperimentalVMOptions -J-Djava.awt.headless=true --no-fallback --link-at-build-time -H:+UnlockExperimentalVMOptions -H:+ReportExceptionStackTraces -H:-UnlockExperimentalVMOptions -H:-AddAllCharsets --enable-url-protocols=http,https --enable-monitoring=heapdump -H:+UnlockExperimentalVMOptions -H:-UseServiceLoaderFeature -H:-UnlockExperimentalVMOptions -J--add-exports=org.graalvm.nativeimage/org.graalvm.nativeimage.impl=ALL-UNNAMED --exclude-config io\.netty\.netty-codec /META-INF/native-image/io\.netty/netty-codec/generated/handlers/reflect-config\.json --exclude-config io\.netty\.netty-handler /META-INF/native-image/io\.netty/netty-handler/generated/handlers/reflect-config\.json library-shop-1.0.0-runner -jar library-shop-1.0.0-runner.jar
    ...
    [3/8] Building universe...
    ...
    Produced artifacts:
    /project/build-artifacts.json (build_info)
    /project/library-shop-1.0.0-runner (executable)
    /project/library-shop-1.0.0-runner-build-output-stats.json (build_info)
    ========================================================================================================================
    Finished generating 'library-shop-1.0.0-runner' in 5m 6s.
    ...
    [INFO] [io.quarkus.deployment.QuarkusAugmentor] Quarkus augmentation completed in 340903ms
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    [INFO] Total time:  05:59 min
    [INFO] Finished at: 2024-12-13T15:53:57Z
    [INFO] ------------------------------------------------------------------------
    ~~~

2. Verify the generated binary:

    ~~~sh
    ls -l target/*-runner
    ~~~

    ~~~output
    -rwxr-xr-x. 1 alumno alumno 97485696 Dec  5 07:24 target/library-shop-1.0.0-runner
    ~~~

3. Run the integration test suite with the native application:

    ~~~sh
    ./mvnw test-compile failsafe:integration-test -Dnative
    ~~~

    ~~~output
    [INFO]
    [INFO] Results:
    [INFO]
    [INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
    [INFO]
    [INFO] ------------------------------------------------------------------------
    [INFO] BUILD SUCCESS
    [INFO] ------------------------------------------------------------------------
    ~~~

4. Run the native application:

    ~~~sh
    target/library-shop-1.0.0-runner
    ~~~

    ~~~console
    __  ____  __  _____   ___  __ ____  ______
    --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
    -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
    --\___\_\____/_/ |_/_/|_/_/|_|\____/___/
    2024-12-13 15:59:19,744 INFO  [io.quarkus] (main) library-shop 1.0.0 native (powered by Quarkus 3.17.2) started in 0.046s. Listening on: http://0.0.0.0:8080
    2024-12-13 15:59:19,744 INFO  [io.quarkus] (main) Profile prod activated.
    2024-12-13 15:59:19,744 INFO  [io.quarkus] (main) Installed features: [agroal, cdi, hibernate-orm, hibernate-orm-panache, hibernate-orm-rest-data-panache, jdbc-postgresql, narayana-jta, rest, rest-jackson, rest-links, smallrye-context-propagation, smallrye-health, smallrye-openapi, swagger-ui, vertx]
    ~~~

5. In a different terminal, verify the application is running correctly:

    ~~~sh
    curl -s http://localhost:8080/ehlo
    ~~~

    ~~~output
    ehlo from version v1 host localhost
    ~~~

    ~~~sh
    curl -s http://localhost:8080/library/
    ~~~

    ~~~output
    [{"id":1,"title":"The Hitchhiker's Guide to the Galaxy", ...}]
    ~~~

6. Stop the application. In the terminal where it's running press `Ctrl + C`.

In the next section we will build the application in native binary format.

### Building the native application container image manually

1. Check the file `Containerfile.native` (`src/main/docker`)

2. Run the podman command to build the native image

    ~~~sh
    cd ~/library-shop/
    podman build -f src/main/docker/Containerfile.native -t rha/library-shop-native:1.0.0 .
    ~~~

    ~~~output
    ...
    STEP 7/7: ENTRYPOINT ["./application", "-Dquarkus.http.host=0.0.0.0"]
    COMMIT rha/library-shop-native:1.0.0
    --> dec4939a705f
    Successfully tagged localhost/rha/library-shop-native:1.0.0
    dec4939a705f3f07a70c0ff1f8ae08489997f040a995471192ece25e2df3e19b
    ~~~

3. Run the container image and verify the app is running correctly:

    ~~~sh
    podman run --net rhademo --name library-shop-app --rm -d -e DATABASE_HOST=pg-library-shop -p 8080:8080 rha/library-shop-native:1.0.0 && \
    podman logs library-shop-app
    ~~~

    ~~~output
    __  ____  __  _____   ___  __ ____  ______
    --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
    -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
    --\___\_\____/_/ |_/_/|_/_/|_|\____/___/
    2024-12-13 16:07:33,260 INFO  [io.quarkus] (main) library-shop 1.0.0 native (powered by Quarkus 3.17.2) started in 0.048s. Listening on: http://0.0.0.0:8080
    2024-12-13 16:07:33,260 INFO  [io.quarkus] (main) Profile prod activated.
    2024-12-13 16:07:33,260 INFO  [io.quarkus] (main) Installed features: [agroal, cdi, hibernate-orm, hibernate-orm-panache, hibernate-orm-rest-data-panache, jdbc-postgresql, narayana-jta, rest, rest-jackson, rest-links, smallrye-context-propagation, smallrye-health, smallrye-openapi, swagger-ui, vertx]
    ~~~

4. With the app running we can add a book to the library service. In a different terminal run the following command:

    ~~~sh
    curl -i -X POST http://localhost:8080/library -H "Content-type: application/json" -d '{"title":"The Difference Engine","year":1990,"isbn":"0-575-04762-3","price":12.0,"authors":[{"name":"William Gibson"},{"name":"Bruce Sterling"}]}'
    ~~~

    ~~~output
    HTTP/1.1 200 OK
    content-length: 153
    Content-Type: application/json;charset=UTF-8

    {"id":10,"title":"The Difference Engine","year":1990,"isbn":"0-575-04762-3","price":12.0,"authors":[{"name":"William Gibson"},{"name":"Bruce Sterling"}]}
    ~~~

5. We can check that the book was created:

    ~~~sh
    curl -i -s http://localhost:8080/library/10
    ~~~

    ~~~output
    HTTP/1.1 200 OK
    content-length: 153
    Content-Type: application/json;charset=UTF-8

    {"id":10,"title":"The Difference Engine","year":1990,"isbn":"0-575-04762-3","price":12.0,"authors":[{"name":"William Gibson"},{"name":"Bruce Sterling"}]}
    ~~~

6. Finally, we stop the application:

    ~~~sh
    podman stop library-shop-app
    ~~~

More information around building a native executable can be found in the [official Quarkus docs](https://quarkus.io/guides/building-native-image).

### Build the image via the Quarkus Extensions

1. We can leverage the Quarkus extensions to get the container image built:

    ~~~sh
    cd ~/library-shop
    ./mvnw verify -Dnative -Pdocker -Dquarkus.container-image.name=library-shop-docker-native -Dquarkus.native.reuse-existing=true
    ~~~

    ~~~output
    [INFO] [io.quarkus.deployment.util.ExecUtil] COMMIT rha/library-shop-docker-native:1.0.0
    [INFO] [io.quarkus.deployment.util.ExecUtil] --> 1354f4b0a7f0
    [INFO] [io.quarkus.deployment.util.ExecUtil] Successfully tagged localhost/rha/library-shop-docker-native:1.0.0
    [INFO] [io.quarkus.deployment.util.ExecUtil] Successfully tagged localhost/rha/library-shop-native:1.0.0
    [INFO] [io.quarkus.deployment.util.ExecUtil] 1354f4b0a7f03dd3061a1df33dd62f80803672de3d90ac1d4cf308a31a9b6415
    [INFO] [io.quarkus.container.image.docker.deployment.DockerProcessor] Built container image rha/library-shop-docker-native:1.0.0
    ~~~

### Build the image via the Jib Container Extension

1. Jib also allows to get the container image built:

    ~~~sh
    cd ~/library-shop
    ./mvnw package -Dnative -Pjib -Dquarkus.container-image.name=library-shop-jib-native -Dquarkus.native.reuse-existing=true
    ~~~

    ~~~output
    ...
    [WARNING] [io.quarkus.container.image.jib.deployment.JibProcessor] Base image 'quay.io/quarkus/quarkus-micro-image:2.0' does not use a specific image digest - build may not be reproducible
    [INFO] [io.quarkus.container.image.jib.deployment.JibProcessor] Using base image with digest: sha256:0c20f8846bacc99824f376e8567d5a98434d1a34996dd47c3b3421bbea21fa40
    [INFO] [io.quarkus.container.image.jib.deployment.JibProcessor] Container entrypoint set to [./application]
    [INFO] [io.quarkus.container.image.jib.deployment.JibProcessor] Created container image rha/library-shop-jib-native:1.0.0 (sha256:4ebd636c42c2b70ce39a12dc508c5ed64eeee8e4e955a8b08e0a915727031b89)
    ~~~

### Comparing the different container images in size

During this lab we have built several container images, we will see how the one using the native binaries have a smaller footprint than the others.

1. Check the comparison between the sizes of the container images.

    ~~~sh
    podman images | grep -i library-shop
    ~~~

    ~~~output
    localhost/rha/library-shop-jib-native               1.0.0           346c620e26de  42 seconds ago  128 MB
    localhost/rha/library-shop-docker-native            1.0.0           1354f4b0a7f0  7 minutes ago   203 MB
    localhost/rha/library-shop-native                   1.0.0           1354f4b0a7f0  7 minutes ago   203 MB
    localhost/rha/library-shop-docker                   1.0.0           8041fd1c34a1  32 minutes ago  421 MB
    localhost/rha/library-shop-jib                      1.0.0           da33481d0656  36 minutes ago  422 MB
    localhost/rha/library-shop                          1.0.0           a88470feeb9f  56 minutes ago  421 MB
    ~~~

As we can see, the natives ones are ~200MB smaller. This will lead to less storage utilization and also to faster startup times since the image will be pulled faster.


### Cleaning up

1. Remove created containers:

    ~~~sh
    podman stop pg-library-shop
    podman network rm rhademo
    ~~~
