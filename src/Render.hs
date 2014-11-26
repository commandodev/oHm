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
        ,vnode "div.row"
               [vnode "div.col-md-3"
                      [vbutton "button.btn.btn-primary" onclick1 "+(5, 0)"
                      ,vbutton "button.btn.btn-primary" onclick2 "+(0, 3)"
                      ,vbutton "button.btn.btn-primary" onclick3 "-(10, 10)"]
               ,vnode "div.col-md-9.well" [vtext "div" (show state)]]]
  where onclick1 _ =
          sendMessage output
                      (IncFst 5)
        onclick2 _ =
          sendMessage output
                      (IncSnd 3)
        onclick3 _ =
          sendMessage output
                      (DecBoth 10)
