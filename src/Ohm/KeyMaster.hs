{-# LANGUAGE OverloadedStrings #-}
module Ohm.KeyMaster (
    initKeyMaster
  , Key
  , key
  , withKeys
  ) where
  
import Data.Foldable (traverse_)
import GHCJS.Foreign
import GHCJS.Types
import System.IO.Unsafe
import MVC

data Key

foreign import javascript unsafe
  "var k = key.noConflict(); $r = k;"
  initKeyMaster :: IO (JSRef Key)


foreign import javascript unsafe
  "$1($2, $3);" ffiKey :: JSRef Key -> JSString -> JSFun (IO JSBool) -> IO ()
  
key :: JSRef Key -> String -> IO () -> IO ()
key k keyStr f = ffiKey k (toJSString keyStr) $ unsafePerformIO (syncCallback AlwaysRetain True (f >> return (toJSBool False)))

withKeys :: JSRef Key -> Output cmd -> [(String, cmd)] -> IO ()
withKeys k cmdSink = traverse_ $ \(keyStr, cmd) -> key k keyStr (void . atomically $ send cmdSink cmd)
