module Render (rootView) where

import Messages
import Virtual

rootView :: (Message -> IO ()) -> (Int,Int) -> HTML
rootView send state =
  vnode "div.container"
        [vnode "nav.navbar.navbar-default" [vtext "div.navbar-brand" "Demo"]
        ,vnode "div.row"
               [vnode "div.col-md-3"
                      [vbutton "button.btn.btn-primary" (\_ -> send (IncFst 5)) "+(5, 0)"
                      ,vbutton "button.btn.btn-primary" (\_ -> send (IncSnd 3)) "+(0, 3)"
                      ,vbutton "button.btn.btn-primary" (\_ -> send (DecBoth 10)) "-(10, 10)"]
               ,vnode "div.col-md-9.well" [vtext "div" (show state)]]]
