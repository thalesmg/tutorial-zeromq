module Main where

import Control.Concurrent
import qualified Data.ByteString.Char8 as C
import Control.Monad
import System.ZMQ4.Monadic

main :: IO ()
main = runZMQ $ do
  liftIO $ putStrLn "[Sub] Vou conectar"
  subscriber <- socket Sub
  connect subscriber "tcp://localhost:5557"
  liftIO $ putStrLn "[Sub] Conectei"
  subscribe subscriber "tópico"
  liftIO $ putStrLn "[Sub] Assinei"
  forever $ do
    buffer <- receive subscriber
    liftIO $ C.putStrLn $ "[Sub] Epa! " <> buffer
