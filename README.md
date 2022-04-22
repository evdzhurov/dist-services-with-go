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

### Store

* Added [proglog/internal/log/store.go](proglog/internal/log/store.go)
    * Defines a **store** object that wraps a writable file and allows records to be written and read.
    * **Append()** writes a record to the store by prepending 8 bytes for the record size.
    * **Read()** reads at some position in the file - first the number of bytes of the record and then the record itself.
    * **ReadAt()** reads a number of bytes defined by the length of the provided slice at some offset.
    * **Close()** flushes writes to the underlying file of the **store** object and closes the file.

* Added [proglog/internal/log/store_test.go](proglog/internal/log/store_test.go)
    * Tests the basic functionality of a **store** object - creating a **store**, appending records, reading from and closing the underlying file.

### Index

* Added [proglog/internal/log/index.go](proglog/internal/log/index.go)
    * Defines an **index** object that wraps a writable file and allows references to records to be stored and retrieved.
    * Index elements are comprised of a relative offset (4 bytes) in a segment of elements and a position (8 bytes) in the storage file.
    * An **index** is supported by a memory mapped file which requires the file on disk to be resized when the **index** object is created and then the file to be truncated because at a subsequent restart of the service we need to read the last element of the index to be able to continue to append new elements.

* Added [proglog/internal/log/index_test.go](proglog/internal/log/index_test.go)
    * Tests creation of an **index** object, memory mapping the underlying file, writing elements to the index and reading back the elements.

### Segment

* Added [proglog/internal/log/segment.go](proglog/internal/log/segment.go)
    * A segment binds a **storage** and **index** object, as well as a configuration on the maximum size of the storage and index files.

* Added [proglog/internal/log/segment_test.go](proglog/internal/log/segment_test.go)
    * Test that we can add a record to a segment, read back the record and eventually hit the configured max size for both the **store** and **index**.

### Log

* Added [proglog/internal/log/log.go](proglog/internal/log/log.go)
    * A **Log** combines a number of segments, the currently active segment, a configuration and the directory name where the segments are placed.
    * **Append()** adds a record to the active segment or creates a new segment to append the record to.
    * **Read()** finds the segment that contains the record for a given offset and returns the record or error if the offset is out of range.
    * **Close()** iterates the segments and closes them.
    * **Remove()** closes the log and removes the files.
    * **Reset()** removes the log and creates a new one.
    * **LowestOffset()** and **HighestOffset()** return the offset range in the log.
    * **Truncate()** removes all segments with a highest offset below some value.
    * **Reader()** returns an io.Reader to read the whole log.

* Added [proglog/internal/log/log_test.go](proglog/internal/log/log_test.go)
    * Test several scenarios for using the **Log** - append and read, out of range read, init existing, reader, truncate.

# Part II - Network
Make services work over a network.

## Chapter 4
Set up gRPC, define our server and client APIs, build client and server.

* Install gRPC protobuf support
    ```
    go install google.golang.org/grpc@v1.32.0
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.0.0
    ```

* Updated the 'compile-proto' Makefile command to include gRPC

* Added [proglog/internal/server/server.go](proglog/internal/server/server.go)
    * Contains an implementation of the gRPC service we defined in the file [proglog/api/v1/log.proto](proglog/api/v1/log.proto)
    * **Produce()** - RPC to add a record to the log.
    * **Consume()** - RPC to read a record from the log.
    * **ProduceStream()** - bidirectional streaming RPC.
    * **ConsumeStream()** - server-side streaming RPC to stream every record starting at some offset.
    * **CommitLog** - an interface that supports an **Append** and **Read** operations sufficient to represent a commit log. This allows us to decouple the implementation of the log from the implementation of the log service.

* Added [proglog/api/v1/error.go](proglog/api/v1/error.go)
    * Implement custom error **ErrOffsetOutOfRange** that includes a localized message and an error code.

* Added [proglog/internal/server/server_test.go](proglog/internal/server/server_test.go)
    * Test different scenarios of a client/server pair:
        * **testProduceConsume()** - single produce and consume call.
        * **testConsumePastBoundary()** - consume past the boundary tests producing **ErrOffsetOutOfRange**.
        * **testProduceConsumeStream()** - test bidirectional produce-consume and server-side continuous consumption.

## Chapter 5
Secure connections by authenticating with SSL/TLS and using access tokens.

* Install CloudFlare CLIs:
    ```
    go install github.com/cloudflare/cfssl/cmd/cfssl@v1.4.1
    go install github.com/cloudflare/cfssl/cmd/cfssljson@v1.4.1
    ```

