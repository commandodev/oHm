{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import GHCJS.Foreign
import GHCJS.Types
import Render
import Browser
import Control.Concurrent.Chan

initialState :: (Int,Int)
initialState = (0,0)

setup :: IO TreeState
setup = do
  body <- documentBody
  let tree = rootView initialState
      node = createDOMNode tree
  _ <- appendChild body node
  return $ makeTreeState node tree

main :: IO TreeState
main = do
  oldState <- setup
  rerender rootView (5,5) oldState
