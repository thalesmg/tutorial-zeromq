module Main where

import           Control.Concurrent
import           Control.Monad
import           Control.Monad.Fix
import           Data.ByteString.Char8 as C8
import           Data.List.NonEmpty
import           Data.Maybe            (isJust)
import           Data.Monoid           ((<>))
import           Data.Restricted       (toRestricted)
import           System.Environment
import           System.Random         (randomRIO)
import           System.ZMQ4.Monadic
import           Text.Printf

workerReady :: C8.ByteString
workerReady = "\001"

numClients = 10

numWorkers = 3

clientTask :: String -> ZMQ z ()
clientTask self = do
  client <- socket Req
  connect client (printf "ipc://%s-localfe.ipc" self)
  forever $ do
    send client [] "Eae!"
    reply <- receive client
    liftIO $ do
      C8.putStrLn $ "Cliente: " <> reply
      threadDelay 1000000

workerTask :: String -> ZMQ z ()
workerTask self = do
  worker <- socket Req
  connect worker $ printf "ipc://%s-localbe.ipc" self
  send worker [] workerReady
  forever $ do
    msg@(clientId:_) <- receiveMulti worker
    liftIO $ do
      C8.putStrLn $ "Trabalhador: "
      print msg
    sendMulti worker (fromList [clientId, "", "OK"])

choose :: [a] -> IO a
choose xs = do
  let n = Prelude.length xs
  i <- randomRIO (0, n - 1)
  pure $ xs Prelude.!! i

main :: IO ()
main = do
  self:peers <- getArgs
  let numPeers = Prelude.length peers
      bspeers = fmap C8.pack peers
  printf "I: preparando corretor em %s...\n" self
  runZMQ $ do
    cloudfe <- socket Router
    let Just rself = toRestricted (C8.pack self)
    setIdentity rself cloudfe
    bind cloudfe $ printf "ipc://%s-cloud.ipc" self
    cloudbe <- socket Router
    forM_ peers $ \peer -> do
      liftIO $ printf "Conectando com o parça '%s'\n" peer
      connect cloudbe $ printf "ipc://%s-cloud.ipc" peer
    localfe <- socket Router
    bind localfe $ printf "ipc://%s-localfe.ipc" self
    localbe <- socket Router
    bind localbe $ printf "ipc://%s-localbe.ipc" self
    liftIO $ do
      printf
        "Pressione Enter quando todos os parças estiverem em suas posições\n"
      void Prelude.getLine
    replicateM_ numWorkers $ liftIO . forkIO $ runZMQ $ workerTask self
    replicateM_ numClients $ liftIO . forkIO $ runZMQ $ clientTask self
    let backends = [Sock localbe [In] Nothing, Sock cloudbe [In] Nothing]
        frontends = [Sock localfe [In] Nothing, Sock cloudfe [In] Nothing]
    flip fix (0, []) $ \cont (capacity, workers) -> do
      let timeout =
            if capacity > 0
              then 1000
              else 5000
      evts <- poll timeout backends
      (capacity, workers, mmsg) <-
        case evts of
          [[In], _] -> do
            (workerIdentity:_:msg@(front:_)) <- receiveMulti localbe
            pure
              ( capacity + 1
              , workers ++ [workerIdentity]
              , if front == workerReady
                  then Nothing
                  else Just msg)
          [_, [In]] -> do
            (_:msg) <- receiveMulti cloudbe
            pure (capacity, workers, Just msg)
          _ -> pure (capacity, workers, Nothing)
      case mmsg of
        Just msg@(identity:_) ->
          if numPeers > 0 && identity `Prelude.elem` bspeers
            then sendMulti cloudfe (fromList msg)
            else sendMulti localfe (fromList msg)
        Nothing -> pure ()
      (capacity, workers) <-
        flip fix (capacity, workers) $ \cont2 (capacity, workers) -> do
          if capacity > 0
            then do
              evts <- poll 0 frontends
              mmsg <-
                case evts of
                  [_, [In]] -> do
                    msg <- receiveMulti cloudfe
                    pure $ Just (msg, False)
                  [[In], _] -> do
                    msg <- receiveMulti localfe
                    pure $ Just (msg, True)
                  _ -> pure Nothing
              case mmsg of
                Nothing -> pure (capacity, workers)
                Just (msg, reroutable) -> do
                  reroute <- fmap (== 0) <$> liftIO $ randomRIO (0 :: Int, 5)
                  if reroutable && reroute && numPeers > 0
                    then do
                      peer <- liftIO $ choose bspeers
                      sendMulti cloudbe (fromList (peer : msg))
                      cont2 (capacity, workers)
                    else do
                      let (worker:rest) = workers
                      sendMulti localbe (fromList (worker : "" : msg))
                      cont2 (capacity - 1, rest)
            else pure (capacity, workers)
      cont (capacity, workers)
