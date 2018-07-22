module Main where

import Control.Concurrent
import qualified Data.ByteString.Char8 as C
import Data.Monoid
import Control.Monad
import System.ZMQ4.Monadic

main :: IO ()
main = runZMQ $ do
  xpub <- socket XPub
  xsub <- socket XSub
  liftIO $ putStrLn "[Proxy] Vou bindar"
  bind xsub "tcp://*:5556"
  bind xpub "tcp://*:5557"
  liftIO $ putStrLn "[Proxy] Bindei"
  forever $ proxy xsub xpub Nothing
