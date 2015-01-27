class: center, inverse, middle

# .yellow[Foreman] Multi-Host Deployments

### Petr Chalupa

???

---
# Content

-   Motivation
-   Stack definition
-   Deployment creation and configuration
-   Deploying Deployment
-   Data Model
-   Use-cases
-   Demo

???

-   *TODO*

---
class: center, inverse, middle
# Motivation

---
# Motivation

-   Multi host deployment.
-   Deploy and re-deploy your whole application infrastructure with ease.
-   Have control over the deployment process (monitor progress and failures).

--

### Use-cases:

-   Application infrastructure definition
-   Compute resource installation
-   Cross machine orchestration
-   OpenStack

---
class: center, inverse, middle

# Stack definition

---
# Stack

The definition of the infrastructure.

-   Independent
-   Reusable
-   Sharable
-   Export
-   Import

---
# Resources

Definition of .yellow[Foreman]'s objects to be created or configured.

-   Configuration
    -   Hostgroups
    -   Parameters
    -   PuppetClass
    -   Overrides
    -   Hosts
    -   SubnetTypes
    -   ComputeResources and ComputeProfiles
    -   ConnectParameters
-   Ordering
    -   PuppetRuns
    -   ParameterUpdates
    -   ChildStacks

---
# Stack example - DB

```ruby
db_stack = stack :db do
  hostgroup :db do
    parameter :db_password
    parameter :db_url, '<%= compute_url() %>'

    puppet_class :postgres do
      override '$postgres::password',
               "<%= get_parameter('db_password') %>" # pseudo
    end

    host :db, min: 1, max: 1 do
      puppet_run >> puppet_run
    end
  end
end
```

???

-   explain associations given by nesting in DSL example

---
# Stack example - Web server

```ruby
web_server_stack = stack :web_server do
  hostgroup :web_server do
    parameter :db_password
    parameter :db_url

    puppet_class :sinatra_app do
      override '$sinatra_app::db_password',
               "<%= get_parameter('db_password') %>" # pseudo
      override '$sinatra_app::db_url',
               "<%= get_parameter('db_url') %>" # pseudo
    end

    host :db, min: 1 do
      puppet_run
    end
  end
end
```

---
# Stacking stacks

New stack "My web application"

-   defines `:db_password` parameter for `db`, `web_server` stacks
-   takes `:db_url` parameter and sets value in `web_server` to read it from `db`
-   it may define common parent hostgroup

```ruby
stack :web_app do
  hostgroup :web_app do
    parent_of db_stack.hostgroups[:db]
    parent_of web_server_stack.hostgroups[:web_server]

    parameter :db_password
    connect db_stack.hostgroups[:db].parameter[:db_url],
            web_server_stack.hostgroups[:web_server].param[:db_url]

    child(db_stack) >> child(web_server_stack)
  end
end
```

???

-   Just demonstration, it's likely to change

---
class: center, inverse, middle

# Deployment creation

# and configuration

---
# Creation

Fill:

-   name
-   stack
-   description

Hit `Create` button.

???

- nothing happens at this point

---
# Configuration

-   Hostgroups
    -   Parents
-   Parameters
    -   Values
-   Hosts
    -   Number of hosts
    -   Bare metal or compute resource
    -   Networks

---
class: center, inverse, middle

# Deploying

---
# State before deploying

All resources are configured for the Deployment, creating:

-   Hostgroups
-   GroupParameters
-   Hosts

--

All hosts 

-   are created in DB waiting for `build` flag to be flipped 
-   and to be provisioned.

---

# Deploying

### using Dynflow

-   Orchestration engine
-   Workflow engine

--

### Order

1.  Provision all hosts at once (no configuration)
1.  Builds Dynflow plan based on dependencies of ordered resources
1.  Dynflow executes the plan and deploys the Deployment
    1.  puppet run on DB host
    1.  puppet runs on all web server hosts in parallel
1.  Voilà!

---
class: center, inverse, middle

# Data Model

???

---
background-image: url(images/overview_class.svg)

---
class: center, inverse, middle

# Use-cases

---
# Application infrastructure definition

-   Easy redeployment of your application's infrastructure.
-   In practice load-balancers and other services added.
-   Pieces can be shared between applications.

---
# Compute resource installation

A .yellow[Foreman] plugin

-   Stack describing oVirt deployment.
-   Custom resource implementing creation of new `ComputeResource`.
-   Uses bare metal hosts in deployment configuration.
-   Deploys and creates configured `ComputeResource` for .yellow[Foreman]'s users.

???

-   Resources are extensible!!

*oVirt logo*

---
# Cross machine orchestration

`PuppetRun` and `ParameterUpdate`

 | Host1 | Host2 | Host3 | Host4
:---: | :---: | :---: | :---: | :---:
 1 |AuthService PuppetRun | | |
2 | |  AuthClient PuppetRun |  AuthClient PuppetRun |  AuthClient PuppetRun
3 | CollectClients PuppetRun |  DataBase PuppetRun | |
4 | | |  WebServer PuppetRun | WebServer PuppetRun

---
# OpenStack

-   Networking configuration
-   HA OpenStack controllers
-   Services orchestration

---
# Other config management tools

*TODO content? use-cases in motivation?*

???

-   explain open stack

*OpenStack logo*

---
class: center, inverse, middle

# Little Demo

???

-   Focus on extensibility

*TODO if applicable*
---
class: center, inverse, middle

# Thanks

## Questions & Answers

???

-   **Q:** Who would like to use it?
-   **Q:** Who would not use it?
-   **Q:** What would prevent you to use it?
-   *todo more*
