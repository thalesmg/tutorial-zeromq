module Main where

import Control.Concurrent
import Control.Monad
import System.ZMQ4.Monadic

main :: IO ()
main = runZMQ $ do
  liftIO $ putStrLn "[Pub] Vou conectar"
  publisher <- socket Pub
  connect publisher "tcp://localhost:5556"
  liftIO $ putStrLn "[Pub] Conectei"
  forever $ do
    send publisher [] "tópico Oi Brasil!"
    liftIO $ threadDelay 1000000
