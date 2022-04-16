# dist-services-with-go
Coding exercises and notes from the book "Distributed Services with Go" by Travis Jeffrey, March 2021, ISBN: 9781680507607

[Book Errata](https://devtalk.com/books/distributed-services-with-go/errata)

# Part I - Get Started
Building basic elements: storage layer, defining data structures.
## Chapter 1 - Creating an http server with an append-only log service
A simple JSON over HTTP commit log service.

- Added the **proglog** go module.
    ```
    go mod init github.com/evdzhurov/dist-services-with-go/proglog
    ```

- Added **proglog/internal/server/log.go**
    - An append-only **Log** data structure with two methods **Append** and **Read**.
- Added **proglog/internal/server/http.go**
    - Represents an http server with a **Log** data structure.
    - The POST "/" http request maps to the **Append** method of the **Log**.
        - **ProduceRequest** - contains the record that the caller wants appended to the log.
        - **ProduceResponse** - tells the caller the offset at which the record is stored in the log.
    - The GET "/" http request maps to the Read method of the **Log**.
        - **ConsumeRequest** - specifies which records the caller wants to read.
        - **ConsumeResponse** - sends back the requested records back to the caller.
    - **handleProduce** implements three steps to append a record to the log:
        1. Unmarshal the request's JSON body into a struct.
        2. Run the endpoint logic for the request and produce a result.
        3. Marshal and write the result to the response.
    - **handleConsume** is similar to **handleProduce** but implements the logic for reading a record from the log.
        - Returns **http.StatusNotFound** if the caller asks for a non-existent record.
- Added **proglog/cmd/server/main.go**
    - Creates and starts the http server we defined above at [localhost:8080](http://localhost:8080).
- Test the API
    ```
    go run main.go
    ```
    - Post records to the log. Since records are byte[] and the encoding/json package encodes byte[] as a base64-encoded string we need to provide a valid base64 string.
        ```
        curl -X POST localhost:8080 -d \
        '{"record": {"value": "TGV0J3MgR28gIzEK"}}'
        curl -X POST localhost:8080 -d \
        '{"record": {"value": "TGV0J3MgR28gIzIK"}}'
        curl -X POST localhost:8080 -d \
        '{"record": {"value": "TGV0J3MgR28gIzMK"}}'
        ```
    - Test if the records can be retrieved from the log by requesting the indices:
        ```
        curl -X GET localhost:8080 -d '{"offset": 0}'
        curl -X GET localhost:8080 -d '{"offset": 1}'
        curl -X GET localhost:8080 -d '{"offset": 2}'
        ```  

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