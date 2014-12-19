{-# LANGUAGE CPP #-}
#ifndef HLINT
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE InterruptibleFFI #-}
#endif
module SocketIO where

import Control.Concurrent.STM
import Control.Monad (void)
import Data.Aeson (FromJSON(..), ToJSON(..))
import qualified Data.Aeson as Aeson
import Pipes.Concurrent
import GHCJS.Foreign
import GHCJS.Marshal
import GHCJS.Types

newtype SocketIO = SocketIO (JSRef ())

#ifndef HLINT

foreign import javascript unsafe
  "io.connect($1, {'query':{}, 'forceNew': true, 'upgrade': false, 'autoConnect': false})"
  socketIONew :: JSString -> IO SocketIO

foreign import javascript unsafe
  "$1.open();"
  socketIOOpen :: SocketIO -> IO ()

foreign import javascript interruptible
  "$1.on('connect', function() { $c(); });"
  socketIOWaitForConnection :: SocketIO -> IO ()

foreign import javascript unsafe
  "$1.on($2, function(data) { $3(data); });"
  socketIOOn :: SocketIO -> JSString -> JSFun (JSRef x -> IO a) -> IO ()

foreign import javascript unsafe
  "$1.emit($2, $3);"
  socketIOEmit :: SocketIO -> JSString -> JSRef x -> IO ()

foreign import javascript unsafe
  "$1.io.disconnect()"
  socketIODisconnect :: SocketIO -> IO ()

foreign import javascript unsafe
  "$1.io.skipReconnect = false; $1.io.reconnect();"
  socketIOReconnect :: SocketIO -> IO ()

foreign import javascript unsafe
  "$1.io.opts.query[$2] = $3"
  socketIOSetQueryParameter :: SocketIO -> JSString -> JSString -> IO ()

#endif

sioSend :: (ToJSON a) => SocketIO -> String -> a -> IO ()
sioSend sio chan a = socketIOEmit sio (toJSString chan) =<< (toJSRef $ toJSON a)

sioSub :: (FromJSON a) => SocketIO -> String -> Output a -> IO ()
sioSub sio chan outPut = do
  callback <- syncCallback1 AlwaysRetain True $ \msg -> do
    Just ref <- fromJSRef msg
    case Aeson.fromJSON ref of 
      Aeson.Success a ->  void $ atomically $ send outPut a 
      Aeson.Error s   -> putStrLn $ "Couldn't decode message on " ++ chan ++ ": " ++ s
  socketIOOn sio (toJSString chan) callback