* Added [proglog/test/ca-csr.json](proglog/test/ca-csr.json)
    * Configuration file used by **cfssl** for our CA's certificate.
    * Definitions:
        * **CN** - Common Name
        * **key** - specifies algorithm and size of signature key
        * Each entry in **names** should contain at least one (or a combination) of:
            * **C** - country
            * **L** - locality or municipality (city)
            * **ST** - state or province
            * **O** - organization
            * **OU** - organizational unit (department)

* Added [proglog/test/ca-config.json](proglog/test/ca-config.json)
    * Configuration file used to define the CA policy.

* Added [proglog/test/server-csr.json](proglog/test/server-csr.json)
    * Configuration file used to for the server certificate.

* Update the [proglog/Makefile](proglog/Makefile)
    * Added the **init** and **gencert** targets

* Added [proglog/internal/config/files.go](proglog/internal/config/files.go)
    * Define paths to generated TLS certificate files.

* Added [proglog/internal/config/tls.go](proglog/internal/config/tls.go)
    * Allows different tls configurations:
        * Client verifies the server's certificate with the client's by setting **RootCA**.
        * Client verifies the server's certificate and allows the server to verify the client's certificate by setting **RootCA** and **Certificates**.
        * Server verifies the client's certificate and allows the client to verify the server's certificate by setting **ClientCAs**, **Certificate** and **ClientAuth** mode to **tls.RequireAndVerifyCert**

* Modify [proglog/internal/server/server_test.go](proglog/internal/server/server_test.go)
    * Use **config.SetupTLSConfig()** to create a client TLS config with **config.CAFile** and connect with credentials.
    * Use **config.SetupTLSConfig()** to create a server TLS config. Pass credentials to **NewGRPCServer()** (extended to receive **grpc.ServerOption** parameters)

### Mutual (two-way) TLS authentication

* Added [proglog/test/client-csr.json](proglog/test/client-csr.json)
    * Configuration files used to generate a client certificate needed for mutual (two-way) TLS authentication.

* Modify [proglog/Makefile](proglog/Makefile)
    * Include client certificate generation in the **gencert** target.

* Modify [proglog/internal/config/files.go](proglog/internal/config/files.go)
    * Add variables for the client certificate files.

* Modify [proglog/internal/server/server_test.go](proglog/internal/server/server_test.go)
    * Add **CertFile**, **KeyFile** to **clientTLSConfig**, distinguish **serverTLSConfig** with **Server** flag turned on.

### Authorize with Access Control Lists (ACL)

* Install the ACL library **Casbin**
    ```
    go get github.com/casbin/casbin@v1.9.1
    ```
* Added [proglog/internal/auth/authorizer.go](proglog/internal/auth/authorizer.go)
    * Defines the **Authorizer** type with the **Authorize** functionality.
    * We defer the actual authorization to the **Casbin** library.

* Modify [proglog/Makefile](proglog/Makefile)
    * In order to test authorization we need at least two clients with different permissions.
    * Replace the previous client certificate generation with two new client certificates:
        * root-client
        * nobody-client

* Run 'make gencert' to generate the new client certificates

* Modify [proglog/internal/server/server_test.go](proglog/internal/server/server_test.go)
    * Create two separate clients 'root' and 'nobody' instead of just one using the appropriate TLS certificate files.
        * 'root' is a superuser that can produce and consume.
        * 'nobody' is not permitted any actions.

* Modify [proglog/internal/config/files.go](proglog/internal/config/files.go)
    * Add paths for root and nobody client certificates and ACL related files.

* Added [proglog/test/model.conf](proglog/test/model.conf) and [proglog/test/policy.csv](proglog/test/policy.csv)
    * **Casbin** specific configuration files

* Modify [proglog/internal/server/server_test.go](proglog/internal/server/server_test.go)
    * Add new function **testUnauthorized** that ascertains lack of permissions on the 'nobody' client.

* Modify [proglog/internal/server/server.go](proglog/internal/server/server.go)
    * Add the **Authorizer** interface to server **Config**.
    * Update **Produce()** to authorize the action before performing it.
    * Update **Consume()** to authorize the action before performing it.
    * **authenticate()** is an interceptor that reads the subject name out of the TLS certificate and writes it to the RPC context. This is a form of middleware.
    * Install the **authenticate()** method as a middleware option in **NewGRPCServer()**

* Modify [proglog/internal/server/server_test.go](proglog/internal/server/server_test.go)
    * Create the **Authorizer** object and add it to the server config.

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