module Main where

import           Data.ByteString.Char8 as C
import           Data.Monoid
import           System.ZMQ4.Monadic

main :: IO ()
main =
  runZMQ $ do
    sender <- socket Req
    connect sender "tcp://localhost:5555"
    send sender [] "Carai."
    trem <- receive sender
    liftIO $ C.putStrLn $ "O cara respondeu! " <> trem
