module Main where

import Render
import Virtual

initialState :: (Int,Int)
initialState = (0,0)

main :: IO TreeState
main = do
  oldState <- renderSetup rootView (0,0)
  rerender rootView (5,5) oldState
