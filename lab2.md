# Deploy the Library Shop Application in OpenShift

In this lab we are going to see how we can use Java with Quarkus to build and run containers in our local system.

## Lab 1 - Deploy &nbsp; *as a Developer* &nbsp; the Quarkus application

1. Connect to the Fedora 39 system
2. Clone the application and change into the created directory

3. Generate the application binaries (only if demo1 was not done)

    For the JVM binaries run the command:

    ~~~sh
    ./mvnw package
    ~~~

    (optional) For the native image run the command:

    ~~~sh
    ./mvnw package -Dnative -Dquarkus.native.container-build=true -Dquarkus.native.container-runtime=podman
    ~~~

4. Login into OpenShift

    1. Access the OpenShift Console URL
    2. Access the "User menu" and open "Copy login command" option
    3. Display and copy the login command with the token
    4. Paste the command on a terminal

    ~~~output
    You have access to the following projects and can switch between them with 'oc project <projectname>':

    Using project "".
    ~~~

5. Create the "dev" project

    ~~~sh
    oc new-project alumno1--dev
    ~~~

    ~~~output
    Now using project "alumno1--dev" on server "https://api....:6443".
    ~~~

    or switch to the project if already exists

    ~~~sh
    oc project alumno1--dev
    ~~~

    ~~~output
    Already on project "alumno1--dev" on server "https://api....:6443".
    ~~~

6. (optional) Deploy the database

    Create the secret with the DDL

    ~~~sh
    oc apply -f https://github.com/juazugas/intro-to-quarkus-containers-ocp/raw/main/demo2-assets/openshift/dev/database.ddl.yaml
    ~~~

    Apply the resources for the deployment

    ~~~sh
    oc apply -f https://github.com/juazugas/intro-to-quarkus-containers-ocp/raw/main/demo2-assets/openshift/dev/database.deployment.yaml
    ~~~

7. Launch the build for the application in OpenShift

    ~~~sh
    ./mvnw oc:build
    ~~~

    ~~~output
    ...
    [INFO] oc: Build library-shop-s2i-1 in status Complete
    [INFO] oc: Found tag on ImageStream library-shop tag: sha256:60da633a...
    [INFO] oc: ImageStream library-shop written to .../library-shop/target/library-shop-is.yml
    ~~~

    Check the generated elements

    ~~~sh
    oc status
    ~~~

    ~~~output
    In project alumno1--dev on server https://...:6443

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

8. Deploy the application

    ~~~sh
    ./mvnw oc:resource oc:apply
    ~~~

    ~~~output
    [INFO] --- oc:1.15.0:apply (default-cli) @ library-shop ---
    [INFO] oc: OpenShift platform detected
    [INFO] oc: Using OpenShift at https://...:6443/ in namespace null with manifest target/classes/META-INF/jkube/openshift.yml
    [INFO] oc: Creating a Secret in alumno1--dev namespace with name library-shop from openshift.yml
    [INFO] oc: Created Secret: target/jkube/applyJson/alumno1--dev/secret-library-shop.json
    [INFO] oc: Creating a Service in alumno1--dev namespace with name library-shop from openshift.yml
    [INFO] oc: Created Service: target/jkube/applyJson/alumno1--dev/service-library-shop.json
    [INFO] oc: Creating a ConfigMap in alumno1--dev namespace with name library-shop from openshift.yml
    [INFO] oc: Created ConfigMap: target/jkube/applyJson/alumno1--dev/configmap-library-shop.json
    [INFO] oc: Creating a Deployment in alumno1--dev namespace with name library-shop from openshift.yml
    [INFO] oc: Created Deployment: target/jkube/applyJson/alumno1--dev/deployment-library-shop.json
    [INFO] oc: Creating Route alumno1--dev:library-shop host: null
    [INFO] oc: HINT: Use the command `oc get pods -w` to watch your pods start up
    ~~~

    Watch the pods

    ~~~sh
    oc get pods -w
    ~~~

    ~~~output
    NAME                            READY   STATUS      RESTARTS   AGE
    library-db-69f74cb64c-snvf6     1/1     Running     0          22m
    library-shop-5cfffb9db8-phlrx   1/1     Running     0          6m23s
    library-shop-s2i-1-build        0/1     Completed   0          21m
    ~~~

    Type Ctrl+C to exit from the watch

