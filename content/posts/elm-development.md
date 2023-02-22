---
title: Elm Development
date: "2022-12-20"
description: A brief guide on the basics of Elm development
draft: false
tags: ["elm"]
---


Elm might be my favourite language ever. 

Have I made anything important with it yet? 
No, but you could say that about all languages, idiot.


This may change in time, since I really only have a tiny amount of experience with it. 
But I have never felt so respected as a human being as I have with Elm. 

So here are the top resources with elm:

- [The Elm Guide - An Introduction to Elm](https://guide.elm-lang.org/)
- [Elm Single Page App - rtfeldman](https://github.com/rtfeldman/elm-spa-example)
- The documentation for the standard libraries


There is one very easy find and seemly popular resource which I will not name because I do not like it. 

Since there is a huge dearth of resources on Elm (considering how much *I* enjoy using it) I decided to quickly 
sketch out some of the more important things I've learned for the people.



# Getting your workspace ready

Call me crazy, but I don't like IDEs or even language servers usually. 
I consider this a personal failing and a hinderance to my career/potential, but it is what it is.

There are some exceptions, for example Flutter is torturous hell to develop on without some serious 
developer tooling (how the hell am I suppose to know what arguments an InkWell wants?), 
and I think only VSCode and JetBrains can actually do a decent job at the moment. 
But usually, I find it gets in the way. And in the case of the Elm language server, it almost killed my
shitty little computer so: 😡 (although it may have been [helix](https://helix-editor.com/) to blame)
(or my computeri, if we're being real).

Anyhoo, Elm is so simple and elegant, what do you need autocomplete for anyways?

However what is important is a development server. Since Elm is just a beautiful. perfect, angel language
which has to compile to filthy javascript. We need a way to serve that up to users.

I refuse to sully Elm with webpack and Node, so instead it is possible to actually just use


Nix shell

`elm live`


Making a script to run things






## Deciding on an Elm **`program`**

`sandbox`
Create a “sandboxed” program that cannot communicate with the outside world.


`element`
Create an HTML element managed by Elm. The resulting elements are easy to embed in larger JavaScript projects.

`document`
Create an HTML document managed by Elm. This expands upon what element can do in that view now gives you control over the <title> and <body>.


`application`
Create an application that manages Url changes. 




# Elm project structure





