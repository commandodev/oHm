{-# LANGUAGE CPP #-}
{-# LANGUAGE JavaScriptFFI #-}

module Ajax where

import GHCJS.Foreign
import GHCJS.Types

data XHR
data XHResponse
data Method = GET
type URL = String

#ifdef __GHCJS__
foreign import javascript unsafe
  "$r = new XMLHttpRequest();\
" xhr_ :: IO (JSRef XHR)

foreign import javascript interruptible
  "$1.onreadystatechange = function () {\
     if ($1.readyState === 4) {\
       $c($1.responseText);\
     }\
   };\
   $1.open('GET', $2, true);\
   $1.setRequestHeader('X-Requested-With', 'XMLHttpRequest');\
   $1.send()" get_ :: JSRef XHR -> JSString -> IO (JSString)
#endif

get :: URL -> IO (String)
get url =
  do xhr <- xhr_
     response <- get_ xhr (toJSString url)
     return (fromJSString response)
