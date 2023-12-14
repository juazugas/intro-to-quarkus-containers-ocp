# Deploy the Library Shop Application in OpenShift

In this lab we are going to see how we can use Java with Quarkus to build and run containers in our local system.

## Lab 1 - Deploy *as a Developer* the Quarkus application

1. Connect to the Fedora 39 system.

2. You should already have the `Visual Studio Code` application opened, if not, go ahead an open it.

3. Make sure you have the `library-shop` project opened, if not, go head and open it by going to the VSCode Menu and click on `File` -> `Open Folder` -> `Carpeta personal` -> `library-shop` -> `Abrir`.

4. Make sure you have a terminal opened, if not, go ahead and open it by going to the top menu, click `Terminal` -> `New Terminal`. You will see a new terminal has been opened at the bottom.

5. Make sure application binaries are generated:

    ~~~sh
    cd ~/library-shop/
    ./mvnw package
    ~~~

6. Login into OpenShift:

    1. Access the [OpenShift Console URL](https://red.ht/ieselgrao
    2. Login using the credentials shared during the session).
    3. If you get a prompt for a console tour press `Skip Tour`.
    4. Click on your username in the top right corner and click `Copy login command`.
    5. In the next screen you may need to login again, once logged in, press `Display Token`.
    6. Copy the command under `Log in with this token`. i.e: `oc login --token=sha256~... --server=https://api.rha.example.com:6443`.
    7. Paste the command in the terminal.

7. Create a development namespace in OpenShift:

    > **NOTE**: Change the username in the command below with the username assigned to you.

    ~~~sh
    export STUDENT=student<your_student_number>
    oc new-project $STUDENT-dev
    ~~~

    ~~~output
    Now using project "studentX-dev" on server...
    ~~~

8. Deploy the database:

    1. Create the secret with the DDL

        ~~~sh
        oc apply -f https://github.com/juazugas/intro-to-quarkus-containers-ocp/raw/main/demo2-assets/openshift/dev/database.ddl.yaml
        ~~~

    2. Apply the resources for the deployment

        ~~~sh
        oc apply -f https://github.com/juazugas/intro-to-quarkus-containers-ocp/raw/main/demo2-assets/openshift/dev/database.deployment.yaml
        ~~~

9. Launch the build for the application in OpenShift

    ~~~sh
    ./mvnw oc:build
    ~~~

    ~~~output
    ...
    [INFO] oc: Build library-shop-s2i-1 in status Complete
    [INFO] oc: Found tag on ImageStream library-shop tag: sha256:60da633a...
    [INFO] oc: ImageStream library-shop written to .../library-shop/target/library-shop-is.yml
    ~~~

    1. Check the generated elements

        ~~~sh
        oc status
        ~~~

        ~~~output
        bc/library-shop-s2i source builds uploaded code on quay.io/jkube/jkube-java:0.0.20
        -> istag/library-shop:1.0.0
        build #1 succeeded 38 seconds ago
        ~~~

        ~~~sh
        oc get pods -l openshift.io/build.name=library-shop-s2i-1
        ~~~

        ~~~output
        NAME                       READY   STATUS      RESTARTS   AGE
        library-shop-s2i-1-build   0/1     Completed   0          11m
        ~~~

10. Deploy the application:

    ~~~sh
    ./mvnw oc:resource oc:apply
    ~~~

    ~~~output
    [INFO] --- oc:1.15.0:apply (default-cli) @ library-shop ---
    [INFO] oc: OpenShift platform detected
    [INFO] oc: Using OpenShift at https://...:6443/ in namespace null with manifest target/classes/META-INF/jkube/openshift.yml
    [INFO] oc: Creating a Secret in student1--dev namespace with name library-shop from openshift.yml
    [INFO] oc: Created Secret: target/jkube/applyJson/student1--dev/secret-library-shop.json
    [INFO] oc: Creating a Service in student1--dev namespace with name library-shop from openshift.yml
    [INFO] oc: Created Service: target/jkube/applyJson/student1--dev/service-library-shop.json
    [INFO] oc: Creating a ConfigMap in student1--dev namespace with name library-shop from openshift.yml
    [INFO] oc: Created ConfigMap: target/jkube/applyJson/student1--dev/configmap-library-shop.json
    [INFO] oc: Creating a Deployment in student1--dev namespace with name library-shop from openshift.yml
    [INFO] oc: Created Deployment: target/jkube/applyJson/student1--dev/deployment-library-shop.json
    [INFO] oc: Creating Route student1--dev:library-shop host: null
    [INFO] oc: HINT: Use the command `oc get pods -w` to watch your pods start up
    ~~~

    1. Watch the pods:

        ~~~sh
        oc get pods -w
        ~~~

        ~~~output
        NAME                            READY   STATUS      RESTARTS   AGE
        library-db-69f74cb64c-snvf6     1/1     Running     0          22m
        library-shop-5cfffb9db8-phlrx   1/1     Running     0          6m23s
        library-shop-s2i-1-build        0/1     Completed   0          21m
        ~~~

    2. Type `Ctrl+C` to exit from the watch.

