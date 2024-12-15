#!/bin/bash
#
# Run as admin

numStudents=${STUDENTS:-50}
nsPreffix=${STUDENT_NS:-student}
studentList=${STUDENT_LIST:-$(seq "${numStudents}")}
studentUser=${STUDENT_USER:-developer}

OC="oc"
TKN="tkn"

# Prepare pipelines base project
pipelinesNs="${nsPreffix}-pipelines"
pipelineTasks="git-clone buildah openshift-client maven"

$OC project "${pipelinesNs}" || $OC new-project "${pipelinesNs}"

# Install tekton tasks from hub
for task in $pipelineTasks; do
  echo "installing task $task in $pipelinesNs"
  $TKN hub install task "${task}" -n "${pipelinesNs}" || \
    echo "$task already installed in $pipelinesNs"
done

$OC adm policy add-role-to-user view "$studentUser" -n "${pipelinesNs}"

for i in $STUDENT_LIST; do
  echo "Preparing environment for student $i"
  namespace="${nsPreffix}${i}"

  $OC project "${namespace}" || $OC new-project "${namespace}"

  $OC annotate --overwrite namespace/${namespace} 'operator.tekton.dev/prune.keep=2'
  $OC annotate --overwrite namespace/${namespace} 'operator.tekton.dev/prune.schedule=* * * * *'

  # deploy the database
  $OC apply -n ${namespace} -f database/

  # define the pipeline
  $OC apply -n ${namespace} -f pipeline/

  # expose the eventlistener
  $OC create route edge el-library-shop -n ${namespace} \
      --service=el-library-shop --insecure-policy=Redirect \
      -o yaml

  # Permissions
  $OC adm policy add-role-to-user admin "$studentUser" -n "${namespace}"

done
