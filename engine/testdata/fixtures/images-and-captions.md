## Architecture Overview

The diagram below shows the request flow through the system.

![Diagram showing a client sending a request through a load balancer to two backend services](https://assets.example.com/diagrams/request-flow.png)

Figure 1: Request flow from client to backend

Each service reports health to a shared ![heartbeat icon](https://assets.example.com/icons/heartbeat.png) monitor, which is polled every 30 seconds.
