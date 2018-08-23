{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import           Control.Monad
import Data.Time.Clock
import System.IO
import qualified Data.ByteString.Char8 as BS
import           System.ZMQ4.Monadic
import           System.Random

main :: IO ()
main = runZMQ $ do
  receiver <- socket Pull
  bind receiver "tcp://*:5558"

  _ <- receive receiver

  start_time <- liftIO getCurrentTime

  liftIO $ hSetBuffering stdout NoBuffering

  forM_ [1..100] $ \i -> do
    _ <- receive receiver
    if i `mod` 10 == 0
      then liftIO $ putStr ":"
      else liftIO $ putStr "."

  end_time <- liftIO getCurrentTime
  liftIO . putStrLn $ "Tempo total: " ++ show (diffUTCTime end_time start_time * 1000) ++ " msec."
