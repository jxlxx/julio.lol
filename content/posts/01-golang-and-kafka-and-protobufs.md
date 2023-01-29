---
title: How to use Protobuf with Golang & Kafka 
date: "2022-04-06"
description: "A quickstart on publishing protocol buffers in Kafka messages. "
draft: false
tags: ["kafka", "golang", "protobuf"]
---

# TLDR;
- Download `protoc` and `protogen-go`
- Create a `.proto` file with a structure definition, this is called defining a message type
- Use the protoc compiler to generate a `*.pb.go` file (which is the golang source code that contains all your functionality related to your message type)
- Instances of a message type are called messages: `msg := pb.ExampleType{}`
- Set data like this: `msg := pb.ExampleType{FieldName : <data>}`
- Add/update data like this: `msg.FieldName = <data>`
- Debug printing is done with: `proto.Message(&msg)`
- Serialize your message: `proto.Marshal(&msg)`
- Publish to Kafka topic: `Kafka.Message{… Value: serialized_message ….})`
- Kafka subscriber receives this Kafka message, deserializes the data via: `proto.Unmarshal(kafkaMessage.Value, &msg))`
- Access fields like this: `&msg.GetFieldName()`
- bingo bongo that's it

> 💡 Note that I'm using [Confluent's implementation of a Golang client](https://github.com/confluentinc/confluent-kafka-go) for Kafka if it matters!! 

# About protobuf

- Protocol Buffers are a mechanism for serializing structured data.
- Protobuf is short for protocol buffers
- Protobufs are like XML but way smaller.
- They are extensible, when you start using them it's really easy to maintain backwards compatibility as you change things.
- You can use protobuf instead of sending JSON between microservices, or when you want to send structured data in your Kafka messages. It's a bit of a time investment initially, but it's worth it for typed messages.


## Probably unnecessary but interesting details
- Protobufs are an example of an IDL, an Interface Definition Language.
- IDLs are a way for two programs written in different languages to communicate with each other.
- What's the [difference between IDL and API](https://stackoverflow.com/questions/19437133/difference-between-api-and-idl)? An IDL is a language that can describe APIs, in a platform independent way.
- [Avro](https://en.wikipedia.org/wiki/Apache_Avro) is an IDL that uses JSON if that's more your jam.
- Protobufs were started in Google and are used in Google's internal communication between services. 
- Google uses an RPC infrastructure called Stubby to connect their zillions of servers. Stubby is google specific, but [gRPC](https://grpc.io/) is a generalized open-source RPC framework based on Stubby (and uses protobuf as default). If you see RPC/gRPC pop up a lot while researching protobufs, this is why.
- RPCs are much beyond the scope of this doc, but basically a way for machines to communicate with one another and execute procedures, and the calling and execution of procedures doesn't have to be in the same address space (a call one one machine can be executed on another machine in the same network). Great for highly distributed systems.
- Protobufs aren't compressed by default, but you can compress them with zip, gzip etc.
- Sometimes compression is sub-optimal for data in the form of JPEGs and PNGs, where JPEG/PNG compression will do a better job.
- When protobuf messages are serialized, the same data can have different binary representations, so you can't check for equality on serialized data.
- Marshalling is similar or synonymous to serialization, although there may be a slight difference between the two depending on the language or framework. 


# Protoc Setup
Go isn't actually one of the languages the protobuf compiler (protoc) supports by default, so you have to download a Go plugin, called `protogen-go`. There are two versions available, the `github.com` one is depreciated, so use the `google.com` one. We'll talk about this more later.


```bash
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
``` 


# Downloading protoc

Go to this web page:` https://github.com/protocolbuffers/protobuf/releases/` and look at the list of latest releases. Download the compressed file that applies to you. I am using Go and Ubuntu, so I downloaded `protoc-3.19.4-linux-x86_64.zip`, since as of now, `3.18.4` is the latest version.

Once you download it, unzip into a directory called protoc (that's what the -d flag is doing). But this is just for you, you can put this anywhere and name it anything.


```bash
unzip -d protoc/ protoc-3.19.4-linux-x86_64.zip
```
After unzipping, your protoc directory should look like this:

```bash
.
├── bin
│   └── protoc
├── include
│   └── google
│       └── protobuf
│           ├── .....
└── readme.txt
``` 
As advised by the `readme.txt`, copy the content of the include directory to `/usr/local/include` and the protoc binary to somewhere like `/usr/bin`.

```bash
sudo cp -r include/google /usr/local/include
sudo cp bin/protoc /usr/bin
```
The compiler, `protoc`, takes a `*.proto` file with protocol buffer definition in it and then generates the source code that you use with your applications code. I had a lot of problems with setting up `protoc`, all path related and really annoying and boring. So I instead did a quick hack, to get up and running quickly.

**If you have protoc working, skip the next section.**

# Resolving my protoc issues in kind of a gross way

I tried a slew of things, but I continued to have issues with `protoc` and paths to things. Since I have better things to do, I did this just to get up and running quickly. I have since changed things on my machine which maybe means I don't have to go this route anymore, but honestly who cares. This way I never have to care about my paths and all my `*.proto` files are together, and it's easy to move them where they need to be.
-  I created a directory (`/protobuf-generator`) where all my other Go repos live (I don't use `~/go` because I like making life harder for myself) 
- and to that I added `/github.com` (from `github.com/protocolbuffers/protobuf`, just for the example directory from the official tutorial),
- then I added `/google` (from `google.golang.org/protobuf/protec-gen-go`, the actual plugin),
-  and finally `protoc`, which is the compiler's executable binary.

Here's what all that looks like:
```bash
.
├── go-application
│   ├── go.mod
│   ├── go.sum
│   ├── main.go
│   └── proto-definitions
│       └── example.pb.go
└── protobuf-generator
    ├── example.pb.go
    ├── example.proto
    ├── github.com
    │   └── ......
    ├── google
    │   └── protobuf
    │       ├── ....
    └── protoc
```
So I create my protobuf generated classes directly in `protobuf-generator`, and then slap them into `go-application/proto-definitions`. I actually wrote a little bash script to make feel cleaner and to somewhat automate it. I called it something like `run_protoc.sh`, and it contains:
```bash
if protoc -I ./ --go_out=./ ./example.proto; then
	cp example.pb.go ../go-application/proto-definitions
	cp example.proto ../go-application/proto-definitions # so that .proto is in your app's repo
	echo "Protobufs Updated!"
else
    echo "Oopsie"
fi
``` 
To run it, `chmod` it (so it's executable) and then run like a regular script.
```bash
chmod a+x run_protoc.sh  # do this once
./run_protoc.sh   # do this whenever you update example.proto
```
And then for example, to reference the message definitions in `main.go` I have:
```go
import (
	"fmt"
	.
	.
	.
        "github.com/confluentinc/confluent-kafka-go/kafka"
        "google.golang.org/protobuf/proto"
        pb "github.com/mygithub/go-application/proto-definitions"
    )
```
Also `package` in `example.proto` should be set to whatever `proto-definitions` is actually called. And don't make `proto-definitons` a module.

And these are **not** the names I use!! Using something as generic as `/proto-definitons` is super frowned upon in Go, so choose something more specific and descriptive (like the name of your most relevant message definition).

To clarify  -- because this is a mess --  these are what the paths look like:
```
~/go/src/github.com/mygithub/go-application/proto-definitions
~/go/src/github.com/mygithub/protobuf-generator
```
And don't forget to double check your Go environment variables are correct and exist (don't ask me why I didn't just have this in my `.zshrc`, I don't have an answer. But they are in there now).
```bash
export GOROOT=/usr/local/go
export GOPATH=$HOME/<go-project-dir>
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOROOT:$GOPATH:$GOBIN
```
If you check `$GOBIN`, you should have the binary of the `protoc-gen-go` plugin.
So with all this you can generate protobuf classes and use types in your message definitions provided by protobuf, like `timestamp` (`"google/protobuf/timestamp.proto"`). And use the `example/tutorial` from the official protobuf/Go tutorial.

# Generating protobufs files (*.pb.go)

Creating `*.proto files` is easy and fun. The tutorial is really clear on this front. Here's an example from the official Go/protobuf tutorial, with all the essentials:

```
syntax = "proto3";
package tutorial;
import "google/protobuf/timestamp.proto";
option go_package = "./";
message Person {
  string name = 1;
  int32 id = 2;  // Unique ID number for this person.
  string email = 3;
  enum PhoneType {
    MOBILE = 0;
    HOME = 1;
    WORK = 2;
  }
  message PhoneNumber {
    string number = 1;
    PhoneType type = 2;
  }
  repeated PhoneNumber phones = 4;
  google.protobuf.Timestamp last_updated = 5;
}
// Our address book file is just one of these.
message AddressBook {
  repeated Person people = 1;
}
```
`option go_package` is where the generated class of (`<example>.pb.go`) will be output.
`package` will be the name of the folder where the `<example>.pb.go` file will live. If you are following what I've been doing it's `proto-definitions`. 

So now to compile:
```bash
protoc -I ./ --go_out=./ ./example.proto
```
- `-I` is the source directory
- `--go_out` is telling `protoc` you want go code, the directory where it should go

For the most part it's really easy, but I have not needed to do anything complex with them yet. For general information on defining message types see: https://developers.google.com/protocol-buffers/docs/gotutorial

>  💡 **for real, look at this:** [developers.google.com/protocol-buffers](https://developers.google.com/protocol-buffers/docs/gotutorial) It's explained really well.

And you're all done with setup, now you have your protobuf class ready and you can begin using protobufs within your project!

# Programming with protobufs

## Fields

You name your fields in `snake_case` and `protoc` will convert them to `CamelCase`. (This is what the style guide says to do).

For example: `my_field` becomes `MyField`

Also note that: `_my_Field` becomes `XMyField`

Nested messages are like the following:
```
message Foo {
		message Bar {}
}
// defines two structs: Foo, Foo_Bar
```
OneOf is pretty neat:
```
message Profile {
		oneof avatar {
				string image_url = 1;
				bytes image_data = 2;
		}
}
```
Dynamic length arrays:
```
message Example {
		repeated int32 lot_of_numbers = 1;
}
```
## Enums (defining and setting)
Defined like this:
```
message Convo {
	enum GreetingType {
	      HI = 0;
	      HELLO = 1;
	      HEY = 2;
	}
	Greeting my_greeting = 1; // this setting the tag, not the value
}
```
The have to have one at 0, because 0 is the default and everything must have a default value. It also has to be first.

Suppose you get some input/data from somewhere with "HELLO" in it, and that's what you want to set your enum field to, you can go this:

```go
data := "HELLO"
msg := &pb.Convo{}
msg.MyGreeting = pb.Convo_GreetingType(pb.convo_GreetingType_value[data])
fmt.Printf("I said: %s\n", msg.GetMyGreeting())
// output: I said: HELLO
```

## Printing messages
If you want to see everything that's in your message then do this:

```go
fmt.Printf("My Message:  %s\n",  proto.Message(msg)) 
// output: My Message: MyGreeting:HELLO
```

## Serializing Messages

```go
msg := &pb.ExampleType{}
// .... do some things with msg
buff, err := proto.Marshal(msg)
```

## Deserializing Messages

```go
serialized_data := // ..... 
msg := &pb.ExampleType{}
proto.Unmarshal(serialized_data, msg)
```


## Protobufs in Kafka messages

```go
// .................... 
// Subscriber
kafka_msg, err := consumer.ReadMessage()
my_example := &pb.ExampleType{}
proto.Unmarshal(msg.Value, my_example)
fmt.Printf("\n%s\n", proto.Message(my_example))
// Publisher
another_example := &pb.ExampleType{}
// do stuff with another_example
buff, err = proto.Marshal(another_example)
err = producer.Produce(&kafka.Message{ TopicPartition: my_partition,
                                            Value: buff},
                                            my_delivery_chan)
// .....................
```

# Protobuf on the frontend

I haven't done this yet, and it may be a while before I do. I am rewriting the backend of an app and I am going to use the corresponding frontend which expects JSON. This is actually maybe not a great idea to be honest because according to the `protojson` documentation, the conversion from `proto.Message` to `JSON` via `protojson.Marshal` is not stable, and it recommends to not rely on it. But anyhoo this is what I do:

```go
msg :=  // serialized Kafka message, it contains message with ExampleType structure

example := &pb.ExampleType{} 
err = proto.Unmarshal(msg.Value, example) // deserialize my Kafka message

// check for errors or something
json_message, err = protojson.Marshal(req) // convert to json in a byte array

// send json_message, which is of type []byte,  an array of bytes
```

I think this a good resource if you would like to send back protobuf messages instead: https://techblog.livongo.com/how-to-use-grpc-and-protobuf-with-javascript-and-reactjs/


# Protobuf and databases

This looks pretty cool if you want to use GORM (a popular Golang ORM) to store protobuf structures in a DB: https://github.com/infobloxopen/protoc-gen-gorm
