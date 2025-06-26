# go-template
A template to create API projects in GO
After crating and configuring a project with this template we will have a project ready to deploy as an API
The project will contain
1. Initial code with a /ping GET method with tests and coverage
2. Dockerfile to create registry in AWS
3. Sonarcloud configuration to check tests, coverage and code quality
4. CI/CD pipelines to deploy
5. Terraform configuration to deploy to AWS as an API
6. Datadog configuration

## Instructions
This template doesn't contain all the names of the created project. So this guideline is **very important** to ensure a proper project configuration

### Code configuration
Golang works with modules, so this project is created with module 'github.com/trafilea/go-template' (see go.mod file)
So here is the list with all the changes needed for the project to build
1. Go to *go.mod* file and change 'go-template' for your project-name
Example: ```module github.com/trafilea/go-template``` -> ```module github.com/trafilea/checkout-api```
2. Go to *internal/routes/routes.go* and change all 'go-template' to your project's name
Example: ```github.com/trafilea/go-template/pkg/apperrors``` -> ```github.com/trafilea/checkout-api/pkg/apperrors```
3. Go to *internal/routes/routes_test.go* and change all 'go-template' to your project's name. Same as point 2
4. Go to *cmd/app/main.go* and change all 'go-template' to your project's name. Same as point 2
5. Run command ```go mod tidy```
6. Run command ```go build ./...``` to check all changes are ok

### Dockerfile configuration
In this case we need to change all project name references
1. ```WORKDIR /go-template``` -> ```WORKDIR /checkout-api```
2. ```RUN go build -o /build/go-template.go cmd/app/main.go``` -> ```RUN go build -o /build/checkout-api.go cmd/app/main.go```
3. ```CMD [ "/build/go-template.go" ]``` -> ```CMD [ "/build/checkout-api.go" ]```

### Sonarcloud configuration
In this case we need to change all project name references
1. ```'sonar.projectKey=trafilea_go-template'``` -> the project key assigned when setting up sonar
2. ```sonar.projectName=go-template``` -> ```sonar.projectName=checkout-api```

### CI/CD configuration
There isn't anything to change in case of CI. But there are some things to change for CD

1. In *.github/workflows/continuous-deployment.yaml* edit the following
    1. Change ```APP_NAME: go-template``` -> ```APP_NAME: checkout-api```
    2. Add `branches` instead of `branches-ignore` to CD pipeline (we are removing this because we don't want to execute them when creating this go-template)
        ```yaml
        on:
            push:
                branches:
                    - main
                    - develop
        ```
        
2. In *.github/workflows/continuous-integration.yaml* edit the following
    1. Add `branches` instead of `branches-ignore` to CD pipeline (we are removing them because we don't want to execute them when creating this go-template)
        ```yaml
        on:
            pull_request:
                branches:
                    - main
                    - develop
        ```

3. In *.github/workflows/datadog-monitors.yaml* edit the following
    1. Add `branches` instead of `branches-ignore` to CD pipeline (we are removing them because we don't want to execute them when creating this go-template)
        ```yaml
        on:
            pull_request:
                branches:
                    - main
                paths:
                    - '.datadog/**'
        ```
    2. ```TF_VAR_APPLICATION_NAME: go-template``` -> ```TF_VAR_APPLICATION_NAME: checkout-api```

4. In *.github/workflows/manual-deployment.yaml* edit the following
    1. Change ```APP_NAME: go-template``` -> ```APP_NAME: checkout-api```

### Terraform
Before starting with your project, you should change some stuff in order to get the best result. 
1. In *terraform/globals/provider.tf* you should change the `default_tags` block according to your API.
For example, you could have the following config:
```hcl
default_tags {
   tags = {
     Application = "MyAPI"
     Environment = var.environment
     Owner       = "soft-dev"
     Project     = "IncredibleAPIProject"
     Provisioned = "Terragrunt"
   }
 }
 ```
2. In each *environment.hcl* file on the *terraform/environment* folders, you should change the *app_name*, *app_name_caps* and *app_port* according to your project. For example:
```hcl
inputs = {
  vpc_id        = "vpc-01af99de0fc923203"
  app_name      = "my-api"
  app_name_caps = "My API"
  app_port      = 80
  environment   = "stage"
  region        = "us-east-1"
  account_id    = 209977326717
}
 ```
**Note: don't change the VPC, Region, environment or account_id inputs, since they are used to deploy the project on the corresponding environment**

3. In *terraform/terragrunt.hcl* you should change the `config.keys` like ```key = "go-template/${basename(get_terragrunt_dir())}.tfstate"``` -> ```key = "checkout-api/${basename(get_terragrunt_dir())}.tfstate"```

4. Review the configuration for each module on the *terraform/environment* folders. There are hardcoded app names, and ports in the modules config. If you don't understand or need a review about your config, tell @jw-tera (Juan Wiggenhauser on Slack) to review it ;) . We are working to remove this and put a global configuration in the future
Example for *alb_sg*:
```hcl
inputs = merge( local.environment_vars, 
  {
    security_group_name = "my-api-alb-sg"
    security_group_desc = "My API ALB Access Control"
    //Check your rules
    sg_inbound = [
      {
        from_port   = 80 //Look for the port on your app
        to_port     = 80 //Look for the port on your app
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
    //Dont touch this:
    sg_outbound = [ 
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
    
})
```
Please, feel free to ask the infra team for a review of your code.


### Datadog
1. In *.datadog/datadog.backend.tf* change project names
    1. ```key = "go-template/datadog.tfstate"``` -> ```key = "checkout-api/datadog.tfstate"```

### Other configurations
1. Create project in SonarCloud and create the secret SONAR_TOKEN in the project
2. Ask Infrastructure team to create ECR repository with the project name (example checkout-api)
3. Ask github organization's admin to allow the project to have AWS secrets
