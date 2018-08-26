{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Control.Concurrent
import           Control.Monad
import qualified Data.ByteString.Char8 as BS
import           Data.Monoid
import           System.IO
import           System.Random
import           System.ZMQ4.Monadic

main :: IO ()
main =
  runZMQ $ do
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
