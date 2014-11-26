{-# LANGUAGE CPP #-}

module Render (rootView) where

import Pipes.Concurrent
import Messages
import Virtual

sendMessage :: Output Message -> Message -> IO ()
sendMessage output msg = atomically $ send output msg >> return ()

rootView :: (Output Message) -> (Int,Int) -> HTML
rootView output state =
  vnode "div.container"
        [vnode "nav.navbar.navbar-default" [vtext "div.navbar-brand" "Demo"]
        ,vnode "div"
               [vbutton "button.btn.btn-primary" click1 "+(5, 0)"
               ,vbutton "button.btn.btn-primary" click2 "+(0, 3)"]
        ,vnode "div.well" [vtext "div" (show state)]]
  where click1 _ = sendMessage output (IncFst 5)
        click2 _ = sendMessage output (IncSnd 3)
