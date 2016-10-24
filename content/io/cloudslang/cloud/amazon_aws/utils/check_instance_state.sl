#!!
#! @description: It checks if an instance has a specific state.
#! @input identity: ID of the secret access key associated with your Amazon AWS account.
#! @input credential: Secret access key associated with your Amazon AWS account.
#! @input proxy_host: Proxy server used to access the provider services
#! @input proxy_port: Proxy server port used to access the provider services - Default: '8080'
#! @input instance_id: The ID of the server (instance) you want to check.
#! @input instance_state: The state that you would like the instance to have.
#! @input region: Region where the server (instance) is. Default: 'us-east-1'
#! @output output: contains the success message or the exception in case of failure
#! @output return_code: "0" if operation was successfully executed, "-1" otherwise
#! @output exception: exception if there was an error when executing, empty otherwise
#! @result SUCCESS: the server (instance) has the expected state
#! @result FAILURE: error checking the instance state, or the actual state is not the expected one
#!!#
####################################################
namespace: io.cloudslang.cloud.amazon_aws.utils

imports:
  instances: io.cloudslang.cloud.amazon_aws.instances
  strings: io.cloudslang.base.strings
  utils: io.cloudslang.base.flow_control

flow:
  name: check_instance_state
  inputs:
    - identity
    - credential:
        sensitive: true
    - proxy_host:
        required: false
    - proxy_port:
        required: false
    - instance_id
    - instance_state
    - region:
        required: false
  workflow:
    - describe_instances:
        do:
          io.cloudslang.cloud.amazon_aws.instances.describe_instances:
            - identity: '${identity}'
            - credential: '${credential}'
            - proxy_host: '${proxy_host}'
            - proxy_port: '${proxy_port}'
            - instance_id: '${instance_id}'
            - region: '${region}'
        publish:
          - return_result
          - return_code: '${return_code}'
          - exception: '${exception}'
        navigate:
          - FAILURE: FAILURE
          - SUCCESS: string_occurrence_counter
    - string_occurrence_counter:
        do:
          io.cloudslang.base.strings.string_occurrence_counter:
            - string_in_which_to_search: '${return_result}'
            - string_to_find: "${'state=' + instance_state}"
        publish: []
        navigate:
          - FAILURE: sleep
          - SUCCESS: SUCCESS
    - sleep:
        do:
          io.cloudslang.base.flow_control.sleep:
            - seconds: '10'
        navigate:
          - FAILURE: FAILURE
          - SUCCESS: FAILURE
  outputs:
    - output: '${return_result}'
    - return_code: '${return_code}'
    - exception: '${exception}'
  results:
    - SUCCESS
    - FAILURE
