
# oHm Om with Haskell in the middle

Om is awesome. oHm is a hommage to Om in GHCJS using Haskell's pipes,
mvc and pipes-concurrent libraries.

## Introduction

Ohm at its core is the idea of building an application as a pure left
fold over a stream of events. At a previous position we built a UI
that captured this model in clojurescript and Om, this is a port of
that architectural idea to Haskell.

### Set up

### Concepts

1.  Models

    Models are the state of your application. Here's the Model from the
    todo mvc example mentioned later:
    
    1.  State
    
            data ToDo = ToDo
              { _items :: [Item]
              , _editText :: String
              , _filter :: Filter
              } deriving Show
        
        In addition to the model you also need a updating function of type
        `mdlEvent -> model -> model` which is a left fold function that
        applies a to the Model resulting in the new Model. This
        function is one of the things you need to construct a .
    
    2.  Fold
    
        Here's the model function from our todo mvc example:
        
            process :: Action -> ToDo -> ToDo
            process (NewItem str) todo = todo &~ do
               items %= (Item str False:)
               editText .= ""
            process (RemoveItem idx) todo = todo & items %~ deleteAt idx
            process (SetEditText str) todo = todo & editText .~ str
            process (SetCompleted idx c) todo = todo & items.element idx.completed .~ c
            process (SetFilter f) todo = todo & filter .~ f
        
        Note that MVC, one of the libraries that oHm is built on has a concept
        of a model too. In MVC Model refers to the pure transformation that
        happens within a Pipe and applies an event to the state to produce a
        new state. In oHm construction of an MVC Model happens with the
        `appModel` function that the `runComponent` function applies for you.

2.  Model Events

    Model Events represent events that happen in your domain to effect
    change to the state of the world. This is the `Action` type mentioned
    in the event -> model -> model function earlier:
    
        
        data Action
          = NewItem String
          | RemoveItem Index
          | SetEditText String
          | SetCompleted Index Bool
          | SetFilter Filter

3.  UI Events

    UI Events occur at the points of interaction between user and your
    app. These are the sorts of things that you'd attach callbacks to:
    changes, clicks, mouse moves etc.

4.  Processors

    Processors consume events of one type, say UI Events and produce
    Events of another type, with the ability to perform actions in some
    Monad. These are used to process the UI Events that a Component emits
    into a form that that component's model can use to update its state.

5.  Renderers

6.  Components

## Examples

### Todo MVC

<http://todomvc.com/>
The canonnical TODO MVC example demonstrates the basic moving parts of
oHm

### Socket.IO Chat

The socket.io example is a bit more involved and adds some new
concepts illustrating nesting components by adapting the types of processors