9. Check the application is working correctly

    Get the generated route host

    ~~~sh
    oc get route library-shop --template='{{ .spec.host }}'
    ~~~

    ~~~output
    library-shop-alumno1--dev.apps...
    ~~~

    Request the application data

    ~~~sh
    curl -k -s https://library-shop-alumno1--dev.apps...
    ~~~

    ~~~output
    ehlo from version v1 host library-shop-5cfffb9db8-phlrx
    ~~~

    ~~~sh
    curl -k -s https://library-shop-alumno1--dev.apps...ehlo/database
    ~~~

    ~~~output
    ehlo from PostgreSQL 15.3 on x86_64-redhat-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-18), 64-bit
    ~~~

    ~~~sh
    curl -k -s https://library-shop-alumno1--dev.apps.../hello
    ~~~

    ~~~sh
    curl -k -s https://library-shop-alumno1--dev.apps.../library
    ~~~

## Lab 2 - Deploy &nbsp; *in production* &nbsp; the Quarkus application

1. Change to the production namespace

    ~~~sh
    oc project alumno1
    ~~~

    ~~~output
    Now using project "alumno1" on server "https://api....:6443".
    ~~~

2. Inspect the OpenShift Pipeline resource

    ~~~sh
    oc get pipeline --show-labels
    ~~~

    ~~~output
    NAME                    AGE   LABELS
    library-shop-pipeline   35m   app=library-shop-pipelines,group=rhacademy
    ~~~

    Check the OpenShift console for a visual representation of the pipeline

    1. Get the console URL

        ~~~sh
        oc whoami --show-console
        ~~~

    2. Access the console URL in your favourite browser
    3. Open (right menu) the Pipelines option and click on the `library-shop-pipeline`

    4. Explore the pipeline details

3. Execute the pipeline

    via command

    ~~~sh
    tkn pipeline start library-shop-pipeline \
        -w name=shared-workspace,volumeClaimTemplateFile=https://github.com/juazugas/intro-to-quarkus-containers-ocp/raw/main/demo2-assets/openshift/prod/pipeline/library-shop-source.pvc.yaml \
        --prefix-name=library-shop-build- \
        --serviceaccount=pipeline \
        -p deployment-name=library-shop \
        -p git-url=https://github.com/juazugas/rha-quarkus-library-shop.git \
        -p backend-image=image-registry.openshift-image-registry.svc:5000/alumno1/library-shop:1.0.0 \
        -l group=rhacademy,app=library-shop \
        --use-param-defaults
    ~~~

4. Check the running pipeline

    via command :

    ~~~sh
    tkn pr ls
    ~~~

    ~~~output
    NAME                        STARTED          DURATION   STATUS
    library-shop-build--nkvj2   20 seconds ago   ---        Running
    ~~~

    via the Web console on the Pipelines section

5. (optional) Configure the webhook to automatically launch the pipeline

    1. Get the EventListener route host

    ~~~sh
    oc get route el-library-shop --template='{{ .spec.host }}'
    ~~~

    2. Define the Webhook in github

    3. Check the status of the Trigger and EventListener via the Administrator console \
    (Administrator -> Pipelines -> Triggers)

6. Trigger the pipeline

    Produce a commit in the application

    ~~~sh
    git commit -m 'trigger pipeline' --allow-empty
    ~~~

    Push the application to the git remote repository

    ~~~sh
    git push origin main
    ~~~

7. Review the running pipeline

    via command :

    ~~~sh
    tkn pr ls
    ~~~

    ~~~output
    NAME                        STARTED           DURATION   STATUS
    library-shop-trigger-72crf   21 seconds ago   ---        Running
    ~~~

    Or graphicaly via the Web console on the Pipelines section