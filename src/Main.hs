{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

-- import GHCJS.DOM
-- import GHCJS.DOM.Document
-- import GHCJS.DOM.Element
-- import GHCJS.DOM.Node

import GHCJS.DOM
import GHCJS.DOM.Document
import GHCJS.DOM.Element
import GHCJS.DOM.Node

import GHCJS.Foreign
import System.IO.Unsafe
import GHCJS.Types

-- import Data.List
import Control.Concurrent.Chan
-- import Control.Concurrent.STM
--import Control.Concurrent.Timer

-- rerender newTree treeState = do
--   (TreeState {vtree = oldTree, node = oldNode}) <- readSTRef treeState
--   _ <- log $ show (diff oldTree newTree)
--   newRootNode <- patch (diff oldTree newTree) oldNode
--   writeSTRef treeState (TreeState {vtree = newTree, node = newRootNode})

-- newtype JSEvent = JSEvent JSAny
-- newtype VNode = VNode JSAny
-- newtype PatchObject = PatchObject JSAny
-- data TreeState = TreeState { vtree :: VNode, node :: Elem }


-- foreign import ccall jsalertImpl :: JSString -> IO ()

-- jsalert :: String -> IO ()
-- jsalert = (jsalertImpl . toJSStr)

-- foreign import ccall diff :: VNode -> VNode -> PatchObject
-- foreign import ccall patch :: Elem -> PatchObject -> IO Elem

-- -- | Apply a new virtual DOM to the existing state of the world.
-- rerender :: VNode -> TVar TreeState -> IO ()
-- rerender newTree treeState = do
--   (TreeState {vtree = oldTree, node = oldNode}) <- atomically $ readTVar treeState
--   newRootNode <- (patch oldNode (diff oldTree newTree))
--   atomically $ writeTVar treeState (TreeState {vtree = newTree, node = newRootNode})

-- step transition render appState treeState = do
--   newAppValue <- atomically $ modifyTVar appState transition
--   rerender (render newAppValue) treeState

-- initialApp :: Int
-- initialApp = 1

-- appTransition :: Int -> Int
-- appTransition = ((+) 1)

-- foreign import ccall vnode_ :: JSString -> Ptr [VNode] -> VNode
-- vnode :: String -> [VNode] -> VNode
-- vnode tag children = vnode_ (toJSStr tag) (toPtr children)

-- foreign import ccall createElement :: VNode -> Elem

data VNode
data DOMNode
newtype HTML = HTML (JSRef VNode)

foreign import javascript unsafe
  "h($1, {}, $2)" vnode_ :: JSString -> JSArray VNode -> JSRef VNode

vnode :: String -> [HTML] -> HTML
vnode tag children = HTML $ vnode_ (toJSString tag) (unsafePerformIO (toArray (map f children)))
                     where f (HTML a) = a

foreign import javascript unsafe
  "h($1, $2)" vtext_ :: JSString -> JSString -> JSRef VNode

vtext :: String -> String -> HTML
vtext tag text = HTML $ vtext_ (toJSString tag) (toJSString text)

foreign import javascript unsafe
  "createElement($1)" createDOMNode_ :: JSRef VNode -> JSRef DOMNode

createDOMNode :: HTML -> JSRef DOMNode
createDOMNode (HTML x) = createDOMNode_ x


-- -- handler :: (Show s) => s -> JSEvent -> IO ()
-- -- handler s e = log (show s)

-- navBar :: (Show s) => s -> VNode
-- navBar s = vnode "nav.navbar.navbar-default"
--   [vnode ".container-fluid"
--     [vnode ".navbar-header"
--       [vnode "a.navbar-brand"
--         [vtext "GitDash"]]]]

-- rootView :: (Show s) => s -> VNode
-- rootView s = vnode "#content"
--   [navBar s,
--    vnode ".container"
--      [vnode "button"
--        [vtext ("Say " ++ (show s))],
--       vnode ".jumbotron" [(vnode "h1" [vtext "Welcome"])],
--       vnode ".well" [vtext (show s)],
--       vnode ".panel" [vtext (show s)]]]

-- main :: IO ()
-- main = do
--        _ <- atomically $ do
--               appState <- newTVar initialApp
--               newTVar initialTreeState
--        addChild rootNode documentBody
--   -- repeatedTimer (step appTransition rootView appState treeState) 200
--   where initialTree = rootView initialApp
--         rootNode = createElement initialTree
--         initialTreeState  = TreeState {vtree = initialTree, node = rootNode}


foreign import javascript unsafe
  "document.body" documentBody :: JSRef DOMNode

foreign import javascript unsafe
  "$1.appendChild($2)" appendChild :: JSRef DOMNode -> JSRef DOMNode -> IO ()

foreign import javascript unsafe
  "alert($1)" say_ :: JSString -> IO ()

say :: String -> IO ()
say = say_ . toJSString

main :: IO ()
main = do
  chan <- newChan
  _ <- writeChan chan (1 :: Int)
  _ <- writeChan chan (2 :: Int)
  val2 <- readChan chan
  _ <- appendChild documentBody (createDOMNode (vtext "div" "Kris"))
  -- say "Woo"
  print (show val2)
