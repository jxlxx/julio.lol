---
title: Golang Essentials
date: "2022-09-11"
description: A short list of the essential things to know about golang to have a good time.
tldr: Channels, goroutines, waitgroups, contexts, and interfaces.
draft: true
tags: ["golang"]
---


# Background

- go was created by some  guys at google and others
- the guy who invented c
- claim to fame is concurrency	
- staticly typed

# Goroutines

```go
go func () {
	// do stuff
}
```


# Channels

What exactly is a channel

You can have two kinds of channels: buffered and unbuffered.

this is how you read and write to a channel

Channels are really useful to make goroutines able to sort of share information with eachother


# WaitGroups

A waitgroup is a really simple idea but really powerful. It allows you to safely control the behaviour of your goroutines in a really clean way.


# Contexts

Contexts are another way to control the behaviours of you goroutines

adding a time out

you need to check if the context has actually expired or been cancelled, otherwise nothing happens

force a cancellation



# Interfaces

> Accept Interfaces, Return Structs - Jim

Interfaces in go are essential

an example of how you can use an interface for testing



# Project Structure

A basic structure for a golang web app.

```bash
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

app-name, whatever it is, is a module. Typically you would have all your server code in `main.go`, and everything else in `/packages`.

Another really common pattern is to use a `cmd` directory of all the 'external' stuff.

```bash
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


It's okay to have files that are a thousand lines plus. 









