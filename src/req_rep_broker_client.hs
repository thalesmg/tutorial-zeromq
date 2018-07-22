module Main where

import Control.Concurrent
import qualified Data.ByteString.Char8 as C
import Data.Monoid
import Control.Monad
import System.ZMQ4.Monadic

main :: IO ()
main = runZMQ $ do
  requester <- socket Req
  connect requester "tcp://localhost:5555"
  forever $ do
    liftIO $ putStrLn "Vou mandar"
    send requester [] "Opa!"
    liftIO $ putStrLn "Esperando resposta..."
    buffer <- receive requester
    liftIO $ do
      C.putStrLn $ "Chegou um bagulho! " <> buffer
      threadDelay 1000000
