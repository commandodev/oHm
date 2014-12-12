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
import qualified Ajax as Ajax

data RestReq a =
     NewChatMessage String String
   | Ping


data Router ein a = Router {
    _local :: ein -> IO ()
  , _remote :: a -> IO ()
  }  

data Component ein model edom = Component {
   
    -- | The processing function of a 'Model' for this component
    model :: ein -> model -> model
    
    -- | A renderer for 'Model' creating 'HTML' produces 'DOMEvent's
  , render :: DOMEvent edom -> model -> HTML
  
    -- | A processor of events emitted from the UI
    --
    -- This has the choice of feeding events back into the model
  , domEventsProcessor :: Output ein -> Consumer edom IO ()

  }

appModel :: (e -> m -> m) ->  Model m e m
appModel fn = asPipe $ forever $ do
  m <- await
  w <- lift $ get
  let w' = fn m w
  lift $ put w'
  yield w'
  

runComponent
  ::  model 
  -> Component ein model edom
  -> IO model
runComponent s Component{..} = do
  (domSink, domSource) <- spawn Unbounded
  (modelSink, modelSource) <- spawn Unbounded
  let render' = render (domChannel domSink)
  void . forkIO . runEffect $ fromInput domSource >-> domEventsProcessor modelSink
  runMVC s (appModel model) $ managed $ \k -> do
    componentEl <- newTopLevelContainer
    renderTo componentEl $ render' s
    k (asSink (renderTo componentEl . render'), asInput modelSource)
    
    

    
