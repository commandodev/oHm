module Virtual (
  vnode,
  vtext,
  documentBody,
  appendChild,
  createDOMNode,
  renderSetup,
  rerender,
  TreeState(),
  makeTreeState,
  HTML()) where

import GHCJS.Foreign
import GHCJS.Types

import System.IO.Unsafe

data VNode
data DOMNode
data Patch
data TreeState = TreeState {_node :: JSRef DOMNode, _tree :: HTML}
newtype HTML = HTML (JSRef VNode)
newtype HTMLPatch = HTMLPatch (JSRef Patch)

makeTreeState :: JSRef DOMNode -> HTML -> TreeState
makeTreeState n t= TreeState { _node = n, _tree = t}

foreign import javascript unsafe
  "document.body" documentBody :: IO (JSRef DOMNode)

foreign import javascript unsafe
  "$1.appendChild($2)" appendChild :: JSRef DOMNode -> JSRef DOMNode -> IO ()

foreign import javascript unsafe
  "h($1, {}, $2)" vnode_ :: JSString -> JSArray VNode -> JSRef VNode

foreign import javascript unsafe
  "h($1, $2)" vtext_ :: JSString -> JSString -> JSRef VNode

foreign import javascript unsafe
  "createElement($1)" createDOMNode_ :: JSRef VNode -> JSRef DOMNode

foreign import javascript safe
  "diff($1, $2)" diff_ :: JSRef VNode -> JSRef VNode -> JSRef Patch

foreign import javascript safe
  "patch($1, $2)" patch_ :: JSRef DOMNode -> JSRef Patch -> IO (JSRef DOMNode)

vnode :: String -> [HTML] -> HTML
vnode tag children = HTML $ vnode_ (toJSString tag) (unsafePerformIO (toArray (map f children)))
  where f (HTML a) = a

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
