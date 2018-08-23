{-# LANGUAGE OverloadedStrings   #-}

module Main where

import Control.Concurrent
import           Control.Monad
import System.IO
import Data.Monoid
import qualified Data.ByteString.Char8 as BS
import           System.ZMQ4.Monadic
import           System.Random

main :: IO ()
main = runZMQ $ do
  receiver <- socket Pull
  connect receiver "tcp://localhost:5557"

  sender <- socket Push
  connect sender "tcp://localhost:5558"

  forever $ do
    string <- receive receiver
    liftIO $ do
      BS.putStr (string <> ".")
      hFlush stdout
      threadDelay $ read (BS.unpack string) * 1000
    send sender [] ""
