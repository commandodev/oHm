{-# language ExtendedDefaultRules #-}
{-# language OverloadedStrings #-}

module Main where

import Render
import Virtual

main :: IO TreeState
main = do
  oldState <- renderSetup rootView (0,0)
  rerender rootView (5,5) oldState
