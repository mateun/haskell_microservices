{-# LANGUAGE OverloadedStrings #-}

import Network.AMQP
import qualified Data.ByteString.Lazy.Char8 as BL
import qualified Data.Text as T


{- 
	The main purpose of this program is to discover the
  possibilities on writing a microservice which handles 
  betting related usecases, e.g. to create a new sports event.
  
  Its goal is to 
	 - get a better feel for using haskell in quite realistic scenario
	 - practice the usage of rabbitmq and get used to the diverse
     exchange, queue and routing abilities.

-}

main :: IO ()
main = do 
  conn <- openConnection "127.0.0.1" "/" "guest" "guest"
  channel <- openChannel conn
  putStrLn("enter q name: ")
  qname <- getLine
   
  declareQueue channel newQueue { queueName = T.pack qname }
  -- This is an example how to declare an anonymous queue; letting 
  -- rabbitmq decide on the qname
  (anonQ, _, _) <- declareQueue channel newQueue { queueName = "" }

  -- Here we declare our exchange. If it exists, it will not be overriden, but must be 
  -- of the same type as it is already existing.
  declareExchange channel newExchange { exchangeName = "events", exchangeType = "topic" }
  -- Next we need to bind queues to the exchange.
  -- To enable the routing mechanisms which topic exchanges offer us, 
  -- we need to setup a routing key rule, in our case here we declare to 
  -- bind our named queue to the routing key "ticket.#".
  --  
  bindQueue channel (T.pack qname) "myExchange" "ticket.#"
  -- We make another routing key binding for our anon queue:
  bindQueue channel anonQ "myExchange" "event.#"
  -- Finally we subscribe to the incoming messages on both queues, 
  -- with different callbacks, but it could be the same callbacks as well: 
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
  
