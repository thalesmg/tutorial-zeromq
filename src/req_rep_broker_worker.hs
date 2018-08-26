module Main where

import           Control.Concurrent
import           Control.Monad
import qualified Data.ByteString.Char8 as C
import           Data.Monoid
import           System.ZMQ4.Monadic

main :: IO ()
main =
  runZMQ $ do
    responder <- socket Rep
    connect responder "tcp://localhost:5556"
    forever $ do
      buffer <- receive responder
      liftIO $ do
        C.putStrLn $ "Chegou um trampo! " <> buffer
        threadDelay 1000000
      send responder [] "Tufe!"
