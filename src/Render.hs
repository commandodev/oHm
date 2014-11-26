{-# LANGUAGE OverloadedStrings #-}
module Render (rootView) where

import Messages
import Virtual

rootView :: (Message -> IO ()) -> World -> HTML
rootView send state =
  vnode "div.container"
        [vnode "nav.navbar.navbar-default" [vtext "div.navbar-brand" "Demo"]
        ,vnode "div.row"
               [vnode "div.col-sm-3"
                      [msgButton (IncFst 5) "+(5, 0)"
                      ,msgButton (IncSnd 3) "+(0, 3)"
                      ,msgButton (IncBoth 1 2) "+(1, 2)"
                      ,msgButton (FetchAjax) "AJAX"
                      ]
               ,vnode "div.col-sm-9" [vtext "div.well" (show state)]]]
  where msgButton msg text =
          vbutton "button.btn.btn-primary" (\_ -> send msg) text
