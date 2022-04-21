# dist-services-with-go
Coding exercises and notes from the book "Distributed Services with Go" by Travis Jeffrey, March 2021, ISBN: 9781680507607

[Book Errata](https://devtalk.com/books/distributed-services-with-go/errata)

# Part I - Get Started
Building basic elements: storage layer, defining data structures.

[Install latest Go](https://go.dev/doc/install)
## Chapter 1 - Creating an http server with an append-only log service
A simple JSON over HTTP commit log service.

- Added the **proglog** go module.
    ```
    go mod init github.com/evdzhurov/dist-services-with-go/proglog
    ```

- Added [proglog/internal/server/log.go](proglog/internal/server/log.go)
    - An append-only **Log** data structure with two methods **Append** and **Read**.
- Added [proglog/internal/server/http.go](proglog/internal/server/http.go)
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
- Added [proglog/cmd/server/main.go](proglog/cmd/server/main.go)
    - Creates and starts the http server we defined above at localhost:8080.
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

* Added [proglog/api/v1/log.proto](proglog/api/v1/log.proto)
    * A protocol buffer description of a log record.

* [Install latest protobuf compiler](https://developers.google.com/protocol-buffers/docs/downloads)
    * Add the compiler executable to PATH

* Install the latest go plugin for protobuf compiler
    ```
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
    ```
    * Add porotoc-gen-go to PATH

* Added [proglog/Makefile](proglog/Makefile)
    * Added a target 'compile-proto' for compiling proto files.
    * Added a target 'test' for running Go tests.

## Chapter 3
Build a commit log library as the core of the service for storing and retrieving data.

* Terminology:
    * Record — the data stored in our log.
    * Store — the file we store records in.
    * Index — the file we store index entries in.
    * Segment — the abstraction that ties a store and an index together.
    * Log — the abstraction that ties all the segments together.

* Added [proglog/internal/log/store.go](proglog/internal/log/store.go)
    * Defines a **store** object that wraps a writable file and allows records to be written and read.
    * **Append** writes a record to the store by prepending 8 bytes for the record size.
    * **Read** reads at some position in the file - first the number of bytes of the record and then the record itself.
    * **ReadAt** reads a number of bytes defined by the length of the provided slice at some offset.
    * **Close** flushes writes to the underlying file of the **store** object and closes the file.

* Added [proglog/internal/log/store_test.go](proglog/internal/log/store_test.go)
    * Tests the basic functionality of a **store** object - creating a **store**, appending records, reading from and closing the underlying file.

* Added [proglog/internal/log/index.go](proglog/internal/log/index.go)
    * Defines an **index** object that wraps a writable file and allows references to records to be stored and retrieved.
    * Index elements are comprised of a relative offset (4 bytes) in a segment of elements and a position (8 bytes) in the storage file.
    * An **index** is supported by a memory mapped file which requires the file on disk to be resized when the **index** object is created and then the file to be truncated because at a subsequent restart of the service we need to read the last element of the index to be able to continue to append new elements.

* Added [proglog/internal/log/index_test.go](proglog/internal/log/index_test.go)
    * Tests creation of an **index** object, memory mapping the underlying file, writing elements to the index and reading back the elements.

* Added [proglog/internal/log/segment.go](proglog/internal/log/segment.go)
    * A segment binds a **storage** and **index** object, as well as a configuration on the maximum size of the storage and index files.

* Added [proglog/internal/log/segment_test.go](proglog/internal/log/segment_test.go)
    * Test that we can add a record to a segment, read back the record and eventually hit the configured max size for both the **store** and **index**.

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