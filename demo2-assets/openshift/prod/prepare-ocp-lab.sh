#!/bin/bash
#

numStudents=${STUDENTS:-50}
nsPreffix=${STUDET_NS:-student}

OC="oc"

for i in $(seq "${numStudents}"); do
  echo "Preparing environment for student $i"
  namespace="${nsPreffix}${i}"

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
done
