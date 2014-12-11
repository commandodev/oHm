{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE TemplateHaskell #-}
module Component where

import Control.Lens
import Control.Applicative
import Control.Monad.State
import Control.Monad (void)
import MVC
import Francium (HTML, renderTo, DOMEvent, domChannel, newTopLevelContainer)

data RestReq a =
     NewChatMessage String String
   | Ping

makePrisms ''RestReq

data Route r a =
    Local a
  | Rest (r a)
  | WS a
  deriving (Functor)
  
makePrisms ''Route

data Router ein a = Router {
    _local :: ein -> IO ()
  , _remote :: a -> IO ()
  }  

data Component ein model edom = Component {
   
    -- | The 'Model' for this component
    model :: Model model ein model
    
    -- | A renderer for 'Model' creating 'HTML' produces 'DOMEvent's
  , render :: DOMEvent edom -> model -> HTML

  }

restView :: Managed (View eRest)
restView = managed $ \k -> do
  k $ asSink $ void . atomically . send

modelInputView :: Managed (View ein)
modelInputView = undefined

wsView :: Managed (View eWs)
wsView = undefined

eventsView :: Managed (View (Route RestReq e))
eventsView = fmap (handles _Local) modelInputView
          <> fmap (handles (_Rest . _NewChatMessage)) restView
          <> fmap (handles _WS) wsView
          
domEventsSource :: Input edom
domEventsSource = undefined


runComponent
  ::  model 
  -> Component ein model edom
  -> (Pipe edom ein IO ())
  -> IO model
runComponent s Component{..} domEventRouter = do
  (domSink, domSource) <- spawn Unbounded
  (modelSink, modelSource) <- spawn Unbounded
  let render' = render (domChannel domSink)
  void . forkIO . runEffect $ fromInput domSource >-> domEventRouter >-> toOutput modelSink
  runMVC s model $ managed $ \k -> do
    componentEl <- newTopLevelContainer
    renderTo componentEl $ render' s
    k (asSink (renderTo componentEl . render'), asInput modelSource)
    
    

    
