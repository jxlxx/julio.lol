---
title: Go Essentials
date: "2022-09-11"
description: A short list of the essential things to know about Go to have a good time.
tldr: Channels, goroutines, waitgroups, contexts, and interfaces.
draft: false
tags: ["go"]
---

# Background

Go was designed at Google. 
It is sometimes called Golang, but its official name is Go. 
However, if you are looking up any documentation/StackOverflow stuff you will most likely have to say Golang instead of just Go.

Go is a statically typed, compiled, high-level language designed for concurrency.
One of the inventors of Go is Ken Thompson, the guy who invented the C programming language.
Go came about because Thompson and the others’ collective distaste for C++. Here is a quote from the guy:

**KT: Yes. When the three of us [Thompson, Rob Pike, and Robert Griesemer] got started, it was pure research. 
The three of us got together and decided that we hated C++. [laughter]**
source: [interview with KT](https://web.archive.org/web/20130105013259/https://www.drdobbs.com/open-source/interview-with-ken-thompson/229502480)

This post is intended to be a short reference to give programmers new to Go enough context to hit the ground running. 

Go is actually a very simple language (in a good way) so it's easy to get started if you have
some experience with any other typed and compiled language. I might even go as far as to say
that it is the easiest typed and compiled langauge to learn these days 😳

We will briefly talk about:

0. [a simple `hello, world` example](https://julio.lol/posts/go-essentials/#hello-shi-jie)
1. [packages and modules](https://julio.lol/posts/go-essentials/#packages-and-modules)
2. [functions, methods, variables](https://julio.lol/posts/go-essentials/#defining-functions-methods-and-variables)
3. [error handling](https://julio.lol/posts/go-essentials/#error-handling)
4. [goroutines (and `defer`)](https://julio.lol/posts/go-essentials/#goroutines)
5. [channels (and `select`)](https://julio.lol/posts/go-essentials/#channels)
6. [waitgroups](https://julio.lol/posts/go-essentials/#waitgroups)
7. [contexts](https://julio.lol/posts/go-essentials/#contexts)
8. [interfaces](https://julio.lol/posts/go-essentials/#interfaces)
9. [project structure](https://julio.lol/posts/go-essentials/#project-structure)
10. [gofmt (and `go.dev/play`)](https://julio.lol/posts/go-essentials/#variables-and-imports)


# Hello, 世界!

First, let's have a quick look at a simple `hello world` program in Go. 
You can go to [https://go.dev/play/](https://go.dev/play/) to run it yourself.

```go

package main

import "fmt"

func main() {
    fmt.Println("Hello, 世界")
  }
	
```

There are 4 details that leap out at us immediately and lead to some natural questions.

1. We are looking at a **package** called `main` *(what is a package?)*
2. We are **importing** something called `fmt` *(what is `fmt`?)*
3. We are **defining** a function called `main` *(is there something special about the name `main`?)*
4. We **calling** a function from `fmt` called `Println` *(why is is capitalized?)*

Let's start with answering those 4 burning questions, and then we will get into concurrency and other fancy stuff.

# Packages and modules

Go projects are composed of **packages**  and **modules**.

A package is a directory of Go files (`*.go`) that do something and are somehow related (ideally, but I guess you can do whatever you want).
All the files in a package contain the line: `package package_name`. In this case we have a `main` package,
probably defined in a file called `main.go`.

> 💡 You can search for publicly available packages here: [pkg.go.dev](https://pkg.go.dev/) 

A **module** is a collection of one or more go packages that is versioned and has dependencies.


A module is identified by a **module path**, which is the *canonical name* for the module.
Module paths usually have two parts to them, the path part and the name part.
The path part specificies where the module is being imported from, of the module and the *name* is the just the name of the module.

For example, the Gin web framework has a module path: `github.com/gin-gonic/gin`
The package is called `gin` and the code repository is hosted at `https://github.com/gin-gonic/gin`.

But unless you are writing some open source Go software (in which case you really don't need to be reading this article), you don't have to 
worry about the path part. Many tutorials tell you to use `github.com/<your_username>/<package_name>`, but it's not at all necessary when you are just learning
or working on your own small projects. This is the suggested path because it will prevent path collisions with other peoples packages when you are a wildly successful
open source dev. 

However, your machine and the Go compiler need to know where you are keeping your go code and your imported packages. 
This information is stored in the `$GOPATH` environment variable. You can see all Go related environment variables with `go env`.

According the Go website, Go developers *usually* keep all their Go code/projects in own directory called a **Workspace** (I do not. Ever heard of Nix, you nerds?).

For example, the workspace of a professional Go developer might look like this:

```
.
├── pkg // contains compiled go packages that are
│       // later used to create binary executable in bin
│
├── bin
│   ├── company_app
│   └── personal_project
│
└── src
    ├── github.com/my_company_github/company_app
    │   ├── .git
    │   └── ... go code
    │   
    └── github.com/my_github/personal_project
        ├── .git
        └── ... go code
      
```

And the `$GOPATH` should be set to that directory. 

> 💡 There is some information on structuring individual Go projects here: [# project structure](https://julio.lol/posts/go-essentials/#project-structure)

Anyways, back to modules.

Modules usually must have have a `go.mod` file, which defines the module path and the modules direct and indirect dependencies.
(Technically, you don't *need* to have one, but I cannot think of a good reason why you wouldn't).
The `go.mod` file is not meant to be created or edited by humans, although it is intended to be readable. 
There are lost of commands to work with `go.mod` files, but the two important ones are `go mod init` and `go mod tidy`

`go mod init` creates a module and generates `go.mod` file in your current repository. 
You can also optionally specify a module path like this: `go mod init some/module/path` 

`go mod tidy` will look at the import statements in your code and add new dependencies and remove dependencies that are no longer needed.

> 💡 Here are some other things you can go with `go mod`: [go.dev/ref/mod](https://go.dev/ref/mod)

Modules also usually have a `go.sum` file, which conatins cryptographic hashes of the modules' direct and indirect dependencies.

So in the end we have something like:

```
.
└── hello-world
   ├── main.go
   ├── go.mod
   └── go.sum

```


Is the word `main`, special? Yes, from the [Go language specification](https://go.dev/ref/spec#Program_execution): 
 
> A complete program is created by linking a single, unimported package called the main package with all the packages it imports, transitively.
The main package must have package name main and declare a function main that takes no arguments and returns no value.

> Program execution begins by initializing the main package and then invoking the function main. When that function invocation returns, 
the program exits. It does not wait for other (non-main) goroutines to complete.

## The `fmt` package

The `fmt` ("format") package is an I/O package in the Go standard library.

It defines functions analogous to C's `printf` and `scanf`.

# Defining functions, methods and variables

This is how you define a function in Go:

```go
func hello() {
  // ... code ...
}
```

This is how you specify arguments:

```go
func hello(name string, age int) {
  // ... code ...
}
```

You can also be cool and do this:

```go
func hello(first_name, last_name string, age int) {
  // ... code ...
}
```

This is how specify return types:


```go
func hello() string {
  // ... code ...
}

// for multiple values, you need braces
func hello_maybe() (string, error) {
  // ... code ...
}
```

There are two ways to define methods:

```go
struct Server {
  // ... fields
}


func (s Server) hello_value_reciever() {
   // doing some stuff 
}

func (s *Server) hello_pointer_reciever() {
  // doing some stuff and maybe changing things in s
}
```

The reason you would you use `(s *Server)`, AKA a **pointer reciever**, is that it will allow you to make changes to the
caller, whereas you cannot change anything inside the caller if you are using a **value reciever**.


## Public and private functions

Exposed values from other modules have to start with a capital. For example:

```go
fmt.Println(...) // this is perfectly fine :)

fmt.padString(...) // not allowed, that's for `fmt` to know about, not you
```

This is also true for structs:


```go

type Server struct {
  secret string
  NonSecret string  
}

```


## Variables and underscores

There are two ways to declare variables. Explicitly saying the type or not saying the type and letting the compiler figure it out.

```go
var x int // explicit
x := 1    // implicit
```

The `:=` means that the variable is being declared, aka set for the first time. When you are reassigning the value you do not use the colon.

```go
y := "something"
y = "another thing"
```

If you have unused variables or imports, Go will complain and the build will fail. 
But while developing you can get around this by using underscores. 

```go
// don't use the colon, because nothing is being declared.
_ = some_function()

// Or, if you want one of the returned values
_, used_var := another_function()
```


Also, you can use this technique to silence the unused imports error:

```go
import _ "fmt" // i'll use this later
```

You can also rename the packages:

```go
import api "https://github.com/jxlxx/superlongpackagename"
import other_api "https://github.com/jxlxx/superlongpackagename2"
```

And also, you only need to say `import` once:

```go
import (
    "time"
    "fmt"
    "context"
    )
```


# Error Handling

Typically in Go, you will see a pattern with errors over and over again.

Functions return: 
- the value you want 
- and maybe an error

By *maybe* I mean it will either return `nil` or an `error`.

```go

SomeFunction (yourstring string) (string, error) {
  if (yourstring == "good string") {
    return "thanks, that's a good string", nil	
  } 
  // bad string
  return "", errors.New("No thanks, bad string")
}

```

Then, when you call a function you can either ignore the error 
(perhaps you know that the default value is fine) or handle it in some way:

```go

response, err := SomeFunction("good string")

if err != nil {
  // here you will usually do something in response to the error and the
  // function will return early
  fmt.Println("an error!!!")
  return
}
// here you know that err == nil, so you can proceed with response
fmt.Println(response)

```

This has a tendency to make your functions really long, but that's okay.


# Goroutines

If you are using Go, you probably want to make use of concurrency. 
You can do this using goroutines, channels, and some other primitives that make life better. 

A **goroutine** is a thread managed by the Go runtime. 

This is how you call a goroutine with no name:

```go

go func() {
  // do stuff
}()

```

And this is how you call a goroutine with a name:

```go

package main

import (
  "fmt"
  "time"
)

func main() {
  go sleep_and_print(5, "this is called first but printed last")
  go sleep_and_print(1, "this is called last but printed first")

  time.Sleep(10000)
}

func sleep_and_print(x int, y string) {
  time.Sleep(time.Duration(x * 1000))
  fmt.Println(y)
}

```

Isn't that nice?

In the above code we had to call `time.Sleep(10000)` at the end of main because 
after the goroutines are called the main function keeps executing and exits without 
checking on whether the goroutines terminated or not. 

Since go routines are managed by the go runtime, they are terminated when they return 
or when the program it’s self exits (`main` in this case). 

Obviously, a sleep function is a terrible way to ensure 
that our functions get executed. To communicate across goroutines we can make use of 
**channels** and **waitgroups**.

Is it possible for goroutines to leak? Yes.

There are many techniques to monitor for goroutine leaks, but I wouldn’t say that they are 
essential to get started with Go. 
[But here is something you can read, if you wish.](https://jvns.ca/blog/2017/09/24/profiling-go-with-pprof/#:~:text=pprof%20basics&text=The%20normal%20way%20to%20use,pprof%20to%20analyze%20said%20profile)

## Defer

Before getting into channels, etc. I want to mention a very lovely keyword `defer`. The `defer` keyword is 
placed before a function call and it “defers” the executing of the function until right before the function that it is being called in, returns. 

All the deferred functions will get executed in the reverse order that they were deferred. 
So if I defer function A and then defer function B, then right before the function returns, 
B will be executed and then A will be executed.

First Deferred, Last Executed. 

```go

package main

import (
  "fmt"
)

func main() {
  defer fmt.Println("A - deferred first")
  defer fmt.Println("B - deferred second")

  fmt.Println("C - first")
  fmt.Println("D - second")
}

// Output: 
// C - first
// D - second
// B - deferred second
// A - deferred first

```

`defer` is very useful when using channels as well, which we will get into soon.

# Channels

A **channel** is a place to send and receive values in a way that is accessible to multiple goroutines.

You can have two kinds of channels: **buffered** and **unbuffered**.

An **unbuffered channel** means that you do not set a size limit when creating it, and it can grow freely.

A **buffered channel** means that you give it a limit on how large in can grow when you declare it. 

This is how you create both kinds of channels: 

```go
unbuffered_channel := make(chan string)

buffered_channel := make(chan string, 2)

message_channel := make(chan Message) // perhaps I have a Message struct
```


This is how you read and write from channels:

```go

package main

import (
  "fmt"
)

func main() {

  messages := make(chan string, 1)

  messages <- "hello"                // adding a message to the channel
  recieved_message, ok := <-messages // receiving a message from a channel

  if ok {
    fmt.Println(recieved_message)
  }
}

```

You can close channels like this:

```go
close(messages)
```

However, you do not always have to close channels. They are not like files. You close channels as a 
way to say to the goroutines using them that there are no more values that are going to be sent to 
the channel. 

> 💡 Link: [How to Gracefully Close Channels](https://go101.org/article/channel-closing.html)


Buffered channels are also called **asynchronous channels**.

And unbuffered channels are also called **synchronous channels**.

Why? Well suppose  we made messages an unbuffered channel in the previous example, like this:

```go

package main

import (
  "fmt"
)

func main() {

  messages := make(chan string)

  messages <- "hello"                // adding a message to the channel
  recieved_message, ok := <-messages // receiving a message from a channel

  if ok {
    fmt.Println(recieved_message)
  }
  
}

// fatal error: all goroutines are asleep - deadlock!

```


If we ran this code we would get a fatal runtime error. This is due to the line:

```go
messages <- "hello" 
```

This line will block the execution of the rest of the code. 

Receivers (`im_a_reciever<-`) always block and wait until there is data to recieve.

Once the receiver begins recieving data, the sender blocks (`<-im_a_sender`):
- If the channel is unbuffered, the sender blocks **until a receiver has read from the channel**.
- If the channel is buffered, it will only wait **until the value is copied to the buffer**. If the buffer is full, it must wait until
    a reciever has read from the channel and "freed up some space" for more data.

This is why buffered channels are considered *asynchronous*, because they facilitate asynchonous communication among goroutines, since the
goroutines don't need to consider if someone is reading what they are saying. They just go about their business.

If we wanted to make the channel unbuffered, we could do something like this:

```go

package main

import "fmt"

func main() {
  messages := make(chan string)

  go func() {
    messages <- "hello"
    close(messages)
  }()

  for i := range messages {
    fmt.Println(i)
  }

}

```

We start a goroutine that begins the message `"hello"` to our channel. Since the channel is unbuffered, it is blocked until someone reads from the channel.

At "the same time", we start a for loop the is looking at `messages`. It will keep trying to read from the `messages` channel, until it is closed.

Once the goroutine writes `"hello"` to `messages`, the for loop proceeds to give us `i`, which is the value in the channel, `"hello"` and we can print it with `fmt`.

Now that `"hello"` was read, the goroutine can proceed to the next step of executing, closing the channel, which which also terminal the for loop and thus terminate `main` successfully.


Here is an example where we don't close the channel, but it doesn't crash the program:

```go

package main

import "fmt"

func add_message_to_channel(messages chan string) {
  messages <- "hello"
  fmt.Println("woo hoo recursion")
  add_message_to_channel(messages)
}

func main() {
  messages := make(chan string)
  go add_message_to_channel(messages)
  fmt.Println(<-messages)
}

```

Because the blocking is happening in a goroutine and not in `main`, the Go runtime doesn't care if the goroutine is 
doing something and will just kill it once main is done. In theory, Go will clean up for you, but this is ugly. 
Perhaps don't do stuff like this.

You could use `defer` to close channels once a function is done with them:

```go

package main

import "fmt"

func add_message_to_channel(messages chan string) {
  defer close(messages) // once we read one message from messages (causing the 
                        // function to close and return) we will never be able
                        // to read from it again
  messages <- "hello"
}

func main() {
  messages := make(chan string)
  go add_message_to_channel(messages)
  for i := range messages {    
    fmt.Println(i)
  }
}

```


## **`select`**

A critical keyword for working with channels is the `select` keyword.

The `select` keyword is like a special switch case for channels which allows you to look at multiple 
channels at once and act of the first one to receive a value. 

```go

// original: https://gobyexample.com/select
// but I modified a bit
package main

import (
  "fmt"
  "time"
)

func main() {

  c1 := make(chan string)
  c2 := make(chan string)

  go func() {
    time.Sleep(2 * time.Second)
    c1 <- "send this after 2 seconds"
  }()

  go func() {
    time.Sleep(1 * time.Second)
    c2 <- "send this after 1 second"
  }()

  for i := 0; i < 2; i++ {
    select {
    case msg1 := <-c1:
      fmt.Println("case 1:", msg1)
    case msg2 := <-c2:
      fmt.Println("case 2:", msg2)
    }
  }
}

// Output:
// case 2: send this after 1 second
// case 1: send this after 2 seconds

```

# WaitGroups

A `WaitGroup` is a really simple idea but really powerful. It allows you to safely control the 
behaviour of your goroutines in a really clean way.

A `WaitGroup` is really just a fancy counter that allows you to stop you code from 
executing at a certain point until that counter reaches 0. 

You instantiate a counter like this:

```go
var wg sync.WaitGroup
```

Add to it like this:

```go
wg.Add(1)
```

Decrement like this:

```go
wg.Done()
```

and wait like this:

```go
wg.Wait()
```

Usually, WaitGroups are used combination with defer and goroutines to wait until all the goroutines
have finished executing. For example:

```go

// source: https://gobyexample.com/waitgroups

package main

import (
  "fmt"
  "sync"
  "time"
)

func worker(id int) {
  fmt.Printf("Worker %d starting\n", id)
  time.Sleep(time.Second)
  fmt.Printf("Worker %d done\n", id)
}

func main() {

  var wg sync.WaitGroup

  for i := 1; i <= 5; i++ {
    wg.Add(1)

    i := i

    go func() {
     defer wg.Done()
     worker(i)
    }()
  }

  wg.Wait()

}

// Output: 
// (Note that the order may change each time you run the program)
// Worker 5 starting
// Worker 2 starting
// Worker 1 starting
// Worker 3 starting
// Worker 4 starting
// Worker 1 done
// Worker 3 done
// Worker 2 done
// Worker 5 done
// Worker 4 done

```

> 💡 Note that when you are passing a waitgroup you must do it by reference, 
otherwise a new WaitGroup will be created if you try to pass by value and 
there is no point of doing that!!

# Contexts

**Contexts** are another way to synchronise the behaviours of your goroutines. 

With contexts you can:

1. Add a time out, which signals to all the goroutines which have access to the context to wrap things up
2. Or just manually signal to all goroutines to wrap things up by cancelling the context


> 💡 Note that you need to check if the context has actually expired or been cancelled, otherwise nothing happens.


There are a few ways to to create a context: 

1. With a deadline (a timestamp at which point the context will expire), 
2. a timeout (a duration, which once elapsed after initialisation will cancel the context), 
3. or a context with a cancel function which if used will allow you to cancel the context manually when every you want. 
4. Or, none of these things (maybe you just need a dummy context for the moment)

> 💡 [You can also pass values to contexts](https://pkg.go.dev/context#example-WithValue).

```go

// source: https://pkg.go.dev/context#example-WithTimeout

package main

import (
  "context"
  "fmt"
  "time"
)

const shortDuration = 1 * time.Millisecond

func main() {
  // Pass a context with a timeout to tell a blocking function that it
  // should abandon its work after the timeout elapses.
  ctx, cancel := context.WithTimeout(context.Background(), shortDuration)
  defer cancel()

  select {
  case <-time.After(1 * time.Second):
    fmt.Println("overslept")
  case <-ctx.Done():
    fmt.Println(ctx.Err()) // prints "context deadline exceeded"
  }

}

// Output:
// context deadline exceeded

```

# Interfaces

> Accept Interfaces, Return Structs - Jim
> 

Interfaces in go are essential.

An **interface** is a collection of method signatures.

If a type has implemented every method in an interface, than it is said to “*implement the interface*”.

Typically, you want interfaces to be small. You want them to be *easy* to implement.

The reason you might want to use an interface is that you want to use different types as
 arguments to a function. 

```go

// source: https://gobyexample.com/interfaces

package main

import (
    "fmt"
    "math"
)

type geometry interface {
    area() float64
    perim() float64
}

type rect struct {
    width, height float64
}
type circle struct {
    radius float64
}

func (r rect) area() float64 {
    return r.width * r.height
}
func (r rect) perim() float64 {
    return 2*r.width + 2*r.height
}

func (c circle) area() float64 {
    return math.Pi * c.radius * c.radius
}
func (c circle) perim() float64 {
    return 2 * math.Pi * c.radius
}

func measure(g geometry) {
    fmt.Println(g)
    fmt.Println(g.area())
    fmt.Println(g.perim())
}

func main() {
    r := rect{width: 3, height: 4}
    c := circle{radius: 5}

    measure(r)
    measure(c)
}

```

## Interfaces for testing

Interfaces also make unit testing a lot easier.

For example, maybe I will have an interface call `DatabaseClient` like so:

```go
interface DatabaseClient {
	ReadFromDB(string) (string, error)
	WriteToDb(string, string) error
}
```

And then I can create two types which both implement the interface: `RealDBClient`and `MockDBClient`.

```go
(s *RealDBClient) ReadFromDB(str string) (string, error) {
	// ...
}

(s *RealDBClient) WriteToDb(str, str2 string) (error) {
	// ...
}

(s *MockDBClient) ReadFromDB(str string) (string, error) {
	// ...
}

(s *MockDBClient) WriteToDb(str, str2 string) (error) {
	// ...
}
```

Now I can thoroughly and reliably test my database client implementation.

# Project Structure

Go projects have modules and packages.

This is the basic structure for a Go web app.

```
.
└── app-name
    │
    ├─── go.mod
    ├─── go.sum
    │
    ├── main.go
    │
    └─── packages
      ├── package-1
      │   ├── handlers.go
      │   └── handlers_test.go
      └── package-2
          ├── handlers.go
          └── handlers_test.go

```

app-name, whatever it is, is a module. 

Typically you would have all your server code in `main.go`, and everything else in `/packages`.

Another really common pattern is to use a `/cmd` directory of all the 'external' stuff. And `/internal` all your helper functions/business logic etc.

```
.
└── app-name
    │
    ├─── go.mod
    ├─── go.sum
    │
    ├─── cmd
    │   └── main.go
    │
    └─── internal
      ├── package-1
      │   ├── handlers.go
      │   └── handlers_test.go
      └── package-2
          ├── handlers.go
          └── handlers_test.go

```

It's okay to have files that are a thousand lines plus. Have you seen the error handling? c'mon.

# Other

## **`go fmt`**

Go has a formatting tool that is very helpful.

In your directory containing your Go code, you can run `gofmt` to see what the formatter would like to change.

`gofmt -s` will also “simplify” your code

`gofmt -w` will actually write the changes to file instead of just `stdout`.

`gofmt -d` will display a diff to `stdout`.



## Go Playground

Another thing I recommend is using: [https://go.dev/play/](https://go.dev/play/)

It is a web service that will compile and run Go code, which is convenient when testing small things. 
And it is very easy to share code with it, so I have found it to be really useful testing and debugging alone and with other people.

# References 

- go routines ([gobyexample.com/goroutines](https://gobyexample.com/goroutines))
- channels ([Arden Labs - The behavior of channels](https://www.ardanlabs.com/blog/2017/10/the-behavior-of-channels.html))
- waitgroups ([gobyexample.com/waitgroups](https://gobyexample.com/waitgroups))
- `defer` ([gobyexample.com/defer](https://gobyexample.com/defer))
- `context` ([Ardan Labs - Context package semantics in go](https://www.ardanlabs.com/blog/2019/09/context-package-semantics-in-go.html))
- best practices and smarter explainations ([Effective Go](https://go.dev/doc/effective_go))
  - this doc has been froxen since January 2022, but I still like it
- [Go language spec](https://go.dev/ref/spec)
  - very nice reading








