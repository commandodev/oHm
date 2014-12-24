{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE OverloadedStrings #-}
module Ohm.Internal.HTML
  ( html, head, title, base, link, meta, style, script, noscript, body, section, nav, article, aside, h1, h2, h3, h4, h5, h6, hgroup, header, footer, address, p, hr, pre, blockquote, ol, ul, li, dl, dt, dd, figure, figcaption, div, a, em, strong, small, s, cite, q, dfn, abbr, data_, time, code, var, samp, kbd, sub, sup, i, b, u, mark, ruby, rt, rp, bdi, bdo, span, br, wbr, ins, del, img, iframe, embed, object, param, video, audio, source, track, canvas, map, area, table, caption, colgroup, col, tbody, thead, tfoot, tr, td, th, form, fieldset, legend, label, input, button, select, datalist, optgroup, option, textarea, keygen, output, progress, meter, details, summary, command, menu, dialog

  , HTML
  , attrs
  , classes
  , text
  , with
  , into

  , onClick
  , onInput
  , renderTo
  , newTopLevelContainer
  , toJSString
  )
where

import Control.Applicative
import Control.Lens hiding (aside, children, coerce, pre)
import Control.Monad
import Control.Monad.State
import Data.Coerce (coerce)
import Data.IORef
import Data.Maybe
import Data.String (IsString(..))
import Ohm.Internal.DOMEvent
import GHCJS.DOM
import GHCJS.DOM.Document
import GHCJS.DOM.Element
import GHCJS.DOM.Node
import GHCJS.Foreign
import GHCJS.Types
import qualified Ohm.Internal.Immutable as Immutable
import Prelude hiding (div, head, map, mapM, sequence, span)
import System.IO.Unsafe

html, head, title, base, link, meta, style, script, noscript, body, section, nav, article, aside, h1, h2, h3, h4, h5, h6, hgroup, header, footer, address, p, hr, pre, blockquote, ol, ul, li, dl, dt, dd, figure, figcaption, div, a, em, strong, small, s, cite, q, dfn, abbr, data_, time, code, var, samp, kbd, sub, sup, i, b, u, mark, ruby, rt, rp, bdi, bdo, span, br, wbr, ins, del, img, iframe, embed, object, param, video, audio, source, track, canvas, map, area, table, caption, colgroup, col, tbody, thead, tfoot, tr, td, th, form, fieldset, legend, label, input, button, select, datalist, optgroup, option, textarea, keygen, output, progress, meter, details, summary, command, menu, dialog :: HTML

html = emptyElement "html"
head = emptyElement "head"
title = emptyElement "title"
base = emptyElement "base"
link = emptyElement "link"
meta = emptyElement "meta"
style = emptyElement "style"
script = emptyElement "script"
noscript = emptyElement "noscript"
body = emptyElement "body"
section = emptyElement "section"
nav = emptyElement "nav"
article = emptyElement "article"
aside = emptyElement "aside"
h1 = emptyElement "h1"
h2 = emptyElement "h2"
h3 = emptyElement "h3"
h4 = emptyElement "h4"
h5 = emptyElement "h5"
h6 = emptyElement "h6"
hgroup = emptyElement "hgroup"
header = emptyElement "header"
footer = emptyElement "footer"
address = emptyElement "address"
p = emptyElement "p"
hr = emptyElement "hr"
pre = emptyElement "pre"
blockquote = emptyElement "blockquote"
ol = emptyElement "ol"
ul = emptyElement "ul"
li = emptyElement "li"
dl = emptyElement "dl"
dt = emptyElement "dt"
dd = emptyElement "dd"
figure = emptyElement "figure"
figcaption = emptyElement "figcaption"
div = emptyElement "div"
a = emptyElement "a"
em = emptyElement "em"
strong = emptyElement "strong"
small = emptyElement "small"
s = emptyElement "s"
cite = emptyElement "cite"
q = emptyElement "q"
dfn = emptyElement "dfn"
abbr = emptyElement "abbr"
data_ = emptyElement "data"
time = emptyElement "time"
code = emptyElement "code"
var = emptyElement "var"
samp = emptyElement "samp"
kbd = emptyElement "kbd"
sub = emptyElement "sub"
sup = emptyElement "sup"
i = emptyElement "i"
b = emptyElement "b"
u = emptyElement "u"
mark = emptyElement "mark"
ruby = emptyElement "ruby"
rt = emptyElement "rt"
rp = emptyElement "rp"
bdi = emptyElement "bdi"
bdo = emptyElement "bdo"
span = emptyElement "span"
br = emptyElement "br"
wbr = emptyElement "wbr"
ins = emptyElement "ins"
del = emptyElement "del"
img = emptyElement "img"
iframe = emptyElement "iframe"
embed = emptyElement "embed"
object = emptyElement "object"
param = emptyElement "param"
video = emptyElement "video"
audio = emptyElement "audio"
source = emptyElement "source"
track = emptyElement "track"
canvas = emptyElement "canvas"
map = emptyElement "map"
area = emptyElement "area"
table = emptyElement "table"
caption = emptyElement "caption"
colgroup = emptyElement "colgroup"
col = emptyElement "col"
tbody = emptyElement "tbody"
thead = emptyElement "thead"
tfoot = emptyElement "tfoot"
tr = emptyElement "tr"
td = emptyElement "td"
th = emptyElement "th"
form = emptyElement "form"
fieldset = emptyElement "fieldset"
legend = emptyElement "legend"
label = emptyElement "label"
input = emptyElement "input"
button = emptyElement "button"
select = emptyElement "select"
datalist = emptyElement "datalist"
optgroup = emptyElement "optgroup"
option = emptyElement "option"
textarea = emptyElement "textarea"
keygen = emptyElement "keygen"
output = emptyElement "output"
progress = emptyElement "progress"
meter = emptyElement "meter"
details = emptyElement "details"
summary = emptyElement "summary"
command = emptyElement "command"
menu = emptyElement "menu"
dialog = emptyElement "dialog"

data VNode

newtype HTML = HTML (JSRef VNode)

foreign import javascript safe
  "new VText($1)" text_ :: JSString -> HTML

text :: ToJSString text => text -> HTML
text = text_ . toJSString

foreign import javascript safe
  "new VNode($1)" emptyElement :: JSString -> HTML

foreign import javascript safe
  "$r = $1 && $1.type == 'VirtualNode';" isVNode :: HTML -> JSBool

foreign import javascript safe
  "if ($1.type == 'VirtualNode') { $r = new VNode($1.tagName, $1.properties, $2); } else { $r = $1; }" setVNodeChildren :: HTML -> JSArray a -> HTML

attrs :: Traversal' HTML Immutable.Map
attrs f n
  | fromJSBool (isVNode n) = f (vNodeGetAttributes n) <&> vNodeSetAttributes n
  | otherwise = pure n

classes :: Traversal' HTML [String]
classes = attrs . at "class" . anon "" (isEmptyStr . fromJSString) . iso (words . fromJSString) (toJSString . unwords)
  where isEmptyStr = (== ("" :: String))

with :: HTML -> State HTML () -> [HTML] -> HTML
with el f xs = setVNodeChildren (el &~ f) (unsafePerformIO (toArray (coerce xs)))

into :: HTML -> [HTML] -> HTML
into el xs = setVNodeChildren el (unsafePerformIO (toArray (coerce xs)))

instance IsString HTML where
  fromString = text . toJSString

foreign import javascript safe
  "Immutable.Map($1.properties.attributes)"
  vNodeGetAttributes :: HTML -> Immutable.Map

foreign import javascript safe
  "new VNode($1.tagName, Immutable.Map($1.properties).set('attributes', $2).toJS(), $1.children)"
  vNodeSetAttributes :: HTML -> Immutable.Map -> HTML

foreign import javascript unsafe
  "$1.preventDefault();" preventDefault :: JSRef a -> IO ()

foreign import javascript safe
  "new VNode($1.tagName, Immutable.Map($1.properties).set('ev-click', evHook($2)).toJS(), $1.children)"
  vnodeSetClickEv :: HTML -> JSRef a -> HTML

foreign import javascript safe
  "new VNode($1.tagName, Immutable.Map($1.properties).set('name', 'stub').set('ev-input', evHook(changeEvent($2))).toJS(), $1.children)"
  vnodeSetInputEv :: HTML -> JSRef a -> HTML

foreign import javascript safe
  "$1.stub" getStubValue :: JSRef a -> JSString

onClick :: MonadState HTML m => DOMEvent () -> m ()
onClick = modify . (setDOMEvent vnodeSetClickEv $ void . preventDefault)

onInput :: MonadState HTML m => DOMEvent String -> m ()
onInput = modify . (setDOMEvent vnodeSetInputEv $ return . fromJSString . getStubValue)

setDOMEvent :: (HTML -> JSFun (JSRef event -> IO ()) -> HTML) -> (JSRef event -> IO a) -> DOMEvent a -> HTML -> HTML
setDOMEvent setter f (DOMEvent chan) n
  | fromJSBool (isVNode n) = setter n $ unsafePerformIO $
      syncCallback1 AlwaysRetain True (f >=> chan)
  | otherwise = n


--------------------------------------------------------------------------------
foreign import javascript unsafe
  "vdom($1)"
  createElement :: HTML -> IO Element

data Diff
foreign import javascript unsafe
  "$r = window.virtualDom.diff($1, $2)"
  diff :: HTML -> HTML -> IO (JSRef Diff)

foreign import javascript unsafe
  "window.virtualDom.patch($1, $2)"
  patch :: Element -> JSRef Diff -> IO ()

--------------------------------------------------------------------------------
-- An element in the DOM that we can render virtualdom elements to
data VNodePresentation = VNodePresentation (IORef HTML) Element

-- Render our internal HTML tree representation into a VNode. We first
-- convert our HTML into a VTree, and then diff this against the container
-- and apply the resulting updates.
renderTo :: VNodePresentation -> HTML -> IO ()
renderTo (VNodePresentation ioref el) !e = do
  oldVnode <- readIORef ioref
  patches <- diff oldVnode e
  patch el patches
  writeIORef ioref e

newTopLevelContainer :: IO VNodePresentation
newTopLevelContainer = do
  initialVNode <- return div
  currentVNode <- newIORef initialVNode
  el <- createElement initialVNode
  Just doc <- currentDocument
  Just bodyNode <- documentGetBody doc
  _ <- nodeAppendChild bodyNode (Just el)
  return (VNodePresentation currentVNode el)
