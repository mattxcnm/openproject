---
sidebar_navigation:
  title: Application architecture
description: An introduction of the architecture used at OpenProject and their interplay.
keywords: architecture overview, hybrid application, Ruby on Rails, Angular
---



# Application architecture



```mermaid
%%{init: {'theme':'neutral'}}%%

flowchart TD
  A[Client Browser] -->|"HTTP(s) requests"| B(Load Balancer / Proxy)
  A1[API or Native clients] -->|"HTTP(s) requests"| B(Load Balancer / Proxy)
  A2[SVN or Git clients] -->|"HTTP(s) requests"| B(Load Balancer / Proxy)
  B -->|Proxy| openproject

  subgraph openproject[OpenProject]
    C[Puma app server]
    D[Background worker]
  end


  subgraph integrations[External integrations]
	  O[Other integrations]
    N[Nextcloud]
  end

  subgraph services[Services]
  	M[memcached]
	  P[PostgreSQL]
	  S[Object storage or NFS]
  end


  openproject <--> services
  openproject --> integrations
  B <--> integrations

```





# Software

OpenProject is developed as a GPLv3 licensed, open-source software. The software core is developed and maintained using [GitHub](https://github.com/opf/openproject/). OpenProject is available as several versions:

- [Community Edition](https://www.openproject.org/community-edition/)
- [Enterprise on-premises and Enterprise cloud](https://www.openproject.org/enterprise-edition/)



# Environments

OpenProject is continuously tested, developed, and distributed using the following environments

| **Environment**                 | **Description**                                              | **Release Target**                                           | **Deployment cycles**                                        |
| ------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Edge                            | Automatic deployments through [GitHub actions](https://github.com/opf/openproject/blob/dev/.github/workflows/continuous-delivery.yml) for instances on openproject-edge.com<br />Subject for continuous QA, acceptance and regression testing. | Next minor or major release planned and developed in our [community instance](https://community.openproject.org/projects/openproject/) | On every push to `opf/openproject#dev`                       |
| Stage                           | Automatic deployments through [GitHub actions](https://github.com/opf/openproject/blob/dev/.github/workflows/continuous-delivery.yml) for instances on openproject-stage.com.<br />Subject for QA and acceptance testing of bugfix prior to stable releases. | Next patch release of the current stable release following our [release plan](https://community.openproject.org/projects/openproject/work_packages?query_id=918) | On every push to `release/X.Y`, where `X.Y` is the current stable release major and minor versions. |
| Production<br />(SaaS / Cloud)  | Production cloud environments. Deployed manually with the latest stable release | Stable releases                                              | Manually                                                     |
| Production<br />(Docker images) | [Official public OpenProject docker images](https://hub.docker.com/r/openproject/community)<br />Continuous delivery for development versions using `dev-*`tags.<br />Stable releases through major, minor, or patch level tags. | Development (`dev`, `dev-slim` tag)<br />Stable releases (`X`, `X.Y`, `X.Y.Z`, `X-slim`, `X.Y-slim`, `X.Y.Z-slim`) | Automatically on new releases of the OpenProject application |
| Production<br />(Packages)      | [Official public OpenProject Linux packages](https://www.openproject.org/docs/installation-and-operations/installation/packaged/) <br /><br />Stable releases for supported distributions | Stable releases                                              | Automatically on new releases of the OpenProject application |
| Production<br />(Helm chart)    | [Official public OpenProject Helm charts](https://www.openproject.org/docs/installation-and-operations/installation/helm-chart/)<br />Stable releases | Stable releases (configurable through container tags)        | Updates to Helm chart are manual, underlying deployment uses OpenProject docker images |
| PullPreview                     | Temporary instances for development of features scope to a pull request. | Feature branches                                             | Automatically deployed when developers/QA request a pull preview instance by labelling pull requests with the `PullPreview` tag. |



# Components

A typical installation of OpenProject uses a web server such as NGINX or Apache to proxy requests to and from the internal [Puma](https://puma.io/) application server. All web requests are handled internally by it. A background job queue is used to execute longer running data requests or asynchronous communications.

For more information on the data flow between these components, please also see our [data flow documentation](../data-flow).



## Puma application server

OpenProject uses a Puma application server to run and handle requests for the Rails stack. All HTTP(S) requests to OpenProject are handled by it. Puma is a configurable multi-process, multithreading server. The exact number of servers being operated depends on your deployment method of OpenProject. See the [process control and scaling documentation](https://www.openproject.org/docs/installation-and-operations/operation/control/) for more information.



## External load balancer or proxying server

A web server is expected to handle requests between the end-user and the internal Puma application server. It is responsible for e.g.,  terminating TLS and managing user-facing HTTP connections, but depending on the deployment, also for serving static assets and certain caching related functionality. This server performs a proxy-reverse proxy pattern with the internal application server. No external connections are allowed directly to the Puma server.



## Rails application

The core application, built on the Ruby on Rails framework, handling business logic, database operations, and user interactions. Utilizes the Model-View-Controller (MVC) design pattern. Follows [secure coding guidelines](../concepts/secure-coding/) for authentication, session management, user input validation, and error logging.

The application aims to return to the MVC pattern using Rails, Hotwire, and ViewComponents for UI element composition. This strategy aims for higher usability and efficient development.



## Angular frontend

Some of the responses of the application include a frontend application approach using Angular. These pages communicate with a REST API to receive data and perform updates. An example of this is the work packages module. Requests within the module are handled completely in the frontend, while boundary requests are forwarded to the Rails stack, returning to a classical request/response pattern.

All requests to the application are still handled by Rails. In some of the responses, only the root Angular component is rendered to bootstrap the Angular frontend. On these pages, [UI-Router for Angular](https://github.com/ui-router/angular) parses the URL to determine what module/frontend route to load and show.

In the following, we'll take a look at the different components at use in the application stack of OpenProject as well as concrete examples on how these components interact.



### Exemplary frontend view request

Let's take a look at how the request to `/projects/identifier/work_packages` would be handled by Rails and Angular (excluding any external actual HTTP requests to the web server)

1. Rails receives the request and according to its [`config/routes.rb`](https://github.com/opf/openproject/blob/dev/config/routes.rb#L257), will handle the request with the [WorkPackagesController#index action](https://github.com/opf/openproject/blob/dev/app/controllers/work_packages_controller.rb#L66-L81).
2. This controller responds with [an index template](https://github.com/opf/openproject/blob/dev/app/views/work_packages/index.html.erb) that only renders some details but otherwise, will output the `<openproject-base>` Angular root component that is defined in the [`Rails angular layout`](https://github.com/opf/openproject/blob/dev/app/views/layouts/angular/angular.html.erb).
3. The rendered response is returned to the Browser and Angular is initialized globally once in [`frontend/src/main.ts`](https://github.com/opf/openproject/blob/dev/frontend/src/main.ts#L48-L49).
4. As the `<openproject-base>` component contains a ui-router [`[ui-ref]`](https://github.com/opf/openproject/blob/dev/frontend/src/app/core/routing/base/application-base.component.ts) directive, the ui-router will start parsing the URL and looks for a route definition that matches. It will end up matching `root.work-packages` [defined in the work packages' module routes file](https://github.com/opf/openproject/blob/dev/frontend/src/app/features/work-packages/routing/work-packages-routes.ts).
5. From there, the flow is as with a single-page application. The router mounts that component and the Angular frontend will use the APIv3 to fetch and render the application table.



This will result in a page on which the majority of the content has been rendered by Angular. Only the toolbar, basic page structure, and upper side menu have been rendered by Rails.

![Work packages table](work-packages-table.png)

This approach has the significant disadvantage to go through the entire Rails stack first to output a response that is mostly irrelevant for the Angular application, and both systems (Rails and Angular) need a somewhat duplicated routing information. The long-term goal is to move to a single-page application and avoid the first two steps.



### Exemplary Rails view request augmented by Angular

A response that is fully controlled by Rails but extended by some Angular components in the frontend might look as follows. Let's take a look at the request to [edit a type's form configuration](../../system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration-enterprise-add-on) `/types/1/edit/form_configuration`:

1. Rails receives the request and according to its [`config/routes.rb`](https://github.com/opf/openproject/blob/dev/config/routes.rb#L257), will handle the request with the [TypesController#edit action](https://github.com/opf/openproject/blob/dev/app/controllers/types_controller.rb#L71-L82) with its tab set to `form_configuration`.

2. This controller responds with [an edit template](https://github.com/opf/openproject/blob/dev/app/views/types/edit.html.erb) that will include the [type form partial](https://github.com/opf/openproject/blob/dev/app/views/types/form/_form_configuration.html.erb#L77-L83). In this component, an Angular component is explicitly output that will be bootstrapped on page load.

3. The rendered response is returned to the Browser and Angular is initialized globally once in [`frontend/src/main.ts`](https://github.com/opf/openproject/blob/dev/frontend/src/main.ts#L48-L49).

4. A global service, the [`DynamicBootstrapper`](https://github.com/opf/openproject/blob/dev/frontend/src/app/core/setup/globals/dynamic-bootstrapper.ts), looks for eligible components to bootstrap in the rendered template and forces the global angular application to bootstrap this component. This may result in many dom-separated components in the page to be bootstrapped by Angular for dynamic content.

5. This triggers the [`FormConfigurationComponent`](https://github.com/opf/openproject/blob/dev/frontend/src/app/features/admin/types/type-form-configuration.component.ts) to be initialized and allows the application to include a highly dynamic component (drag & drop organization of attributes) to be used on an admin form that otherwise has no connection to Angular.

   ![Exemplary form configuration](form-configuration.png)



# Evolution of the application

Historically, OpenProject has been forked from [Redmine](https://www.redmine.org/) and modified from a primarily software-development focused flow into a general project management application suite. A Ruby on Rails monolith was used to serve the entire application, frontend and API. Javascript was used to extend some of the functionality with Prototype.js and jQuery on existing, Rails-rendered pages.

The monolith was turned into a hybrid application with semi-separated JavaScript frontend by the [introduction of AngularJS in 2014](https://github.com/opf/openproject/pull/913) for a redesign of the [work package table](../../user-guide/work-packages/work-package-views/#work-packages-views). The Rails monolith was and is still rendering a large portion of the frontend however. The AngularJS frontend was served from within Rails and not separated. Therefore, the application frontend is not a single-page application yet.

Due to performance issues with AngularJS digest cycles and a large number of components, the work package table was [refactored into a plain JavaScript renderer](https://github.com/opf/openproject/pull/5117) end of 2016. Finally, in early 2018, the application frontend was [migrated from AngularJS to Angular](https://github.com/opf/openproject/pull/5984) during the course of a few releases.

[In early 2019](https://github.com/opf/openproject/pull/7385), the rest of AngularJS code was removed and the frontend switched to the Angular CLI with Ahead-of-Time compilation (AOT).
