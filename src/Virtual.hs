{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}

module Virtual (
  vnode,
  vnodeFull,
  svgProp,
  rect,
  vtext,
  vbutton,
  renderSetup,
  rerender,
  documentBody,
  diff,
  patch,
  TreeState(..),
  makeTreeState,
  Size(..),
  Position(..),
  HTML()
  ) where

import           GHCJS.Foreign
import           GHCJS.Types
import           GHCJS.Marshal
import           System.IO.Unsafe -- TODO This is, of course, bad.

data VNode
data DOMNode
data Patch
data JSProperties
data TreeState = TreeState {_node :: JSRef DOMNode, _tree :: HTML}
newtype HTML = HTML (JSRef VNode)
newtype HTMLPatch = HTMLPatch (JSRef Patch)
newtype Properties =
  Properties {props :: JSRef JSProperties}

makeTreeState :: JSRef DOMNode -> HTML -> TreeState
makeTreeState n t= TreeState { _node = n, _tree = t}

#ifndef HLINT
foreign import javascript unsafe
  "document.body" documentBody :: IO (JSRef DOMNode)

foreign import javascript unsafe
  "$1.appendChild($2)" appendChild :: JSRef DOMNode -> JSRef DOMNode -> IO ()

foreign import javascript unsafe
  "h($1, $2, $3)" vnode_ :: JSString -> JSRef JSProperties -> JSArray VNode -> JSRef VNode

foreign import javascript unsafe
  "h($1, {'ev-click': $2}, $3)" vbutton_ :: JSString -> JSFun (JSRef a -> IO ()) -> JSString -> JSRef VNode

foreign import javascript unsafe
  "h($1, $2)" vtext_ :: JSString -> JSString -> JSRef VNode

foreign import javascript unsafe
  "createElement($1)" createDOMNode_ :: JSRef VNode -> JSRef DOMNode

foreign import javascript safe
  "diff($1, $2)" diff_ :: JSRef VNode -> JSRef VNode -> JSRef Patch

foreign import javascript safe
  "patch($1, $2)" patch_ :: JSRef DOMNode -> JSRef Patch -> IO (JSRef DOMNode)

foreign import javascript unsafe
  "$r = {};" noproperty_ :: JSRef JSProperties

foreign import javascript unsafe
  "$r = {namespace: 'http://www.w3.org/2000/svg',width: '800px', height: '500px'};" svgProp_ :: JSRef JSProperties

foreign import javascript unsafe
  "$r = svg('rect', { width: $1, height: $2, x: $3, y: $4 });" rect_ :: JSString -> JSString -> JSString -> JSString -> JSRef VNode
#endif

-- property :: String -> String -> Properties
-- property k v =
--   Properties $
--   property_ (toJSString k)
--             (toJSString v)

noProperty :: Properties
noProperty = Properties noproperty_

svgProp :: Properties
svgProp = Properties svgProp_

data Size = Size String String deriving (Show,Eq)
data Position = Position String String deriving (Show,Eq)

rect :: Size -> Position -> HTML
rect (Size w h) (Position x y) =
  HTML $
  rect_ (toJSString w)
        (toJSString h)
        (toJSString x)
        (toJSString y)

vnodeFull :: String -> Properties -> [HTML] -> HTML
vnodeFull tag properties children =
  HTML $
  vnode_ (toJSString tag)
         (props properties)
         (unsafePerformIO (toArray (fmap f children)))
  where f (HTML a) = a

vnode :: String -> [HTML] -> HTML
vnode tag children =
  HTML $
  vnode_ (toJSString tag)
         noproperty_
         (unsafePerformIO (toArray (map f children)))
  where f (HTML a) = a

vbutton :: String -> (JSRef a -> IO ()) -> String -> HTML
vbutton tag f s =
  HTML $
  vbutton_ (toJSString tag) f' (toJSString s)
  where f' =
          unsafePerformIO $
          syncCallback1 AlwaysRetain True f

vtext :: String -> String -> HTML
vtext tag text = HTML $ vtext_ (toJSString tag) (toJSString text)

createDOMNode :: HTML -> JSRef DOMNode
createDOMNode (HTML x) = createDOMNode_ x

patch :: JSRef DOMNode -> HTMLPatch -> IO (JSRef DOMNode)
patch n (HTMLPatch p) = patch_ n p

diff :: HTML -> HTML -> HTMLPatch
diff (HTML old) (HTML new) = HTMLPatch (diff_ old new)

rerender :: (a -> HTML) -> a -> TreeState -> IO TreeState
rerender render x (TreeState {_node = oldNode, _tree = oldTree}) = do
  let newTree = render x
      patches = diff oldTree newTree
  newNode <- patch oldNode patches
  return (makeTreeState newNode newTree)

renderSetup :: (a -> HTML) -> a -> IO TreeState
renderSetup render x = do
  body <- documentBody
  let tree = render x
      node = createDOMNode tree
  _ <- appendChild body node
  return $ makeTreeState node tree
