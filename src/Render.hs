{-# LANGUAGE OverloadedStrings #-}
module Render (
    rootView
  ) where

import Control.Lens hiding (children)
import Francium.HTML
import Messages
import Prelude hiding (div,id,span,map)
import qualified Prelude as P
import Francium.DOMEvent

bootstrapEl :: String -> [HTML] -> HTML
bootstrapEl cls = with div (classes .= [cls])

bsCol :: Int -> [HTML] -> HTML
bsCol n = bootstrapEl $ "col-sm-" ++ (show n)

container, row, col3 :: [HTML] -> HTML
container = bootstrapEl "container"
row = bootstrapEl "row"
col3 = bsCol 3
--col9 = bsCol 9

mkButton :: (() -> IO ()) -> HTML -> [String] -> HTML
mkButton msgAction btnTxt classList = 
  with button
    (do
       classes .= ["button", "btn"] ++ classList
       onClick $ DOMEvent msgAction)
    [btnTxt]

countRender :: DOMEvent CountMessage -> Int -> HTML
countRender (DOMEvent sendCount) count =
  container
    [ with div (classes .= ["row"])
        [ with div (classes .= ["col-sm-3"])
            [ into strong
                [text $ show count]
            ]
        , with div (classes .= ["btn-group"])
            [ msgButton Decr "Dec" ["btn-danger"]
            , msgButton Incr "Inc" ["btn-success"]
            ]
        ]
     ]
  where msgButton msg =  mkButton (const $ sendCount msg)
          
msgRender :: (Name, Said) -> HTML
msgRender (name, said) =
  row
    [ col3 [into strong [text $ name ++ " said: "]]
    , col3 [into p $ [text said]]
    ]

messagesRender :: DOMEvent ChatMessage -> ChatModel -> HTML
messagesRender chan (ChatModel msgs name currentMsg) =
  container
    (P.map msgRender msgs ++ [textBoxRender name currentMsg chan])
  

textBoxRender :: Name -> String -> DOMEvent ChatMessage -> HTML
textBoxRender name currentMsg saidEvent@(DOMEvent chan) =
  with form (classes .= ["form-inline row"])
    [ with div (classes .= ["form-group col-sm-3"])
        [ with label (classes .= ["form-control-static"])
            [ text $ "Got Something to say " ++ name ++ "?"]
        ]
    , with div (classes .= ["form-group col-sm-6"]) 
        [ with input (do
            classes .= ["form-control"]
            attrs . at "placeholder" ?= "Enter Message"
            attrs . at "value" ?= (toJSString currentMsg)
            onInput $ contramap Typing saidEvent)
            []
        ]
      , mkButton sendMessage "Send Message" ["btn-primary"]
    ]
  where addName said = EnterMessage (name, said)
        sendMessage = const $ chan (addName currentMsg)
        
rootView :: DOMEvent Message -> AppModel -> HTML
rootView chan (AppModel chatModel count) =
  container
    [ with nav (classes .= ["nav", "navbar", "navbar-default"])
       [with div (classes .= ["navbar-brand"])
         ["Demo"]]
                  
    , countRender (contramap Count chan) count
    , messagesRender (contramap Chat chan) chatModel
    ]
