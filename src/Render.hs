{-# LANGUAGE OverloadedStrings #-}
module Render (rootView) where

import Prelude hiding (id,span)

import Messages
import Virtual
import HTML

userView :: Pending User -> HTML
userView NotRequested = span "No user loaded yet. (Press the AJAX button!)"
userView NotFound = span "User not found. Sadness."
userView Loading = span "Loading user...please wait."
userView (Loaded user) =
  table [tr [th [span "ID"]
            ,th [span "Login"]
            ,th [span "Name"]
            ,th [span "Email"]]
        ,tr [td [span (show (id user))]
            ,td [span (login user)]
            ,td [span (name user)]
            ,td [span (email user)]]]

controls :: (Message -> IO ()) -> HTML
controls send =
  vnode "div"
        [msgButton (IncFst 5) "+(5, 0)"
        ,msgButton (IncSnd 3) "+(0, 3)"
        ,msgButton (IncBoth 1 2) "+(1, 2)"
        ,msgButton FetchAjax "AJAX"]
  where msgButton msg =
          vbutton "button.btn.btn-primary" (\_ -> send msg)

rootView :: (Message -> IO ()) -> World -> HTML
rootView send (a,b,user) =
  container [navbar [vtext "div.navbar-brand" "Demo"]
            ,row [col3 [controls send],col9 [well [span (show (a,b))],well [userView user]]]]
