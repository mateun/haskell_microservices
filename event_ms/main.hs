{-# LANGUAGE OverloadedStrings #-}

import Network.AMQP
import qualified Data.ByteString.Lazy.Char8 as BL
import qualified Data.Text as T

main :: IO ()
main = do 
  conn <- openConnection "127.0.0.1" "/" "guest" "guest"
  channel <- openChannel conn
  putStrLn("enter q name: ")
  qname <- getLine
   
  declareQueue channel newQueue { queueName = T.pack qname }
  (anonQ, _, _) <- declareQueue channel newQueue { queueName = "" }
  declareExchange channel newExchange { exchangeName = "myExchange", exchangeType = "topic" }
  bindQueue channel (T.pack qname) "myExchange" "ticket.#"
  bindQueue channel anonQ "myExchange" "event.#"
  consumeMsgs channel (T.pack qname) Ack myCallback
  consumeMsgs channel anonQ Ack myEventCallback

  putStrLn "connection open, press key to end"
  getLine
  closeConnection conn
  putStrLn "connection closed"


myCallback :: (Message, Envelope) -> IO()
myCallback (msg, env) = do
  putStrLn $ "received message: " ++ (BL.unpack $ msgBody msg)
  ackEnv env

myEventCallback :: (Message, Envelope) -> IO ()
myEventCallback (msg, env) = do
  putStrLn $ "received eventQ msg: " ++ (BL.unpack $ msgBody msg)
  ackEnv env
  