11. Check the application is working correctly

    1. Get the generated route host

        ~~~sh
        APP_ROUTE=$(oc get route library-shop --template='{{ .spec.host }}')
        ~~~

    2. Request the application data

        ~~~sh
        curl -k -s https://${APP_ROUTE}/ehlo
        ~~~

        ~~~output
        ehlo from version v1 host library-shop-xxx..
        ~~~

        ~~~sh
        curl -k -s https://${APP_ROUTE}/ehlo/database
        ~~~

        ~~~output
        ehlo from PostgreSQL 15.3 on x86_64-redhat-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-18), 64-bit
        ~~~

        ~~~sh
        curl -k -s https://${APP_ROUTE}/hello
        ~~~

        ~~~output
        Hello from RESTEasy Reactive
        ~~~

        ~~~sh
        curl -k -s https://${APP_ROUTE}/library
        ~~~

        ~~~output
        [{"id":1,"title":"The Hitchhiker's Guide to the Galaxy","year":1979,"isbn":"0-330-25864-8","price":10.0,"authors":[{"name":"Douglas Adams"}]},{"id":2,"title":"Snow Crash","year":1992,"isbn":"0-593-59973-X","price":10.0,"authors":[{"name":"Neal Stephenson"}]},{"id":3,"title":"Digital Fortress","year":1998,"isbn":"0-312-18087-X","price":10.0,"authors":[{"name":"Dan Brown"}]}
        ~~~

## Lab 2 - Deploy *in production* the Quarkus application

1. Access the [Git Server](https://gogs-git-rha.apps.rha.mavazque.sysdeseng.com/) we use for production in your browser and login with the credentials shared during the session.

2. Click on `library-shop` in the right section, under `Your repositories`.

3. Keep this repository opened since we will be using it later on.

4. Back in the terminal, change to the production namespace:

    ~~~sh
    oc project $STUDENT
    ~~~

    ~~~output
    Now using project "studentX" on server ...
    ~~~

5. Inspect the OpenShift Pipeline resource:

    ~~~sh
    oc get pipeline --show-labels
    ~~~

    ~~~output
    NAME                    AGE   LABELS
    library-shop-pipeline   35m   app=library-shop-pipelines,group=rhacademy
    ~~~

    Check the OpenShift console for a visual representation of the pipeline

    1. Access the [console url](https://red.ht/ieselgrao) from your browser.
    2. Make sure the left menu top option is set to `Developer` and click `Pipelines` in this same menu.
    3. Click on the `library-shop-pipeline` Pipeline.
    4. Explore the pipeline details

6. Execute the pipeline:

    1. Via CLI

        ~~~sh
        tkn pipeline start library-shop-pipeline \
            -w name=shared-workspace,volumeClaimTemplateFile=https://github.com/juazugas/intro-to-quarkus-containers-ocp/raw/main/demo2-assets/openshift/prod/pipeline/library-shop-source.pvc.yaml \
            --prefix-name=library-shop-build- \
            --serviceaccount=pipeline \
            -p deployment-name=library-shop \
            -p git-url=https://gogs-git-rha.apps.rha.mavazque.sysdeseng.com/$STUDENT/library-shop.git \
            -p backend-image=image-registry.openshift-image-registry.svc:5000/$STUDENT/library-shop:1.0.0 \
            -l group=rhacademy,app=library-shop \
            --use-param-defaults
        ~~~

7. Check the running pipeline in the OpenShift WebUI under `Pipelines` -> `PipelinesRuns`. You can also follow the pipeline progress using the `tkn` CLI.

8. In this section we are going to make a change into our repository, and we will see how the pipeline gets executed automatically.

    1. Access your git repository in the [Git Server](https://gogs-git-rha.apps.rha.mavazque.sysdeseng.com/).
    2. Click on `README.md`.
    3. Once the file is opened, click on the pencil icon in the right corner.
    4. Make some changes and click on `Commit changes`.
    5. Go back to the Pipelineruns screen and you will see the Pipeline running.
