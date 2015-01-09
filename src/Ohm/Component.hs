{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RankNTypes #-}

module Ohm.Component
  (
    Processor(..)
  , idProcessor
  , handles
  , Component(..)
  , appModel
  , runComponent
  , runComponentDebug
  ) where

import Control.Lens (Prism', preview)
import Control.Monad.Trans.Reader
import Control.Monad.State
import Data.Foldable (traverse_)
import Data.Profunctor
import MVC hiding (handles)
import Ohm.HTML (Renderer, domChannel, newTopLevelContainer, renderTo)
import Pipes ((~>))

newtype Processor m edom ein = Processor
  { 
    runProcessor :: edom -> Producer ein m ()
  } deriving (Monoid)

idProcessor :: (Monad m) => Processor m e e
idProcessor = Processor yield

instance (Monad m) => Functor (Processor m ein) where
  fmap f (Processor p) = Processor (p ~> yield . f)

instance (Monad m) => Profunctor (Processor m) where
  lmap f (Processor p) = Processor (p . f)
  rmap = fmap
  
-- | Use a Prism to determine which part of a message to handle
handles :: Monad m => Prism' b a -> Processor m a c -> Processor m b c  
handles prism p = Processor $ traverse_ (runProcessor p) . preview prism


--------------------------------------------------------------------------------

data Component env ein model edom = Component {
   
    -- | The processing function of a 'Model' for this component
    model :: ein -> model -> model
    
    -- | A renderer for 'Model' creating 'HTML' produces 'DOMEvent's
  , render :: Renderer edom model
  
    -- | A processor of events emitted from the UI
    --
    -- This has the choice of feeding events back into the model
  , domEventsProcessor :: Processor (ReaderT env IO) edom ein
  }

appModel :: (e -> m -> m) ->  Model m e m
appModel fn = asPipe $ forever $ do
  e <- await
  lift $ modify (fn e)
  yield =<< lift get

  
--------------------------------------------------------------------------------

runComponent'
  ::  forall model env ein edom. (Show model)
  => (model -> IO ())
  -> model
  -> env
  -> Component env ein model edom
  -> IO (Output ein)
runComponent' dbg s env Component{..} = do
  (domSink, domSource) <- spawn Unbounded
  (modelSink, modelSource) <- spawn Unbounded
  
  runEvents $ for (fromInput domSource) (runProcessor domEventsProcessor)
           >-> (toOutput modelSink)
  void . forkIO . void $ runMVC s (appModel model) $ app modelSource domSink
  return modelSink
  where
    runEvents :: Effect (ReaderT env IO) () -> IO ()
    runEvents = void . forkIO . (flip runReaderT $ env) . runEffect
    app :: Input ein -> Output edom -> Managed (View model, Controller ein)
    app eventSource domSink = managed $ \k -> do
      let render' = render (domChannel domSink)
      componentEl <- newTopLevelContainer
      renderTo componentEl $ render' s
      k (asSink (debugRender render' componentEl), asInput eventSource)
    --debugRender :: ()
    debugRender f el mdl = do
      dbg mdl
      renderTo el $ f mdl

runComponentDebug
  ::  forall model env ein edom. (Show model)
  => model
  -> env
  -> Component env ein model edom
  -> IO (Output ein)      
runComponentDebug = runComponent' print

runComponent
  ::  forall model env ein edom. (Show model)
  => model
  -> env
  -> Component env ein model edom
  -> IO (Output ein)      
runComponent = runComponent' (void . return)
