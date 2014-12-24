{-# LANGUAGE CPP #-}
#ifndef HLINT
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE InterruptibleFFI #-}
#endif
module Ohm.SocketIO where

import Data.Aeson (FromJSON(..), ToJSON(..))
import qualified Data.Aeson as Aeson
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
  "$1.emit($2);"
  socketIOEmit_ :: SocketIO -> JSString -> IO ()


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

sioSend_ :: SocketIO -> String -> IO ()
sioSend_ sio chan = socketIOEmit_ sio (toJSString chan)


sioSub :: (FromJSON a) => SocketIO -> String -> (a -> IO ()) -> IO ()
sioSub sio chan outPut = do
  callback <- syncCallback1 AlwaysRetain True $ \msg -> do
    Just ref <- fromJSRef msg
    case Aeson.fromJSON ref of 
      Aeson.Success a ->  outPut a 
      Aeson.Error s   -> putStrLn $ "Couldn't decode message on " ++ chan ++ ": " ++ s
  socketIOOn sio (toJSString chan) callback
