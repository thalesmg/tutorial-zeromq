module Main where

import Control.Concurrent
import qualified Data.ByteString.Char8 as C
import Data.Monoid
import Control.Monad
import System.ZMQ4.Monadic

main :: IO ()
main = runZMQ $ do
  responder <- socket Rep
  bind responder "tcp://*:5555"
  forever $ do
    buffer <- receive responder
    liftIO $ do
      C.putStrLn $ "Chegou um bagulho! " <> buffer
      threadDelay 1000000
    send responder [] "Opa!"
