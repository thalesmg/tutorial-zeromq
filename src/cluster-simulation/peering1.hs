{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}

module Main where

import Control.Monad
import Data.ByteString.Char8 as C8
import Data.List.NonEmpty
import System.ZMQ4.Monadic
import System.Environment
import System.Random
import Text.Printf

main :: IO ()
main = do
  self : others <- getArgs
  print (self : others)
  printf "I: preparando broker em %s...\n" self
  runZMQ $ do
    statebe <- socket Pub
    bind statebe $ printf "ipc://%s-state.ipc" self
    statefe <- socket Sub
    subscribe statefe ""
    forM_ others $ \other -> do
      liftIO $ printf "I: conectando com o backend do par %s\n" other
      connect statefe $ printf "ipc://%s-state.ipc" other
    let pStateFE =
          Sock
            statefe
            [In]
            (Just (\case
                      [In] -> do
                        [peer_name, available] <- receiveMulti statefe
                        liftIO $ printf "%s - %s trabalhadores livres\n" (show peer_name) (show available)

                      [] -> do
                        x <- liftIO $ (randomRIO (1, 10) :: IO Int)
                        sendMulti statebe (fromList [C8.pack self, C8.pack $ show x])

                      _ ->
                        liftIO $ Prelude.putStrLn "taporra"
                     ))
    forever $ do
      evts <- poll 1000 [pStateFE]
      case evts of
        [[]] -> do
          x <- liftIO $ (randomRIO (1, 10) :: IO Int)
          sendMulti statebe (fromList [C8.pack self, C8.pack $ show x])
        _ -> pure ()
