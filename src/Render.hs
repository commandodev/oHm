{-# LANGUAGE OverloadedStrings #-}
module Render (rootView) where

import Prelude hiding (id)

import Messages
import Virtual

userView :: Pending User -> HTML
userView NotRequested = vtext "div.well" "No user loaded yet. (Press the AJAX button!)"
userView NotFound = vtext "div.well" "User not found. Sadness."
userView Loading = vtext "div.well" "Loading user...please wait."
userView (Loaded user) =
  vnode "table.table"
        [vnode "tr"
               [vnode "th" [vtext "span" "ID"]
               ,vnode "th" [vtext "span" "Login"]
               ,vnode "th" [vtext "span" "Name"]
               ,vnode "th" [vtext "span" "Email"]]
        ,vnode "tr"
               [vnode "td" [vtext "span" (show (id user))]
               ,vnode "td" [vtext "span" (login user)]
               ,vnode "td" [vtext "span" (name user)]
               ,vnode "td" [vtext "span" (email user)]]]

controls :: (Message -> IO ()) -> HTML
controls send =
  vnode "div"
        [msgButton (IncFst 5) "+(5, 0)"
        ,msgButton (IncSnd 3) "+(0, 3)"
        ,msgButton (IncBoth 1 2) "+(1, 2)"
        ,msgButton (FetchAjax) "AJAX"]
  where msgButton msg text =
          vbutton "button.btn.btn-primary" (\_ -> send msg) text

rootView :: (Message -> IO ()) -> World -> HTML
rootView send (a,b,user) =
  vnode "div.container"
        [vnode "nav.navbar.navbar-default" [vtext "div.navbar-brand" "Demo"]
        ,vnode "div.row"
               [vnode "div.col-sm-3" [controls send]
               ,vnode "div.col-sm-9"
                      [vtext "div.well" (show (a,b)),userView user]]]
