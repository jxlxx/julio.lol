---
title: Golang Essentials
date: "2022-09-11"
description: A short list of the essential things to know about golang to have a good time.
tldr: Channels, goroutines, waitgroups, contexts, and interfaces.
draft: false
tags: ["golang"]
---

# Background

Go was designed at Google. 
It is sometimes called Golang, but its official name is Go. 
Go is a statically typed, compiled, high-level language designed for concurrency.

One of the inventors of Go is Ken Thompson, the guy who invented the C programming language.
Go came about because Thompson and the others’ collective distaste for C++ 

**KT: Yes. When the three of us [Thompson, Rob Pike, and Robert Griesemer] got started, it was pure research. 
The three of us got together and decided that we hated C++. [laughter]**
source: [interview with KT](https://web.archive.org/web/20130105013259/https://www.drdobbs.com/open-source/interview-with-ken-thompson/229502480)

This post is intended to be a short reference to give programmers new to Go enough context to hit the ground running. 

Go is actually a very simple language (in a good way) so it's easy to get started if you have
some experience with any other typed and compiled language. I might even go as far as to say
that it is the easiest typed and compiled langauge to learn 😳

We will briefly talk about:

- [variables, imports](https://julio.lol/posts/go-essentials/#variables-and-imports)
- [error handling](https://julio.lol/posts/go-essentials/#error-handling)
- [goroutines (and `defer`)](https://julio.lol/posts/go-essentials/#goroutines)
- [channels (and `select`)](https://julio.lol/posts/go-essentials/#channels)
- [waitgroups](https://julio.lol/posts/go-essentials/#waitgroups)
- [contexts](https://julio.lol/posts/go-essentials/#contexts)
- [interfaces](https://julio.lol/posts/go-essentials/#interfaces)
- [project structure](https://julio.lol/posts/go-essentials/#project-structure)
- [gofmt (and `go.dev/play`)](https://julio.lol/posts/go-essentials/#variables-and-imports)

# Variables and imports

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

If you have unused variables or imports, go will complain and the build will fail. 
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

## Public and private functions

Exposed values from other modules have to start with a capital. For example:

```go
time.Sleep(...) // this is perfectly fine

time.sleep(...) // not allowed, that's for time to know about not you
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

# Goroutines

If you are using Go, you probably want to make use of concurrency. 
You can do this using goroutines, channels, and some other primitives that make life better. 

A **goroutine** is a thread managed by the go runtime. 

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

Before getting into channels, etc. I want to mention a very lovely keyword `defer`. The `defer` key word is placed before a function call and it “defers” the executing of the function until right before the function that it is being called in, returns. 

All the deferred functions will get executed in the reverse order that they were deferred. 
So if I defer function A and then defer function B, then right before the function returns, 
B will be executed and then A will be executed.

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

This means a goroutine which is sending things to a channel will not be “blocked” or forced to wait 
if if a channel is unbuffered. It can keep on adding things without being concern if those values are
 being read by any other thread. A buffered channel will stop accepting values if it is “full” so 
any goroutine that is trying to send to it will have to wait until there is space. Space is made 
in a channel by another goroutine reading (aka recieving) values from a channel. 

This is how you create channels: 

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

Link: [How to Gracefully Close Channels](https://go101.org/article/channel-closing.html)

For instance, the previous channel if we made messages an unbuffered channel, then we would get a 
fatal runtime error. This is due to:

```go
messages <- "hello" 
```

This line will block the execution of the rest of the code. 
Because this channel is capable of receiving more values it will just keep waiting forever, unless someone
reads from it.

If we wanted to make it unbuffered we would have to do something like:

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

The goroutine is blocked at `messages <- "hello"` until the for loop reads from it, 
then it can continue and close the channel. The for loop then tries to read from the channel again, 
sees that it is closed and moves along and `main` terminates. 

So we have to close the channel before the for loop loops again, either in the goroutine 
or right after printing the message in the loop,  or else it will get blocked, 
there will be a deadlock, and the program will crash. 

The for loop reads from the channel until it is closed, if we never send anything the program will 
crash because it will want to wait forever to receive a value. However, if we are sending within a 
goroutine that is called by main, it doesn’t matter because the go runtime will clean up for us, 
for example:

```go

package main

import "fmt"

func add_message_to_channel(messages chan string) {
  messages <- "hello"
  fmt.Println("this line will never execute, but the program won't crash")
}

func main() {
  messages := make(chan string)
  go add_message_to_channel(messages)
}

```

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
    go add_message_to_channel(messages) // this will close the channel, 
                      // so we will only ever read from it once
                      // (the message sent before the for loop starts)
  }
}

```

(This is gross looking but it’s just an example of how things work, not the best way to implement things).

## `select`

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

Note that when you are passing a waitgroup you must do it by reference, 
otherwise a new WaitGroup will be created if you try to pass by value and 
there is no point of doing that.

# Contexts

**Contexts** are another way to synchronise the behaviours of your goroutines. 

With contexts you can:

1. Add a time out, which signals to all the goroutines which have access to the context to wrap things up
2. Or just manually signal to all goroutines to wrap things up by cancelling the context

<aside>

💡 Note that you need to check if the context has actually expired or been cancelled, otherwise nothing happens.

</aside>

There are a few ways to to create a context: 

1. With a deadline (a timestamp at which point the context will expire), 
2. a timeout (a duration, which once elapsed after initialisation will cancel the context), 
3. or a context with a cancel function which if used will allow you to cancel the context manually when every you want. 
4. Or, none of these things (maybe you just need a dummy context for the moment)

[You can also pass values to contexts](https://pkg.go.dev/context#example-WithValue).

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

An interface is simple a collection of method signatures.

If a type has implemented every method in an interface, than it is said to “implement the interface”.

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

Another really common pattern is to use a `/cmd` directory of all the 'external' stuff. And `/internal` all you help functions/business logic etc.

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

## `go fmt`

Go has a formatting tool that is very helpful.

In your directory containing your go code, you can run `gofmt` to see what the formatter would like to change.

`gofmt -s` will also “simplify” your code

`gofmt -w` will actually write the changes to file instead of just `stdout`.

`gofmt -d` will display a diff to `stdout`.



## Go Playground

Another thing I recommend is using: [https://go.dev/play/](https://go.dev/play/)

It is a web service that will compile and run go code, which is convenient when testing small things. And it is very easy to share code with it, so I have found it to be really useful testing and debugging alone and with other people.

# References

- go routines ([https://gobyexample.com/goroutines](https://gobyexample.com/goroutines))
- channels ([https://www.ardanlabs.com/blog/2017/10/the-behavior-of-channels.html](https://www.ardanlabs.com/blog/2017/10/the-behavior-of-channels.html))
- waitgroups ([https://gobyexample.com/waitgroups](https://gobyexample.com/waitgroups))
- defer ([https://gobyexample.com/defer](https://gobyexample.com/defer))
- context ([https://www.ardanlabs.com/blog/2019/09/context-package-semantics-in-go.html](https://www.ardanlabs.com/blog/2019/09/context-package-semantics-in-go.html))


