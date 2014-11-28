module Render (rootView) where

import GHC.Exts (sortWith)
import HTML
import Data.Maybe
import Messages
import MarketData
import Prelude hiding (div,id,span)
import Virtual

marketDataGraph :: [Market] -> HTML
marketDataGraph rows =
  vnodeFull "svg"
            svgProp
            (zipWith (curry f)
                     [(0 :: Int) ..]
                     rows)
  where count = length rows
        closes = mapMaybe close rows
        highest = maximum closes
        f (n,r) =
          rect (show w ++ "%")
               (show h ++ "%")
               (show x ++ "%")
               (show y ++ "%")
          where w, h, x, y :: Double
                x = 100.0 * fromIntegral n / fromIntegral count
                y = 100 - h
                w = 100 / fromIntegral count
                h =
                  100.0 *
                  fromMaybe 0 (close r) /
                  highest

marketDataView :: (Market -> Bool) -> Pending [Market] -> HTML
marketDataView _ NotRequested = span "No data loaded yet. (Press the AJAX button!)"
marketDataView _ NotFound = span "Data not found. Sadness."
marketDataView _ Loading = span "Loading marketData...please wait."
marketDataView _ (LoadFailed e) = span ("Loading marketData failed: " ++ e)
marketDataView filterFn (Loaded rows) =
  vnode "div"
        [marketDataGraph filteredRows,simpleTable marketTableDef filteredRows]
  where filteredRows =
          sortWith symbol $
          filter filterFn rows

showMaybe :: Show a => String -> Maybe a -> String
showMaybe d Nothing = d
showMaybe _ (Just s) = show s

marketTableDef :: TableDef Market
marketTableDef =
  [("Latest Trade",show . time . latest_trade)
  ,("Symbol",symbol)
  ,("Bid"
   ,showMaybe "-" .
    bid)
  ,("Ask"
   ,showMaybe "-" .
    ask)
  ,("High"
   ,showMaybe "-" .
    high)
  ,("Low"
   ,showMaybe "-" .
    low)
  ,("Close"
   ,showMaybe "-" .
    close)
  ,("Volume"
   ,showMaybe "-" .
    volume)
  ,("Currency Volume"
   ,\x ->
      currency x ++
      " " ++
      showMaybe "-" (fmap floor (currency_volume x)::Maybe Integer))]

controls :: (Message -> IO ()) -> HTML
controls send =
  vnode "div"
        [msgButton (IncFst 5) "+(5, 0)"
        ,msgButton (IncSnd 3) "+(0, 3)"
        ,msgButton (IncBoth 1 2) "+(1, 2)"
        ,msgButton (FilterCurrency (Just "USD")) "USD"
        ,msgButton (FilterCurrency (Just "GBP")) "GBP"
        ,msgButton (FilterCurrency Nothing) "All"
        ,msgButton FetchMarket "AJAX"]
  where msgButton msg =
          vbutton "button.btn.btn-primary" (\_ -> send msg)

rootView :: (Message -> IO ()) -> World -> HTML
rootView send (a,b,filterFn,marketData) =
  vnode "div.container"
            [navbar [vtext "div.navbar-brand" "Demo"]
            ,row [col3 [controls send],col9 [well [span (show (a,b))]]]
            ,row [col12 [well [marketDataView filterFn marketData]]]]
