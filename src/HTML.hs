{-# LANGUAGE OverloadedStrings #-}

-- NOTE: This is very much an interim namespace. I'd prefer to use Lucid.
module HTML where

import Prelude hiding (span)

import Virtual

span :: String -> HTML
span = vtext "span"

navbar, well, container, row, col3, col9, th, td, tr, table :: [HTML] -> HTML

container = vnode "div.container"
row = vnode "div.row"
well = vnode "div.well"
col3 = vnode "div.col-sm-3"
col9 = vnode "div.col-sm-9"
th = vnode "th"
td = vnode "td"
tr = vnode "tr"
table = vnode "table.table"
navbar = vnode "nav.navbar.navbar-default"
