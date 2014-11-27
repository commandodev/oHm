{-# LANGUAGE CPP #-}
{-# LANGUAGE JavaScriptFFI #-}

module Ajax where

import Control.Monad
import GHCJS.Foreign
import GHCJS.Types
import Pipes.Concurrent

data XHR
data XHResponse
data Method = GET
type URL = String

#ifdef __GHCJS__
foreign import javascript unsafe
  "$r = new XMLHttpRequest();\
" xhr_ :: IO (JSRef XHR)

-- TODO There's a retain issue here.  $1 can have been cleaned up by the time $c is called.
foreign import javascript unsafe
  "$1.onreadystatechange = function () {\
     if ($1.readyState === 4) {\
       $3($1.responseText);\
     }\
   };\
   $1.open('GET', $2, true);\
   $1.setRequestHeader('X-Requested-With', 'XMLHttpRequest');\
   $1.send()" get_ :: JSRef XHR -> JSString -> (JSFun (JSString -> IO ())) -> IO ()

#endif

get :: URL -> Output String -> IO ()
get url output =
  do xhr <- xhr_
     let action response = void $ atomically $ send output (fromJSString response)
     js_callback <- syncCallback1 AlwaysRetain False action
     get_ xhr (toJSString url) js_callback
