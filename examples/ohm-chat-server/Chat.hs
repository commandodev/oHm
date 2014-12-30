{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}


module Chat (server, ServerState (..)) where

import Prelude hiding (mapM_)

import Control.Monad.IO.Class (liftIO)
import Data.Aeson ((.=))
import Data.Foldable (mapM_)
import GHC.Generics
import Control.Applicative
import qualified Control.Concurrent.STM as STM
import qualified Data.Aeson as Aeson
import qualified Data.Text as Text
import qualified Network.SocketIO as SocketIO
import ChatTypes
--------------------------------------------------------------------------------
data ServerState = ServerState { ssNConnected :: STM.TVar Int }

--server :: ServerState -> StateT SocketIO.RoutingTable Snap.Snap ()
server state = do
  userNameMVar <- liftIO STM.newEmptyTMVarIO
  let forUserName m = liftIO (STM.atomically (STM.tryReadTMVar userNameMVar)) >>= mapM_ m

  SocketIO.on "new message" $ \(NewMessage message) ->
    forUserName $ \userName -> do
      liftIO $ print message
      SocketIO.broadcast "new message" (Said userName message)

  SocketIO.on "add user" $ \m@(AddUser userName) -> do
    liftIO $ print m
    n <- liftIO $ STM.atomically $ do
      n <- (+ 1) <$> STM.readTVar (ssNConnected state)
      STM.putTMVar userNameMVar userName
      STM.writeTVar (ssNConnected state) n
      return n

    SocketIO.emit "login" (NumConnected n)
    SocketIO.broadcast "user joined" (UserJoined userName n)

  SocketIO.appendDisconnectHandler $ do
    (n, mUserName) <- liftIO $ STM.atomically $ do
      n <- (+ (-1)) <$> STM.readTVar (ssNConnected state)
      mUserName <- STM.tryReadTMVar userNameMVar
      STM.writeTVar (ssNConnected state) n
      return (n, mUserName)

    case mUserName of
      Nothing -> return ()
      Just userName ->
        SocketIO.broadcast "user left" (UserJoined userName n)

  SocketIO.on_ "typing" $
    forUserName $ \userName -> do
      liftIO $ print ("typing", userName)
      SocketIO.broadcast "typing" (UserName userName)

  SocketIO.on_ "stop typing" $
    forUserName $ \userName ->
      SocketIO.broadcast "stop typing" (UserName userName)
