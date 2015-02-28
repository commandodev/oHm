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

-- | Converts @UI Events@ to @Model Events@ in a monad for external communication
--
-- see "Pipes.Tutorial" for more on function @a -> 'Producer' b m ()@
newtype Processor m edom ein = Processor
  { 
    runProcessor :: edom -> Producer ein m ()
  } deriving (Monoid)

-- | Pass @UI Events@ directly to the model
--
-- Use this in the case of simple components that use the same type
-- for both @UI Events@ and @Model Events@
idProcessor :: (Monad m) => Processor m e e
idProcessor = Processor yield

instance (Monad m) => Functor (Processor m ein) where
  fmap f (Processor p) = Processor (p ~> yield . f)

instance (Monad m) => Profunctor (Processor m) where
  lmap f (Processor p) = Processor (p . f)
  rmap = fmap
  
-- | Use a Prism' to determine which part of a message to handle
handles :: Monad m => Prism' b a -> Processor m a c -> Processor m b c  
handles prism p = Processor $ traverse_ (runProcessor p) . preview prism


--------------------------------------------------------------------------------

data Component env ein model edom = Component {
   
    -- | The processing function of an 'MVC.Model' for this component
    model :: ein -> model -> model
    
    -- | A renderer for 'MVC.Model' creating 'HTML' produces @UI Events@
  , render :: Renderer edom model
  
    -- | A processor of events emitted from the UI
  , domEventsProcessor :: Processor (ReaderT env IO) edom ein
  }

-- | Convert's the 'model' function from a 'Component' to an 'MVC.Model'
appModel :: (e -> m -> m) ->  Model m e m
appModel fn = asPipe $ forever $ do
  e <- await
  lift $ modify (fn e)
  yield =<< lift get

  
--------------------------------------------------------------------------------
{- | Runs a 'Component'

Running a component forks two IO threads:

 * The first is for @UI Events@. The thead processes them, running any
   IO actions and feeding @Model Events@ into the 'MVC.Model' 'Controller'
 
 * The second is the thread which calls 'MVC.runMVC' and updates the DOM
-}
runComponent'
  ::  forall model env ein edom.
     (model -> IO ())
  -- ^ An action to run every time the model updates (used by 'runComponentDebug')
  -> model
  -- ^ Initial model state
  -> env
  -- ^ Configuration available in 'ReaderT'
  -> Component env ein model edom
  -- ^ The component to run
  -> IO (Output ein)
  -- ^ Returns an 'Output' that accepts @Model Events@ from external systems
runComponent' dbg s env Component{..} = do
  (domSink, domSource) <- spawn unbounded
  (modelSink, modelSource) <- spawn unbounded
  
  runEvents $ for (fromInput domSource) (runProcessor domEventsProcessor)
           >-> (toOutput modelSink)
  void . forkIO . void $ runMVC s (appModel model) $ app modelSource domSink
  return modelSink
  where
    -- Run the event processor over the events produced by the dom
    runEvents :: Effect (ReaderT env IO) () -> IO ()
    runEvents = void . forkIO . (flip runReaderT $ env) . runEffect
    
    -- Create an MVC app
    app :: Input ein -> Output edom -> Managed (View model, Controller ein)
    app eventSource domSink = managed $ \k -> do
      let render' = render (domChannel domSink)
      componentEl <- newTopLevelContainer
      renderTo componentEl $ render' s
      k (asSink (debugRender render' componentEl), asInput eventSource)

    -- Render the current model by patching the DOM
    -- debugRender :: (model -> HTML) -> VNodePresentation -> model -> IO ()
    debugRender f el mdl = do
      dbg mdl
      renderTo el $ f mdl

-- | 'runComponent'' printing the model at each modification
runComponentDebug
  ::  forall model env ein edom. (Show model)
  => model
  -> env
  -> Component env ein model edom
  -> IO (Output ein)      
runComponentDebug = runComponent' print

-- | 'runComponent'' with no extra action
runComponent
  ::  forall model env ein edom.
     model
  -> env
  -> Component env ein model edom
  -> IO (Output ein)      
runComponent = runComponent' (void . return)
