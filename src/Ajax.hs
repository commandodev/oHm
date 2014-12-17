{-# LANGUAGE CPP #-}
{-# LANGUAGE JavaScriptFFI #-}
{-# LANGUAGE OverloadedStrings #-}

module Ajax where

import Control.Monad
import GHCJS.Foreign
import GHCJS.Types
import Pipes.Concurrent

import XHRIO

type URL = String

get :: URL -> Output String -> IO ()
get url output =
  do xhr <- xhr_
     let action response = void $ atomically $ send output (fromJSString response)
     js_callback <- syncCallback1 AlwaysRetain False action
     get_ xhr (toJSString url) js_callback

post :: URL -> Output b -> a -> IO ()
post = undefined
