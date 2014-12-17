{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE InterruptibleFFI #-}
{-# LANGUAGE RecordWildCards #-}
module XHRIO where

import Control.Arrow
import Control.Concurrent.STM
import Control.Monad (void)
import Data.Aeson (ToJSON, FromJSON)
import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Char8 as C8
import qualified Data.ByteString.Lazy as BSL
import Pipes.Concurrent (Output(..))
import Data.Maybe
import Data.List.Split
import Control.Applicative
import Data.Foldable (for_)
import GHCJS.Foreign
import GHCJS.Types

data Request = Request
  { rqWithCredentials :: Bool
  , rqURL :: String
  , rqMethod :: Method
  , rqHeaders :: [(String, String)]
  , rqPayload :: Maybe JSString
  }

mkRequest :: (ToJSON a) => Method -> String -> a -> Request
mkRequest meth url a = Request 
  { rqWithCredentials = False
  , rqURL = url
  , rqMethod = meth
  , rqHeaders = []
  , rqPayload = Just (toJSString . C8.unpack . BSL.toStrict $ Aeson.encode a)
  } 
    
data Method = GET | POST | DELETE | PUT deriving (Eq, Show)

instance ToJSString Method where
  toJSString = toJSString . show

data Response = Response { resStatus :: Int
                         , resHeaders :: [(String, String)]
                         , resText :: String
                         }

request :: Request -> IO Response
request Request{..} = do
  xhr <- jsNewXHR
  jsXHROpen xhr (toJSString rqMethod) (toJSString rqURL)
  jsXHRSetWithCredentials xhr (toJSBool rqWithCredentials)
  for_ rqHeaders $ \(k, v) -> jsXHRSetRequestHeader xhr (toJSString k) (toJSString v)
  jsXHRSend xhr (fromMaybe jsNull rqPayload)
  Response
   <$> jsXHRGetStatus xhr
   <*> (map (second (drop 2) . break (== ':')) . splitOn "\r\n" . fromJSString
          <$> jsXHRGetAllResponseHeaders xhr)
   <*> (fromJSString <$> jsXHRGetResponseText xhr)

--------------------------------------------------------------------------------
data XHR

foreign import javascript unsafe
 "$r = new XMLHttpRequest();\
 \$r.latestProgressMessage = null;\
 \$r.awaitingProgress = null;\
 \$r.incrementalPos = 0;\
 \$r.err = null"
 jsNewXHR :: IO (JSRef XHR)

foreign import javascript unsafe
 "$1.withCredentials = $2;"
  jsXHRSetWithCredentials :: JSRef XHR -> JSBool -> IO ()

foreign import javascript unsafe
 "$1.open($2, $3, true);"
  jsXHROpen :: JSRef XHR -> JSString -> JSString -> IO ()

foreign import javascript unsafe
 "$1.setRequestHeader($2, $3);"
  jsXHRSetRequestHeader :: JSRef XHR -> JSString -> JSString -> IO ()

foreign import javascript interruptible
 "$1.onload = function(e) { $c(); };\
 \$1.onerror = function(e) { $1['h$err'] = true; $c(); };\
 \$1.send($2);"
 jsXHRSend :: JSRef XHR -> JSRef a -> IO ()

foreign import javascript unsafe
 "$1.status"
 jsXHRGetStatus :: JSRef XHR -> IO Int

foreign import javascript unsafe
 "$1.getAllResponseHeaders()"
 jsXHRGetAllResponseHeaders :: JSRef XHR -> IO JSString

foreign import javascript unsafe
 "$1.responseText"
 jsXHRGetResponseText :: JSRef XHR -> IO JSString

--------------------------------------------------------------------------------
ajax :: (ToJSON a, FromJSON b) => Method -> String -> a -> Output b -> IO ()
ajax meth url payload output = do
  resp <- request $ mkRequest meth url payload
  case resp of
    Response 200 _ r -> do
      case decode' r of
        Just b -> void . atomically $ send output b
        _      -> return ()
    _                -> return ()
  where decode' = Aeson.decode . BSL.fromStrict . C8.pack

get, post :: (ToJSON a) => String -> a -> Output String -> IO ()
get = ajax GET
post = ajax POST

--------------------------------------------------------------------------------
ajax_ :: (ToJSON a) => Method -> String -> a -> IO Response
ajax_ =meth url payload = request $ mkRequest meth url payload

get_, post_ :: (ToJSON a) => String -> a -> IO Response
get_ = ajax_ GET
post_ = ajax_ POST
