# dist-services-with-go
Coding exercises and notes from the book "Distributed Services with Go" by Travis Jeffrey, March 2021, ISBN: 9781680507607

[Book Errata](https://devtalk.com/books/distributed-services-with-go/errata)

# Part I - Get Started
Building basic elements: storage layer, defining data structures.
## Chapter 1
Simple JSON over HTTP commit log service.

## Chapter 2
Set up protocol buffers, generate data structures, set up automation.

## Chapter 3
Build a commit log library as the core of the service for storing and retrieving data.

# Part II - Network
Make services work over a network.

## Chapter 4
Set up gRPC, define our server and client APIs, build client and server.

## Chapter 5
Secure connections by authenticating with SSL/TLS and using access tokens.

## Chapter 6
Make our service observable by adding logs, metrics and tracing.

# Part III - Distribute
Make our service distributed, highly available, resilient and scalable.

## Chapter 7
Build discovery into our service and make server instances aware of each other.

## Chapter 8
Add consensus to coordinate our servers and turn them into a cluster.

## Chapter 9
Add discovery in our gRPC clients so they can connect to the server with client-side load balancing.

# Part IV - Deploy
Deploy our service and make it live.

## Chapter 10
Set up Kubernetes locally and run a cluster on your machine. Prepare to deploy on the Cloud.

## Chapter 11
Create a Kubernetes cluster on Google Cloud's Kubernetes Engine and deploy our service to the Cloud.