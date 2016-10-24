#!!
#! @description: Performs an Amazon Web Services Elastic Compute Cloud (EC2) command to start a STOPPED server (instance) and changes its status to ACTIVE. PAUSED and SUSPENDED servers (instances) cannot be started.
#! @input identity: ID of the secret access key associated with your Amazon AWS account.
#! @input proxy_host: Proxy server used to access the provider services
#! @input proxy_port: Proxy server port used to access the provider services - Default: '8080'
#! @input proxy_username: Proxy server user name.
#! @input proxy_password: Proxy server password associated with the proxyUsername input value.
#! @input headers: String containing the headers to use for the request separated by new line (CRLF). The header name-value pair will be separated by ":". Format: Conforming with HTTP standard for headers (RFC 2616). Examples: "Accept:text/plain"
#! @input query_params: String containing query parameters that will be appended to the URL. The names and the values must not be URL encoded because if they are encoded then a double encoded will occur. The separator between name-value pairs is "&" symbol. The query name will be separated from query value by "=". Examples: "parameterName1=parameterValue1&parameterName2=parameterValue2"
#! @input instance_id: The ID of the server (instance) you want to start.
#! @input region: Region where the server (instance) is. Default: 'us-east-1'
#! @output output: contains the success message or the exception in case of failure
#! @output return_code: "0" if operation was successfully executed, "-1" otherwise
#! @output exception: exception if there was an error when executing, empty otherwise
#!!#
namespace: io.cloudslang.cloud.amazon_aws

imports:
  instances: io.cloudslang.cloud.amazon_aws.instances
  strings: io.cloudslang.base.strings
  utils: io.cloudslang.base.flow_control

flow:
  name: start_instance
  inputs:
    - identity
    - credential:
        sensitive: true
    - proxy_host:
        required: false
    - proxy_port:
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
        sensitive: true
    - headers:
        required: false
    - query_params:
        required: false
    - instance_id:
        required: true
    - region:
        required: false
  workflow:
    - start_instances:
        do:
          io.cloudslang.cloud.amazon_aws.instances.start_instances:
            - identity: '${identity}'
            - credential: '${credential}'
            - proxy_host: '${proxy_host}'
            - proxy_port: '${proxy_port}'
            - proxy_username: '${proxy_username}'
            - proxy_password: '${proxy_password}'
            - headers: '${headers}'
            - query_params: '${query_params}'
            - instance_id: '${instance_id}'
        publish:
          - return_result: '${return_result}'
          - return_code: '${return_code}'
          - exception: '${exception}'
        navigate:
          - FAILURE: FAILURE
          - SUCCESS: check_instance_state
    - check_instance_state:
        loop:
          for: step in range(50)
          do:
            io.cloudslang.utils.check_instance_state:
              - identity: '${identity}'
              - credential: '${credential}'
              - instance_id: '${instance_id}'
              - instance_state: running
              - proxy_host: '${proxy_host}'
              - proxy_port: '${proxy_port}'
              - region: '${region}'
          break:
            - SUCCESS
          publish:
            - return_result: '${return_result}'
            - return_code: '${return_code}'
            - exception: '${exception}'
        navigate:
          - FAILURE: FAILURE
          - SUCCESS: SUCCESS
  outputs:
    - output: '${return_result}'
    - return_code: '${return_code}'
    - exception: '${exception}'
  results:
    - SUCCESS
    - FAILURE
