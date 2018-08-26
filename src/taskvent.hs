{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import           Control.Monad
import qualified Data.ByteString.Char8 as BS
import           System.Random
import           System.ZMQ4.Monadic

main :: IO ()
main =
  runZMQ $ do
    sender <- socket Push
    bind sender "tcp://*:5557"
    sink <- socket Push
    connect sink "tcp://localhost:5558"
    liftIO $ do
      putStrLn "Aperte Enter quando os trabalhadores estiverem prontos."
      _ <- getLine
      putStrLn "Mandando os cabras tramparem..."
    send sink [] "0"
    total_msec <-
      fmap sum $
      replicateM 100 $ do
        workload :: Int <- liftIO $ randomRIO (1, 100)
        send sender [] $ BS.pack (show workload)
        pure workload
    liftIO . putStrLn $ "Custo esperado total: " ++ show total_msec ++ " msec."
