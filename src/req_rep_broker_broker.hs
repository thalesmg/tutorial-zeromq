module Main where

import Control.Concurrent
import qualified Data.ByteString.Char8 as C
import Data.Monoid
import Control.Monad
import System.ZMQ4.Monadic
import qualified Data.List.NonEmpty as NE

main :: IO ()
main = runZMQ $ do
  dealer <- socket Dealer
  router <- socket Router
  bind router "tcp://*:5555"
  bind dealer "tcp://*:5556"
  {-??? Por que precisa ser {send,receive}Multi ???-}
  let pDealer =
        Sock
          dealer
          [In]
          (Just (\_ -> do
                    liftIO $ putStrLn "Dealer -> Broker"
                    receiveMulti dealer >>= sendMulti router . NE.fromList))
  let pRouter =
        Sock
          router
          [In]
          (Just (\_ -> do
                    liftIO $ putStrLn "Broker -> Dealer"
                    receiveMulti router >>= sendMulti dealer . NE.fromList))
  forever $ poll (-1) [pDealer, pRouter]
